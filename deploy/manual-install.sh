#!/usr/bin/env bash

# Simple manual installation for Lukseh.dev Portfolio
set -e

echo "🚀 Installing Lukseh.dev Portfolio"

# Create lukseh user
echo "Creating lukseh user..."
useradd -m -s /bin/bash lukseh 2>/dev/null || echo "User already exists"
usermod -aG sudo lukseh 2>/dev/null || true

# Update system
echo "Updating system..."
apt-get update >/dev/null 2>&1

# Install Node.js 20
echo "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null 2>&1
apt-get install -y nodejs >/dev/null 2>&1

# Install .NET 9
echo "Installing .NET..."
wget -q https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb >/dev/null 2>&1
apt-get update >/dev/null 2>&1
apt-get install -y dotnet-sdk-9.0 >/dev/null 2>&1
rm packages-microsoft-prod.deb

# Install other dependencies
echo "Installing dependencies..."
apt-get install -y git nginx curl wget net-tools >/dev/null 2>&1

# Install PM2
echo "Installing PM2..."
npm install -g pm2 >/dev/null 2>&1

# Create app directory
echo "Setting up application..."
mkdir -p /opt/lukseh.dev
chown lukseh:lukseh /opt/lukseh.dev

# Clone repository
echo "Downloading source code..."
cd /opt/lukseh.dev
sudo -u lukseh git clone https://github.com/Lukseh/luksehDev.git . >/dev/null 2>&1

# Install Node dependencies
echo "Installing Node.js dependencies (this may take a few minutes)..."
cd /opt/lukseh.dev/node-proxy
sudo -u lukseh npm install --production >/dev/null 2>&1

cd /opt/lukseh.dev/frontend-vue
sudo -u lukseh npm install >/dev/null 2>&1

# Build frontend
echo "Building frontend..."
sudo -u lukseh npm run build >/dev/null 2>&1

# Build backend
echo "Building backend..."
cd /opt/lukseh.dev/backend
sudo -u lukseh dotnet restore >/dev/null 2>&1
sudo -u lukseh dotnet build -c Release >/dev/null 2>&1

# Configure nginx
echo "Configuring web server..."
rm -rf /var/www/html/*
cp -r /opt/lukseh.dev/frontend-vue/dist/* /var/www/html/

# Configure nginx
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    server_name _;
    root /var/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# Start PM2 services
echo "Starting services..."
sudo -u lukseh mkdir -p /home/lukseh/.pm2
cd /opt/lukseh.dev

# Start backend
sudo -u lukseh pm2 start "dotnet run --configuration Release --urls http://0.0.0.0:5188" --name "backend" --cwd "/opt/lukseh.dev/backend"

# Start proxy
sudo -u lukseh pm2 start "node server.js" --name "proxy" --cwd "/opt/lukseh.dev/node-proxy"

# Save PM2 config
sudo -u lukseh pm2 save

# Configure PM2 startup
sudo -u lukseh pm2 startup systemd -u lukseh --hp /home/lukseh | grep "sudo" | bash

# Start nginx
systemctl enable nginx
systemctl restart nginx

echo ""
echo "✅ Installation completed!"
echo ""
echo "Your portfolio should be accessible at:"
IP=$(hostname -I | awk '{print $1}')
echo "Frontend: http://$IP"
echo "Proxy API: http://$IP:3000"
echo "Backend API: http://$IP:5188"
echo ""
echo "Services status:"
sudo -u lukseh pm2 list
