#!/bin/bash

# Deployment script for AWS EC2
# This script deploys the React app and Flask backend on EC2

set -e

echo "======================================"
echo "AWS EC2 Deployment Script"
echo "======================================"

# Variables
APP_DIR="/var/www/attendance-analysis"
BACKEND_DIR="/opt/flask-backend"
EC2_USER="ubuntu"  # Change if using different AMI (e.g., 'ec2-user' for Amazon Linux)

echo "Step 1: Update system packages..."
sudo apt-get update
sudo apt-get upgrade -y

echo "Step 2: Install required software..."
# Install Node.js (if not already installed)
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Install Python and pip (if not already installed)
if ! command -v python3 &> /dev/null; then
    echo "Installing Python..."
    sudo apt-get install -y python3 python3-pip python3-venv
fi

# Install Nginx (if not already installed)
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    sudo apt-get install -y nginx
fi

echo "Step 3: Create application directories..."
sudo mkdir -p $APP_DIR
sudo mkdir -p $BACKEND_DIR
sudo chown -R $EC2_USER:$EC2_USER $APP_DIR
sudo chown -R $EC2_USER:$EC2_USER $BACKEND_DIR

echo "Step 4: Copy application files..."
# Note: You should upload your files using SCP before running this
# Example: scp -i your-key.pem -r Client/build/* ubuntu@your-ec2-ip:/tmp/client-build/
# Example: scp -i your-key.pem -r Server/* ubuntu@your-ec2-ip:/tmp/server/

if [ -d "/tmp/client-build" ]; then
    echo "Copying React build files..."
    sudo cp -r /tmp/client-build/* $APP_DIR/
else
    echo "Warning: React build files not found in /tmp/client-build"
fi

if [ -d "/tmp/server" ]; then
    echo "Copying Flask backend files..."
    sudo cp -r /tmp/server/* $BACKEND_DIR/
else
    echo "Warning: Flask backend files not found in /tmp/server"
fi

echo "Step 5: Set up Python virtual environment and install dependencies..."
cd $BACKEND_DIR
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "Step 6: Configure Nginx..."
sudo cp /tmp/nginx.conf /etc/nginx/sites-available/attendance-analysis
sudo ln -sf /etc/nginx/sites-available/attendance-analysis /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

echo "Step 7: Set up Flask as a systemd service..."
cat << EOF | sudo tee /etc/systemd/system/flask-api.service
[Unit]
Description=Flask API for Attendance Analysis
After=network.target

[Service]
Type=notify
User=$EC2_USER
WorkingDirectory=$BACKEND_DIR
Environment="PATH=$BACKEND_DIR/venv/bin"
ExecStart=$BACKEND_DIR/venv/bin/gunicorn --config gunicorn_config.py wsgi:app

[Install]
WantedBy=multi-user.target
EOF

echo "Step 8: Start Flask service..."
sudo systemctl daemon-reload
sudo systemctl start flask-api
sudo systemctl enable flask-api
sudo systemctl status flask-api

echo "Step 9: Configure firewall..."
sudo ufw allow 'Nginx Full'
sudo ufw allow 22/tcp
sudo ufw --force enable

echo "======================================"
echo "Deployment Complete!"
echo "======================================"
echo "Your application should now be accessible at:"
echo "http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo ""
echo "To check service status:"
echo "  - Nginx: sudo systemctl status nginx"
echo "  - Flask API: sudo systemctl status flask-api"
echo ""
echo "To view logs:"
echo "  - Nginx access: sudo tail -f /var/log/nginx/access.log"
echo "  - Nginx error: sudo tail -f /var/log/nginx/error.log"
echo "  - Flask API: sudo journalctl -u flask-api -f"
