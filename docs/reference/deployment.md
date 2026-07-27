# 部署与环境参考

> 本文件从 AGENTS.md 拆分而来，按需引用，不随会话全量加载。

## 双环境隔离（test / dev）

单台服务器（172.22.1.123，32 核 / 126GB 内存）运行两套完全隔离的 docker-compose stack：

| 环境 | 角色 | 端口段（nginx 入口） | compose 文件 | 项目名 | env 文件 |
|------|------|---------------------|-------------|--------|---------|
| **test** | 现有 stack | `18080` | `docker-compose.test.yml` | `smart-livestock-server` | `.env` |
| **dev** | 新建 stack | `19080` | `docker-compose.dev.yml` | `sl-dev` | `.env.dev` |

两套 stack 共享同一份 Dockerfile 和构建产物，各自独立的 PostgreSQL / Redis / RocketMQ / volume，互不干扰。设计文档：`docs/superpowers/specs/2026-07-01-dev-test-env-isolation-design.md`

## blade 平台环境对应

dev stack ↔ blade dev（172.21.2.41），test stack ↔ blade test（172.22.4.17）。地址默认值写在各自 compose 文件的 `AGENTIC_PLATFORM_*` 变量中，密钥在远程 `.env` / `.env.dev` 手动维护。本项目作为 blade 外部调用方走 URL 直连，不注册 Nacos。

blade dev/test 是两套独立平台：OAuth2 client（`hkt_openapi`）相同，但服务账号各自独立（dev=`2079382969422938112`，test=`2074385063398711296`）。新建环境需按 `business-platform/hkt-blade-device-docking/README.md` 自助流程创建服务账号。设计文档：`docs/superpowers/specs/2026-07-21-blade-env-mapping-design.md`

## 一键部署（本地执行）

```bash
cd smart-livestock-server
./scripts/deploy.sh dev    # 部署到 dev 环境（端口 19080）
./scripts/deploy.sh test   # 部署到 test 环境（端口 18080）
```

脚本内部流程：编译 bootJar → rsync 同步代码（排除 .git/.gradle/.env/.env.dev 等）→ 远程清理旧 JAR → docker compose build + up → docker image prune。

注意事项：
- `.env`（test）和 `.env.dev`（dev）在远程手动维护，不随 rsync 覆盖
- tile-worker 的 Dockerfile 需要联网下载 docker-ce-cli，若服务器无法访问 download.docker.com，dev stack 可复用 test 已构建的镜像（`docker tag smart-livestock-server-tile-worker:latest sl-dev-tile-worker:latest`）
- Flutter 连接环境通过运行参数切换，不改代码：`--dart-define=API_BASE_URL=http://172.22.1.123:19080/api/v1`（dev）或 `:18080`（test）

## 种子数据登录凭据

| 角色 | 手机号 | 密码 | 说明 |
|------|--------|------|------|
| platform_admin（平台管理员） | 13800000000 | 123 | 平台级管理，无租户归属 |
| b2b_admin（B端管理员） | 13900139000 | 123 | B端管理员，关联 Demo 租户（V13 seed） |
| owner（牧场主） | 13800138000 | 123 | Demo 租户 owner，关联主牧场 |

## Seed 密码三步验证流程

Seed 迁移中的 BCrypt hash 必须严格遵循三步验证，不可跳过：

1. **生成时验证**：生成 hash 后立即用 `bcrypt.compare(plaintext, hash)` 确认匹配（可用 `scripts/verify-seed-hash.sh`）
2. **写入迁移**：确认匹配后写入 SQL 文件，不得跨迁移复制 hash（之前的 hash 可能本身就是错的）
3. **部署后验证**：部署后用 `curl` 调用 `/auth/login` 确认真实登录成功

历史教训：V4 hash 错误 → V5 "修复" 仍然错误 → V13 复制 V5 hash 延续错误。每一步都跳过了验证。

## Flyway 迁移命名规范

新增 Flyway 迁移使用时间戳版本号，格式 `V{YYYYMMDDHHmmss}__description.sql`，避免多对话并行创建时版本号冲突。

- V1-V41 已有迁移保持原样（整数版本号），不改名
- V20260701... 及以后的新迁移用时间戳格式（Flyway 按数字排序，时间戳天然大于 41）
- 安装 pre-commit hook 防止重复版本号：`cp smart-livestock-server/scripts/check-flyway-duplicates.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit`

## 前端 Live 模式连接后端

```bash
cd Mobile/mobile_app
flutter run -d chrome --dart-define=APP_MODE=live --dart-define=API_BASE_URL=http://172.22.1.123:18080/api/v1
```

## 常用命令速查

后端（smart-livestock-server/）：
```bash
./gradlew compileJava              # 编译
./gradlew test                     # 全部测试
./gradlew test --tests "*.domain.model.*"  # 领域模型单元测试
./gradlew bootRun                  # 启动（需 PostgreSQL + Redis）
docker compose up -d               # 全栈启动
```

前端（Mobile/mobile_app/）：
```bash
flutter pub get
flutter test                           # 运行所有测试
flutter analyze                        # 静态分析
flutter build web                      # 默认
./build_web.sh                         # 推荐（抑制 WASM dry-run 误报）
```
