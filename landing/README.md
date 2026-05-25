# Lolipants landing site

Static marketing site at **`landing/`** — mirrors the app (ink + gold, Poppins +
Noto Naskh Arabic). Uses real onboarding screenshots from the Flutter app.

## Contents

| Path | Purpose |
|------|---------|
| `index.html` | Home: hero, features, app preview, how-it-works, showcase, CTA |
| `styles.css` | Brand tokens + layout |
| `images/` | `onboarding_screen{1,2,3}.jpg`, studio render, brand pattern |
| `privacy.html` / `terms.html` | Legal pages |
| `_redirects` | Cloudflare Pages: `/privacy` and `/terms` pretty URLs |

## Local preview

```bash
cd landing
python -m http.server 4321
# open http://localhost:4321
```

## Deploy to Cloudflare Pages (`loli-pants.com`)

Your domain is on Cloudflare — use **Pages** for the static site.

### Option A: direct upload (fastest)

1. **Workers & Pages → Create → Pages → Upload assets**
2. Project name: `lolipants-landing`
3. Upload the entire **`landing/`** folder (include `images/` and `_redirects`)
4. **Custom domains → Set up a custom domain** → `loli-pants.com`
5. Add **`www.loli-pants.com`** → redirect to apex (Cloudflare dashboard → **Rules → Redirect Rules**, or Pages www alias)

### Option B: Git (recommended)

1. Connect this repo to Cloudflare Pages
2. Build settings:
   - **Build command:** *(empty)*
   - **Build output directory:** `landing`
3. Attach custom domain `loli-pants.com`

### DNS (if not automatic)

With the domain on Cloudflare, Pages usually provisions records when you attach the custom domain. Confirm:

- `loli-pants.com` → CNAME to `<project>.pages.dev` (proxied)
- `www` → redirect to apex

### After deploy

- Open `https://loli-pants.com` and check `/privacy`, `/terms`
- Enable **Web Analytics** on the Pages project (optional, no code change)
- Point App Store / in-app legal URLs to `https://loli-pants.com/privacy` and `/terms`

## Refreshing images

Onboarding art lives in the Flutter repo at `assets/images/onboarding_screen*.jpg`.
When those change, copy into `landing/images/`:

```bash
cp assets/images/onboarding_screen*.jpg landing/images/
```

Then redeploy Pages.
