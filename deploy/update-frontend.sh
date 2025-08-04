#!/usr/bin/env bash

echo "🔧 Updating Lukseh.dev Portfolio Frontend"

# Update and rebuild frontend with API URL fix
echo "Updating frontend to use relative API URLs..."
cd /opt/lukseh.dev

# Pull latest changes
sudo -u lukseh git pull origin main >/dev/null 2>&1

# Rebuild frontend
echo "Rebuilding frontend..."
cd /opt/lukseh.dev/frontend-vue
sudo -u lukseh npm run build >/dev/null 2>&1

# Update nginx
echo "Updating web server..."
rm -rf /var/www/html/*
cp -r /opt/lukseh.dev/frontend-vue/dist/* /var/www/html/

# Restart nginx
systemctl restart nginx

echo ""
echo "✅ Frontend updated successfully!"
echo ""
echo "The portfolio now uses relative API URLs and should work correctly"
echo "both locally and through Cloudflare tunnels."
echo ""
IP=$(hostname -I | awk '{print $1}')
echo "Access your portfolio at: http://$IP"
