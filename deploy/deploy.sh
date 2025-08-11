#!/bin/bash

# Simple launcher for Cloudflare deployment
# Runs setup if needed, then deploys

echo "🚀 lukseh.dev Cloudflare Deployment Launcher"
echo ""

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo "⚠️ Wrangler not found. Running setup first..."
    chmod +x setup-cloudflare.sh
    ./setup-cloudflare.sh
    
    if [ $? -ne 0 ]; then
        echo "❌ Setup failed"
        exit 1
    fi
fi

# Check if user is authenticated
if ! wrangler whoami &> /dev/null; then
    echo "🔐 Please authenticate with Cloudflare:"
    wrangler login
    
    if [ $? -ne 0 ]; then
        echo "❌ Authentication failed"
        exit 1
    fi
fi

# Run the deployment
echo "🚀 Starting deployment..."
chmod +x deploy-cloudflare.sh
./deploy-cloudflare.sh
