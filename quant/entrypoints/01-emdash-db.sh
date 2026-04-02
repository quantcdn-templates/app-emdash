#!/bin/bash
set -e

echo "emdash: Preparing database..."

# Ensure data directory exists (SQLite mode)
if [ -z "${DB_HOST}" ]; then
  mkdir -p /data/uploads
  echo "emdash: Using SQLite at /data/data.db"
else
  echo "emdash: Using PostgreSQL at ${DB_HOST}:${DB_PORT:-5432}"
fi

# Run emdash init - safe to run on every boot:
# - Migrations are always run (idempotent)
# - Schema/seed only applied on first run
cd /app
npx emdash init

# Ensure the node user owns all data files (entrypoint runs as root,
# but the app process runs as node)
chown -R node:node /data

echo "emdash: Database ready."
