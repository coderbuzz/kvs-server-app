# kvs-server-app

Dockerized deployment of [@coderbuzz/kvs-server](https://github.com/coderbuzz/kvs-server) — self-hosted HTTP REST + WebSocket key-value store.

## Quick Start

Prerequisites: Docker, Docker Compose, Traefik reverse proxy with `web` network.

```bash
echo "ACCESS_TOKEN=my-secret-token" > .env
echo "DOMAIN=kvs.example.com" >> .env
docker compose up -d
```

## Configuration

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ACCESS_TOKEN` | Yes | — | Bearer token for API auth |
| `DOMAIN` | Yes | — | Domain for Traefik routing |
| `PORT` | No | `3000` | HTTP/WS port |

## API

Unauthenticated: `GET /health`

Authenticated (`Authorization: Bearer <token>`):

| Method | Path | Description |
|--------|------|-------------|
| POST | `/kv/get` | Get value by key |
| POST | `/kv/set` | Set key-value with optional TTL |
| POST | `/kv/delete` | Delete key |
| POST | `/kv/list` | List keys by prefix/range |
| POST | `/kv/atomic` | Atomic check-and-set mutations |
| POST | `/kv/reset` | Reset store |
| POST | `/kv/clean-expired` | Clean expired entries |
| POST | `/queue/enqueue` | Enqueue message |
| POST | `/queue/dequeue` | Dequeue messages |
| POST | `/queue/ack` | Acknowledge message |

WebSocket: `wss://<domain>/ws?token=<access_token>`

Full docs: [@coderbuzz/kvs-server](https://github.com/coderbuzz/kvs-server)

## Deployment

See [AGENTS.md](./AGENTS.md) for CI/CD setup and VM initialization.
