#!/bin/bash

# Quick setup script for Cloudflare Workers deployment
# This script installs prerequisites and prepares the environment

echo "🚀 Setting up Cloudflare Workers environment for lukseh.dev"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed${NC}"
    echo -e "${BLUE}Please install Node.js from https://nodejs.org/${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Node.js found: $(node --version)${NC}"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ npm found: $(npm --version)${NC}"

# Install Wrangler CLI globally
echo -e "${BLUE}📦 Installing Wrangler CLI...${NC}"
npm install -g wrangler

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Wrangler installed successfully${NC}"
else
    echo -e "${RED}❌ Failed to install Wrangler${NC}"
    exit 1
fi

# Check Wrangler version
echo -e "${GREEN}✅ Wrangler version: $(wrangler --version)${NC}"

# Install frontend dependencies
echo -e "${BLUE}📦 Installing frontend dependencies...${NC}"
cd ../frontend-vue
npm install

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Frontend dependencies installed${NC}"
else
    echo -e "${RED}❌ Failed to install frontend dependencies${NC}"
    exit 1
fi

# Go back to deploy directory
cd ../deploy

# Create worker directory structure
echo -e "${BLUE}📁 Setting up worker directory...${NC}"
mkdir -p cloudflare-worker

echo -e "${GREEN}✅ Environment setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Run: ${BLUE}wrangler login${NC} to authenticate with Cloudflare"
echo -e "2. Update the API URL in frontend-vue/.env.production"
echo -e "3. Run: ${BLUE}./deploy-cloudflare.sh${NC} to deploy"
echo ""
echo -e "${GREEN}🎉 Ready to deploy to Cloudflare Workers!${NC}"
