#!/usr/bin/env bash

# Lukseh.dev Portfolio - Community Script Style (Self-Hosted)
# Copyright (c) 2025 Lukseh  
# Author: Lukseh
# License: MIT
# Source: https://github.com/Lukseh/luksehDev

set -euo pipefail

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define functions
header_info() { echo -e "\n${BLUE}🚀 $1${NC}\n"; }
msg_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
msg_ok() { echo -e "${GREEN}✅ $1${NC}"; }
msg_error() { echo -e "${RED}❌ $1${NC}"; exit 1; }

APP="Lukseh.dev Portfolio"
CTID="${1:-100}"

header_info "$APP"

# Check if running on Proxmox VE host
if ! command -v pct >/dev/null 2>&1; then
    msg_error "This script must be run on a Proxmox VE host with 'pct' command available"
fi

# Check if container exists
if ! pct status $CTID >/dev/null 2>&1; then
    msg_error "Container $CTID does not exist. Please create it first."
fi

# Check if container is running
if [[ $(pct status $CTID) != *"running"* ]]; then
    msg_info "Starting container $CTID"
    pct start $CTID
    sleep 5
fi

function update_script() {
    header_info "Update Menu"
    
    if ! pct exec $CTID -- test -d /opt/lukseh.dev; then
        msg_error "No ${APP} Installation Found in container $CTID!"
    fi
    
    if command -v whiptail >/dev/null 2>&1; then
        UPD=$(whiptail --backtitle "Lukseh.dev Portfolio" --title "UPDATE" --radiolist --cancel-button Exit-Script "Spacebar = Select" 11 58 2 \
            "1" "Update Lukseh.dev Portfolio" ON \
            "2" "Uninstall Lukseh.dev Portfolio" OFF \
            3>&1 1>&2 2>&3)
    else
        echo "1) Update Lukseh.dev Portfolio"
        echo "2) Uninstall Lukseh.dev Portfolio"
        echo "q) Quit"
        read -p "Choose option (1/2/q): " UPD
    fi

    if [ "$UPD" == "1" ]; then
        msg_info "Updating ${APP} in container $CTID"
        
        # Stop services for update
        pct exec $CTID -- systemctl stop nginx >/dev/null 2>&1 || true
        pct exec $CTID -- su - lukseh -c "pm2 stop all" >/dev/null 2>&1 || true
        
        # Update system packages
        pct exec $CTID -- apt-get update >/dev/null 2>&1
        pct exec $CTID -- apt-get -y upgrade >/dev/null 2>&1
        
        # Update application
        pct exec $CTID -- bash -c "cd /opt/lukseh.dev && git pull" >/dev/null 2>&1
        
        # Update Node.js dependencies
        msg_info "Updating Node.js Dependencies"
        pct exec $CTID -- bash -c "cd /opt/lukseh.dev/node-proxy && npm update" >/dev/null 2>&1
        pct exec $CTID -- bash -c "cd /opt/lukseh.dev/frontend-vue && npm update && npm run build" >/dev/null 2>&1
        
        # Update .NET dependencies
        msg_info "Updating .NET Backend"
        pct exec $CTID -- bash -c "cd /opt/lukseh.dev/backend && dotnet restore && dotnet build -c Release" >/dev/null 2>&1
        
        # Copy updated frontend to nginx
        pct exec $CTID -- rm -rf /var/www/html/*
        pct exec $CTID -- cp -r /opt/lukseh.dev/frontend-vue/dist/* /var/www/html/
        
        # Restart services
        pct exec $CTID -- su - lukseh -c "pm2 restart all" >/dev/null 2>&1 || true
        pct exec $CTID -- systemctl start nginx >/dev/null 2>&1 || true
        
        msg_ok "Updated ${APP} Successfully"
        exit 0
    fi
    
    if [ "$UPD" == "2" ]; then
        msg_info "Uninstalling ${APP} from container $CTID"
        pct exec $CTID -- systemctl stop nginx >/dev/null 2>&1 || true
        pct exec $CTID -- su - lukseh -c "pm2 stop all && pm2 delete all" >/dev/null 2>&1 || true
        pct exec $CTID -- userdel -r lukseh >/dev/null 2>&1 || true
        pct exec $CTID -- rm -rf /opt/lukseh.dev
        pct exec $CTID -- rm -rf /var/www/html/*
        msg_ok "Uninstalled ${APP} Successfully"
        exit 0
    fi
    
    exit 0
}

# Check if this is an update/manage request
if pct exec $CTID -- test -d /opt/lukseh.dev 2>/dev/null; then
    update_script
fi

# Fresh installation
msg_info "Installing ${APP} in container $CTID"

# Run the installation directly in the container
pct exec $CTID -- bash -c "$(curl -fsSL https://raw.githubusercontent.com/Lukseh/luksehDev/main/deploy/lukseh-dev-install.sh)"

# Get container IP
CONTAINER_IP=$(pct exec $CTID -- hostname -I | awk '{print $1}' 2>/dev/null || echo "container-$CTID")

msg_ok "Completed Successfully!"
echo ""
echo -e "${GREEN}🎉 ${APP} setup has been successfully initialized!${NC}"
echo -e "${YELLOW}ℹ️  Access it using the following URLs:${NC}"
echo -e "   ${BLUE}Frontend:${NC}  http://${CONTAINER_IP}"
echo -e "   ${BLUE}Proxy API:${NC} http://${CONTAINER_IP}:3000"
echo -e "   ${BLUE}Backend:${NC}   http://${CONTAINER_IP}:5188"
echo ""
echo -e "${YELLOW}ℹ️  Management:${NC}"
echo -e "   Run this script again to update/uninstall"
echo -e "   Container shell: ${BLUE}pct enter $CTID${NC}"
