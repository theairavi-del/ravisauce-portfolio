#!/bin/bash

# 🚀 GitHub Pages Deployment Script
# Usage: ./deploy-github-pages.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting GitHub Pages Deployment...${NC}"

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
cd "$WORKSPACE_DIR"

# Check if git repo exists
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Error: Not a git repository${NC}"
    echo -e "${YELLOW}Initializing git repository...${NC}"
    git init
    git remote add origin https://github.com/ravisauce/ravisauce.git 2>/dev/null || true
fi

# Ensure index.html exists and is up to date
if [ -f "pinterest-clone.html" ]; then
    echo -e "${BLUE}📄 Copying pinterest-clone.html to index.html...${NC}"
    cp pinterest-clone.html index.html
fi

# Check GitHub remote
echo -e "${BLUE}🔍 Checking GitHub remote...${NC}"
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")

if [ -z "$REMOTE_URL" ]; then
    echo -e "${YELLOW}⚠️  No remote configured. Setting up GitHub remote...${NC}"
    echo -e "${YELLOW}Please enter your GitHub username:${NC}"
    read -r GITHUB_USER
    git remote add origin "https://github.com/$GITHUB_USER/ravisauce.git"
fi

# Stage all files
echo -e "${BLUE}📦 Staging files...${NC}"
git add -A

# Check if there are changes to commit
if git diff --cached --quiet; then
    echo -e "${YELLOW}⚠️  No changes to deploy${NC}"
else
    # Commit with timestamp
    COMMIT_MSG="Deploy: $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${BLUE}💾 Committing: $COMMIT_MSG${NC}"
    git commit -m "$COMMIT_MSG"
    
    # Push to main
    echo -e "${BLUE}⬆️  Pushing to GitHub...${NC}"
    git push origin main || {
        echo -e "${RED}❌ Push failed. Trying to pull first...${NC}"
        git pull origin main --rebase
        git push origin main
    }
    
    echo -e "${GREEN}✅ Successfully pushed to GitHub!${NC}"
fi

# Check if GitHub Pages is enabled
echo -e ""
echo -e "${BLUE}📋 GitHub Pages Status:${NC}"
echo -e "${YELLOW}Repository: $(git remote get-url origin 2>/dev/null || echo 'Not configured')${NC}"
echo -e "${YELLOW}Your site will be available at:${NC}"
echo -e "${GREEN}  https://ravisauce.github.io/ravisauce/${NC}"
echo -e ""
echo -e "${YELLOW}⚠️  IMPORTANT: Ensure GitHub Pages is enabled:${NC}"
echo -e "  1. Go to https://github.com/ravisauce/ravisauce/settings/pages"
echo -e "  2. Under 'Source', select 'Deploy from a branch'"
echo -e "  3. Select 'main' branch and '/ (root)' folder"
echo -e "  4. Click Save"
echo -e ""
echo -e "${BLUE}⏱️  Deployment takes 2-5 minutes to propagate${NC}"

# Update deploy config
CONFIG_FILE="$WORKSPACE_DIR/deploy-config.json"
if [ -f "$CONFIG_FILE" ]; then
    # Update last deploy info using node
    node -e "
        const fs = require('fs');
        const config = JSON.parse(fs.readFileSync('$CONFIG_FILE', 'utf8'));
        config.lastDeploy = {
            platform: 'github-pages',
            timestamp: new Date().toISOString(),
            commit: '$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')',
            url: 'https://ravisauce.github.io/ravisauce/'
        };
        fs.writeFileSync('$CONFIG_FILE', JSON.stringify(config, null, 2));
    " 2>/dev/null || true
fi

echo -e ""
echo -e "${GREEN}🎉 Deployment complete!${NC}"
