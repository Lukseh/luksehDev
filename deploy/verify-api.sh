#!/usr/bin/env bash

echo "🔍 Verifying Lukseh.dev Portfolio API"
echo ""

# Check if running on container
IP=$(hostname -I | awk '{print $1}' | tr -d ' ')
echo "Server IP: $IP"
echo ""

# Test all endpoints
echo "=== Testing API Endpoints ==="

echo "1. Backend Health:"
curl -s http://localhost:5188/health || echo "❌ Backend not responding"
echo ""

echo "2. Proxy Health:"
curl -s http://localhost:3000/health | jq . 2>/dev/null || curl -s http://localhost:3000/health
echo ""

echo "3. GitHub API via Proxy:"
curl -s http://localhost:3000/api/social/lukseh | jq . 2>/dev/null || curl -s http://localhost:3000/api/social/lukseh
echo ""

echo "4. LinkedIn API via Proxy:"
curl -s http://localhost:3000/api/social/linkedin | jq . 2>/dev/null || curl -s http://localhost:3000/api/social/linkedin
echo ""

echo "5. Frontend via Nginx:"
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost/
echo ""

echo "=== Port Status ==="
echo "Listening ports:"
netstat -tlnp | grep -E ':(80|3000|5188)' || echo "No ports found (netstat may not be installed)"
echo ""

echo "=== Process Status ==="
echo "PM2 Services:"
sudo -u lukseh pm2 list --no-color
echo ""

echo "✅ Verification completed!"
echo ""
echo "If GitHub/LinkedIn APIs show data, your portfolio is fully functional!"
echo "Access your portfolio at: http://$IP"
