#!/bin/bash

# Lukseh.dev Proxmox VE Container Deployment Script
# This script deploys the full-stack application to a Proxmox VE container

set -e

echo "🚀 Starting Lukseh.dev Proxmox VE Deployment..."

# Configuration
CONTAINER_ID="100"  # Change this to your container ID
CONTAINER_NAME="lukseh-dev"
PVE_USER="lukseh"
APP_DIR="/home/$PVE_USER/lukseh.dev"
DOMAIN="lukseh.dev"
TUNNEL_NAME="lukseh-dev-tunnel"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Proxmox container exists and is running
check_container() {
    log "Checking Proxmox container status..."
    
    if ! pct list | grep -q "$CONTAINER_ID"; then
        error "Proxmox container '$CONTAINER_ID' not found!"
        echo "Create it with:"
        echo "  pct create $CONTAINER_ID local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst --hostname $CONTAINER_NAME --memory 2048 --cores 2 --rootfs local-lvm:8 --net0 name=eth0,bridge=vmbr0,ip=dhcp --start"
        exit 1
    fi
    
    if ! pct status $CONTAINER_ID | grep -q "running"; then
        log "Starting Proxmox container..."
        pct start $CONTAINER_ID
        sleep 10
    fi
    
    log "Container '$CONTAINER_ID' ($CONTAINER_NAME) is running"
}

# Function to setup the container environment
setup_container() {
    log "Setting up container environment..."
    
    # Update system and install prerequisites
    pct exec $CONTAINER_ID -- apt-get update
    pct exec $CONTAINER_ID -- apt-get install -y curl wget git nginx software-properties-common
    
    # Install Node.js 20 (LTS)
    pct exec $CONTAINER_ID -- curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    pct exec $CONTAINER_ID -- apt-get install -y nodejs
    
    # Install .NET 9.0
    pct exec $CONTAINER_ID -- wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    pct exec $CONTAINER_ID -- dpkg -i packages-microsoft-prod.deb
    pct exec $CONTAINER_ID -- apt-get update
    pct exec $CONTAINER_ID -- apt-get install -y dotnet-sdk-9.0
    
    # Install PM2 for process management
    pct exec $CONTAINER_ID -- npm install -g pm2
    
    # Create user if not exists
    pct exec $CONTAINER_ID -- id -u $PVE_USER || pct exec $CONTAINER_ID -- useradd -m -s /bin/bash $PVE_USER
    
    # Add user to sudo group (optional)
    pct exec $CONTAINER_ID -- usermod -aG sudo $PVE_USER
    
    log "Container environment setup complete"
}

# Function to deploy application files
deploy_app() {
    log "Deploying application files..."
    
    # Remove old deployment
    pct exec $CONTAINER_ID -- rm -rf $APP_DIR
    pct exec $CONTAINER_ID -- mkdir -p $APP_DIR
    
    # Copy project files using tar to preserve permissions
    tar -czf /tmp/lukseh-app.tar.gz -C .. backend node-proxy frontend-vue package.json 2>/dev/null || true
    pct push $CONTAINER_ID /tmp/lukseh-app.tar.gz /tmp/lukseh-app.tar.gz
    pct exec $CONTAINER_ID -- tar -xzf /tmp/lukseh-app.tar.gz -C $APP_DIR
    pct exec $CONTAINER_ID -- rm /tmp/lukseh-app.tar.gz
    rm /tmp/lukseh-app.tar.gz
    
    # Set ownership
    pct exec $CONTAINER_ID -- chown -R $PVE_USER:$PVE_USER $APP_DIR
    
    log "Application files deployed"
}

# Function to build and setup services
setup_services() {
    log "Building and setting up services..."
    
    # Build .NET backend
    log "Building .NET backend..."
    pct exec $CONTAINER_ID -- bash -c "cd $APP_DIR/backend && dotnet restore"
    pct exec $CONTAINER_ID -- bash -c "cd $APP_DIR/backend && dotnet build -c Release"
    
    # Install Node.js dependencies for proxy
    log "Installing proxy dependencies..."
    pct exec $CONTAINER_ID -- bash -c "cd $APP_DIR/node-proxy && npm install --production"
    
    # Build Vue.js frontend
    log "Building Vue.js frontend..."
    pct exec $CONTAINER_ID -- bash -c "cd $APP_DIR/frontend-vue && npm install"
    pct exec $CONTAINER_ID -- bash -c "cd $APP_DIR/frontend-vue && npm run build"
    
    # Setup Nginx for frontend
    log "Setting up Nginx..."
    pct push $CONTAINER_ID ../frontend-vue/nginx.conf /etc/nginx/sites-available/lukseh.dev
    pct exec $CONTAINER_ID -- ln -sf /etc/nginx/sites-available/lukseh.dev /etc/nginx/sites-enabled/
    pct exec $CONTAINER_ID -- rm -f /etc/nginx/sites-enabled/default
    
    # Copy built frontend to nginx directory
    pct exec $CONTAINER_ID -- rm -rf /var/www/html/*
    pct exec $CONTAINER_ID -- cp -r $APP_DIR/frontend-vue/dist/* /var/www/html/
    
    log "Services setup complete"
}

# Function to setup PM2 ecosystem
setup_pm2() {
    log "Setting up PM2 ecosystem..."
    
    # Create PM2 ecosystem file
    cat > /tmp/ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: 'lukseh-backend',
      cwd: '$APP_DIR/backend',
      script: 'dotnet',
      args: 'run --urls http://0.0.0.0:5188',
      env: {
        ASPNETCORE_ENVIRONMENT: 'Production',
        ASPNETCORE_URLS: 'http://0.0.0.0:5188'
      },
      restart_delay: 1000,
      max_restarts: 10
    },
    {
      name: 'lukseh-proxy',
      cwd: '$APP_DIR/node-proxy',
      script: 'server.js',
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
        BACKEND_URL: 'http://localhost:5188'
      },
      restart_delay: 1000,
      max_restarts: 10
    }
  ]
};
EOF
    
    pct push $CONTAINER_ID /tmp/ecosystem.config.js $APP_DIR/ecosystem.config.js
    pct exec $CONTAINER_ID -- bash -c "cd $APP_DIR && chown $PVE_USER:$PVE_USER ecosystem.config.js"
    rm /tmp/ecosystem.config.js
    
    log "PM2 ecosystem configured"
}

# Function to start services
start_services() {
    log "Starting services..."
    
    # Start PM2 services as the lukseh user
    pct exec $CONTAINER_ID -- bash -c "cd $APP_DIR && su - $PVE_USER -c 'pm2 start ecosystem.config.js'"
    pct exec $CONTAINER_ID -- su - $PVE_USER -c "pm2 save"
    pct exec $CONTAINER_ID -- su - $PVE_USER -c "pm2 startup systemd -u $PVE_USER --hp /home/$PVE_USER" || true
    
    # Start Nginx
    pct exec $CONTAINER_ID -- systemctl enable nginx
    pct exec $CONTAINER_ID -- systemctl restart nginx
    
    log "Services started successfully"
}

# Function to setup Argo Tunnel
setup_argo_tunnel() {
    log "Setting up Argo Tunnel..."
    
    # Install cloudflared
    pct exec $CONTAINER_ID -- curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    pct exec $CONTAINER_ID -- dpkg -i cloudflared.deb
    
    warn "Manual step required:"
    echo "1. Run this command in the container to authenticate:"
    echo "   pct exec $CONTAINER_ID -- cloudflared tunnel login"
    echo "2. Create tunnel:"
    echo "   pct exec $CONTAINER_ID -- cloudflared tunnel create $TUNNEL_NAME"
    echo "3. Copy config file:"
    echo "   pct push $CONTAINER_ID cloudflared-config.yml /home/$PVE_USER/.cloudflared/config.yml"
    echo "4. Run tunnel:"
    echo "   pct exec $CONTAINER_ID -- cloudflared tunnel run $TUNNEL_NAME"
    
    log "Argo Tunnel setup initiated"
}

# Function to display status
show_status() {
    log "Deployment Status:"
    echo ""
    echo "🌐 Container: $CONTAINER_ID ($CONTAINER_NAME)"
    echo "🏠 App Directory: $APP_DIR"
    echo "👤 User: $PVE_USER"
    echo ""
    echo "📊 Service Status:"
    pct exec $CONTAINER_ID -- su - $PVE_USER -c "pm2 status" || warn "PM2 not running"
    echo ""
    echo "🌍 Nginx Status:"
    pct exec $CONTAINER_ID -- systemctl is-active nginx || warn "Nginx not running"
    echo ""
    echo "🔗 Access URLs (inside container):"
    echo "   Frontend: http://localhost:80"
    echo "   Proxy:    http://localhost:3000"
    echo "   Backend:  http://localhost:5188"
    echo ""
    echo "📝 Logs:"
    echo "   PM2 logs:   pct exec $CONTAINER_ID -- su - $PVE_USER -c 'pm2 logs'"
    echo "   Nginx logs: pct exec $CONTAINER_ID -- tail -f /var/log/nginx/error.log"
    echo ""
    echo "🔧 Container IP:"
    pct exec $CONTAINER_ID -- hostname -I | head -1
}

# Main deployment flow
main() {
    log "🚀 Lukseh.dev Proxmox VE Deployment Started"
    
    check_container
    setup_container
    deploy_app
    setup_services
    setup_pm2
    start_services
    setup_argo_tunnel
    
    echo ""
    log "✅ Deployment completed successfully!"
    show_status
    
    echo ""
    log "🔧 Next steps:"
    echo "1. Configure Argo Tunnel authentication"
    echo "2. Set up domain DNS records"
    echo "3. Configure SSL certificates"
    echo "4. Test the application"
}

# Run deployment
main "$@"
