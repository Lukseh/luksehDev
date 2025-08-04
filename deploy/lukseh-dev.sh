#!/usr/bin/env bash

# Lukseh.dev Portfolio - Community Script Style (Self-Hosted)
# Copyright (c) 2025 Lukseh  
# Author: Lukseh
# License: MIT
# Source: https://github.com/Lukseh/luksehDev

# Load community script functions but handle gracefully if not available
if curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func >/dev/null 2>&1; then
    source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
    COMMUNITY_FUNCTIONS=true
else
    COMMUNITY_FUNCTIONS=false
    # Fallback functions if community scripts aren't available
    header_info() { echo -e "\n🚀 $1\n"; }
    msg_info() { echo -e "ℹ️  $1"; }
    msg_ok() { echo -e "✅ $1"; }
    msg_error() { echo -e "❌ $1"; exit 1; }
    variables() { :; }
    color() { :; }
    catch_errors() { set -euo pipefail; }
fi

APP="Lukseh.dev Portfolio"
var_tags="${var_tags:-development;portfolio;nodejs;dotnet;vue}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
if [ "$COMMUNITY_FUNCTIONS" = true ]; then
    variables
    color
fi
catch_errors

function update_script() {
    header_info
    if [ "$COMMUNITY_FUNCTIONS" = true ]; then
        check_container_storage
        check_container_resources
    fi
    
    if [[ ! -d /opt/lukseh.dev ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    
    UPD=$(whiptail --backtitle "Lukseh.dev Portfolio" --title "UPDATE" --radiolist --cancel-button Exit-Script "Spacebar = Select" 11 58 2 \
        "1" "Update Lukseh.dev Portfolio" ON \
        "2" "Uninstall Lukseh.dev Portfolio" OFF \
        3>&1 1>&2 2>&3)

    if [ "$UPD" == "1" ]; then
        msg_info "Updating ${APP}"
        
        # Stop services for update
        systemctl stop pm2-lukseh >/dev/null 2>&1 || true
        systemctl stop nginx >/dev/null 2>&1 || true
        
        # Update system packages
        apt-get update >/dev/null 2>&1
        apt-get -y upgrade >/dev/null 2>&1
        
        # Update application
        cd /opt/lukseh.dev
        git pull
        
        # Update Node.js dependencies
        msg_info "Updating Node.js Dependencies"
        cd /opt/lukseh.dev/node-proxy
        npm update >/dev/null 2>&1
        
        cd /opt/lukseh.dev/frontend-vue
        npm update >/dev/null 2>&1
        npm run build >/dev/null 2>&1
        
        # Update .NET dependencies
        msg_info "Updating .NET Backend"
        cd /opt/lukseh.dev/backend
        dotnet restore >/dev/null 2>&1
        dotnet build -c Release >/dev/null 2>&1
        
        # Copy updated frontend to nginx
        rm -rf /var/www/html/*
        cp -r /opt/lukseh.dev/frontend-vue/dist/* /var/www/html/
        
        # Restart services
        systemctl start pm2-lukseh >/dev/null 2>&1 || true
        systemctl start nginx >/dev/null 2>&1 || true
        
        msg_ok "Updated ${APP} Successfully"
        exit
    fi
    
    if [ "$UPD" == "2" ]; then
        msg_info "Uninstalling ${APP}"
        systemctl stop nginx >/dev/null 2>&1 || true
        systemctl stop pm2-lukseh >/dev/null 2>&1 || true
        systemctl disable pm2-lukseh >/dev/null 2>&1 || true
        userdel -r lukseh >/dev/null 2>&1 || true
        rm -rf /opt/lukseh.dev
        rm -rf /var/www/html/*
        msg_ok "Uninstalled ${APP} Successfully"
        exit
    fi
}

if [ "$COMMUNITY_FUNCTIONS" = true ]; then
    start
    build_container
    description
fi

# Run the installation
bash <(curl -fsSL https://raw.githubusercontent.com/Lukseh/luksehDev/main/deploy/lukseh-dev-install.sh)

msg_ok "Completed Successfully!\n"
echo -e "🎉 ${APP} setup has been successfully initialized!"
echo -e "ℹ️  Access it using the following URL:"
if [ "$COMMUNITY_FUNCTIONS" = true ]; then
    echo -e "   http://${IP}"
    echo -e "ℹ️  Services:"
    echo -e "   Frontend: http://${IP}"
    echo -e "   Proxy API: http://${IP}:3000"
    echo -e "   Backend API: http://${IP}:5188"
else
    CONTAINER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    echo -e "   http://${CONTAINER_IP}"
    echo -e "ℹ️  Services:"
    echo -e "   Frontend: http://${CONTAINER_IP}"
    echo -e "   Proxy API: http://${CONTAINER_IP}:3000"
    echo -e "   Backend API: http://${CONTAINER_IP}:5188"
fi
