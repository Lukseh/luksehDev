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

msg_info "Configuring Nginx"
# Copy frontend dist to nginx
rm -rf /var/www/html/*
cp -r /opt/lukseh.dev/frontend-vue/dist/* /var/www/html/

# Copy nginx configuration if it exists
if [[ -f "/opt/lukseh.dev/frontend-vue/nginx.conf" ]]; then
    cp /opt/lukseh.dev/frontend-vue/nginx.conf /etc/nginx/sites-available/default
fi

# Test nginx config
nginx -t >/dev/null 2>&1
msg_ok "Configured Nginx"

msg_info "Setting up PM2 for lukseh user"
# Initialize PM2 directories with correct ownership
sudo -u lukseh mkdir -p /home/lukseh/.pm2/{logs,pids,modules}
sudo -u lukseh touch /home/lukseh/.pm2/{module_conf.json,pm2.log,pm2.pid}

# Start services with PM2 as lukseh user
cd /opt/lukseh.dev
sudo -u lukseh bash -c '
    cd /opt/lukseh.dev/backend
    pm2 start "dotnet run --configuration Release" --name "backend" --cwd "/opt/lukseh.dev/backend"
    
    cd /opt/lukseh.dev/node-proxy  
    pm2 start "npm start" --name "proxy" --cwd "/opt/lukseh.dev/node-proxy"
    
    pm2 save
'
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

msg_info "Installing Backend Dependencies"
cd /opt/lukseh.dev/backend
$STD dotnet restore
$STD dotnet build -c Release
msg_ok "Built .NET Backend"

msg_info "Installing Proxy Dependencies"
cd /opt/lukseh.dev/node-proxy
$STD npm install --production
msg_ok "Installed Proxy Dependencies"

msg_info "Installing Frontend Dependencies"
cd /opt/lukseh.dev/frontend-vue
$STD npm install
$STD npm run build
msg_ok "Built Vue.js Frontend"

msg_info "Configuring Nginx"
cat <<EOF >/etc/nginx/sites-available/lukseh-dev
server {
    listen 80;
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

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Security
    location ~ /\. {
        deny all;
    }
}
EOF

ln -sf /etc/nginx/sites-available/lukseh-dev /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Copy built frontend to nginx directory
rm -rf /var/www/html/*
cp -r /opt/lukseh.dev/frontend-vue/dist/* /var/www/html/
msg_ok "Configured Nginx"

msg_info "Creating PM2 Ecosystem"
cat <<EOF >/opt/lukseh.dev/ecosystem.config.js
module.exports = {
  apps: [
    {
      name: 'lukseh-backend',
      cwd: '/opt/lukseh.dev/backend',
      script: 'dotnet',
      args: 'run --urls http://0.0.0.0:5188',
      env: {
        ASPNETCORE_ENVIRONMENT: 'Production',
        ASPNETCORE_URLS: 'http://0.0.0.0:5188'
      },
      restart_delay: 1000,
      max_restarts: 10,
      min_uptime: '10s'
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
      min_uptime: '10s'
    }
  ]
};
EOF
msg_ok "Created PM2 Ecosystem"

msg_info "Creating Service User"
useradd -r -s /bin/false lukseh || true
chown -R lukseh:lukseh /opt/lukseh.dev
msg_ok "Created Service User"

msg_info "Starting PM2 Services"
cd /opt/lukseh.dev
sudo -u lukseh pm2 start ecosystem.config.js
sudo -u lukseh pm2 save

# Create systemd service for PM2
cat <<EOF >/etc/systemd/system/pm2-lukseh.service
[Unit]
Description=PM2 process manager for Lukseh.dev
After=network.target

[Service]
Type=oneshot
User=lukseh
ExecStart=/usr/bin/pm2 resurrect
ExecStop=/usr/bin/pm2 kill
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable pm2-lukseh
systemctl start pm2-lukseh
msg_ok "Started PM2 Services"

msg_info "Configuring Nginx Service"
systemctl enable nginx
systemctl restart nginx
msg_ok "Started Nginx"

msg_info "Creating Production Configuration Template"
cat <<EOF >/opt/lukseh.dev/backend/appsettings.Production.json
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
chown lukseh:lukseh /opt/lukseh.dev/backend/appsettings.Production.json
msg_ok "Created Configuration Template"

msg_info "Installing Cloudflared (Optional)"
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
echo "Next steps:"
echo "1. Configure API keys in /opt/lukseh.dev/backend/appsettings.Production.json"
echo "2. Set up Cloudflare tunnel: cloudflared tunnel login"
echo "3. Create tunnel: cloudflared tunnel create lukseh-dev-tunnel"
echo "4. Configure DNS in Cloudflare dashboard"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
