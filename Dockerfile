# syntax=docker/dockerfile:1
# Build stage - runs on native platform to avoid QEMU emulation issues
ARG NODE_VERSION=22
FROM --platform=$BUILDPLATFORM node:${NODE_VERSION}-bookworm-slim AS builder

# Install pnpm and build tools for native modules (better-sqlite3)
RUN corepack enable && corepack prepare pnpm@latest --activate
RUN apt-get update && apt-get install -y python3 make g++ && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Copy package files and install all dependencies
# pnpm.onlyBuiltDependencies in package.json whitelists native builds
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# Copy source and build
COPY . .
RUN pnpm build

# Install production dependencies only
RUN rm -rf node_modules && pnpm install --frozen-lockfile --prod

# Production stage - multi-arch compatible
FROM ghcr.io/quantcdn-templates/app-node:${NODE_VERSION}

WORKDIR /app

# Copy custom entrypoint scripts
COPY quant/entrypoints/ /quant-entrypoint.d/
RUN find /quant-entrypoint.d -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# Create persistent data directory for SQLite + uploads
RUN mkdir -p /data/uploads && chown -R node:node /data

# Symlink default paths to EFS volume so emdash CLI and runtime
# both use the persistent storage regardless of path configuration
RUN ln -sf /data/data.db /app/data.db && \
    ln -sf /data/uploads /app/uploads

# Copy built application from builder
COPY --from=builder --chown=node:node /build/dist ./dist
COPY --from=builder --chown=node:node /build/node_modules ./node_modules
COPY --from=builder --chown=node:node /build/package.json ./

ENV HOST=0.0.0.0
ENV PORT=4321

EXPOSE 3000

CMD ["node", "dist/server/entry.mjs"]
