#!/bin/bash

# Flask File Upload API - AWS EC2 Deployment Script
# This script automates the deployment process on Ubuntu EC2 instance

set -e  # Exit on any error

echo "======================================"
echo "Flask API Deployment Script"
echo "======================================"

# Configuration
APP_DIR="/home/ubuntu/file-upload-api"
APP_USER="ubuntu"
SERVICE_NAME="flask-api"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run with sudo: sudo bash deploy.sh"
    exit 1
fi

print_status "Starting deployment process..."

# Update system packages
print_status "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# Install required system packages
print_status "Installing system dependencies..."
apt-get install -y python3 python3-pip python3-venv nginx git curl

# Create application directory
print_status "Setting up application directory..."
if [ ! -d "$APP_DIR" ]; then
    mkdir -p $APP_DIR
    chown $APP_USER:$APP_USER $APP_DIR
fi

# Navigate to app directory
cd $APP_DIR

# Copy application files (assuming files are already uploaded or cloned from git)
print_warning "Make sure your application files are in $APP_DIR"

# Create virtual environment
print_status "Creating Python virtual environment..."
if [ ! -d "$APP_DIR/venv" ]; then
    sudo -u $APP_USER python3 -m venv $APP_DIR/venv
fi

# Activate virtual environment and install dependencies
print_status "Installing Python dependencies..."
sudo -u $APP_USER $APP_DIR/venv/bin/pip install --upgrade pip
sudo -u $APP_USER $APP_DIR/venv/bin/pip install -r $APP_DIR/requirements.txt

# Create required directories
print_status "Creating upload and output directories..."
sudo -u $APP_USER mkdir -p $APP_DIR/uploads
sudo -u $APP_USER mkdir -p $APP_DIR/output

# Set up environment file
print_status "Setting up environment configuration..."
if [ ! -f "$APP_DIR/.env" ]; then
    if [ -f "$APP_DIR/.env.example" ]; then
        sudo -u $APP_USER cp $APP_DIR/.env.example $APP_DIR/.env
        print_warning "Please edit $APP_DIR/.env to configure your settings"
    else
        sudo -u $APP_USER cat > $APP_DIR/.env << EOF
FLASK_ENV=production
FLASK_DEBUG=False
HOST=0.0.0.0
PORT=5000
UPLOAD_FOLDER=uploads
OUTPUT_FOLDER=output
MAX_CONTENT_LENGTH=16777216
WORKERS=4
TIMEOUT=120
EOF
    fi
fi

# Set proper permissions
print_status "Setting file permissions..."
chown -R $APP_USER:www-data $APP_DIR
chmod -R 755 $APP_DIR
chmod -R 775 $APP_DIR/uploads
chmod -R 775 $APP_DIR/output

# Install systemd service
print_status "Installing systemd service..."
if [ -f "$APP_DIR/deployment/flask-api.service" ]; then
    cp $APP_DIR/deployment/flask-api.service /etc/systemd/system/$SERVICE_NAME.service
    systemctl daemon-reload
    systemctl enable $SERVICE_NAME
    systemctl restart $SERVICE_NAME
    print_status "Service installed and started"
else
    print_error "Service file not found at $APP_DIR/deployment/flask-api.service"
    exit 1
fi

# Configure Nginx
print_status "Configuring Nginx..."
if [ -f "$APP_DIR/deployment/nginx.conf" ]; then
    cp $APP_DIR/deployment/nginx.conf /etc/nginx/sites-available/$SERVICE_NAME
    
    # Remove default site if exists
    rm -f /etc/nginx/sites-enabled/default
    
    # Enable our site
    ln -sf /etc/nginx/sites-available/$SERVICE_NAME /etc/nginx/sites-enabled/
    
    # Test Nginx configuration
    nginx -t
    
    # Restart Nginx
    systemctl restart nginx
    systemctl enable nginx
    print_status "Nginx configured and restarted"
else
    print_error "Nginx config file not found at $APP_DIR/deployment/nginx.conf"
    exit 1
fi

# Configure UFW firewall (if enabled)
print_status "Configuring firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 'Nginx Full'
    ufw allow OpenSSH
    print_status "Firewall rules updated"
fi

# Check service status
print_status "Checking service status..."
sleep 2
systemctl status $SERVICE_NAME --no-pager

# Display final information
echo ""
echo "======================================"
print_status "Deployment completed successfully!"
echo "======================================"
echo ""
echo "Service Status:"
echo "  sudo systemctl status $SERVICE_NAME"
echo ""
echo "View Logs:"
echo "  sudo journalctl -u $SERVICE_NAME -f"
echo ""
echo "API Endpoints:"
echo "  Health Check: http://YOUR_EC2_IP/"
echo "  Upload (Disk): http://YOUR_EC2_IP/api/upload"
echo "  Upload (Stream): http://YOUR_EC2_IP/api/upload-stream"
echo ""
echo "Configuration Files:"
echo "  App Directory: $APP_DIR"
echo "  Environment: $APP_DIR/.env"
echo "  Service File: /etc/systemd/system/$SERVICE_NAME.service"
echo "  Nginx Config: /etc/nginx/sites-available/$SERVICE_NAME"
echo ""
print_warning "Don't forget to:"
echo "  1. Update the server_name in Nginx config (/etc/nginx/sites-available/$SERVICE_NAME)"
echo "  2. Configure your security group to allow HTTP (port 80) traffic"
echo "  3. Review and update $APP_DIR/.env with your specific settings"
echo ""
