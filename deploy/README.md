# Lukseh.dev Container Deployment

This directory contains deployment files for the Lukseh.dev portfolio supporting multiple container platforms:
- **Proxmox VE Containers** (recommended for PVE hosts)
- **LXC/LXD Containers** (for Ubuntu/other Linux hosts)
- **Docker Containers** (universal containerization)

## 🚀 Quick Deployment

### For Proxmox VE (PVE)
```bash
# Make deployment script executable
chmod +x deploy/deploy-pve.sh deploy/manage-pve.sh

# Run the deployment
cd deploy
./deploy-pve.sh
```

### For LXC/LXD
```bash
# Make deployment script executable
chmod +x deploy/deploy-lxc.sh deploy/manage-lxc.sh

# Run the deployment
cd deploy
./deploy-lxc.sh
```

## 📁 Deployment Files

### Core Deployment
- `deploy-pve.sh` - Proxmox VE deployment script
- `manage-pve.sh` - Proxmox VE management script
- `deploy-lxc.sh` - LXC/LXD deployment script
- `manage-lxc.sh` - LXC/LXD management script
- `docker-compose.yml` - Docker deployment

### Application Configuration
- `Dockerfile.backend` - .NET backend container
- `Dockerfile.proxy` - Node.js proxy container  
- `Dockerfile.frontend` - Vue.js frontend with Nginx
- `cloudflared-config.yml` - Argo Tunnel configuration

### Production Settings
- `../backend/appsettings.Production.json` - Backend production config
- `../frontend-vue/nginx.conf` - Nginx configuration for SPA

## 🏗️ Architecture

```
Internet
    ↓ (Argo Tunnel)
Proxmox VE Container / LXC Container
    ├── Nginx (Port 80) → Vue.js SPA
    ├── Node Proxy (Port 3000) → API Gateway  
    └── .NET Backend (Port 5188) → GitHub/LinkedIn APIs
```

## 📋 Prerequisites

### For Proxmox VE
```bash
# Create Ubuntu 22.04 container
pct create 100 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname lukseh-dev \
  --memory 2048 \
  --cores 2 \
  --rootfs local-lvm:8 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --start

# Configure container (optional)
pct set 100 --memory 4096
pct set 100 --cores 4
```

### For LXC/LXD
```bash
# Create Ubuntu 22.04 LXC container
lxc launch ubuntu:22.04 lukseh-dev

# Configure container (optional)
lxc config set lukseh-dev limits.cpu 2
lxc config set lukseh-dev limits.memory 2GB
```

### Required on Host
- **Proxmox VE**: PVE host with container template
- **LXC/LXD**: LXC/LXD installed and configured
- Access to container management
- Cloudflare account (for Argo Tunnel)

## 🔧 Deployment Process

### 1. Automatic Setup
The deployment scripts handle:
- ✅ Container environment setup (Node.js, .NET, Nginx)
- ✅ Application file deployment
- ✅ Service building and configuration
- ✅ PM2 process management setup
- ✅ Nginx configuration for SPA routing
- ✅ Cloudflared installation

### 2. Manual Steps Required
After deployment, you need to:

#### For Proxmox VE:
```bash
# 1. Authenticate Cloudflare tunnel
pct exec 100 -- cloudflared tunnel login

# 2. Create tunnel
pct exec 100 -- cloudflared tunnel create lukseh-dev-tunnel

# 3. Copy config file
pct push 100 cloudflared-config.yml /home/lukseh/.cloudflared/config.yml

# 4. Start tunnel
pct exec 100 -- cloudflared tunnel run lukseh-dev-tunnel
```

#### For LXC/LXD:
```bash
# 1. Authenticate Cloudflare tunnel
lxc exec lukseh-dev -- cloudflared tunnel login

# 2. Create tunnel
lxc exec lukseh-dev -- cloudflared tunnel create lukseh-dev-tunnel

# 3. Copy config file
lxc file push cloudflared-config.yml lukseh-dev/home/lukseh/.cloudflared/config.yml

# 4. Start tunnel
lxc exec lukseh-dev -- cloudflared tunnel run lukseh-dev-tunnel
```

### 3. DNS Configuration
Point your domain to the Argo Tunnel:
- `lukseh.dev` → Cloudflare tunnel
- `api.lukseh.dev` → Cloudflare tunnel (optional subdomain)

## 🎛️ Service Management

### For Proxmox VE:
```bash
# Check service status
./manage-pve.sh status

# View logs
./manage-pve.sh logs backend
./manage-pve.sh logs proxy
./manage-pve.sh logs nginx

# Restart services
./manage-pve.sh restart all
./manage-pve.sh restart backend

# Health checks
./manage-pve.sh health

# Manage tunnel
./manage-pve.sh tunnel start
./manage-pve.sh tunnel stop

# Open container shell
./manage-pve.sh shell

# Container backup
./manage-pve.sh backup
```

### For LXC/LXD:
```bash
# Check service status
./manage-lxc.sh status

# View logs
./manage-lxc.sh logs backend
./manage-lxc.sh logs proxy
./manage-lxc.sh logs nginx

# Restart services
./manage-lxc.sh restart all
./manage-lxc.sh restart backend

# Health checks
./manage-lxc.sh health

# Manage tunnel
./manage-lxc.sh tunnel start
./manage-lxc.sh tunnel stop

# Open container shell
./manage-lxc.sh shell
```

## 🌐 Service URLs

### Inside Container
- **Frontend**: http://localhost:80
- **Proxy**: http://localhost:3000  
- **Backend**: http://localhost:5188
- **Health Checks**: `/health` endpoints

### External (via Argo Tunnel)
- **Main Site**: https://lukseh.dev
- **API**: https://api.lukseh.dev (optional)

## 🔍 Troubleshooting

### Service Issues
```bash
# Check PM2 processes
lxc exec lukseh-dev -- su - lukseh -c "pm2 status"

# Check Nginx status  
lxc exec lukseh-dev -- systemctl status nginx

# View detailed logs
./manage-lxc.sh logs all
```

### Network Issues
```bash
# Test internal connectivity
lxc exec lukseh-dev -- curl http://localhost:5188/health
lxc exec lukseh-dev -- curl http://localhost:3000/health

# Check port bindings
lxc exec lukseh-dev -- netstat -tlnp
```

### Argo Tunnel Issues
```bash
# Check tunnel status
./manage-lxc.sh tunnel status

# View tunnel logs
lxc exec lukseh-dev -- journalctl -u cloudflared -f
```

## 🔒 Security Notes

- Services run as non-root user `lukseh`
- Nginx handles static file serving
- CORS properly configured for API access
- Security headers added in Nginx config
- Production environment variables used

## 🚀 Production Checklist

- [ ] LXC container created and running
- [ ] Deployment script executed successfully  
- [ ] All services running (PM2 + Nginx)
- [ ] API keys configured in production settings
- [ ] Cloudflare tunnel authenticated and configured
- [ ] DNS records pointing to tunnel
- [ ] SSL/TLS certificates active
- [ ] Health checks passing
- [ ] Monitoring and logging configured

## 📊 Monitoring

### Service Health
```bash
# Continuous monitoring
watch ./manage-lxc.sh health

# Log monitoring
./manage-lxc.sh logs all | grep ERROR
```

### Performance
- PM2 provides built-in monitoring: `pm2 monit`
- Nginx access logs for traffic analysis
- Backend health endpoint for API status

## 🔄 Updates and Maintenance

### Application Updates
1. Pull latest code changes
2. Run deployment script again
3. Services will be rebuilt and restarted automatically

### System Updates
```bash
# Update container packages
lxc exec lukseh-dev -- apt update && apt upgrade -y

# Update Node.js dependencies
lxc exec lukseh-dev --cwd $APP_DIR/node-proxy -- npm update
lxc exec lukseh-dev --cwd $APP_DIR/frontend-vue -- npm update
```
