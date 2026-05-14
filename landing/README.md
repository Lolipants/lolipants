# Lolipants landing site

Static marketing site that mirrors the app's visual identity (ink background,
gold accents, Latin + Noto Naskh Arabic typography). Ships as two files:

- `index.html` — semantic single-page structure: hero, features,
  how-it-works, showcase tiles, CTA, footer.
- `styles.css` — brand tokens + responsive layout.

## Local preview

```bash
cd landing
python -m http.server 4321
# open http://localhost:4321
```

No build step is required; the site is fully static and the fonts are
fetched from Google Fonts at load time.

## Deploying to Cloudflare Pages

### Option 1: direct upload (fastest for pre-launch)

1. Go to **Cloudflare dashboard → Workers & Pages → Create application
   → Pages → Upload assets**.
2. Name the project `lolipants-landing` and drop the `landing/` folder.
3. Set the custom domain to `lolipants.com` once DNS is configured.

### Option 2: Git integration (recommended for iteration)

1. Push this repository to GitHub/GitLab.
2. Cloudflare dashboard → Pages → **Create a project → Connect to Git**.
3. Select the repo and use these build settings:
   - **Build command:** *leave empty*
   - **Build output directory:** `landing`
   - **Root directory:** *leave empty*
4. Preview deployments will be produced for every branch.

### Custom domains

- Primary: `lolipants.com` (A/AAAA records managed by Cloudflare).
- Alias: `www.lolipants.com` → redirect to apex via a Cloudflare Page Rule.

### Analytics

Enable **Cloudflare Web Analytics** on the Pages project (cookie-less). No
code changes are required.

## Replacing the placeholder art

The showcase tiles use CSS gradients so the site is production-quality even
without imagery. When real renders are available:

1. Drop exports into `landing/images/` (JPEG or WebP, ~1080×1440).
2. Replace each `.showcase__tile--n` background rule in `styles.css` with:

```css
.showcase__tile--one {
  background: url("./images/showcase-1.webp") center / cover;
}
```

## Legal pages

The app links to the canonical routes `/privacy` and `/terms`. The landing
site keeps those routes in sync with the detailed documents in
`landing/privacy.html` and `landing/terms.html`.
