# 🚀 Cloudflare Workers Deployment Guide

This guide explains how to deploy your lukseh.dev portfolio to Cloudflare Workers and Pages.

## 📋 Prerequisites

Before deploying, ensure you have:

1. **Node.js** (version 16 or higher)
2. **Cloudflare account** (free tier is sufficient)
3. **Wrangler CLI** (Cloudflare's command-line tool)
4. **Domain** (optional, you can use the provided .pages.dev subdomain)

## 🛠️ Setup Instructions

### 1. Install Wrangler CLI

```bash
npm install -g wrangler
```

### 2. Login to Cloudflare

```bash
wrangler login
```

This will open your browser to authenticate with Cloudflare.

### 3. Configure Environment Variables

Update the following files with your actual values:

#### `.env.production` (Frontend)
```env
VITE_API_BASE_URL=https://lukseh-dev-api.YOUR_SUBDOMAIN.workers.dev
```

Replace `YOUR_SUBDOMAIN` with your actual Cloudflare subdomain.

#### `wrangler.toml` (Worker Configuration)
```toml
name = "lukseh-dev-api"
main = "cloudflare-worker.js"
compatibility_date = "2023-12-07"
compatibility_flags = ["nodejs_compat"]

[vars]
ENVIRONMENT = "production"

# Optional: Configure custom domain
# routes = [
#   { pattern = "lukseh.dev/api/*", zone_name = "lukseh.dev" },
#   { pattern = "api.lukseh.dev/*", zone_name = "lukseh.dev" }
# ]
```

## 🚀 Deployment Options

### Option 1: Automated Deployment (Recommended)

#### Windows (PowerShell)
```powershell
.\deploy-cloudflare.ps1
```

#### Windows (Batch)
```cmd
deploy-cloudflare.bat
```

#### Linux/Mac (Bash)
```bash
chmod +x deploy-cloudflare.sh
./deploy-cloudflare.sh
```

### Option 2: Manual Deployment

#### Step 1: Build Frontend
```bash
cd ../frontend-vue
npm install
npm run build
```

#### Step 2: Deploy Worker
```bash
cd ../deploy/cloudflare-worker
npm install
wrangler deploy
```

#### Step 3: Deploy Pages
```bash
cd ..
wrangler pages deploy ../frontend-vue/dist --project-name lukseh-dev
```

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Cloudflare     │    │  Cloudflare     │    │  GitHub API     │
│  Pages          │───▶│  Worker         │───▶│  (External)     │
│  (Frontend)     │    │  (API)          │    │                 │
│                 │    │                 │    │                 │
│ • Vue.js SPA    │    │ • GitHub API    │    │ • Repository    │
│ • Vuetify UI    │    │ • CORS Handler  │    │   Data          │
│ • Static CV     │    │ • Error Handler │    │ • User Info     │
│ • Static Assets │    │ • Rate Limiting │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🌐 What Gets Deployed

### Cloudflare Pages (Frontend)
- Vue.js Single Page Application
- Vuetify UI components
- Static CV page
- Optimized assets (CSS, JS, images)
- Automatic HTTPS
- Global CDN distribution

### Cloudflare Worker (API)
- GitHub API proxy
- CORS handling
- Error management
- Rate limiting
- Edge computing (runs in 300+ locations)

## 🔧 Configuration Options

### Custom Domain Setup

1. **Add your domain to Cloudflare**
2. **Configure DNS records**
3. **Update wrangler.toml routes**
4. **Update frontend API URL**

Example configuration:
```toml
routes = [
  { pattern = "lukseh.dev/api/*", zone_name = "lukseh.dev" },
  { pattern = "api.lukseh.dev/*", zone_name = "lukseh.dev" }
]
```

### Environment Variables

Set these in the Cloudflare dashboard under Workers & Pages:

- `GITHUB_TOKEN`: Optional GitHub personal access token for higher rate limits
- `ENVIRONMENT`: Set to "production"

## 📊 Monitoring & Analytics

### Built-in Analytics
- **Pages Analytics**: Automatic visitor tracking
- **Worker Analytics**: Request metrics and performance
- **Real User Monitoring**: Core Web Vitals

### Custom Monitoring
```javascript
// Add to worker for custom analytics
export default {
  async fetch(request, env, ctx) {
    // Log requests to Analytics Engine
    ctx.waitUntil(
      env.ANALYTICS.writeDataPoint({
        'blobs': [`${request.method} ${new URL(request.url).pathname}`],
        'doubles': [Date.now()],
        'indexes': [`${new URL(request.url).hostname}`]
      })
    )
    
    // Your existing code...
  }
}
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Build Failures
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
npm run build
```

#### 2. Authentication Errors
```bash
# Re-authenticate with Cloudflare
wrangler logout
wrangler login
```

#### 3. Worker Deployment Issues
```bash
# Check worker logs
wrangler tail lukseh-dev-api

# Test worker locally
wrangler dev
```

#### 4. CORS Issues
- Ensure your worker includes proper CORS headers
- Check the `corsHeaders` configuration in `cloudflare-worker.js`
- Verify the API base URL in your frontend environment files

### Performance Optimization

#### Frontend Optimizations
- Assets are automatically minified and compressed
- Images are optimized through Cloudflare's image optimization
- CSS and JS are bundled and cached

#### Worker Optimizations
- Use Workers KV for caching GitHub API responses
- Implement rate limiting to avoid API limits
- Use Durable Objects for stateful operations

## 💰 Cost Considerations

### Free Tier Limits
- **Pages**: 500 builds/month, unlimited requests
- **Workers**: 100,000 requests/day, 10ms CPU time per request
- **KV**: 1GB storage, 100,000 reads/day

### Paid Features
- **Workers Unbound**: $5/month for higher CPU limits
- **Analytics Engine**: $0.05 per million events
- **Custom domains**: Free with Cloudflare DNS

## 🔒 Security Features

### Automatic Security
- **DDoS Protection**: Built-in DDoS mitigation
- **SSL/TLS**: Automatic HTTPS certificates
- **WAF**: Web Application Firewall protection
- **Bot Management**: Automatic bot detection

### Custom Security
```javascript
// Add rate limiting to worker
const rateLimiter = new Map()

export default {
  async fetch(request) {
    const clientIP = request.headers.get('CF-Connecting-IP')
    
    // Implement rate limiting logic
    if (isRateLimited(clientIP)) {
      return new Response('Rate limited', { status: 429 })
    }
    
    // Your existing code...
  }
}
```

## 🚀 Deployment Checklist

- [ ] Node.js and npm installed
- [ ] Wrangler CLI installed and authenticated
- [ ] Environment variables configured
- [ ] Frontend builds successfully
- [ ] Worker deploys without errors
- [ ] Pages deployment completes
- [ ] API endpoints respond correctly
- [ ] Custom domain configured (optional)
- [ ] SSL certificates active
- [ ] Analytics configured

## 📞 Support

If you encounter issues:

1. Check the [Cloudflare Workers documentation](https://developers.cloudflare.com/workers/)
2. Review the [Cloudflare Pages documentation](https://developers.cloudflare.com/pages/)
3. Check the deployment logs in the Cloudflare dashboard
4. Use `wrangler tail` to debug worker issues

## 🔄 Continuous Deployment

For automatic deployments, you can:

1. **GitHub Actions**: Deploy on push to main branch
2. **Cloudflare Pages Git Integration**: Automatic builds from repository
3. **Wrangler API**: Programmatic deployments

Example GitHub Action:
```yaml
name: Deploy to Cloudflare
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm install
      - run: npm run build
      - uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
```

---

**Your Vue.js portfolio is now ready for global deployment! 🌍**
