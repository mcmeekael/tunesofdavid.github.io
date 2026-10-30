-- Tunes of David backend schema starter.
-- Apply only to a development Supabase project first. This is not a complete production system.
-- No raw NIN, four-digit PIN, password, bank account number, card data or secret belongs here.

create extension if not exists pgcrypto;
create extension if not exists btree_gist;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('musician', 'employer', 'admin', 'owner')),
  account_status text not null default 'active' check (account_status in ('active', 'suspended', 'closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.profiles is 'Private account and authorization roles. Admin/owner roles must be assigned only by trusted server-side code.';

create table if not exists public.musician_public_profiles (
  user_id uuid primary key references public.profiles(user_id) on delete cascade,
  display_name text not null,
  stage_name text,
  specialty text not null check (specialty in ('Bass Guitarist', 'Keyboardist', 'Drummer', 'Lead Guitarist', 'Saxophonist', 'Trumpeter', 'Singer', 'Percussionist', 'Other')),
  city text,
  bio text,
  avatar_path text,
  verification_status text not null default 'pending' check (verification_status in ('pending', 'approved', 'rejected', 'suspended')),
  is_publicly_visible boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.musician_public_profiles is 'Safe-to-display fields only. Public clients must never see raw identity or payout information.';

create table if not exists public.musician_private_profiles (
  user_id uuid primary key references public.profiles(user_id) on delete cascade,
  phone text,
  verified_email text,
  verified_legal_name text,
  identity_provider_reference text,
  identity_verified_at timestamptz,
  skill_video_storage_path text,
  skill_video_duration_seconds integer check (skill_video_duration_seconds is null or skill_video_duration_seconds >= 0),
  skill_review_status text not null default 'pending' check (skill_review_status in ('pending', 'approved', 'rejected', 'resubmission_required')),
  payout_provider text,
  payout_recipient_token text,
  payout_bank_name text,
  payout_account_name text,
  payout_destination_verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.musician_private_profiles is 'Private data. Store a provider reference and tokenised payout destination, not raw NIN or bank account number.';

create table if not exists public.employer_profiles (
  user_id uuid primary key references public.profiles(user_id) on delete cascade,
  display_name text,
  organisation_name text,
  email_verified_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.gigs (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references public.profiles(user_id),
  title text not null,
  description text not null,
  required_specialty text not null check (required_specialty in ('Bass Guitarist', 'Keyboardist', 'Drummer', 'Lead Guitarist', 'Saxophonist', 'Trumpeter', 'Singer', 'Percussionist', 'Other')),
  payment_amount_ngn bigint not null check (payment_amount_ngn >= 2000),
  penalty_reserve_ngn bigint not null default 1000 check (penalty_reserve_ngn = 1000),
  platform_fee_basis_points integer not null default 100 check (platform_fee_basis_points = 100),
  musician_poster_share_basis_points integer not null default 0 check (musician_poster_share_basis_points in (0, 1000)),
  venue_name text,
  address text not null,
  city text not null,
  gps_latitude double precision check (gps_latitude is null or (gps_latitude >= -90 and gps_latitude <= 90)),
  gps_longitude double precision check (gps_longitude is null or (gps_longitude >= -180 and gps_longitude <= 180)),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null default 'draft' check (status in ('draft', 'awaiting_payment', 'published', 'booked', 'completed', 'cancellation_requested', 'cancelled', 'closed', 'disputed')),
  payment_state text not null default 'unpaid' check (payment_state in ('unpaid', 'pending', 'paid', 'partially_refunded', 'refunded', 'released', 'disputed')),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint gig_time_valid check (ends_at > starts_at)
);
comment on table public.gigs is 'Publishing and payment state must be changed by trusted backend code after provider verification.';

create table if not exists public.gig_applications (
  id uuid primary key default gen_random_uuid(),
  gig_id uuid not null references public.gigs(id) on delete restrict,
  musician_id uuid not null references public.profiles(user_id) on delete restrict,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined', 'schedule_conflict', 'withdrawn', 'cancelled')),
  applied_at timestamptz not null default now(),
  decided_at timestamptz,
  decision_note text,
  unique(gig_id, musician_id)
);

create table if not exists public.musician_schedules (
  id uuid primary key default gen_random_uuid(),
  musician_id uuid not null references public.profiles(user_id) on delete restrict,
  gig_id uuid not null references public.gigs(id) on delete restrict,
  application_id uuid not null unique references public.gig_applications(id) on delete restrict,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null default 'accepted' check (status in ('accepted', 'completed', 'cancelled', 'no_show', 'disputed')),
  created_at timestamptz not null default now(),
  constraint schedule_time_valid check (ends_at > starts_at),
  constraint musician_has_no_overlapping_accepted_gigs exclude using gist (
    musician_id with =,
    tstzrange(starts_at, ends_at, '[)') with &&
  ) where (status = 'accepted')
);
comment on table public.musician_schedules is 'The exclusion constraint prevents overlapping accepted bookings; acceptance should be performed in one database transaction.';

create table if not exists public.payment_transactions (
  id uuid primary key default gen_random_uuid(),
  gig_id uuid not null references public.gigs(id) on delete restrict,
  payer_id uuid not null references public.profiles(user_id),
  beneficiary_id uuid references public.profiles(user_id),
  provider_name text not null,
  provider_reference text not null unique,
  transaction_kind text not null check (transaction_kind in ('gig_payment', 'penalty_reserve', 'reserve_refund', 'musician_payout', 'poster_share', 'platform_fee', 'late_penalty', 'no_show_fine', 'employer_lateness_fee', 'other_refund')),
  amount_ngn bigint not null check (amount_ngn > 0),
  status text not null default 'pending' check (status in ('pending', 'authorised', 'settled', 'failed', 'refunded', 'disputed')),
  provider_payload_reference text,
  created_at timestamptz not null default now(),
  settled_at timestamptz
);
comment on table public.payment_transactions is 'Never trust browser payment status. Reconcile server-side against signed provider webhooks.';

create table if not exists public.ledger_entries (
  id uuid primary key default gen_random_uuid(),
  gig_id uuid references public.gigs(id) on delete restrict,
  related_transaction_id uuid references public.payment_transactions(id) on delete restrict,
  entry_type text not null check (entry_type in ('employer_charge', 'musician_payout', 'reserve_hold', 'reserve_refund', 'platform_fee', 'poster_share', 'late_penalty', 'no_show_fine', 'employer_lateness_fee', 'refund', 'adjustment')),
  amount_ngn bigint not null check (amount_ngn > 0),
  debit_account text not null,
  credit_account text not null,
  idempotency_key text not null unique,
  created_at timestamptz not null default now()
);
comment on table public.ledger_entries is 'Immutable accounting entries; inserts and reads should be restricted to trusted server code and approved audit roles.';

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  gig_id uuid not null references public.gigs(id) on delete restrict,
  reviewer_user_id uuid not null references public.profiles(user_id) on delete restrict,
  musician_user_id uuid not null references public.profiles(user_id) on delete restrict,
  rating smallint not null check (rating between 1 and 5),
  review_text text not null,
  is_anonymous_to_public boolean not null default true check (is_anonymous_to_public),
  moderation_status text not null default 'pending' check (moderation_status in ('pending', 'published', 'hidden', 'flagged')),
  created_at timestamptz not null default now(),
  unique(gig_id, reviewer_user_id, musician_user_id)
);
comment on table public.reviews is 'Do not expose reviewer_user_id through public queries. Provide a server-side public projection with rating and review_text only.';

create table if not exists public.complaints (
  id uuid primary key default gen_random_uuid(),
  filed_by uuid not null references public.profiles(user_id) on delete restrict,
  gig_id uuid references public.gigs(id) on delete restrict,
  category text not null,
  description text not null,
  status text not null default 'open' check (status in ('open', 'under_review', 'disclosed_to_owner', 'resolved', 'closed')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table if not exists public.admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references public.profiles(user_id) on delete set null,
  action text not null,
  target_type text not null,
  target_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
comment on table public.admin_audit_log is 'Write audit events from trusted server-side functions; keep sensitive values out of details.';

-- All application tables are private by default. Add narrowly-scoped policies only after testing.
alter table public.profiles enable row level security;
alter table public.musician_public_profiles enable row level security;
alter table public.musician_private_profiles enable row level security;
alter table public.employer_profiles enable row level security;
alter table public.gigs enable row level security;
alter table public.gig_applications enable row level security;
alter table public.musician_schedules enable row level security;
alter table public.payment_transactions enable row level security;
alter table public.ledger_entries enable row level security;
alter table public.reviews enable row level security;
alter table public.complaints enable row level security;
alter table public.admin_audit_log enable row level security;

-- Minimal self-read policies. Account creation/role changes, applications, payments,
-- reviews and booking decisions should be implemented through authenticated server functions.
drop policy if exists "Users can read own profile" on public.profiles;
create policy "Users can read own profile" on public.profiles
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "Public can read visible approved musician profiles" on public.musician_public_profiles;
create policy "Public can read visible approved musician profiles" on public.musician_public_profiles
  for select to anon, authenticated using (
    verification_status = 'approved' and is_publicly_visible = true
  );

drop policy if exists "Musicians can read own public profile while pending" on public.musician_public_profiles;
create policy "Musicians can read own public profile while pending" on public.musician_public_profiles
  for select to authenticated using (user_id = auth.uid());

grant select on public.profiles to authenticated;
grant select on public.musician_public_profiles to anon, authenticated;
grant select on public.musician_private_profiles to authenticated;
grant select on public.employer_profiles to authenticated;
grant select on public.gigs to anon, authenticated;
grant select on public.gig_applications to authenticated;
grant select on public.musician_schedules to authenticated;
grant select on public.payment_transactions to authenticated;
grant select on public.complaints to authenticated;

drop policy if exists "Users can read own private musician profile" on public.musician_private_profiles;
create policy "Users can read own private musician profile" on public.musician_private_profiles
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "Employers can read own employer profile" on public.employer_profiles;
create policy "Employers can read own employer profile" on public.employer_profiles
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "Public can read paid published gigs" on public.gigs;
create policy "Public can read paid published gigs" on public.gigs
  for select to anon, authenticated using (status = 'published' and payment_state = 'paid');

drop policy if exists "Creators can read their own gigs" on public.gigs;
create policy "Creators can read their own gigs" on public.gigs
  for select to authenticated using (created_by = auth.uid());

drop policy if exists "Musicians can read own applications" on public.gig_applications;
create policy "Musicians can read own applications" on public.gig_applications
  for select to authenticated using (musician_id = auth.uid());

drop policy if exists "Creators can read applications to their gigs" on public.gig_applications;
create policy "Creators can read applications to their gigs" on public.gig_applications
  for select to authenticated using (exists (
    select 1 from public.gigs g where g.id = gig_applications.gig_id and g.created_by = auth.uid()
  ));

drop policy if exists "Musicians can read own schedule" on public.musician_schedules;
create policy "Musicians can read own schedule" on public.musician_schedules
  for select to authenticated using (musician_id = auth.uid());

drop policy if exists "Users can read own payment transactions" on public.payment_transactions;
create policy "Users can read own payment transactions" on public.payment_transactions
  for select to authenticated using (payer_id = auth.uid() or beneficiary_id = auth.uid());

drop policy if exists "Users can read complaints they filed" on public.complaints;
create policy "Users can read complaints they filed" on public.complaints
  for select to authenticated using (filed_by = auth.uid());

-- Intentionally no client policies for schedules, ledger entries, reviews, or admin audit logs.
-- Create reviewed server-side RPC/Edge Function endpoints before allowing these operations.


-- Transaction-safe booking workflow. Money collection/refunds remain provider-side.
create or replace function public.apply_for_gig(p_gig_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_specialty text;
  v_profile_status text;
  v_skill_status text;
  v_identity_verified_at timestamptz;
  v_payout_verified_at timestamptz;
  v_gig public.gigs%rowtype;
  v_application_id uuid;
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;

  select role into v_role from public.profiles where user_id = v_user_id and account_status = 'active';
  if v_role <> 'musician' then raise exception 'Only an active musician can apply'; end if;

  select pub.specialty, pub.verification_status, priv.skill_review_status,
         priv.identity_verified_at, priv.payout_destination_verified_at
    into v_specialty, v_profile_status, v_skill_status, v_identity_verified_at, v_payout_verified_at
    from public.musician_public_profiles pub
    join public.musician_private_profiles priv on priv.user_id = pub.user_id
   where pub.user_id = v_user_id;

  if v_profile_status is distinct from 'approved' or v_skill_status is distinct from 'approved'
     or v_identity_verified_at is null or v_payout_verified_at is null then
    raise exception 'Complete identity, skill-video and payout verification before applying';
  end if;

  select * into v_gig from public.gigs
   where id = p_gig_id and status = 'published' and payment_state = 'paid'
     and starts_at > now()
   for share;
  if not found then raise exception 'This gig is not currently available'; end if;
  if v_gig.required_specialty <> v_specialty then raise exception 'This gig does not match your approved specialty'; end if;

  if exists (
    select 1 from public.musician_schedules s
     where s.musician_id = v_user_id and s.status = 'accepted'
       and tstzrange(s.starts_at, s.ends_at, '[)') && tstzrange(v_gig.starts_at, v_gig.ends_at, '[)')
  ) then
    raise exception 'This gig clashes with an accepted booking';
  end if;

  insert into public.gig_applications(gig_id, musician_id, status)
  values (p_gig_id, v_user_id, 'pending')
  on conflict (gig_id, musician_id) do update set status = 'pending', applied_at = now(), decided_at = null, decision_note = null
  returning id into v_application_id;

  return v_application_id;
end;
$$;
revoke all on function public.apply_for_gig(uuid) from public;
grant execute on function public.apply_for_gig(uuid) to authenticated;

create or replace function public.accept_gig_application(p_application_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_gig public.gigs%rowtype;
  v_app public.gig_applications%rowtype;
  v_role text;
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;

  select * into v_app from public.gig_applications where id = p_application_id for update;
  if not found then raise exception 'Application not found'; end if;
  if v_app.status <> 'pending' then raise exception 'Application is no longer pending'; end if;

  select * into v_gig from public.gigs where id = v_app.gig_id for update;
  if not found or v_gig.created_by <> v_user_id then raise exception 'Only the gig creator can accept an application'; end if;
  if v_gig.status <> 'published' or v_gig.payment_state <> 'paid' or v_gig.starts_at <= now() then
    raise exception 'This gig cannot accept applications';
  end if;

  select role into v_role from public.profiles where user_id = v_app.musician_id and account_status = 'active';
  if v_role <> 'musician' then raise exception 'Applicant is not an active musician'; end if;
  if not exists (
    select 1 from public.musician_public_profiles pub
    join public.musician_private_profiles priv on priv.user_id = pub.user_id
    where pub.user_id = v_app.musician_id
      and pub.specialty = v_gig.required_specialty
      and pub.verification_status = 'approved'
      and priv.skill_review_status = 'approved'
      and priv.identity_verified_at is not null
      and priv.payout_destination_verified_at is not null
  ) then raise exception 'Musician is not eligible for this specialty or is not fully verified'; end if;

  -- An exclusion constraint is the final race-safe guard if two employers accept bookings at once.
  begin
    update public.gig_applications set status = 'accepted', decided_at = now(), decision_note = null where id = v_app.id;
    insert into public.musician_schedules(musician_id, gig_id, application_id, starts_at, ends_at, status)
    values (v_app.musician_id, v_gig.id, v_app.id, v_gig.starts_at, v_gig.ends_at, 'accepted');
  exception when exclusion_violation then
    update public.gig_applications set status = 'schedule_conflict', decided_at = now(), decision_note = 'A different booking was accepted first.' where id = v_app.id;
    return false;
  end;
  return true;
end;
$$;
revoke all on function public.accept_gig_application(uuid) from public;
grant execute on function public.accept_gig_application(uuid) to authenticated;

create or replace function public.request_gig_cancellation(p_gig_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_gig public.gigs%rowtype;
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  select * into v_gig from public.gigs where id = p_gig_id for update;
  if not found or v_gig.created_by <> v_user_id then raise exception 'Only the gig creator can request cancellation'; end if;
  if v_gig.starts_at < now() + interval '48 hours' then
    raise exception 'Cancellation is available only at least 48 hours before the gig';
  end if;
  if v_gig.status not in ('published', 'booked') then raise exception 'This gig cannot be cancelled from its current state'; end if;
  update public.gigs set status = 'cancellation_requested', updated_at = now() where id = p_gig_id;
  -- A trusted provider integration must perform/reconcile refunds before setting cancelled/refunded.
  return true;
end;
$$;
revoke all on function public.request_gig_cancellation(uuid) from public;
grant execute on function public.request_gig_cancellation(uuid) to authenticated;

create or replace function public.submit_musician_review(
  p_gig_id uuid,
  p_musician_id uuid,
  p_rating smallint,
  p_review_text text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_review_id uuid;
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  if p_rating < 1 or p_rating > 5 then raise exception 'Rating must be from 1 to 5'; end if;
  if length(trim(coalesce(p_review_text, ''))) < 3 then raise exception 'Please provide a short review'; end if;
  if not exists (
    select 1 from public.gigs g
    join public.musician_schedules s on s.gig_id = g.id and s.musician_id = p_musician_id
    where g.id = p_gig_id and g.created_by = v_user_id and g.status = 'completed' and s.status = 'completed'
  ) then raise exception 'Only an employer for a completed gig can review an attending musician'; end if;
  insert into public.reviews(gig_id, reviewer_user_id, musician_user_id, rating, review_text, is_anonymous_to_public, moderation_status)
  values (p_gig_id, v_user_id, p_musician_id, p_rating, trim(p_review_text), true, 'published')
  returning id into v_review_id;
  return v_review_id;
end;
$$;
revoke all on function public.submit_musician_review(uuid, uuid, smallint, text) from public;
grant execute on function public.submit_musician_review(uuid, uuid, smallint, text) to authenticated;

-- Safe public review projection: deliberately excludes reviewer_user_id.
create or replace view public.public_musician_reviews
with (security_barrier = true)
as
  select musician_user_id, rating, review_text, created_at
    from public.reviews
   where moderation_status = 'published' and is_anonymous_to_public = true;
grant select on public.public_musician_reviews to anon, authenticated;

create or replace view public.public_musician_review_summary
with (security_barrier = true)
as
  select musician_user_id, count(*)::integer as review_count, round(avg(rating)::numeric, 2) as average_rating
    from public.reviews
   where moderation_status = 'published' and is_anonymous_to_public = true
   group by musician_user_id;
grant select on public.public_musician_review_summary to anon, authenticated;

-- These functions intentionally do not collect payment or release funds. Implement provider
-- checkout creation and webhook reconciliation using Edge Functions and idempotent ledger writes.
