# Multi-Instance Deployment Plan

## Problem

Deploy beberapa instance `kvs-server-app` di VM yang sama, masing-masing dengan domain dan data sendiri, dengan satu push ke `main`.

## Requirements

-   Codebase sama (satu Docker image)
-   VM yang sama
-   2-3 instance (awal: `kv.amg.id` dan `tmx-kv.amg.id`)
-   Access token BEDA tiap instance
-   Data SQLite terisolasi per instance
-   Satu push ke `main` → update SEMUA instance

---

## Architecture

### Repo-side: `deploy-config.json`

Daftar instance di-version control, isinya:

```json
{
  "instances": [
    { "name": "kv", "domain": "kv.amg.id", "port": 3001 },
    { "name": "tmx-kv", "domain": "tmx-kv.amg.id", "port": 3002 }
  ]
}
```

### VM-side: `/opt/kvs-server-app/`

```
/opt/kvs-server-app/
├── docker-compose.yml   # generated oleh CI
├── .env                  # generated oleh CI dari secrets
└── data/
    ├── kv/
    │   └── kv.db
    └── tmx-kv/
        └── kv.db
```

### docker-compose.yml (generated)

Template per instance:

```yaml
x-kvs: &kvs
  image: ghcr.io/coderbuzz/kvs-server-app:latest
  restart: always
  networks: [web]
  labels:
    traefik.enable: "true"
    traefik.http.routers.{name}.entrypoints: web,websecure
    traefik.http.routers.{name}.rule: "Host(`{domain}`)"
    traefik.http.routers.{name}.tls.certresolver: letsencrypt
    traefik.http.routers.{name}.tls: "true"
    traefik.http.services.{name}.loadbalancer.server.port: "{port}"
    traefik.http.services.{name}.loadbalancer.server.scheme: http

services:
  kvs-{name}:
    <<: *kvs
    hostname: kvs-{name}
    environment:
      ACCESS_TOKEN: ${NAME_UC_ACCESS_TOKEN}
      PORT: "{port}"
    volumes:
      - ./data/{name}:/data

networks:
  web:
    external: true
```

CI script loop `deploy-config.json` dan generate satu service block per instance.

---

## Files to Create

| File | Isi |
|------|-----|
| `deploy-config.json` | Daftar instance |
| `.github/workflows/deploy.yml` | CI/CD workflow (build → generate compose → deploy) |

## Files to Modify

| File | Perubahan |
|------|-----------|
| `docker-compose.yml` | Hapus service hardcoded → jadi generated |
| `scripts/vm-init-deploy-user.sh` | Buat subfolder data per instance di `/opt/kvs-server-app/` |
| `AGENTS.md` | Update instruksi: secrets baru, cara tambah instance |

---

## GitHub Secrets

| Secret | Value |
|--------|-------|
| `KV_ACCESS_TOKEN` | token untuk kv.amg.id |
| `TMX_KV_ACCESS_TOKEN` | token untuk tmx-kv.amg.id |
| `DEPLOY_HOST` | (existing) |
| `DEPLOY_SSH_KEY` | (existing) |
| `GHCR_TOKEN` | (existing) |

---

## CI Workflow Flow (`.github/workflows/deploy.yml`)

```yaml
on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build and push Docker image
        run: |
          echo "$GHCR_TOKEN" | docker login ghcr.io -u coderbuzz --password-stdin
          docker build -t ghcr.io/coderbuzz/kvs-server-app:latest .
          docker push ghcr.io/coderbuzz/kvs-server-app:latest

      - name: Generate docker-compose.yml and .env
        run: |
          # baca deploy-config.json, generate compose + env
          # (detail script ada di implementasi nanti)

      - name: SCP files to VM
        run: |
          scp docker-compose.yml .env deploy@$DEPLOY_HOST:/opt/kvs-server-app/

      - name: Deploy via SSH
        run: |
          ssh deploy@$DEPLOY_HOST "
            cd /opt/kvs-server-app
            docker compose pull
            docker compose up -d --remove-orphans
            docker image prune -f
          "
```

---

## Cara Tambah Instance Baru

1. Edit `deploy-config.json`: tambah entry `{ "name", "domain", "port" }`
2. Tambah GitHub secret: `NAMA_ACCESS_TOKEN`
3. Push ke `main` → CI otomatis deploy semua instance

---

## Next Steps (besok)

1. Buat `deploy-config.json`
2. Tulis script generate compose + env (bisa inline di workflow atau file `.sh`)
3. Tulis `.github/workflows/deploy.yml`
4. Update `docker-compose.yml` → hapus isi lama, ganti jadi template yang siap digenerate
5. Update `scripts/vm-init-deploy-user.sh`
6. Update `AGENTS.md`
7. Setup GitHub secrets
8. Test push ke `main`
