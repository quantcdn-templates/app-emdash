#!/bin/bash
set -e

echo "emdash: Preparing database..."

# Quant Cloud injects DB_HOST for every environment in an application with a
# managed database, whatever its engine. Only a Postgres port means Postgres;
# anything else (including the shared MySQL instance) means SQLite on /data.
if [ -n "${DB_HOST}" ] && [ "${DB_PORT:-5432}" = "5432" ]; then
  echo "emdash: Using PostgreSQL at ${DB_HOST}:5432"
else
  mkdir -p /data/uploads
  echo "emdash: Using SQLite at /data/data.db"
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
