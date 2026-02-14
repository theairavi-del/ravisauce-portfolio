#!/bin/bash

# ☁️ Cloudflare Pages Deployment Script
# Usage: ./deploy-cloudflare.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}☁️  Starting Cloudflare Pages Deployment...${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
cd "$WORKSPACE_DIR"

# Check for wrangler CLI
if ! command -v wrangler &> /dev/null; then
    echo -e "${YELLOW}⚠️  Wrangler CLI not found. Installing...${NC}"
    
    # Check for npm
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}❌ npm not found. Please install Node.js first:${NC}"
        echo -e "   https://nodejs.org/"
        exit 1
    fi
    
    npm install -g wrangler
fi

# Check if logged in to Cloudflare
echo -e "${BLUE}🔍 Checking Cloudflare authentication...${NC}"
if ! wrangler whoami &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not logged in to Cloudflare${NC}"
    echo -e "${BLUE}Please run:${NC}"
    echo -e "  wrangler login"
    echo -e ""
    echo -e "${YELLOW}Or visit: https://dash.cloudflare.com/${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Authenticated with Cloudflare${NC}"

# Ensure index.html exists
if [ -f "pinterest-clone.html" ]; then
    echo -e "${BLUE}📄 Copying pinterest-clone.html to index.html...${NC}"
    cp pinterest-clone.html index.html
fi

# Get project name from config or use default
PROJECT_NAME="ravisauce-website"
if [ -f "deploy-config.json" ]; then
    PROJECT_NAME=$(node -e "console.log(require('./deploy-config.json').cloudflare?.projectName || 'ravisauce-website')" 2>/dev/null || echo "ravisauce-website")
fi

# Deploy to Cloudflare Pages
echo -e "${BLUE}⬆️  Deploying to Cloudflare Pages...${NC}"
echo -e "${YELLOW}Project: $PROJECT_NAME${NC}"

wrangler pages deploy . --project-name="$PROJECT_NAME" --branch=main || {
    echo -e "${YELLOW}⚠️  Project may not exist. Creating...${NC}"
    echo -e "${YELLOW}Please create the project at:${NC}"
    echo -e "  https://dash.cloudflare.com/ → Pages → Create a project${NC}"
    echo -e ""
    echo -e "${BLUE}Then run this script again.${NC}"
    exit 1
}

echo -e ""
echo -e "${GREEN}✅ Deployed to Cloudflare Pages!${NC}"
echo -e "${BLUE}🌐 Your site will be available at:${NC}"
echo -e "  https://$PROJECT_NAME.pages.dev/${NC}"

# Update deploy config
if [ -f "deploy-config.json" ]; then
    node -e "
        const fs = require('fs');
        const config = JSON.parse(fs.readFileSync('deploy-config.json', 'utf8'));
        config.lastDeploy = {
            platform: 'cloudflare-pages',
            timestamp: new Date().toISOString(),
            commit: '$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')',
            url: 'https://$PROJECT_NAME.pages.dev/'
        };
        fs.writeFileSync('deploy-config.json', JSON.stringify(config, null, 2));
    " 2>/dev/null || true
fi

echo -e ""
echo -e "${GREEN}🎉 Deployment complete!${NC}"
