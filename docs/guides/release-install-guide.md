# 智慧畜牧市场测试版 安装部署指南（release）

> **读者**: 交付工程师。覆盖从发布包获取到系统可用的完整安装流程，以及 ONPREM 环境的首次离线授权。
> **配套文档**: 运行维护（`release-operations-guide.md`）、发布检查清单（`release-checklist.md`）、FAQ（`docs/marketing/technical-support-guide.md`）、测试用例（`docs/testing/market-beta-test-cases.md`）。
> **对应 NIX-184 任务卡**: T8a/T8b（compose 基线 + 发布脚本）、T9b（本指南）。

---

## 1. 部署形态总览

单主机离线部署：9 个容器服务（nginx / app / postgres / redis / rocketmq-namesrv / rocketmq-broker / ai-platform / tileserver / tile-worker），只有 **nginx 暴露宿主机 80/443**，其余服务仅限 compose 内网互访。所有镜像预构建并随包携带（`docker load` 离线导入），安装机**不需要任何构建上下文或外网**。

两种授权模式（互斥，安装前必须选定，见 §5.2）：

| 模式 | 含义 | 授权方式 |
|------|------|---------|
| `HOSTED` | 厂商托管（跑在厂商自己的服务器上） | 订阅自助 + platform_admin 开通 365 天试点；地端离线授权端点不可用 |
| `ONPREM` | 客户机房（客户自有硬件，可完全离线） | 离线 `.sllicense` 授权文件导入驱动订阅；试点/自助订阅端点禁用 |

---

## 2. 硬件与软件要求（对齐 install-release.sh preflight）

安装脚本的预检与下表逐项对应，**任一项不通过则整个预检失败，且在触碰 docker 状态前一次性报齐所有问题**。

| 项目 | 要求 | 预检行为 |
|------|------|---------|
| 操作系统 | Linux（`/etc/machine-id` 是 ONPREM 授权指纹源） | 非 Linux 直接拒绝 |
| Docker | ≥ 20，daemon 可用 | 读 `docker version` Server 版本 |
| Compose | v2 插件（`docker compose version` 可用） | 失败即拒绝 |
| CPU | ≥ 8 核（`nproc`） | 可用 `MIN_CPU_CORES` 覆盖 |
| 内存 | ≥ 16 GB（`/proc/meminfo`） | 可用 `MIN_MEM_GB` 覆盖 |
| 磁盘 | release 目录所在分区可用空间 ≥ 100 GB | 可用 `MIN_DISK_GB` 覆盖 |
| 宿主端口 | HTTP_PORT(80)、HTTPS_PORT(443) 空闲 | TCP 连接探测，占用即拒绝 |
| TLS 证书 | `secrets/certs/{fullchain.pem,privkey.pem}` 存在且未过期 | 过期/不可读即拒绝 |
| 工具 | `curl` 或 `wget`（健康探测）、`openssl`（证书检查） | — |

> 阈值仅为资源下限自检，可用环境变量临时放宽（如小规格验证机）：`MIN_CPU_CORES=4 MIN_MEM_GB=8 ./scripts/install-release.sh`。生产环境不建议放宽。
> 健康等待超时默认 300 秒（app 容器 `start_period` 为 120 秒），慢盘可用 `HEALTH_TIMEOUT_SECS=600` 覆盖。

---

## 3. 发布包获取与校验

### 3.1 包结构

构建机执行 `smart-livestock-server/scripts/build-release-package.sh`（**仅构建机运行**，需 JDK17 + Flutter + docker）产出：

```text
smart-livestock-market-beta-<version>.tar.gz
├── images.tar.gz                 # 8 个镜像（9 服务共用，apache/rocketmq 由 namesrv+broker 共享）
├── SHA256SUMS                    # images.tar.gz + release/ 全部文件的 SHA-256
└── release/
    ├── docker-compose.release.yml
    ├── .env.release.example
    ├── RELEASE_VERSION           # 包内镜像标签（安装时必须与 .env.release 的 RELEASE_VERSION 一致）
    ├── scripts/                  # install-release / check-release-health / backup-release /
    │                             # restore-release / verify-release-bundle（仅这 5 个目标机脚本）
    ├── docs/                     # 本指南 + 运维指南 + 检查清单
    └── infrastructure/nginx/nginx.release.conf
```

> 构建参数：`--version <v>` 指定镜像标签与包名（默认取 `build.number`）；`--skip-web` 复用已构建的 Flutter web 产物；`--out <dir>` 指定输出目录。**issuer、私钥、授权文件绝不进包**（见 §10 安全红线）。

### 3.2 传输与校验（目标机执行）

```bash
# 构建机 → 目标机传输
scp smart-livestock-market-beta-<version>.tar.gz user@<目标机>:/opt/

# 目标机：解包 + 双重校验
cd /opt
tar xzf smart-livestock-market-beta-<version>.tar.gz
cd smart-livestock-market-beta-<version>

# ① SHA256SUMS 逐文件校验（发现传输损坏/篡改立即失败）
sha256sum -c SHA256SUMS

# ② 发布包契约检查（13 项，见下表）
./release/scripts/verify-release-bundle.sh .
```

`verify-release-bundle.sh` 的 13 项 PASS 断言：

| # | 断言 | # | 断言 |
|---|------|---|------|
| 1 | `images.tar.gz` 存在 | 8 | 无 `*.pem` 文件（证书由用户安装时自备） |
| 2 | `SHA256SUMS` 存在 | 9 | 无 `*.sllicense` 授权文件 |
| 3 | `release/docker-compose.release.yml` 存在 | 10 | compose 硬编码 `DATAGEN_ENABLED="false"` |
| 4 | `release/.env.release.example` 存在 | 11 | compose 硬编码 `TELEMETRY_SIMULATOR_ENABLED="false"` |
| 5 | SHA256SUMS 全部校验通过 | 12 | compose 无 `build:` 段（纯预构建镜像） |
| 6 | 包内无 `license-issuer*` 路径 | 13 | `ports:` 仅存在于 nginx |
| 7 | 无 `BEGIN ... PRIVATE KEY` 私钥材料 | | |

> 局限（脚本头注释已声明）：grep 无法透视 gzip，私钥/issuer 扫描覆盖解压后的文件树；ports/build 断言基于缩进解析，依赖 compose 文件的规范排版。

---

## 4. TLS 证书准备

证书不随包携带，安装前放到包内 `release/secrets/certs/`：

```bash
cd release
mkdir -p secrets/certs
# 放置正式证书：
#   secrets/certs/fullchain.pem   （证书链）
#   secrets/certs/privkey.pem     （私钥）
chmod 600 secrets/certs/privkey.pem

# 仅冒烟验证可用自签证书（浏览器会告警，正式交付勿用）：
cd secrets/certs && \
openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout privkey.pem -out fullchain.pem -subj "/CN=<你的域名或IP>" && cd ../..
```

要点：

- nginx 443 终结 TLS（TLSv1.2/1.3），80 端口全局 301 跳转 HTTPS。
- 证书以只读 bind-mount 挂进 nginx 容器（见 `docker-compose.release.yml`），更换证书后 `docker compose restart nginx` 即可，无需重建镜像（运维详见运维指南 §6）。
- `nginx.release.conf` 在构建时烤入镜像、不读 compose 环境变量：80 跳转固定指向 443。若自定义 `HTTPS_PORT`，需同步调整该配置并重建 nginx 镜像（默认 80/443 无需处理）。

---

## 5. .env.release 配置

### 5.1 必填键表（install-release.sh 逐项强校验）

```bash
cd release
cp .env.release.example .env.release
chmod 600 .env.release
```

| 键 | 必填 | 校验规则 | 说明 |
|----|------|---------|------|
| `RELEASE_VERSION` | ✅ | 非空，且必须等于包内 `release/RELEASE_VERSION` | 镜像标签 `smart-livestock/<svc>:<version>`，不一致时安装器拒绝（避免 up 时镜像找不到） |
| `HTTP_PORT` / `HTTPS_PORT` | ✅ | 非空，宿主机未占用 | 仅 nginx 使用，默认 80 / 443 |
| `SMARTLIVESTOCK_LICENSE_MODE` | ✅ | 只允许 `HOSTED` 或 `ONPREM` | 授权模式（见 §5.2） |
| `SMARTLIVESTOCK_PILOT_LICENSE_ENABLED` | ✅ | 非空 | 365 天试点开关；ONPREM 下应为 `false`（`true` 会被警告：HOSTED 专属） |
| `DATAGEN_ENABLED` | ✅ | 必须 `false` | 发布契约；compose 层还硬编码了一道 false（双保险） |
| `TELEMETRY_SIMULATOR_ENABLED` | ✅ | 必须 `false` | 同上 |
| `POSTGRES_PASSWORD` | ✅ | 非模板占位符 | 单一口令源：postgres / app / ai-platform 共用 |
| `JWT_SECRET` | ✅ | 非模板占位符 | `openssl rand -base64 48` 生成 |
| `SMART_LIVESTOCK_TILE_WORKER_KEY` | ✅ | 非模板占位符 | tile-worker 调用 app /api/v1 的 API Key |
| `AGENTIC_PLATFORM_OAUTH2_ENABLED` | 条件 | 为 `true` 时 CLIENT_ID/CLIENT_SECRET 必填且非占位 | blade 平台 OAuth2；不用 blade 保持 `false` |
| `SMARTLIVESTOCK_TB_ENABLED` | 条件 | 为 `true` 时 USERNAME/PASSWORD 必填且非占位 | ThingsBoard 遥测源，默认 `false` |
| `SMARTLIVESTOCK_NS_ENABLED` | 条件 | 为 `true` 时 USERNAME/PASSWORD 必填且非占位 | NS 遥测源，默认 `false` |

> 密钥生成：`openssl rand -base64 48`。模板值（`CHANGE_ME_*` / `your-*` / `generate-*` 等）会被安装器识别为「未填写」并拒绝。
> 内部路由键（`DB_HOST=postgres`、`REDIS_HOST=redis`、`ROCKETMQ_NAME_SERVER=rocketmq-namesrv:9876` 等）保持模板值不动：compose 已显式钉死到服务名，指向外部地址不会生效。

### 5.2 SMARTLIVESTOCK_LICENSE_MODE：HOSTED / ONPREM 选择与信任边界

| 维度 | `HOSTED`（厂商托管） | `ONPREM`（客户机房） |
|------|---------------------|---------------------|
| 信任边界 | 厂商运营，客户经 App/浏览器访问 | 客户完全掌控主机，厂商无法直接进入 |
| 授权驱动 | commerce 订阅（自助开通/升级/取消 + 365 天试点） | 离线 `.sllicense` 导入驱动订阅；订阅与主机指纹绑定 |
| 试点授权 API（`POST /admin/tenants/{id}/pilot-license`） | ✅（需 `SMARTLIVESTOCK_PILOT_LICENSE_ENABLED=true`） | ❌ 403 |
| 地端授权 API（enrollment / import / current） | ❌ 403（`license.onpremOnly`） | ✅ |
| 自助订阅端点 | ✅ | ❌ 403 `LICENSE_REQUIRED`（订阅只能由授权文件驱动） |
| 业务 API 授权门禁 | 无（行为与 dev/test 一致） | PENDING_ACTIVATION / SUSPENDED 时阻断业务 API，仅登录与授权管理可达 |
| 指纹来源 | 不读取 | Linux `/etc/machine-id`（compose 只读挂载进 app 容器） |
| 发布默认值 | — | `SMARTLIVESTOCK_LICENSE_MODE=ONPREM` |

> 判断依据很简单：**这套部署装在谁的服务器上**。厂商云主机选 HOSTED，客户机房（尤其离线内网）选 ONPREM。装错模式不会导致功能异常崩溃，但对应 API 组会 403，前端会按 `/mode` 端点渲染成另一种形态——交付前务必核对。

---

## 6. 安装步骤（install-release.sh 全流程）

前置：§3 校验通过、§4 证书就位、§5 `.env.release` 填写完毕。以下命令均在目标机 `release/` 目录执行：

```bash
cd /opt/smart-livestock-market-beta-<version>/release

./scripts/install-release.sh
```

脚本自动完成（顺序执行，预检全部通过前**不会触碰 docker 状态**）：

1. **Preflight**（§2 全部检查 + env 键校验 + 镜像标签一致性 + 端口空闲 + 证书有效期），问题一次性报齐后失败退出。
   - 首次运行若 `.env.release` 不存在，会从模板复制一份（`chmod 600`）并退出，提示填写后重跑。
2. **docker load** 导入 `images.tar.gz`（几分钟）。
3. **docker compose up -d** 启动 9 服务（app 会等 postgres/redis/rocketmq/ai-platform 健康后才启动）。
4. **等待健康**：轮询 `https://localhost:<HTTPS_PORT>/health` 直至 200（默认 300 秒超时；超时会打印 app 最近 50 行日志辅助定位）。

成功输出形如：

```text
[OK] version : <version> (images smart-livestock/<svc>:<version>)
[OK] entry   : https://<hostname>:443/
Next: run ./scripts/check-release-health.sh for the full health report.
```

---

## 7. 首次授权流程（ONPREM）

ONPREM 部署启动后处于 `PENDING_ACTIVATION`：可登录、可查看登记信息，但业务 API 全部被阻断（403 `LICENSE_REQUIRED`）。按以下流程完成首次授权。

### 7.1 获取 platform_admin 令牌

```bash
BASE="https://localhost:443"
TOKEN=$(curl -ksS -X POST "$BASE/api/v1/auth/login" \
  -H 'Content-Type: application/json' \
  -d '{"phone":"<platform_admin 手机号>","password":"<密码>"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["accessToken"])')
```

### 7.2 获取安装登记（installationId + 指纹）

```bash
curl -ksS -H "Authorization: Bearer $TOKEN" \
  "$BASE/api/v1/admin/deployment-license/enrollment?tenantId=<租户ID>"
```

返回 `data.tenantId`、`data.installationId`、`data.fingerprintHash`、`data.publicKeyId`。重复调用 `installationId` 保持稳定；指纹来自宿主机 `/etc/machine-id`，实机重装系统会变化（变化后旧授权拒绑，需重新签发）。

> 也可在管理端 Web 的授权页直接查看并复制这三个值（Flutter 授权页，对应测试用例 TC-F-02）。

### 7.3 厂商 issuer 签发 .sllicense（issuer 主机操作，内网）

在厂商内部 license-issuer（FastAPI，只部署在内部可信网络，绝不进客户包/公网）：

1. `/login` 登录运营账号；
2. `/issue/new` 填写绑定字段：`tenantId`、`installationId`、`fingerprintHash`（即 7.2 的三个值）、`publicKeyId` 用登记返回的 `publicKeyId`；选择类型（首次建议 TRIAL 或按合同 ACTIVE）、档位（BASIC/PREMIUM/ENTERPRISE）、有效期 `expiresAt`、可选配额；
3. `/issue/preview` 核对 canonical payload 摘要 → 确认签发；
4. `/issue/{id}/done` 下载 `{licenseId}.sllicense`。

> issuer 侧初始化/密钥管理见 `license-issuer/README.md`（私钥目录 0700/0600、Ed25519、`ACTIVE_KEY_ID`）；生成新签名密钥用 `license-issuer/scripts/generate-license-key.sh <keyId>`（仅在 issuer 主机/安全操作机运行）。

### 7.4 上传导入授权

```bash
curl -ksS -X POST "$BASE/api/v1/admin/deployment-license?tenantId=<租户ID>" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@{licenseId}.sllicense" \
  -F "confirm=true"
```

成功返回 `data.runtimeStatus="VALID"` 与授权类型/档位/到期时间；导入即驱动订阅映射（TRIAL → TRIAL 订阅；ACTIVE → ACTIVE 订阅）。常见拒绝：缺 `confirm=true`（400）、绑定不匹配（403 `LICENSE_BINDING_MISMATCH`）、已过期（403 `LICENSE_EXPIRED`）、用量超授权配额（403 `LICENSE_QUOTA_EXCEEDED`）——完整错误码表见 `docs/api-contracts/admin-api.md` §14。

### 7.5 确认生效

```bash
curl -ksS -H "Authorization: Bearer $TOKEN" \
  "$BASE/api/v1/admin/deployment-license/current?tenantId=<租户ID>"
# 期望：runtimeStatus=VALID、lastResult=VALID、subscriptionStatus=TRIAL/ACTIVE
```

业务 API 随即恢复可用。之后调度器每 5 分钟自动重验（时间回拨/篡改自愈与降级见运维指南 §4）。

### 7.6 HOSTED 环境的对应动作（无 7.2–7.5）

HOSTED 部署不做离线导入。platform_admin 在管理端**订阅页**对目标租户「开通 365 天试点」（底层即 `POST /api/v1/admin/tenants/{tenantId}/pilot-license`）：无订阅创建 TRIAL（now+365d），活跃 TRIAL 延长到 max(当前， now+365d)；FREE/ACTIVE/SUSPENDED 等状态返回 409 `STATE_CONFLICT`。

---

## 8. 安装验证（check-release-health.sh 九项）

```bash
./scripts/check-release-health.sh
```

PASS/FAIL 逐项输出，全绿后打印 `HEALTH CHECK PASSED`（任一 FAIL 退出码 1）：

| # | 检查项 | # | 检查项 |
|---|--------|---|--------|
| 1 | `GET /health`（本机 HTTPS，-k）→ 200 | 6 | 最新一条 Flyway 迁移在库内标记成功 |
| 2 | 9 个服务全部 running 且 healthcheck 为 healthy/none | 7 | 8 个内部服务均无宿主机端口映射 |
| 3 | postgres `pg_isready` | 8 | TLS 证书剩余有效期 > 30 天 |
| 4 | redis `PING → PONG` | 9 | `.env.release` 中 `DATAGEN_ENABLED` / `TELEMETRY_SIMULATOR_ENABLED` 均为 `false` |
| 5 | rocketmq namesrv(9876) / broker(10911) 可达 | | |

> 交付收尾时同时走一遍端到端冒烟（登录、牧场/牲畜增删改查、遥测→告警、GPS 轨迹、离线地图、Open API），对应测试用例 TC-E-01~07。

---

## 9. 双机验证环境（内部信息）

| 环境 | 主机 | 模式 | 验证重点 | 用例编号 |
|------|------|------|---------|---------|
| HOSTED 托管验证机 | 172.17.10.86 | `HOSTED`（pilot 开启） | 安装/端口暴露/HTTPS/试点授权/health/备份恢复 | TC-H-01 ~ TC-H-06 |
| ONPREM 离线验证机 | 172.17.10.223 | `ONPREM` | 离线安装、PENDING_ACTIVATION 阻断、登记→签发→导入、绑定拒绝、时间回拨、到期降级、续费恢复、断网独立运行 | TC-O-01 ~ TC-O-10 |

> 步骤细节与预期结果以 `docs/testing/market-beta-test-cases.md` §6 为准；两台机器均应完整跑一遍 §8 的九项 health check 并留存输出记录。

---

## 10. 安全红线（安装/交付必读）

- **包内永不出现**：license-issuer 及其私钥、任何 `*.pem`、任何 `*.sllicense`、任何 `BEGIN ... PRIVATE KEY` 文本——`verify-release-bundle.sh` 会拒绝此类包，收到报警立即停发并追查来源。
- issuer 只部署在厂商内部可信网络，签发/下载均有审计；私钥目录 `0700`、密钥文件 `0600`。
- `.env.release` 含数据库口令与 JWT 密钥，`chmod 600`；`backup-release.sh` 产出的备份（含同样敏感内容）已自动 `go-rwx`，异地保存时保持该权限。
- 交付客户的凭证仅限：`.tar.gz` 发布包 + 安装/运维指南 + 客户租户的 platform_admin 初始凭证（首次登录后引导改密）。

---

## 11. 常见安装失败排查

| 症状（脚本输出） | 原因 | 处置 |
|------------------|------|------|
| `Linux required ...` | 在 macOS/Windows 上运行安装器 | 换 Linux 目标机（`/etc/machine-id` 指纹仅 Linux 有） |
| `docker compose v2 plugin not available` | 只装了 docker（无 compose v2 插件）或装的是 docker-compose v1 | 安装 `docker-compose-plugin`；确认 `docker compose version` 可用 |
| `host port 443 already in use` | 宿主机已有 nginx/其他服务占 80/443 | 停掉占用服务，或改 `.env.release` 的 `HTTP_PORT/HTTPS_PORT`（注意 nginx 80→443 跳转按 443 写死，见 §4） |
| `TLS certificates missing / expired` | `secrets/certs/` 缺文件或证书过期 | 按 §4 放置有效证书后重跑 |
| `RELEASE_VERSION ... does not match package image tag` | `.env.release` 的版本与包内 `release/RELEASE_VERSION` 不一致 | 把 `RELEASE_VERSION` 改成包内戳记值（`cat release/RELEASE_VERSION`） |
| `invalid (template) secret ...: POSTGRES_PASSWORD` | env 仍是 `CHANGE_ME_*` 占位符 | 按 §5.1 逐键填写；密钥用 `openssl rand -base64 48` 生成 |
| `DATAGEN_ENABLED must be "false"` | 发布包契约禁止仿真开关 | 改回 `false`（compose 层已硬编码，改了也不生效） |
| health check 超时（`did not return 200 within 300s`） | app 启动慢/依赖未就绪/配置错误 | 看超时输出的 app 日志尾部；慢盘重跑加 `HEALTH_TIMEOUT_SECS=600`；配置错误修正后 `docker compose up -d` |
| `sha256sum -c` 报 FAILED | 传输损坏或包被改动 | 重新传输并再次校验；确认来源可信 |
| 解包后出现 `._*` 文件、脚本乱报错 | macOS AppleDouble 污染（构建机打包问题时） | `find . -name '._*' -delete` 后重试；正规发布包已在打包时排除（lessons #1/#2） |
| 浏览器访问证书告警 | 自签冒烟证书 | 正式交付替换为受信任证书（§4） |
| up 时报 `manifest unknown` / 镜像不存在 | 手动 up 时漏 `--env-file .env.release`，标签回落为 `beta` | 始终用 `./scripts/install-release.sh` 或带 `--env-file` 的 compose 命令 |
