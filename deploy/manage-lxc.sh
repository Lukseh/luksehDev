#!/bin/bash

# Lukseh.dev LXC Management Script
# Quick commands for managing the deployed application

CONTAINER_NAME="lukseh-dev"
LXC_USER="lukseh"
APP_DIR="/home/$LXC_USER/lukseh.dev"

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
        lxc list | grep $CONTAINER_NAME
        echo ""
        echo "📊 PM2 Status:"
        lxc exec $CONTAINER_NAME -- su - $LXC_USER -c "pm2 status"
        echo ""
        echo "🌍 Nginx Status:"
        lxc exec $CONTAINER_NAME -- systemctl status nginx --no-pager -l
        ;;
        
    "logs")
        case "$2" in
            "backend")
                log "Backend logs:"
                lxc exec $CONTAINER_NAME -- su - $LXC_USER -c "pm2 logs lukseh-backend --lines 50"
                ;;
            "proxy")
                log "Proxy logs:"
                lxc exec $CONTAINER_NAME -- su - $LXC_USER -c "pm2 logs lukseh-proxy --lines 50"
                ;;
            "nginx")
                log "Nginx logs:"
                lxc exec $CONTAINER_NAME -- tail -50 /var/log/nginx/access.log
                echo "--- ERROR LOG ---"
                lxc exec $CONTAINER_NAME -- tail -50 /var/log/nginx/error.log
                ;;
            "all")
                log "All PM2 logs:"
                lxc exec $CONTAINER_NAME -- su - $LXC_USER -c "pm2 logs --lines 20"
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
                lxc exec $CONTAINER_NAME -- su - $LXC_USER -c "pm2 restart lukseh-backend"
                ;;
            "proxy")
                log "Restarting proxy..."
                lxc exec $CONTAINER_NAME -- su - $LXC_USER -c "pm2 restart lukseh-proxy"
                ;;
            "nginx")
                log "Restarting nginx..."
                lxc exec $CONTAINER_NAME -- systemctl restart nginx
                ;;
            "all")
                log "Restarting all services..."
                lxc exec $CONTAINER_NAME -- su - $LXC_USER -c "pm2 restart all"
                lxc exec $CONTAINER_NAME -- systemctl restart nginx
                ;;
            *)
                log "Available services: backend, proxy, nginx, all"
                ;;
        esac
        ;;
        
    "stop")
        log "Stopping all services..."
        lxc exec $CONTAINER_NAME -- su - $LXC_USER -c "pm2 stop all"
        lxc exec $CONTAINER_NAME -- systemctl stop nginx
        ;;
        
    "start")
        log "Starting all services..."
        lxc exec $CONTAINER_NAME -- su - $LXC_USER -c "pm2 start all"
        lxc exec $CONTAINER_NAME -- systemctl start nginx
        ;;
        
    "shell")
        log "Opening shell in container..."
        lxc exec $CONTAINER_NAME -- su - $LXC_USER
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
                lxc exec $CONTAINER_NAME -- su - $LXC_USER -c "cloudflared tunnel run lukseh-dev-tunnel &"
                ;;
            "stop")
                log "Stopping Cloudflare tunnel..."
                lxc exec $CONTAINER_NAME -- pkill cloudflared
                ;;
            "status")
                log "Tunnel status:"
                lxc exec $CONTAINER_NAME -- ps aux | grep cloudflared
                ;;
            *)
                log "Tunnel commands: start, stop, status"
                ;;
        esac
        ;;
        
    "health")
        log "Health check:"
        echo "🔍 Backend Health:"
        lxc exec $CONTAINER_NAME -- curl -s http://localhost:5188/health || error "Backend unhealthy"
        echo ""
        echo "🔍 Proxy Health:"
        lxc exec $CONTAINER_NAME -- curl -s http://localhost:3000/health || error "Proxy unhealthy"
        echo ""
        echo "🔍 Frontend Health:"
        lxc exec $CONTAINER_NAME -- curl -s http://localhost:80 | head -5 || error "Frontend unhealthy"
        ;;
        
    *)
        echo "Lukseh.dev LXC Management Script"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  status              - Show service status"
        echo "  logs <service>      - Show logs (backend|proxy|nginx|all)"
        echo "  restart <service>   - Restart service (backend|proxy|nginx|all)"
        echo "  stop                - Stop all services"
        echo "  start               - Start all services"
        echo "  shell               - Open shell in container"
        echo "  tunnel <action>     - Manage Cloudflare tunnel (start|stop|status)"
        echo "  health              - Run health checks"
        echo "  update              - Update application (TBD)"
        echo ""
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 logs backend"
        echo "  $0 restart all"
        echo "  $0 tunnel start"
        ;;
esac
