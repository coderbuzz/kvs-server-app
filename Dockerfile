FROM oven/bun:1-slim

WORKDIR /app

COPY package.json bun.lock ./
RUN bun install --production --frozen-lockfile

COPY src/ ./src/

RUN mkdir -p /data

ENV HOSTNAME=0.0.0.0
ENV PORT=3000
ENV DB_PATH=/data/kv.db

EXPOSE 3000

CMD ["bun", "run", "src/index.ts"]
