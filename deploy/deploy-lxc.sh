#!/bin/bash

# Lukseh.dev LXC Deployment Script
# This script deploys the full-stack application to an LXC container

set -e

echo "🚀 Starting Lukseh.dev LXC Deployment..."

# Configuration
CONTAINER_NAME="lukseh-dev"
LXC_USER="lukseh"
APP_DIR="/home/$LXC_USER/lukseh.dev"
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

# Function to check if LXC container exists and is running
check_container() {
    log "Checking LXC container status..."
    
    if ! lxc list | grep -q "$CONTAINER_NAME"; then
        error "LXC container '$CONTAINER_NAME' not found!"
        echo "Create it with: lxc launch ubuntu:22.04 $CONTAINER_NAME"
        exit 1
    fi
    
    if ! lxc list | grep "$CONTAINER_NAME" | grep -q "RUNNING"; then
        log "Starting LXC container..."
        lxc start $CONTAINER_NAME
        sleep 5
    fi
    
    log "Container '$CONTAINER_NAME' is running"
}

# Function to setup the container environment
setup_container() {
    log "Setting up container environment..."
    
    # Update system and install prerequisites
    lxc exec $CONTAINER_NAME -- apt-get update
    lxc exec $CONTAINER_NAME -- apt-get install -y curl wget git nginx
    
    # Install Node.js 20 (LTS)
    lxc exec $CONTAINER_NAME -- curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    lxc exec $CONTAINER_NAME -- apt-get install -y nodejs
    
    # Install .NET 9.0
    lxc exec $CONTAINER_NAME -- wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    lxc exec $CONTAINER_NAME -- dpkg -i packages-microsoft-prod.deb
    lxc exec $CONTAINER_NAME -- apt-get update
    lxc exec $CONTAINER_NAME -- apt-get install -y dotnet-sdk-9.0
    
    # Install PM2 for process management
    lxc exec $CONTAINER_NAME -- npm install -g pm2
    
    # Create user if not exists
    lxc exec $CONTAINER_NAME -- id -u $LXC_USER || lxc exec $CONTAINER_NAME -- useradd -m -s /bin/bash $LXC_USER
    
    log "Container environment setup complete"
}

# Function to deploy application files
deploy_app() {
    log "Deploying application files..."
    
    # Remove old deployment
    lxc exec $CONTAINER_NAME -- rm -rf $APP_DIR
    lxc exec $CONTAINER_NAME -- mkdir -p $APP_DIR
    
    # Copy project files
    lxc file push -r ../backend $CONTAINER_NAME$APP_DIR/
    lxc file push -r ../node-proxy $CONTAINER_NAME$APP_DIR/
    lxc file push -r ../frontend-vue $CONTAINER_NAME$APP_DIR/
    lxc file push ../package.json $CONTAINER_NAME$APP_DIR/ 2>/dev/null || true
    
    # Set ownership
    lxc exec $CONTAINER_NAME -- chown -R $LXC_USER:$LXC_USER $APP_DIR
    
    log "Application files deployed"
}

# Function to build and setup services
setup_services() {
    log "Building and setting up services..."
    
    # Build .NET backend
    log "Building .NET backend..."
    lxc exec $CONTAINER_NAME --cwd $APP_DIR/backend -- dotnet restore
    lxc exec $CONTAINER_NAME --cwd $APP_DIR/backend -- dotnet build -c Release
    
    # Install Node.js dependencies for proxy
    log "Installing proxy dependencies..."
    lxc exec $CONTAINER_NAME --cwd $APP_DIR/node-proxy -- npm install --production
    
    # Build Vue.js frontend
    log "Building Vue.js frontend..."
    lxc exec $CONTAINER_NAME --cwd $APP_DIR/frontend-vue -- npm install
    lxc exec $CONTAINER_NAME --cwd $APP_DIR/frontend-vue -- npm run build
    
    # Setup Nginx for frontend
    log "Setting up Nginx..."
    lxc file push ../frontend-vue/nginx.conf $CONTAINER_NAME/etc/nginx/sites-available/lukseh.dev
    lxc exec $CONTAINER_NAME -- ln -sf /etc/nginx/sites-available/lukseh.dev /etc/nginx/sites-enabled/
    lxc exec $CONTAINER_NAME -- rm -f /etc/nginx/sites-enabled/default
    
    # Copy built frontend to nginx directory
    lxc exec $CONTAINER_NAME -- rm -rf /var/www/html/*
    lxc exec $CONTAINER_NAME -- cp -r $APP_DIR/frontend-vue/dist/* /var/www/html/
    
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
    
    lxc file push /tmp/ecosystem.config.js $CONTAINER_NAME$APP_DIR/
    lxc exec $CONTAINER_NAME --cwd $APP_DIR -- chown $LXC_USER:$LXC_USER ecosystem.config.js
    
    log "PM2 ecosystem configured"
}

# Function to start services
start_services() {
    log "Starting services..."
    
    # Start PM2 services as the lukseh user
    lxc exec $CONTAINER_NAME --cwd $APP_DIR -- su - $LXC_USER -c "pm2 start ecosystem.config.js"
    lxc exec $CONTAINER_NAME -- su - $LXC_USER -c "pm2 save"
    lxc exec $CONTAINER_NAME -- su - $LXC_USER -c "pm2 startup" || true
    
    # Start Nginx
    lxc exec $CONTAINER_NAME -- systemctl enable nginx
    lxc exec $CONTAINER_NAME -- systemctl restart nginx
    
    log "Services started successfully"
}

# Function to setup Argo Tunnel
setup_argo_tunnel() {
    log "Setting up Argo Tunnel..."
    
    # Install cloudflared
    lxc exec $CONTAINER_NAME -- curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    lxc exec $CONTAINER_NAME -- dpkg -i cloudflared.deb
    
    warn "Manual step required:"
    echo "1. Run this command in the container to authenticate:"
    echo "   lxc exec $CONTAINER_NAME -- cloudflared tunnel login"
    echo "2. Create tunnel:"
    echo "   lxc exec $CONTAINER_NAME -- cloudflared tunnel create $TUNNEL_NAME"
    echo "3. Create config file at ~/.cloudflared/config.yml"
    echo "4. Run tunnel:"
    echo "   lxc exec $CONTAINER_NAME -- cloudflared tunnel run $TUNNEL_NAME"
    
    log "Argo Tunnel setup initiated"
}

# Function to display status
show_status() {
    log "Deployment Status:"
    echo ""
    echo "🌐 Container: $CONTAINER_NAME"
    echo "🏠 App Directory: $APP_DIR"
    echo "👤 User: $LXC_USER"
    echo ""
    echo "📊 Service Status:"
    lxc exec $CONTAINER_NAME -- su - $LXC_USER -c "pm2 status" || warn "PM2 not running"
    echo ""
    echo "🌍 Nginx Status:"
    lxc exec $CONTAINER_NAME -- systemctl is-active nginx || warn "Nginx not running"
    echo ""
    echo "🔗 Access URLs (inside container):"
    echo "   Frontend: http://localhost:80"
    echo "   Proxy:    http://localhost:3000"
    echo "   Backend:  http://localhost:5188"
    echo ""
    echo "📝 Logs:"
    echo "   PM2 logs:   lxc exec $CONTAINER_NAME -- su - $LXC_USER -c 'pm2 logs'"
    echo "   Nginx logs: lxc exec $CONTAINER_NAME -- tail -f /var/log/nginx/error.log"
}

# Main deployment flow
main() {
    log "🚀 Lukseh.dev LXC Deployment Started"
    
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
