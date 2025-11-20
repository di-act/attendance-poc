#!/bin/bash

# Complete Deployment Script for AWS EC2 Ubuntu Instance
# Attendance Analysis Portal - React + Flask Application
# Author: Auto-generated
# Date: 2025-11-20

set -e  # Exit on error

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration Variables
APP_DIR="/var/www/attendance-analysis"
BACKEND_DIR="/opt/flask-backend"
EC2_USER="ubuntu"  # Change to 'ec2-user' for Amazon Linux
NGINX_CONFIG="/etc/nginx/sites-available/attendance-analysis"
FLASK_SERVICE="/etc/systemd/system/flask-api.service"

# Log function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo "=========================================="
echo "  AWS EC2 Deployment Script"
echo "  Attendance Analysis Portal"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    error "Please do not run this script as root. Run as normal user with sudo privileges."
    exit 1
fi

# Verify required files exist
log "Checking for required files..."
if [ ! -d "/tmp/client-build" ]; then
    warning "React build files not found in /tmp/client-build"
    echo "Please upload files first using:"
    echo "  scp -i your-key.pem -r Client/build/* ubuntu@YOUR_EC2_IP:/tmp/client-build/"
fi

if [ ! -d "/tmp/server" ]; then
    warning "Flask backend files not found in /tmp/server"
    echo "Please upload files first using:"
    echo "  scp -i your-key.pem -r Server/* ubuntu@YOUR_EC2_IP:/tmp/server/"
fi

if [ ! -f "/tmp/nginx.conf" ]; then
    warning "Nginx config not found in /tmp/nginx.conf"
fi

# Ask for confirmation
read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Step 1: Update System
log "Step 1: Updating system packages..."
sudo apt-get update -qq
sudo apt-get upgrade -y -qq
log "System packages updated successfully"

# Step 2: Install Required Software
log "Step 2: Installing required software..."

# Install Node.js
if ! command -v node &> /dev/null; then
    log "Installing Node.js 18.x..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    log "Node.js $(node --version) installed"
else
    log "Node.js already installed: $(node --version)"
fi

# Install Python and pip
if ! command -v python3 &> /dev/null; then
    log "Installing Python..."
    sudo apt-get install -y python3 python3-pip python3-venv
    log "Python $(python3 --version) installed"
else
    log "Python already installed: $(python3 --version)"
fi

# Install Nginx
if ! command -v nginx &> /dev/null; then
    log "Installing Nginx..."
    sudo apt-get install -y nginx
    log "Nginx installed successfully"
else
    log "Nginx already installed"
fi

# Install additional utilities
log "Installing additional utilities..."
sudo apt-get install -y curl wget git ufw -qq

# Step 3: Create Application Directories
log "Step 3: Creating application directories..."
sudo mkdir -p $APP_DIR
sudo mkdir -p $BACKEND_DIR
sudo mkdir -p $BACKEND_DIR/uploads
sudo mkdir -p $BACKEND_DIR/output
sudo chown -R $EC2_USER:$EC2_USER $APP_DIR
sudo chown -R $EC2_USER:$EC2_USER $BACKEND_DIR
log "Directories created successfully"

# Step 4: Copy Application Files
log "Step 4: Copying application files..."

if [ -d "/tmp/client-build" ]; then
    log "Copying React build files..."
    sudo cp -r /tmp/client-build/* $APP_DIR/
    sudo chown -R www-data:www-data $APP_DIR
    log "React files copied to $APP_DIR"
else
    error "React build files not found!"
    exit 1
fi

if [ -d "/tmp/server" ]; then
    log "Copying Flask backend files..."
    cp -r /tmp/server/* $BACKEND_DIR/
    log "Flask files copied to $BACKEND_DIR"
else
    error "Flask backend files not found!"
    exit 1
fi

# Step 5: Set Up Python Virtual Environment
log "Step 5: Setting up Python virtual environment..."
cd $BACKEND_DIR

if [ -d "venv" ]; then
    log "Removing existing virtual environment..."
    rm -rf venv
fi

python3 -m venv venv
source venv/bin/activate

log "Installing Python dependencies..."
pip install --upgrade pip -q
pip install -r requirements.txt -q

log "Python dependencies installed successfully"
deactivate

# Step 6: Configure Nginx
log "Step 6: Configuring Nginx..."

if [ -f "/tmp/nginx.conf" ]; then
    sudo cp /tmp/nginx.conf $NGINX_CONFIG
    log "Nginx configuration copied"
else
    log "Creating default Nginx configuration..."
    cat << 'NGINX_EOF' | sudo tee $NGINX_CONFIG > /dev/null
server {
    listen 80;
    server_name _;

    root /var/www/attendance-analysis;
    index index.html;

    # Serve static files
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Proxy API requests to Flask
    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript application/json;

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    client_max_body_size 20M;
}
NGINX_EOF
fi

# Enable site
sudo ln -sf $NGINX_CONFIG /etc/nginx/sites-enabled/attendance-analysis
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
if sudo nginx -t; then
    log "Nginx configuration is valid"
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    log "Nginx restarted and enabled"
else
    error "Nginx configuration test failed!"
    exit 1
fi

# Step 7: Set Up Flask as Systemd Service
log "Step 7: Setting up Flask as systemd service..."

cat << EOF | sudo tee $FLASK_SERVICE > /dev/null
[Unit]
Description=Flask API for Attendance Analysis
After=network.target

[Service]
Type=notify
User=$EC2_USER
WorkingDirectory=$BACKEND_DIR
Environment="PATH=$BACKEND_DIR/venv/bin"
ExecStart=$BACKEND_DIR/venv/bin/gunicorn --config gunicorn_config.py wsgi:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

log "Flask service configuration created"

# Step 8: Start Flask Service
log "Step 8: Starting Flask service..."
sudo systemctl daemon-reload
sudo systemctl enable flask-api
sudo systemctl restart flask-api

# Wait for service to start
sleep 3

if sudo systemctl is-active --quiet flask-api; then
    log "Flask service started successfully"
else
    error "Flask service failed to start"
    sudo journalctl -u flask-api -n 20
    exit 1
fi

# Step 9: Configure Firewall
log "Step 9: Configuring firewall..."
sudo ufw --force enable
sudo ufw allow 'Nginx Full'
sudo ufw allow 22/tcp
sudo ufw allow 5000/tcp
log "Firewall configured"

# Step 10: Set Correct Permissions
log "Step 10: Setting correct permissions..."
sudo chown -R www-data:www-data $APP_DIR
sudo chmod -R 755 $APP_DIR
sudo chown -R $EC2_USER:$EC2_USER $BACKEND_DIR
sudo chmod -R 755 $BACKEND_DIR
sudo chmod -R 777 $BACKEND_DIR/uploads
sudo chmod -R 777 $BACKEND_DIR/output
log "Permissions set correctly"

# Step 11: Clean up temporary files
log "Step 11: Cleaning up temporary files..."
rm -rf /tmp/client-build
rm -rf /tmp/server
rm -f /tmp/nginx.conf
log "Temporary files cleaned up"

# Step 12: Verify Deployment
log "Step 12: Verifying deployment..."

# Check Nginx status
if sudo systemctl is-active --quiet nginx; then
    log "✓ Nginx is running"
else
    error "✗ Nginx is not running"
fi

# Check Flask service status
if sudo systemctl is-active --quiet flask-api; then
    log "✓ Flask API is running"
else
    error "✗ Flask API is not running"
fi

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo ""
echo "=========================================="
echo "  Deployment Complete!"
echo "=========================================="
echo ""
echo "Your application is now accessible at:"
echo "  http://$PUBLIC_IP"
echo ""
echo "Service Status:"
echo "  Nginx:     $(sudo systemctl is-active nginx)"
echo "  Flask API: $(sudo systemctl is-active flask-api)"
echo ""
echo "Useful Commands:"
echo "  Check Nginx status:     sudo systemctl status nginx"
echo "  Check Flask status:     sudo systemctl status flask-api"
echo "  View Nginx logs:        sudo tail -f /var/log/nginx/access.log"
echo "  View Flask logs:        sudo journalctl -u flask-api -f"
echo "  Restart services:       sudo systemctl restart nginx flask-api"
echo ""
echo "Application Directories:"
echo "  React App:    $APP_DIR"
echo "  Flask API:    $BACKEND_DIR"
echo ""
echo "Next Steps:"
echo "  1. Visit http://$PUBLIC_IP to test the application"
echo "  2. Update DNS records if using a custom domain"
echo "  3. Set up SSL certificate with: sudo certbot --nginx"
echo "  4. Configure automated backups"
echo ""
echo "=========================================="
