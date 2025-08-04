# Lukseh.dev Portfolio - Proxmox VE Helper Script

Deploy a modern full-stack portfolio website in a Proxmox VE container with Vue.js frontend, Node.js proxy, and .NET backend.

## 🚀 Quick Installation

Run this command in your Proxmox VE shell:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Lukseh/luksehDev/main/deploy/lukseh-dev.sh)
```

## 📋 What This Installs

### Architecture
```
Internet → Nginx (Port 80) → Vue.js SPA
                   ↓
            Node.js Proxy (Port 3000) ← .NET API (Port 5188)
```

### Components
- **Frontend**: Vue.js 3.5.18 + Vuetify 3.9.3 SPA
- **Proxy**: Node.js Express server for CORS handling
- **Backend**: .NET 9.0 Web API with GitHub/LinkedIn integration
- **Web Server**: Nginx with SPA routing and compression
- **Process Manager**: PM2 for service management

### Features
- ✅ GitHub repository showcase with filtering
- ✅ LinkedIn profile integration
- ✅ Responsive Material Design UI
- ✅ Dark theme with modern animations
- ✅ Health monitoring endpoints
- ✅ Automatic service restart on failure
- ✅ Cloudflare Tunnel support (optional)

## 🛠️ Default Container Specifications

- **OS**: Debian 12
- **CPU**: 4 cores
- **RAM**: 4GB
- **Disk**: 16GB
- **Network**: DHCP (bridged)
- **Privileged**: No (unprivileged container)

## 🌐 Access URLs

After installation:
- **Main Site**: `http://CONTAINER_IP`
- **API Proxy**: `http://CONTAINER_IP:3000`
- **Backend API**: `http://CONTAINER_IP:5188`

## 🔧 Post-Installation Configuration

### 1. Add API Keys
Edit the production configuration:
```bash
nano /opt/lukseh.dev/backend/appsettings.Production.json
```

Add your GitHub and LinkedIn API credentials.

### 2. Restart Services
```bash
systemctl restart pm2-lukseh
```

### 3. Optional: Setup Cloudflare Tunnel
```bash
# Authenticate with Cloudflare
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create lukseh-dev-tunnel

# Configure tunnel (create config file)
mkdir -p ~/.cloudflared
nano ~/.cloudflared/config.yml

# Run tunnel
cloudflared tunnel run lukseh-dev-tunnel
```

## 📊 Service Management

### Check Status
```bash
# PM2 processes
sudo -u lukseh pm2 status

# Nginx status
systemctl status nginx

# All services
systemctl status pm2-lukseh nginx
```

### View Logs
```bash
# Application logs
sudo -u lukseh pm2 logs

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

### Restart Services
```bash
# Restart all PM2 apps
sudo -u lukseh pm2 restart all

# Restart specific service
sudo -u lukseh pm2 restart lukseh-backend
sudo -u lukseh pm2 restart lukseh-proxy

# Restart Nginx
systemctl restart nginx
```

## 🔄 Updates

The container includes an update function accessible via:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Lukseh/luksehDev/main/deploy/lukseh-dev.sh) update
```

This will:
- Update system packages
- Update Node.js dependencies
- Rebuild frontend
- Update .NET backend
- Restart services

## 🐛 Troubleshooting

### Common Issues

1. **Services not starting**: Check PM2 status and logs
2. **Frontend not loading**: Verify Nginx configuration and frontend build
3. **API errors**: Check backend configuration and API keys
4. **Network issues**: Verify container IP and port accessibility

### Health Checks
```bash
# Backend health
curl http://localhost:5188/health

# Proxy health
curl http://localhost:3000/health

# Frontend accessibility
curl http://localhost/
```

### Reset Services
```bash
# Stop all services
sudo -u lukseh pm2 stop all
systemctl stop nginx

# Start all services
sudo -u lukseh pm2 start all
systemctl start nginx
```

## 📁 Directory Structure

```
/opt/lukseh.dev/
├── backend/                 # .NET 9.0 Web API
├── node-proxy/             # Express.js proxy server
├── frontend-vue/           # Vue.js source + built dist
└── ecosystem.config.js     # PM2 configuration

/var/www/html/              # Nginx document root (built frontend)
/etc/nginx/sites-available/ # Nginx configuration
```

## 🤝 Contributing

This script follows the [Proxmox VE Helper Scripts](https://github.com/community-scripts/ProxmoxVE) patterns and can be contributed to their repository.

## 📄 License

MIT License - see the [LICENSE](https://github.com/Lukseh/luksehDev/blob/main/LICENSE) file for details.

---

Built with ❤️ for the Proxmox and developer community
