# 开发与测试环境分离设计

## 背景与动机

当前系统仅有一套部署环境（172.22.1.123），开发、集成验证、演示全部挤在同一个 docker-compose stack 里，导致两个核心痛点：

- **A. 数据无法隔离** — 测试造数据会污染日常开发/演示数据，无法随时重置到干净状态。
- **B. 部署与验证互相阻塞** — 改代码部署会导致服务短暂中断，同一时间无法做集成验证或演示。

本设计通过在同一台服务器上运行两套完全隔离的 docker-compose stack，从根本上解决这两个问题。

## 目标与非目标

### 目标

1. **数据隔离** — 两套环境各自独立的 PostgreSQL 实例和 volume，互不干扰。
2. **并行不干扰** — 一套部署更新时，另一套正常运行不受影响。
3. **两套能力对等** — 都包含完整的 10 个服务（含 device-simulator、tile-worker、tileserver）。
4. **统一部署入口** — 一条命令部署到指定环境，降低操作出错概率。

### 非目标

- **不引入第二台服务器** — 单台 172.22.1.123 即可承载两套 stack。
- **不做生产级 staging 流程** — 本次只解决 dev/test 分离，不涉及生产环境定义。
- **不做 CI/CD 改造** — 现有 `.gitlab-ci.yml` 未实际使用，本次不改。部署仍走 rsync + 手动脚本。
- **不处理 datagen 数据量控制** — 两套都保留 datagen，数据产生量大小控制另行处理。
- **不改 Flutter 前端代码** — 连接哪个环境通过 `--dart-define` 运行参数切换，不改代码。

## 现状分析

### 服务器资源（172.22.1.123）

| 维度 | 数值 | 评估 |
|------|------|------|
| CPU | 32 核 | 充裕 |
| 内存 | 126 GB（available 81 GB） | 充裕，两套各约 24GB 无压力 |
| 磁盘 | 97 GB（已用 63 GB，剩 30 GB） | 偏紧，需 prune + 监控 |

单套 stack 内存占用约 24GB（app 10.8GB + rocketmq-broker 8.8GB + rocketmq-namesrv 2.0GB + 其余约 2.4GB）。

### 磁盘消耗拆解

| 类别 | 占用 | 备注 |
|------|------|------|
| Docker 镜像 | 15.5 GB | 其中 8.4GB 可回收（旧版本堆积） |
| Build Cache | 7.4 GB | 其中 2.7GB 可回收 |
| 容器层 | 7.1 GB | 27 个容器 |
| PG 数据卷 | 2.47 GB | 实际库约 960MB |
| 可即时回收 | ~11 GB | `docker image prune -f` + `docker builder prune -f` |

关键洞察：**磁盘大头是 Docker 镜像层而非数据库**。两套 stack 共享同一份 app 镜像构建产物，镜像层不会翻倍，因此新增 stack 的磁盘开销可控。

## 设计方案

### 环境角色定义

| 环境 | 角色 | 状态 | 端口段 |
|------|------|------|--------|
| **test** | 测试环境 | 现有 stack，改名保留 | 18xxx / 15xxx |
| **dev** | 开发环境 | 新建 stack | 19xxx / 16xxx |

test 环境的容器名（`smart-livestock-server-{svc}-1`）和 volume 名保持不变，仅 compose 文件改名。dev 环境使用项目名 `sl-dev`，容器名 `sl-dev-{svc}-1`，volume 名 `sl-dev_*`。

### 端口与命名规划

| 服务 | test（现有） | dev（新建） |
|------|-------------|------------|
| nginx（入口） | 18080 | 19080 |
| app（Spring Boot） | 18081 | 19081 |
| ai-platform | 18000 | 19000 |
| device-simulator | 18002 | 19002 |
| postgres | 15432 | 16432 |
| redis | 26379 | 26380 |
| rocketmq-namesrv | 19876 | 19877 |
| rocketmq-broker | 10911 | 10912 |
| rocketmq-dashboard | 18082 | 19082 |
| tileserver | 8081 | 9081 |

rocketmq-broker 监听端口 10911 和 10912（dev 占用 10912），需确认两个 broker 的 `listenPort` 配置互不冲突（见 broker 配置细节章节）。

### 文件组织

一份代码、一个 Dockerfile、两个 compose 文件，共享同一份构建产物。

**本地仓库结构：**

```
smart-livestock-server/
├── docker-compose.test.yml     # test stack（现有 docker-compose.yml 改名）
├── docker-compose.dev.yml      # dev stack（新建）
├── .env                        # test 环境配置（现有，不提交）
├── .env.dev                    # dev 环境配置（新建，不提交）
├── .env.example                # 模板（更新，补充 .env.dev 示例）
├── Dockerfile                  # 两套共用
├── scripts/
│   └── deploy.sh               # 统一部署入口
└── ...
```

**远程服务器结构（172.22.1.123）：**

```
~/smart-livestock-server/       # 单一目录，rsync 同步全部代码
├── docker-compose.test.yml
├── docker-compose.dev.yml
├── .env                        # 远程手动维护（不随 rsync 覆盖）
├── .env.dev                    # 远程手动维护
├── Dockerfile
├── build/libs/*.jar            # 共享构建产物
└── ...
```

两个 compose 文件唯一差异：**项目名、端口段、volume 名**。Dockerfile、build context、服务定义完全相同。镜像由 Docker 共享层去重。

### Compose 文件差异说明

两个文件结构完全相同，以下只列差异项：

| 差异点 | docker-compose.test.yml | docker-compose.dev.yml |
|--------|------------------------|------------------------|
| 项目名（`-p`） | `smart-livestock-server`（默认，可省略） | `sl-dev`（必须显式指定） |
| 端口映射 | 18080/18081/18000/... | 19080/19081/19000/... |
| volume 名前缀 | `smart-livestock-server_`（默认） | `sl-dev_`（由 project name 推导） |
| env_file | `.env` | `.env.dev` |
| 项目内 volume 名 | `pgdata` / `tileserver-data` | `pgdata` / `tileserver-data`（project name 自动加前缀） |

注：Docker Compose 的 volume 名格式为 `{project_name}_{volume_name}`，因此 test 是 `smart-livestock-server_pgdata`，dev 是 `sl-dev_pgdata`，天然隔离。

### 环境配置与密钥分离

两个环境各自独立的 `.env` 文件：

| 配置项 | test（.env） | dev（.env.dev） | 说明 |
|--------|-------------|----------------|------|
| `JWT_SECRET` | 现有值 | 独立随机值（`openssl rand -base64 48`） | 两套 token 不互通 |
| `DB_*` / `REDIS_*` / `ROCKETMQ_*` | 内部网络服务名 | 内部网络服务名 | 各自实例，服务名相同但实例独立 |
| `DATAGEN_ENABLED` | true | true | 两套都开 |
| `SIMULATOR_*_KEY` | 现有值 | 独立随机值 | API Key 各自独立 |

密钥生成方式：`openssl rand -base64 48`，在 dev 环境首次初始化时生成并写入 `.env.dev`。`.env.dev` 加入 `.gitignore`，不提交仓库。

### 部署流程

统一部署脚本 `scripts/deploy.sh`，接受环境参数：

```bash
# 用法
./scripts/deploy.sh dev    # 部署到 dev 环境
./scripts/deploy.sh test   # 部署到 test 环境
```

脚本逻辑（以 dev 为例）：

1. 本地编译：`./gradlew bootJar -x test`
2. rsync 代码到远程 `~/smart-livestock-server/`（排除 .git/.gradle/build 临时文件等）
3. 远程构建镜像：`docker compose -f docker-compose.dev.yml -p sl-dev build app`
4. 远程启动：`docker compose -f docker-compose.dev.yml -p sl-dev up -d`
5. 清理悬空镜像：`docker image prune -f`
6. 清理旧 JAR：保留最新版本

脚本需处理的边界：
- 参数校验（只接受 `dev` / `test`）
- rsync 排除规则与现有排除项一致
- 远程 `.env` / `.env.dev` 不被 rsync 覆盖（rsync 只推代码和 compose 文件，env 文件远程手动维护或首次推送后不覆盖）

### Test 环境迁移步骤

现有 `docker-compose.yml` 改名为 `docker-compose.test.yml`，需要一次性短暂停服：

1. 停服：`docker compose -f docker-compose.yml -p smart-livestock-server down`
2. 改名：`mv docker-compose.yml docker-compose.test.yml`
3. 重启：`docker compose -f docker-compose.test.yml -p smart-livestock-server up -d`
4. 验证：`curl http://172.22.1.123:18080/api/v1/actuator/health`

容器名、volume 名不变（project name 保持 `smart-livestock-server`），数据不丢。停服时间约 1-2 分钟。

### RocketMQ Broker 端口冲突处理

dev stack 的 rocketmq-broker 监听端口为 10912（test 是 10911）。需要在 `docker-compose.dev.yml` 的 broker 服务中通过端口映射区分：

```yaml
rocketmq-broker:
  image: apache/rocketmq:5.1.0
  command: sh mqbroker -n rocketmq-namesrv:9876
  ports:
    - "10912:10911"   # host 10912 -> container 10911
  environment:
    JAVA_OPT: "-Duser.home=/home/rocketmq"
```

容器内部 broker 始终监听 10911，通过宿主机端口映射区分即可，无需改 broker 的 `listenPort` 配置。两个 stack 各自有独立的 compose 网络，broker 间无跨网络通信。

### 前端连接切换

Flutter live 模式通过运行参数切换连接环境，不改代码：

```bash
# 连 test（现有）
flutter run --dart-define=APP_MODE=live --dart-define=API_BASE_URL=http://172.22.1.123:18080/api/v1

# 连 dev（新增）
flutter run --dart-define=APP_MODE=live --dart-define=API_BASE_URL=http://172.22.1.123:19080/api/v1
```

## 磁盘管理

### 部署内置清理（方案 1）

每次 `deploy.sh` 执行完毕自动运行 `docker image prune -f`，清理悬空旧镜像。简单有效，无需额外运维。

### 磁盘监控告警（方案 3）

服务器已有监控栈（smg-prometheus + smg-grafana）。本次设计记录方案，实施延后单独做：

1. 确认 smg 监控栈是否包含 node-exporter（磁盘指标来源）
2. 在 Grafana 添加磁盘使用率 dashboard panel
3. 配置告警规则：磁盘使用率 > 85% 时触发通知

延后原因：监控告警是锦上添花，不阻塞 dev 环境核心搭建；需先确认现有监控栈细节才能给出准确配置。

## 实施产出物清单

| 序号 | 文件 | 操作 | 说明 |
|------|------|------|------|
| 1 | `docker-compose.test.yml` | 改名 | 现有 `docker-compose.yml` 改名 |
| 2 | `docker-compose.dev.yml` | 新建 | 19xxx 端口段，项目名 sl-dev |
| 3 | `.env.dev` | 新建 | 独立密钥，加入 .gitignore |
| 4 | `.env.example` | 更新 | 补充 dev 环境配置说明 |
| 5 | `scripts/deploy.sh` | 新建 | 统一部署入口 |
| 6 | `.gitignore` | 更新 | 补充 `.env.dev` |

## 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 磁盘空间不足 | 两套 stack 运行不稳定 | 部署脚本内置 prune；监控方案已设计待实施 |
| test 改名停服 | 集成验证/演示中断 1-2 分钟 | 安排在低峰期操作 |
| rocketmq-broker 端口冲突 | dev broker 启动失败 | 端口映射区分（10912），实施时验证 |
| `.env` 被 rsync 覆盖 | 远程密钥丢失 | deploy.sh 中 env 文件不纳入 rsync 同步范围 |
