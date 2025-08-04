#!/usr/bin/env bash

# Lukseh.dev Portfolio Rebuild Script
# Copyright (c) 2025 Lukseh
# License: MIT

set -euo pipefail

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define functions
msg_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
msg_ok() { echo -e "${GREEN}✅ $1${NC}"; }
msg_error() { echo -e "${RED}❌ $1${NC}"; exit 1; }

echo -e "${BLUE}🔄 Rebuilding Lukseh.dev Portfolio${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   msg_error "This script must be run as root"
fi

# Check if installation exists
if [[ ! -d "/opt/lukseh.dev" ]]; then
    msg_error "Lukseh.dev installation not found at /opt/lukseh.dev"
fi

msg_info "Stopping services"
sudo -u lukseh pm2 stop all >/dev/null 2>&1 || true
systemctl stop nginx >/dev/null 2>&1 || true
msg_ok "Stopped services"

msg_info "Updating source code"
cd /opt/lukseh.dev
sudo -u lukseh git pull >/dev/null 2>&1
msg_ok "Updated source code"

msg_info "Rebuilding Node.js dependencies"
cd /opt/lukseh.dev/node-proxy
sudo -u lukseh npm install --production >/dev/null 2>&1
msg_ok "Rebuilt proxy dependencies"

cd /opt/lukseh.dev/frontend-vue
sudo -u lukseh npm install >/dev/null 2>&1
msg_ok "Installed frontend dependencies"

msg_info "Rebuilding frontend"
sudo -u lukseh npm run build >/dev/null 2>&1
msg_ok "Rebuilt frontend"

msg_info "Rebuilding .NET backend"
cd /opt/lukseh.dev/backend
sudo -u lukseh dotnet restore >/dev/null 2>&1
sudo -u lukseh dotnet build -c Release >/dev/null 2>&1
msg_ok "Rebuilt backend"

msg_info "Updating nginx content"
rm -rf /var/www/html/*
cp -r /opt/lukseh.dev/frontend-vue/dist/* /var/www/html/
msg_ok "Updated nginx content"

msg_info "Restarting services"
sudo -u lukseh pm2 restart all >/dev/null 2>&1
systemctl start nginx >/dev/null 2>&1
msg_ok "Restarted services"

msg_info "Verifying services"
sleep 3
if sudo -u lukseh pm2 list | grep -q "online"; then
    msg_ok "PM2 services are running"
else
    msg_error "PM2 services failed to start"
fi

if systemctl is-active --quiet nginx; then
    msg_ok "Nginx is running"
else
    msg_error "Nginx failed to start"
fi

echo ""
echo -e "${GREEN}🎉 Rebuild completed successfully!${NC}"
echo ""
echo "Services status:"
sudo -u lukseh pm2 list
echo ""
echo "Access your portfolio at:"
echo "- Frontend: http://$(hostname -I | awk '{print $1}')"
echo "- Proxy API: http://$(hostname -I | awk '{print $1}'):3000"
echo "- Backend API: http://$(hostname -I | awk '{print $1}'):5188"
