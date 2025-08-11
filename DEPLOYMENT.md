# 🚀 Cloudflare Deployment Guide for lukseh.dev

## 📋 Prerequisites

1. **Install Wrangler CLI:**
   ```bash
   npm install -g wrangler
   ```

2. **Login to Cloudflare:**
   ```bash
   wrangler login
   ```

## 🏗️ Deployment Steps

### Option 1: Automatic Deployment (Recommended)
Run the deployment script:
```powershell
# PowerShell (Windows)
.\deploy\deploy-cloudflare.ps1

# Bash (Linux/Mac)
chmod +x deploy/deploy-cloudflare.sh
./deploy/deploy-cloudflare.sh
```

### Option 2: Manual Deployment

#### 1. Deploy Frontend to Cloudflare Pages
```bash
# Build the frontend
cd frontend-vue
npm install
npm run build

# Deploy to Pages
cd ../deploy
wrangler pages deploy ../frontend-vue/dist --project-name lukseh-dev
```

#### 2. Deploy Backend to Cloudflare Workers
```bash
# Navigate to worker directory
cd cloudflare-worker

# Install dependencies
npm install

# Deploy the worker
wrangler deploy
```

## 🔧 Configuration

### Frontend Environment Variables
Create `frontend-vue/.env.production`:
```env
VITE_API_BASE_URL=https://lukseh-dev-api.YOUR_SUBDOMAIN.workers.dev
```

### Worker Configuration
The `wrangler.toml` is already configured for your worker.

## 🌐 URLs After Deployment

- **Frontend**: `https://lukseh-dev.pages.dev`
- **API Worker**: `https://lukseh-dev-api.YOUR_SUBDOMAIN.workers.dev`

## 📝 Custom Domain Setup

1. Go to Cloudflare Pages dashboard
2. Add custom domain: `lukseh.dev`
3. Update DNS records as instructed
4. Update worker routes if needed

## 🔄 Continuous Deployment

Connect your GitHub repo to Cloudflare Pages for automatic deployments:

1. **Pages Settings:**
   - Build command: `npm run build`
   - Build output directory: `dist`
   - Root directory: `frontend-vue`

2. **Environment Variables:**
   - `VITE_API_BASE_URL`: Your worker URL

## 🚨 Troubleshooting

- **CORS Issues**: Worker handles CORS automatically
- **API Errors**: Check worker logs with `wrangler tail`
- **Build Failures**: Ensure Node.js 18+ and clean `node_modules`

## 💡 Quick Commands

```bash
# Test worker locally
cd deploy/cloudflare-worker && wrangler dev

# View worker logs
wrangler tail lukseh-dev-api

# Update worker
cd deploy/cloudflare-worker && wrangler deploy

# Deploy frontend only
cd frontend-vue && npm run build
cd ../deploy && wrangler pages deploy ../frontend-vue/dist --project-name lukseh-dev
```
