# MVP 后端设计规格

> Issue #40: 构建 MVP
> 方案: Domain-First + DDD + TDD
> 状态: Phase 1 设计完成，待实施

## 技术路线变更说明

**决策:** MVP 后端采用 **Spring Boot 3.x + Java 17**，取代之前 CLAUDE.md 中规划的 AdonisJS v6 + TypeScript。

**变更原因:**
1. PC/ 目录已有 Spring Boot 设计基础（backend-springboot-design.md、init_postgresql.sql 3770 行）
2. 企业级场景（多租户、订阅计费、IoT）Spring Boot 生态更成熟
3. Java 强类型在复杂业务域上更不容易出错

**对现有仓库的影响:**
- Mobile/ 端的 Node.js Express Mock Server 继续保留，作为前端独立开发的后端支撑
- Spring Boot 后端与 Mock Server 共享相同的 API 契约（统一响应包络、错误码枚举、分页格式）
- Flutter 前端 Live Repository 层需要适配 Spring Boot API（URL 从 `/api/` 改为 `/api/v1/`，响应格式对齐）
- CLAUDE.md 中 "MVP 后端（待实现）: AdonisJS v6" 的描述需更新为 Spring Boot
- PC/ 前端从 Angular 切换为 Vue 3，与 Mobile Flutter 共享同一个 Spring Boot 后端

**迁移策略:**
- Phase 1: Spring Boot 与 Mock Server 并行存在。Mock Server 继续服务 Flutter 前端开发，Spring Boot 逐步实现 API 端点
- Flutter 前端通过 `--dart-define=APP_MODE=live` 切换到 Spring Boot 后端（修改 API_BASE_URL）
- 两个后端保持相同的响应格式和错误码体系，前端切换只需改 URL 前缀

## 技术选型

| 组件 | 技术栈 | 版本 |
|------|--------|------|
| 后端框架 | Spring Boot | 3.x (LTS) |
| 语言 | Java | 17 |
| 构建工具 | Gradle | — |
| 数据库 | PostgreSQL | 16 |
| 缓存 | Redis | 7 |
| 消息队列 | RocketMQ | 5.1 |
| 数据库迁移 | Flyway | — |
| ORM | Spring Data JPA + Hibernate | — |
| 认证 | Spring Security + JWT | — |
| 测试 | JUnit 5 + Mockito + Testcontainers | — |
| 前端 | Flutter (Mobile) + Vue 3 (PC) | — |
| 部署 | Docker Compose (单机) | — |
| 代码托管 | 内网 GitLab (172.22.1.123) | — |

## 交付阶段

| 阶段 | 范围 | 状态 |
|------|------|------|
| Phase 1 | 核心底座: Identity + Ranch + IoT(Device) | 本文档设计完毕，待实施 |
| Phase 2 | 商业模型: Commerce + Health + Analytics 全量 | 待设计 |
| Phase 3 | IoT 真实接入: LoRa/NS 平台 + 设备 license + 传感器数据 | 待设计 |

---

## 1. 限界上下文 (Bounded Context)

### 1.1 上下文划分

```
┌──────────────────────────────────────────────────────────┐
│                 Smart Livestock System                    │
├───────────┬───────────┬──────────┬──────────┬────────────┤
│ Identity  │  Ranch    │   IoT    │ Commerce │  Analytics │
│           │           │          │          │            │
│ · Tenant  │ · Livestock│ · Device │ · Sub    │ · Dashboard│
│ · User    │ · Fence   │ · License│ · Contract│ · MapView │
│ · Farm    │ · Alert   │ · Install│ · Revenue │ · Stats   │
│ · Role    │ · Worker  │ · Telem  │ · ApiKey  │            │
└───────────┴───────────┴──────────┴──────────┴────────────┘
         Phase 1 实现     Phase 1 实现    Phase 2     Phase 2
```

### 1.2 各上下文详细设计

#### Identity Context（身份与租户）

| 类型 | 名称 | 说明 |
|------|------|------|
| 聚合根 | Tenant | 租户，含 phase(SAMPLE/BATCH) |
| 聚合根 | User | 用户，含角色和认证信息 |
| 聚合根 | Farm | 牧场，归属 Tenant |
| 值对象 | Role | owner / worker / platform_admin / b2b_admin / api_consumer |
| 值对象 | TenantPhase | SAMPLE（首年免费）/ BATCH（签合同后） |

**Farm 归属规则:** Identity 拥有 Farm 的写入权，Ranch 仅引用 farm_id（共享内核模式）。

#### Ranch Context（牧场管理）

| 类型 | 名称 | 说明 |
|------|------|------|
| 聚合根 | Livestock | 牲畜档案，含品种、体重、健康状态，归属 Farm |
| 聚合根 | Fence | 电子围栏，多边形顶点集合，关联 Farm |
| 聚合根 | Alert | 告警，状态机(pending→acknowledged→handled→archived) |
| 领域服务 | FenceBreachDetector | 越界检测：消费 GPS 定位事件 + 围栏多边形规则 → 产出 Alert |
| 值对象 | HealthStatus | healthy / warning / critical |
| 值对象 | AlertStatus | pending / acknowledged / handled / archived |
| 值对象 | AlertType | FENCE_BREACH / TEMPERATURE_ABNORMAL / BEHAVIOR_ABNORMAL / ESTRUS / EPIDEMIC |
| 值对象 | Severity | info / warning / critical |
| 值对象 | GpsCoordinate | 纬度 + 经度 |

**围栏越界检测归属:** 归 Ranch Context。IoT 只产出 GpsLogUpdated 事件，不持有围栏形状或越界规则。

#### IoT Context（设备与数据）

| 类型 | 名称 | 说明 |
|------|------|------|
| 聚合根 | Device | 设备(tracker/capsule/accelerometer)，含状态和 LoRa 信息 |
| 聚合根 | DeviceLicense | 设备许可证，绑定 Device 和 Tenant，含有效期 |
| 聚合根 | Installation | 安装记录，绑定 Device 和 Livestock |
| 实体 | GpsLog | GPS 时序数据 |
| 实体 | TemperatureLog | 温度时序数据 (Phase 2) |
| 实体 | PeristalticLog | 蠕动时序数据 (Phase 2) |
| 值对象 | DeviceType | TRACKER / CAPSULE / ACCELEROMETER |
| 值对象 | DeviceStatus | INVENTORY / ACTIVE / OFFLINE / DECOMMISSIONED |
| 值对象 | LicenseStatus | ACTIVE / EXPIRED / REVOKED |

**Device 与 DeviceLicense 分离原因:** 物理设备和商业授权有不同的生命周期。设备是物理实体，变更是因为坏了/没电/固件升级；许可证是商业授权，变更是因为过期/续费/撤销。分离后各阶段可独立演进。

#### Health Context（健康分析） — Phase 2

| 类型 | 名称 | 说明 |
|------|------|------|
| 聚合根 | HealthProfile | 牲畜健康档案，汇总健康评分 |
| 实体 | FeverAssessment | 发热评估：基线温度、阈值、72h 趋势、结论 |
| 实体 | DigestiveAssessment | 消化评估：蠕动基线、24h 趋势、建议 |
| 实体 | EstrusAssessment | 发情评估：综合评分(步态+温度+距离)、7d 趋势、配种建议 |
| 实体 | EpidemicAssessment | 疫情评估：群体健康指标、接触追踪、异常率 |
| 值对象 | HealthScore | 综合健康评分（温度+蠕动+活动量加权） |

**数据流方向:** IoT → Health → Ranch（单向，不回头）。Health 消费 IoT 遥测事件，产出 HealthAnomalyDetected 事件，Ranch 订阅后生成 Alert。IoT 不知道 Health 的评分规则。

#### Commerce Context（商业模型） — Phase 2

| 类型 | 名称 | 说明 |
|------|------|------|
| 聚合根 | Subscription | 订阅，绑定 Tenant，含 phase 和 tier |
| 聚合根 | SubscriptionService | 可订阅的服务目录（围栏服务、健康服务等） |
| 聚合根 | Contract | B2B 合同，约定 tier、分润比例、有效期 |
| 聚合根 | Revenue | 分润记录，关联 Contract，按月结算 |
| 聚合根 | ApiKey | API 密钥，含权限范围和调用频率 |
| 值对象 | SubscriptionTier | basic / pro / enterprise |
| 值对象 | SubscriptionPhase | SAMPLE / BATCH |
| 值对象 | ApiKeyStatus | ACTIVE / REVOKED / EXPIRED |

#### Analytics Context（数据洞察） — Phase 2

| 类型 | 名称 | 说明 |
|------|------|------|
| 聚合根 | Dashboard | 看板数据聚合：牲畜数/健康率/告警数/设备在线率 |
| 聚合根 | MapView | 地图视图：牲畜实时位置 + 围栏叠加 + 告警标记 |
| 聚合根 | Stats | 统计分析：健康/告警/设备概览，按时间段聚合 |

**Analytics 定位:** 纯读模型（CQRS Query 侧），绝不反向写回任何上下文。输出形态为 REST API（Dashboard/Map/Stats 查询接口）。如果需要"点击看板→跳转到告警处理"，跳转走前端路由，不走 Analytics 写回。

### 1.3 商业模型

**两个客户阶段:**

| 阶段 | 触发条件 | 围栏 | 告警 | 设备 | 数据保留 | 牧工 |
|------|---------|------|------|------|---------|------|
| 样品单 | 注册即生效，首年免费 | 无限 | 无限 | 10 台 | 30 天 | 5 人 |
| 批量单 | 签署合同后升级 | 按 tier | 按 tier | 按 tier | 按 tier | 按 tier |

**批量单 tier（签署合同后）:**

| Tier | 围栏 | 告警类型 | 设备 | 数据保留 | 牧工 |
|------|------|---------|------|---------|------|
| basic | 10 | 围栏+温度 | 50 | 30 天 | 5 |
| pro | 50 | 全类型 | 200 | 90 天 | 20 |
| enterprise | 无限 | 全类型 | 无限 | 无限 | 无限 |

**门控逻辑:**

```
if (tenant.phase == SAMPLE) {
  // 不门控功能，仅做合理上限保护
  enforceSoftLimit(fence: 20, alert: unlimited, device: 10)
} else {
  // 批量单，按 tier 严格门控
  enforceTierLimit(tier)
}
```

### 1.4 跨上下文映射

| 上游 | 下游 | 模式 | 说明 |
|------|------|------|------|
| Identity | 所有上下文 | 共享内核 | tenant_id / farm_id 全局隔离键 |
| Identity↔Ranch | | 共享内核 | Identity 拥有 Farm 写入权，Ranch 仅引用 farm_id |
| IoT | Ranch | 领域事件 | GpsLogUpdated → FenceBreachDetector → Alert |
| IoT | Health (P2) | 领域事件 | 遥测更新事件 |
| Health (P2) | Ranch | 领域事件 | HealthAnomalyDetected → Alert |
| IoT | Commerce (P2) | 领域事件 | DeviceActivated / LicenseExpired → 计费 |
| Commerce (P2) | Identity | 领域事件 | 合同签署 → Tenant.phase 转为 BATCH |
| Commerce (P2) | Ranch/IoT/Health | 开放主机服务 | tier/phase 查询，功能门控和配额 |
| 所有 | Analytics (P2) | 开放主机服务 | Analytics 只读查询，不写回 |

### 1.5 数据流方向图

```
Identity ──(tenant_id/farm_id)──→ 所有上下文（共享内核）

IoT ──GpsLogUpdated──→ Ranch（FenceBreachDetector → Alert）
IoT ──遥测事件──────→ Health（评分规则 → HealthAnomalyDetected）
Health ──异常事件───→ Ranch（→ Alert）

Commerce ──tier/phase查询──→ Ranch / IoT / Health（功能门控）
Commerce ──合同签署事件──→ Identity（phase 转为 BATCH）

Identity / Ranch / IoT / Health / Commerce ──(只读)──→ Analytics
```

---

## 2. 数据库 Schema (Phase 1)

### 2.1 Identity Context

**tenants**

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGSERIAL | PK | |
| name | VARCHAR(100) | NOT NULL | 租户名称 |
| contact_name | VARCHAR(100) | | 联系人 |
| contact_phone | VARCHAR(20) | | 联系电话 |
| phase | VARCHAR(10) | NOT NULL, DEFAULT 'SAMPLE' | SAMPLE / BATCH |
| created_at | TIMESTAMP | DEFAULT now() | |
| updated_at | TIMESTAMP | DEFAULT now() | |

**farms**（Identity 拥有写入权，Ranch 仅引用 farm_id）

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGSERIAL | PK | |
| tenant_id | BIGINT | FK → tenants.id, NOT NULL | 所属租户 |
| name | VARCHAR(100) | NOT NULL | 牧场名称 |
| latitude | DECIMAL(10,7) | | 中心纬度 |
| longitude | DECIMAL(10,7) | | 中心经度 |
| area_hectares | DECIMAL(10,2) | | 面积（公顷） |
| created_at | TIMESTAMP | DEFAULT now() | |
| updated_at | TIMESTAMP | DEFAULT now() | |

**users**

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGSERIAL | PK | |
| username | VARCHAR(50) | UNIQUE, NOT NULL | |
| password_hash | VARCHAR(100) | NOT NULL | BCrypt |
| name | VARCHAR(100) | NOT NULL | 显示名 |
| phone | VARCHAR(20) | | 手机号 |
| role | VARCHAR(30) | NOT NULL | owner/worker/platform_admin/b2b_admin/api_consumer |
| tenant_id | BIGINT | FK → tenants.id | 所属租户（platform_admin 为 NULL） |
| is_active | BOOLEAN | DEFAULT true | |
| last_login_at | TIMESTAMP | | |
| created_at | TIMESTAMP | DEFAULT now() | |
| updated_at | TIMESTAMP | DEFAULT now() | |

### 2.2 Ranch Context

**livestock**

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGSERIAL | PK | |
| farm_id | BIGINT | FK → farms.id, NOT NULL | 所属牧场 |
| tag_id | VARCHAR(50) | UNIQUE, NOT NULL | 耳标号 |
| breed | VARCHAR(50) | | 品种 |
| gender | VARCHAR(10) | CHECK IN ('公','母') | |
| birth_date | DATE | | 出生日期 |
| weight | DECIMAL(7,2) | | 体重(kg) |
| health_status | VARCHAR(20) | NOT NULL, DEFAULT 'healthy' | healthy/warning/critical |
| last_latitude | DECIMAL(10,7) | | 最新纬度（缓存） |
| last_longitude | DECIMAL(10,7) | | 最新经度（缓存） |
| last_position_at | TIMESTAMP | | 最后定位时间 |
| created_at | TIMESTAMP | DEFAULT now() | |
| updated_at | TIMESTAMP | DEFAULT now() | |

**fences**

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGSERIAL | PK | |
| farm_id | BIGINT | FK → farms.id, NOT NULL | 所属牧场 |
| name | VARCHAR(100) | NOT NULL | 围栏名称 |
| vertices | JSONB | NOT NULL | 多边形顶点 [{lat,lng},...] |
| color | VARCHAR(7) | | 显示颜色 #RRGGBB |
| status | VARCHAR(20) | NOT NULL, DEFAULT 'active' | active/disabled |
| created_at | TIMESTAMP | DEFAULT now() | |
| updated_at | TIMESTAMP | DEFAULT now() | |

**alerts**

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGSERIAL | PK | |
| farm_id | BIGINT | FK → farms.id, NOT NULL | 所属牧场 |
| livestock_id | BIGINT | FK → livestock.id | 关联牲畜 |
| fence_id | BIGINT | FK → fences.id | 关联围栏（越界告警时） |
| type | VARCHAR(30) | NOT NULL | FENCE_BREACH / TEMPERATURE_ABNORMAL / BEHAVIOR_ABNORMAL / ESTRUS / EPIDEMIC |
| status | VARCHAR(20) | NOT NULL, DEFAULT 'pending' | 状态机：pending→acknowledged→handled→archived |
| severity | VARCHAR(10) | NOT NULL, DEFAULT 'warning' | info/warning/critical |
| message | TEXT | | 告警描述 |
| acknowledged_by | BIGINT | FK → users.id | 确认人 |
| acknowledged_at | TIMESTAMP | | 确认时间 |
| handled_by | BIGINT | FK → users.id | 处理人 |
| handled_at | TIMESTAMP | | 处理时间 |
| created_at | TIMESTAMP | DEFAULT now() | |
| updated_at | TIMESTAMP | DEFAULT now() | |

**user_farm_assignments**（替代 workers 表，表达用户与牧场的分配关系）

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGSERIAL | PK | |
| user_id | BIGINT | FK → users.id, NOT NULL | 用户 |
| farm_id | BIGINT | FK → farms.id, NOT NULL | 牧场 |
| role | VARCHAR(30) | NOT NULL | 在该牧场的角色（owner/worker） |
| status | VARCHAR(20) | NOT NULL, DEFAULT 'active' | active/disabled |
| created_at | TIMESTAMP | DEFAULT now() | |

UNIQUE(user_id, farm_id)

### 2.3 IoT Context

**devices**

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGSERIAL | PK | |
| tenant_id | BIGINT | FK → tenants.id, NOT NULL | 所属租户 |
| device_code | VARCHAR(50) | UNIQUE, NOT NULL | 设备编码 |
| device_type | VARCHAR(20) | NOT NULL | TRACKER / CAPSULE / ACCELEROMETER |
| status | VARCHAR(20) | NOT NULL, DEFAULT 'INVENTORY' | INVENTORY / ACTIVE / OFFLINE / DECOMMISSIONED |
| battery_level | INTEGER | | 电量百分比 |
| firmware_version | VARCHAR(50) | | 固件版本 |
| dev_eui | VARCHAR(16) | | LoRa DevEUI |
| last_online_at | TIMESTAMP | | 最后在线时间 |
| created_at | TIMESTAMP | DEFAULT now() | |
| updated_at | TIMESTAMP | DEFAULT now() | |

**device_licenses**

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGSERIAL | PK | |
| device_id | BIGINT | FK → devices.id, UNIQUE, NOT NULL | 一对一绑定设备 |
| tenant_id | BIGINT | FK → tenants.id, NOT NULL | 购买方 |
| license_key | VARCHAR(100) | UNIQUE, NOT NULL | 许可证密钥 |
| status | VARCHAR(20) | NOT NULL, DEFAULT 'ACTIVE' | ACTIVE / EXPIRED / REVOKED |
| activated_at | TIMESTAMP | | 激活时间 |
| expires_at | TIMESTAMP | NOT NULL | 过期时间 |
| created_at | TIMESTAMP | DEFAULT now() | |

**installations**

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGSERIAL | PK | |
| device_id | BIGINT | FK → devices.id, NOT NULL | 设备 |
| livestock_id | BIGINT | NOT NULL | 牲畜 ID（跨上下文引用，无 FK 约束） |
| installed_at | TIMESTAMP | NOT NULL | 安装时间 |
| removed_at | TIMESTAMP | | 拆除时间（NULL = 当前安装中） |
| operator_id | BIGINT | FK → users.id | 操作人 |
| created_at | TIMESTAMP | DEFAULT now() | |

约束：同一设备不能有两条 removed_at IS NULL 的记录。

**跨上下文引用说明:** `installations.livestock_id` 不使用 FK 约束，仅作为普通列存储 Ranch 上下文的 livestock ID。这是 Phase 1 的务实折中 — 避免跨上下文的数据库耦合。数据一致性由应用层保证（安装时校验 livestock 是否存在）。

**gps_logs**（Phase 1 用模拟数据填充）

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGSERIAL | PK | |
| device_id | BIGINT | FK → devices.id, NOT NULL | 设备 |
| latitude | DECIMAL(10,7) | NOT NULL | 纬度 |
| longitude | DECIMAL(10,7) | NOT NULL | 经度 |
| accuracy | DECIMAL(6,2) | | 精度(m) |
| recorded_at | TIMESTAMP | NOT NULL | 记录时间 |
| created_at | TIMESTAMP | DEFAULT now() | |

索引：`(device_id, recorded_at DESC)`

### 2.4 Phase 1 表总览 (11 张)

| # | 上下文 | 表 | 聚合根 | 跨上下文引用 |
|---|--------|-----|--------|-------------|
| 1 | Identity | tenants | Tenant | — |
| 2 | Identity | farms | Farm | — |
| 3 | Identity | users | User | → tenants |
| 4 | Identity | user_farm_assignments | —（关系表） | → users, farms |
| 5 | Ranch | livestock | Livestock | → farms (共享内核) |
| 6 | Ranch | fences | Fence | → farms (共享内核) |
| 7 | Ranch | alerts | Alert | → farms, livestock, fences |
| 8 | IoT | devices | Device | → tenants |
| 9 | IoT | device_licenses | DeviceLicense | → devices, tenants |
| 10 | IoT | installations | Installation | → devices, livestock (跨上下文) |
| 11 | IoT | gps_logs | —（时序实体） | → devices |
| — | 框架 | flyway_schema_history | — | Flyway 迁移管理 |

### 2.5 ER 关系汇总

| 关系 | 基数 | 说明 |
|------|------|------|
| tenants → farms | 1:N | 租户拥有多个牧场 |
| tenants → users | 1:N | 租户下多个用户 |
| tenants → devices | 1:N | 租户下多个设备 |
| tenants → device_licenses | 1:N | 租户购买多个许可证 |
| users ↔ farms | M:N | user_farm_assignments 关系表 |
| farms → livestock | 1:N | 牧场下多头牲畜（共享内核引用） |
| farms → fences | 1:N | 牧场下多个围栏（共享内核引用） |
| farms → alerts | 1:N | 牧场下多条告警（共享内核引用） |
| livestock → alerts | 1:N | 牲畜关联多条告警 |
| fences → alerts | 1:N | 围栏关联越界告警（可为 NULL） |
| users → alerts | 1:N | 用户确认/处理告警 |
| devices → device_licenses | 1:1 | 设备绑定一个许可证 |
| devices → installations | 1:N | 设备可多次安装/拆除 |
| devices → gps_logs | 1:N | 设备产生 GPS 时序数据 |
| livestock → installations | 1:N | 牲畜可多次安装设备（跨上下文，无 FK 约束，应用层保证一致性） |

### 2.6 Phase 2/3 待新增表

| 阶段 | 上下文 | 待新增表 |
|------|--------|---------|
| Phase 2 | Commerce | subscriptions, subscription_services, contracts, revenues, api_keys |
| Phase 2 | Health | health_profiles, fever_assessments, digestive_assessments, estrus_assessments, epidemic_assessments |
| Phase 2 | IoT | temperature_logs, peristaltic_log |
| Phase 3 | IoT | accelerometer_logs, lora_network_configs |

---

## 3. 项目结构（洋葱架构 + 充血模型）

### 3.1 架构分层

```
┌───────────────────────────────────┐
│     interfaces (API 层)            │  REST Controller, DTO
│  ┌───────────────────────────────┐│
│  │   application (应用层)         ││  用例编排, 事务管理, 事件发布
│  │  ┌───────────────────────────┐││
│  │  │  domain (领域层)           │││  聚合根, 实体, 值对象, 领域服务, 领域事件
│  │  │  ┌─────────────────────┐  │││
│  │  │  │  domain model       │  │││  纯业务规则, 零外部依赖
│  │  │  └─────────────────────┘  │││
│  │  └───────────────────────────┘││
│  └───────────────────────────────┘│
│                                   │
│  infrastructure (基础设施层)       │  JPA 实现, 安全, 配置, 消息
└───────────────────────────────────┘

依赖方向：外层 → 内层，内层不知道外层存在
```

### 3.2 目录结构

```
smart-livestock-server/
├── build.gradle
├── settings.gradle
├── docker-compose.yml
├── Dockerfile
│
└── src/
    ├── main/
    │   ├── java/com/smartlivestock/
    │   │   ├── SmartLivestockApplication.java
    │   │   │
    │   │   ├── identity/                              # Identity Context
    │   │   │   ├── domain/
    │   │   │   │   ├── model/
    │   │   │   │   │   ├── Tenant.java
    │   │   │   │   │   ├── User.java
    │   │   │   │   │   ├── Farm.java
    │   │   │   │   │   ├── Role.java
    │   │   │   │   │   └── TenantPhase.java
    │   │   │   │   ├── event/
    │   │   │   │   │   └── TenantPhaseChangedEvent.java
    │   │   │   │   └── repository/
    │   │   │   │       ├── TenantRepository.java      # port
    │   │   │   │       ├── UserRepository.java
    │   │   │   │       └── FarmRepository.java
    │   │   │   ├── application/
    │   │   │   │   ├── service/
    │   │   │   │   │   ├── AuthApplicationService.java
    │   │   │   │   │   ├── TenantApplicationService.java
    │   │   │   │   │   └── FarmApplicationService.java
    │   │   │   │   ├── command/
    │   │   │   │   │   ├── LoginCommand.java
    │   │   │   │   │   ├── CreateTenantCommand.java
    │   │   │   │   │   └── CreateFarmCommand.java
    │   │   │   │   └── dto/
    │   │   │   │       ├── AuthTokenDto.java
    │   │   │   │       └── TenantDto.java
    │   │   │   ├── infrastructure/
    │   │   │   │   ├── persistence/
    │   │   │   │   │   ├── entity/
    │   │   │   │   │   │   ├── TenantJpaEntity.java
    │   │   │   │   │   │   ├── UserJpaEntity.java
    │   │   │   │   │   │   └── FarmJpaEntity.java
    │   │   │   │   │   ├── mapper/
    │   │   │   │   │   │   ├── TenantMapper.java
    │   │   │   │   │   │   ├── UserMapper.java
    │   │   │   │   │   │   └── FarmMapper.java
    │   │   │   │   │   ├── JpaTenantRepositoryImpl.java
    │   │   │   │   │   ├── JpaUserRepositoryImpl.java
    │   │   │   │   │   └── JpaFarmRepositoryImpl.java
    │   │   │   │   └── security/
    │   │   │   │       └── BcryptPasswordHasher.java
    │   │   │   └── interfaces/
    │   │   │       ├── AuthController.java
    │   │   │       ├── TenantController.java
    │   │   │       └── FarmController.java
    │   │   │
    │   │   ├── ranch/                                  # Ranch Context
    │   │   │   ├── domain/
    │   │   │   │   ├── model/
    │   │   │   │   │   ├── Livestock.java
    │   │   │   │   │   ├── Fence.java
    │   │   │   │   │   ├── Alert.java
    │   │   │   │   │   ├── AlertStatus.java
    │   │   │   │   │   ├── AlertType.java
    │   │   │   │   │   ├── HealthStatus.java
    │   │   │   │   │   ├── Severity.java
    │   │   │   │   │   └── GpsCoordinate.java
    │   │   │   │   ├── service/
    │   │   │   │   │   └── FenceBreachDetector.java
    │   │   │   │   ├── event/
    │   │   │   │   │   ├── FenceBreachDetectedEvent.java
    │   │   │   │   │   └── AlertStatusChangedEvent.java
    │   │   │   │   └── repository/
    │   │   │   │       ├── LivestockRepository.java
    │   │   │   │       ├── FenceRepository.java
    │   │   │   │       └── AlertRepository.java
    │   │   │   ├── application/
    │   │   │   │   ├── service/
    │   │   │   │   │   ├── LivestockApplicationService.java
    │   │   │   │   │   ├── FenceApplicationService.java
    │   │   │   │   │   └── AlertApplicationService.java
    │   │   │   │   ├── command/
    │   │   │   │   │   ├── CreateFenceCommand.java
    │   │   │   │   │   └── AcknowledgeAlertCommand.java
    │   │   │   │   └── dto/
    │   │   │   ├── infrastructure/
    │   │   │   │   ├── persistence/
    │   │   │   │   │   ├── entity/
    │   │   │   │   │   │   ├── LivestockJpaEntity.java
    │   │   │   │   │   │   ├── FenceJpaEntity.java
    │   │   │   │   │   │   └── AlertJpaEntity.java
    │   │   │   │   │   ├── mapper/
    │   │   │   │   │   │   ├── LivestockMapper.java
    │   │   │   │   │   │   ├── FenceMapper.java
    │   │   │   │   │   │   └── AlertMapper.java
    │   │   │   │   │   ├── JpaLivestockRepositoryImpl.java
    │   │   │   │   │   ├── JpaFenceRepositoryImpl.java
    │   │   │   │   │   └── JpaAlertRepositoryImpl.java
    │   │   │   │   └── event/
    │   │   │   │       └── GpsLogEventHandler.java
    │   │   │   └── interfaces/
    │   │   │       ├── LivestockController.java
    │   │   │       ├── FenceController.java
    │   │   │       └── AlertController.java
    │   │   │
    │   │   ├── iot/                                    # IoT Context
    │   │   │   ├── domain/
    │   │   │   │   ├── model/
    │   │   │   │   │   ├── Device.java
    │   │   │   │   │   ├── DeviceLicense.java
    │   │   │   │   │   ├── Installation.java
    │   │   │   │   │   ├── GpsLog.java
    │   │   │   │   │   ├── DeviceType.java
    │   │   │   │   │   ├── DeviceStatus.java
    │   │   │   │   │   └── LicenseStatus.java
    │   │   │   │   ├── event/
    │   │   │   │   │   ├── GpsLogUpdatedEvent.java
    │   │   │   │   │   ├── DeviceActivatedEvent.java
    │   │   │   │   │   └── LicenseExpiredEvent.java
    │   │   │   │   └── repository/
    │   │   │   │       ├── DeviceRepository.java
    │   │   │   │       ├── DeviceLicenseRepository.java
    │   │   │   │       ├── InstallationRepository.java
    │   │   │   │       └── GpsLogRepository.java
    │   │   │   ├── application/
    │   │   │   │   ├── service/
    │   │   │   │   │   ├── DeviceApplicationService.java
    │   │   │   │   │   ├── DeviceLicenseApplicationService.java
    │   │   │   │   │   ├── InstallationApplicationService.java
    │   │   │   │   │   └── GpsLogApplicationService.java
    │   │   │   │   ├── command/
    │   │   │   │   │   ├── RegisterDeviceCommand.java
    │   │   │   │   │   ├── ActivateLicenseCommand.java
    │   │   │   │   │   └── InstallDeviceCommand.java
    │   │   │   │   └── dto/
    │   │   │   ├── infrastructure/
    │   │   │   │   ├── persistence/
    │   │   │   │   │   ├── entity/
    │   │   │   │   │   │   ├── DeviceJpaEntity.java
    │   │   │   │   │   │   ├── DeviceLicenseJpaEntity.java
    │   │   │   │   │   │   ├── InstallationJpaEntity.java
    │   │   │   │   │   │   └── GpsLogJpaEntity.java
    │   │   │   │   │   ├── mapper/
    │   │   │   │   │   └── Jpa*RepositoryImpl.java
    │   │   │   │   └── event/
    │   │   │   │       └── SpringEventPublisher.java
    │   │   │   └── interfaces/
    │   │   │       ├── DeviceController.java
    │   │   │       └── InstallationController.java
    │   │   │
    │   │   └── shared/                                 # 共享内核
    │   │       ├── domain/
    │   │       │   ├── AggregateRoot.java
    │   │       │   ├── DomainEvent.java
    │   │       │   └── Entity.java
    │   │       ├── security/
    │   │       │   ├── JwtTokenProvider.java
    │   │       │   ├── JwtAuthenticationFilter.java
    │   │       │   └── SecurityConfig.java
    │   │       ├── common/
    │   │       │   ├── ApiException.java
    │   │       │   ├── GlobalExceptionHandler.java
    │   │       │   └── ApiResponse.java
    │   │       ├── tenant/
    │   │       │   └── TenantContext.java
    │   │       ├── messaging/
    │   │       │   ├── RocketMQEventPublisher.java
    │   │       │   ├── RocketMQEventSubscriber.java
    │   │       │   └── topics/Topics.java
    │   │       └── cache/
    │   │           ├── RedisCacheService.java
    │   │           └── CacheKeys.java
    │   │
    │   └── resources/
    │       ├── application.yml
    │       └── db/migration/
    │           ├── V1__create_identity_tables.sql
    │           ├── V2__create_ranch_tables.sql
    │           └── V3__create_iot_tables.sql
    │
    └── test/
        └── java/com/smartlivestock/
            ├── identity/
            │   └── domain/model/
            │       └── UserTest.java
            ├── ranch/
            │   └── domain/model/
            │       ├── AlertTest.java
            │       └── FenceBreachDetectorTest.java
            └── iot/
                └── domain/model/
                    ├── DeviceTest.java
                    └── DeviceLicenseTest.java
```

### 3.3 充血模型示例

```java
// Alert.java — 业务规则内聚在实体中
public class Alert extends AggregateRoot {
    private AlertStatus status;
    private AlertType type;
    private Severity severity;
    private Long acknowledgedBy;
    private Long handledBy;

    public void acknowledge(Long userId) {
        if (status != AlertStatus.PENDING) {
            throw new DomainException("只有 pending 状态的告警可以确认");
        }
        this.status = AlertStatus.ACKNOWLEDGED;
        this.acknowledgedBy = userId;
        registerEvent(new AlertStatusChangedEvent(this.id, status));
    }

    public void handle(Long userId) {
        if (status != AlertStatus.ACKNOWLEDGED) {
            throw new DomainException("只有 acknowledged 状态的告警可以处理");
        }
        this.status = AlertStatus.HANDLED;
        this.handledBy = userId;
        registerEvent(new AlertStatusChangedEvent(this.id, status));
    }

    public void archive(Long userId) {
        if (status != AlertStatus.HANDLED) {
            throw new DomainException("只有 handled 状态的告警可以归档");
        }
        this.status = AlertStatus.ARCHIVED;
        registerEvent(new AlertStatusChangedEvent(this.id, status));
    }
}

// Device.java — 设备状态转换规则内聚
public class Device extends AggregateRoot {
    private DeviceStatus status;
    private DeviceType type;

    public void activate() {
        if (status != DeviceStatus.INVENTORY) {
            throw new DomainException("只有库存设备可以激活");
        }
        this.status = DeviceStatus.ACTIVE;
        registerEvent(new DeviceActivatedEvent(this.id, this.tenantId));
    }
}

// Fence.java — 围栏包含点检测规则内聚
public class Fence extends AggregateRoot {
    private List<GpsCoordinate> vertices;

    public boolean contains(GpsCoordinate point) {
        // 射线法判断点是否在多边形内
    }
}
```

### 3.4 分层规则

| 层 | 职责 | 依赖方向 |
|----|------|---------|
| interfaces/ | REST Controller + DTO，参数校验 | → application |
| application/ | 用例编排，事务管理，Command/DTO | → domain |
| domain/model/ | 实体、值对象、枚举，纯业务规则 | 零外部依赖 |
| domain/repository/ | Repository 接口（port） | 零外部依赖 |
| domain/service/ | 领域服务，跨聚合编排 | → domain/model, domain/repository |
| infrastructure/ | JPA 实现（adapter）、安全、消息 | → domain/repository |

**禁止反向依赖:** infrastructure 不能被 domain 层 import；interfaces 不能直接访问 infrastructure。

---

## 4. API 设计

> **状态: 草案。** 需重新设计多端统一 API 契约（App端 + PC端 + 第三方开发者），以 `Mobile/docs/api-contracts/` 为基础升级。本节内容仅作领域模型推导的参考，待独立 API 契约设计完成后替换。

### 4.1 统一响应格式

```json
// 成功
{ "code": "OK", "message": "success", "requestId": "uuid", "data": { ... } }

// 列表（分页）
{ "code": "OK", "message": "success", "requestId": "uuid", "data": {
    "items": [...], "page": 1, "pageSize": 20, "total": 100
}}

// 错误（不含 data 字段）
{ "code": "AUTH_UNAUTHORIZED", "message": "未授权", "requestId": "uuid" }
```

code 字段使用字符串枚举（与现有 API 契约保持一致）：`OK`、`AUTH_UNAUTHORIZED`、`FORBIDDEN`、`NOT_FOUND`、`CONFLICT`、`BAD_REQUEST`、`INTERNAL_ERROR`。

### 4.2 认证

- Bearer Token (JWT)
- JWT payload: `{ "sub": "userId", "tid": "tenantId", "role": "owner", "iat": ..., "exp": ... }`
- 牧场权限在请求时实时校验 user_farm_assignments 表

### 4.3 Identity Context API

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| POST | `/api/v1/auth/login` | 登录，返回 JWT | 公开 |
| GET | `/api/v1/auth/me` | 当前用户信息 | 已认证 |
| POST | `/api/v1/tenants` | 创建租户（注册） | 公开 |
| GET | `/api/v1/tenants/{id}` | 租户详情 | owner/admin |
| PUT | `/api/v1/tenants/{id}` | 更新租户 | owner |
| GET | `/api/v1/tenants/{id}/farms` | 租户下的牧场列表 | owner/admin |
| POST | `/api/v1/tenants/{id}/farms` | 创建牧场 | owner |
| GET | `/api/v1/farms/{farmId}` | 牧场详情 | 成员 |
| PUT | `/api/v1/farms/{farmId}` | 更新牧场 | owner |
| DELETE | `/api/v1/farms/{farmId}` | 删除牧场（软删除） | owner |
| GET | `/api/v1/farms/{farmId}/members` | 牧场成员列表 | owner |
| POST | `/api/v1/farms/{farmId}/members` | 添加成员 | owner |
| DELETE | `/api/v1/farms/{farmId}/members/{userId}` | 移除成员 | owner |

### 4.4 Ranch Context API

**牲畜**

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | `/api/v1/farms/{farmId}/livestock` | 牲畜列表（分页） | owner/worker |
| POST | `/api/v1/farms/{farmId}/livestock` | 添加牲畜 | owner |
| GET | `/api/v1/farms/{farmId}/livestock/{id}` | 牲畜详情 | owner/worker |
| PUT | `/api/v1/farms/{farmId}/livestock/{id}` | 更新牲畜 | owner |
| DELETE | `/api/v1/farms/{farmId}/livestock/{id}` | 删除牲畜 | owner |

**围栏**

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | `/api/v1/farms/{farmId}/fences` | 围栏列表 | owner/worker |
| POST | `/api/v1/farms/{farmId}/fences` | 创建围栏 | owner |
| GET | `/api/v1/farms/{farmId}/fences/{id}` | 围栏详情 | owner/worker |
| PUT | `/api/v1/farms/{farmId}/fences/{id}` | 更新围栏 | owner |
| DELETE | `/api/v1/farms/{farmId}/fences/{id}` | 删除围栏 | owner |
| PATCH | `/api/v1/farms/{farmId}/fences/{id}/status` | 启用/禁用 | owner |

**告警**

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | `/api/v1/farms/{farmId}/alerts` | 告警列表 | owner/worker |
| GET | `/api/v1/farms/{farmId}/alerts/{id}` | 告警详情 | owner/worker |
| PATCH | `/api/v1/farms/{farmId}/alerts/{id}/acknowledge` | 确认告警 | owner/worker |
| PATCH | `/api/v1/farms/{farmId}/alerts/{id}/handle` | 处理告警 | owner |
| PATCH | `/api/v1/farms/{farmId}/alerts/{id}/archive` | 归档告警 | owner |

### 4.5 IoT Context API

**设备**

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | `/api/v1/devices` | 设备列表 | owner/admin |
| POST | `/api/v1/devices` | 注册设备 | owner |
| GET | `/api/v1/devices/{id}` | 设备详情 | owner/worker |
| PUT | `/api/v1/devices/{id}` | 更新设备 | owner |
| PATCH | `/api/v1/devices/{id}/activate` | 激活设备 | owner |
| PATCH | `/api/v1/devices/{id}/decommission` | 停用设备 | owner |

**设备许可证**

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| POST | `/api/v1/devices/{id}/license` | 分配许可证 | owner |
| GET | `/api/v1/devices/{id}/license` | 查看许可证 | owner |
| PATCH | `/api/v1/devices/{id}/license/revoke` | 撤销许可证 | owner |

**安装记录**

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | `/api/v1/devices/{id}/installations` | 安装历史 | owner/worker |
| POST | `/api/v1/installations` | 安装设备到牲畜 | owner |
| PATCH | `/api/v1/installations/{id}/remove` | 拆除设备 | owner |

**GPS 数据**

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| POST | `/api/v1/devices/{id}/gps-logs` | 上报 GPS（批量） | 系统内部/模拟器 |
| GET | `/api/v1/devices/{id}/gps-logs` | GPS 历史轨迹 | owner/worker |
| GET | `/api/v1/farms/{farmId}/livestock/positions` | 牧场牲畜实时位置 | owner/worker |

### 4.6 设计要点

| 要点 | 做法 |
|------|------|
| URL 风格 | `/api/v1/` 前缀，资源嵌套最多 2 层 |
| farmId 路径参数 | Ranch API 统一以 `/farms/{farmId}/` 为前缀 |
| IoT 租户隔离 | 设备 API 通过 JWT 中的 `tid`（tenantId）过滤，不嵌入 URL。platform_admin 的 tenant_id 为 NULL 时可查看所有租户设备 |
| 状态变更 | PATCH + 子路径（/acknowledge, /activate） |
| 删除策略 | 牧场删除为软删除（设置 status=deleted），不级联删除关联数据。如有依赖数据则拒绝删除 |
| 批量 GPS 上报 | POST body 为数组 |
| 多端统一 | Flutter 和 Vue 3 使用相同 API |

### 4.7 牧场作用域（Farm Scope）硬约束

MVP 必须一次性统一牧场作用域的契约与实现，禁止同一请求同时依赖 path 与 header 的双来源隐式解析。

**作用域解析规则：**

| 操作类型 | 作用域来源 | 禁止行为 |
|---------|-----------|---------|
| 写操作（POST/PUT/PATCH/DELETE） | 仅 `/farms/{farmId}` 路径参数 | header `x-active-farm` 不得参与写操作作用域解析 |
| 读操作（GET） | 优先 `/farms/{farmId}` 路径参数 | 兼容模式下可仅用 header，但不可与 path 同时出现 |
| 无作用域（跨牧场查询） | 不需要 farmId | platform_admin 的全局查询 |

**硬约束：**

1. **禁止双来源:** 若同一请求同时包含 path farmId 和 header `x-active-farm`，返回 `422 VALIDATION_ERROR`
2. **写操作强制 path:** Ranch 领域所有写操作必须使用 `/farms/{farmId}/...`，后端只认 path 中的 farmId
3. **权限显式校验:** 对 owner/worker：校验 farmId ∈ user_farm_assignments；对 platform_admin/b2b_admin：必须走 `/farms/{farmId}`，不能靠 header 推断
4. **门控不依赖隐式全局:** shaping/feature gating 读取的是 path 解析出的 farmId，不是 header 中的 activeFarmTenantId

**FarmScope 解析模块：**

```
FarmScopeResolver:
  - WriteScope: 只接受 path farmId，无 path 则 400
  - ReadScope: path farmId 或 header（二选一），同时存在则 422
  - NoScope: 不解析 farmId（全局查询）
  - 所有路由显式声明所需 scope 类型，handler 内部不允许自由解析
```

**`x-active-farm` 兼容策略：**

- 仅作为读接口的过渡兼容，仅限 GET 请求
- 必须写入 API 契约与兼容矩阵
- **下线版本:** Phase 2 上线时同步移除（Phase 1 结束即为下线日期）
- Phase 1 期间必须有集成测试保证 path 入口与 header 入口返回一致（直到下线）

**测试覆盖：**

| 测试场景 | 预期结果 |
|---------|---------|
| 写操作 + path farmId | 正常执行 |
| 写操作 + 仅 header | 400 BAD_REQUEST |
| 写操作 + path + header 同时 | 422 VALIDATION_ERROR |
| 读操作 + path farmId | 正常执行 |
| 读操作 + 仅 header（兼容模式） | 正常执行，与 path 入口返回一致 |
| 读操作 + path + header 同时 | 422 VALIDATION_ERROR |
| owner/worker 访问非授权 farmId | 403 FORBIDDEN |
| platform_admin 跨 farm 查询 | 走 /farms/{farmId}，正常执行 |

---

## 5. 部署架构

### 5.1 服务拓扑

```
┌─────────────────────────────────────────────────┐
│                 172.22.1.123                     │
│                                                  │
│  ┌──────────┐   ┌────────────────────────────┐  │
│  │  Nginx   │──▶│    Spring Boot App :8080    │  │
│  │  :80/443 │   └──────┬──────┬──────┬───────┘  │
│  └──────────┘          │      │      │          │
│               ┌────────▼┐  ┌─▼────┐ ┌▼────────┐ │
│               │PostgreSQL│  │Redis │ │RocketMQ │ │
│               │  :5432   │  │:6379 │ │:9876    │ │
│               └──────────┘  └──────┘ └─────────┘ │
└──────────────────────────────────────────────────┘
```

### 5.2 组件职责

**Redis:**

| 用途 | Key 模式 | 说明 |
|------|---------|------|
| 牲畜实时位置 | `livestock:position:{id}` | GPS 上报写入，Map 查询读缓存 |
| 牧场成员权限 | `farm:{id}:members` | 避免每次请求查 user_farm_assignments |
| 设备在线状态 | `device:online:{id}` | TTL 自动过期，心跳续期 |
| JWT 黑名单 | `jwt:blacklist:{token}` | 注销时加入 |
| 接口频率限制 | `ratelimit:{userId}:{endpoint}` | 计数器 + TTL |

**RocketMQ:**

| Topic | 生产者 | 消费者 | 阶段 |
|-------|--------|--------|------|
| `gps-log-updated` | IoT | Ranch | Phase 1 |
| `device-activated` | IoT | Commerce | Phase 2 |
| `license-expired` | IoT | Commerce | Phase 2 |
| `health-anomaly` | Health | Ranch | Phase 2 |
| `tenant-phase-changed` | Commerce | Identity | Phase 2 |
| `alert-status-changed` | Ranch | Analytics | Phase 2 |

### 5.3 Nginx 路由

| 路径 | 目标 | 说明 |
|------|------|------|
| `/api/v1/` | → app:8080 | 后端 API |
| `/` | → Vue 3 静态文件 | PC 端前端 |
| `/developer/` | → app:8080 | 开发者门户 (Phase 2) |

Flutter 移动端直连 `http://172.22.1.123:8080/api/v1/`。

### 5.4 CI/CD

```
GitLab push → GitLab CI Pipeline
  ├── build:  gradle build
  ├── test:   gradle test
  ├── image:  docker build
  └── deploy: docker-compose up -d (SSH 到 172.22.1.123)
```

---

## 6. 测试策略 (TDD)

### 6.1 TDD 节奏

```
RED → GREEN → REFACTOR

1. 先写领域模型测试（纯 POJO，零依赖，毫秒级）
2. 再写应用层集成测试（Spring Context + Testcontainers）
3. 最后写 API 端到端测试（MockMvc）
```

### 6.2 测试分层

| 层 | 覆盖率目标 | 优先级 | 框架 |
|----|-----------|--------|------|
| 领域模型 | ≥90% | 最高 | 纯 JUnit 5 |
| 应用层 | ≥70% | 高 | @SpringBootTest + Testcontainers |
| API 层 | 关键流程 100% | 中 | MockMvc |

### 6.3 领域模型单元测试（TDD 起点）

| 测试类 | 验证内容 |
|--------|---------|
| `UserTest` | 密码匹配、角色判断、登录状态变更 |
| `AlertTest` | 状态机转换 + 非法跳转抛异常 |
| `FenceTest` | contains() 射线法各场景 |
| `FenceBreachDetectorTest` | GPS + 围栏越界判定 |
| `DeviceTest` | 状态转换规则 |
| `DeviceLicenseTest` | 过期/有效/撤销规则 |
| `InstallationTest` | 重复安装约束 |
| `LivestockTest` | 健康状态变更规则 |

### 6.4 应用层集成测试

| 测试类 | 验证内容 |
|--------|---------|
| `AuthApplicationServiceTest` | 登录/JWT/密码验证 |
| `FenceApplicationServiceTest` | 围栏 CRUD 持久化 |
| `AlertApplicationServiceTest` | 告警状态变更 + 事件发布 |
| `DeviceApplicationServiceTest` | 注册→分配 license→激活完整流程 |
| `GpsLogApplicationServiceTest` | GPS 上报→事件→越界告警（跨上下文） |

### 6.5 API 端到端测试

| 测试类 | 验证内容 |
|--------|---------|
| `AuthApiTest` | 登录 200/401 |
| `FenceApiTest` | CRUD + 权限 |
| `AlertApiTest` | 状态机 + 409 非法跳转 |
| `DeviceApiTest` | 注册→license→激活→安装完整链路 |
| `GpsAlertFlowTest` | GPS 上报→越界→自动生成告警 |

### 6.6 测试命令

```bash
./gradlew test                                    # 全部测试
./gradlew test --tests "*.domain.model.*"         # 仅领域模型单元测试
./gradlew test --tests "*.application.*"          # 仅集成测试
./gradlew test --tests "AlertTest"                # 单个测试类
```

---

## 7. 待完成事项

### Phase 1 待实施

| # | 事项 | 状态 |
|---|------|------|
| 0 | **多端 API 契约重设计**（前置任务）：基于领域上下文设计和 App 端实际代码，统一设计 App端(Flutter) + PC端(Vue 3) + 第三方开发者(Open API) 的 API 契约，完成后更新本规格第 4 节 | 待设计（独立 brainstorming） |
| 1 | Spring Boot 项目初始化（Gradle + Java 17 + Spring Boot 3.x） | 待实施 |
| 2 | Flyway 迁移脚本（V1~V3） | 待实施 |
| 3 | Identity Context 完整实现（domain + application + infrastructure + interfaces） | 待实施 |
| 4 | Ranch Context 完整实现 | 待实施 |
| 5 | IoT Context 完整实现 | 待实施 |
| 6 | 共享内核（AggregateRoot、DomainEvent、Security、Cache、Messaging） | 待实施 |
| 7 | Docker Compose 部署配置 | 待实施 |
| 8 | GitLab 仓库创建 + CI/CD Pipeline | 待实施 |
| 9 | Flutter 前端 Live Repository 适配新 API | 待实施 |
| 10 | Vue 3 PC 端前端初始化 | 待实施 |
| 11 | GPS 模拟数据生成器 | 待实施 |

### Phase 2 待设计

| # | 事项 |
|---|------|
| 1 | Commerce Context 设计（Subscription, Contract, Revenue, ApiKey） |
| 2 | Health Context 设计（Fever, Digestive, Estrus, Epidemic 评估） |
| 3 | Analytics Context 设计（Dashboard, MapView, Stats） |
| 4 | 功能门控与配额系统设计 |
| 5 | B 端管理后台 API 设计 |
| 6 | RocketMQ 剩余 Topic 启用 |
| 7 | 分润对账流程设计 |

### Phase 3 待设计

| # | 事项 |
|---|------|
| 1 | LoRa/NS 平台对接方案 |
| 2 | 设备 license 入网凭证管理 |
| 3 | 真实传感器数据接入（温度、蠕动、加速度） |
| 4 | 设备心跳与在线状态管理 |
| 5 | 时序数据分区策略 |
| 6 | 开发者门户与 Open API |
