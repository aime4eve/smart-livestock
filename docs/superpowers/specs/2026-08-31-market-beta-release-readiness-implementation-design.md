# 智慧畜牧市场测试版实现设计

## 1. 设计结论

- 引入独立 `licensing` 限界上下文，负责云端试点授权与地端离线授权。
- 云端试点授权由 `platform_admin` 调用，固定开通或延长 365 天。
- 地端使用厂商签发的 `.sllicense` 离线授权文件，采用 Ed25519 签名、安装 ID 和主机指纹绑定。
- 新增独立 `license-issuer` 内部签发服务；它不进入客户 release 包，私钥不进入地端。
- 地端信任根是内置公钥，不允许通过普通环境变量替换。
- 订阅仍归 `commerce` 上下文；`licensing` 只通过端口驱动订阅状态，避免上下文反向依赖。
- release 环境统一健康检查为 `/health`，不新增 Actuator 依赖。

## 2. 部署模式与配置

新增配置：

```yaml
smartlivestock:
  license:
    mode: CLOUD | ONPREM
    public-key-file: classpath:licensing/license-public-keys.json
    time-tolerance: PT2M
    validation-cron: "0 */5 * * * *"
  pilot-license:
    enabled: true | false
```

- `CLOUD`：默认模式，dev/test/云端使用；启用试点授权 API，不要求主机指纹。
- `ONPREM`：release 地端模式；启用离线授权、主机绑定、授权 enforcement，禁用云端试点 API 和自助订阅变更。
- `.env.release.example` 中 `SMARTLIVESTOCK_LICENSE_MODE=ONPREM`、`SMARTLIVESTOCK_PILOT_LICENSE_ENABLED=false`。
- 云端环境反向配置为 `CLOUD=true`。

## 3. 授权文件格式

文件扩展名：`.sllicense`

外层 JSON：

```json
{
  "format": "SMART_LIVESTOCK_LICENSE_V1",
  "keyId": "sl-license-2026q3",
  "payload": "<base64url>",
  "payloadSha256": "<hex>",
  "signature": "<base64url>"
}
```

payload 为 canonical JSON，字段固定：

```json
{
  "payloadVersion": 1,
  "licenseId": "uuid",
  "tenantId": 123,
  "installationId": "uuid",
  "fingerprintHash": "sha256-hex",
  "keyId": "sl-license-2026q3",
  "licenseType": "TRIAL | ACTIVE",
  "tier": "BASIC | PREMIUM | ENTERPRISE",
  "effectiveTier": "BASIC | PREMIUM | ENTERPRISE",
  "issuedAt": "2026-08-31T00:00:00Z",
  "expiresAt": "2027-08-31T00:00:00Z",
  "quotas": {
    "livestock_management": 1000,
    "fence_management": 100,
    "worker_management": 50,
    "device_management": 1000
  },
  "features": {},
  "replacesLicenseId": "optional-uuid"
}
```

规则：

- 签名算法：Ed25519。
- canonical JSON：UTF-8、递归按键名字典序排序、compact separator、无换行、时间使用 UTC `yyyy-MM-dd'T'HH:mm:ss'Z'`、整数不带小数点。
- `signature = Ed25519.sign(privateKey, canonicalPayloadBytes)`。
- REPLACEMENT 不作为运行时类型，而是签发原因；文件中通过 `replacesLicenseId` 关联被替换授权。
- 公钥文件由构建产物内置，包含当前公钥和上一个轮换公钥。
- Java 与 Python issuer 必须使用同一组 canonical JSON 测试向量。

## 4. 内部签发服务

新增目录：

```text
license-issuer/
```

技术选型：

- Python FastAPI + Jinja2 server-rendered 页面。
- SQLite 存储签发记录与审计，文件挂载到内部数据卷。
- `cryptography` 实现 Ed25519。
- bcrypt 校验内部运营账号。
- 服务端 session + CSRF token。
- 只部署在内部可信网络，不进入 `docker-compose.release.yml`。

页面：

- 登录页。
- 新建授权页。
- 授权预览页。
- 授权列表页。
- 授权详情页。
- 审计日志页。
- 密钥状态页。

签发流程：

1. 运维输入 `tenantId`、`installationId`、`fingerprintHash`、授权类型、档位、到期时间、配额。
2. 服务生成 canonical payload 和 SHA-256 摘要。
3. 页面展示 payload 摘要，要求二次确认。
4. 服务使用当前 `keyId` 对应私钥签名。
5. 生成 `.sllicense` 文件。
6. 保存 license 元数据、payload SHA-256、签发原因、操作人和审计。
7. 运维下载文件并交给客户导入。

私钥管理：

- 私钥目录只挂载到 issuer 容器。
- 私钥权限 `0600`，目录权限 `0700`。
- 当前私钥由 `active-key-id` 指定。
- 私钥缺失、权限错误、算法不支持时 fail fast。
- 页面只显示 `keyId`、公钥指纹和启用状态，永不显示私钥。

## 5. 后端模块设计

新增包：

```text
com.smartlivestock.licensing
```

按现有 DDD 结构拆分：

### domain

- `LicensePayload`
- `LicenseEnvelope`
- `LicenseType`
- `LicenseRuntimeStatus`
- `DeploymentLicense`
- `DeploymentInstallation`
- `LicenseValidator`
- `HostFingerprint`
- `LicenseQuotaSnapshot`

### application

- `DeploymentLicenseApplicationService`
- `CloudPilotLicenseService`
- `LicenseSubscriptionPort`
- `LicenseQuotaPort`
- `LicenseTimeGuardService`
- `DeploymentLicenseScheduler`

### infrastructure

- `Ed25519LicenseVerifier`
- `CanonicalJsonSerializer`
- `ClasspathLicensePublicKeyRegistry`
- `HostFingerprintReader`
- JPA repositories
- `CommerceLicenseAdapter`
- `CommerceQuotaLicenseAdapter`

### interfaces

- `DeploymentLicenseAdminController`
- `CloudPilotLicenseController`
- DTO 与 response assembler

## 6. 数据模型

新增 Flyway：

```text
V20260831120000__deployment_licensing.sql
```

### deployment_installations

- `id`
- `tenant_id`
- `installation_id UUID`
- `fingerprint_hash CHAR(64)`
- `created_at`
- `updated_at`
- unique：`tenant_id`
- unique：`installation_id`

### deployment_licenses

- `id`
- `license_id UUID`
- `tenant_id`
- `installation_id`
- `fingerprint_hash`
- `key_id`
- `license_type`
- `tier`
- `effective_tier`
- `issued_at`
- `expires_at`
- `payload_sha256`
- `raw_license TEXT`
- `status`
- `accepted_at`
- `last_validated_at`
- `last_result`
- `last_error_code`
- `replaces_license_id`
- unique：`license_id`
- index：`tenant_id,status,expires_at`

### deployment_license_states

- `tenant_id` primary key
- `current_license_id`
- `runtime_status`
- `max_observed_at`
- `last_validated_at`
- `last_error_code`
- `protection_reason`
- `updated_at`

### deployment_license_events

- `id`
- `license_id`
- `tenant_id`
- `event_type`
- `result`
- `error_code`
- `details JSONB`
- `operator_user_id`
- `occurred_at`
- index：`tenant_id,occurred_at`

不种子任何可用授权文件，避免迁移本身成为绕过入口。

## 7. 云端试点授权

新增接口：

```http
POST /api/v1/admin/tenants/{tenantId}/pilot-license
```

规则：

- 仅 `platform_admin`。
- `CLOUD` 模式且 `pilot-license.enabled=true` 时可用。
- `ONPREM` 模式返回 `AUTH_FORBIDDEN`。
- 无订阅：创建 `TRIAL / BASIC`，`trialEndsAt = now + 365d`。
- 已有未过期 `TRIAL`：延长到 `max(currentTrialEndsAt, now + 365d)`。
- 已有 `ACTIVE / FREE / SUSPENDED / CANCELLED / EXPIRED / RENEWAL_FAILED`：拒绝。
- 所有成功与失败操作写入审计。

`Subscription` 新增领域方法：

```java
extendTrial(Instant newTrialEndsAt)
```

只允许当前状态为 `TRIAL`，且不允许缩短当前到期时间。

## 8. 地端授权 API

### 获取登记信息

```http
GET /api/v1/admin/deployment-license/enrollment?tenantId={tenantId}
```

返回：

```json
{
  "tenantId": "123",
  "installationId": "uuid",
  "fingerprintHash": "sha256-hex",
  "publicKeyId": "sl-license-2026q3",
  "supportedPublicKeyIds": ["sl-license-2026q3"],
  "generatedAt": "2026-08-31T00:00:00Z"
}
```

### 上传授权

```http
POST /api/v1/admin/deployment-license?tenantId={tenantId}
Content-Type: multipart/form-data
```

表单字段：

- `file`：`.sllicense`
- `confirm`: `true`

### 查询状态

```http
GET /api/v1/admin/deployment-license/current?tenantId={tenantId}
```

返回当前授权、订阅映射、最近校验结果、最大已观测时间、保护原因。

所有接口仅 `platform_admin` 可访问。

## 9. 地端校验状态机

启动与每 5 分钟执行：

1. 读取当前系统时间。
2. 更新 `max_observed_at`。
3. 如 `now + tolerance < maxObservedAt`，进入 `SUSPENDED / LICENSE_TIME_ROLLBACK`。
4. 加载当前 `.sllicense`。
5. 校验 format、keyId、公钥、签名、payload hash。
6. 校验 `tenantId`、`installationId`、`fingerprintHash`。
7. 校验 `issuedAt <= now`、`expiresAt > now`。
8. 校验当前关键资源用量不超过授权配额。
9. 根据结果映射订阅。

状态映射：

| runtime_status | 订阅映射 |
|---|---|
| `PENDING_ACTIVATION` | 无订阅或阻止业务访问 |
| `VALID + TRIAL` | `TRIAL / BASIC / effectiveTier=PREMIUM` |
| `VALID + ACTIVE` | `ACTIVE / license.tier` |
| `EXPIRED` | `FREE / BASIC` |
| `SUSPENDED` | `SUSPENDED / BASIC` |

授权导入：

- 新有效 `TRIAL`：创建或延长试用。
- 已过期试用降级为 `FREE` 后，不允许普通导入重新变回 `TRIAL`，必须签发 `ACTIVE` 续费授权。
- `ACTIVE` 授权允许从 `TRIAL / FREE / ACTIVE` 映射为 `ACTIVE / license.tier`。
- `SUSPENDED` 状态只有在导入签名有效、绑定正确、时间正常的授权后才能恢复。
- 旧 license 标记 `REPLACED`。
- 数据永不删除。

## 10. Commerce 集成

`licensing` 定义端口：

```java
LicenseSubscriptionPort
LicenseQuotaPort
```

`commerce` 实现适配器：

- `applyTrialLicense(tenantId, expiresAt)`
- `applyActiveLicense(tenantId, tier, expiresAt)`
- `downgradeForLicense(tenantId)`
- `suspendForLicense(tenantId, reason)`
- `findEffectiveFeatureGate(tenantId, featureKey)`

`QuotaApplicationService.loadGate()` 调整为：

1. `ONPREM` 下先查询 license quota。
2. license 存在配额时优先生效。
3. license 无该 key 配额时回退现有 `FeatureGate`。
4. `CLOUD` 下行为不变。

导入授权前检查：

- 当前牲畜数 ≤ `livestock_management`。
- 当前围栏数 ≤ `fence_management`。
- 当前牧工数 ≤ `worker_management`。
- 当前设备数 ≤ `device_management`。

超限则导入失败，不进入降级或激活状态。

## 11. 地端 enforcement

新增 `LicenseEnforcementInterceptor`。

放行路径：

- `/health`
- `/api/v1/auth/login`
- `/api/v1/auth/refresh`
- `/api/v1/admin/deployment-license/**`
- `/api/v1/admin/tenants/**`：仅用于 pending 状态完成租户选择
- 静态资源

`PENDING_ACTIVATION`：

- 允许登录、查看租户、查看授权登记信息、上传授权。
- 阻止牧场、牲畜、设备、遥测、健康、Open API 等业务 API。

`SUSPENDED`：

- 仅允许登录和授权管理。
- 阻止业务 API 与 Open API。
- 返回 `LICENSE_REQUIRED` 或对应 license 错误码。

`EXPIRED`：

- 应用可启动，业务 API 可进入。
- 订阅已映射为 `FREE / BASIC`。
- 实际可见能力由现有 FeatureGate 决定。

`ONPREM` 下同时禁用：

- 云端试点授权接口。
- 自助订阅结账。
- 自助订阅升级。
- 自助取消。
- Admin subscription 手工状态变更。

## 12. 前端实现

新增 Flutter 管理模块：

```text
Mobile/mobile_app/lib/features/admin/license/
```

包含：

- `data/deployment_license_api_repository.dart`
- `domain/deployment_license_models.dart`
- `presentation/deployment_license_controller.dart`
- `presentation/deployment_license_page.dart`

页面能力：

- 租户选择。
- 当前授权状态卡片。
- 到期时间与倒计时。
- 安装 ID。
- 主机指纹哈希。
- 公钥 ID。
- 最近校验结果。
- 失败原因。
- 上传 `.sllicense`。
- 成功、失败、保护模式提示。
- 续费引导文案。

新增路由：

```dart
platformDeploymentLicense(
  '/admin/deployment-license',
  'platform-deployment-license',
  '部署授权',
)
```

只对 `platform_admin` 显示。

云端订阅管理页新增：

- 开通 365 天试点授权按钮。
- 当前订阅状态展示。
- 状态冲突错误提示。

修复：

```dart
// app_router.dart alerts route
return AlertsPage(role: role, category: category, fenceId: fenceId);
```

删除 dead code：

```dart
return AlertsPage(role: role);
```

所有新增文案进入 `app_zh.arb` 和 `app_en.arb`。

## 13. release 包设计

新增文件：

```text
smart-livestock-server/docker-compose.release.yml
smart-livestock-server/.env.release.example
smart-livestock-server/infrastructure/nginx/nginx.release.conf
smart-livestock-server/scripts/build-release-package.sh
smart-livestock-server/scripts/install-release.sh
smart-livestock-server/scripts/check-release-health.sh
smart-livestock-server/scripts/backup-release.sh
smart-livestock-server/scripts/restore-release.sh
smart-livestock-server/scripts/verify-release-bundle.sh
```

release 服务：

- nginx
- app
- postgres
- redis
- rocketmq-namesrv
- rocketmq-broker
- ai-platform
- tileserver
- tile-worker

明确不包含：

- license-issuer
- 签名私钥
- RocketMQ Dashboard
- datagen console 数据
- telemetry simulator
- 测试私钥
- demo 密码文档

nginx：

- 80 跳转 443。
- 443 启用 TLS 1.2/1.3。
- 挂载 `./secrets/certs/fullchain.pem` 和 `privkey.pem`。
- 仅暴露 `${HTTP_PORT}`、`${HTTPS_PORT}`。
- API、前端、tiles 继续走 nginx。

离线包结构：

```text
smart-livestock-market-beta-<version>/
  images.tar.gz
  release/
    docker-compose.release.yml
    .env.release.example
    scripts/
    docs/
  SHA256SUMS
```

`verify-release-bundle.sh` 检查：

- 镜像包 SHA256 正确。
- 包内不存在 `license-issuer`。
- 不存在 `BEGIN PRIVATE KEY`。
- 不存在 `*.pem` 私钥。
- 不存在 `*.sllicense`。
- compose 中 `DATAGEN_ENABLED=false`。
- compose 中 `TELEMETRY_SIMULATOR_ENABLED=false`。
- 数据库、Redis、RocketMQ 无 host port 映射。

## 14. 运维脚本

### install-release.sh

- 校验 Linux、Docker、Docker Compose v2。
- 校验 CPU、内存、磁盘。
- 校验 80/443 或自定义端口未占用。
- 校验 `.env.release` 必填 secret 非模板值。
- 校验 TLS 证书存在。
- 加载离线镜像。
- 启动 release compose。
- 等待 `/health` 返回 200。
- 输出版本、入口地址、健康检查命令。

### check-release-health.sh

- `/health` 200。
- PostgreSQL 可连接。
- Redis ping。
- RocketMQ name server 可达。
- Flyway 最新迁移已执行。
- 数据库、Redis、RocketMQ 无外部端口。
- HTTPS 证书未过期。
- datagen 关闭。

### backup-release.sh

备份：

- PostgreSQL `pg_dump`。
- tileserver 数据卷。
- AI 模型卷。
- release env 文件。
- TLS 证书目录。
- 生成 SHA256SUMS。

### restore-release.sh

- 停止 app、tile-worker。
- 恢复 PostgreSQL。
- 恢复 tileserver 和模型卷。
- 校验授权状态和数据库连接。
- 启动服务。
- 执行 health check。

## 15. 测试设计

### 后端单元测试

- canonical JSON 排序与时间格式。
- Ed25519 签名验签。
- 非法 envelope 拒绝。
- keyId 不支持拒绝。
- payload SHA-256 不匹配拒绝。
- fingerprint、tenant、installation 不匹配拒绝。
- 过期授权降级。
- 续费授权激活。
- 授权配额优先于 FeatureGate。
- 时间回拨进入保护模式。
- 手工改库后 scheduler 恢复真实状态。
- 云端 365 天试用创建和延长。
- 非法订阅状态拒绝试点授权。

### Controller 测试

- 非 platform_admin 返回 403。
- CLOUD 模式禁用地端 API。
- ONPREM 模式禁用试点 API。
- pending 状态阻止业务 API。
- suspended 状态只允许授权管理。
- multipart 上传成功与失败。

### Issuer 测试

- 登录失败。
- CSRF 缺失拒绝。
- 私钥缺失拒绝。
- canonical payload 与 Java 测试向量一致。
- 下载文件可被 Java verifier 接受。
- 篡改 payload 后 Java verifier 拒绝。
- 每次签发和下载都有审计。

### Flutter 测试

- 授权页 platform_admin 可见。
- 非 platform_admin 不可见。
- 登记信息渲染。
- 文件上传调用正确 API。
- 状态卡片渲染 VALID、PENDING、EXPIRED、SUSPENDED。
- alerts route 不再有 dead code。
- 中英文 key 完整。

### 发布验收

- 干净 Linux 主机离线安装成功。
- HTTPS 正常。
- `/health` 返回 200。
- 数据库、Redis、RocketMQ 无外部端口。
- release 包无私钥和 issuer。
- 授权导入、到期降级、续费恢复全链路通过。
- 备份恢复通过。
- 核心业务链路端到端通过。

## 16. 实施顺序

1. 创建 spec、plan、测试用例文档。
2. 增加 licensing 数据模型和错误码。
3. 实现 canonical JSON、Ed25519、公钥注册、host fingerprint。
4. 实现 cloud pilot license API 和测试。
5. 实现 offline license validator、状态机、Commerce adapter。
6. 实现 enrollment/import/current API 与 enforcement。
7. 实现 license-issuer 服务和后台页面。
8. 实现 Flutter 授权页与云端试点入口。
9. 修复 alerts route dead code。
10. 增加 release compose、TLS、离线镜像包和运维脚本。
11. 跑目标测试、发布包验证、备份恢复、端到端链路。
12. 更新 API 契约、安装指南、签发手册和发布检查清单。

## 17. 验收门槛

- 后端目标测试 0 failure、0 error。
- Flutter CI 同口径分析通过。
- Flutter 契约测试全部通过。
- Flutter Web 构建成功。
- release Compose config 通过。
- 干净环境离线安装成功。
- `/health` 连续通过。
- 授权绑定、篡改、时间回拨、到期降级、续费恢复全部通过。
- release 包扫描确认无私钥和 issuer。
- 备份恢复成功。
- datagen 和 simulator 确认关闭。
- 中英文资源同步完整。
