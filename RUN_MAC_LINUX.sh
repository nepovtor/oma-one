#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
command -v node >/dev/null || { echo 'Установите Node.js 20 или новее.'; exit 1; }
if [ -z "${DATABASE_URL:-}" ]; then
  export DATABASE_URL='postgresql://oma:oma@127.0.0.1:55432/oma_one'
  if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
    docker compose up -d --wait db
  elif ! command -v pg_isready >/dev/null || ! pg_isready -d "$DATABASE_URL" >/dev/null 2>&1; then
    echo 'PostgreSQL не запущен. Запустите compose.yaml или задайте DATABASE_URL.'
    exit 1
  fi
fi
echo 'OMA ONE запущен: http://localhost:8787'
node server.mjs
