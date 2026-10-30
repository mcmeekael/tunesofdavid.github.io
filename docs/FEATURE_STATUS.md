# Feature status — preview versus live platform

The supplied brief describes a full two-sided musical-gig marketplace. This ZIP provides the public website UX and a database starter, but does not pretend that services requiring authentication, identity checks, emails, file storage, or money movement are already live.

| Requirement from the brief | Included now | Required before production |
|---|---|---|
| Clear, responsive UI and supplied logo | Yes | Branding review on target devices |
| Browse/filter by instrument and location | Working with clearly labelled sample gigs | Connect the live gigs database |
| Musician/employer/admin login choices | Preview dialog and role-specific form fields | Secure server-side authentication and authorisation |
| Musician name bound to verified NIN name | Registration field shown | Contract with an authorised verification provider; server-only legal-name result |
| Skill video at least one minute | Client-side duration hint | Authenticated upload/storage, server-side media validation and admin review queue |
| Employer email + password + OTP | Registration form and explanation | Email provider, one-time codes, expiry, throttling and verification endpoint |
| Forgotten-password email | Button and preview message | Secure, expiring email recovery flow; never email a password or PIN |
| Owner created once; admin accounts owner-only | Admin access described as invitation-only | Server-side owner bootstrap, secure credential rotation, admin audit log and role controls |
| Bank details for musician payouts | Required fields shown in preview | Bank-account validation and tokenised payout provider; do not store raw account numbers in public tables |
| Gigs contain specialty, pay, address, GPS and time | Post-gig preview form validates specialty, amount, address, coordinates and start/end times | Connect the form to an authenticated backend; coordinate validation and paid-before-publish workflow must be server-enforced |
| Minimum ₦2,000 gig + ₦1,000 reserve | Rule displayed | Server-side price validation and payment authorisation |
| Cancellation only at least 48 hours before event | Rule displayed | Server-time cutoff and provider refund logic |
| Ratings/reviews anonymous to public | Workflow described | Private reviewer identity table/API and public review projection that excludes identity |
| Specialty-only gig matching | Filter and data model starter | Server-enforced speciality access rules |
| Availability conflict checks and first approval wins | Workflow described | Transactional database function plus exclusion/locking to prevent race conditions |
| Payment release, reserve refund, 1% owner fee, 10% poster share, ₦1,000 late arrival, ₦5,000 no-show | Rules are displayed | Authoritative attendance evidence, double-entry ledger, webhook reconciliation, dispute workflow and payout/refund service |
| Admin video approvals, suspensions and complaints | Admin role shown | Secure admin console and audited backend endpoints |

## Deliberately not faked

The site does not label example musicians as verified, fabricate reviews, claim that a payment happened, pretend an OTP email was sent, or store the login form content in local storage. Buttons explain when the action is preview-only. Live listings are also not advertised as available jobs.
