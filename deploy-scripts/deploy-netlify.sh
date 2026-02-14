#!/bin/bash

# 🌍 Netlify Deployment Script
# Usage: ./deploy-netlify.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🌍 Starting Netlify Deployment...${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
cd "$WORKSPACE_DIR"

# Check for Netlify CLI
if ! command -v netlify &> /dev/null; then
    echo -e "${YELLOW}⚠️  Netlify CLI not found. Installing...${NC}"
    
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}❌ npm not found. Please install Node.js first:${NC}"
        echo -e "   https://nodejs.org/"
        exit 1
    fi
    
    npm install -g netlify-cli
fi

# Check if logged in
echo -e "${BLUE}🔍 Checking Netlify authentication...${NC}"
if ! netlify status &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not logged in to Netlify${NC}"
    echo -e "${BLUE}Please run:${NC}"
    echo -e "  netlify login"
    echo -e ""
    echo -e "${YELLOW}Or use drag-and-drop at:${NC}"
    echo -e "  https://app.netlify.com/drop${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Authenticated with Netlify${NC}"

# Ensure index.html exists
if [ -f "pinterest-clone.html" ]; then
    echo -e "${BLUE}📄 Copying pinterest-clone.html to index.html...${NC}"
    cp pinterest-clone.html index.html
fi

# Get site name
SITE_NAME="ravisauce"
if [ -f "deploy-config.json" ]; then
    SITE_NAME=$(node -e "console.log(require('./deploy-config.json').netlify?.siteName || 'ravisauce')" 2>/dev/null || echo "ravisauce")
fi

# Check if site is linked
if [ ! -f ".netlify/state.json" ]; then
    echo -e "${YELLOW}⚠️  Site not linked. Linking...${NC}"
    netlify link --name="$SITE_NAME" || {
        echo -e "${YELLOW}Creating new site...${NC}"
        netlify sites:create --name="$SITE_NAME"
        netlify link
    }
fi

# Deploy
echo -e "${BLUE}⬆️  Deploying to Netlify...${NC}"
netlify deploy --prod --dir=. --message="Deploy: $(date '+%Y-%m-%d %H:%M:%S')"

echo -e ""
echo -e "${GREEN}✅ Deployed to Netlify!${NC}"

# Get site URL
SITE_URL=$(netlify status --json 2>/dev/null | node -e "const d=require('fs').readFileSync(0,'utf8'); const j=JSON.parse(d); console.log(j.siteUrl || '')" 2>/dev/null || echo "")
if [ -z "$SITE_URL" ]; then
    SITE_URL="https://$SITE_NAME.netlify.app"
fi

echo -e "${BLUE}🌐 Your site is available at:${NC}"
echo -e "  $SITE_URL${NC}"

# Update deploy config
if [ -f "deploy-config.json" ]; then
    node -e "
        const fs = require('fs');
        const config = JSON.parse(fs.readFileSync('deploy-config.json', 'utf8'));
        config.lastDeploy = {
            platform: 'netlify',
            timestamp: new Date().toISOString(),
            commit: '$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')',
            url: '$SITE_URL'
        };
        fs.writeFileSync('deploy-config.json', JSON.stringify(config, null, 2));
    " 2>/dev/null || true
fi

echo -e ""
echo -e "${GREEN}🎉 Deployment complete!${NC}"
