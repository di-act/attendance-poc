#!/bin/bash

# Quick deployment script for updates
# Use this when you need to quickly update the application without full redeployment

APP_DIR="/home/ubuntu/file-upload-api"

echo "Updating Flask File Upload API..."

# Navigate to app directory
cd $APP_DIR

# Activate virtual environment
source venv/bin/activate

# Pull latest changes (if using git)
# git pull origin main

# Install/update dependencies
pip install -r requirements.txt

# Restart service
sudo systemctl restart flask-api

# Check status
sudo systemctl status flask-api --no-pager

echo "Update complete!"
