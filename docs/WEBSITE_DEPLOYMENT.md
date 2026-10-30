# AUTO Website Deployment Guide

This guide provides instructions for deploying the official AUTO website and download portal located in the `website/` directory to modern hosting platforms.

---

## 1. Overview & Build Configuration

The AUTO website is built with **Vite 6, React 19, TypeScript, and Tailwind/Lucide React**. It compiles to pure static HTML/CSS/JS and requires zero server-side runtimes.

| Property | Value |
|---|---|
| **Source Directory** | `website/` |
| **Framework Preset** | Vite |
| **Node Version** | Node.js 18+ (Node 20+ recommended) |
| **Package Manager** | `npm` |
| **Install Command** | `npm install` |
| **Build Command** | `npm run build` |
| **Output Directory** | `website/dist` (or `dist` when root directory is set to `website`) |
| **Base Path** | `./` (relative path routing, supported on root and sub-paths) |

---

## 2. Cloudflare Pages Deployment

Cloudflare Pages provides global edge distribution, zero bandwidth fees, and built-in SSL.

### Option A: Cloudflare Dashboard (Recommended for Continuous Deployment)

1. Log into your [Cloudflare Dashboard](https://dash.cloudflare.com/) and navigate to **Workers & Pages** > **Create application** > **Pages** > **Connect to Git**.
2. Select your `AUTO` repository.
3. Configure the build settings:
   - **Project Name**: `auto-desktop`
   - **Production Branch**: `main`
   - **Framework Preset**: `Vite`
   - **Root Directory**: `website`
   - **Build Command**: `npm run build`
   - **Build Output Directory**: `dist`
4. Click **Save and Deploy**.
5. Cloudflare will automatically build and deploy preview URLs for PRs and update production on pushes to `main`.

### Option B: Cloudflare Wrangler CLI (Direct Static Upload)

```bash
cd website
npm install
npm run build
npx wrangler pages deploy dist --project-name=auto-desktop
```

---

## 3. Vercel Deployment

### Option A: Vercel Dashboard

1. Import your GitHub repository in the [Vercel Dashboard](https://vercel.com/new).
2. Set **Root Directory** to `website` (click "Edit" next to Root Directory).
3. Vercel will automatically detect **Vite**:
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`
   - **Install Command**: `npm install`
4. Click **Deploy**.

### Option B: Vercel CLI

```bash
cd website
npm install -g vercel
vercel
# For production deployment:
vercel --prod
```

---

## 4. Netlify Deployment

### Option A: Netlify Dashboard

1. Log into [Netlify](https://app.netlify.com/) and select **Add new site** > **Import an existing project**.
2. Connect your GitHub repository.
3. Configure site settings:
   - **Base directory**: `website`
   - **Build command**: `npm run build`
   - **Publish directory**: `website/dist`
4. Click **Deploy AUTO**.

### Option B: Netlify CLI & Manual Drag-and-Drop

```bash
cd website
npm install
npm run build
npx netlify deploy --dir=dist --prod
```

Or drag the `website/dist/` folder directly into the Netlify manual deploy dropzone.

---

## 5. GitHub Pages Deployment

To host directly from your GitHub repository using GitHub Actions:

Create `.github/workflows/deploy-website.yml`:

```yaml
name: Deploy AUTO Website to GitHub Pages

on:
  push:
    branches: [main]
    paths:
      - 'website/**'
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: 'pages'
  cancel-in-progress: true

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'
          cache-dependency-path: website/package-lock.json

      - name: Install Dependencies
        working-directory: website
        run: npm ci

      - name: Build Static Site
        working-directory: website
        run: npm run build

      - name: Setup Pages
        uses: actions/configure-pages@v4

      - name: Upload Artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: website/dist

      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

Then in GitHub repository settings: **Settings** > **Pages** > set source to **GitHub Actions**.

---

## 6. Release Binary Asset Hosting (.dmg & .app)

The download portal in `website/src/pages/Download.tsx` links to official binary distributions:
- `https://github.com/[OWNER]/AUTO/releases/download/v1.0.0/AUTO-1.0.0.dmg`

### Hosting Guidelines
1. **GitHub Releases**: Recommended for versioned open-source distribution. When creating release `v1.0.0` on GitHub, attach `dist/AUTO-1.0.0.dmg`.
2. **Self-Hosted Cloud Storage**: Alternatively, store `AUTO-1.0.0.dmg` in an S3/Cloudflare R2 bucket with a custom domain (e.g., `https://downloads.auto.desktop/AUTO-1.0.0.dmg`).
3. **Checksum Verification**: Always ensure the SHA-256 hash published in `website/src/release-metadata.json` matches the binary:
   ```bash
   shasum -a 256 dist/AUTO-1.0.0.dmg
   ```

---

## 7. Custom Domain & DNS Configuration

When attaching a custom domain (e.g., `auto.desktop` or `getauto.ai`):

1. **Apex / CNAME Records**:
   - For Cloudflare Pages: Point CNAME to `<project>.pages.dev`
   - For Vercel: Point CNAME to `cname.vercel-dns.com`
   - For Netlify: Point CNAME to `<project>.netlify.app`
2. **HTTPS / SSL**: Ensure full TLS 1.3 is enforced by your DNS / CDN provider.
3. **Security Headers**: Recommend serving with HSTS, X-Content-Type-Options: nosniff, and Referrer-Policy: strict-origin-when-cross-origin.

