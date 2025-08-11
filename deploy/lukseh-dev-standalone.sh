#!/usr/bin/env bash

# Lukseh.dev Portfolio - Standalone Proxmox VE Deployment Script
# Copyright (c) 2025 Lukseh
# License: MIT
# Source: https://github.com/Lukseh/luksehDev

set -e

# Configuration
APP_NAME="Lukseh.dev Portfolio"
CTID="${1:-100}"
HOSTNAME="lukseh-dev"
MEMORY="${2:-4096}"
CORES="${3:-4}"
DISK="${4:-16}"
USER="lukseh"
APP_DIR="/opt/lukseh.dev"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

info "Starting ${APP_NAME} deployment in container ${CTID}"

# Check if container exists
if ! pct status $CTID &>/dev/null; then
    error "Container $CTID does not exist. Please create it first."
fi

# Check if container is running
if [[ $(pct status $CTID) != *"running"* ]]; then
    info "Starting container $CTID"
    pct start $CTID
    sleep 5
fi

info "Installing system dependencies..."
pct exec $CTID -- bash -c "
    apt-get update
    apt-get install -y curl wget git unzip nginx
    
    # Install Node.js 20.x
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
    
    # Install .NET 8
    wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    dpkg -i packages-microsoft-prod.deb
    apt-get update
    apt-get install -y dotnet-sdk-8.0
    
    # Install PM2 globally
    npm install -g pm2
    
    # Clean up
    rm -f packages-microsoft-prod.deb
    apt-get autoremove -y
"

info "Creating application user..."
pct exec $CTID -- bash -c "
    if ! id '$USER' &>/dev/null; then
        useradd -m -s /bin/bash $USER
        usermod -aG sudo $USER
    fi
"

info "Creating application directory..."
pct exec $CTID -- bash -c "
    mkdir -p $APP_DIR
    chown $USER:$USER $APP_DIR
"

info "Downloading application source..."
pct exec $CTID -- bash -c "
    cd $APP_DIR
    if [[ -d '.git' ]]; then
        sudo -u $USER git pull
    else
        sudo -u $USER git clone https://github.com/Lukseh/luksehDev.git .
    fi
"

info "Installing Node.js dependencies..."
pct exec $CTID -- bash -c "
    cd $APP_DIR/node-proxy
    sudo -u $USER npm install --production
    
    cd $APP_DIR/frontend-vue
    sudo -u $USER npm install
    sudo -u $USER npm run build
"

info "Building .NET backend..."
pct exec $CTID -- bash -c "
    cd $APP_DIR/backend
    sudo -u $USER dotnet restore
    sudo -u $USER dotnet build -c Release
"

info "Configuring Nginx..."
pct exec $CTID -- bash -c "
    # Copy frontend dist to nginx
    rm -rf /var/www/html/*
    cp -r $APP_DIR/frontend-vue/dist/* /var/www/html/
    
    # Copy nginx configuration
    cp $APP_DIR/frontend-vue/nginx.conf /etc/nginx/sites-available/default
    
    # Test nginx config
    nginx -t
"

info "Setting up PM2 services..."
pct exec $CTID -- bash -c "
    sudo -u $USER bash -c '
        cd $APP_DIR
        
        # Start backend
        cd backend
        pm2 start \"dotnet run --configuration Release\" --name \"backend\" --cwd \"$APP_DIR/backend\"
        
        # Start proxy
        cd ../node-proxy
        pm2 start \"npm start\" --name \"proxy\" --cwd \"$APP_DIR/node-proxy\"
        
        # Save PM2 configuration
        pm2 save
    '
"

info "Setting up systemd services..."
pct exec $CTID -- bash -c "
    # Setup PM2 to start on boot
    sudo -u $USER pm2 startup systemd -u $USER --hp /home/$USER
    
    # Enable and start nginx
    systemctl enable nginx
    systemctl restart nginx
"

info "Verifying services..."
pct exec $CTID -- bash -c "
    sleep 5
    
    # Check services
    systemctl is-active nginx || echo 'Nginx not running'
    sudo -u $USER pm2 list
    
    # Test endpoints
    curl -f http://localhost/health || echo 'Frontend health check failed'
    curl -f http://localhost:3000/health || echo 'Proxy health check failed'
    curl -f http://localhost:5188/health || echo 'Backend health check failed'
"

# Get container IP
CONTAINER_IP=$(pct exec $CTID -- hostname -I | awk '{print $1}')

info "Deployment completed successfully!"
echo ""
echo -e "${GREEN}🎉 ${APP_NAME} is now running!${NC}"
echo ""
echo -e "${YELLOW}Access URLs:${NC}"
echo -e "  Frontend:  http://${CONTAINER_IP}"
echo -e "  Proxy API: http://${CONTAINER_IP}:3000"
echo -e "  Backend:   http://${CONTAINER_IP}:5188"
echo ""
echo -e "${YELLOW}Management:${NC}"
echo -e "  Container shell: pct enter ${CTID}"
echo -e "  PM2 status:      pct exec ${CTID} -- sudo -u ${USER} pm2 status"
echo -e "  Nginx status:    pct exec ${CTID} -- systemctl status nginx"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Configure your API keys in backend/appsettings.Production.json"
echo "2. Set up Cloudflare tunnel for external access"
echo "3. Point your domain to the tunnel"
