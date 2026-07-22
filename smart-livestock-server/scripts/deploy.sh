#!/usr/bin/env bash
set -euo pipefail

# Deploy script for smart-livestock-server dev/test environments
# Usage: ./scripts/deploy.sh <dev|test>

ENV="${1:-}"
REMOTE="agentic@172.22.1.123"
REMOTE_DIR="~/smart-livestock-server"

case "$ENV" in
  dev)
    COMPOSE_FILE="docker-compose.dev.yml"
    PROJECT="sl-dev"
    ENV_FILE=".env.dev"
    ;;
  test)
    COMPOSE_FILE="docker-compose.test.yml"
    PROJECT="smart-livestock-server"
    ENV_FILE=".env"
    ;;
  *)
    echo "Usage: $0 <dev|test>"
    exit 1
    ;;
esac

# Resolve repo root (parent of scripts/)
cd "$(dirname "$0")/.."

echo "==> [1/5] Building JAR (skip tests)..."
./gradlew bootJar -x test

# Clean old JARs locally — keep only the latest one.
# Without this, rsync transfers 8+ GB of accumulated old JARs every deploy.
echo "==> [1.5] Cleaning old JARs..."
cd build/libs && ls -t smart-livestock-server-*.jar 2>/dev/null | tail -n +2 | xargs -r rm -f && cd ../..

echo "==> [2/5] Syncing code to remote ($ENV)..."
rsync -avz \
  --exclude='.git' \
  --exclude='.gradle' \
  --exclude='node_modules' \
  --exclude='build/classes/' \
  --exclude='build/resources/' \
  --exclude='build/generated/' \
  --exclude='build/reports/' \
  --exclude='build/tmp/' \
  --exclude='build/test-results/' \
  --exclude='.env' \
  --exclude='.env.dev' \
  --exclude='._*' \
  . "$REMOTE:$REMOTE_DIR/"

echo "==> [3/5] Cleaning old JARs on remote..."
ssh "$REMOTE" "cd $REMOTE_DIR/build/libs && ls -t smart-livestock-server-*.jar 2>/dev/null | tail -n +2 | xargs -r rm -f"

echo "==> [4/5] Building and starting $ENV stack..."
ssh "$REMOTE" "cd $REMOTE_DIR && docker compose --env-file $ENV_FILE -f $COMPOSE_FILE -p $PROJECT build app nginx && docker compose --env-file $ENV_FILE -f $COMPOSE_FILE -p $PROJECT up -d"

echo "==> [4.5/5] Syncing tileserver data to named volume..."
# Snap Docker cannot bind-mount paths under /data/agentic, so we sync the
# project's mbtiles + config.json into the named volume after compose up.
ssh "$REMOTE" "cd $REMOTE_DIR && \
  TILE_CTR=\$(docker compose --env-file $ENV_FILE -f $COMPOSE_FILE -p $PROJECT ps -q tileserver) && \
  docker cp infrastructure/tileserver/data/. \$TILE_CTR:/data/ && \
  docker exec -u root \$TILE_CTR sh -c 'chmod -R a+rX /data && rm -f /data/._* && rm -f /data/*-shm /data/*-wal' && \
  docker restart \$TILE_CTR"

echo "==> [5/5] Pruning dangling images..."
ssh "$REMOTE" "docker image prune -f"

echo ""
echo "==> Deploy complete. $ENV stack is running."
if [ "$ENV" = "dev" ]; then
  echo "    Health check: curl http://172.22.1.123:19080/api/v1/actuator/health"
else
  echo "    Health check: curl http://172.22.1.123:18080/api/v1/actuator/health"
fi
