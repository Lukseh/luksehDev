#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2025 Lukseh
# Author: Lukseh
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Lukseh/luksehDev

APP="Lukseh.dev Portfolio"
var_tags="${var_tags:-development;portfolio;nodejs;dotnet;vue}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /opt/lukseh.dev ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Updating ${APP}"
    
    # Stop services for update
    systemctl stop pm2-lukseh
    systemctl stop nginx
    
    # Update system packages
    $STD apt-get update
    $STD apt-get -y upgrade
    
    # Update Node.js dependencies
    msg_info "Updating Node.js Dependencies"
    cd /opt/lukseh.dev/node-proxy
    $STD npm update
    
    cd /opt/lukseh.dev/frontend-vue
    $STD npm update
    $STD npm run build
    
    # Update .NET dependencies
    msg_info "Updating .NET Backend"
    cd /opt/lukseh.dev/backend
    $STD dotnet restore
    $STD dotnet build -c Release
    
    # Copy updated frontend to nginx
    rm -rf /var/www/html/*
    cp -r /opt/lukseh.dev/frontend-vue/dist/* /var/www/html/
    
    # Restart services
    systemctl start pm2-lukseh
    systemctl start nginx
    
    msg_ok "Updated ${APP}"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
echo -e "${INFO}${YW} Services:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}Frontend: http://${IP}${CL}"
echo -e "${TAB}${GATEWAY}${BGN}Proxy API: http://${IP}:3000${CL}"
echo -e "${TAB}${GATEWAY}${BGN}Backend API: http://${IP}:5188${CL}"
