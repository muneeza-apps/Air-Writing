#!/bin/bash
# AirWriter Pro - GitHub Pages Deployment Script

# NOTE: Replace with your actual GitHub repository name
REPO_NAME="air-writer-pro"

echo "================================================="
echo "🚀 Building AirWriter Pro for Web..."
echo "================================================="

# Clean previous builds
flutter clean

# Build the Flutter web app with the base-href for GitHub Pages
# This ensures that assets load correctly on https://[username].github.io/[REPO_NAME]/
flutter build web --release --base-href "/$REPO_NAME/"

echo "================================================="
echo "📦 Deploying to gh-pages branch..."
echo "================================================="

# Navigate into the compiled web directory
cd build/web

# Initialize a temporary git repository
git init
git add .
git commit -m "🚀 Auto-deploy to GitHub Pages"

# Push the build folder to the gh-pages branch forcefully
# Make sure your remote origin URL is properly set up in your local git config.
# If this fails, you can explicitly provide your repo URL below:
# git push -f https://github.com/[YOUR_USERNAME]/$REPO_NAME.git HEAD:gh-pages

git push -f origin HEAD:gh-pages

echo "✅ Successfully deployed! Give it a few minutes for GitHub Pages to update."
