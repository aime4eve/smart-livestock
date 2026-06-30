# 开发与测试环境分离实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在单台服务器（172.22.1.123）上运行两套完全隔离的 docker-compose stack（test + dev），实现数据隔离和并行互不干扰。

**Architecture:** 一份代码、一个 Dockerfile、两个 compose 文件。现有 stack 改名为 test（`docker-compose.test.yml`，端口段 18xxx），新建 dev stack（`docker-compose.dev.yml`，端口段 19xxx，项目名 `sl-dev`）。统一部署脚本 `scripts/deploy.sh` 接受环境参数，编译 → rsync → 远程 build+up → 清理。

**Tech Stack:** Docker Compose, Bash, rsync, SSH

**设计文档:** `docs/superpowers/specs/2026-07-01-dev-test-env-isolation-design.md`

---

## 计划与 Spec 的偏差说明

以下三点在实施准备中发现，与 spec 略有偏差：

1. **`.gitignore` 无需修改** — 现有 `.gitignore` 已包含 `.env.*` 通配符规则，`.env.dev` 天然被排除，不需要单独添加。
2. **`.env.dev` 不提交、远程手动维护** — Agent 创建 `.env.dev.example` 模板供参考，实际 `.env.dev` 由用户在远程手动创建（deploy.sh 的 rsync 排除 `.env` 和 `.env.dev`，不覆盖远程配置）。
3. **device-simulator 未在 compose 中定义** — 本地 `docker-compose.yml` 实际只定义了 9 个服务（不含 device-simulator），远程的 device-simulator 容器是旧版本遗留。dev/test compose 均不含此服务，如需保留另行处理。

## 文件结构

| 文件 | 操作 | 职责 |
|------|------|------|
| `docker-compose.test.yml` | 改名（git mv） | test stack 定义，端口段 18xxx |
| `docker-compose.dev.yml` | 新建 | dev stack 定义，端口段 19xxx，项目名 sl-dev |
| `scripts/deploy.sh` | 新建 | 统一部署入口，接受 dev/test 参数 |
| `.env.example` | 修改 | 补充 SIMULATOR key 和 dev 环境说明 |
| `.env.dev.example` | 新建 | dev 环境配置模板（实际 .env.dev 远程手动维护） |

## 约定

- **Agent 负责**：创建/修改仓库文件、YAML 语法验证、Bash 语法验证、git 提交
- **用户负责**：rsync 部署、docker compose 操作、远程 .env / .env.dev 维护、部署后集成测试

---

### Task 1: docker-compose.yml 改名为 docker-compose.test.yml

用 `git mv` 保留历史，内容不做任何改动。

**Files:**
- Rename: `smart-livestock-server/docker-compose.yml` → `smart-livestock-server/docker-compose.test.yml`

- [ ] **Step 1: git mv**

```bash
cd smart-livestock-server
git mv docker-compose.yml docker-compose.test.yml
```

- [ ] **Step 2: 验证 YAML 语法**

```bash
docker compose -f docker-compose.test.yml config --quiet
```

Expected: 无输出，exit code 0（YAML 语法正确）

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "infra: docker-compose.yml 改名为 docker-compose.test.yml"
```

---

### Task 2: 创建 docker-compose.dev.yml

基于 test compose 内容，修改三组值：端口段（18xxx → 19xxx / 15xxx → 16xxx）、broker 端口（10911 → 10912）、env_file（.env → .env.dev）。

**Files:**
- Create: `smart-livestock-server/docker-compose.dev.yml`

- [ ] **Step 1: 创建 docker-compose.dev.yml**

完整文件内容（基于 test 的 9 个服务，端口段全部改为 19xxx/16xxx，env_file 改为 .env.dev，broker 端口改为 10912）：

```yaml
services:
  postgres:
    build: ./infrastructure/postgres
    command: ["postgres", "-c", "hba_file=/etc/postgresql/pg_hba.conf"]
    environment:
      POSTGRES_DB: smart_livestock
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "16432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "26380:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

  rocketmq-namesrv:
    image: apache/rocketmq:5.1.0
    command: sh mqnamesrv
    ports:
      - "19877:9876"

  rocketmq-broker:
    image: apache/rocketmq:5.1.0
    command: sh mqbroker -n rocketmq-namesrv:9876
    depends_on:
      - rocketmq-namesrv
    ports:
      - "10912:10911"
    environment:
      JAVA_OPT: "-Duser.home=/home/rocketmq"

  rocketmq-dashboard:
    image: apacherocketmq/rocketmq-dashboard:latest
    ports:
      - "19082:8082"
    environment:
      JAVA_OPTS: "-Drocketmq.namesrv.addr=rocketmq-namesrv:9876"
    depends_on:
      - rocketmq-namesrv

  app:
    build: .
    ports:
      - "19081:8080"
    env_file:
      - .env.dev
    volumes:
      - tileserver-data:/data:ro
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: smart_livestock
      DB_USER: postgres
      DB_PASSWORD: postgres
      REDIS_HOST: redis
      REDIS_PORT: 6379
      ROCKETMQ_NAME_SERVER: rocketmq-namesrv:9876
      AI_PLATFORM_URL: http://ai-platform:8000
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      rocketmq-broker:
        condition: service_started
      ai-platform:
        condition: service_healthy
    restart: unless-stopped

  ai-platform:
    build:
      context: ./ai-platform
    ports:
      - "19000:8000"
    environment:
      AI_DB_HOST: postgres
      AI_DB_PORT: 5432
      AI_DB_NAME: smart_livestock
      AI_DB_USER: ${AI_DB_USER:-postgres}
      AI_DB_PASSWORD: ${AI_DB_PASSWORD:-postgres}
    depends_on:
      postgres:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/ai/health/live')"]
      interval: 10s
      timeout: 3s
      retries: 5
    restart: unless-stopped

  tileserver:
    image: maptiler/tileserver-gl:latest
    volumes:
      - tileserver-data:/data
    ports:
      - "9081:8080"
    command: ["-c", "config.json", "--port", "8080"]
    restart: unless-stopped

  nginx:
    build:
      context: .
      dockerfile: infrastructure/nginx/Dockerfile
    ports:
      - "19080:80"
    depends_on:
      - app

  tile-worker:
    build:
      context: .
      dockerfile: infrastructure/tile-worker/Dockerfile
    environment:
      API_URL: http://app:8080/api/v1
      SMART_LIVESTOCK_API_KEY: "${SMART_LIVESTOCK_TILE_WORKER_KEY:-sl_live_tile_worker_a1b2c3d4e5f6g7h8i9j0k1l2}"
      OUTDIR: /data
      POLL_INTERVAL: "60"
      TILE_CONCURRENCY: "${TILE_CONCURRENCY:-8}"
    volumes:
      - tileserver-data:/data
      - /var/run/docker.sock:/var/run/docker.sock
    depends_on:
      - app
    restart: unless-stopped

volumes:
  pgdata:
  tileserver-data:
```

与 test 的差异说明：
- postgres 端口 `15432` → `16432`
- redis 端口 `26379` → `26380`
- rocketmq-namesrv 端口 `19876` → `19877`
- rocketmq-broker 端口 `10911` → `10912`（宿主机端口映射区分，容器内仍 10911）
- rocketmq-dashboard 端口 `18082` → `19082`
- app 端口 `18081` → `19081`，env_file `.env` → `.env.dev`
- ai-platform 端口 `18000` → `19000`
- tileserver 端口 `8081` → `9081`
- nginx 端口 `18080` → `19080`

- [ ] **Step 2: 验证 YAML 语法**

```bash
docker compose -f docker-compose.dev.yml config --quiet
```

Expected: 无输出，exit code 0

- [ ] **Step 3: Commit**

```bash
git add docker-compose.dev.yml
git commit -m "infra: 新建 docker-compose.dev.yml — dev 环境 19xxx 端口段"
```

---

### Task 3: 创建 scripts/deploy.sh

统一部署脚本，接受 `dev` / `test` 参数，内部完成编译 → rsync → 远程 build+up → 清理。

**Files:**
- Create: `smart-livestock-server/scripts/deploy.sh`

- [ ] **Step 1: 创建 deploy.sh**

完整脚本内容：

```bash
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
```

- [ ] **Step 2: 验证 Bash 语法**

```bash
bash -n scripts/deploy.sh
```

Expected: 无输出，exit code 0

- [ ] **Step 3: 添加可执行权限并 Commit**

```bash
chmod +x scripts/deploy.sh
git add scripts/deploy.sh
git commit -m "infra: 统一部署脚本 scripts/deploy.sh — dev/test 一键部署"
```

---

### Task 4: 更新 .env.example + 创建 .env.dev.example

补充实际 `.env` 中已有但 `.env.example` 缺失的配置项，并创建 dev 环境模板。

**Files:**
- Modify: `smart-livestock-server/.env.example`
- Create: `smart-livestock-server/.env.dev.example`

- [ ] **Step 1: 更新 .env.example**

完整内容（在现有基础上补充 SIMULATOR keys）：

```env
# ============================================
# Smart Livestock Server - Environment Config
# Copy to .env (test) or .env.dev (dev)
# ============================================

# Database
DB_HOST=postgres
DB_PORT=5432
DB_NAME=smart_livestock
DB_USER=postgres
DB_PASSWORD=your-secure-password

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=

# RocketMQ
ROCKETMQ_NAME_SERVER=rocketmq-namesrv:9876

# JWT (generate with: openssl rand -base64 48)
JWT_SECRET=your-secure-jwt-secret-change-this
JWT_ACCESS_EXPIRATION=3600000
JWT_REFRESH_EXPIRATION=604800000

# Server
SERVER_PORT=8080

# Device Simulator API Keys (generate unique per environment)
SIMULATOR_DEVICE_REGISTER_KEY=your-device-register-key
SIMULATOR_FENCE_SYNC_KEY=your-fence-sync-key
```

- [ ] **Step 2: 创建 .env.dev.example**

与 .env.example 内容相同，但标注为 dev 环境模板，密钥标注需要重新生成：

```env
# ============================================
# Smart Livestock Server - DEV Environment Config
# Copy to .env.dev and fill with real values
# Generate keys: openssl rand -base64 48
# ============================================

# Database
DB_HOST=postgres
DB_PORT=5432
DB_NAME=smart_livestock
DB_USER=postgres
DB_PASSWORD=your-secure-dev-password

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=

# RocketMQ
ROCKETMQ_NAME_SERVER=rocketmq-namesrv:9876

# JWT — MUST be different from test environment
JWT_SECRET=generate-with-openssl-rand-base64-48
JWT_ACCESS_EXPIRATION=3600000
JWT_REFRESH_EXPIRATION=604800000

# Server
SERVER_PORT=8080

# Device Simulator API Keys — MUST be different from test environment
SIMULATOR_DEVICE_REGISTER_KEY=generate-unique-key
SIMULATOR_FENCE_SYNC_KEY=generate-unique-key
```

- [ ] **Step 3: Commit**

```bash
git add .env.example .env.dev.example
git commit -m "infra: 更新 .env.example + 新建 .env.dev.example 模板"
```

---

### Task 5: 远程 .env.dev 初始化 + test 环境迁移 + 首次部署（用户执行）

此任务全部由用户在部署阶段执行，Agent 提供命令但不执行。

**Files:**
- 无本地文件变更
- 远程操作：创建 .env.dev、迁移 test compose、首次部署 dev

- [ ] **Step 1: 在远程创建 .env.dev（用户执行）**

登录远程服务器，生成独立密钥并创建 .env.dev：

```bash
ssh agentic@172.22.1.123
cd ~/smart-livestock-server

# Generate independent secrets for dev
JWT_DEV=$(openssl rand -base64 48)
SIM_REG_DEV=$(openssl rand -hex 24)
SIM_FENCE_DEV=$(openssl rand -hex 24)

cat > .env.dev << DEVENV
DB_HOST=postgres
DB_PORT=5432
DB_NAME=smart_livestock
DB_USER=postgres
DB_PASSWORD=postgres
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=
ROCKETMQ_NAME_SERVER=rocketmq-namesrv:9876
JWT_SECRET=$JWT_DEV
JWT_ACCESS_EXPIRATION=3600000
JWT_REFRESH_EXPIRATION=604800000
SERVER_PORT=8080
SIMULATOR_DEVICE_REGISTER_KEY=$SIM_REG_DEV
SIMULATOR_FENCE_SYNC_KEY=$SIM_FENCE_DEV
DEVENV

echo "Created .env.dev with independent secrets"
```

- [ ] **Step 2: 部署 test 环境（迁移 compose 文件名）（用户执行）**

先部署 test，触发 compose 文件名迁移（deploy.sh 内部完成 rsync + remote build/up）：

```bash
cd smart-livestock-server
./scripts/deploy.sh test
```

deploy.sh 在远程执行 `docker compose -f docker-compose.test.yml -p smart-livestock-server build app && up -d`。project name 保持 `smart-livestock-server` 不变，容器名和 volume 名不变，数据不丢。

迁移后删除远程旧的 docker-compose.yml（rsync 不删文件）：

```bash
ssh agentic@172.22.1.123 "rm ~/smart-livestock-server/docker-compose.yml"
```

- [ ] **Step 3: 首次部署 dev 环境（用户执行）**

```bash
cd smart-livestock-server
./scripts/deploy.sh dev
```

dev stack 首次启动需要拉取镜像和初始化 PG volume，预计 3-5 分钟。

- [ ] **Step 4: 验证两个环境独立运行（用户执行）**

```bash
# Test environment health check
curl http://172.22.1.123:18080/api/v1/actuator/health

# Dev environment health check
curl http://172.22.1.123:19080/api/v1/actuator/health

# Verify two independent PostgreSQL containers
ssh agentic@172.22.1.123 "docker ps --format '{{.Names}}' | grep postgres"

# Verify two independent volumes
ssh agentic@172.22.1.123 "docker volume ls | grep pgdata"
```

Expected output:
- 两个 health check 返回 UP
- 两个 postgres 容器：`smart-livestock-server-postgres-1` 和 `sl-dev-postgres-1`
- 两个 volume：`smart-livestock-server_pgdata` 和 `sl-dev_pgdata`

---

## Self-Review

**1. Spec coverage:**

| Spec 产出物 | 对应 Task | 状态 |
|------------|----------|------|
| docker-compose.test.yml 改名 | Task 1 | covered |
| docker-compose.dev.yml 新建 | Task 2 | covered |
| .env.dev 独立密钥 | Task 5 Step 1（用户远程创建） | covered |
| .env.example 更新 | Task 4 | covered |
| scripts/deploy.sh 新建 | Task 3 | covered |
| .gitignore 更新 | 无需（已有 .env.* 规则） | 偏差已说明 |

**2. Placeholder scan:** 无 TBD/TODO，所有代码完整。

**3. Type consistency:** 端口号、项目名、文件名在各 Task 间一致。deploy.sh 中的端口与端口表一致。

**4. Broker 端口冲突处理:** dev compose 使用 `10912:10911`（宿主机 10912 -> 容器 10911），与 test 的 `10911:10911` 不冲突。两个 broker 在各自独立的 compose 网络中运行，无跨网络通信。
