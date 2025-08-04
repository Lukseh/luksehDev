#!/usr/bin/env bash

# Lukseh.dev Portfolio Installation Script
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
msg_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
msg_ok() { echo -e "${GREEN}✅ $1${NC}"; }
msg_error() { echo -e "${RED}❌ $1${NC}"; exit 1; }

# Create lukseh user if it doesn't exist
if ! id "lukseh" &>/dev/null; then
    msg_info "Creating lukseh user"
    useradd -m -s /bin/bash lukseh
    usermod -aG sudo lukseh
    msg_ok "Created lukseh user"
fi

msg_info "Installing Dependencies"
apt-get update >/dev/null 2>&1
apt-get install -y \
    curl \
    wget \
    git \
    nginx \
    software-properties-common \
    gnupg2 \
    ca-certificates \
    lsb-release \
    unzip >/dev/null 2>&1
msg_ok "Installed Dependencies"

msg_info "Installing Node.js 20 LTS"
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null 2>&1
apt-get install -y nodejs >/dev/null 2>&1
msg_ok "Installed Node.js $(node --version)"

msg_info "Installing .NET 9.0 SDK"
wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb >/dev/null 2>&1
dpkg -i packages-microsoft-prod.deb >/dev/null 2>&1
apt-get update >/dev/null 2>&1
apt-get install -y dotnet-sdk-9.0 >/dev/null 2>&1
rm packages-microsoft-prod.deb
msg_ok "Installed .NET $(dotnet --version)"

msg_info "Installing PM2 Process Manager"
npm install -g pm2 >/dev/null 2>&1
msg_ok "Installed PM2"

msg_info "Creating Application Directory"
mkdir -p /opt/lukseh.dev
chown lukseh:lukseh /opt/lukseh.dev
msg_ok "Created Application Directory"

msg_info "Downloading Application Source"
cd /opt/lukseh.dev
if [[ -d '.git' ]]; then
    sudo -u lukseh git pull >/dev/null 2>&1
else
    sudo -u lukseh git clone https://github.com/Lukseh/luksehDev.git . >/dev/null 2>&1
fi
msg_ok "Downloaded Application Source"

msg_info "Installing Node.js Dependencies"
cd /opt/lukseh.dev/node-proxy
sudo -u lukseh npm install --production >/dev/null 2>&1
msg_ok "Installed Node.js Proxy Dependencies"

cd /opt/lukseh.dev/frontend-vue
sudo -u lukseh npm install >/dev/null 2>&1
msg_ok "Installed Frontend Dependencies"

msg_info "Building Frontend"
sudo -u lukseh npm run build >/dev/null 2>&1
msg_ok "Built Frontend"

msg_info "Building Backend"
cd /opt/lukseh.dev/backend
sudo -u lukseh dotnet restore >/dev/null 2>&1
sudo -u lukseh dotnet build -c Release >/dev/null 2>&1
msg_ok "Built Backend"

msg_info "Creating Production Configuration"
# Create production appsettings if it doesn't exist
if [[ ! -f "/opt/lukseh.dev/backend/appsettings.Production.json" ]]; then
    sudo -u lukseh cat <<EOF >/opt/lukseh.dev/backend/appsettings.Production.json
{
  "ApiSettings": {
    "GitHubToken": "your_github_token_here",
    "LinkedInAccessToken": "your_linkedin_access_token_here", 
    "LinkedInClientSecret": "your_linkedin_client_secret_here",
    "LinkedInProfileId": "lukseh74"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://0.0.0.0:5188"
      }
    }
  }
}
EOF
fi
msg_ok "Created Production Configuration"

msg_info "Configuring Nginx"
# Copy frontend dist to nginx
rm -rf /var/www/html/*
cp -r /opt/lukseh.dev/frontend-vue/dist/* /var/www/html/

# Create enhanced nginx configuration
cat <<EOF >/etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    root /var/www/html;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Handle Vue Router (SPA)
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # API proxy to Node.js proxy server
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Direct backend access (optional)
    location /direct-api/ {
        rewrite ^/direct-api/(.*) /\$1 break;
        proxy_pass http://localhost:5188;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Security - deny access to hidden files
    location ~ /\. {
        deny all;
    }
}
EOF

# Test nginx config
nginx -t >/dev/null 2>&1
msg_ok "Configured Nginx"

msg_info "Setting up PM2 for lukseh user"
# Initialize PM2 directories with correct ownership
sudo -u lukseh mkdir -p /home/lukseh/.pm2/{logs,pids,modules}
sudo -u lukseh touch /home/lukseh/.pm2/{module_conf.json,pm2.log,pm2.pid}

# Create PM2 ecosystem configuration
sudo -u lukseh cat <<EOF >/opt/lukseh.dev/ecosystem.config.js
module.exports = {
  apps: [
    {
      name: 'lukseh-backend',
      cwd: '/opt/lukseh.dev/backend',
      script: 'dotnet',
      args: 'run --configuration Release --urls http://0.0.0.0:5188',
      env: {
        ASPNETCORE_ENVIRONMENT: 'Production',
        ASPNETCORE_URLS: 'http://0.0.0.0:5188'
      },
      restart_delay: 1000,
      max_restarts: 10,
      min_uptime: '10s',
      instances: 1,
      exec_mode: 'fork'
    },
    {
      name: 'lukseh-proxy',
      cwd: '/opt/lukseh.dev/node-proxy',
      script: 'server.js',
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
        BACKEND_URL: 'http://localhost:5188'
      },
      restart_delay: 1000,
      max_restarts: 10,
      min_uptime: '10s',
      instances: 1,
      exec_mode: 'fork'
    }
  ]
};
EOF

# Start services with PM2 ecosystem
cd /opt/lukseh.dev
sudo -u lukseh pm2 start ecosystem.config.js
sudo -u lukseh pm2 save
msg_ok "Started PM2 Services"

msg_info "Setting up PM2 system service"
# Setup PM2 to start on boot
sudo -u lukseh bash -c 'pm2 startup systemd -u lukseh --hp /home/lukseh' | grep -E '^sudo ' | bash
systemctl enable pm2-lukseh >/dev/null 2>&1
systemctl start pm2-lukseh >/dev/null 2>&1
msg_ok "Configured PM2 System Service"

msg_info "Starting Nginx"
systemctl enable nginx >/dev/null 2>&1
systemctl restart nginx >/dev/null 2>&1
msg_ok "Started Nginx"

msg_info "Installing Cloudflared"
# Download and install cloudflared
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -O cloudflared.deb
dpkg -i cloudflared.deb >/dev/null 2>&1
rm cloudflared.deb
msg_ok "Installed Cloudflared"

msg_info "Cleaning up"
apt-get autoremove -y >/dev/null 2>&1
apt-get autoclean >/dev/null 2>&1
msg_ok "Cleaned up packages"

msg_info "Installation completed successfully!"
echo ""
echo "🎉 Lukseh.dev Portfolio is now running!"
echo ""
echo "Next steps:"
echo "1. Configure API keys in /opt/lukseh.dev/backend/appsettings.Production.json"
echo "2. Set up Cloudflare tunnel: cloudflared tunnel login"
echo "3. Create tunnel: cloudflared tunnel create lukseh-dev-tunnel"
echo "4. Configure DNS in Cloudflare dashboard"
echo ""
echo "Services should be accessible at:"
echo "- Frontend: http://$(hostname -I | awk '{print $1}')"
echo "- Proxy API: http://$(hostname -I | awk '{print $1}'):3000"
echo "- Backend API: http://$(hostname -I | awk '{print $1}'):5188"
