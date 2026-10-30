# Supabase schema starter

1. Create a separate Supabase development project.
2. Review `schema.sql` before executing it in the SQL editor.
3. Configure Supabase Auth and email OTP for employers; decide the verified auth/session flow for musicians and admins.
4. Keep the service-role key only in Edge Function/server secrets. Never place it in `site/config.js`.
5. Create reviewed Edge Functions for profile registration, owner bootstrap, NIN provider verification, secure video uploads, payment checkout, signed webhook handling and payout/refund reconciliation.
6. Use the included database functions for application and schedule logic only after testing them with concurrent requests and the production auth setup.

## Included database workflow functions

- `apply_for_gig(gig_id)` checks the authenticated musician's verification, approved specialty, paid/published gig state, future start and currently accepted schedule before creating an application.
- `accept_gig_application(application_id)` accepts on behalf of the gig creator and inserts a schedule row. A PostgreSQL exclusion constraint prevents two overlapping accepted bookings; a losing simultaneous acceptance is marked `schedule_conflict`.
- `request_gig_cancellation(gig_id)` applies the 48-hour cutoff and marks a cancellation request. It intentionally does not issue a refund; a payment-provider webhook must confirm the actual refund before final cancellation.
- `submit_musician_review(...)` only allows a gig creator to review a musician with a completed schedule for a completed gig. Public review views exclude reviewer identity and the gig ID.

All money operations remain unimplemented until you choose providers. The schema and functions are a starter to review, not a complete marketplace backend. Run database tests, abuse/rate-limit tests, RLS tests, provider sandbox tests and a qualified security review before using real user data or funds.
