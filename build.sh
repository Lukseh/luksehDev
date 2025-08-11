#!/bin/bash
# Build script for Cloudflare Pages

echo "🏗️ Building lukseh.dev portfolio..."

# Navigate to frontend directory
cd frontend-vue

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Build the project
echo "🔨 Building for production..."
npm run build

echo "✅ Build completed successfully!"
