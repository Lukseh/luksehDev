#!/bin/bash
# Quick Cloudflare Deployment Script

echo "🚀 Starting Cloudflare deployment..."

# 1. Build frontend
echo "📦 Building frontend..."
cd frontend-vue
npm install
npm run build
cd ..

# 2. Deploy worker
echo "⚡ Deploying worker..."
cd deploy/cloudflare-worker
npm install
wrangler deploy
cd ../..

# 3. Deploy frontend to Pages
echo "📄 Deploying to Pages..."
cd deploy
wrangler pages deploy ../frontend-vue/dist --project-name lukseh-dev

echo "✅ Deployment complete!"
echo "🌐 Frontend: https://lukseh-dev.pages.dev"
echo "⚡ Worker: Check wrangler output for URL"
