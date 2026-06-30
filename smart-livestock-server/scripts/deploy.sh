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
    ;;
  test)
    COMPOSE_FILE="docker-compose.test.yml"
    PROJECT="smart-livestock-server"
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

echo "==> [2/5] Syncing code to remote ($ENV)..."
rsync -avz \
  --exclude='.git' \
  --exclude='.gradle' \
  --exclude='node_modules' \
  --exclude='build/tmp' \
  --exclude='build/classes' \
  --exclude='.env' \
  --exclude='.env.dev' \
  . "$REMOTE:$REMOTE_DIR/"

echo "==> [3/5] Cleaning old JARs on remote..."
ssh "$REMOTE" "cd $REMOTE_DIR/build/libs && ls -t smart-livestock-server-*.jar 2>/dev/null | tail -n +2 | xargs -r rm -f"

echo "==> [4/5] Building and starting $ENV stack..."
ssh "$REMOTE" "cd $REMOTE_DIR && docker compose -f $COMPOSE_FILE -p $PROJECT build app && docker compose -f $COMPOSE_FILE -p $PROJECT up -d"

echo "==> [5/5] Pruning dangling images..."
ssh "$REMOTE" "docker image prune -f"

echo ""
echo "==> Deploy complete. $ENV stack is running."
if [ "$ENV" = "dev" ]; then
  echo "    Health check: curl http://172.22.1.123:19080/api/v1/actuator/health"
else
  echo "    Health check: curl http://172.22.1.123:18080/api/v1/actuator/health"
fi
