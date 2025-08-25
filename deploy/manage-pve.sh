#!/bin/bash

# Lukseh.dev Proxmox VE Management Script
# Quick commands for managing the deployed application

CONTAINER_ID="100"  # Change this to your container ID
PVE_USER="lukseh"
APP_DIR="/home/$PVE_USER/lukseh.dev"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

case "$1" in
    "status")
        log "Checking service status..."
        echo "🐳 Container Status:"
        pct status $CONTAINER_ID
        echo ""
        echo "📊 PM2 Status:"
        pct exec $CONTAINER_ID -- su - $PVE_USER -c "pm2 status"
        echo ""
        echo "🌍 Nginx Status:"
        pct exec $CONTAINER_ID -- systemctl status nginx --no-pager -l
        echo ""
        echo "🌐 Container IP:"
        pct exec $CONTAINER_ID -- hostname -I | head -1
        ;;
        
    "logs")
        case "$2" in
            "backend")
                log "Backend logs:"
                pct exec $CONTAINER_ID -- su - $PVE_USER -c "pm2 logs lukseh-backend --lines 50"
                ;;
            "proxy")
                log "Proxy logs:"
                pct exec $CONTAINER_ID -- su - $PVE_USER -c "pm2 logs lukseh-proxy --lines 50"
                ;;
            "nginx")
                log "Nginx logs:"
                pct exec $CONTAINER_ID -- tail -50 /var/log/nginx/access.log
                echo "--- ERROR LOG ---"
                pct exec $CONTAINER_ID -- tail -50 /var/log/nginx/error.log
                ;;
            "all")
                log "All PM2 logs:"
                pct exec $CONTAINER_ID -- su - $PVE_USER -c "pm2 logs --lines 20"
                ;;
            *)
                log "Available log types: backend, proxy, nginx, all"
                ;;
        esac
        ;;
        
    "restart")
        case "$2" in
            "backend")
                log "Restarting backend..."
                pct exec $CONTAINER_ID -- su - $PVE_USER -c "pm2 restart lukseh-backend"
                ;;
            "proxy")
                log "Restarting proxy..."
                pct exec $CONTAINER_ID -- su - $PVE_USER -c "pm2 restart lukseh-proxy"
                ;;
            "nginx")
                log "Restarting nginx..."
                pct exec $CONTAINER_ID -- systemctl restart nginx
                ;;
            "container")
                log "Restarting container..."
                pct restart $CONTAINER_ID
                ;;
            "all")
                log "Restarting all services..."
                pct exec $CONTAINER_ID -- su - $PVE_USER -c "pm2 restart all"
                pct exec $CONTAINER_ID -- systemctl restart nginx
                ;;
            *)
                log "Available services: backend, proxy, nginx, container, all"
                ;;
        esac
        ;;
        
    "stop")
        case "$2" in
            "services")
                log "Stopping all services..."
                pct exec $CONTAINER_ID -- su - $PVE_USER -c "pm2 stop all"
                pct exec $CONTAINER_ID -- systemctl stop nginx
                ;;
            "container")
                log "Stopping container..."
                pct stop $CONTAINER_ID
                ;;
            *)
                log "Stopping all services..."
                pct exec $CONTAINER_ID -- su - $PVE_USER -c "pm2 stop all"
                pct exec $CONTAINER_ID -- systemctl stop nginx
                ;;
        esac
        ;;
        
    "start")
        case "$2" in
            "services")
                log "Starting all services..."
                pct exec $CONTAINER_ID -- su - $PVE_USER -c "pm2 start all"
                pct exec $CONTAINER_ID -- systemctl start nginx
                ;;
            "container")
                log "Starting container..."
                pct start $CONTAINER_ID
                ;;
            *)
                log "Starting all services..."
                pct exec $CONTAINER_ID -- su - $PVE_USER -c "pm2 start all"
                pct exec $CONTAINER_ID -- systemctl start nginx
                ;;
        esac
        ;;
        
    "shell")
        log "Opening shell in container..."
        pct enter $CONTAINER_ID
        ;;
        
    "update")
        log "Updating application..."
        # This would be used for CI/CD updates
        warn "Not implemented yet - run full deployment for now"
        ;;
        
    "tunnel")
        case "$2" in
            "start")
                log "Starting Cloudflare tunnel..."
                pct exec $CONTAINER_ID -- su - $PVE_USER -c "nohup cloudflared tunnel run lukseh-dev-tunnel > /dev/null 2>&1 &"
                ;;
            "stop")
                log "Stopping Cloudflare tunnel..."
                pct exec $CONTAINER_ID -- pkill cloudflared
                ;;
            "status")
                log "Tunnel status:"
                pct exec $CONTAINER_ID -- ps aux | grep cloudflared
                ;;
            "login")
                log "Tunnel login:"
                pct exec $CONTAINER_ID -- cloudflared tunnel login
                ;;
            "create")
                log "Creating tunnel..."
                pct exec $CONTAINER_ID -- cloudflared tunnel create lukseh-dev-tunnel
                ;;
            *)
                log "Tunnel commands: start, stop, status, login, create"
                ;;
        esac
        ;;
        
    "health")
        log "Health check:"
        echo "🔍 Backend Health:"
        pct exec $CONTAINER_ID -- curl -s http://localhost:5188/health || error "Backend unhealthy"
        echo ""
        echo "🔍 Proxy Health:"
        pct exec $CONTAINER_ID -- curl -s http://localhost:3000/health || error "Proxy unhealthy"
        echo ""
        echo "🔍 Frontend Health:"
        pct exec $CONTAINER_ID -- curl -s http://localhost:80 | head -5 || error "Frontend unhealthy"
        ;;
        
    "ip")
        log "Container network info:"
        echo "🌐 IP Address:"
        pct exec $CONTAINER_ID -- hostname -I
        echo "🔗 Network interfaces:"
        pct exec $CONTAINER_ID -- ip addr show eth0
        ;;
        
    "backup")
        log "Creating container backup..."
        vzdump $CONTAINER_ID --storage local --compress gzip
        ;;
        
    *)
        echo "Lukseh.dev Proxmox VE Management Script"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  status              - Show service status"
        echo "  logs <service>      - Show logs (backend|proxy|nginx|all)"
        echo "  restart <service>   - Restart service (backend|proxy|nginx|container|all)"
        echo "  stop [target]       - Stop services or container"
        echo "  start [target]      - Start services or container"
        echo "  shell               - Open shell in container"
        echo "  tunnel <action>     - Manage Cloudflare tunnel (start|stop|status|login|create)"
        echo "  health              - Run health checks"
        echo "  ip                  - Show container network info"
        echo "  backup              - Create container backup"
        echo "  update              - Update application (TBD)"
        echo ""
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 logs backend"
        echo "  $0 restart all"
        echo "  $0 tunnel start"
        echo "  $0 shell"
        echo "  $0 backup"
        ;;
esac
