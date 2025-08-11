#!/bin/bash

# Cloudflare Workers Deployment Script for lukseh.dev
# This script builds and deploys the Vue.js frontend to Cloudflare Pages
# and creates a Cloudflare Worker for the API endpoints

set -e

echo "🚀 Starting Cloudflare Workers deployment for lukseh.dev"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="lukseh-dev"
FRONTEND_DIR="../frontend-vue"
WORKER_DIR="./cloudflare-worker"
BUILD_DIR="$FRONTEND_DIR/dist"

# Check if required commands are available
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 is not installed. Please install it first.${NC}"
        exit 1
    fi
}

echo -e "${BLUE}📋 Checking prerequisites...${NC}"
check_command "npm"
check_command "wrangler"

# Check if user is logged in to Wrangler
if ! wrangler whoami &> /dev/null; then
    echo -e "${YELLOW}⚠️  You are not logged in to Wrangler.${NC}"
    echo -e "${BLUE}🔐 Please run: wrangler login${NC}"
    exit 1
fi

# Build the Vue.js frontend
echo -e "${BLUE}🏗️  Building Vue.js frontend...${NC}"
cd $FRONTEND_DIR

# Clean previous build
if [ -d "dist" ]; then
    rm -rf dist
    echo -e "${GREEN}✅ Cleaned previous build${NC}"
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo -e "${BLUE}📦 Installing frontend dependencies...${NC}"
    npm install
fi

# Build for production
echo -e "${BLUE}🔨 Building for production...${NC}"
npm run build

if [ ! -d "dist" ]; then
    echo -e "${RED}❌ Build failed - dist directory not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Frontend build completed${NC}"

# Go back to deploy directory
cd ../deploy

# Create Cloudflare Worker if it doesn't exist
if [ ! -d "$WORKER_DIR" ]; then
    echo -e "${BLUE}⚡ Creating Cloudflare Worker...${NC}"
    mkdir -p $WORKER_DIR
fi

# Copy worker files
cp cloudflare-worker.js $WORKER_DIR/
cp wrangler.toml $WORKER_DIR/
cp package.json $WORKER_DIR/

cd $WORKER_DIR

# Install worker dependencies
if [ ! -d "node_modules" ]; then
    echo -e "${BLUE}📦 Installing worker dependencies...${NC}"
    npm install
fi

# Deploy the worker
echo -e "${BLUE}⚡ Deploying Cloudflare Worker...${NC}"
wrangler deploy

echo -e "${GREEN}✅ Worker deployed successfully${NC}"

# Go back to deploy directory for Pages deployment
cd ..

# Deploy to Cloudflare Pages
echo -e "${BLUE}📄 Deploying to Cloudflare Pages...${NC}"

# Check if Pages project exists
if ! wrangler pages project list | grep -q "$PROJECT_NAME"; then
    echo -e "${BLUE}📄 Creating Cloudflare Pages project...${NC}"
    wrangler pages project create $PROJECT_NAME --production-branch main
fi

# Deploy to Pages
echo -e "${BLUE}🚀 Deploying to Cloudflare Pages...${NC}"
wrangler pages deploy $BUILD_DIR --project-name $PROJECT_NAME

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${BLUE}📄 Your site will be available at: https://$PROJECT_NAME.pages.dev${NC}"
echo -e "${BLUE}⚡ Worker API will be available at: https://lukseh-dev-api.YOUR_SUBDOMAIN.workers.dev${NC}"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo -e "1. Configure your custom domain in Cloudflare Pages dashboard"
echo -e "2. Update your worker's domain routing if needed"
echo -e "3. Set up environment variables in the Cloudflare dashboard"
echo ""
echo -e "${GREEN}✨ Deployment complete!${NC}"
