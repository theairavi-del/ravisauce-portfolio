#!/bin/bash

# 🚀 MASTER DEPLOYMENT SCRIPT
# Usage: ./deploy.sh [platform]
# Platforms: github, cloudflare, netlify, surge, all

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM="${1:-github}"

echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════╗"
echo "║     🚀 RAVI SAUCE DEPLOYMENT SYSTEM 🚀         ║"
echo "╚════════════════════════════════════════════════╝"
echo -e "${NC}"

show_help() {
    echo -e "${BLUE}Usage: ./deploy.sh [platform]${NC}"
    echo ""
    echo "Platforms:"
    echo "  github      - GitHub Pages (default)"
    echo "  cloudflare  - Cloudflare Pages"
    echo "  netlify     - Netlify"
    echo "  surge       - Surge.sh"
    echo "  all         - Deploy to all platforms"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh              # Deploy to GitHub Pages"
    echo "  ./deploy.sh cloudflare   # Deploy to Cloudflare"
    echo "  ./deploy.sh all          # Deploy everywhere"
}

case "$PLATFORM" in
    github|gh|github-pages)
        echo -e "${BLUE}📦 Deploying to GitHub Pages...${NC}"
        "$SCRIPT_DIR/deploy-github-pages.sh"
        ;;
    
    cloudflare|cf|wrangler)
        echo -e "${BLUE}☁️  Deploying to Cloudflare Pages...${NC}"
        "$SCRIPT_DIR/deploy-cloudflare.sh"
        ;;
    
    netlify|ntl)
        echo -e "${BLUE}🌍 Deploying to Netlify...${NC}"
        "$SCRIPT_DIR/deploy-netlify.sh"
        ;;
    
    surge|surge.sh)
        echo -e "${BLUE}⚡ Deploying to Surge.sh...${NC}"
        "$SCRIPT_DIR/deploy-surge.sh"
        ;;
    
    all|deploy-all|everywhere)
        echo -e "${BLUE}🚀 Deploying to ALL platforms...${NC}"
        echo ""
        
        echo -e "${YELLOW}1/4 - GitHub Pages...${NC}"
        "$SCRIPT_DIR/deploy-github-pages.sh" || echo -e "${RED}   GitHub Pages failed${NC}"
        
        echo ""
        echo -e "${YELLOW}2/4 - Cloudflare Pages...${NC}"
        "$SCRIPT_DIR/deploy-cloudflare.sh" || echo -e "${RED}   Cloudflare Pages failed${NC}"
        
        echo ""
        echo -e "${YELLOW}3/4 - Netlify...${NC}"
        "$SCRIPT_DIR/deploy-netlify.sh" || echo -e "${RED}   Netlify failed${NC}"
        
        echo ""
        echo -e "${YELLOW}4/4 - Surge.sh...${NC}"
        "$SCRIPT_DIR/deploy-surge.sh" || echo -e "${RED}   Surge.sh failed${NC}"
        
        echo ""
        echo -e "${GREEN}🎉 Multi-platform deployment complete!${NC}"
        ;;
    
    help|--help|-h)
        show_help
        ;;
    
    *)
        echo -e "${RED}❌ Unknown platform: $PLATFORM${NC}"
        show_help
        exit 1
        ;;
esac
