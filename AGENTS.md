# Agents Instructions

Dockerized deployment of `@coderbuzz/kvs-server` (HTTP/WS key-value store, SQLite-backed).

## Stack

- **Runtime:** Bun (`bun:sqlite` required by kvs)
- **Deps:** `@coderbuzz/kvs`, `@coderbuzz/kvs-server`, `@coderbuzz/velox`
- **Reverse proxy:** Traefik (shared `web` network)
- **Persistence:** SQLite at `/data/kv.db` (Docker volume)
- **CI/CD:** GitHub Actions → `ghcr.io` → SSH deploy

## Development

```bash
bun install
ACCESS_TOKEN=dev-token bun run src/index.ts
# or: bun run dev  (--watch mode)
```

No tests, linter, or typecheck exist. Add them before making risky changes.

## CI/CD Deploy

Push to `main` or tag `v*` → build & push image → SCP `docker-compose.yml` → SSH:
write `.env` from secrets, `docker login`, `docker-compose pull && up -d --remove-orphans`, `docker image prune -f`.

**One-time VM setup:** run `scripts/vm-init-deploy-user.sh` to create user, SSH key, docker group, and `/opt/kvs-server-app/` owned by deploy user.

**GitHub Secrets:** `DEPLOY_HOST`, `DEPLOY_SSH_KEY`, `ACCESS_TOKEN`, `DOMAIN`, `GHCR_TOKEN`.

## Important

- `ACCESS_TOKEN` is required at runtime — server exits without it
- `bun.lock` is tracked and required for Docker (`--frozen-lockfile`)
- `.env`, `data/`, `*.db` in `.gitignore` — never commit secrets
- User `deploy` is shared across all apps on the same VM (create once, reuse)
