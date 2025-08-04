#!/usr/bin/env bash

# Copyright (c) 2025 Lukseh
# Author: Lukseh
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Lukseh/luksehDev

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
    curl \
    wget \
    git \
    nginx \
    software-properties-common \
    gnupg2 \
    ca-certificates \
    lsb-release \
    unzip
msg_ok "Installed Dependencies"

msg_info "Installing Node.js 20 LTS"
$STD curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
$STD apt-get install -y nodejs
msg_ok "Installed Node.js $(node --version)"

msg_info "Installing .NET 9.0 SDK"
$STD wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
$STD dpkg -i packages-microsoft-prod.deb
$STD apt-get update
$STD apt-get install -y dotnet-sdk-9.0
$STD rm packages-microsoft-prod.deb
msg_ok "Installed .NET $(dotnet --version)"

msg_info "Installing PM2 Process Manager"
$STD npm install -g pm2
msg_ok "Installed PM2"

msg_info "Creating Application Directory"
mkdir -p /opt/lukseh.dev/{backend,node-proxy,frontend-vue}
msg_ok "Created Application Directory"

msg_info "Downloading Application Source"
cd /tmp
$STD git clone https://github.com/Lukseh/luksehDev.git lukseh-source
cp -r lukseh-source/backend/* /opt/lukseh.dev/backend/
cp -r lukseh-source/node-proxy/* /opt/lukseh.dev/node-proxy/
cp -r lukseh-source/frontend-vue/* /opt/lukseh.dev/frontend-vue/
rm -rf lukseh-source
msg_ok "Downloaded Application Source"

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
$STD curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
$STD dpkg -i cloudflared.deb
rm cloudflared.deb
msg_ok "Installed Cloudflared"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
