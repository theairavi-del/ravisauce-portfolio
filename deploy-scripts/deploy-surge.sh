#!/bin/bash

# ⚡ Surge.sh Deployment Script (EASIEST CLI)
# Usage: ./deploy-surge.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}⚡ Starting Surge.sh Deployment...${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
cd "$WORKSPACE_DIR"

# Check for Surge CLI
if ! command -v surge &> /dev/null; then
    echo -e "${YELLOW}⚠️  Surge CLI not found. Installing...${NC}"
    
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}❌ npm not found. Please install Node.js first:${NC}"
        echo -e "   https://nodejs.org/"
        exit 1
    fi
    
    npm install -g surge
fi

# Ensure index.html exists
if [ -f "pinterest-clone.html" ]; then
    echo -e "${BLUE}📄 Copying pinterest-clone.html to index.html...${NC}"
    cp pinterest-clone.html index.html
fi

# Create CNAME file for custom domain if needed
# echo "ravisauce.com" > CNAME

# Deploy
echo -e "${BLUE}⬆️  Deploying to Surge.sh...${NC}"
echo -e "${YELLOW}This will create: ravisauce.surge.sh${NC}"
echo -e "${YELLOW}(Or specify your own domain)${NC}"
echo -e ""

surge . --domain ravisauce.surge.sh --project .

echo -e ""
echo -e "${GREEN}✅ Deployed to Surge.sh!${NC}"
echo -e "${BLUE}🌐 Your site is available at:${NC}"
echo -e "  https://ravisauce.surge.sh${NC}"
echo -e ""
echo -e "${YELLOW}💡 To deploy updates, just run this script again${NC}"

# Update deploy config
if [ -f "deploy-config.json" ]; then
    node -e "
        const fs = require('fs');
        const config = JSON.parse(fs.readFileSync('deploy-config.json', 'utf8'));
        config.lastDeploy = {
            platform: 'surge',
            timestamp: new Date().toISOString(),
            commit: '$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')',
            url: 'https://ravisauce.surge.sh'
        };
        fs.writeFileSync('deploy-config.json', JSON.stringify(config, null, 2));
    " 2>/dev/null || true
fi

echo -e ""
echo -e "${GREEN}🎉 Deployment complete!${NC}"
