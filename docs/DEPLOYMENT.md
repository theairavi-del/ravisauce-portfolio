# Ravi Builder - Deployment Guide

Complete deployment documentation for Ravi Visual Website Builder.

## Table of Contents

- [Quick Start](#quick-start)
- [Deployment Options](#deployment-options)
  - [Netlify](#netlify-recommended)
  - [Vercel](#vercel)
  - [GitHub Pages](#github-pages)
  - [Docker](#docker-self-hosting)
- [Environment Variables](#environment-variables)
- [Custom Domain Setup](#custom-domain-setup)
- [SSL/HTTPS Configuration](#sslhttps-configuration)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

### Prerequisites

- Node.js 18+ installed
- Git configured
- One of the following accounts:
  - Netlify (recommended)
  - Vercel
  - GitHub

### One-Command Deploy

```bash
# Clone and setup
git clone https://github.com/yourusername/ravi-builder.git
cd ravi-builder
npm install

# Deploy to Netlify (recommended)
npm run deploy:netlify
```

---

## Deployment Options

### Netlify (Recommended)

#### Option 1: One-Click Deploy Button

[![Deploy to Netlify](https://www.netlify.com/img/deploy/button.svg)](https://app.netlify.com/start/deploy?repository=https://github.com/yourusername/ravi-builder)

#### Option 2: CLI Deployment

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Login to Netlify
netlify login

# Link to site (first time only)
netlify link

# Deploy
npm run deploy:netlify
```

#### Option 3: Git Integration (Auto-Deploy)

1. Push code to GitHub
2. Connect repo in Netlify dashboard
3. Auto-deploys on every push to `main`

**Configuration**: See `netlify.toml` for build settings.

---

### Vercel

#### Option 1: One-Click Deploy

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/yourusername/ravi-builder)

#### Option 2: CLI Deployment

```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
npm run deploy:vercel
```

**Configuration**: See `vercel.json` for build settings.

---

### GitHub Pages

#### Setup

1. Go to repository **Settings** > **Pages**
2. Set source to **GitHub Actions**
3. The workflow will auto-deploy on pushes to `main`

#### Manual Deploy

```bash
npm run deploy:gh-pages
```

#### Custom Domain on GitHub Pages

1. Add `CNAME` file with your domain:
   ```
   www.yourdomain.com
   ```
2. Configure DNS (see [Custom Domain Setup](#custom-domain-setup))
3. Enable HTTPS in repository settings

---

### Docker (Self-Hosting)

#### Quick Start with Docker Compose

```bash
# Clone repository
git clone https://github.com/yourusername/ravi-builder.git
cd ravi-builder

# Copy environment file
cp docker/.env.example docker/.env

# Edit environment variables
nano docker/.env

# Start services
docker-compose -f docker/docker-compose.yml up -d

# View logs
docker-compose -f docker/docker-compose.yml logs -f
```

#### Production Deployment

```bash
# Build and run production image
docker build -t ravi-builder -f docker/Dockerfile .
docker run -d \
  -p 80:80 \
  -p 443:443 \
  -e NODE_ENV=production \
  --name ravi-builder \
  ravi-builder
```

#### Docker Swarm

```bash
# Initialize swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker/docker-compose.yml ravi

# View services
docker stack ps ravi
```

---

## Environment Variables

### Required Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Environment mode | `production` |
| `DOMAIN` | Your custom domain | `localhost` |

### Optional Variables

| Variable | Description | Used By |
|----------|-------------|---------|
| `NETLIFY_AUTH_TOKEN` | Netlify API token | Netlify deploys |
| `NETLIFY_SITE_ID` | Netlify site ID | Netlify deploys |
| `VERCEL_TOKEN` | Vercel API token | Vercel deploys |
| `VERCEL_ORG_ID` | Vercel organization ID | Vercel deploys |
| `GITHUB_TOKEN` | GitHub personal token | GitHub Actions |
| `JWT_SECRET` | Secret for JWT signing | API server |
| `DATABASE_URL` | Database connection string | API server |

### Setting Environment Variables

#### Local Development

Create `.env` file:
```bash
cp docker/.env.example .env
# Edit .env with your values
```

#### Netlify

```bash
netlify env:set KEY value
# Or via dashboard: Site settings > Environment variables
```

#### Vercel

```bash
vercel env add KEY
# Or via dashboard: Project settings > Environment Variables
```

#### GitHub Actions (Secrets)

Go to: Repository Settings > Secrets and variables > Actions

---

## Custom Domain Setup

### Netlify Custom Domain

1. Go to **Site settings** > **Domain management**
2. Click **Add custom domain**
3. Enter your domain
4. Configure DNS:
   - **Option A**: Use Netlify DNS (recommended)
   - **Option B**: Add CNAME record:
     ```
     CNAME www your-site.netlify.app
     ```

### Vercel Custom Domain

1. Go to **Project Settings** > **Domains**
2. Enter your domain
3. Add DNS records as shown

### GitHub Pages Custom Domain

1. Add `CNAME` file to repository root
2. Configure DNS:
   ```
   A RECORD @ 185.199.108.153
   A RECORD @ 185.199.109.153
   A RECORD @ 185.199.110.153
   A RECORD @ 185.199.111.153
   CNAME www youruser.github.io
   ```

### Docker with Custom Domain

Edit `docker/.env`:
```bash
DOMAIN=www.yourdomain.com
LETSENCRYPT_EMAIL=admin@yourdomain.com
```

SSL certificates are automatically generated via Let's Encrypt.

---

## SSL/HTTPS Configuration

### Automatic SSL (All Platforms)

All deployment options include automatic SSL:

- **Netlify**: Auto SSL via Let's Encrypt
- **Vercel**: Auto SSL via Let's Encrypt
- **GitHub Pages**: Auto SSL (enable in settings)
- **Docker**: Auto SSL via Certbot

### Force HTTPS

Already configured in all deployment configs. To verify:

```bash
# Check HTTPS redirect
curl -I http://yourdomain.com
# Should return: 301 Moved Permanently to https://...
```

### SSL Certificate Renewal

- **Netlify/Vercel/GitHub**: Automatic
- **Docker**: Auto-renews every 12 hours via Certbot

---

## Troubleshooting

### Build Failures

**Problem**: Build fails with "Module not found"
```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install
```

**Problem**: Out of memory during build
```bash
# Increase Node memory
export NODE_OPTIONS="--max-old-space-size=4096"
npm run build
```

### Deployment Failures

**Problem**: Netlify deploy fails
```bash
# Check build logs
netlify deploy --build

# Debug locally
netlify dev
```

**Problem**: Vercel deploy fails
```bash
# Check build locally
vercel build

# Deploy with logs
vercel --debug
```

### Custom Domain Issues

**Problem**: Domain not resolving
1. Check DNS propagation: `dig +short yourdomain.com`
2. Wait 24-48 hours for DNS propagation
3. Verify SSL certificate is issued

**Problem**: HTTPS not working
1. Check certificate status in platform dashboard
2. Force HTTPS in security settings
3. Clear browser cache

### Docker Issues

**Problem**: Container won't start
```bash
# View logs
docker-compose logs

# Check port conflicts
sudo lsof -i :80
sudo lsof -i :443
```

**Problem**: SSL certificate not generated
```bash
# Check certbot logs
docker-compose logs certbot

# Manual certificate generation
docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d yourdomain.com
```

---

## Support

- **Issues**: https://github.com/yourusername/ravi-builder/issues
- **Documentation**: https://ravi-builder.netlify.app/docs
- **Discord**: https://discord.gg/ravibuilder

---

## License

MIT License - see LICENSE file for details.
