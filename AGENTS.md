# Agents Instructions

## Overview

Dockerized deployment of `@coderbuzz/kvs-server`. Wraps `KVStore` (SQLite-backed) + `createServer` (HTTP/WS) into a single Docker container.

## Stack

- **Runtime:** Bun (`bun:sqlite` required by kvs)
- **Deps:** `@coderbuzz/kvs`, `@coderbuzz/kvs-server`, `@coderbuzz/velox`
- **Reverse proxy:** Traefik (shared `web` network on VM)
- **Persistence:** SQLite at `/data/kv.db` (Docker volume)
- **CI/CD:** GitHub Actions → `ghcr.io` → SSH deploy

## Project Structure

```
src/index.ts                    # Entry point
docker-compose.yml              # Production deploy config
Dockerfile                      # oven/bun:1-slim base
.github/workflows/              # CI/CD pipeline
scripts/vm-init-deploy-user.sh  # One-time VM setup
```

## Development

```bash
bun install
ACCESS_TOKEN=dev-token bun run src/index.ts
```

## Deployment Flow

1. **One-time:** Run `scripts/vm-init-deploy-user.sh` on VM → creates `deploy` user + SSH key
2. **GitHub Secrets:** `DEPLOY_HOST`, `DEPLOY_SSH_KEY`, `ACCESS_TOKEN`, `DOMAIN`
3. **Push to `main`** → CI builds Docker image → pushes to `ghcr.io` → SSH deploys to VM

Each deploy writes `.env` fresh from GitHub Secrets, then runs `docker compose pull && up -d`.

## VM Architecture

```
VM
├── Traefik (shared reverse proxy, network: web)
│   ├── sso-amg-id (existing)
│   └── kvs-server-app (this app)
└── User: deploy (docker group, SSH key auth, shared across all apps)
```

## DNS & SSL

- Cloudflare DNS: A record → VM IP (proxied, orange cloud)
- Traefik: Let's Encrypt via `certresolver=letsencrypt`
- Each app adds Traefik labels in `docker-compose.yml`

## Important

- Never commit `.env` or secrets
- `bun.lock` in `.gitignore` (not needed for Docker builds)
- User `deploy` is shared across all apps on the same VM — create once, reuse
