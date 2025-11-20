#!/bin/bash

# Build script for production deployment
echo "Building React application for production..."

# Install dependencies
echo "Installing dependencies..."
npm install

# Build the application
echo "Creating production build..."
npm run build

# Check if build was successful
if [ -d "build" ]; then
  echo "Build successful! Production files are in the 'build' directory."
  echo "Build size:"
  du -sh build/
else
  echo "Build failed!"
  exit 1
fi

echo "Production build complete!"
