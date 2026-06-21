# Prompt: Buat Project Baru dengan CI Flow & Konfigurasi yang Sama

Sebelum membuat project, tanyakan ke saya:

1. **Nama app** — digunakan untuk nama folder, image ghcr, dan path `/opt/<app-name>/`
2. **Dependencies** — runtime apa (Bun/Node/Python/dll), package apa saja yang perlu di-install
3. **Volumes** — apakah ada persistent data yang perlu di-mount (e.g. SQLite, uploads, dll). Jika ada, tanyakan path di container dan host (default `/data`)

Setelah itu, buat project dengan struktur berikut:

```
<root>
├── src/index.ts (atau entry point sesuai runtime)
├── docker-compose.yml
├── Dockerfile
├── .github/workflows/
├── scripts/vm-init-deploy-user.sh
└── AGENTS.md
```

## Yang harus dibuat

1. **docker-compose.yml** — service `app` image dari ghcr, mount volume yang diperlukan, expose port, Traefik labels (redirect scheme https, letsencrypt, host `${DOMAIN}`, network `web`, port `3000`), env dari file `.env`.
2. **Dockerfile** — base image sesuai runtime, install dependencies, copy source, entry point sesuai runtime.
3. **GitHub Actions** — trigger push main/tag v*, build & push image ke ghcr, SCP `docker-compose.yml` ke `/opt/<app-name>/`, lalu SSH: tulis `.env` dari secrets, `docker login`, `docker compose pull && up -d --remove-orphans && image prune -f`.
4. **scripts/vm-init-deploy-user.sh** — buat user `deploy` (default), docker group, SSH key + authorized_keys, dan buat `/opt/<app-name>/` + chown ke user deploy.
5. **AGENTS.md** — dokumentasi arsitektur, development, deployment flow, VM architecture, DNS & SSL, dan important notes.

## Konvensi

- Lock file jangan di-commit (.gitignore)
- `.env` jangan pernah di-commit
- User `deploy` reusable untuk semua app di VM yang sama
- AGENTS.md pakai format: Overview, Stack, Project Structure, Development, Deployment Flow, VM Architecture, DNS & SSL, Important
- GitHub Secrets: `DEPLOY_HOST`, `DEPLOY_SSH_KEY`, `ACCESS_TOKEN`, `DOMAIN`, `GHCR_TOKEN`

Gunakan proyek `kvs-server-app` sebagai referensi implementasi.
