# Backend implementation checklist

The website is deployed as static files on GitHub Pages. GitHub Pages does not run a private application server, authenticate users securely by itself, verify NIN, send email OTPs, store private video uploads, or process bank payments. Those operations must be implemented on a secure backend such as Supabase Edge Functions (or an equivalent hosted API) and tested before collecting real user data.

## Secrets and owner account

- Do not place the supplied owner NIN or four-digit PIN in `site/`, HTML, JavaScript, `config.js`, SQL seed files, Git history, or a public GitHub Actions variable.
- Provision the owner on the server as a one-time bootstrap operation. Store any bootstrap credential values only in the backend provider's encrypted secret manager; require rate limiting, audit logging, credential rotation, and preferably email/MFA confirmation. The four-digit PIN should not be accepted as the sole protection for a high-privilege owner account.
- Do not expose a public API endpoint that returns a user's password, PIN, NIN, bank account number or other user's private information. A forgotten-password route should send a short-lived reset link, not the existing credential.
- Assign the `owner` and `admin` roles only from trusted server-side code. Never accept a user-selected role as proof of admin permission.

## Required provider integrations

1. **Authentication and email:** verified email OTP, secure sessions, rate limits, reset links, account lockout, and server-side role claims.
2. **NIN verification:** use a service you're authorised to use. Verify the NIN and retrieve the associated name from the provider; do not infer verification from a user typing an NIN. Keep raw NIN out of public tables/logs, and minimise retention.
3. **Private media:** signed upload URLs, file size/type restrictions, server-side video duration checks, malware scanning where available, and admin-only review access.
4. **Payments/payouts:** choose a Nigeria-supported provider that can accept employer payments and support your required refund/payout flows. Implement an immutable server-side ledger, idempotent provider webhooks, reconciliation, dispute handling, and owner/admin audit logs. Never trust a browser message for payment success or gig attendance.
5. **Bank destination validation:** use a supported bank/account verification and payout provider; prefer provider tokens rather than storing raw account numbers. Protect any account-name returned by the provider.
6. **GPS and arrival evidence:** agree on a lawful attendance process. Do not trigger a fine only because a browser supplies a GPS coordinate; validate server-side, retain minimal evidence, and provide a dispute route.

## Business logic to implement server-side

- Publishing requires a successful payment for the gig amount (minimum ₦2,000) plus a separately recorded ₦1,000 reserve.
- A payment provider webhook must be the source of truth. An event marked paid in the browser must never count as settled.
- Cancellation is accepted only when `starts_at >= server_time + interval '48 hours'`, subject to the payment provider's actual refund result.
- Applications must match the musician's approved specialty. Accepting an application must atomically check overlapping accepted schedules and reserve the slot, so simultaneous requests cannot double-book a musician.
- Public reviews expose the rating and text but never the employer's public identity. Only a completed eligible gig can be reviewed; enforce one required review per attending musician.
- Apply the brief's specified rules: 1% platform fee; a musician who posted the gig receives a 10% share directly from the gig payment (not the reserve); return the ₦1,000 reserve when no penalty applies; a verified arrival more than 30 minutes late triggers the specified ₦1,000 deduction/refund; an accepted no-show triggers the stated ₦5,000 fine. All fines/fees need ledger entries and payment-provider settlement.
- The brief also states that an employer more than 30 minutes late must pay an extra ₦1,000 to the musician and the musician may leave 30 minutes after the agreed time. The precise start/end grace rule, proof and dispute process should be written into the provider workflow before coding money movement.
- The brief mentions both the gig payment being paid 30 minutes after the agreed time and event ending. Clarify whether the release clock is tied to agreed start or agreed end before production; the preview does not release funds.
- Allow cancellation only through a server endpoint, keep audit logs, and keep schedule changes consistent with the payment/refund state.

## Suggested build order

1. Configure auth, verified email, owner bootstrap and RLS.
2. Complete musician profile verification and private media storage.
3. Implement gigs, speciality filtering and transactional schedule handling.
4. Integrate payments in sandbox mode, then test reserve refunds, fees, fines and payouts end-to-end.
5. Add review submission, admin moderation, complaints and audit screens.
6. Add privacy notice, terms, customer support/dispute process, operational monitoring, backups and security testing.
7. Turn off preview mode only after every server integration has been tested.

`schema.sql` is a starting schema, not a complete production implementation. Review and extend its row-level policies and database functions with a qualified engineer before attaching real accounts or money.
