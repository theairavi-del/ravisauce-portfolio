# Environment Variables Reference

Complete guide to all environment variables used in Ravi Builder.

## Table of Contents

- [Quick Reference](#quick-reference)
- [Application Settings](#application-settings)
- [Deployment Platforms](#deployment-platforms)
- [Database](#database)
- [Security](#security)
- [Storage](#storage)
- [Notifications](#notifications)
- [Monitoring](#monitoring)

---

## Quick Reference

### Required for Production

```bash
NODE_ENV=production
DOMAIN=yourdomain.com
JWT_SECRET=your-secure-secret
```

### Required for Platform Deployments

**Netlify:**
```bash
NETLIFY_AUTH_TOKEN=your-token
NETLIFY_SITE_ID=your-site-id
```

**Vercel:**
```bash
VERCEL_TOKEN=your-token
VERCEL_ORG_ID=your-org-id
VERCEL_PROJECT_ID=your-project-id
```

---

## Application Settings

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `NODE_ENV` | Environment mode (`development`, `production`, `test`) | `development` | Yes |
| `PORT` | Server port | `3000` | No |
| `API_PORT` | API server port | `3000` | No |
| `FRONTEND_PORT` | Frontend port | `8080` | No |
| `DOMAIN` | Primary domain name | `localhost` | Yes (prod) |
| `BASE_URL` | Full base URL | `http://localhost:3000` | No |

---

## Deployment Platforms

### Netlify

| Variable | Description | Where to Get |
|----------|-------------|--------------|
| `NETLIFY_AUTH_TOKEN` | Personal access token | Netlify Dashboard → User Settings → Applications |
| `NETLIFY_SITE_ID` | Site API ID | Site Settings → General → Site Details |

### Vercel

| Variable | Description | Where to Get |
|----------|-------------|--------------|
| `VERCEL_TOKEN` | API token | Vercel Dashboard → Settings → Tokens |
| `VERCEL_ORG_ID` | Organization ID | `vercel whoami` or Project Settings |
| `VERCEL_PROJECT_ID` | Project ID | Project Settings → General |

### GitHub

| Variable | Description | Where to Get |
|----------|-------------|--------------|
| `GITHUB_TOKEN` | Personal access token | GitHub Settings → Developer Settings → Tokens |

### Docker / Self-Hosted

| Variable | Description | Default |
|----------|-------------|---------|
| `LETSENCRYPT_EMAIL` | Email for SSL notifications | - |
| `DOCKER_REGISTRY` | Docker registry URL | `docker.io` |
| `DOCKER_IMAGE` | Image name | `ravi-builder` |
| `DOCKER_TAG` | Image tag | `latest` |

---

## Database

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | Database connection string | `sqlite:///app/data/ravi.db` |
| `DATABASE_HOST` | Database host | `localhost` |
| `DATABASE_PORT` | Database port | `5432` |
| `DATABASE_NAME` | Database name | `ravi` |
| `DATABASE_USER` | Database user | - |
| `DATABASE_PASSWORD` | Database password | - |
| `DATABASE_SSL` | Enable SSL connection | `true` |

### Database URL Format

**SQLite:**
```bash
DATABASE_URL=sqlite:///path/to/database.db
```

**PostgreSQL:**
```bash
DATABASE_URL=postgresql://user:password@localhost:5432/ravi
```

**MySQL:**
```bash
DATABASE_URL=mysql://user:password@localhost:3306/ravi
```

---

## Security

| Variable | Description | Default |
|----------|-------------|---------|
| `JWT_SECRET` | Secret key for JWT signing | **Required** |
| `JWT_EXPIRES_IN` | JWT expiration time | `7d` |
| `API_KEY` | API key for external services | - |
| `CORS_ORIGINS` | Allowed CORS origins (comma-separated) | `*` |
| `RATE_LIMIT_ENABLED` | Enable rate limiting | `true` |
| `RATE_LIMIT_WINDOW` | Rate limit window (ms) | `900000` |
| `RATE_LIMIT_MAX` | Max requests per window | `100` |

### Generating Secure Secrets

```bash
# Generate JWT secret
openssl rand -base64 32

# Generate API key
uuidgen

# Generate password
openssl rand -hex 16
```

---

## Storage

| Variable | Description | Default |
|----------|-------------|---------|
| `UPLOAD_DIR` | File upload directory | `/app/uploads` |
| `MAX_UPLOAD_SIZE` | Max upload size in MB | `50` |
| `STORAGE_PROVIDER` | Storage provider (`local`, `s3`, `gcs`) | `local` |

### AWS S3

| Variable | Description |
|----------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `AWS_REGION` | AWS region |
| `AWS_S3_BUCKET` | S3 bucket name |
| `AWS_S3_ENDPOINT` | Custom S3 endpoint (optional) |

### Google Cloud Storage

| Variable | Description |
|----------|-------------|
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to service account JSON |
| `GCS_BUCKET` | GCS bucket name |

---

## Notifications

### SMTP Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `SMTP_SERVER` | SMTP server hostname | `smtp.gmail.com` |
| `SMTP_PORT` | SMTP port | `587` |
| `SMTP_USER` | SMTP username | - |
| `SMTP_PASS` | SMTP password/app password | - |
| `SMTP_SECURE` | Use TLS | `true` |
| `SMTP_FROM` | From email address | - |

### Email Recipients

| Variable | Description |
|----------|-------------|
| `NOTIFICATION_EMAIL` | Primary notification email |
| `ALERT_EMAIL` | Critical alert email |
| `SUPPORT_EMAIL` | Support contact email |

### Slack Integration

| Variable | Description |
|----------|-------------|
| `SLACK_WEBHOOK_URL` | Slack incoming webhook URL |
| `SLACK_CHANNEL` | Default channel for notifications |

### Discord Integration

| Variable | Description |
|----------|-------------|
| `DISCORD_WEBHOOK_URL` | Discord webhook URL |

---

## Monitoring

| Variable | Description | Default |
|----------|-------------|---------|
| `ENABLE_HEALTH_CHECK` | Enable health check endpoint | `true` |
| `HEALTH_CHECK_PATH` | Health check URL path | `/health` |
| `LOG_LEVEL` | Logging level (`error`, `warn`, `info`, `debug`) | `info` |
| `LOG_FORMAT` | Log format (`json`, `simple`) | `json` |
| `ENABLE_METRICS` | Enable Prometheus metrics | `true` |
| `METRICS_PORT` | Metrics endpoint port | `9090` |

### APM Integration

| Variable | Description |
|----------|-------------|
| `SENTRY_DSN` | Sentry DSN for error tracking |
| `DATADOG_API_KEY` | Datadog API key |
| `NEW_RELIC_LICENSE_KEY` | New Relic license key |

---

## Platform-Specific Variables

### Netlify

```bash
# Build settings
NETLIFY_BUILD_COMMAND=npm run build
NETLIFY_PUBLISH_DIRECTORY=dist
NETLIFY_NODE_VERSION=20
```

### Vercel

```bash
# Framework settings
VERCEL_FRAMEWORK_PRESET=static
VERCEL_BUILD_COMMAND=npm run build:static
VERCEL_OUTPUT_DIRECTORY=dist
```

### GitHub Actions

```bash
# Deployment settings
GH_PAGES_BRANCH=gh-pages
GH_PAGES_CNAME=yourdomain.com
GH_PAGES_JEKYLL=false
```

---

## Example .env Files

### Development

```bash
NODE_ENV=development
PORT=3000
BASE_URL=http://localhost:3000
DATABASE_URL=sqlite:./dev.db
JWT_SECRET=dev-secret-not-for-production
LOG_LEVEL=debug
```

### Production (Netlify)

```bash
NODE_ENV=production
BASE_URL=https://yourdomain.com
NETLIFY_AUTH_TOKEN=ntlify_xxxxxxxx
NETLIFY_SITE_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
JWT_SECRET=your-super-secure-secret
DATABASE_URL=postgresql://user:pass@db.provider.com/ravi
```

### Production (Docker)

```bash
NODE_ENV=production
DOMAIN=yourdomain.com
LETSENCRYPT_EMAIL=admin@yourdomain.com
JWT_SECRET=your-super-secure-secret
DATABASE_URL=postgresql://postgres:password@db:5432/ravi
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=admin@yourdomain.com
SMTP_PASS=app-specific-password
NOTIFICATION_EMAIL=admin@yourdomain.com
```

---

## Security Best Practices

1. **Never commit `.env` files** to version control
2. **Use strong secrets** (32+ characters, mixed case, symbols)
3. **Rotate secrets regularly** (every 90 days)
4. **Use different secrets** for each environment
5. **Enable 2FA** on all platform accounts
6. **Use app-specific passwords** for SMTP
7. **Restrict CORS origins** in production
8. **Enable rate limiting** to prevent abuse

---

## Validation

Validate your environment setup:

```bash
# Check required variables
node scripts/validate-env.js

# Or use the built-in check
npm run check:env
```
