# syntax=docker/dockerfile:1
ARG NODE_VERSION=22

# Build stage - runs on the build host's platform so the Astro build is not
# emulated. Nothing native from this stage ships in the final image.
FROM --platform=$BUILDPLATFORM node:${NODE_VERSION}-bookworm-slim AS builder

RUN corepack enable && corepack prepare pnpm@12.3.4 --activate
RUN apt-get update && apt-get install -y python3 make g++ && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# pnpm-workspace.yaml carries allowBuilds for the native modules
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .
RUN pnpm build

# Dependency stage - runs on the TARGET platform so better-sqlite3 compiles
# for the architecture that will run it. A builder pinned to BUILDPLATFORM
# used to copy an aarch64 binary into the amd64 image and vice versa.
FROM node:${NODE_VERSION}-bookworm-slim AS deps

RUN corepack enable && corepack prepare pnpm@12.3.4 --activate
RUN apt-get update && apt-get install -y python3 make g++ && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile --prod

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

# Astro sessions path gets baked in from the builder's WORKDIR
RUN mkdir -p /build/node_modules/.astro/sessions && chown -R node:node /build

# Copy built application from builder
COPY --from=builder --chown=node:node /build/dist ./dist
COPY --from=deps --chown=node:node /build/node_modules ./node_modules
COPY --from=builder --chown=node:node /build/package.json ./

ENV HOST=0.0.0.0
ENV PORT=4321
ENV QUANT_APP_PORT=4321

EXPOSE 3000

CMD ["node", "dist/server/entry.mjs"]
