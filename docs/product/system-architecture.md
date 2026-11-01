# 智慧畜牧系统架构说明（Smart Livestock System Architecture）

> 版本：v2.0　基线日期：2026-11-01（上一版 v1.0 / 2026-06-15）
> 信息来源：`smart-livestock-server/`（Spring Boot 后端）、`Mobile/mobile_app/`（Flutter 前端）源码与 Flyway 迁移脚本核实（v2.0 按 master 逐章对账刷新，对账明细见 `docs/reports/2026-11-01-product-docs-sync-audit.md`）
> 维护原则：本文档与代码同步演进，数字与结构均来自实际代码核查，非概述性描述。

---

## 目录

1. [总体架构概览](#1-总体架构概览)
2. [业务架构](#2-业务架构)
3. [功能架构](#3-功能架构)
4. [数据架构](#4-数据架构)
5. [集成架构](#5-集成架构)
6. [技术架构](#6-技术架构)
7. [附录](#7-附录)

---

## 1. 总体架构概览

### 1.1 系统定位

智慧畜牧系统是面向**牧场主**的牲畜管理 SaaS 平台，通过物联网设备（GPS 追踪器、瘤胃胶囊、加速度计、耳标）实现：

- **实时定位与电子围栏**守护
- **健康预警**（体温/瘤胃蠕动/发情/疫病）
- **行为分析**（活动量、运动距离）
- **商业化运营**（多级订阅、分润对账、API 开放能力）

系统以 **多租户（Multi-Tenant）** 形式提供，支持直营、经销商（Reseller）、企业、开发者四类租户。

### 1.2 系统全景图

```mermaid
graph TB
    subgraph 客户端
        APP["Flutter 移动端<br/>Android / iOS / Web"]
        PORTAL["开发者门户（App 内页面）"]
        OPEN["第三方系统<br/>Open API 调用方"]
        MON["sp-monitoring<br/>Prometheus/Grafana"]
    end

    subgraph "外部数据源"
        BLADE["hkt-blade-device 中台<br/>（地址经 Nacos 下发）"]
        TB["ThingsBoard<br/>LoRa NS"]
        MQTTB(("设备侧 MQTT/HTTP<br/>外部链路"))
    end

    subgraph "Spring Boot 后端 (DDD 洋葱架构)"
        API["REST API 层<br/>JWT / API Key 双认证 + SSE"]
        subgraph 限界上下文
            ID["Identity<br/>身份与租户"]
            RANCH["Ranch<br/>牧场与围栏"]
            IOT["IoT<br/>设备与遥测"]
            HEALTH["Health<br/>健康分析"]
            COM["Commerce<br/>商业计费"]
            ANA["Analytics<br/>统计与门户"]
            DG["Datagen<br/>数据合成与评估"]
            LIC["Licensing<br/>部署/试点授权"]
        end
        NACOS["NacosRemoteConfigLoader<br/>环境配置下发"]
        MQ["RocketMQ<br/>事件总线"]
    end

    subgraph 数据与基础设施
        PG[("PostgreSQL 16<br/>业务 + 时序分区")]
        REDIS[("Redis 7<br/>缓存/限流")]
        TILE["tileserver-gl<br/>离线瓦片"]
        MQBROKER(("RocketMQ Broker"))
    end

    APP --> API
    PORTAL --> API
    OPEN --> API
    MON -.-> API
    BLADE -->|"Feign 轮询"| IOT
    TB -->|"REST 直连"| IOT
    MQTTB -.->|HTTP push / 导入| IOT
    NACOS -.-> ID
    API --> ID & RANCH & IOT & HEALTH & COM & ANA & DG & LIC
    ID <--> MQ
    RANCH <--> MQ
    IOT <--> MQ
    HEALTH <--> MQ
    COM <--> MQ
    MQ <--> MQBROKER
    ID & RANCH & IOT & HEALTH & COM & ANA & DG & LIC --> PG
    API --> REDIS
    APP -.离线瓦片.-> TILE
```

### 1.3 技术栈总览

| 端 | 技术栈 | 版本 | 说明 |
|----|--------|------|------|
| **后端** | Spring Boot | 3.3.0 | Java 17，Gradle 构建 |
| **持久层** | Spring Data JPA + Hibernate | — | `ddl-auto: none`，结构由 Flyway 管理 |
| **数据库** | PostgreSQL | 16 | 含时序分区表 |
| **缓存** | Spring Data Redis | 7 | 限流 + 缓存 |
| **消息队列** | RocketMQ | 5.1.0（`rocketmq-spring-boot-starter:2.3.0`） | 跨上下文事件分发 |
| **数据库迁移** | Flyway | — | **117 个**迁移脚本（V1–V41 + 77 个 V2026xxxx 日期序，2026-11-01 核实） |
| **认证** | JJWT | 0.12.5 | 单 access token + 过期后 30min 刷新宽限（无独立 refresh token）+ 条件性 `act` 委托 claim（NIX-306） |
| **配置中心** | Nacos（自建 NacosRemoteConfigLoader） | — | blade 地址等环境配置启动期 HTTP 拉取（仅 dev/test；86/223 不启用） |
| **可观测性** | Spring Boot Actuator + Micrometer Prometheus | — | `/actuator/prometheus` 独立管理端口（dev 19081 / test 18081），接入 sp-monitoring |
| **空间计算** | JTS Topology Suite | 1.19.0 | 围栏多边形/缓冲区计算 |
| **安全** | Spring Security + BCrypt | — | 无状态 Session |
| **移动端** | Flutter | SDK ≥3.3.0 | Riverpod + Go Router |
| **开发者门户** | Vue 3 + Vite | — | API Consumer 使用 |
| **PC 端** | Angular 19 | — | 归档，不随主流程迭代 |
| **离线地图** | tileserver-gl | latest | MBTiles 瓦片服务 |
| **部署** | Docker Compose | — | 4 环境（dev :19080 / test :18080 / 86 HOSTED / 223 ONPREM） |

### 1.4 架构设计原则

1. **领域驱动设计（DDD）**：按业务能力划分 9 个上下文（7 业务限界上下文 + Platform 支撑 + Shared 共享内核），每个上下文采用洋葱（分层）架构。
2. **事件驱动解耦**：上下文之间通过 RocketMQ 发布/订阅领域事件，避免直接代码级耦合。
3. **防腐层（ACL）隔离**：跨上下文查询通过 Port/Adapter 端口适配器，不直接引用对方领域模型。
4. **多租户隔离**：基于 JWT 解析的 `tenantId`，通过 `ThreadLocal` 在请求生命周期内传递。
5. **优雅降级**：RocketMQ 不可用时事件发布静默跳过，保证应用可启动与测试可执行。
6. **配置外置**：数据库、Redis、JWT、模拟器等均通过环境变量注入，提供合理默认值。

---

## 2. 业务架构

### 2.1 业务领域与核心价值

```
智慧畜牧平台
├── 牲畜数字孪生      一畜一档，实时位置 + 健康画像
├── 围栏守护          电子围栏 + 缓冲区预警，越界即时告警
├── 健康监测          体温/蠕动/发情/活动多维分析，提前发现异常
├── 设备全生命周期    注册→激活→安装→退役，License 管理
└── 商业化运营        多级订阅、功能门控、分润对账、API 开放
```

### 2.2 利益相关者与角色体系

系统内置 **6 种角色**，角色决定前端 Shell 形态与可访问功能：

| 角色 | 定位 | 权限范围 | 移动端 Shell |
|------|------|---------|-------------|
| `SUPER_ADMIN` | 超管 root（NIX-306） | 经 `/select-context` 选择身份进入，act token 委托 + `AUTH_CONTEXT_SWITCHED` 审计 | 随所选角色 |
| `PLATFORM_ADMIN` | 平台管理员 | 租户/用户/合同/分润/订阅服务/API Key 全量管理 | 纯 Scaffold |
| `B2B_ADMIN` | B 端经销商 | 概览 + 牧场管理 + 合同 + 对账 + 牧工管理 | NavigationRail |
| `OWNER` | 牧场主 | 全部业务页面 + 牧工 + 订阅管理（后台管理入口已移除） | 底部导航栏 |
| `WORKER` | 牧工 | 看板/地图/告警/我的/围栏，已读 + 关闭（dismiss）告警 | 底部导航栏 |
| `API_CONSUMER` | 开发者 | 通过 API Key 访问 Open API | — |

租户（Tenant）的生命周期、演进阶段与业务类型：

- **生命周期**（V20261012140000，2026-10-14 裁决）：`status` = `active | disabled`（可逆启停，登录/API 网关）+ `deleted_at` 软删除（可恢复）；业务数据永不物理删除
- **阶段**：`SAMPLE`（试点）→ `BATCH`（批量）
- **类型**：`rancher`（牧场主）、`reseller`（经销商）、`enterprise`（企业）、`developer`（开发者）

### 2.3 核心业务流程

#### 流程一：实时定位与围栏守护

```mermaid
sequenceDiagram
    participant DEV as IoT 设备
    participant IOT as IoT 上下文
    participant MQ as RocketMQ
    participant RANCH as Ranch 上下文
    participant DB as PostgreSQL
    participant APP as 移动端

    DEV->>IOT: 上报 GPS / 遥测数据（多源：blade 轮询 / TB 直连 / HTTP push / 手动导入）
    IOT->>DB: ingest 主事务只写 gps_ingestion_tasks（outbox）
    IOT->>DB: GpsIngestionTaskScheduler 异步写 gps_logs（幂等键 device_id+recorded_at）
    IOT->>MQ: 发布 gps-log-updated
    MQ->>RANCH: GpsLogEventConsumer 消费
    RANCH->>RANCH: FenceBreachDetector 检测越界
    alt 越界 / 接近缓冲区
        RANCH->>DB: 创建 Alert（FENCE_BREACH）
        RANCH->>MQ: 发布 fence-breach-detected
    end
    RANCH->>DB: 更新 livestock.last_position
    APP->>RANCH: 拉取 alerts + 地图概览
```

**围栏检测算法**（`FenceBreachDetector`）：
- **Safe**：点在围栏内且在缓冲区外
- **Approaching**：点在缓冲区环带内（接近边界预警）
- **Breach**：点在围栏外（越界告警）

缓冲区通过 `buffer_distance`（默认 50m）+ `buffer_polygon`（预计算）实现。

#### 流程二：健康监测与预警

```mermaid
flowchart LR
    SRC["多源遥测<br/>blade 轮询 / TB 直连 / HTTP / datagen / 手动导入"] -->|"TelemetrySource 5 值"| INGEST["TelemetryIngestionService"]
    INGEST -->|"telemetry-received 事件"| MQ{{RocketMQ}}
    MQ --> CONSUMER["TelemetryEventConsumer"]
    CONSUMER --> TL["temperature_logs<br/>rumen_motility_logs<br/>activity_logs"]
    TL --> FA["FeverAnalysisService"]
    TL --> EA["EstrusAnalysisService"]
    TL --> DA["DigestiveAnalysisService"]
    TL --> EP["EpidemicAnalysisService"]
    FA & EA & DA & EP --> HS["health_snapshots<br/>estrus_scores"]
    FA -.异常.-> ALERT["创建告警"]
```

**发热检测规则**（`FeverAnalysisService`，基于实际代码阈值）：

| 条件 | 判定状态 |
|------|---------|
| `delta < 1.0°C` | NORMAL |
| `1.0 ≤ delta < 1.5°C`（持续 < 2h） | ELEVATED |
| `delta ≥ 1.5°C` 或持续 > 2h | FEVER |
| `delta ≥ 2.0°C` 或 `temp ≥ 41.0°C` | CRITICAL |

> `delta` 为生成列（`temperature - baseline_temp`），基线体温默认 38.50°C。

#### 流程三：商业化运营（订阅 → 配额 → 功能门控）

```mermaid
flowchart TD
    SIGN["签订 Contract<br/>billing_model + tier"] --> SUB["创建/升级 Subscription"]
    SUB --> GATE["FeatureGate 引擎<br/>tier × feature_key"]
    GATE -->|"gate_type"| NONE["none: 无限制"]
    GATE --> LOCK["lock: 开关门控"]
    GATE --> LIMIT["limit: 数量上限"]
    GATE --> FILTER["filter: 数据范围/保留期"]
    REQ["业务请求"] --> QI["QuotaInterceptor 拦截"]
    QI -->|"@QuotaCheck 注解"| CHK["QuotaCheckService 校验"]
    CHK --> RES["UsageResolver 计算用量"]
    CHK -->|"超限"| REJ[403 配额不足]
    CHK -->|"通过"| OK[放行]
```

### 2.4 商业模型

**4 种计费模式**（`billing_model`）：

| 模式 | 说明 |
|------|------|
| `direct` | 直营直接计费 |
| `revenue_share` | 分润模式（经销商），按 `revenue_share_ratio` 分配 |
| `licensed` | 买断授权 |
| `api_usage` | 按 API 用量计费 |

**4 级套餐**（`tier`）与功能门控矩阵（初始 7 个 feature key 来自 `V11__seed_commerce_data`；后随 `V20260923120000` USD 定价门、`V20261005110000` 饮水同群对照门、`V20261026000000` 遥测导出门演进，下表为初版口径，逐格值以迁移种子为准）：

| Feature Key | basic | standard | premium | enterprise |
|-------------|:-----:|:--------:|:-------:|:----------:|
| livestock_management | limit(50) | limit(200) | limit(1000) | 无限 |
| fence_management | limit(5) | limit(20) | limit(100) | 无限 |
| alert_management | ❌ lock | ✅ | ✅ | ✅ |
| advanced_analytics | ❌ lock | filter(30天) | ✅ | ✅ |
| api_access | ❌ lock | ❌ lock | ✅ | ✅ |
| worker_management | limit(3) | limit(10) | limit(50) | 无限 |
| health_monitoring | ❌ lock | ✅ | ✅ | ✅ |

> 门控类型：`none`（无限制）、`lock`（布尔开关）、`limit`（数量上限）、`filter`（数据范围/保留天数）。

**分润对账**：`revenue_periods` 按 `合同 × 周期` 记录流水，状态流转：`pending → platform_confirmed → partner_confirmed → settled`。

**订阅生命周期**（NIX-323/324/325，2026-10）：`SubscriptionStatus` 7 态（TRIAL/ACTIVE/FREE/SUSPENDED/RENEWAL_FAILED/CANCELLED/EXPIRED），`CommerceScheduler` 统一调度（expireTrials / markExpiredSubscriptions 每小时、downgradeAfterRenewalFailure 每日 2:00）；免费试点**统一截止日 2027-09-30**（可按租户时区换算）；到期降档不拒绝（Open 遥测窗口 clamp + 24h 调用预算）；终止后 30 天 GDPR 自助导出权 + 导出文件 30 天下载窗。

---

## 3. 功能架构

### 3.1 限界上下文全景

```mermaid
graph LR
    ID[Identity<br/>身份与租户]
    RANCH[Ranch<br/>牧场与围栏]
    IOT[IoT<br/>设备与遥测]
    HEALTH[Health<br/>健康分析]
    COM[Commerce<br/>商业计费]
    ANA[Analytics<br/>统计与门户]
    DG[Datagen<br/>数据合成与评估]
    LIC[Licensing<br/>部署/试点授权]
    SHARED[Shared<br/>公共基础设施]
    PLATFORM[Platform<br/>通知与配额]

    ID --- RANCH
    RANCH --- IOT
    IOT --- HEALTH
    HEALTH --- RANCH
    COM --- ID
    ANA --- ID
    DG --- IOT & HEALTH & RANCH
    LIC --- ID

    SHARED -.支撑.-> ID & RANCH & IOT & HEALTH & COM & ANA & DG & LIC
    PLATFORM -.支撑.-> COM
```

### 3.2 各上下文功能职责

| 上下文 | 职责 | Controller 数 | 核心能力 |
|--------|------|:---:|---------|
| **Identity** | 多租户隔离、用户、角色权限（6 角色）、认证授权（多标识登录 + 超管上下文）、牧场归属、审计日志、GDPR 数据导出 | 14 | 登录（account/email/phone）/上下文切换/刷新、租户管理、用户管理、API Key、审计日志、数据导出（NIX-325） |
| **Ranch** | 牲畜、围栏、告警（工作台）、仪表盘、地图、离线瓦片、SSE 信号流 | 16 | 牲畜 CRUD、围栏管理（含缓冲区/GPX 导入）、告警 dismiss 模型 + 工作台分桶、瓦片下载、SignalController |
| **IoT** | 设备全生命周期、License、安装、多源遥测接入（blade/TB/HTTP/导入）、GPS outbox、网关、移交 | 21 | 设备注册/激活/退役、跨租户移交、TB 直连（NIX-179/180/214）、遥测接入、GPS outbox、网关定位/覆盖诊断、Open API |
| **Health** | 体温/蠕动/发情/疫病/活动/饮水多维分析 + AI 异常 | 13 | 发热检测、消化分析、发情评分、疫病工作台、饮水事件检测与标注（NIX-256）、生理事件流、AI 异常分数（V40） |
| **Commerce** | 订阅（7 态）、合同、分润、Tier 配额、功能门控 | 8 | 订阅结算、合同签约、分润对账、配额校验、CommerceScheduler 生命周期调度 |
| **Analytics** | API 用量统计、调用日志、开发者门户 | 4 | 用量概览/趋势、调用日志查询、门户 API |
| **Datagen** | 合成数据、GroundTruth 标签、评估、Phase C 行为数据集 | 3 | Scenario 驱动合成、行为数据集/训练/评估、饮水标注导出 |
| **Licensing** | 部署 license（NIX-184）、托管试点授权 | 3 | 部署授权发放/校验、免费试点发放（统一截止日） |
| **Shared** | 认证、安全、多租户、限流、缓存、异常处理、事件发布、密码策略、Nacos 配置加载 | 2 | JWT/API Key 认证、CORS、Rate Limit、统一响应包络、PasswordPolicy、NacosRemoteConfigLoader |
| **Platform** | 通知中心、配额拦截、分区维护 | — | 通知服务、事件聚合消费、配额拦截器、PartitionMaintenanceService |

> 全仓合计 **84 个 @RestController 类（83 个业务控制器 + 1 全局异常处理）/ 329 端点**（App 158 / Admin 147 / Open 17 / Portal 7，2026-11-01 机械计数）。

### 3.3 前后端功能矩阵

> 模块级概览（原 `system-feature-document.md` 已删除；端点级对接状态以 `docs/api-contracts/` 为准）。

| 上下文 | 后端状态 | 移动端对接 | 备注 |
|--------|:---:|:---:|------|
| Identity（登录/用户/租户/API Key） | ✅ | ✅ | Token 自动刷新已实现（`_withRefreshRetry`） |
| Ranch（牲畜/围栏/告警/仪表盘/地图/SSE） | ✅ | ✅ | 围栏 force 更新、瓦片 Admin 前端缺失 |
| IoT（设备/安装/GPS/TB 开通） | ✅ | ✅ | 设备安装/解绑与 TB 开通向导（TbDeviceWizardSheet）已对接 |
| Health（体温/发情/消化/疫病/饮水/AI） | ✅ | ✅ | 饮水事件/生理事件流/AI 异常已并入详情与健康页 |
| Commerce（订阅/合同/分润） | ✅ | ✅ | B2B 管理 + 订阅管理 + 到期横幅/导出权卡已对接 |
| Analytics（用量/门户） | ✅ | 部分 | 分析事件上报前端调用情况未复核 |

### 3.4 移动端功能模块

移动端采用 **Feature-First** 组织，`lib/features/` 下 **34 个功能模块**（2026-11-01 计数）：

```
lib/
├── app/                      # 路由、Session、Shell（角色化导航）
│   ├── app_route.dart        # AppRoute 枚举 — 57 项单一来源（61 条 GoRoute）
│   ├── app_router.dart       # GoRouter + 认证重定向守卫（含 /select-context）
│   └── session/              # AppSession + SessionController
├── core/                     # 跨功能基础设施
│   ├── api/                  # ApiClient 单例（JWT + farm-scoped CRUD）
│   ├── models/               # 共享数据模型 + ViewState（含 6 角色 UserRole）
│   ├── map/                  # flutter_map 封装
│   ├── database/             # 本地离线缓存
│   └── l10n/                 # 国际化
├── features/                 # 按业务划分（34 目录）
│   ├── auth, ranch, fence, livestock, alerts
│   ├── dashboard, mine, stats, devices, gateways
│   ├── fever_warning, estrus, digestive, epidemic, drinking, physiology, ai_anomaly
│   ├── subscription, subscription_service_management, contract_management, revenue
│   ├── b2b_admin, admin, worker_management, tenant
│   ├── farm_creation, farm_switcher
│   ├── offline_tiles, offline_fences, offline_livestock
│   └── api_authorization, twin_overview, highfi, pages, ...
└── widgets/                  # 通用组件
```

**Feature 内部分层**（渐进式）：
- `data/` — API Repository 实现，调用 `ApiClient`
- `domain/` — 领域模型（部分模块采用）
- `presentation/` — Riverpod Controller + Widget

**状态管理**：`flutter_riverpod` 独占，`Provider`（只读依赖）+ `NotifierProvider`（可变状态），无 `setState`/`ChangeNotifier`。

---

## 4. 数据架构

### 4.1 存储技术选型

| 数据类型 | 存储 | 说明 |
|---------|------|------|
| 业务实体（租户/牧场/牲畜/设备/订阅…） | PostgreSQL 16 | 关系型，强一致性 |
| 时序遥测数据（体温/蠕动/活动/GPS） | PostgreSQL **分区表** | 按月 RANGE 分区，见 4.3 |
| 空间围栏数据 | PostgreSQL JSONB + JTS | 顶点存 JSONB，计算用 JTS |
| 配额/限流计数 | Redis 7 | Lua 脚本滑动窗口 |
| 通知/消息 | PostgreSQL + RocketMQ | 持久化通知 + 事件分发 |
| 离线瓦片 | MBTiles 文件 | tileserver-gl 提供 |

### 4.2 核心数据模型

#### Identity 上下文

```mermaid
erDiagram
    tenants ||--o{ farms : owns
    tenants ||--o{ users : has
    tenants ||--o{ api_keys : issues
    farms ||--o{ user_farm_assignments : has
    users ||--o{ user_farm_assignments : assigned

    tenants {
        bigint id PK
        string name
        string phase "SAMPLE|BATCH"
        string type "rancher|reseller|enterprise|developer"
        string billing_model
        string status "active|disabled（V20261012140000）"
        timestamptz deleted_at "软删除"
        string timezone "NULL=继承（V20261012110000）"
    }
    farms {
        bigint id PK
        bigint tenant_id FK
        string name
        decimal latitude
        decimal longitude
        timestamptz deleted_at "软删除"
    }
    users {
        bigint id PK
        string account "登录标识之一"
        string email
        string phone "E.164"
        string password_hash
        string role "6种角色"
        boolean must_change_password
        bigint tenant_id FK
        boolean is_active
    }
    user_farm_assignments {
        bigint id PK
        bigint user_id FK
        bigint farm_id FK
        string role "OWNER|WORKER"
    }
    api_keys {
        bigint id PK
        bigint tenant_id FK
        string key_hash UK
        string scopes
        int requests_per_minute
        int daily_quota
    }
```

> **v2.0 增补**：多标识登录（PR #132）——account / email / phone(E.164) 任一 + 密码，大小写不敏感；`must_change_password` 强制改密锁（NIX-191）；`SUPER_ADMIN` 第 6 角色（V20261019100000）；`tenants`/`farms` `timezone` 时区三级链（`TenantZoneResolver`：牧场→租户→平台默认，存储恒 UTC）。

#### Ranch 上下文

```mermaid
erDiagram
    farms ||--o{ livestock : contains
    farms ||--o{ fences : has
    farms ||--o{ alerts : generates
    fences ||--o{ fence_zones : has
    alerts ||--o{ alert_read_status : tracked
    fences {
        bigint id PK
        bigint farm_id FK
        jsonb vertices "围栏顶点"
        jsonb buffer_polygon "缓冲区"
        int buffer_distance "默认50"
        int version "乐观锁"
        string fence_type "sub|..."
    }
    livestock {
        bigint id PK
        bigint farm_id FK
        string livestock_code
        string health_status "HEALTHY|WARNING|CRITICAL"
        decimal last_latitude
        decimal last_longitude
        timestamptz deleted_at
    }
    alerts {
        bigint id PK
        bigint farm_id FK
        bigint livestock_id FK
        string type "FENCE_BREACH|TEMPERATURE_ABNORMAL|..."
        string status "ACTIVE|DISMISSED|AUTO_RESOLVED"
        string severity "INFO|WARNING|CRITICAL"
    }
```

#### IoT 上下文（跨上下文引用）

```mermaid
erDiagram
    devices ||--o| device_licenses : "1:1 active"
    devices ||--o{ installations : installed
    devices ||--o{ gps_logs : reports
    installations }o--|| livestock : "引用(无FK)"

    devices {
        bigint id PK
        bigint tenant_id FK
        string device_code UK
        string device_type "EAR_TAG|TRACKER|CAPSULE"
        string status "INVENTORY|ACTIVE|DECOMMISSIONED"
        string dev_eui "全球唯一索引"
        string blade_device_id "blade 侧 ID"
        int rssi
    }
    tb_device_bindings {
        bigint id PK
        bigint device_id FK
        string tb_device_id
        string status "PENDING|RESOLVED|INVALID"
    }
    gps_ingestion_tasks {
        bigint id PK
        bigint device_id
        timestamp recorded_at "幂等键 device_id+recorded_at"
    }
    installations {
        bigint id PK
        bigint device_id FK
        bigint livestock_id "跨上下文,无FK"
        timestamptz installed_at
        timestamptz removed_at
    }
    gps_logs {
        bigint id PK
        bigint device_id FK
        decimal latitude
        decimal longitude
        string source "TelemetrySource"
        timestamp recorded_at "分区键"
    }
```

> **v2.0 更正**：`status` 无 `OFFLINE`——在线/离线为运行时 `runtimeStatus` 计算值（`DeviceStatus.java`）；`ACCELEROMETER` 类型已移除（V25）；`dev_eui` 全球唯一索引（2026-10-12，跨租户预检 + `POST /admin/devices/transfer` 移交）；GPS 写入走 outbox；设备扩展字段（blade_device_id/rssi/snr/anti_disassembly_status 等）见 V20260709120000。

#### Health 上下文（时序分区）

```mermaid
erDiagram
    livestock ||--o{ temperature_logs : monitored
    livestock ||--o{ rumen_motility_logs : monitored
    livestock ||--o{ activity_logs : monitored
    livestock ||--o| health_snapshots : "1:1 当前状态"
    farms ||--o{ estrus_scores : has
    farms ||--o{ contact_traces : records

    temperature_logs {
        bigint id PK
        bigint livestock_id
        decimal temperature
        decimal delta "生成列"
        timestamp recorded_at "分区键"
    }
    health_snapshots {
        bigint id PK
        bigint livestock_id UK
        bigint farm_id FK
        string temp_status "NORMAL|ELEVATED|FEVER|CRITICAL"
        string motility_status
        int estrus_score
    }
```

> **v2.0 增补**：`device_telemetry_logs`（设备运维指标月分区，V20260709120000）、`drinking_events`（饮水事件 + 人工标注 label/confidence，V20261005100000）、`physiology_events`（人工生理事件流，V20261004120000）、`anomaly_scores`（规则 + AI 双轨异常分月分区，V40）。

#### Commerce 上下文

```mermaid
erDiagram
    tenants ||--o| subscriptions : "1:1"
    tenants ||--o{ contracts : signs
    contracts ||--o{ revenue_periods : settles
    tenants ||--o{ subscription_services : "1:1"

    subscriptions {
        bigint id PK
        bigint tenant_id UK
        string tier "basic|standard|premium|enterprise"
        string billing_model
        string status "TRIAL|ACTIVE|FREE|SUSPENDED|RENEWAL_FAILED|CANCELLED|EXPIRED"
        bigint version "乐观锁"
    }
    contracts {
        bigint id PK
        string contract_number UK
        bigint tenant_id FK
        decimal revenue_share_ratio
        string status "draft|active|suspended|expired|terminated"
    }
    feature_gates {
        bigint id PK
        string tier
        string feature_key
        string gate_type "none|lock|limit|filter"
        int limit_value
        int retention_days
    }
```

### 4.3 时序数据分区策略

六张核心时序表采用 PostgreSQL **声明式 RANGE 分区**（按月）：

| 表 | 分区键 | 数据源 | 索引策略 |
|----|--------|---------|-----------|
| `gps_logs` | `recorded_at` | GPS 上报（outbox 异步写入） | `(livestock_id, recorded_at DESC)` |
| `temperature_logs` | `recorded_at` | CAPSULE（~30min） | `(livestock_id, recorded_at DESC)` + 部分索引 `WHERE delta > 1.0` |
| `rumen_motility_logs` | `recorded_at` | CAPSULE（~30min） | `(livestock_id, recorded_at DESC)` |
| `activity_logs` | `recorded_at` | TRACKER | `(livestock_id, recorded_at DESC)` |
| `device_telemetry_logs` | `recorded_at` | blade/TB 设备运维快照 | 按 recorded_at 分区（V20260709120000） |
| `anomaly_scores` | 月分区 | 规则 + AI 双轨异常分 | V40 |

分区设计要点：
- 分区由 `PartitionMaintenanceService`（platform 上下文）**自动创建/维护，禁止手工预建分区**
- 主键包含分区键：`PRIMARY KEY (id, recorded_at)`
- `temperature_logs.delta` 为 `GENERATED ALWAYS AS (temperature - baseline_temp) STORED` 生成列，免维护

### 4.4 跨上下文数据一致性

**关键设计：跨限界上下文的引用不使用外键约束，由应用层保证一致性。**

典型场景 — `installations.livestock_id`：
```sql
-- V3 注释原文：
-- NOTE: livestock_id is a cross-context reference (Ranch Context) with NO FK constraint.
-- Data consistency is enforced at the application layer only.
```

GPS 位置到牲畜的 JOIN 路径：
```
gps_logs → devices → installations (WHERE removed_at IS NULL) → livestock
```

一致性保障机制：
1. **应用层校验**：写操作时通过 ACL Port 查询关联实体是否存在
2. **唯一性约束**：`installations` 上 `CREATE UNIQUE INDEX ... WHERE removed_at IS NULL`（一台设备仅一个活跃安装）
3. **事件驱动同步**：上下文状态变更通过 RocketMQ 事件广播

### 4.5 数据治理

| 机制 | 实现 | 示例 |
|------|------|------|
| **软删除** | `deleted_at TIMESTAMPTZ` + 部分唯一索引 | `farms`, `livestock`, `devices` |
| **乐观锁** | `version BIGINT` 列 | `subscriptions`, `contracts`, `revenue_periods` |
| **审计日志** | `audit_logs` 表（V18） | 全操作可追溯 |
| **API 调用日志** | `api_call_logs`（逐请求）+ `api_usage_daily`（日聚合） | V22 |
| **告警已读追踪** | `alert_read_status`（用户×告警） | V26 |
| **枚举约束** | `CHECK` 约束 | 所有状态/类型字段 |
| **部分索引** | 条件索引优化查询 | `WHERE deleted_at IS NULL`、`WHERE score >= 70` |
| **GDPR 数据导出** | `data_export_jobs`（机器可读 zip；终止后 30 天导出权 + 文件 30 天下载窗） | NIX-325 |
| **GPS 写入幂等** | outbox 幂等键 `(device_id, recorded_at)` | `gps_ingestion_tasks` |
| **租户时区** | `tenants/farms.timezone` 三级链（`TenantZoneResolver`，存储恒 UTC） | V20261012110000 |

### 4.6 数据库表清单

| 迁移版本 | 上下文 | 表 |
|---------|--------|-----|
| V1 | Identity | tenants, farms, users, user_farm_assignments, api_keys |
| V2 | Ranch | livestock, fences, alerts |
| V3 | IoT | devices, device_licenses, installations, gps_logs |
| V6 | Commerce | subscriptions, contracts, revenue_periods, subscription_services, feature_gates, notifications |
| V13 | Ranch | tile_regions, tile_generation_tasks, farm_tile_tasks, tile_download_logs（+ fences 扩展 version/fence_type） |
| V18 | Shared | audit_logs |
| V20 | Health | temperature_logs, rumen_motility_logs, activity_logs, estrus_scores, health_snapshots, contact_traces |
| V22 | Analytics | api_call_logs, api_usage_daily（+ api_keys 扩展 scopes/quota） |
| V26 | Ranch | alert_read_status, fence_zones（+ fences 扩展 buffer, alerts 状态迁移） |
| V38–V41 | Datagen/AI | synthesis_scenarios, ground_truth_labels（+ AI 异常集成 anomaly_scores V40） |
| V2026xxxx（77 个，日期序） | 全上下文 | 要点：V20260709120000 设备扩展（blade/健康评分）、V20260828110000 tb_device_bindings、V20260905100000 告警工作台、V20260907120000 admin bootstrap、V20260918100000 gateway_registry/数据治理、V20261004120000 physiology_events、V20261005100000 drinking_events、V20261012110000 timezone、V20261012140000 tenant_lifecycle、V20261019100000 super_admin、订阅生命周期与导出系列（NIX-323/324/325） |

> V4–V12、V15–V17、V19、V21、V23–V25、V27–V37 为种子数据与修复脚本；合计 **117 个迁移**（V1–V41 + 77 个 V2026xxxx 日期序，2026-11-01 核实）。

---

## 5. 集成架构

### 5.1 事件驱动总线

系统通过 **RocketMQ** 实现限界上下文之间的异步解耦，事件中心注册在 `Topics.java`。

#### 事件 Topic 生态

```mermaid
graph LR
    subgraph 发布方
        IOTPUB[IoT 上下文]
        RANCHPUB[Ranch 上下文]
        IDPUB[Identity 上下文]
        COMPUB[Commerce 上下文]
    end

    subgraph "RocketMQ Topics（17 个）"
        T1[gps-log-updated]
        T2[device-activated]
        T3[license-expired]
        T4[telemetry-received]
        T5[fence-breach-detected]
        T6[alert-status-changed]
        T7[tenant-phase-changed]
        T8[subscription-created]
        T9[contract-signed]
        T10[service-degraded/revoked/quota-adjusted]
        T11[device-telemetry-sync]
        T12[subscription-tier-changed/suspended<br/>reactivated/expired]
    end

    subgraph 消费方
        CONSUMER1["Ranch: GpsLogEventConsumer<br/>ranch-gps-consumer"]
        CONSUMER2["Health: TelemetryEventConsumer<br/>health-telemetry-consumer"]
        CONSUMER3["Platform: PlatformEventConsumer<br/>platform-notification-consumer"]
    end

    IOTPUB --> T1 & T2 & T3 & T4 & T11
    RANCHPUB --> T5 & T6
    IDPUB --> T7
    COMPUB --> T8 & T9 & T10 & T12

    T1 --> CONSUMER1
    T4 --> CONSUMER2
    T2 & T5 & T6 & T7 & T8 & T9 & T10 & T11 & T12 --> CONSUMER3
```

| Topic | 发布方 | 消费方 | 业务作用 |
|-------|--------|--------|---------|
| `gps-log-updated` | IoT | Ranch | 触发围栏越界检测 + 更新牲畜位置 |
| `telemetry-received` | IoT | Health | 触发体温/蠕动/活动分析 |
| `device-telemetry-sync` | IoT | Platform | 设备遥测同步（blade/TB 通道） |
| `device-activated` / `license-expired` | IoT | Platform | 设备激活通知 / License 到期 |
| `fence-breach-detected` | Ranch | Platform | 围栏越界事件 |
| `alert-status-changed` | Ranch | Platform | 告警状态流转 |
| `tenant-phase-changed` | Identity | Platform | 租户阶段变化 |
| `subscription-created/tier-changed/suspended/reactivated/expired` | Commerce | Platform | 订阅生命周期事件 |
| `contract-signed` / `service-degraded/revoked/quota-adjusted` | Commerce | Platform | 合同签署 / 订阅服务变化 |

> `Topics.java` 现注册 **17 个 topic**；跨域事件统一由 `PlatformEventConsumer` 聚合消费（写入 `notifications` 表 / 审计），不再只是"预留"。

**事件基础设施**：
- 所有领域事件继承 `DomainEvent`（含 `eventId` UUID + `occurredAt`）
- `RocketMQEventPublisher` 统一发布，**优雅降级**：RocketMQ 不可用时静默跳过，不阻断主流程
- 消费者使用 `@RocketMQMessageListener` 注解，独立 `consumerGroup` 隔离

### 5.2 ACL 防腐层（端口/适配器）

限界上下文之间**禁止直接引用对方领域模型**，一律通过 Port（接口）+ Adapter（实现）隔离。

```mermaid
graph TD
    ID[Identity]
    RANCH[Ranch]
    IOT[IoT]
    HEALTH[Health]
    COM[Commerce]
    ANA[Analytics]

    ID -->|"CommerceQueryPort"| COM
    ID -->|"IoTQueryPort"| IOT
    ID -->|"RanchQueryPort<br/>RanchCommandPort"| RANCH
    RANCH -->|"IdentityQueryPort"| ID
    RANCH -->|"IoTQueryPort"| IOT
    HEALTH -->|"RanchQueryPort<br/>RanchCommandPort"| RANCH
    COM -->|"RanchQueryPort"| RANCH
    ANA -->|"IdentityQueryPort"| ID
    IOT -->|"IdentityQueryPort"| ID
    IOT -->|"RanchQueryPort"| RANCH
```

ACL 实现清单（`infrastructure/acl/` 下）：

| 消费方上下文 | 提供方上下文 | Port | 用途 |
|------------|------------|------|------|
| Identity | Commerce | CommerceQueryPort | B2B 查询订阅/合同信息 |
| Identity | IoT | IoTQueryPort | 查询设备/安装信息 |
| Identity | Ranch | RanchQueryPort / RanchCommandPort | 牧场归属、牲畜引用 |
| Ranch | Identity | IdentityQueryPort | 用户/租户信息 |
| Ranch | IoT | IoTQueryPort | GPS 数据、设备状态 |
| Health | Ranch | RanchQueryPort / RanchCommandPort | 牲畜信息、回写健康状态 |
| Commerce | Ranch | RanchQueryPort | 计算用量（牲畜/围栏数） |
| Analytics | Identity | IdentityQueryPort | 用量统计关联租户 |
| IoT | Identity | IdentityQueryPort | 租户归属 |
| IoT | Ranch | RanchQueryPort | 牲畜/牧场关联 |

### 5.3 外部系统与第三方集成

| 外部系统 | 集成方式 | 用途 |
|---------|---------|------|
| **hkt-blade-device 中台** | OAuth2（grant_type=openapi）+ Feign 轮询 `report-record/page` | 真实设备数据主通道（`AGENTIC_PLATFORM`）；地址经自建 Nacos 下发（dev→SIT / test→客户试用） |
| **ThingsBoard** | REST 直连（`TbTelemetryChannel`，NIX-179） | 第二真实通道（`THINGSBOARD`）；绑定 `tb_device_bindings`；开通四能力 + profile 白名单（NIX-214） |
| **IoT 设备（HTTP push）** | `TelemetryController`（`HTTP` 来源） | 第三方直推遥测 |
| **IoT 设备（手动导入）** | `TelemetryImportAdminController`（NIX-79，`MANUAL_IMPORT`） | 历史数据回填（GPX/RTK XLSX） |
| **tileserver-gl** | HTTP（挂载 MBTiles 卷） | 离线地图瓦片服务，移动端按需下载 |
| **第三方业务系统** | Open API（`/api/v1/open/**`，API Key 认证，8 控制器 17 端点） | 查询/注册/导出（见下） |
| **datagen / Simulator** | ACL 写入 / 内置开关 | 合成数据（研发用）与开发演示 |

**Open API 能力**（API Key 认证，独立于 JWT，资源须归属 path farm——NIX-333）：
- 牲畜 / 围栏 / 告警 / 设备 / GPS 只读（`OpenLivestock/Fence/Alert/Device/GpsController`）
- 遥测历史与导出（`OpenTelemetryController`：窗口 clamp + 24h 调用预算，NIX-323）
- 设备自注册（`OpenDeviceRegisterController`，`device:register` scope，写端点）
- GDPR 数据导出（`OpenDataExportController`，NIX-325）

### 5.4 客户端集成

**移动端 ↔ 后端**：
- 协议：REST + JSON，统一响应包络 `{ code, message, requestId, data }`
- 认证：JWT Bearer Token（单 access token + 过期后 30 分钟刷新宽限，无独立 refresh token）
- 作用域：`ApiClient.setActiveFarmId()` 自动注入 `/farms/{farmId}` 前缀
- 容错：401 自动触发 Token 刷新 + 重试（`_withRefreshRetry`）
- 实时：SSE 信号流（`POST /signals/stream-ticket` → `GET /signals/stream`，`SignalEventType` 10 值）
- 离线：本地 SQLite 缓存牲畜位置、围栏数据，支持离线查看

---

## 6. 技术架构

### 6.1 后端分层架构（DDD 洋葱）

每个限界上下文遵循**洋葱架构**四层分层：

```mermaid
graph TB
    subgraph "限界上下文 (如 Ranch)"
        IF["Interfaces 接口层<br/>Controller / DTO / Assembler"]
        APP["Application 应用层<br/>ApplicationService / Query / Port"]
        DOM["Domain 领域层<br/>Model / Service / Repository接口 / Event"]
        INF["Infrastructure 基础设施层<br/>JPA Entity / Mapper / ACL / MQ"]
    end

    IF --> APP
    APP --> DOM
    APP -.依赖倒置.-> DOM
    INF -.实现.-> DOM
```

| 层 | 职责 | 代码位置示例（Ranch） |
|----|------|---------------------|
| **Interfaces** | REST Controller、请求/响应 DTO、组装器 | `ranch/interfaces/`（LivestockController、FenceController…） |
| **Application** | 用例编排、事务边界、查询服务、Port 定义 | `ranch/application/`（FenceApplicationService、LivestockApplicationService） |
| **Domain** | 领域模型、领域服务、仓储接口、领域事件 | `ranch/domain/`（Fence、FenceBreachDetector、FenceRepository） |
| **Infrastructure** | JPA 持久化、Mapper、ACL 适配器、MQ 消费者 | `ranch/infrastructure/`（FenceJpaEntity、JpaFenceRepositoryImpl、GpsLogEventConsumer） |

**分层约束**：
- 依赖方向：Interfaces → Application → Domain ← Infrastructure（依赖倒置）
- Domain 层不依赖任何外部框架（纯 Java）
- 跨上下文交互仅通过 Application 层定义的 Port 接口

### 6.2 安全架构

```mermaid
flowchart LR
    REQ[HTTP 请求] --> CORS[CORS 过滤]
    CORS --> RF[RequestIdFilter<br/>注入 requestId]
    RF --> JWT{JwtAuthenticationFilter}
    JWT -->|"有 Bearer Token"| VERIFY[解析 JWT<br/>设置 SecurityContext + TenantContext]
    JWT -->|"无 Token"| APIKEY{ApiKeyAuthFilter}
    APIKEY -->|"有 X-API-Key"| APIVERIFY[校验 Key Hash<br/>设置 ApiKey 权限]
    APIKEY -->|"无"| AUTHFAIL[401 未认证]
    VERIFY --> SCOPE[FarmScopeInterceptor<br/>解析 active farm]
    APIVERIFY --> SCOPE
    SCOPE --> CTRL[Controller]
```

**双轨认证**：

| 认证方式 | 适用场景 | 实现 |
|---------|---------|------|
| **JWT** | 移动端、门户（用户态） | `JwtAuthenticationFilter` + `JwtTokenProvider`（JJWT 0.12.5） |
| **API Key** | Open API、第三方系统 | `ApiKeyAuthFilter` + `ApiKeyAuthService`（SHA-256 hash 校验） |

**安全配置要点**（`SecurityConfig`）：
- 无状态 Session（`STATELESS`）
- CSRF 关闭（纯 API 服务）
- BCrypt 密码加密
- CORS 白名单：`localhost:*`、`127.0.0.1:*`、`172.22.1.123:*`、`https://livestock.hkttech.cn`（`SecurityConfig:106`）
- 开放端点：`/auth/login`、`/auth/refresh`、`/auth/logout`、`/health`、`GET /api/v1/deployment-info`、部署授权 enrollment/import（NIX-184）
- 多标识登录与超管上下文：account / email / phone(E.164)（PR #132）；`/auth/entry-contexts`、`/auth/switch-context`（SUPER_ADMIN，act token，NIX-306）
- 方法级权限：`@EnableMethodSecurity`

### 6.3 多租户与数据隔离

```mermaid
flowchart LR
    LOGIN[登录] --> ISSUE[签发 JWT<br/>含 tenantId/role]
    ISSUE --> REQ[后续请求带 JWT]
    REQ --> FILTER[JwtAuthenticationFilter]
    FILTER --> TC[TenantContext<br/>ThreadLocal 设置 tenantId]
    TC --> REPO[JPA 查询自动过滤 tenant_id]
    REPO --> CLEAR[请求结束<br/>ThreadLocal.clear]
```

**作用域解析**（`FarmScopeResolver`）：
- **写操作**（`WRITE`）：必须通过 path `/farms/{farmId}/...` 指定，禁止 header 冲突
- **读操作**（`READ`）：path 或 header `x-active-farm` 二选一，禁止同时提供
- **无作用域**（`NONE`）：租户级操作

**时区三级链**（`TenantZoneResolver`，2026-10）：`farms.timezone` → `tenants.timezone` → 平台默认（`SMARTLIVESTOCK_DEFAULT_TIMEZONE`，未配置时客户端偏移兜底）；存储恒 UTC，链仅作用于展示与业务边界（日分组 / 试点截止换算 / blade 调用 X-TimeZone 头）。

### 6.4 限流、配额与缓存

#### 限流（Redis 滑动窗口）

`RateLimitService` 使用 **Redis Lua 脚本**实现原子滑动窗口：
- 数据结构：Sorted Set（ZSET）
- 原子操作：`ZREMRANGEBYSCORE`（清除过期）→ `ZADD`（记录）→ `ZCARD`（计数）
- 应用：API Key 按分钟限流（`requests_per_minute`，默认 60）

#### 配额拦截（Tier 门控）

`QuotaInterceptor` 通过 `@QuotaCheck` 注解声明式拦截：
1. 请求到达 Controller 方法前拦截
2. 读取注解声明的 `featureKey`
3. `UsageResolver`（按 featureKey 分发）计算当前用量
4. `QuotaCheckService` 比对 `feature_gates.limit_value`
5. 超限返回 `403`，否则放行

**已实现的 UsageResolver**：
- `FarmLivestockUsageResolver`（livestock_management）
- `FarmFenceUsageResolver`（fence_management）

#### 缓存（Redis）

`RedisCacheService` 提供通用缓存能力，`CacheKeys` 统一管理 key 命名空间。

### 6.5 部署架构

```mermaid
graph LR
    subgraph "Docker Compose"
        NGINX["nginx :18080<br/>反向代理"] --> APP["app :8080<br/>Spring Boot"]
        APP --> PG[("postgres :5432<br/>PostgreSQL 16")]
        APP --> REDIS[("redis :6379<br/>Redis 7")]
        APP --> NAMESRV["rocketmq-namesrv :9876"]
        NAMESRV --> BROKER["rocketmq-broker :10911"]
        APP -.只读.-> VOL[("tileserver-data<br/>MBTiles 卷")]
        TILE["tileserver-gl :8080<br/>离线瓦片"] --> VOL2[("tileserver-data")]
    end

    EXT["外部客户端"] --> NGINX
    EXT -.瓦片.-> TILE
```

**Docker Compose 服务清单**：

| 服务 | 镜像 | 端口映射 | 依赖 |
|------|------|---------|------|
| `app` | 自构建（Spring Boot） | 18081:8080 | postgres、redis、rocketmq-broker |
| `postgres` | 自构建（含自定义 pg_hba.conf） | 15432:5432 | — |
| `redis` | redis:7-alpine | 26379:6379 | — |
| `rocketmq-namesrv` | apache/rocketmq:5.1.0 | 19876:9876 | — |
| `rocketmq-broker` | apache/rocketmq:5.1.0 | 10911:10911 | rocketmq-namesrv |
| `tileserver` | maptiler/tileserver-gl | 8081:8080 | — |

**部署拓扑（2026-11，共 4 环境）**：dev（:19080，blade SIT）/ test（:18080，blade 客户试用）/ 86 HOSTED / 223 ONPREM（发布包继承升级、免 sudo，旧版本目录留作回滚点）。全量发布链 = `build_web.sh` → deploy dev → deploy test → 123 打包 → 86/223 两跳升级（`docs/deployment/release-deployment-playbook.md`）。blade 地址经自建 Nacos 下发（`NacosRemoteConfigLoader`：OS env > Nacos > application.yml，Nacos 不可达自动回落；86/223 不启用）。可观测性：`/actuator/prometheus` 独立管理端口（dev 19081 / test 18081）接入 sp-monitoring 栈。

**配置外置**（`application.yml` + 环境变量）：

| 配置项 | 环境变量 | 默认值 |
|--------|---------|--------|
| 数据库 | `DB_HOST/PORT/NAME/USER/PASSWORD` | localhost:5432/smart_livestock |
| Redis | `REDIS_HOST/PORT/PASSWORD` | localhost:6379 |
| RocketMQ | `ROCKETMQ_NAME_SERVER` | localhost:9876 |
| JWT 密钥 | `JWT_SECRET` | default-secret-change-in-production |
| Access Token 有效期 | `JWT_ACCESS_EXPIRATION` | 3600000（1h；单 Token 模型，无独立 refresh token） |
| 刷新宽限期 | `REFRESH_GRACE_MS`（代码常量） | 1800000（30min） |
| 统一试点截止日 | `SMARTLIVESTOCK_TRIAL_ENDS_AT` | 2027-09-30T21:00:00Z（= 2027-10-01 肯尼亚 EAT） |
| 平台默认时区 | `SMARTLIVESTOCK_DEFAULT_TIMEZONE` | 未配置 = 客户端偏移兜底 |
| GPS 模拟器 | `GPS_SIMULATOR_ENABLED/INTERVAL_MS` | false / 30000 |
| 遥测模拟器 | `TELEMETRY_SIMULATOR_ENABLED/INTERVAL_MS` | true / 30000 |

### 6.6 前端架构（Flutter）

```mermaid
graph TB
    subgraph "Flutter 移动端"
        ROUTER["GoRouter<br/>61 条路由 + 认证守卫"]
        SESSION["SessionController<br/>Riverpod Notifier"]
        SCOPE["FarmSwitcherController<br/>active farm 管理"]
        APICLIENT["ApiClient 单例<br/>JWT + farm-scoped CRUD"]
        FEATURES["34 个 Feature 模块<br/>data / domain / presentation"]
        CORE["core/<br/>map / database / l10n / analytics"]
    end

    ROUTER --> SESSION
    SESSION --> APICLIENT
    SCOPE --> APICLIENT
    FEATURES --> APICLIENT
    FEATURES --> CORE
    APICLIENT -->|"REST + JSON"| BE[Spring Boot 后端]
    CORE -->|"MBTiles 下载"| TILE[tileserver-gl]
```

**关键设计**：
- **路由单一来源**：`AppRoute` 枚举定义全部 **57 项**（61 条 GoRoute，2026-11-01 核实），`GoRouter` 配置认证重定向（含 `/select-context` 超管分支）
- **角色化 Shell**：根据用户角色渲染不同导航（底部导航 / NavigationRail / Scaffold）
- **ApiClient 单例**：管理 baseUrl、JWT、activeFarmId，提供 `farmGet/farmPost/farmPut/farmDelete` 农场作用域方法
- **自动刷新**：401 时自动调用 `/auth/refresh`，单飞防并发（`_refreshInProgress` + `_refreshFuture`）
- **离线能力**：`offline_tiles`（瓦片）、`offline_fences`（围栏）、`offline_livestock`（牲畜缓存）
- **国际化**：`app_en.arb` + `app_zh.arb`，支持中英双语

---

## 7. 附录

### 7.1 关键文件索引

| 领域 | 文件 |
|------|------|
| 安全配置 | `shared/security/SecurityConfig.java` |
| 多租户上下文 | `shared/tenant/TenantContext.java` |
| 牧场作用域 | `shared/scope/FarmScopeResolver.java` |
| 事件 Topic 注册 | `shared/messaging/Topics.java` |
| 事件发布器 | `shared/messaging/RocketMQEventPublisher.java` |
| 限流服务 | `shared/ratelimit/RateLimitService.java` |
| 配额拦截器 | `platform/web/QuotaInterceptor.java` |
| 发热分析算法 | `health/domain/service/FeverAnalysisService.java` |
| 围栏检测算法 | `ranch/domain/service/FenceBreachDetector.java` |
| 数据库迁移 | `src/main/resources/db/migration/`（117 个：V1–V41 + V2026xxxx 日期序） |
| 信号流（SSE） | `ranch/interfaces/SignalController.java` |
| 遥测来源枚举 | `iot/domain/model/TelemetrySource.java` |
| 分区自动维护 | `platform/application/PartitionMaintenanceService.java` |
| Nacos 配置加载 | `shared/config/NacosRemoteConfigLoader.java` |
| 应用配置 | `src/main/resources/application.yml` |
| 部署编排 | `smart-livestock-server/docker-compose.yml` |
| 构建配置 | `smart-livestock-server/build.gradle` |

### 7.2 相关文档

| 文档 | 说明 |
|------|------|
| [`customer-journey.md`](./customer-journey.md) | 客户旅程（2026-11-01 基线） |
| [`user-journey-guide.md`](./user-journey-guide.md) | 用户旅程与权限说明（2026-11-01 代码基线） |
| [`smart-livestock-prd-v2.4.md`](./smart-livestock-prd-v2.4.md) | 产品需求文档 v2.4（功能口径事实源） |
| [`../api-contracts/`](../api-contracts/) | API 契约（app / admin / open / overview） |
| [`../reference/seed-data-landscape.md`](../reference/seed-data-landscape.md) | 种子数据全景 |
| [`../guides/subscription-guide.md`](../guides/subscription-guide.md) | 订阅功能指南 |
| [`../guides/tileserver-deployment-guide.md`](../guides/tileserver-deployment-guide.md) | 瓦片服务部署指南 |
| [`../protocols/`](../protocols/) | LoRaWAN 上行 Payload 解析协议（牛羊追踪器/瘤胃胶囊） |

> 原 `system-feature-document.md` / `system-feature-list.md` / `backend-feature-list.md` / `frontend-feature-list.md` 已删除，功能清单以 `docs/api-contracts/` 为准。

### 7.3 术语表

| 术语 | 含义 |
|------|------|
| **限界上下文（Bounded Context）** | DDD 中特定业务领域的边界，本系统有 7 个 |
| **ACL（防腐层）** | Anti-Corruption Layer，隔离外部上下文的适配层 |
| **FeatureGate** | 功能门控，按 Tier 控制功能可用性与配额 |
| **缓冲区（Buffer Zone）** | 围栏边界的预警环带，默认 50m |
| **数字孪生** | 牲畜在系统中的数字化档案（一畜一档） |
| **Open API** | 面向第三方系统的 API Key 认证接口 |
| **TelemetrySource** | 遥测来源枚举：AGENTIC_PLATFORM / THINGSBOARD / DATAGEN / HTTP / MANUAL_IMPORT |
| **GPS outbox** | GPS 写入外置任务表异步落库的管道模式，幂等键 (device_id, recorded_at) |
| **SSE 信号流** | SignalController 服务端单向推送（stream-ticket + SignalEventType 10 值） |
| **超管上下文（act）** | SUPER_ADMIN 经 switch-context 重签的委托 token（RFC 8693 act claim，NIX-306） |

---

*本文档 v2.0 基于 2026-11-01 `master` 代码状态核实（上一版 v1.0 / 2026-06-15）。后续架构演进请同步更新。*
