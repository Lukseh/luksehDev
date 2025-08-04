# Proxmox VE Quick Setup Guide

## 🚀 Before You Start

1. **Update the Container ID** in the deployment script:
   ```bash
   # Edit deploy-pve.sh and change this line:
   CONTAINER_ID="100"  # Change to your desired container ID
   ```

2. **Download Ubuntu 22.04 template** (if not already available):
   ```bash
   # On Proxmox host
   pveam update
   pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst
   ```

## 📦 Container Creation

Create the container manually or let the script guide you:

```bash
# Manual creation (recommended)
pct create 100 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname lukseh-dev \
  --memory 2048 \
  --cores 2 \
  --rootfs local-lvm:8 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --start

# Wait for container to start, then check IP
pct exec 100 -- hostname -I
```

## ⚡ Deployment

```bash
# 1. Make script executable
chmod +x deploy-pve.sh manage-pve.sh

# 2. Run deployment
./deploy-pve.sh

# 3. Check status
./manage-pve.sh status

# 4. Get container IP
./manage-pve.sh ip
```

## 🌐 Cloudflare Tunnel Setup

```bash
# 1. Login to Cloudflare
./manage-pve.sh tunnel login

# 2. Create tunnel
./manage-pve.sh tunnel create

# 3. Copy config file
pct push 100 cloudflared-config.yml /home/lukseh/.cloudflared/config.yml

# 4. Start tunnel
./manage-pve.sh tunnel start

# 5. Check tunnel status
./manage-pve.sh tunnel status
```

## 🔧 Common Commands

```bash
# Container management
pct start 100          # Start container
pct stop 100           # Stop container
pct restart 100        # Restart container
pct enter 100          # Enter container shell

# Service management
./manage-pve.sh status     # Check all services
./manage-pve.sh health     # Health check
./manage-pve.sh logs all   # View all logs
./manage-pve.sh restart all # Restart all services

# Backup
./manage-pve.sh backup     # Create backup
```

## 🌍 Access URLs

Once deployed, access via:
- **Container IP**: `http://CONTAINER_IP`
- **Argo Tunnel**: `https://lukseh.dev` (after DNS setup)

## 🐛 Troubleshooting

```bash
# Check container status
pct status 100

# View container resources
pct config 100

# Container console
pct console 100

# Service logs
./manage-pve.sh logs backend
./manage-pve.sh logs proxy
./manage-pve.sh logs nginx

# Network check
pct exec 100 -- ip addr
pct exec 100 -- netstat -tlnp
```
