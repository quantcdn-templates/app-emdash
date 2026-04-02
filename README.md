# EmDash CMS on Quant Cloud

[![Deploy to Quant Cloud](https://www.quantcdn.io/img/quant-deploy-btn-sml.svg)](https://dashboard.quantcdn.io/deploy/app/app-emdash)

A production-ready [EmDash CMS](https://github.com/emdash-cms/emdash) template for [Quant Cloud](https://www.quantcdn.io). EmDash is a modern TypeScript CMS built on Astro, designed as a spiritual successor to WordPress.

## Quick Start

### Docker Compose

```bash
# Clone the repository
git clone <your-repo-url>
cd app-emdash

# Start the application
docker compose up -d
```

The application will be available at `http://localhost:3000`. Access the admin panel at `http://localhost:3000/_emdash/admin`.

### Local Development

```bash
# Install dependencies
pnpm install

# Initialize the database
pnpm bootstrap

# Start the dev server
pnpm dev
```

The dev server runs at `http://localhost:4321`.

## Deploying to Quant Cloud

1. Create a new application from this template in the [Quant Cloud dashboard](https://dashboard.quantcdn.io)
2. The following secrets are auto-generated during provisioning:
   - `EMDASH_AUTH_SECRET` - Authentication signing key
   - `EMDASH_PREVIEW_SECRET` - Content preview secret
3. Push to your repository - the GitHub Actions workflow handles building and deploying

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `EMDASH_AUTH_SECRET` | Yes | Auth signing key (auto-generated on Quant Cloud) |
| `EMDASH_PREVIEW_SECRET` | Yes | Preview mode secret (auto-generated on Quant Cloud) |
| `EMDASH_SITE_NAME` | No | Site display name |

## Database

### Default: SQLite

Out of the box, EmDash uses SQLite stored on the persistent EFS volume at `/data/data.db`. This works well for single-instance deployments.

### Production: PostgreSQL

For production deployments or when scaling beyond a single instance, switch to PostgreSQL:

1. Add a PostgreSQL database to your application via the Quant Cloud dashboard
2. That's it - no code changes needed

The application auto-detects the Quant Cloud database environment variables (`DB_HOST`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`) and switches to PostgreSQL automatically.

**Note:** There is no automated migration from SQLite to PostgreSQL. If you have existing content in SQLite, you will need to manually export and import your data. We recommend choosing PostgreSQL before adding significant content if you plan to scale.

## Storage

Media uploads are stored on the persistent EFS volume at `/data/uploads`. This storage is automatically backed up by Quant Cloud.

## Architecture

```
Internet → Quant CDN → :3000 (Quant Proxy) → :4321 (EmDash/Astro)
                                                ├── /data/data.db (SQLite)
                                                └── /data/uploads/ (Media)
```

The Quant proxy on port 3000 handles host header rewriting and forwards requests to EmDash on port 4321.
