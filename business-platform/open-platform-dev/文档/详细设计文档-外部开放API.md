# 详细设计文档：外部开放 API

| 项目 | 内容 |
|------|------|
| 文档版本 | v1.0 |
| 状态 | 草案 |
| 依据 | 《产品需求文档-外部开放API-设备控制 v1.3》、《AI智能体技术架构》 |
| 更新日期 | 2026-04-27 |

---

## 1. 概述

### 1.1 背景

基于《产品需求文档-外部开放API-设备控制 v1.3》，需新增一个**开放 API 服务**（Open API Service），作为外部客户端访问内部系统的统一入口。该服务部署于现有 Spring Cloud Alibaba 微服务体系内，承接网关转发的开放 API 请求，完成外部凭证鉴权后，通过 OpenFeign 调用内部微服务（空间服务、设备服务、设备中台等）。

### 1.2 目标

- 实现双层凭证模型（appId/appSecret + API Key）的认证与授权
- 对外部暴露 RESTful 接口，对内通过 OpenFeign 转换为内部服务调用
- 密钥管理逻辑由 Open API 服务自行处理（自建表）
- 空间管理、设备操作等业务请求透传至对应内部微服务
- 兼容 AI 智能体场景（API Key 可关联内部用户）

### 1.3 术语对照

| 外部术语 | 内部映射 | 说明 |
|----------|----------|------|
| 集成方 / 客户 | 租户（Tenant） | 一个 appId 对应一个租户 |
| appId | open_app.app_id | 租户标识 |
| appSecret | open_app.app_secret_hash（哈希存储） | 租户凭证 |
| API Key | open_api_key.api_key_hash（哈希存储） | 访问密钥 |
| key_id | open_api_key.key_id | Key 的对外标识 |
| 空间（space） | 空间节点（SpaceNode） | 设备的物理/逻辑分组 |
| 空间 ID（space_id） | nodeId | 空间节点主键 ID |
| 设备（device） | 内部设备服务实体 | 智能设备 |
| 设备序列号（sn） | deviceSn | 设备 SN 码，通过 License 服务查询获取 deviceEui |
| 设备类型（type） | deviceTypeCode | 设备类型编码（如 RUMEN_CAPSULE） |
| LoginUser | LoginUser | 设备服务内部用户对象，含 userId/userName/tenantId |

---

## 2. 架构设计

### 2.1 整体架构

```
外部客户端（波兰客户 / AI 智能体）
        │ HTTPS
        ▼
    Nginx / WAF
        │
        ▼
  Spring Cloud Gateway
        │
        │  路由规则：路径前缀 /open-api/v1/*
        │  不走内部 OAuth2.0 / JWT 认证
        ▼
  ┌──────────────────────────────────────────────────┐
  │              Open API 服务（新增微服务）            │
  │                                                    │
  │  ┌─────────────┐  ┌──────────────┐                │
  │  │ 鉴权过滤器   │  │ 密钥管理模块  │ ← 自建表       │
  │  │（Filter）   │  │ /api-keys    │                │
  │  └──────┬──────┘  └──────────────┘                │
  │         │                                          │
  │         │ 鉴权通过，携带 app_id + scope             │
  │         │                                          │
  │  ┌──────┴──────────────────────────┐               │
  │  │        BFF 转发模块              │               │
  │  │  ┌──────────┐ ┌──────────┐     │               │
  │  │  │ 空间适配器 │ │ 设备适配器 │     │               │
  │  │  └────┬─────┘ └────┬─────┘     │               │
  │  └───────┼────────────┼───────────┘               │
  └──────────┼────────────┼───────────────────────────┘
             │            │
        OpenFeign    OpenFeign
             │            │
             ▼            ▼
     ┌──────────────┐  ┌──────────────┐
     │  空间服务      │  │  设备服务      │
     │  (已有微服务)  │  │  (已有微服务)  │
     └──────────────┘  └──────┬───────┘
                             │
                             ▼
                      ┌──────────────┐
                      │  设备中台      │
                      │ (ThingsBoard) │
                      └──────────────┘
```

### 2.2 服务定位

Open API 服务在架构中的定位是**外部协议的 BFF（Backend for Frontend）层**，职责包括：

| 职责 | 说明 |
|------|------|
| 外部鉴权 | 校验 appId/appSecret（密钥管理接口）或 API Key（业务接口） |
| 协议转换 | 将外部 REST 接口参数映射为内部微服务接口参数 |
| 租户隔离 | 从凭证中提取 app_id，作为租户上下文传递给内部服务 |
| Scope 校验 | 根据 API Key 的 scope 与 HTTP 方法判定权限 |
| 密钥管理 | API Key 的创建、查询、吊销、轮换（自建表，自处理） |
| 审计日志 | 记录外部 API 的调用日志 |

**Open API 服务不做的事情：**
- 不处理设备实际控制逻辑（由设备中台完成）
- 不存储设备/空间业务数据（由内部微服务完成）
- 不做业务规则校验（由内部微服务完成）

### 2.3 请求流转路径

#### 2.3.1 密钥管理请求

```
客户端 → Nginx → Gateway（按前缀路由） → Open API 服务
    → 鉴权过滤器：提取 appId + appSecret → 查 open_app 表 → bcrypt 比对
    → 密钥管理模块：操作 open_app / open_api_key 表
    → 直接返回 JSON 响应
```

#### 2.3.2 空间管理请求

```
客户端 → Nginx → Gateway → Open API 服务
    → 鉴权过滤器：提取 API Key → 查 open_api_key 表 → 校验 scope
    → 空间适配器：字段映射 → OpenFeign → 空间服务
    → 空间服务返回 → 字段映射 → 返回 JSON 响应
```

#### 2.3.3 设备注册请求

```
客户端 → Nginx → Gateway → Open API 服务
    → 鉴权过滤器：提取 API Key → 校验 scope
    → License 查询：sn → License 服务 → 获取 deviceEui + deviceTypeCode
    → 设备注册：OpenFeign → 设备服务 registerDevice
    → 空间绑定（可选）：OpenFeign → 空间服务 binding/create
    → 更新名称（可选）：OpenFeign → 设备服务 updateDeviceInfo
    → 返回结果
```

#### 2.3.4 设备操作请求（读/写/控制）

```
客户端 → Nginx → Gateway → Open API 服务
    → 鉴权过滤器：提取 API Key → 查 open_api_key 表 → 校验 scope
    → 设备适配器：字段映射 → OpenFeign → 设备服务
    → 设备服务处理（可能进一步调用设备中台 ThingsBoard）
    → 返回结果 → 字段映射 → 返回 JSON 响应
```

### 2.4 网关路由配置

在 Spring Cloud Gateway 中新增路由规则，将 `/open-api/v1/**` 前缀的请求转发到 Open API 服务，且**不经过内部 OAuth2.0 认证过滤器**：

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: open-api-route
          uri: lb://open-api-service   # Nacos 服务名
          predicates:
            - Path=/open-api/v1/**
          filters:
            - StripPrefix=1             # 去掉 /open-api 前缀，保留 /v1/...
          # 该路由不走内部 OAuth2.0 认证
```

**关键点：** 需在 Gateway 的安全配置中，将 `/open-api/v1/**` 路径排除在内部 OAuth2.0 认证链之外。外部认证由 Open API 服务自行负责。

---

## 3. 服务设计

### 3.1 技术选型

| 组件 | 选型 | 版本 | 说明 |
|------|------|------|------|
| 构建工具 | Maven | — | 与现有微服务一致 |
| 框架 | Spring Boot | 3.5.3 | 与现有微服务技术栈一致 |
| 微服务框架 | Spring Cloud | 2025.0.0 | — |
| 微服务框架 | Spring Cloud Alibaba | 2023.0.3.3 | Nacos、Sentinel 等 |
| 注册/配置中心 | Nacos | — | 服务注册与配置管理 |
| 服务间调用 | OpenFeign | — | 调用空间服务、设备服务 |
| 熔断限流 | Sentinel | — | 与现有体系一致 |
| ORM | MyBatis-Plus | — | 操作自建的三张业务表 |
| 数据库 | PostgreSQL | — | 存储凭证、密钥、审计日志 |
| 缓存 | Redis | — | API Key 校验缓存、限流 |
| 密码哈希 | BCrypt | — | appSecret 与 API Key 的安全存储 |
| 消息队列 | RocketMQ | — | 审计日志异步写入（可选） |
| 链路追踪 | SkyWalking | — | 与现有体系一致 |
| API 文档 | SpringDoc OpenAPI | — | 生成 Swagger UI，便于开发联调 |

### 3.2 工程信息

| 项目 | 值 |
|------|-----|
| Group ID | `com.ai.openapi` |
| Artifact ID | `open-api-service` |
| Nacos 服务名 | `open-api-service` |
| 基础包路径 | `com.ai.openapi` |

### 3.2 模块划分

```
src/main/java/com/ai/openapi/
├── auth/                    # 鉴权模块
│   ├── filter/              # WebFilter：拦截所有请求，提取凭证并校验
│   ├── strategy/            # 认证策略：AppAuthStrategy / ApiKeyAuthStrategy
│   └── context/             # 请求上下文：存放当前 app_id、scope、key_id 等
├── key/                     # 密钥管理模块
│   ├── controller/          # REST 控制器
│   ├── service/             # Key 的 CRUD、轮换逻辑
│   └── generator/           # API Key 生成器（安全随机）
├── space/                   # 空间管理 BFF 模块
│   ├── controller/          # REST 控制器
│   ├── adapter/             # 字段映射适配器（外部 ↔ 内部）
│   └── client/              # OpenFeign 客户端（SpaceServiceClient、SpaceBindingClient）
├── device/                  # 设备操作 BFF 模块
│   ├── controller/          # REST 控制器
│   ├── adapter/             # 字段映射适配器
│   └── client/              # OpenFeign 客户端（DeviceServiceClient）
├── audit/                   # 审计模块
│   ├── interceptor/         # 请求/响应拦截器
│   └── service/             # 审计日志记录
├── mapper/                  # MyBatis-Plus Mapper
│   ├── OpenAppMapper.java
│   ├── OpenApiKeyMapper.java
│   └── OpenApiAuditLogMapper.java
├── entity/                  # 数据实体（对应数据库表）
│   ├── OpenApp.java
│   ├── OpenApiKey.java
│   └── OpenApiAuditLog.java
├── common/                  # 公共模块
│   ├── exception/           # 统一异常处理
│   ├── response/            # 统一响应体
│   ├── config/              # SpringDoc、Redis、BCrypt 等配置
│   └── util/                # 工具类
└── OpenApiApplication.java  # 启动类
```

---

## 4. 鉴权设计

### 4.1 鉴权策略路由

鉴权过滤器（AuthFilter）根据请求路径决定使用哪种认证策略：

```
请求进入 AuthFilter
    │
    ├─ 路径匹配 /v1/api-keys/**  →  AppAuthStrategy（appId + appSecret）
    │
    └─ 其余路径                     →  ApiKeyAuthStrategy（API Key）
```

### 4.2 密钥管理接口鉴权流程（AppAuthStrategy）

```
1. 从请求中提取凭证
   - 推荐：Authorization: Basic base64(appId:appSecret)
   - 或：自定义 Header 组合（X-App-Id + X-App-Secret）

2. 查询数据库
   SELECT * FROM open_app WHERE app_id = ? AND status = 'active'

3. 校验 appSecret
   - BCrypt.checkpw(输入的 appSecret, 数据库中的 app_secret_hash)

4. 校验通过
   - 将 app_id 存入请求上下文（RequestContext）
   - 后续业务逻辑可从上下文获取 app_id 用于数据隔离

5. 校验失败
   - 返回 401 Unauthorized
```

### 4.3 业务接口鉴权流程（ApiKeyAuthStrategy）

```
1. 从请求中提取 API Key
   - X-API-Key: <api_key>
   - 或：Authorization: Bearer <api_key>

2. 查询缓存（Redis）
   - Key: "open_api_key:hash:{sha256(api_key)}"
   - 命中缓存 → 直接获取 key 信息，跳到步骤 5
   - 未命中 → 继续步骤 3

3. 查询数据库
   SELECT * FROM open_api_key
   WHERE api_key_hash = ? AND status = 'active'

4. 写入缓存（TTL 与 Key 过期时间对齐，无过期 Key 默认 5 分钟）

5. 逐项校验
   ├─ Key 是否存在且状态为 active    → 否则 401
   ├─ Key 是否已过期                  → 是则 401
   └─ scope 是否允许当前 HTTP 方法    → 否则 403

6. 校验通过
   - 将 app_id、key_id、scope 存入 RequestContext
   - 异步更新 last_used_at（通过消息队列或定时批量更新，避免高频写库）

7. 校验失败
   - 401：凭证无效或已过期
   - 403：scope 不允许该操作
```

### 4.4 Scope 与 HTTP 方法校验矩阵

| Scope | GET | POST | PUT | DELETE |
|-------|-----|------|-----|--------|
| `read` | Y | N | N | N |
| `write` | N | Y | Y | N |
| `read_write` | Y | Y | Y | N |
| `admin` | Y | Y | Y | Y |

### 4.5 请求上下文（RequestContext）

鉴权通过后，将以下信息存入 ThreadLocal（或响应式 Context），供后续业务逻辑和 OpenFeign 拦截器使用：

```
RequestContext {
    Long    appId;          // 内部租户 ID
    String  appExternalId;  // 对外 appId
    Long    keyId;          // API Key 记录 ID（密钥管理接口为 null）
    String  keyExternalId;  // 对外 key_id（密钥管理接口为 null）
    String  scope;          // 当前 Key 的 scope
    String  clientIp;       // 客户端 IP
}
```

OpenFeign 调用内部服务时，通过 RequestInterceptor 将 `appExternalId`（或内部 appId）放入请求头（如 `X-Tenant-Id`），内部服务据此做租户隔离。

---

## 5. 数据模型

### 5.1 ER 关系

```
┌──────────────┐       ┌──────────────────┐
│   open_app   │  1:N  │   open_api_key   │
│──────────────│◄──────│──────────────────│
│ id (PK)      │       │ id (PK)          │
│ app_id (UQ)  │       │ app_id (FK)      │
│ app_secret   │       │ key_id (UQ)      │
│   _hash      │       │ api_key_hash     │
│ name         │       │ description      │
│ status       │       │ scope            │
│ created_at   │       │ status           │
│ updated_at   │       │ expires_at       │
│              │       │ last_used_at     │
│              │       │ internal_user_id │
│              │       │ created_at       │
│              │       │ rotated_at       │
└──────────────┘       └──────────────────┘
```

### 5.2 表结构

#### 5.2.1 open_app（集成方应用）

```sql
CREATE TABLE open_app (
    id              BIGSERIAL       PRIMARY KEY,
    app_id          VARCHAR(64)     NOT NULL UNIQUE,       -- 对外标识，人工发放
    app_secret_hash VARCHAR(255)    NOT NULL,              -- appSecret 的 BCrypt 哈希
    name            VARCHAR(128)    NOT NULL,              -- 应用名称/客户名称
    description     VARCHAR(512)    DEFAULT NULL,          -- 备注
    status          VARCHAR(16)     NOT NULL DEFAULT 'active',  -- active / disabled
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_open_app_status ON open_app(status);
```

#### 5.2.2 open_api_key（API Key）

```sql
CREATE TABLE open_api_key (
    id              BIGSERIAL       PRIMARY KEY,
    app_id          BIGINT          NOT NULL REFERENCES open_app(id),  -- 关联应用
    key_id          VARCHAR(64)     NOT NULL UNIQUE,       -- 对外标识，用于列表/吊销/轮换
    api_key_hash    VARCHAR(255)    NOT NULL,              -- API Key 的 BCrypt 哈希
    description     VARCHAR(256)    DEFAULT NULL,
    scope           VARCHAR(16)     NOT NULL,              -- read / write / read_write / admin
    status          VARCHAR(16)     NOT NULL DEFAULT 'active',  -- active / revoked
    expires_at      TIMESTAMPTZ     DEFAULT NULL,          -- 过期时间，NULL 表示永不过期
    last_used_at    TIMESTAMPTZ     DEFAULT NULL,
    internal_user_id BIGINT         DEFAULT 1,              -- 关联内部用户 ID（一期固定为 1，后续对接）
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    rotated_at      TIMESTAMPTZ     DEFAULT NULL           -- 上次轮换时间
);

CREATE INDEX idx_open_api_key_app ON open_api_key(app_id);
CREATE INDEX idx_open_api_key_hash ON open_api_key(api_key_hash);
CREATE INDEX idx_open_api_key_status ON open_api_key(status);
CREATE INDEX idx_open_api_key_expires ON open_api_key(expires_at) WHERE expires_at IS NOT NULL;
```

#### 5.2.3 open_api_audit_log（审计日志）

```sql
CREATE TABLE open_api_audit_log (
    id              BIGSERIAL       PRIMARY KEY,
    app_id          BIGINT          NOT NULL,
    key_id          BIGINT          DEFAULT NULL,          -- 密钥管理接口时为 NULL
    http_method     VARCHAR(8)      NOT NULL,
    request_path    VARCHAR(512)    NOT NULL,
    response_status SMALLINT        NOT NULL,
    client_ip       VARCHAR(64)     DEFAULT NULL,
    request_duration INTEGER        DEFAULT NULL,          -- 请求耗时（毫秒）
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_log_app ON open_api_audit_log(app_id);
CREATE INDEX idx_audit_log_created ON open_api_audit_log(created_at);
```

### 5.3 API Key 生成规则

- 长度：**48 字符**
- 字符集：`ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789`
- 生成方式：`SecureRandom` 生成，确保密码学安全
- 格式示例：`ak_live_xR7kP2mN9vB4jH8wQ1tY6cF3dL5sA0eG`
  - 前缀 `ak_live_` 区分环境（后续若有沙箱可用 `ak_sandbox_`）
  - 后续 40 位为随机字符串
- 存储：仅存 BCrypt 哈希，明文仅在创建/轮换时返回一次

---

## 6. 接口设计

### 6.1 接口总览

所有接口统一前缀：`/open-api/v1`

| 模块 | 方法 | 路径 | 鉴权方式 | 内部处理 |
|------|------|------|----------|----------|
| 密钥管理 | POST | `/v1/api-keys` | appId + appSecret | Open API 自处理 |
| 密钥管理 | GET | `/v1/api-keys` | appId + appSecret | Open API 自处理 |
| 密钥管理 | DELETE | `/v1/api-keys/{key_id}` | appId + appSecret | Open API 自处理 |
| 密钥管理 | PUT | `/v1/api-keys/{key_id}/rotate` | appId + appSecret | Open API 自处理 |
| 空间管理 | GET | `/v1/spaces` | API Key (read+) | OpenFeign → 空间服务 node/page |
| 空间管理 | GET | `/v1/spaces/{space_id}` | API Key (read+) | OpenFeign → 空间服务 node/detail |
| 空间管理 | POST | `/v1/spaces` | API Key (admin) | OpenFeign → 空间服务 node/create |
| 空间管理 | PUT | `/v1/spaces/{space_id}` | API Key (admin) | OpenFeign → 空间服务 node/update |
| 空间管理 | DELETE | `/v1/spaces/{space_id}` | API Key (admin) | OpenFeign → 空间服务 node/delete |
| 设备读 | GET | `/v1/devices` | API Key (read+) | OpenFeign → 设备服务 pageDevices |
| 设备读 | GET | `/v1/devices/{device_id}` | API Key (read+) | OpenFeign → 设备服务 getDeviceDetail |
| 设备写 | POST | `/v1/devices/{device_id}/commands` | API Key (write+) | OpenFeign → 设备服务（待补充） |
| 设备写 | PUT | `/v1/devices/{device_id}/settings` | API Key (write+) | OpenFeign → 设备服务（待补充） |
| 设备写 | DELETE | `/v1/devices/{device_id}/commands/{command_id}` | API Key (write+) | OpenFeign → 设备服务（待补充） |
| 设备写 | GET | `/v1/commands/{command_id}/status` | API Key (write+) | OpenFeign → 设备服务（待补充） |
| 设备管理 | POST | `/v1/devices` | API Key (admin) | License 查询 → 设备服务 registerDevice + 空间绑定 |
| 设备管理 | PUT | `/v1/devices/{device_id}` | API Key (admin) | OpenFeign → 设备服务 updateDeviceInfo |
| 设备管理 | DELETE | `/v1/devices/{device_id}` | API Key (admin) | OpenFeign → 设备服务 removeDevice |

### 6.2 密钥管理接口详细设计

#### 6.2.1 POST `/v1/api-keys` — 创建 API Key

**请求**

```
Authorization: Basic base64(appId:appSecret)
Content-Type: application/json
```

```json
{
  "description": "用于设备数据采集",
  "scope": "read_write",
  "expires_in_days": 90
}
```

**处理逻辑**

```
1. 鉴权过滤器：校验 appId + appSecret（AppAuthStrategy）
2. 校验 scope 枚举值
3. 生成 key_id（UUID 或 NanoId，32 位）
4. 生成 api_key（SecureRandom，48 字符，ak_live_ 前缀）
5. BCrypt 哈希 api_key
6. 计算 expires_at = NOW() + expires_in_days（未传则为 NULL）
7. INSERT open_api_key
8. 返回明文 api_key（仅此一次）
```

**响应（201）**

```json
{
  "key_id": "key_a1b2c3d4e5f6",
  "api_key": "ak_live_xR7kP2mN9vB4jH8wQ1tY6cF3dL5sA0eG",
  "description": "用于设备数据采集",
  "scope": "read_write",
  "expires_at": "2026-07-26T10:00:00Z",
  "created_at": "2026-04-27T10:00:00Z"
}
```

#### 6.2.2 GET `/v1/api-keys` — 列出所有 Key

**请求**

```
Authorization: Basic base64(appId:appSecret)
```

```
GET /v1/api-keys?limit=20&offset=0
```

**处理逻辑**

```
1. 鉴权：校验 appId + appSecret
2. SELECT open_api_key WHERE app_id = ? ORDER BY created_at DESC
3. 分页（limit / offset）
4. 返回列表（不含 api_key 明文）
```

**响应（200）**

```json
{
  "data": [
    {
      "key_id": "key_a1b2c3d4e5f6",
      "description": "用于设备数据采集",
      "scope": "read_write",
      "status": "active",
      "expires_at": "2026-07-26T10:00:00Z",
      "last_used_at": "2026-04-27T12:30:00Z",
      "created_at": "2026-04-27T10:00:00Z"
    }
  ],
  "total": 1,
  "limit": 20,
  "offset": 0
}
```

#### 6.2.3 DELETE `/v1/api-keys/{key_id}` — 吊销 Key

**请求**

```
Authorization: Basic base64(appId:appSecret)
```

**处理逻辑**

```
1. 鉴权：校验 appId + appSecret
2. SELECT open_api_key WHERE key_id = ? AND app_id = ?
3. 不存在或 app_id 不匹配 → 404
4. UPDATE status = 'revoked'
5. 删除 Redis 缓存
6. 返回
```

**响应（200）**

```json
{
  "key_id": "key_a1b2c3d4e5f6",
  "status": "revoked"
}
```

#### 6.2.4 PUT `/v1/api-keys/{key_id}/rotate` — 轮换 Key

**请求**

```
Authorization: Basic base64(appId:appSecret)
```

**处理逻辑**

```
1. 鉴权：校验 appId + appSecret
2. SELECT open_api_key WHERE key_id = ? AND app_id = ? AND status = 'active'
3. 不存在 → 404
4. 生成新 api_key（新明文）
5. UPDATE api_key_hash = 新哈希, rotated_at = NOW()
6. 删除 Redis 旧缓存
7. 返回新 api_key（仅此一次）
```

**响应（200）**

```json
{
  "key_id": "key_a1b2c3d4e5f6",
  "new_api_key": "ak_live_G8eA0sL5dF3cY6tQ1wH8jB4vN9mP2kRx",
  "rotated_at": "2026-04-27T14:00:00Z"
}
```

### 6.3 空间管理接口详细设计

空间管理接口为 BFF 层，Open API 服务负责鉴权和字段映射，实际数据操作由空间服务（hkt-blade-space-resource-service）完成。内部服务认证方式为 `Authorization: Bearer {token}`，Open API 通过 Feign 调用时由 `FeignAuthInterceptor` 注入认证信息。

**内部服务响应格式**（所有内部服务统一）：
```json
{ "code": 200, "success": true, "data": {}, "msg": "操作成功" }
```

#### 6.3.1 GET `/v1/spaces` — 查询空间列表（分页）

**请求**

```
X-API-Key: ak_live_xR7kP2mN9vB4jH8wQ1tY6cF3dL5sA0eG
```

```
GET /v1/spaces?name=会议室&level_id=level_002&parent_id=node_001&limit=20&offset=0
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | String | 否 | 空间名称（模糊查询） |
| level_id | String | 否 | 层级 ID |
| parent_id | String | 否 | 父节点 ID |
| limit | Integer | 否 | 每页条数，默认 20 |
| offset | Integer | 否 | 偏移量，默认 0 |

**处理逻辑**

```
1. 鉴权：ApiKeyAuthStrategy（scope 需含 read）
2. 分页参数映射：
   - limit → size
   - offset → current（offset/limit + 1）
3. OpenFeign → 空间服务
   GET /v1/space/node/page?name={name}&levelId={level_id}&parentId={parent_id}&current={current}&size={size}
4. 响应映射：
   - nodeId → space_id
   - name → name
   - levelId → level_id
   - levelName → level_name
   - createdAt → created_at
```

**响应（200）**

```json
{
  "data": [
    {
      "space_id": "node_123456",
      "name": "A栋办公楼",
      "parent_id": null,
      "root_id": "node_123456",
      "level_id": "level_001",
      "level_name": "楼栋",
      "created_at": "2024-01-15T10:30:00Z"
    }
  ],
  "total": 1,
  "limit": 20,
  "offset": 0
}
```

#### 6.3.2 GET `/v1/spaces/{space_id}` — 查询空间详情

**请求**

```
GET /v1/spaces/node_123456
```

**处理逻辑**

```
1. 鉴权：ApiKeyAuthStrategy（scope 需含 read）
2. 字段映射：space_id → nodeId
3. OpenFeign → 空间服务
   GET /v1/space/node/detail/{nodeId}
4. 响应映射：nodeId → space_id，同上字段映射
```

**响应（200）**

```json
{
  "space_id": "node_123456",
  "name": "A栋办公楼",
  "parent_id": null,
  "root_id": "node_123456",
  "level_id": "level_001",
  "level_name": "楼栋",
  "area": 5000.00,
  "created_at": "2024-01-15T10:30:00Z"
}
```

#### 6.3.3 POST `/v1/spaces` — 创建空间

**请求**

```
X-API-Key: ak_live_...
Content-Type: application/json
```

```json
{
  "name": "3楼大厅",
  "level_id": "level_002",
  "parent_id": "node_123456"
}
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | String | 是 | 空间名称 |
| level_id | String | 是 | 层级 ID |
| parent_id | String | 否 | 父节点 ID（创建根节点时为空） |
| area | Number | 否 | 面积 |

**处理逻辑**

```
1. 鉴权：ApiKeyAuthStrategy（scope = admin）
2. 字段映射：
   - name → name
   - level_id → levelId
   - parent_id → parentId
   - area → area
3. OpenFeign → 空间服务
   POST /v1/space/node/create
   Body: { name, levelId, parentId, rootId, area, path }
   （rootId 和 path 由空间服务内部处理）
4. 空间服务返回新创建的 nodeId
5. 字段映射：nodeId → space_id，返回给客户端
```

**响应（201）**

```json
{
  "space_id": "node_789012",
  "name": "3楼大厅",
  "level_id": "level_002",
  "parent_id": "node_123456",
  "created_at": "2026-04-27T10:00:00Z"
}
```

#### 6.3.4 PUT `/v1/spaces/{space_id}` — 修改空间

**请求**

```
X-API-Key: ak_live_...
Content-Type: application/json
```

```json
{
  "name": "3楼大厅（已改造）",
  "level_id": "level_002",
  "area": 1200
}
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | String | 是 | 空间名称 |
| level_id | String | 是 | 层级 ID |
| parent_id | String | 否 | 父节点 ID |
| area | Number | 否 | 面积 |

**处理逻辑**

```
1. 鉴权：ApiKeyAuthStrategy（scope = admin）
2. 字段映射：
   - space_id → nodeId（放入请求体，非路径参数）
   - name → name
   - level_id → levelId
   - parent_id → parentId
   - area → area
3. OpenFeign → 空间服务
   PUT /v1/space/node/update
   Body: { nodeId: space_id, name, levelId, parentId, rootId, path }
   注意：nodeId 在请求体中，不在路径中；name 和 levelId 均必填
4. 返回修改结果
```

**响应（200）**

```json
{
  "space_id": "node_789012",
  "name": "3楼大厅（已改造）",
  "area": 1200
}
```

#### 6.3.5 DELETE `/v1/spaces/{space_id}` — 删除空间

**处理逻辑**

```
1. 鉴权：ApiKeyAuthStrategy（scope = admin）
2. 字段映射：space_id → nodeId
3. OpenFeign → 空间服务
   DELETE /v1/space/node/delete/{nodeId}
4. 空间服务执行逻辑删除，级联删除所有子节点
5. 返回
```

**响应（200）**

```json
{
  "space_id": "node_789012",
  "deleted": true
}
```

### 6.4 设备接口详细设计

设备接口为 BFF 层，Open API 调用设备服务（hkt-blade-device）。设备服务的 `@Inner` 注解仅标识接口为内部接口，认证方式同为 `Authorization: Bearer {token}`。所有请求体需包含 `LoginUser { userId, userName, tenantId }` 对象用于身份传递和租户隔离。

**内部服务响应格式**（所有内部服务统一）：
```json
{ "code": 200, "success": true, "data": { ... }, "msg": "操作成功" }
```

**LoginUser 构造规则**：
- `userId`：从 `open_api_key.internal_user_id` 获取（一期固定为 "1"）
- `userName`：从 open_api_key 关联信息获取（一期固定为 "超级管理员"）
- `tenantId`：从 `RequestContext.appExternalId`（即 appId）获取

#### 6.4.1 GET `/v1/devices` — 查询设备列表（分页）

**请求**

```
X-API-Key: ak_live_...
```

```
GET /v1/devices?keyword=会议室&space_id=node_123456&limit=20&offset=0
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| keyword | String | 否 | 搜索关键字（匹配设备名称、设备标识） |
| space_id | String | 否 | 空间 ID（按空间过滤设备） |
| limit | Integer | 否 | 每页条数，默认 20 |
| offset | Integer | 否 | 偏移量，默认 0 |

**处理逻辑**

```
1. 鉴权：ApiKeyAuthStrategy（scope 需含 read）
2. 构建 LoginUser { userId, userName, tenantId }
3. 分页参数映射：
   - limit → size
   - offset → current（offset/limit + 1）
4. OpenFeign → 设备服务
   POST /feign/v1/device/lifecycle/pageDevices
   Body: {
     user: LoginUser,
     tenantId: appExternalId,
     keyword: "会议室",
     spaceId: "node_123456",    // 待设备服务新增此参数支持
     current: 1,
     size: 20
   }
5. 响应映射：
   - data.records[].deviceId → device_id
   - data.records[].deviceName → name
   - data.records[].deviceTypeCode → type
   - data.records[].deviceTypeName → type_name
   - data.records[].onlineStatusName → status
   - data.records[].onlineStatus → status_code
   - data.records[].createTime → created_at
   - data.records[].lastActiveTime → last_active_at
   - data.total → total
```

**响应（200）**

```json
{
  "data": [
    {
      "device_id": "2037377921942110208",
      "name": "十楼小会议室",
      "type": "SWITCH_PANEL",
      "type_name": "开关面板",
      "status": "在线",
      "status_code": 1,
      "created_at": "2024-01-15T10:30:00+08:00",
      "last_active_at": "2024-01-15T14:20:00+08:00"
    }
  ],
  "total": 5,
  "limit": 20,
  "offset": 0
}
```

> **注意**：`spaceId` 参数目前设备服务的 `pageDevices` 接口尚未支持，需与设备服务团队协调新增此过滤参数。新增后 Open API 适配器直接透传即可。

#### 6.4.2 GET `/v1/devices/{device_id}` — 查询设备详情

**请求**

```
GET /v1/devices/2037377921942110208
```

**处理逻辑**

```
1. 鉴权：ApiKeyAuthStrategy（scope 需含 read）
2. 字段映射：device_id → deviceId
3. OpenFeign → 设备服务
   POST /feign/v1/device/lifecycle/getDeviceDetail
   Body: { deviceId: "2037377921942110208" }
4. 响应映射：同 6.4.1 字段映射规则，额外映射：
   - deviceIdentifier → identifier
   - deviceTypeId → type_id
   - isControlEnabled → control_enabled
   - isDataCollectionEnabled → data_collection_enabled
   - rssi → rssi
   - snr → snr
   - sf → spreading_factor
   - lastGateway → last_gateway
```

**响应（200）**

```json
{
  "device_id": "2037377921942110208",
  "name": "十楼小会议室",
  "identifier": "001a0102ff00057b",
  "type": "SWITCH_PANEL",
  "type_name": "开关面板",
  "type_id": "2000003",
  "status": "在线",
  "status_code": 1,
  "control_enabled": true,
  "data_collection_enabled": true,
  "created_at": "2024-01-15T10:30:00+08:00",
  "last_active_at": "2024-01-15T14:20:00+08:00"
}
```

#### 6.4.3 POST `/v1/devices` — 注册设备

**请求**

```
X-API-Key: ak_live_...  (scope = admin)
Content-Type: application/json
```

```json
{
  "sn": "SN20260428001",
  "name": "瘤胃胶囊-A",
  "space_id": "node_123456"
}
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| sn | String | 是 | 设备序列号（SN 码） |
| name | String | 否 | 设备名称（不传则使用设备类型名称） |
| space_id | String | 否 | 所属空间 ID |

**处理逻辑**

```
1. 鉴权：ApiKeyAuthStrategy（scope = admin）
2. 构建 LoginUser { userId, userName, tenantId }
3. 调用 License 服务查询设备信息
   OpenFeign → License 服务
   GET /api/device-license-client/feign/v1/device-license/control/by-sn?deviceSn={sn}
   响应: { code, success, data: { deviceEui, deviceSn, deviceTypeCode, status, isValid, ... } }
   校验：isValid == true && status 有效
   失败 → 返回 400 INVALID_SN（SN 不存在或未激活）
4. 若传入 space_id，校验空间是否存在：
   OpenFeign → 空间服务 GET /v1/space/node/detail/{nodeId}
   不存在 → 返回 400 INVALID_SPACE
5. OpenFeign → 设备服务（注册设备）
   POST /feign/v1/device/lifecycle/registerDevice
   Body: {
     user: LoginUser,
     deviceIdentifier: "<从 License 返回的 deviceEui>",
     deviceTypeCode: "<从 License 返回的 deviceTypeCode>"
   }
6. 若注册成功且传入了 space_id，创建空间-设备绑定关系：
   OpenFeign → 空间服务
   POST /v1/space/binding/create
   Body: {
     nodeId: "node_123456",
     resourceId: "<返回的 deviceId>",
     resourceType: "1"     // 1=设备
   }
7. 若传入 name，更新设备名称：
   OpenFeign → 设备服务
   POST /feign/v1/device/lifecycle/updateDeviceInfo
   Body: { user: LoginUser, deviceId: "<deviceId>", deviceName: "瘤胃胶囊-A" }
8. 响应映射：deviceId → device_id，deviceTypeCode → type，status → status
```

**响应（201）**

```json
{
  "device_id": "2037377921942110208",
  "type": "RUMEN_CAPSULE",
  "type_name": "瘤胃胶囊",
  "name": "瘤胃胶囊-A",
  "status": "INACTIVE",
  "created_at": "2026-04-27T10:00:00Z"
}
```

#### 6.4.4 DELETE `/v1/devices/{device_id}` — 删除设备

**请求**

```
DELETE /v1/devices/2037377921942110208
```

**处理逻辑**

```
1. 鉴权：ApiKeyAuthStrategy（scope = admin）
2. 构建 LoginUser
3. OpenFeign → 设备服务（逻辑删除，支持批量）
   POST /feign/v1/device/lifecycle/removeDevice
   Body: {
     user: LoginUser,
     deviceIds: ["2037377921942110208"]
   }
4. 返回
```

**响应（200）**

```json
{
  "device_id": "2037377921942110208",
  "deleted": true
}
```

#### 6.4.5 PUT `/v1/devices/{device_id}` — 修改设备信息

**请求**

```json
{
  "name": "十楼大会议室"
}
```

**处理逻辑**

```
1. 鉴权：ApiKeyAuthStrategy（scope = admin）
2. 构建 LoginUser
3. OpenFeign → 设备服务
   POST /feign/v1/device/lifecycle/updateDeviceInfo
   Body: { user: LoginUser, deviceId: device_id, deviceName: "十楼大会议室" }
4. 返回
```

**响应（200）**

```json
{
  "device_id": "2037377921942110208",
  "name": "十楼大会议室"
}
```

#### 6.4.6 设备控制接口

设备控制相关接口（命令下发、设置、取消等）的处理模式：

```
1. 鉴权（scope 需含 write 或 admin）
2. 构建 LoginUser
3. 字段映射
4. OpenFeign → 设备服务（具体接口待设备控制 API 文档确认）
5. 设备服务内部调用设备中台（ThingsBoard）执行实际控制
6. 返回结果映射
```

> **说明**：设备控制类接口的内部 API 细节（命令下发、遥测读取、设置下发等）需待设备服务团队提供对应接口文档后补充。当前设计已预留 BFF 适配器架构，后续仅需实现具体适配逻辑。

---

## 7. 与内部服务的对接

### 7.1 内部服务接口约定

Open API 服务通过 OpenFeign 调用内部服务时，所有服务统一使用 `Authorization: Bearer {token}` 认证。Open API 服务需维护一个内部服务间调用的 token，通过 Feign 拦截器统一注入请求头。

> **说明**：设备服务的 `@Inner` 注解仅标识该接口为内部接口，不改变认证方式。

### 7.2 OpenFeign 客户端定义

Open API 服务通过 OpenFeign 调用三个内部服务。所有客户端需配置 `fallbackFactory` 实现熔断降级。

#### 7.2.1 空间服务客户端（SpaceServiceClient）

服务名：`hkt-blade-space-resource-service`，基础路径：`/v1/space`

```java
@FeignClient(
    name = "hkt-blade-space-resource-service",
    path = "/v1/space/node",
    fallbackFactory = SpaceServiceFallback.class
)
public interface SpaceServiceClient {

    /**
     * 创建空间节点
     * 内部路径: POST /v1/space/node/create
     */
    @PostMapping("/create")
    SpaceNodeResponse createNode(@RequestBody CreateNodeRequest request);

    /**
     * 修改空间节点（nodeId 在请求体中，非路径参数）
     * 内部路径: PUT /v1/space/node/update
     */
    @PutMapping("/update")
    Boolean updateNode(@RequestBody UpdateNodeRequest request);

    /**
     * 删除空间节点（逻辑删除，级联删除子节点）
     * 内部路径: DELETE /v1/space/node/delete/{nodeId}
     */
    @DeleteMapping("/delete/{nodeId}")
    Boolean deleteNode(@PathVariable("nodeId") String nodeId);

    /**
     * 查询单个空间节点详情
     * 内部路径: GET /v1/space/node/detail/{nodeId}
     */
    @GetMapping("/detail/{nodeId}")
    SpaceNodeVO getNodeDetail(@PathVariable("nodeId") String nodeId);

    /**
     * 查询空间节点分页列表
     * 内部路径: GET /v1/space/node/page
     */
    @GetMapping("/page")
    SpacePageResponse pageNodes(
        @RequestParam(value = "name", required = false) String name,
        @RequestParam(value = "levelId", required = false) String levelId,
        @RequestParam(value = "parentId", required = false) String parentId,
        @RequestParam(value = "rootId", required = false) String rootId,
        @RequestParam(value = "current", defaultValue = "1") Integer current,
        @RequestParam(value = "size", defaultValue = "20") Integer size);
}
```

#### 7.2.2 空间绑定客户端（SpaceBindingClient）

服务名：`hkt-blade-space-resource-service`，基础路径：`/v1/space/binding`

```java
@FeignClient(
    name = "hkt-blade-space-resource-service",
    path = "/v1/space/binding",
    fallbackFactory = SpaceBindingFallback.class
)
public interface SpaceBindingClient {

    /**
     * 创建空间-设备绑定关系
     * 内部路径: POST /v1/space/binding/create
     */
    @PostMapping("/create")
    String createBinding(@RequestBody CreateBindingRequest request);
}
```

#### 7.2.3 设备服务客户端（DeviceServiceClient）

服务名：`hkt-blade-device`，基础路径：`/feign/v1/device/lifecycle`

> **注意**：设备服务所有接口均为 `@Inner` 内部接口，所有请求均使用 POST 方法，请求体需包含 `LoginUser`。

```java
@FeignClient(
    name = "hkt-blade-device",
    path = "/feign/v1/device/lifecycle",
    fallbackFactory = DeviceServiceFallback.class
)
public interface DeviceServiceClient {

    /**
     * 注册设备
     * 内部路径: POST /feign/v1/device/lifecycle/registerDevice
     */
    @PostMapping("/registerDevice")
    DeviceRegistrationResp registerDevice(@RequestBody DeviceRegistrationReq request);

    /**
     * 分页查询设备列表
     * 内部路径: POST /feign/v1/device/lifecycle/pageDevices
     */
    @PostMapping("/pageDevices")
    DevicePageResp pageDevices(@RequestBody DevicePageReq request);

    /**
     * 查询设备列表（不分页）
     * 内部路径: POST /feign/v1/device/lifecycle/listDevices
     */
    @PostMapping("/listDevices")
    List<DeviceDetailResp> listDevices(@RequestBody DeviceListReq request);

    /**
     * 获取设备详情
     * 内部路径: POST /feign/v1/device/lifecycle/getDeviceDetail
     */
    @PostMapping("/getDeviceDetail")
    DeviceDetailResp getDeviceDetail(@RequestBody DeviceDetailReq request);

    /**
     * 修改设备信息（名称）
     * 内部路径: POST /feign/v1/device/lifecycle/updateDeviceInfo
     */
    @PostMapping("/updateDeviceInfo")
    Boolean updateDeviceInfo(@RequestBody DeviceUpdateReq request);

    /**
     * 删除设备（逻辑删除，支持批量）
     * 内部路径: POST /feign/v1/device/lifecycle/removeDevice
     */
    @PostMapping("/removeDevice")
    Boolean removeDevice(@RequestBody DeviceRemoveReq request);

    /**
     * 批量获取设备详情
     * 内部路径: POST /feign/v1/device/lifecycle/batchGetDeviceDetails
     */
    @PostMapping("/batchGetDeviceDetails")
    List<DeviceDetailResp> batchGetDeviceDetails(@RequestBody BatchDeviceDetailReq request);
}
```

#### 7.2.4 License 服务客户端（DeviceLicenseClient）

服务名：`hkt-blade-device-license-client`（待确认），基础路径：`/api/device-license-client`

用于设备注册前，通过 SN 码查询设备 License 信息（deviceEui、deviceTypeCode 等）。

```java
@FeignClient(
    name = "hkt-blade-device-license-client",
    path = "/api/device-license-client/feign/v1/device-license/control",
    fallbackFactory = DeviceLicenseFallback.class
)
public interface DeviceLicenseClient {

    /**
     * 根据 SN 码查询设备 License 状态
     * 内部路径: GET /api/device-license-client/feign/v1/device-license/control/by-sn?deviceSn={sn}
     */
    @GetMapping("/by-sn")
    LicenseStatusResp getLicenseStatusBySn(@RequestParam("deviceSn") String deviceSn);
}
```

#### 7.2.5 内部 DTO 定义

```java
// ========== 通用 ==========

/** 内部用户身份（所有设备服务接口必传） */
public class LoginUser {
    private String userId;     // 用户 ID（一期固定 "1"）
    private String userName;   // 用户名（一期固定 "超级管理员"）
    private String tenantId;   // 租户 ID（即 appId）
}

// ========== 空间服务 DTO ==========

/** 创建空间节点请求 */
public class CreateNodeRequest {
    private String name;       // 必填
    private BigDecimal area;
    private String parentId;
    private String rootId;
    private String levelId;    // 必填
    private String path;
}

/** 修改空间节点请求（nodeId 在请求体中） */
public class UpdateNodeRequest {
    private String nodeId;     // 必填
    private String name;       // 必填
    private BigDecimal area;
    private String parentId;
    private String rootId;
    private String levelId;    // 必填
    private String path;
}

/** 创建空间-设备绑定请求 */
public class CreateBindingRequest {
    private String nodeId;         // 空间节点 ID
    private String resourceId;     // 设备 ID
    private String resourceType;   // "1" = 设备
}

// ========== License 服务 DTO ==========

/** License 状态查询响应 */
public class LicenseStatusResp {
    private String deviceEui;        // 设备 EUI（用作 deviceIdentifier）
    private String deviceSn;         // 设备序列号
    private String deviceTypeCode;   // 设备类型编码（用作 deviceTypeCode）
    private String status;           // License 状态
    private String agentId;          // 代理商 ID
    private String agentCode;        // 代理商编码
    private OffsetDateTime activatedAt; // 激活时间
    private Boolean isValid;         // 是否有效
}

// ========== 设备服务 DTO ==========

/** 设备注册请求 */
public class DeviceRegistrationReq {
    private LoginUser user;
    private String deviceIdentifier;  // 必填：设备唯一标识
    private String deviceTypeCode;    // 必填：设备类型编码
}

/** 设备注册响应 */
public class DeviceRegistrationResp {
    private String deviceId;
    private String deviceIdentifier;
    private String deviceTypeId;
    private String status;
    private OffsetDateTime createTime;
}

/** 设备分页查询请求 */
public class DevicePageReq {
    private String tenantId;
    private String userId;
    private String keyword;
    private String spaceId;          // 待设备服务新增支持
    private Integer current;         // 页码，从 1 开始
    private Integer size;            // 每页大小
}

/** 设备详情响应（设备列表/详情统一结构） */
public class DeviceDetailResp {
    private String deviceId;
    private String deviceName;
    private String deviceIdentifier;
    private String deviceTypeId;
    private String deviceTypeName;
    private String deviceTypeCode;
    private String tenantId;
    private Integer onlineStatus;
    private String onlineStatusName;
    private OffsetDateTime lastActiveTime;
    private Integer isControlEnabled;
    private Integer isDataCollectionEnabled;
    private Integer offlineDuration;
    private OffsetDateTime createTime;
    private Integer rssi;
    private BigDecimal snr;
    private Integer sf;
    private String lastGateway;
}
```
```

### 7.3 OpenFeign 请求拦截器

所有 OpenFeign 调用统一注入 `Authorization: Bearer {token}` 认证头：

```java
@Component
public class FeignAuthInterceptor implements RequestInterceptor {

    @Autowired
    private InternalTokenProvider tokenProvider;  // 内部服务间 token 提供器

    @Override
    public void apply(RequestTemplate template) {
        String token = tokenProvider.getToken();
        template.header("Authorization", "Bearer " + token);
    }
}
```

> `InternalTokenProvider` 负责获取/缓存内部服务间调用 token，具体实现方式（如通过内部 OAuth2 客户端凭证模式获取）待与基础设施团队确认。
```

### 7.4 设备控制数据流

设备控制请求的完整数据流（以发送命令为例）：

```
客户端
  → POST /open-api/v1/devices/{device_id}/commands
  → Nginx → Gateway → Open API 服务
    → 鉴权（API Key, scope 需含 write 或 admin）
    → OpenFeign → 设备服务
      → 设备服务校验设备归属与状态
      → 设备服务调用设备中台（ThingsBoard HTTP API）
        → ThingsBoard → MQTT → 物理设备
    → 设备服务返回 command_id
  → Open API 返回 command_id
```

---

## 8. 字段映射规则

Open API 适配器层负责外部接口字段与内部服务字段之间的转换。

### 8.1 空间相关映射

| 外部字段（Open API） | 内部字段（空间服务 SpaceNodeVO） | 转换规则 |
|---------------------|--------------------------------|----------|
| space_id | nodeId | 直接映射 |
| name | name | 一致 |
| parent_id | parentId | 直接映射 |
| root_id | rootId | 直接映射 |
| level_id | levelId | 直接映射 |
| level_name | levelName | 直接映射 |
| area | area | 直接映射 |
| created_at | createdAt | 直接映射 |

**请求参数映射**（空间创建/修改）：

| 外部字段 | 内部字段 | 说明 |
|----------|----------|------|
| space_id | nodeId | 修改时放入请求体（路径参数传入） |
| name | name | 创建/修改均必填 |
| level_id | levelId | 创建/修改均必填 |
| parent_id | parentId | 可选 |
| area | area | 可选 |

### 8.2 设备相关映射

| 外部字段（Open API） | 内部字段（设备服务 DeviceDetailRespDto） | 转换规则 |
|---------------------|----------------------------------------|----------|
| device_id | deviceId | 直接映射 |
| name | deviceName | 直接映射 |
| identifier | deviceIdentifier | 直接映射 |
| type | deviceTypeCode | 直接映射（如 RUMEN_CAPSULE） |
| type_name | deviceTypeName | 直接映射（如 瘤胃胶囊） |
| type_id | deviceTypeId | 直接映射 |
| status | onlineStatusName | 直接映射（如 "在线"/"离线"） |
| status_code | onlineStatus | Integer（1=在线，0=离线） |
| control_enabled | isControlEnabled | Integer → Boolean（1→true, 0→false） |
| data_collection_enabled | isDataCollectionEnabled | Integer → Boolean |
| created_at | createTime | 直接映射 |
| last_active_at | lastActiveTime | 直接映射 |
| rssi | rssi | 直接映射 |
| snr | snr | 直接映射 |
| spreading_factor | sf | 直接映射 |
| last_gateway | lastGateway | 直接映射 |

**请求参数映射**（设备注册）：

| 外部字段 | 内部字段 | 说明 |
|----------|----------|------|
| sn | deviceSn | 通过 License 服务查询，获取 deviceEui 和 deviceTypeCode |
| sn（License 查询结果） | deviceIdentifier | License 返回的 deviceEui |
| sn（License 查询结果） | deviceTypeCode | License 返回的 deviceTypeCode |
| name | deviceName | 需分两步：先注册，再调用 updateDeviceInfo |
| space_id | nodeId | 通过空间绑定接口 POST /v1/space/binding/create 传递 |

### 8.3 分页参数映射（通用）

所有分页接口外部统一使用 `limit/offset`，内部空间服务和设备服务使用 `current/size`：

| 外部字段 | 内部字段 | 转换规则 |
|----------|----------|----------|
| limit | size | 直接映射 |
| offset | current | `current = offset / size + 1` |

### 8.4 LoginUser 构造映射

### 8.3 LoginUser 构造映射

所有设备服务调用均需在请求体中携带 `LoginUser` 对象：

| LoginUser 字段 | 值来源 | 一期默认值 |
|----------------|--------|-----------|
| userId | open_api_key.internal_user_id | "1" |
| userName | open_api_key 关联用户名 | "超级管理员" |
| tenantId | RequestContext.appExternalId | 即外部 appId |

### 8.5 内部响应解包规则

所有内部服务（空间服务、设备服务、License 服务）统一使用相同的响应包装格式：

```json
{ "code": 200, "success": true, "data": { ... }, "msg": "操作成功" }
```

- 成功判断：`code == 200 && success == true`
- 业务数据：`data` 字段
- 错误处理：`code != 200` 时，提取 `msg` 转换为 Open API 错误码返回

> 适配器层的统一解包类和解包策略（如定义 `InternalResponse<T>` 包装类、Feign Decoder 等）待后续细化。

---

## 9. 安全设计

### 9.1 凭证安全

| 凭证 | 存储方式 | 传输方式 | 校验方式 |
|------|----------|----------|----------|
| appSecret | BCrypt 哈希（cost factor ≥ 12） | HTTPS + Basic Auth | BCrypt.checkpw |
| API Key | BCrypt 哈希（cost factor ≥ 12） | HTTPS + Header | 先 SHA256 再 BCrypt，或直接 BCrypt |

> **说明：** API Key 长度 48 字符，BCrypt 最多处理 72 字节，无需截断。

### 9.2 API Key 缓存安全

- Redis 缓存 Key 不存储明文，使用 SHA256(api_key) 作为缓存 Key
- 缓存 Value 存储完整的 Key 信息（key_id、scope、expires_at 等）
- Key 吊销时立即删除对应缓存
- 缓存 TTL 与 Key 过期时间对齐；永不过期的 Key 缓存 TTL 为 5 分钟

### 9.3 限流

| 维度 | 策略 | 说明 |
|------|------|------|
| appId 维度 | 全局限流 | 防止单个租户过度消耗资源 |
| API Key 维度 | Key 级限流 | 防止单把 Key 被滥用 |
| IP 维度 | 全局 IP 限流 | 防暴力破解 |

使用 Sentinel 配置限流规则，或在网关层对 `/open-api/v1/**` 路径统一限流。

### 9.4 输入校验

- 所有外部输入（路径参数、Query 参数、请求体）在 Open API 层做基础校验（格式、长度、枚举值）
- 业务级校验（如设备是否存在、空间归属关系）由内部服务负责
- SQL 参数全部使用预编译语句，防止 SQL 注入

---

## 10. 错误处理

### 10.1 统一错误响应格式

```json
{
  "error": "ERROR_CODE",
  "details": "人类可读的错误描述",
  "request_id": "trace-id-xxx"
}
```

### 10.2 错误码定义

| HTTP 状态码 | 错误码 | 说明 |
|-------------|--------|------|
| 400 | `INVALID_REQUEST` | 请求参数不合法 |
| 400 | `INVALID_SCOPE` | scope 值不在枚举范围内 |
| 400 | `INVALID_SPACE` | space_id 对应的空间不存在 |
| 401 | `UNAUTHORIZED` | appId/appSecret 或 API Key 无效 |
| 401 | `KEY_EXPIRED` | API Key 已过期 |
| 403 | `FORBIDDEN` | scope 不允许当前操作 |
| 404 | `NOT_FOUND` | 资源不存在（key_id、device_id、space_id） |
| 409 | `CONFLICT` | 空间下仍有设备，无法删除 |
| 429 | `RATE_LIMITED` | 请求频率超限 |
| 500 | `INTERNAL_ERROR` | 服务端内部错误 |

### 10.3 内部服务异常处理

内部服务通过 OpenFeign 调用时可能抛出异常，Open API 需做兜底处理：

```java
@FeignClient(name = "device-service", fallbackFactory = DeviceServiceFallback.class)
public interface DeviceServiceClient { ... }

@Component
public class DeviceServiceFallback implements FallbackFactory<DeviceServiceClient> {

    @Override
    public DeviceServiceClient create(Throwable cause) {
        return new DeviceServiceClient() {
            @Override
            public DeviceDTO getDevice(String deviceId) {
                throw new OpenApiException(502, "UPSTREAM_ERROR",
                    "内部设备服务暂时不可用", cause);
            }
            // ... 其他方法
        };
    }
}
```

对客户端屏蔽内部错误细节，统一返回 Open API 层的错误格式。

---

## 11. 审计设计

### 11.1 审计日志记录内容

| 字段 | 说明 |
|------|------|
| app_id | 哪个集成方 |
| key_id | 使用了哪把 Key（密钥管理接口为 NULL） |
| http_method | 请求方法 |
| request_path | 请求路径 |
| response_status | 响应状态码 |
| client_ip | 客户端 IP |
| request_duration | 请求耗时（毫秒） |
| created_at | 时间 |

### 11.2 审计日志写入策略

- **推荐异步写入**：通过 RocketMQ 发送审计事件，由消费者批量写入数据库
- **避免影响主流程性能**：审计写入失败不应影响正常业务响应
- **日志保留策略**：建议保留 90 天，超期归档或删除

### 11.3 审计日志查询（内部运维）

审计日志仅供内部运维使用，不对外开放查询接口。运维人员可通过内部管理系统或直接查询数据库进行排查。

---

## 12. 部署方案

### 12.1 服务部署

| 项目 | 说明 |
|------|------|
| 服务名 | `open-api-service` |
| 注册中心 | Nacos |
| 实例数 | 初期 2 实例，支持水平扩展 |
| 端口 | 8080（或按团队规范） |
| 容器化 | Docker，与现有微服务一致 |

### 12.2 数据库

使用现有的 PostgreSQL 实例，创建独立数据库 `open_api`，使用默认 `public` Schema：

```
Host: 172.21.2.41
Port: 5432
Database: open_api
Username: root
```

> **建库语句（需人工执行一次）：**
> ```sql
> CREATE DATABASE open_api ENCODING 'UTF8';
> ```

建库后执行以下建表语句：

```sql
CREATE TABLE open_app (
    id              BIGSERIAL       PRIMARY KEY,
    app_id          VARCHAR(64)     NOT NULL UNIQUE,
    app_secret_hash VARCHAR(255)    NOT NULL,
    name            VARCHAR(128)    NOT NULL,
    description     VARCHAR(512)    DEFAULT NULL,
    status          VARCHAR(16)     NOT NULL DEFAULT 'active',
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_open_app_status ON open_app(status);

CREATE TABLE open_api_key (
    id              BIGSERIAL       PRIMARY KEY,
    app_id          BIGINT          NOT NULL REFERENCES open_app(id),
    key_id          VARCHAR(64)     NOT NULL UNIQUE,
    api_key_hash    VARCHAR(255)    NOT NULL,
    description     VARCHAR(256)    DEFAULT NULL,
    scope           VARCHAR(16)     NOT NULL,
    status          VARCHAR(16)     NOT NULL DEFAULT 'active',
    expires_at      TIMESTAMPTZ     DEFAULT NULL,
    last_used_at    TIMESTAMPTZ     DEFAULT NULL,
    internal_user_id BIGINT         DEFAULT 1,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    rotated_at      TIMESTAMPTZ     DEFAULT NULL
);

CREATE INDEX idx_open_api_key_app ON open_api_key(app_id);
CREATE INDEX idx_open_api_key_hash ON open_api_key(api_key_hash);
CREATE INDEX idx_open_api_key_status ON open_api_key(status);
CREATE INDEX idx_open_api_key_expires ON open_api_key(expires_at) WHERE expires_at IS NOT NULL;

CREATE TABLE open_api_audit_log (
    id              BIGSERIAL       PRIMARY KEY,
    app_id          BIGINT          NOT NULL,
    key_id          BIGINT          DEFAULT NULL,
    http_method     VARCHAR(8)      NOT NULL,
    request_path    VARCHAR(512)    NOT NULL,
    response_status SMALLINT        NOT NULL,
    client_ip       VARCHAR(64)     DEFAULT NULL,
    request_duration INTEGER        DEFAULT NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_log_app ON open_api_audit_log(app_id);
CREATE INDEX idx_audit_log_created ON open_api_audit_log(created_at);
```

### 12.3 Redis

```
Host: 172.22.3.13
Port: 6379
Password: hkt1234!QAZ
```

API Key 缓存使用独立前缀：

```
open_api:key:{sha256_of_api_key} → Key 信息 JSON（TTL 5min 或 Key 过期时间）
open_api:rate_limit:app:{app_id} → 限流计数
open_api:rate_limit:key:{key_id} → 限流计数
```

### 12.4 配置中心（Nacos）

```
Namespace: AI智能体开发
Group: DEFAULT_GROUP
Data ID: open-api-service.yml
```

```yaml
# open-api-service.yml（Nacos 配置）
server:
  port: 8080

spring:
  datasource:
    url: jdbc:postgresql://172.21.2.41:5432/open_api
    username: root
    password: 7qX#yL8vz!
    driver-class-name: org.postgresql.Driver
  data:
    redis:
      host: 172.22.3.13
      port: 6379
      password: hkt1234!QAZ

mybatis-plus:
  mapper-locations: classpath:mapper/*.xml
  configuration:
    map-underscore-to-camel-case: true

springdoc:
  api-docs:
    path: /v3/api-docs
  swagger-ui:
    path: /swagger-ui.html

open-api:
  security:
    bcrypt-cost: 12
    api-key-prefix: "ak_live_"
    api-key-length: 48
  cache:
    key-ttl-seconds: 300        # 永不过期 Key 的缓存 TTL
  rate-limit:
    app-qps: 100                # 每个 appId 每秒上限
    key-qps: 50                 # 每把 Key 每秒上限
  audit:
    async: true                 # 异步写入审计日志
  mapping:
    # 外部字段 → 内部字段映射（可热更新）
    device:
      location-to-space-id: true
```

---

## 13. AI 智能体兼容设计

### 13.1 场景说明

AI 智能体在创建用户时，需要同时创建 API Key，并将该 Key 与内部系统用户关联，以便后续通过设备服务调用时能以该用户身份操作。

### 13.2 当前实现方式

`open_api_key` 表预留了 `internal_user_id` 字段。**一期固定写死为 1**，后续根据实际需求再对接内部用户体系。

### 13.3 后续扩展

后续如需对接内部用户，有两种实现路径：

| 路径 | 说明 | 适用场景 |
|------|------|----------|
| **路径 A：扩展请求体** | POST /v1/api-keys 增加 `internal_user_id` 字段，仅允许特定 appId 使用 | AI 智能体与外部客户共用 Open API 接口 |
| **路径 B：内部接口** | AI 智能体直接调内部服务创建用户 + Key 关联，不经过 Open API | AI 智能体走内部通道，与外部客户物理隔离 |

后续根据实际情况选择其中一种路径实现。

---

## 14. 后续扩展

以下内容不在一期范围内，但设计时需预留扩展空间：

| 扩展项 | 说明 |
|--------|------|
| 沙箱环境 | 通过 API Key 前缀 `ak_sandbox_` 区分，路由到沙箱数据源 |
| Webhook | 设备状态变更、命令执行完成等事件主动推送给客户 |
| API 调用配额 | 按 appId 或 API Key 设置月度/日调用量上限 |
| IP 白名单 | 限制特定 appId 仅允许特定 IP 段访问 |
| 分页游标 | 大数据量列表接口支持 cursor-based 分页，替代 offset |
| 多租户空间隔离 | 支持跨 appId 的空间共享（如有业务需求） |
