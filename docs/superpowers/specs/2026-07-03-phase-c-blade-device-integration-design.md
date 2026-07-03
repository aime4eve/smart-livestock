# Phase C：hkt-blade-device 对接设计规格

**Date**: 2026-07-03
**Status**: 草案
**涉及团队**: smart-livestock 团队 + blade 设备中台团队
**参考**: `business-platform/open-platform-dev/` — blade Feign 接口契约（已验证）

---

## 1. 背景与目标

### 1.1 当前状态

两个系统独立运行，无任何集成：

| | smart-livestock-server | hkt-blade-device |
|------|------|------|
| **定位** | 畜牧业务系统（DDD 洋葱架构） | 设备管理平台（Spring Cloud 微服务） |
| **设备数据** | 自有 `devices` 表，datagen 模拟遥测 | ThingsBoard 接入真实设备，管理全生命周期 |
| **遥测通路** | `TelemetryIngestionService` + RocketMQ → Health | 设备 → LoRa NS → ThingsBoard → blade 存储 |
| **认证体系** | JWT（用户）+ API Key（Open API） | OAuth2（内部服务间） |
| **是否在同一网格** | **否** — 独立 Spring Boot 3.3，无 Nacos/Feign | **是** — Spring Cloud Alibaba 体系 |

### 1.2 Phase C 目标

打通两套系统，让真实 IoT 设备数据流入 smart-livestock-server 的业务管线：

1. **设备注册打通**：smart-livestock 注册设备时 → 查 blade License → 在 blade 注册 → 本地同步
2. **实时遥测接入**：blade 侧设备上报 → webhook 推送 → smart-livestock 的遥测 pipeline
3. **历史数据查询**：smart-livestock 按需从 blade 拉取历史时序数据
4. **License 校验**：设备 SN 校验对接 blade License 服务

---

## 2. 团队分工总览

```
┌─────────────────────────────────────────────────────────────────┐
│                    工作界面（Interface Boundary）                  │
│                                                                  │
│  ┌──────────────────────────┐    ┌──────────────────────────┐   │
│  │   hkt-blade-device 团队   │    │  smart-livestock 团队     │   │
│  │                          │    │                          │   │
│  │  ★ 新增：Webhook 推送引擎  │    │  ★ 新增：Blade HTTP 客户端 │   │
│  │  ★ 新增：Webhook 配置管理  │    │  ★ 新增：OAuth2 Token    │   │
│  │  ★ 新增：OAuth2 客户端注册 │    │  ★ 修改：Device 模型     │   │
│  │  ▲ 已有：Feign API 端点   │    │  ★ 修改：注册流程         │   │
│  │  ▲ 已有：License 服务     │    │  ★ 修改：遥测接收         │   │
│  │                          │    │  ★ 新增：Flyway 迁移      │   │
│  │                          │    │                          │   │
│  │  ── webhook POST ───────→│    │                          │   │
│  │  ←─ GET License ─────────│    │                          │   │
│  │  ←─ POST registerDevice ─│    │                          │   │
│  │  ←─ POST history query ──│    │                          │   │
│  └──────────────────────────┘    └──────────────────────────┘   │
│                                                                  │
│  图例：★ 新增开发   ▲ 已有（确认可用即可）                         │
└─────────────────────────────────────────────────────────────────┘
```

**接口方向：**

| # | 方向 | 调用方 | 被调用方 | 接口 | 团队 |
|---|------|--------|----------|------|------|
| ① | blade → smart-livestock | blade webhook | smart-livestock TelemetryController | `POST /api/v1/telemetry/webhook` | **双方** |
| ② | smart-livestock → blade | smart-livestock BladeLicenseClient | blade License 服务 | `GET /feign/v1/device-license/control/by-sn` | blade 已有 |
| ③ | smart-livestock → blade | smart-livestock BladeDeviceClient | blade 设备服务 | `POST /feign/v1/device/lifecycle/registerDevice` 等 | blade 已有 |
| ④ | smart-livestock → blade | smart-livestock BladeHistoryClient | blade 设备服务 | `POST /feign/v1/device/history/data/query-list-page/{deviceId}` | blade 已有 |

---

## 3. 接口 ① Webhook 契约 — 两队联调的关键界面

这是**唯一的新接口**，需两队共同遵守。其余接口（②③④）blade 侧已实现，smart-livestock 侧调用即可。

### 3.1 Webhook 请求（blade → smart-livestock）

```
POST /api/v1/telemetry/webhook
Host: {smart-livestock-host}:{port}
Content-Type: application/json
X-Blade-Signature: t=1709468000,v1=abc123def456...
```

```json
{
  "device_id": "BLD-20250510-00001",
  "device_type": "tracker",
  "recorded_at": "2026-07-03T10:00:00Z",
  "properties": {
    "latitude": 28.245800,
    "longitude": 112.851900,
    "battery_level": 85,
    "step_count": 1234,
    "accel_x": 0.12,
    "accel_y": -0.05,
    "accel_z": 1.01
  }
}
```

**字段规范：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `device_id` | String | ✅ | **blade 侧的 deviceId**（blade 内部标识），smart-livestock 侧通过 `blade_device_id` 字段映射到本地 Device |
| `device_type` | String | ✅ | blade 的 `deviceTypeCode`，取值：`tracker` / `rumenCapsule` / `earTag` |
| `recorded_at` | String | ✅ | ISO-8601 UTC 时间戳，设备采样的真实时间 |
| `properties` | Object | ✅ | 扁平 key-value 遥测数据，key 统一用 **snake_case** |

**`properties` 字段定义（按设备类型）：**

_TRACKER 追踪器：_

| key | 类型 | 单位 | 说明 |
|-----|------|------|------|
| `latitude` | Number | 度 | WGS-84 纬度 |
| `longitude` | Number | 度 | WGS-84 经度 |
| `battery_level` | Integer | % | 电量 0-100 |
| `step_count` | Integer | 步 | 本周期步数 |
| `accel_x` | Number | g | X 轴加速度 |
| `accel_y` | Number | g | Y 轴加速度 |
| `accel_z` | Number | g | Z 轴加速度 |
| `temperature` | Number | °C | 环境温度（可选） |
| `humidity` | Number | % | 环境湿度（可选） |

_CAPSULE 瘤胃胶囊：_

| key | 类型 | 单位 | 说明 |
|-----|------|------|------|
| `temperature` | Number | °C | 瘤胃温度（单点均值，胶囊内部取 7 点平均后的值） |
| `temperature_points` | Number[] | °C | 7 点原始温度数组（可选，用于精细分析） |
| `gastric_motility` | Number | — | 胃动量原始值 |
| `battery_voltage` | Integer | mV | 电池电压 |
| `accel_x` | Number | — | X 轴加速度 |
| `accel_y` | Number | — | Y 轴加速度 |
| `accel_z` | Number | — | Z 轴加速度 |

> **注意**：`properties` 中 key 的命名、单位、语义由**本契约锁定**。blade 侧负责将其内部的 `telemetryProperties[{identifier, value}]` 转换为本契约的扁平格式。

### 3.2 Webhook 响应（smart-livestock → blade）

**成功：**
```json
HTTP 200
{
  "code": 200,
  "message": "ok",
  "data": {
    "device_id": "BLD-20250510-00001",
    "local_device_id": 51,
    "processed": true
  }
}
```

**设备未映射（blade 侧的设备在 smart-livestock 侧没有对应记录）：**
```json
HTTP 404
{
  "code": 404,
  "message": "设备未在 smart-livestock 注册，请先在业务系统注册该设备"
}
```

**参数校验失败：**
```json
HTTP 400
{
  "code": 400,
  "message": "device_id 不能为空"
}
```

### 3.3 Webhook 签名（Phase C 第一期可选）

blade 侧发送时携带签名头 `X-Blade-Signature`，smart-livestock 侧可选择性校验：

```
X-Blade-Signature: t=1709468000,v1=HMAC-SHA256(t + "." + body, secret)
```

- `t`：Unix 时间戳（秒），防重放（smart-livestock 拒绝超过 5 分钟的请求）
- `v1`：`HMAC-SHA256("{t}.{request_body}", webhook_secret)` 的 hex 编码
- `webhook_secret`：双方约定的共享密钥，通过环境变量配置

**第一期实现建议**：内网环境先不做签名校验（`BLADE_TELEMETRY_WEBHOOK_SECRET` 为空时跳过校验），联调通过后再打开。

### 3.4 Webhook 重试策略（blade 侧职责）

blade 侧推送失败时的重试策略：

| 参数 | 值 | 说明 |
|------|-----|------|
| 最大重试次数 | 5 | |
| 退避策略 | 指数退避 | 1s → 2s → 4s → 8s → 16s |
| 失败判定 | HTTP 非 2xx 或连接超时 | 404 不重试（设备未注册是业务错误） |
| 超时 | 30s / 次 | |
| 死信处理 | 日志记录 + 告警 | 5 次全失败后记录 ERROR 日志 |

**注意**：404 响应（设备未映射）**不重试**——这是业务错误，需要人工介入（在 smart-livestock 侧注册设备后，后续推送会自动成功）。

---

## 4. 接口 ②③④ 契约 — blade 已有端点（确认清单）

smart-livestock 侧需要调用的 blade Feign 端点，已从 `open-platform-dev` 代码确证。

### 4.1 通用约定

- **Base URL**: `http://{blade-host}/feign/v1`
- **认证**: `token: {access_token}` 请求头（或 `Authorization: Bearer`，需与 blade 团队最终确认）
- **响应包络**: `InternalResponse<T>` — `{ "code": 200, "success": true, "data": {...}, "msg": "..." }`
- `isOk()` = `success && (code == 200 || code == 0)`

### 4.2 License 查询

```
GET /feign/v1/device-license/control/by-sn?deviceSn={sn}
```

**响应 `LicenseStatusResp`**:
```json
{
  "code": 200, "success": true,
  "data": {
    "deviceEui": "AABBCCDDEEFF0011",
    "deviceSn": "SN-20250510-00001",
    "deviceTypeCode": "tracker",
    "status": "activated",
    "isValid": true,
    "agentId": "AGT001",
    "agentCode": "HKT",
    "activatedAt": "2026-05-10T08:00:00Z"
  }
}
```

### 4.3 设备注册

```
POST /feign/v1/device/lifecycle/registerDevice
Content-Type: application/json

{
  "user": { "userId": "xxx", "userName": "xxx", "tenantId": "xxx" },
  "deviceIdentifier": "AABBCCDDEEFF0011",
  "deviceTypeCode": "tracker",
  "spaceId": null
}
```

**响应 `DeviceRegistrationResp`**:
```json
{
  "code": 200, "success": true,
  "data": {
    "deviceId": "BLD-20250510-00001",
    "deviceTypeId": "TYPE_TRACKER_V2",
    "status": "active",
    "createTime": "2026-07-03T10:00:00Z"
  }
}
```

### 4.4 设备详情 + 遥测

```
GET /feign/v1/device/lifecycle/getDeviceDetailWithTelemetry?deviceId={bladeDeviceId}
```

**响应 `DeviceTelemetryResp`** — 包含设备元信息 + LoRa 信号指标 + `telemetryProperties[]` 数组 + `subDevices[]`。

### 4.5 历史数据分页

```
POST /feign/v1/device/history/data/query-list-page/{bladeDeviceId}
Content-Type: application/json

{
  "startTime": "2026-07-01T00:00:00+08:00",
  "endTime": "2026-07-03T23:59:59+08:00",
  "current": 1,
  "size": 20
}
```

**响应 `DeviceHistoryDataPageResp`**:
```json
{
  "code": 200, "success": true,
  "data": {
    "total": 150,
    "current": 1,
    "size": 20,
    "records": [
      { "timestamp": "...", "temperature": 38.6, ... },
      ...
    ]
  }
}
```

---

## 5. 团队 A：hkt-blade-device 团队 — 改造需求

### 5.1 新增：Webhook 推送引擎

**这是 blade 团队的核心开发任务。** blade 侧目前没有向外部系统推送遥测数据的能力。

**功能需求：**

1. **事件触发**：当 ThingsBoard 收到设备遥测上报时，触发 webhook 推送
2. **Payload 转换**：将 blade 内部的 `telemetryProperties[{identifier, value}]` 数组转换为 §3.1 定义的扁平 `properties` 格式
3. **HTTP 推送**：向配置的 webhook URL 发送 POST 请求
4. **签名生成**：按 §3.3 规则生成 `X-Blade-Signature` 请求头
5. **重试机制**：按 §3.4 定义的重试策略执行
6. **404 不重试**：收到 404 响应时停止重试，记录日志

**技术实现建议：**

```
blade 侧新增组件：
├── webhook/
│   ├── WebhookConfig.java              — 配置管理（URL, secret, 开关）
│   ├── WebhookDispatcher.java          — 事件监听 + 调度
│   ├── WebhookPayloadTransformer.java  — telemetryProperties → 扁平 properties
│   ├── WebhookSigner.java              — HMAC-SHA256 签名生成
│   └── WebhookRetryPolicy.java         — 重试策略
```

**配置项（blade 侧 application.yml / Nacos）：**

```yaml
blade:
  webhook:
    smart-livestock:
      enabled: true
      url: http://smart-livestock-server:8080/api/v1/telemetry/webhook
      secret: ${WEBHOOK_SECRET:}
      timeout-ms: 30000
      retry:
        max-attempts: 5
        backoff-initial-ms: 1000
        backoff-multiplier: 2.0
```

### 5.2 新增：OAuth2 客户端注册

为 smart-livestock-server 注册 OAuth2 客户端凭据：

1. 在 blade 网关的 OAuth2 授权服务器中注册新客户端
2. 分配 `client_id` + `client_secret`
3. 授权 `grant_type=openapi` 权限
4. 将凭据交付给 smart-livestock 团队（通过安全通道）

**产出物：** `client_id` + `client_secret` 字符串

### 5.3 确认（已有 API 可达性）

以下端点已存在于 blade，open-platform-dev 正在使用。blade 团队需确认：

1. ✅ 网络可达 — smart-livestock-server 可以访问 blade 的内网地址
2. ✅ 认证方式 — 确认 token header 名称（`token` 还是 `Authorization: Bearer`）
3. ✅ DeviceType 编码 — 确认 `deviceTypeCode` 的精确取值
4. ✅ 不分页历史查询 — 如果一次查询的时间范围过大（> 10000 条），是否支持或需要特殊处理

### 5.4 Blade 团队交付物清单

| # | 交付物 | 类型 | 优先级 |
|---|--------|------|--------|
| A1 | Webhook 推送引擎（含 Payload 转换） | 代码 | P0 |
| A2 | Webhook 配置项（Nacos / application.yml） | 配置 | P0 |
| A3 | OAuth2 client_id + client_secret | 密钥 | P0 |
| A4 | 网络白名单开通（smart-livestock → blade） | 运维 | P0 |
| A5 | Webhook 签名实现 | 代码 | P1（第一期可选） |
| A6 | 设备类型编码清单确认 | 文档 | P0 |

---

## 6. 团队 B：smart-livestock 团队 — 改造需求

### 6.1 新增：Blade HTTP Client 基础设施

参考项目现有模式（`RestAnomalyScoreClient`），用 `java.net.http.HttpClient` 实现，**不引入 Spring Cloud / Feign**。

**新增文件清单（`iot/infrastructure/client/`）：**

```
iot/infrastructure/client/
├── BladeAuthTokenProvider.java       — OAuth2 token 获取 + 缓存
├── BladeLicenseClient.java           — License 查询
├── BladeDeviceClient.java            — 设备注册/详情/遥测
├── BladeHistoryClient.java           — 历史数据分页
├── BladeHttpClient.java              — HttpClient 封装基类（超时、响应解析）
└── dto/
    ├── BladeInternalResponse.java    — 通用响应包络
    ├── BladeLicenseStatusResp.java   — License 状态
    ├── BladeDeviceDetailResp.java    — 设备详情
    ├── BladeTelemetryResp.java       — 遥测数据（仅按需拉取用）
    ├── BladeHistoryPageResp.java     — 历史数据分页
    ├── BladeDeviceRegistrationReq.java
    └── BladeDeviceRegistrationResp.java
```

**核心类设计：`BladeAuthTokenProvider`**

```java
@Component
public class BladeAuthTokenProvider {
    // 配置: blade.oauth2.token-uri, client-id, client-secret
    // 流程:
    //   1. Basic Auth (clientId:clientSecret) → POST token-uri
    //   2. Form: grant_type=openapi
    //   3. 缓存 accessToken，过期前 60s 自动刷新
    //   4. 线程安全（synchronized per lock object）
    // 参考: open-platform-dev 的 OpenApiGatewayTokenService
}
```

**配置项（`application.yml` 新增）：**

```yaml
blade:
  device:
    base-url: ${BLADE_DEVICE_URL:http://hkt-blade-device:8080}
  oauth2:
    enabled: ${BLADE_OAUTH2_ENABLED:false}
    token-uri: ${BLADE_OAUTH2_TOKEN_URL:}
    client-id: ${BLADE_OAUTH2_CLIENT_ID:}
    client-secret: ${BLADE_OAUTH2_CLIENT_SECRET:}
  connect-timeout-ms: ${BLADE_CONNECT_TIMEOUT_MS:5000}
  request-timeout-ms: ${BLADE_REQUEST_TIMEOUT_MS:30000}
  telemetry:
    webhook-secret: ${BLADE_TELEMETRY_WEBHOOK_SECRET:}
```

### 6.2 新增：Webhook 接收端点

**新增 `TelemetryWebhookController`**（与现有的 `TelemetryController` 独立，避免冲突）：

```java
// 新文件：iot/interfaces/TelemetryWebhookController.java

@RestController
@RequestMapping("/api/v1/telemetry")
public class TelemetryWebhookController {

    // POST /api/v1/telemetry/webhook
    // 1. 可选：校验 X-Blade-Signature（如果 webhook-secret 已配置）
    // 2. 解析 device_id（blade 侧标识）
    // 3. 通过 blade_device_id 映射到本地 Device ID
    // 4. 如果设备未映射 → 返回 404
    // 5. 组装 readings Map（从 properties 转换）
    // 6. 调用 TelemetryIngestionService.ingest(localDeviceId, readings, recordedAt)
    //    注意：ingest() 内部会从 Installation 解析 farmId 和 livestockId
    // 7. 返回 200
}
```

**与现有 `TelemetryController` 的区别：**

| | TelemetryController（已有） | TelemetryWebhookController（新增） |
|------|------|------|
| 路径 | `POST /api/v1/farms/{farmId}/telemetry` | `POST /api/v1/telemetry/webhook` |
| 调用方 | App 前端、datagen | blade |
| deviceId 格式 | Long（本地 ID） | String（blade ID） |
| 认证 | JWT | 无（内网 + 可选签名） |
| farmId | URL 路径中提供 | 由 TelemetryIngestionService 从 Installation 解析 |
| readings 格式 | `[{temperature: 38.6, ...}]` | `{"properties": {"temperature": 38.6, ...}}` |

**关键实现细节：`properties` → `readings` 转换**

webhook 中的 `properties` 是单层 key-value：
```json
{ "temperature": 38.6, "battery_level": 85, "step_count": 1234 }
```

`TelemetryIngestionService.ingest()` 期望 `Map<String, Object> readings`，key 使用 camelCase：
```java
Map<String, Object> readings = new HashMap<>();
properties.forEach((key, value) -> {
    readings.put(toCamelCase(key), value);  // battery_level → batteryLevel
});
```

### 6.3 修改：Device 领域模型

**`iot/domain/model/Device.java`** — 新增字段：

```java
private String bladeDeviceId;     // hkt-blade-device 的 deviceId
private Integer rssi;
private BigDecimal snr;
private Integer spreadingFactor;
private String lastGateway;

// 新增方法
public void bindBladeDevice(String bladeDeviceId) { ... }
public void updateBladeTelemetry(Integer rssi, BigDecimal snr,
                                  Integer sf, String gateway,
                                  Integer batteryLevel, String runtimeStatus) { ... }
```

**`iot/domain/repository/DeviceRepository.java`** — 新增查询：

```java
Optional<Device> findByBladeDeviceId(String bladeDeviceId);
```

**`iot/infrastructure/persistence/entity/DeviceJpaEntity.java`** — 新增 5 个字段映射。

**`iot/infrastructure/persistence/SpringDataDeviceRepository.java`** — 新增：

```java
Optional<DeviceJpaEntity> findByBladeDeviceId(String bladeDeviceId);
```

### 6.4 修改：设备注册流程

**`iot/application/DeviceApplicationService.java`** `registerDevice()` 方法：

```
改造前：（纯本地）
  ① 校验 deviceCode 唯一性
  ② 构建 Device → save → 返回 DTO

改造后：（有条件走 blade）
  ① 校验 deviceCode 唯一性
  ② 如果提供了 sn 且 blade.oauth2.enabled=true：
     a. BladeLicenseClient.getLicenseStatusBySn(sn)
        → 验证 isValid，获取 devEui + deviceTypeCode
     b. BladeDeviceClient.registerDevice(devEui, deviceTypeCode)
        → 获取 bladeDeviceId
  ③ 构建 Device（含 bladeDeviceId, devEui）→ save → 返回 DTO
  ④ 如果 blade.oauth2.enabled=false → 完全走旧逻辑（不做任何 blade 调用）
```

### 6.5 修改：DeviceDto + DeviceMapper

`DeviceDto.java` 新增 5 个字段透出，`DeviceMapper.java` 新增映射。

### 6.6 新增：Flyway 迁移

`V{yyyyMMddHHmmss}__phase_c_blade_integration.sql`：

```sql
ALTER TABLE devices
    ADD COLUMN IF NOT EXISTS blade_device_id VARCHAR(64),
    ADD COLUMN IF NOT EXISTS rssi INTEGER,
    ADD COLUMN IF NOT EXISTS snr NUMERIC(4,1),
    ADD COLUMN IF NOT EXISTS spreading_factor INTEGER,
    ADD COLUMN IF NOT EXISTS last_gateway VARCHAR(128);

CREATE UNIQUE INDEX IF NOT EXISTS idx_devices_blade_device_id
    ON devices (blade_device_id) WHERE blade_device_id IS NOT NULL;
```

### 6.7 修改：设备详情 + 遥测查询（可选增强）

`DeviceController` 的 `GET /api/v1/devices/{id}` → 如果设备有 `bladeDeviceId` 且 blade 可用 → 调用 `BladeDeviceClient.getDeviceWithTelemetry()` 获取实时遥测 → 合并返回。

### 6.8 修改：错误码 + i18n

`shared/common/ErrorCode.java` 新增：

```java
BLADE_DEVICE_NOT_MAPPED("BLADE_001", "未找到 blade 设备映射"),
BLADE_SERVICE_UNAVAILABLE("BLADE_002", "设备中台服务暂时不可用"),
BLADE_REGISTRATION_FAILED("BLADE_003", "设备中台注册失败"),
BLADE_LICENSE_INVALID("BLADE_004", "设备序列号未激活或已失效"),
```

**i18n messages 同步维护**（`messages.properties` + `messages_zh_CN.properties`）。

### 6.9 Smart-Livestock 团队交付物清单

| # | 交付物 | 类型 | 优先级 |
|---|--------|------|--------|
| B1 | `BladeAuthTokenProvider` | 代码 | P0 |
| B2 | `BladeLicenseClient` + `BladeDeviceClient` + `BladeHistoryClient` | 代码 | P0 |
| B3 | Blade DTO 类（6 个） | 代码 | P0 |
| B4 | `TelemetryWebhookController` | 代码 | P0 |
| B5 | Device 模型扩展（字段 + 方法 + JPA + Repository） | 代码 | P0 |
| B6 | DeviceApplicationService 注册流程改造 | 代码 | P0 |
| B7 | Flyway 迁移 SQL | 代码 | P0 |
| B8 | 配置项 `application.yml` | 配置 | P0 |
| B9 | ErrorCode + i18n | 代码 | P1 |
| B10 | Docker Compose 环境变量更新 | 运维 | P1 |

---

## 7. 数据模型对齐（双方共享）

### 7.1 Device ID 映射

```
blade 侧                    smart-livestock 侧
┌─────────────────┐         ┌─────────────────────────────┐
│ deviceId: String │ ←───→  │ blade_device_id: VARCHAR(64) │
│ (UUID 或编码字符串) │         │ id: BIGSERIAL (本地主键)      │
└─────────────────┘         └─────────────────────────────┘
```

blade 推送 webhook 时使用 `device_id`（String），smart-livestock 通过 `blade_device_id` 字段反查本地 `id`。

### 7.2 DeviceType 枚举映射

| blade `deviceTypeCode` | smart-livestock `DeviceType` | 说明 |
|------|------|------|
| `tracker` | `TRACKER` | GPS 追踪器 |
| `rumenCapsule` | `CAPSULE` | 瘤胃胶囊 |
| `earTag` | `EAR_TAG` | 耳标 |

> **待确认**：blade 侧 `deviceTypeCode` 的精确取值。以上为从 open-platform-dev 推测值，需 blade 团队最终确认。

### 7.3 设备状态概念差异

| | blade `onlineStatus` | smart-livestock `status` |
|------|------|------|
| **含义** | 运行时在线状态（online/offline） | 生命周期状态（INVENTORY→ACTIVE→OFFLINE→DECOMMISSIONED） |
| **更新方式** | 心跳超时自动判定 | 人工操作状态机 |
| **Phase C 集成** | webhook 推送持续更新 `runtimeStatus` | 保持独立，不自动变更 |

两个状态机**各自独立维护**，不互相驱动。

---

## 8. 对接测试方案

### 8.1 测试环境准备

| 环境 | 配置 | 用途 |
|------|------|------|
| **blade 测试环境** | 内网可访问，含测试设备 License | 联调测试 |
| **smart-livestock 测试环境** | `BLADE_OAUTH2_ENABLED=true`，指向 blade 测试地址 | 联调测试 |
| **smart-livestock CI** | `BLADE_OAUTH2_ENABLED=false` | 本地开发/CI |

### 8.2 测试阶段与用例

#### 阶段 1：连通性测试（blade 已有 API）

**前置条件**：blade 提供 OAuth2 凭据 + 网络已通

| # | 测试用例 | 调用方 | 验证点 |
|---|----------|--------|--------|
| 1.1 | OAuth2 换票成功 | smart-livestock | `BladeAuthTokenProvider.getToken()` 返回有效 token |
| 1.2 | License 查询 — 有效 SN | smart-livestock | `getLicenseStatusBySn("SN-TEST-001")` → `isValid=true` |
| 1.3 | License 查询 — 无效 SN | smart-livestock | 返回 `isValid=false`，smart-livestock 正确拒绝注册 |
| 1.4 | 设备注册 | smart-livestock | 提供 devEui + deviceTypeCode → 返回 bladeDeviceId |
| 1.5 | 设备详情 + 遥测 | smart-livestock | bladeDeviceId + token → 返回完整 `DeviceTelemetryResp` |
| 1.6 | 历史数据分页 | smart-livestock | 时间范围 + token → 返回分页 records |

**测试方式**：smart-livestock 团队在测试环境（`BLADE_OAUTH2_ENABLED=true`）运行集成测试，直连 blade 测试环境。

#### 阶段 2：Webhook 推送测试（blade 新增功能）

**前置条件**：blade webhook 引擎已开发完成 + smart-livestock `TelemetryWebhookController` 已部署

| # | 测试用例 | 触发方 | 验证点 |
|---|----------|--------|--------|
| 2.1 | 单条遥测推送 | blade（手动触发或测试设备上报） | smart-livestock 返回 200，DB 中 `devices` 表 `rssi/snr` 等字段更新 |
| 2.2 | 批量遥测推送（10 条/秒） | blade | smart-livestock 无丢数据、无超时 |
| 2.3 | 设备未映射 | blade | smart-livestock 返回 404，blade 不重试 |
| 2.4 | smart-livestock 宕机恢复 | blade（模拟 smart-livestock 重启） | blade 重试 5 次后停止，日志记录完整 |
| 2.5 | HTTP 超时 | blade（smart-livestock 侧模拟慢响应） | blade 在 30s 超时后重试 |
| 2.6 | Payload 字段缺失 | blade（发送缺少必填字段的请求） | smart-livestock 返回 400 |

**测试方式**：两队联合调试。建议 blade 先提供一个测试页面或 curl 命令来手动触发 webhook 推送。

#### 阶段 3：端到端业务流程测试

| # | 测试用例 | 流程 | 验证点 |
|---|----------|------|--------|
| 3.1 | 完整设备注册 | App 前端 → smart-livestock `POST /devices` → blade License + 注册 → 返回 | `blade_device_id` 写入 DB，设备状态 ACTIVE |
| 3.2 | 遥测 → 健康分析 | blade webhook 推送温度 → `TelemetryIngestionService` → RocketMQ → Health `TelemetryEventConsumer` → `temperature_logs` 写入 | 查询 `temperature_logs` 有新记录 |
| 3.3 | 遥测 → GPS 日志 | blade webhook 推送 GPS → `extractAndLogGps()` → `gps_logs` 写入 | 查询 `gps_logs` 有新记录 |
| 3.4 | 历史数据查询 | App 前端 → `GET /devices/{id}/history-data` → blade 历史查询 → 返回 | 前端收到分页历史数据 |
| 3.5 | blade 不可用降级 | 停止 blade 服务 → 调用设备注册 / 历史查询 | 注册返回 502，历史查询降级到本地数据 |

#### 阶段 4：签名校验（第一期可选）

| # | 测试用例 | 验证点 |
|---|----------|--------|
| 4.1 | 正确签名 | smart-livestock 校验通过，返回 200 |
| 4.2 | 错误签名 | smart-livestock 返回 401 |
| 4.3 | 签名时间戳过期 | smart-livestock 返回 401 |
| 4.4 | 缺少签名头 | `BLADE_TELEMETRY_WEBHOOK_SECRET` 配置时 401，未配置时 200 |

### 8.3 测试数据

**blade 侧准备：**

| 数据 | 说明 |
|------|------|
| 测试 SN（2-3 个） | 分别对应 tracker / rumenCapsule 类型，License 已激活 |
| 测试设备（已注册） | 可在 ThingsBoard 手动推送遥测数据 |
| 无效 SN | 用于测试 License 拒绝流程 |

**smart-livestock 侧准备：**

| 数据 | 说明 |
|------|------|
| 测试租户 + 牧场 | 用于注册设备后的 Installation 关联 |
| 测试牲畜 | 同上 |
| Mock blade 响应（单元测试用） | 不依赖真实 blade 环境即可运行的核心逻辑测试 |

### 8.4 联调 Checklist

- [ ] blade 提供内网可访问的测试环境地址
- [ ] blade 提供 OAuth2 凭据（client_id + client_secret）
- [ ] blade 确认 token 请求头名称（`token` 还是 `Authorization: Bearer`）
- [ ] blade 确认 `deviceTypeCode` 枚举值清单
- [ ] smart-livestock 提供 webhook URL（`http://{host}:{port}/api/v1/telemetry/webhook`）
- [ ] 网络打通（smart-livestock ↔ blade 双向）
- [ ] 日志约定：双方 ERROR 日志包含 `[PhaseC]` 标记便于排查

---

## 9. 实施顺序与依赖

```
时间线 ──────────────────────────────────────────────────────→

blade 团队:
  [A3 提供凭据] ────────────────── [A1 Webhook引擎开发] ── [A2 配置部署]
       │                                    │
       │  OAuth2 凭据交付                     │  webhook 联调
       ↓                                    ↓
smart-livestock 团队:
  [B1-B3 HTTP Client + DTO] ── [B4 Webhook Controller] ── [B5-B7 模型+注册+迁移]
       │                                                       │
       └── 阶段1 连通性测试 ──────────────────────────────────┘
                                                                  │
                                                          ┌───────┘
                                                          ↓
                                              阶段2 Webhook联调
                                                          │
                                                          ↓
                                              阶段3 端到端验证
```

**关键依赖：**

| 依赖 | 被谁依赖 | 阻塞 |
|------|----------|------|
| blade OAuth2 凭据（A3） | smart-livestock B1-B3 | smart-livestock 无法开始 HTTP Client 联调 |
| blade webhook 引擎（A1） | 阶段 2 联调 | 阶段 1 可以独立进行（仅调 blade 已有 API） |
| smart-livestock WebhookController（B4） | 阶段 2 联调 | blade 无法测试 webhook 推送 |

**并行工作：** 阶段 1 的 smart-livestock HTTP Client 开发 + blade 已有 API 测试，可以与 blade 的 webhook 引擎开发**并行进行**。两队只需共享 OAuth2 凭据即可启动阶段 1。

---

## 10. 风险与待确认项

| # | 风险 | 影响 | 确认方 | 状态 |
|---|------|------|--------|------|
| 1 | blade token 请求头名是 `token` 还是 `Authorization: Bearer` | `BladeAuthTokenProvider` 实现 | blade 团队 | ⏳ 待确认 |
| 2 | blade `deviceTypeCode` 精确取值 | DeviceType 枚举映射 | blade 团队 | ⏳ 待确认 |
| 3 | blade `deviceId` 格式（UUID / 数字串 / 自定义编码） | DB `blade_device_id VARCHAR(64)` 是否够长 | blade 团队 | ⏳ 待确认 |
| 4 | 历史数据 records 的 schema 是否固定 | 前端展示适配 | blade 团队 | ⏳ 待确认 |
| 5 | 1 条 webhook 推送包含多个时间点的数据 vs 每条 webhook 仅 1 个时间点 | Webhook payload 设计 | 双方 | ⏳ 待确认（当前设计为单时间点） |
| 6 | `properties` 中是否应携带 `livestockId` 以跳过 smart-livestock 侧的 Installation 查询 | TelemetryWebhookController 性能 | 双方 | 第一期不携带 |
| 7 | blade 侧 webhook 是否需要 tenant 级别的过滤（仅推送特定租户的设备） | 多租户隔离 | blade 团队 | 第一期全量推送 |

---

## 11. 附录

### A. 参考文件索引

| 参考源 | 路径 | 内容 |
|--------|------|------|
| blade Feign 客户端 | `open-platform-dev/.../client/DeviceServiceClient.java` | blade REST 端点签名 |
| blade Feign 客户端 | `open-platform-dev/.../client/DeviceHistoryDataClient.java` | 历史数据接口 |
| blade Feign 客户端 | `open-platform-dev/.../client/DeviceLicenseClient.java` | License 接口 |
| blade 响应包络 | `open-platform-dev/.../InternalResponse.java` | `{code, success, data, msg}` |
| blade 遥测 DTO | `open-platform-dev/.../internal/DeviceTelemetryResp.java` | blade 侧完整遥测结构 |
| blade License DTO | `open-platform-dev/.../internal/LicenseStatusResp.java` | blade License 响应 |
| OAuth2 换票 | `open-platform-dev/.../oauth/OpenApiGatewayTokenService.java` | 换票流程参考 |
| 现有 HTTP Client | `smart-livestock-server/.../RestAnomalyScoreClient.java` | `java.net.http.HttpClient` 模式 |
| 现有遥测 pipeline | `smart-livestock-server/.../TelemetryIngestionService.java` | 不需改动的核心 |
| 现有遥测端点 | `smart-livestock-server/.../TelemetryController.java` | 现有格式，webhook 用新 Controller |
| 现有 Device 模型 | `smart-livestock-server/.../Device.java` | 新增字段的宿主 |
| 遥测事件模型 | `smart-livestock-server/.../TelemetryReceivedEvent.java` | 事件结构 |
| 遥测事件消费 | `smart-livestock-server/.../TelemetryEventConsumer.java` | Health 侧 RocketMQ 消费 |
| 现有设计文档 | `docs/superpowers/specs/2026-06-03-iot-telemetry-ingestion-design.md` | 遥测 pipeline 原始设计 |
| 现有设计文档 | `docs/superpowers/specs/2026-06-04-telemetry-redesign-spec.md` | Telemetry 重构规格 |
