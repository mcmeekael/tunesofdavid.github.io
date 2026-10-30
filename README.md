# Tunes of David — website starter

A responsive, dark-and-gold website concept for connecting musicians with employers, built around the supplied Tunes of David logo. The front end is ready to publish on GitHub Pages and includes the `tunesofdavid.com` custom-domain file and a GitHub Actions deployment workflow.

> **Important:** This ZIP is a front-end preview plus a backend/database starter, not a live booking or payment platform yet. The preview deliberately does not transmit or store registration data, verify NINs, send OTPs, email password resets, accept payments, transfer funds, or create real accounts. Do not enter real identity, bank or login information on the preview site.

## What's included

- `site/` — deployable static website, responsive layout, supplied logo, gig filters, role-aware login/register dialog, sample gig detail view, and custom-domain files.
- `.github/workflows/pages.yml` — deploys only `site/` to GitHub Pages when you push to `main`.
- `backend/supabase/schema.sql` — starter relational schema for profiles, specialties, gigs, applications, schedules, reviews, payment records and complaints, with row-level-security enabled.
- `backend/IMPLEMENTATION_CHECKLIST.md` — backend and provider work that must be completed before accepting real accounts or money.
- `docs/DOMAIN_SETUP.md` — exact GitHub Pages DNS checklist for `tunesofdavid.com`.
- `docs/FEATURE_STATUS.md` — what the preview does now versus what needs a secure backend.

## Publish the website on GitHub Pages

1. Create a new GitHub repository named `tunes-of-david` (or another name you prefer).
2. Upload the contents of this ZIP to the **root of the repository**. Keep the `.github` folder and `site` folder in place.
3. In GitHub, open **Settings → Pages**. Under build and deployment, choose **GitHub Actions**.
4. Push or commit the files to the `main` branch. The workflow publishes the contents of `site/` automatically.
5. Follow `docs/DOMAIN_SETUP.md` to connect `tunesofdavid.com` and `www.tunesofdavid.com` at your domain registrar.
6. In **Settings → Pages → Custom domain**, enter `tunesofdavid.com` and save. After DNS resolves and GitHub issues the certificate, enable **Enforce HTTPS**.

The domain must be registered/owned by you, and the registrar must allow DNS record changes. DNS propagation cannot be forced by website code; GitHub notes it can take up to 24 hours.

## Preview locally

Open `site/index.html` in a modern browser. Some browsers restrict local media metadata or certain features for `file://` URLs; if needed, run a static web server from the project folder, e.g. `python -m http.server 8080 --directory site`, and visit `http://localhost:8080`.

The sample listings and directory cards are clearly labelled as previews. The site has no real account database or live job listings until the backend is connected.

## Security notes

- The owner NIN and PIN supplied in the brief are **not embedded in public files**. Anything committed to a GitHub Pages repository must be treated as public. Keep owner credentials, API secrets, payment keys and service-role keys in a server-side secret manager only.
- Never store raw NIN values, four-digit PINs, bank account numbers, payment credentials or password reset tokens in browser storage or publicly readable tables.
- An authorised identity-verification provider is required to verify NIN and retrieve the legal name. The starter schema stores a provider reference rather than a raw NIN.
- Payment, refunds, reserved penalties, fines, the 1% platform fee, the specified 10% gig-poster share, and musician payouts need server-side ledger logic plus a payment/bank payout provider. The front-end does not move money.
- Review the complete `backend/IMPLEMENTATION_CHECKLIST.md` before using the site with real people.
