# Connect `tunesofdavid.com` to GitHub Pages

The repository includes `site/CNAME` with `tunesofdavid.com`. The GitHub Pages **repository setting** must also be saved to activate the custom domain. This cannot be completed from the ZIP alone because it requires access to your GitHub account and your domain registrar.

## 1. Publish first

1. Upload this project's files to a GitHub repository.
2. In **Settings → Pages → Build and deployment**, choose **GitHub Actions**.
3. Push to the `main` branch and wait for the Pages workflow to complete successfully.
4. In **Settings → Pages → Custom domain**, enter `tunesofdavid.com` and click **Save**.
5. If GitHub offers domain verification, verify the domain before relying on it. This helps protect against domain takeover.

## 2. Add DNS records at your domain registrar

For the apex/root domain (`tunesofdavid.com`), add these four **A** records. The record name/host is usually `@`:

| Type | Host / name | Value |
|---|---|---|
| A | `@` | `185.199.108.153` |
| A | `@` | `185.199.109.153` |
| A | `@` | `185.199.110.153` |
| A | `@` | `185.199.111.153` |

For IPv6 support, add these **AAAA** records too, if your DNS provider supports them:

| Type | Host / name | Value |
|---|---|---|
| AAAA | `@` | `2606:50c0:8000::153` |
| AAAA | `@` | `2606:50c0:8001::153` |
| AAAA | `@` | `2606:50c0:8002::153` |
| AAAA | `@` | `2606:50c0:8003::153` |

For the `www` version, add a **CNAME** record:

| Type | Host / name | Value |
|---|---|---|
| CNAME | `www` | `YOUR-GITHUB-USERNAME.github.io` |

Replace `YOUR-GITHUB-USERNAME` with the actual GitHub account or organisation that owns the Pages site. Do **not** point `www` at an unrelated host or at a guessed username.

Remove conflicting/old A, AAAA, CNAME, or registrar parking records for the same host before saving. Do not use wildcard DNS (`*`). Leave unrelated mail records (MX/TXT) alone unless you know they are obsolete.

If your DNS provider supports an apex `ALIAS` or `ANAME`, GitHub also documents pointing that record to the Pages host. Do not add competing apex A and ALIAS/ANAME configurations unless your provider explicitly requires it.

## 3. Confirm and enable HTTPS

- Use your DNS provider's DNS checker or a terminal to confirm the A records match the values above and `www` points to the correct `github.io` host.
- Return to **Settings → Pages** and wait until GitHub reports the custom domain as configured. Then enable **Enforce HTTPS** when it becomes available.
- DNS and certificate provisioning may take time. GitHub's documentation says DNS changes can take up to 24 hours to propagate; no configuration can guarantee instant approval.

### Sources

- GitHub Docs — [Managing a custom domain for your GitHub Pages site](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site)
- GitHub Docs — [About custom domains and GitHub Pages](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/about-custom-domains-and-github-pages)
