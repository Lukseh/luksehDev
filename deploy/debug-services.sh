#!/usr/bin/env bash

# Lukseh.dev Portfolio Debug and Fix Script
set -e

echo "🔍 Debugging Lukseh.dev Portfolio Services"

# Check if services are running
echo ""
echo "=== Service Status ==="
echo "PM2 Services:"
sudo -u lukseh pm2 list || echo "PM2 not running"

echo ""
echo "Nginx Status:"
systemctl status nginx --no-pager -l || echo "Nginx not running"

echo ""
echo "=== Port Status ==="
echo "Checking if ports are listening:"
netstat -tlnp | grep -E ":(80|3000|5188)" || echo "No services listening on expected ports"

echo ""
echo "=== Process Check ==="
echo "Node.js processes:"
ps aux | grep node | grep -v grep || echo "No Node.js processes"

echo ""
echo "Dotnet processes:"
ps aux | grep dotnet | grep -v grep || echo "No .NET processes"

echo ""
echo "=== Service Logs ==="
echo "PM2 Logs (last 20 lines):"
sudo -u lukseh pm2 logs --lines 20 || echo "No PM2 logs"

echo ""
echo "=== Testing Connectivity ==="
echo "Testing backend directly:"
curl -s http://localhost:5188/health || echo "Backend not responding"

echo ""
echo "Testing proxy:"
curl -s http://localhost:3000/health || echo "Proxy not responding"

echo ""
echo "Testing nginx:"
curl -s http://localhost/ | head -5 || echo "Nginx not serving content"

echo ""
echo "=== Fix Attempt ==="
echo "Restarting services..."

# Stop everything
sudo -u lukseh pm2 stop all >/dev/null 2>&1 || true
systemctl stop nginx >/dev/null 2>&1 || true

# Start backend with verbose logging
echo "Starting backend..."
cd /opt/lukseh.dev/backend
sudo -u lukseh pm2 delete backend >/dev/null 2>&1 || true
sudo -u lukseh pm2 start "dotnet run --configuration Release --urls http://0.0.0.0:5188" --name "backend" --cwd "/opt/lukseh.dev/backend" --log-date-format "YYYY-MM-DD HH:mm:ss"

# Start proxy with verbose logging  
echo "Starting proxy..."
cd /opt/lukseh.dev/node-proxy
sudo -u lukseh pm2 delete proxy >/dev/null 2>&1 || true
sudo -u lukseh pm2 start "node server.js" --name "proxy" --cwd "/opt/lukseh.dev/node-proxy" --log-date-format "YYYY-MM-DD HH:mm:ss"

# Save PM2 config
sudo -u lukseh pm2 save

# Start nginx
echo "Starting nginx..."
systemctl start nginx

echo ""
echo "Waiting for services to start..."
sleep 5

echo ""
echo "=== Post-Fix Status ==="
echo "PM2 Services:"
sudo -u lukseh pm2 list

echo ""
echo "Port check:"
netstat -tlnp | grep -E ":(80|3000|5188)"

echo ""
echo "Testing services:"
echo "Backend health:"
curl -s http://localhost:5188/health || echo "❌ Backend still not responding"

echo "Proxy health:"
curl -s http://localhost:3000/health || echo "❌ Proxy still not responding"

echo "Frontend (nginx):"
curl -s -I http://localhost/ | head -1 || echo "❌ Nginx still not responding"

echo ""
echo "✅ Debug and fix attempt completed"
echo ""
echo "If services are still not working, check the logs with:"
echo "sudo -u lukseh pm2 logs"
