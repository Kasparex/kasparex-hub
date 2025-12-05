# Cloudflare Pages Deployment Guide

## Prerequisites

1. A Cloudflare account
2. The repository pushed to GitHub: `https://github.com/Kasparex/kasparex-hub`

## Deployment Steps

### Option 1: Deploy via Cloudflare Dashboard (Recommended)

1. **Sign in to Cloudflare**
   - Go to [dash.cloudflare.com](https://dash.cloudflare.com)
   - Navigate to **Workers & Pages**

2. **Create a New Project**
   - Click **Create application**
   - Select the **Pages** tab
   - Click **Connect to Git**

3. **Connect GitHub Repository**
   - Authorize Cloudflare to access your GitHub account
   - Select the `Kasparex/kasparex-hub` repository
   - Click **Begin setup**

4. **Configure Build Settings**
   - **Project name**: `kasparex-hub`
   - **Production branch**: `main`
   - **Framework preset**: `Remix` (Cloudflare will auto-detect)
   - **Build command**: `npm run build`
   - **Build output directory**: Leave empty (Cloudflare auto-detects for Remix)
   - **Root directory**: `/` (leave as default)

5. **Environment Variables** (if needed)
   - Add any required environment variables in the **Environment variables** section
   - For now, none are required for the landing page

6. **Deploy**
   - Click **Save and Deploy**
   - Wait for the build to complete
   - Your site will be available at `https://kasparex-hub.pages.dev`

7. **Custom Domain** (Optional)
   - Go to your project settings
   - Navigate to **Custom domains**
   - Add your custom domain (e.g., `hub.kasparex.com`)

### Option 2: Deploy via Wrangler CLI

1. **Install Wrangler** (if not already installed)
   ```bash
   npm install -g wrangler
   ```

2. **Login to Cloudflare**
   ```bash
   wrangler login
   ```

3. **Build the Project**
   ```bash
   npm run build
   ```

4. **Deploy to Cloudflare Pages**
   ```bash
   wrangler pages deploy ./build/client --project-name=kasparex-hub
   ```

## Post-Deployment

After deployment, your site will be live at:
- **Cloudflare Pages URL**: `https://kasparex-hub.pages.dev`
- **Custom Domain** (if configured): Your configured domain

## Continuous Deployment

Once connected to GitHub, Cloudflare Pages will automatically deploy:
- Every push to the `main` branch triggers a new deployment
- Pull requests can be previewed with preview deployments

## Troubleshooting

### Build Fails
- Check build logs in Cloudflare dashboard
- Ensure `npm run build` works locally
- Verify Node.js version (requires Node 20+)

### Assets Not Loading
- Ensure public assets are in the `public/` directory
- Check that image paths are correct (e.g., `/img/logos/kasparex.png`)

### Styling Issues
- Verify Tailwind CSS is properly configured
- Check that `app/styles/tailwind.css` is imported in `app/root.tsx`

