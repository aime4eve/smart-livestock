# 智慧畜牧系统统一商业模型设计

> **文档编号**: SL-BIZ-2026-001
> **版本**: v1.3
> **编制日期**: 2026-04-28
> **修订日期**: 2026-04-28
> **状态**: 已修订（按 R3 评审报告修复 4 个新问题 + 语义澄清）
> **受众**: 产品经理 + 技术团队
> **评审报告**:
> - R1: `docs/superpowers/reviews/2026-04-28-unified-business-model-review.md`
> - R2: `docs/superpowers/reviews/2026-04-28-unified-business-model-review-r2.md`
> - R3: `docs/superpowers/reviews/2026-04-28-unified-business-model-review-r3.md`
> **修订记录**:
> - v1.3 (2026-04-28): 按 R3 评审报告修复 NEW-1（`now` 定义）、NEW-2（null-sub 防御）、NEW-3（设备月费中途变更策略）、NEW-4（全局中间件包装模式说明）；澄清 `entitlementTier` 存储语义为"当前有效的 tier"
> - v1.2 (2026-04-28): 按 R2 评审报告修复 N1+C1（getEffectiveTier + subscription 状态检查）、N4（tier 权威数据源）、N3（中间件注册方式统一）、C2（超额计费公式对齐）、N2+C3（calculatedPrice 单位+字段迁移）、N5（owner farm 数量描述）、N6+C6（list 端点 deviceLocked 响应结构）、N7（b2b_admin Phase 1 降级方案）、C4（requiredDevices 跨文档）、C5（checkout/renew 设备月费）
> - v1.1 (2026-04-28): 按 R1 评审报告修复 P0-1~P3-15 共 15 个问题
> - v1.0 (2026-04-28): 初始版本
> **关联文档**:
> - 订阅服务设计规格: `docs/superpowers/specs/2026-04-24-subscription-service-design(B2C).md`
> - 订阅服务实施计划: `docs/superpowers/plans/2026-04-27-subscription-service-implementation(B2C).md`
> - 商业模式评审报告: `docs/superpowers/reviews/2026-04-28-subscription-service-plan-review.md`
> - 机器学习需求说明书: `docs/2026-04-27-机器学习需求说明书.md`

---

## 概述

本设计文档定义智慧畜牧系统的统一商业模型，同时支撑四种商业通道：

| 通道 | 计费方 | 付费方 | 计费方式 |
|---|---|---|---|
| B2C 直订阅 | 平台 | 牧场主 | 设备月费 + tier 月费 |
| B2B 云托管分润 | B端客户 | B端客户的最终用户 | 设备月费 + tier 月费，平台按合同比例分润 |
| B2B 独立部署 | 平台 | B端客户 | 订阅服务年费（含设备和 tier） |
| **API 开放平台** | 平台 | 外部第三方 / B端客户 | API Tier 月费 + 超出调用量

核心设计原则：**tenant 统一为"付钱给我们的实体"**，而非"牧场运营单元"。

---

## 一、核心实体定义

| 实体 | 定义 | 对应角色 | 计费关系 |
|---|---|---|---|
| **平台** | 我们 | `platform_admin` (原 ops) | — |
| **B端客户** | 合作商/代理商，和我们签合同 | `b2b_admin`（新增） | 按旗下牧场主实付订阅费 × 合同分润比，和我们分账 |
| **牧场主** | 养殖户，B端客户发展的最终用户（B2B）或平台的直接客户（B2C） | `owner`（保留） | 按牛数 × 设备月费向 B端客户或平台付费（取决于 billingModel）。可拥有多个牧场 |
| **牧场** | 运营单元，包含牛/设备/围栏/告警 | owner + `worker`（保留） | 订阅套餐绑定在此层 |
| **牧工** | 牧场主的员工 | worker | 不付费，继承所属牧场的权限 |
| **API客户** | 外部第三方，独立购买 API | `api_consumer`（新增） | 按 API 调用量 / API Tier 独立计费 |

### 变化说明

| 变化项 | 原模型 | 新模型 |
|---|---|---|
| tenant 定义 | 等于牧场 | 等于付费客户（partner/farm/api 三种类型） |
| owner → tenant | 一对一 | 一对多（一个 owner 可管理多个 farm tenant） |
| B端客户 | 不存在 | 新增 partner tenant + b2b_admin |
| API 客户 | 不存在 | 新增 api tenant + api_consumer |

---

## 二、tenant 数据模型

### 2.1 三种类型

| type | 语义 | 有合同？ | 有牛/设备？ | 有订阅套餐？ | 有计费？ |
|---|---|---|---|---|---|
| `partner` | B端客户/代理商 | 是（和我们签） | 否 | 是 | 分润结算 |
| `farm` | 牧场（运营单元） | 否 | 是 | 继承 parent | 牛数 × 设备月费 |
| `api` | API 客户 | 是（API 合同） | 否 | 否 | API 调用量 |

### 2.2 完整字段

保留所有现有字段（`id, name, status, region, contactName, contactPhone, contactEmail, remarks, licenseUsed, licenseTotal, createdAt, updatedAt, lastUpdatedBy`），新增：

**Phase 1 新增字段**（通用字段，所有类型共用）：

```
// === 层级关系 ===
type: 'partner' | 'farm' | 'api',    // 默认 'farm'（兼容现有种子数据）
parentTenantId: string | null,       // farm 归属哪个 partner

// === 订阅权限 ===
entitlementTier: 'basic' | 'standard' | 'premium' | 'enterprise',  // partner/direct 直接绑定，farm 继承 parent

// === 商业模式 ===
billingModel: 'direct' | 'revenue_share' | 'licensed' | 'api_usage',

// === farm 专用 ===
ownerId: string | null,               // 牧场主 user id。Phase 1 唯一约束（一个 owner 只能绑定一个 farm）
```

**entitlementTier 数据所有权与存储语义**（解决 tenantStore 与 subscriptionStore 双数据源问题）：

- `tenant.entitlementTier` — 存储的是**当前有效的 tier**（非"购买时的 tier"）。由 subscription 管理模块维护：购买/升级时写入新 tier，到期/取消/试用结束时回写为 `'basic'`。是 Shaping 的权威数据源。`getEffectiveTier()` 在 subscription 检查通过后信任此值
- `subscriptionStore.tier` — **非规范化缓存**，记录用户购买/选择的 tier（不受生命周期影响），用于 UI 展示"您当前订阅的套餐"和历史查询。在 Phase 1 中与 `tenant.entitlementTier` 保持同步
- `subscriptionStore.status` / `currentPeriodEnd` / `trialEndsAt` — 生命周期的权威来源。`getEffectiveTier()` 实时检查这些字段作为安全兜底，即使 `tenant.entitlementTier` 因异常未及时更新，也不会向已过期用户开放高级功能

三层关系：`subscriptionStore.status` 决定"是否有效" → `tenant.entitlementTier` 决定"有效时的 tier 是什么" → `subscriptionStore.tier` 仅记录"用户买了什么"

**Phase 2 新增字段**：

```
// === partner 专用 ===
contractId: string | null,
revenueShareRatio: float | null,      // 分润比例，如 0.15

// === licensed partner 专用（独立部署订阅服务） ===
deploymentType: 'cloud' | 'on_premise' | null,
serviceKey: string | null,            // 订阅服务激活密钥，格式 SL-SUB-XXXX-XXXX
heartbeatAt: datetime | null,

// === api 专用 ===
apiTier: 'free' | 'growth' | 'scale' | null,
apiKey: string | null,
apiCallQuota: int | null,             // 月调用量上限
accessibleFarmTenantIds: string[] | null,  // 可访问的 farm tenant 列表（null 表示仅统计端点）
```

**API Key 生命周期**（Phase 2 实现）：

- 生成算法：UUID v4 + HMAC 签名，格式 `sl_apikey_<uuid>`
- 轮换机制：支持同时持有 2 个有效 Key，旧 Key 轮换后 24h 内仍有效（过渡期）
- 撤销流程：platform_admin 在后台手动撤销，或 api_consumer 自助轮换
- 安全存储：仅存储 Key 的 SHA-256 哈希，原始 Key 仅在生成时返回一次

### 2.3 层级关系

```
partner tenant (type=partner)
  billingModel: revenue_share 或 licensed
  │
  ├── farm tenant (type=farm)
  │     parentTenantId = partner.id
  │     billingModel = 继承自 parent
  │     tier = 继承自 parent
  │
  └── farm tenant (type=farm) ...

direct farm (type=farm, parentTenantId=null)
  billingModel = 'direct'
  tier = 牧场主自主选择

api tenant (type=api)
  billingModel = 'api_usage'
  apiTier = free / growth / scale
```

**继承机制**：farm tenant 的 `entitlementTier` 和 `billingModel` 字段在本行存储的值可能为 null（当该 farm 归属 partner 时）。Shaping 中间件和前端读取时通过以下链查找：

```
farm.entitlementTier ?? parent.entitlementTier ?? 'basic'
farm.billingModel ?? parent.billingModel ?? 'direct'
```

即：farm 自有值优先，null 时查 parent partner。不采用双向同步（父改子同步）以避免一致性负担。parent partner 的 tier 变更立即对所有子 farm 生效（因为每次请求实时 lookup）。

**Shaping 中间件调用接口**（取代原订阅规格中简单的 `getSubscriptionTier(tenantId)`）：

```
function getEffectiveTier(farmTenantId) {
  const farm = tenantStore.findById(farmTenantId);
  if (!farm) return 'basic';
  const now = new Date();

  // direct farm：需检查 subscription 状态（试用过期/取消/到期 → basic）
  if (!farm.parentTenantId) {
    const sub = subscriptionStore.getByTenantId(farmTenantId);
    // 防御：无 subscription 记录时降级为 basic（Phase 1 假设所有 direct farm
    // 均通过 createTrial 创建，正常流程不应进入此分支；此检查覆盖创建失败、
    // 手动删除、数据迁移遗漏等异常场景）
    if (!sub) return 'basic';
    // 已过期
    if (sub.status === 'expired') return 'basic';
    // 已取消且当前周期结束
    if (sub.status === 'cancelled' && now > sub.currentPeriodEnd) return 'basic';
    // 试用期结束
    if (sub.status === 'trial' && now > sub.trialEndsAt) return 'basic';
  }

  // farm 自有值优先（direct farm 购买后由 subscription 模块写入）
  if (farm.entitlementTier) return farm.entitlementTier;

  // 查 parent partner
  if (farm.parentTenantId) {
    const parent = tenantStore.findById(farm.parentTenantId);
    return parent?.entitlementTier ?? 'basic';
  }

  return 'basic';
}
```

**与订阅规格的差异**：本函数取代订阅服务设计规格中的 `getSubscriptionTier(tenantId)`。关键差异：(1) 函数名和输入参数——输入为 `farmTenantId` 而非通用 `tenantId`；(2) 数据源——以 `tenant.entitlementTier` 为权威（经 subscription 状态校验后），而非直接查 `subscriptionStore.tier`；(3) 新增 parent partner 继承链。订阅规格的 `getSubscriptionTier()` 相关描述应以本规格为准。

订阅相关 Store 的 `getByTenantId()` 改为调用此函数获取 effective tier，而非直接查 subscriptionStore。tier 变更通知机制：parent partner 的 tier 变更后，由于每次请求实时 lookup `getEffectiveTier()`，子 farm 的 Shaping 结果在下一次请求时自然反映新 tier，无需主动推送。

### 2.4 种子数据兼容

现有 6 个 tenant（`tenant_001` ~ `tenant_006`）都是牧场：
- `type` 默认 `'farm'`
- `parentTenantId` 默认 `null`
- `billingModel` 默认 `'direct'`
- 无需修改现有种子数据，store 初始化时补默认值

---

## 三、角色体系与权限模型

### 3.1 角色定义

| 角色 | 管理范围 | 登录入口 | 可视数据 |
|---|---|---|---|
| `platform_admin` (原 ops) | 全部 tenant | /ops/admin | 所有 partner/farm/api tenant |
| `b2b_admin`（新增） | 自己的 partner tenant + 旗下 farm | /b2b/admin | 旗下 farm 的用量汇总，不能操作牛/设备 |
| `owner`（保留） | Phase 1: 1 个 farm; Phase 2: 1~N 个 farm | /twin（App 主页） | 自己 farm 的牛/设备/围栏/告警 |
| `worker`（保留） | 被分配到的 farm(s) | /twin | 分配到的 farm，权限受订阅 tier 限制 |
| `api_consumer`（新增） | 自己的 api tenant | 无 UI（仅 API） | 无，纯接口调用 |

### 3.2 绑定关系

```
platform_admin  → tenantId = null（看全部）
b2b_admin       → tenantId = partner tenant id
owner           → 不绑定 tenant，而是 ownerId 字段。Phase 1：唯一约束（一个 owner 只能绑定一个 farm tenant）
worker          → 关联表 worker_farm_assignments { userId, farmTenantId, role, assignedAt }
api_consumer    → tenantId = api tenant id
```

**worker-farm 关联表**（Phase 2 实现完整的 CRUD 和管理界面）：

```
// backend/data/workerFarmStore.js (Phase 1 占位，Phase 2 完整实现)
// 表: worker_farm_assignments
// 字段: { id, userId, farmTenantId, role ('worker'|'supervisor'), assignedAt }
//
// Phase 1 处理: 沿用现有 worker 的单一 tenantId，worker 继承该 farm 的 tier
// Phase 2 处理: 多 farm 分配，worker 登录后可在分配的 farm 间切换
//
// 管理权限:
//   - platform_admin: 可管理所有 worker 分配
//   - owner: 可管理自己 farm 的 worker 分配
//   - b2b_admin: Phase 2 可管理旗下 farm 的 worker 分配
```

### 3.3 权限矩阵

| 操作 | platform_admin | b2b_admin | owner | worker | api_consumer |
|---|---|---|---|---|---|
| 管理所有 tenant | ✓ | ✗ | ✗ | ✗ | ✗ |
| 查看自己合同/分润 | ✗ | ✓ | ✗ | ✗ | ✗ |
| 创建/编辑 farm | ✓ | ✓（旗下） | ✗ | ✗ | ✗ |
| 管理牛/设备/围栏 | ✗ | ✗ | ✓（自己的 farm） | 部分（分配+订阅限制） | ✗ |
| 处理告警 | ✗ | ✗ | ✓ | ✓（仅确认） | ✗ |
| 订阅套餐管理 | ✗ | ✗ | ✓（B2C 散户） | ✗ | ✗ |
| API 调用 | ✗ | ✗ | ✗ | ✗ | ✓（按 apiTier） |
| 查看用量统计 | ✓ | ✓（旗下 farm） | ✓（自己的 farm） | ✗ | ✓（自己的调用量） |
| 创建/管理 worker | ✓ | ✗（Phase 2） | ✓（自己的 farm） | ✗ | ✗ |

> 注：b2b_admin 创建/管理 worker 推迟至 Phase 2（与 B端管理后台一起交付）。Phase 1 中 farm worker 的分配由 platform_admin 或 farm owner 负责。

### 3.4 数据隔离

```
platform_admin:     无隔离，可跨一切
b2b_admin:          只能看到 parentTenantId = 自己的 partner tenant 的 farm
owner:              只能看到 ownerId = 自己的 farm
worker:             只能看到 user-farm 关联表中分配的 farm
api_consumer:       按 apiKey 识别，只能调用授权的端点，看不到 UI
```

### 3.5 对现有代码的影响

| 模块 | 改动 |
|---|---|
| `auth.js` 中间件 | 新增 `b2b_admin`、`api_consumer` 角色，`requirePermission` 扩展权限集。`ops` → `platform_admin` 改名推迟到 Phase 2（影响面大：backend TOKEN_MAP/seed 3 个用户，Flutter DemoRole 枚举/AppSession/SessionController/app_router/demo_shell/role_permission 全部静态方法，以及所有引用 `DemoRole.ops` 的测试文件）。Phase 1 保留 `ops` 名称，仅新增 `b2b_admin`、`api_consumer` |
| `users` 种子数据 | 新增 b2b_admin 和 api_consumer 示例用户 |
| `TOKEN_MAP` | 新增 `mock-token-b2b-admin`、`mock-token-api-consumer`。b2b_admin 使用 Bearer token 认证（与现有角色一致），Mock token 格式 `mock-token-b2b-admin`，JWT payload 结构为 `{ role: 'b2b_admin', tenantId: '<partner_tenant_id>' }` |
| App Session | `AppSession` 新增 role 枚举值，路由守卫适配 |
| Shell/导航 | b2b_admin 看到 B端管理控制台，不含牛/地图/围栏等操作入口 |
| worker 可见性 | 从"看整个 tenant" 改为"看分配的 farm tenant" |

---

## 四、订阅与计费模型

### 4.1 设备 → 服务 → Feature Flag 映射

```
仅 GPS:
  ├── 定位 + 轨迹          → gps_location, trajectory
  ├── 电子围栏             → fence
  └── 围栏越界告警         → （通过 alerts 系统）

仅 瘤胃胶囊:
  ├── 体温监测             → temperature_monitor
  ├── 蠕动监测             → peristaltic_monitor
  │                          （以上两队即覆盖基础消化健康）
  │

GPS + 胶囊（双配）:
  ├── 上述全部
  ├── 发情检测             → estrus_detect
  ├── 个体健康评分         → health_score（需多传感器融合）
  └── 疫病预警             → epidemic_alert

无设备:
  └── 基础档案管理         → livestock_detail, device_management
```

本节省略了无设备依赖的 Feature Flags（如 `stats`、`dashboard_summary`、`profile`、`tenant_admin`、`alert_history`、`dedicated_support`、`data_retention_days`、`gait_analysis`、`behavior_stats`、`api_access`），完整 20 个 key 列表及 Tier 映射见订阅服务设计规格 Section "Feature Flag 清单"。

### 4.1.1 双门控机制：Tier + 设备依赖

功能可用性由两层门控共同决定：

```
功能可用 = tier_gate(tier, feature) AND device_gate(cattleId, feature)
```

| 场景 | Tier 满足？ | 设备满足？ | 前端表现 |
|---|---|---|---|
| 正常使用 | 是 | 是 | 功能正常可用 |
| 需升级 | 否 | 是 | LockedOverlay："升级到 premium 解锁此功能" |
| 缺设备 | 是 | 否 | LockedOverlay："此功能需要安装瘤胃胶囊"，不显示升级按钮 |
| 都缺 | 否 | 否 | LockedOverlay：提示设备缺失（与"缺设备"相同。设备缺失是根本原因，仅升级 tier 解决不了问题） |

**设备检查位置**：device_gate 应在**路由处理函数内部**实现，而非 Shaping 中间件。原因：Shaping 中间件的工作方式是包装 `res.ok()`，操作的是响应数据而非请求上下文，它无法知道当前请求针对的是哪头牛。

路由处理函数在组装数据时，对每头牛检查其设备列表，在返回数据中标记 `deviceLocked: true`。Shaping 中间件只负责 tier 层面的 lock。

实现模式（以 `/twin/fever/:id` 为例）：

```
// 路由处理函数内部
const cattle = cattleStore.findById(req.params.id);
const hasRequiredDevices = checkDeviceRequirement(cattle, 'health_score');
// 在响应数据中标记设备状态
data.deviceLocked = !hasRequiredDevices;
data.deviceMessage = hasRequiredDevices ? null : '此功能需要安装瘤胃胶囊';

// Shaping 中间件后续只处理 tier lock：
//   locked = tier_gate(tier, feature)  ← 不管设备
//   最终 locked = tier_locked || deviceLocked
//   前端据此显示对应提示
```

**前后端协作**：响应数据中每个功能点含两个标记字段：

| 字段 | 来源 | 含义 |
|---|---|---|
| `locked` | Shaping 中间件（tier 检查） | tier 不足，需升级 |
| `deviceLocked` | 路由处理函数（设备检查） | 缺少所需设备 |
| `upgradeTier` | Shaping 中间件 | 非 null 时前端显示"升级到 X"按钮 |
| `deviceMessage` | 路由处理函数 | 非 null 时前端显示设备缺失提示 |

前端 LockedOverlay 判断优先级：若 `deviceLocked && locked`（都缺），显示设备缺失提示（因为升级也解决不了问题）；若仅 `deviceLocked`，显示设备缺失提示；若仅 `locked`，显示升级提示。

**设备判断粒度**：
- 单牛查询（如 `/twin/fever/:id`）：检查该牛的设备列表，在 `data` 级别返回 `deviceLocked` / `deviceMessage`
- 牛只列表（如 `/twin/fever/list`）：按牛粒度逐条检查，每条记录含 `deviceLocked` / `deviceMessage` 字段。Shaping 中间件的 `locked` / `upgradeTier` 仍在信封 `data` 级别
- 非牛相关端点（如 `/dashboard/summary`）：不检查设备依赖

**list 端点响应结构示例**：

```json
{
  "code": 200,
  "message": "success",
  "requestId": "req-xxx",
  "data": {
    "locked": false,
    "upgradeTier": null,
    "items": [
      { "cattleId": "c001", "deviceLocked": false, "deviceMessage": null, ... },
      { "cattleId": "c002", "deviceLocked": true, "deviceMessage": "此功能需要安装瘤胃胶囊", ... },
      { "cattleId": "c003", "deviceLocked": false, "deviceMessage": null, ... }
    ],
    "page": 1,
    "pageSize": 20,
    "total": 3
  }
}
```

即：`locked`（tier 级）在信封 `data` 层，`deviceLocked`（设备级）在每条 item 内。前端 LockedOverlay 在每个 item 上独立判断：`item.deviceLocked || data.locked`。

**device_gate 规则表**：

| Feature Flag | 所需设备 |
|---|---|
| `fence`, `gps_location`, `trajectory` | GPS 追踪器 |
| `temperature_monitor`, `peristaltic_monitor` | 瘤胃胶囊 |
| `health_score`, `estrus_detect`, `epidemic_alert` | GPS 追踪器 + 瘤胃胶囊（双配） |
| 其他 Feature Flag | 无设备依赖 |

### 4.2 三层计费结构

#### Layer 1: 设备月费

计费单元：每头牛 × 佩戴的设备

- GPS 追踪器: ¥c /牛/月（TBD，待与业务方确定）
- 瘤胃胶囊: ¥d /牛/月（TBD，待与业务方确定）
- farm 总费用 = ∑(每头牛的设备配置月费)

面向所有 farm tenant，用途：B2C 散户直接付平台 / B2B 牧场主付 B端客户。

#### Layer 2: 订阅 Tier

在设备月费之上叠加的增值功能：

| Tier | 月费 | 超出单价 | 围栏上限 | 告警历史 | 数据保留 | 设备费之外包含的服务 |
|---|---|---|---|---|---|---|
| basic | ¥0 | ¥3/头/月 | 3个 | 7天 | 7天 | 基础版（设备月费单独算） |
| standard | ¥299 | ¥2/头/月 | 5个 | 30天 | 30天 | 历史轨迹 + 告警历史 |
| premium | ¥699 | ¥1/头/月 | 10个 | 90天 | 365天 | 健康评分 + 发情 + 疫病 |
| enterprise | 定制 | 免费 | 不限 | 1年 | 3年 | 全部 + API 访问 + 专属支持 |

Tier 绑定于 partner tenant 或 direct farm tenant。非 direct 模式的 farm 继承 parent partner 的 tier。

**Tier 到 Feature Flag 的完整映射**和牲畜上限规则（basic=50, standard=200, premium=1000, enterprise=无限）见订阅服务设计规格 Section "Feature Flag 清单"。本规格不重复该表，仅在此明确：

- **设备月费（Layer 1）**是本规格新增的计费维度，独立于 tier 月费。每头牛按实际佩戴设备计费。
- **牲畜上限（原订阅规格）**保留，但语义调整为"tier 包含牲畜数内不额外叠加设备溢价"。超出上限部分按套餐阶梯单价叠加（basic=¥3/头/月, standard=¥2/头/月, premium=¥1/头/月, enterprise=免费）。两套公式共存：`总月费 = 设备月费 + tier 月费 + 超出上限阶梯费`。
- **围栏/告警/数据保留**按套餐差异化：围栏上限（3/5/10/不限）、告警历史天数（7/30/90/365天）、数据保留天数（7/30/365/1095天），详见上表。

注意：premium 及以上 tier 包含的 ML 功能（健康评分、发情检测、疫病预警）需要双配设备数据才能实际生效。数据不满足条件时，前端显示"需要安装瘤胃胶囊"而非"升级套餐"。

#### Layer 3: API 增值

独立于设备费，按 API 调用量计费：

| Tier | 月调用配额 | 超出单价 | 开放端点 |
|---|---|---|---|
| free (捆绑 enterprise) | 1,000 calls | 不可超出 | /twin/* 只读 |
| growth (¥500/月) | 10,000 calls | ¥0.01/call | 全部 twin |
| scale (¥2,000/月) | 100,000 calls | ¥0.005/call | 全部 + 写入 |

注意：`free` tier 不单独销售，仅捆绑 enterprise 订阅。外部 `api_consumer` 客户最小起步为 `growth` tier。面向 api tenant（外部第三方）。enterprise App 用户通过 Feature Flag `api_access` 获得 free tier。

#### 端到端计费示例

以下以 350 头牛、standard tier、GPS + 胶囊双配为例，展示完整计费计算：

**场景设定**：
- farm 规模：350 头牛
- 订阅 tier：standard（¥299/月，含 200 头牲畜上限）
- 设备配置：每头牛同时佩戴 GPS 追踪器 + 瘤胃胶囊
- 商业模式：B2C direct

**Step 1 — 设备月费（Layer 1）**：
```
GPS 追踪器: 350 头 × ¥c/月（假设 ¥15）= ¥5,250
瘤胃胶囊:   350 头 × ¥d/月（假设 ¥30）= ¥10,500
设备月费合计: ¥15,750
```

**Step 2 — Tier 月费（Layer 2）**：
```
standard tier 固定月费: ¥299
包含牲畜数: 200 头
超出: 350 - 200 = 150 头
超出阶梯费: 150 × ¥2/头 = ¥300（standard 超出单价）
Tier 月费合计: ¥299 + ¥300 = ¥599
```
*注：超出单价按套餐差异化（basic=¥3/头/月, standard=¥2/头/月, premium=¥1/头/月, enterprise=免费）。本规格采用每头定价而非订阅服务设计规格中的批次定价（每 50 头 +¥50）。每头定价更简单透明，且与设备月费的计费粒度保持一致。订阅规格中的批次定价公式已被本规格覆盖，实施时以本规格每头定价为准。*

**Step 3 — 总月费**：
```
总月费 = 设备月费 + tier 月费
       = ¥15,750 + ¥599
       = ¥16,349/月
```

**语义澄清**："tier 包含牲畜数内不额外叠加设备溢价" 的含义是：前 200 头牛的设备费按标准单价计算（无溢价），超出 200 头的 150 头牛在设备费基础上**另加** tier 阶梯费。设备月费与 tier 月费是累加关系，不存在"包含"替代关系。

**`calculatedPrice` 字段更新**：`SubscriptionStatus.calculatedPrice` 需拆分为三个子字段。单位统一为**元**（订阅规格原为"分"——本规格采用"元"以与设备月费、tier 月费的展示单位一致，降低前端转换出错风险）：

```
{
  calculatedDeviceFee: 15750,   // Layer 1 设备月费（元），新增
  calculatedTierFee: 599,       // Layer 2 tier 月费（元），对应原 calculatedPrice 语义
  calculatedTotal: 16349        // Layer 1 + Layer 2（元）
}
```

**从订阅规格迁移**：订阅规格定义单一 `calculatedPrice: int // 单位：分`。实施时：(1) 数据库新增 `calculatedDeviceFee` 和 `calculatedTotal` 列，`calculatedPrice` 改名为 `calculatedTierFee`；(2) 单位从分改为元，历史数据需除以 100（Phase 1 为全新部署无历史数据，无需迁移）。

**设备月费中途变更策略**：Phase 1 设备月费仅在 checkout（新购）和 renew（续费）时按当前牛数和设备配置重新计算。中途新增牛只、移除牛只（死亡/出售）、更换设备类型等变更不触发实时费用调整，费用差异在下次 checkout/renew 时自然体现。

### 4.3 三种商业模式下的计费路径

| | B2C 直订阅 | B2B 云托管分润 | B2B 独立部署 |
|---|---|---|---|
| 谁付设备月费？ | 牧场主 → 平台 | 牧场主 → B端客户 | B端客户 → 平台（订阅服务一口价含设备） |
| 谁付订阅 Tier？ | 牧场主 → 平台 | B端客户 → 平台（enterprise 合同价） | B端客户 → 平台（订阅服务年费含 tier） |
| 平台收入来源 | 设备月费 + tier 月费 | B端客户 enterprise 合同费 + 分润 | 订阅服务年费 |
| 谁选 tier？ | 牧场主自主 | B端客户（旗下 farm 统一） | B端客户（订阅服务捆绑） |
| API 增值 | enterprise tier 含 free API | B端客户可额外开通 API tier | 可额外开通 |

### 4.4 对当前订阅规格的影响

| 原规格内容 | 变化 |
|---|---|
| 四层 tier（basic/standard/premium/enterprise） | 保留，语义扩展：tier 是"增值服务层"，设备费独立计算 |
| 混合计费（基础月费 + 牲畜阶梯加价） | 拆分为两条公式：设备月费 = ∑(牛 × 设备配置单价)；tier 月费 = 固定月费 + 超出阶梯费（按套餐差异化单价：basic=¥3, standard=¥2, premium=¥1, enterprise=免费） |
| tier 绑定 tenant | partner/direct 类型 tenant 绑定 tier，farm 类型继承 parent |
| Feature Flag 定义（20 个 key） | 新增设备依赖约束 |
| 价格展示 | direct 模式显示价格；非 direct 模式显示"由经销商管理" |
| `POST /api/subscription/checkout` | 请求/响应结构扩展：新增 `calculatedDeviceFee` 和 `calculatedTotal` 字段，设备月费与 tier 月费分别展示 |
| `POST /api/subscription/renew` | 同上，renew 时重算设备月费（牛数可能已变化） |
| 试用机制 | 仅 direct farm 新注册时触发（高级版 14 天免费试用，到期自动降级为基础版，详见订阅服务设计规格 Section "订阅层级"）；partner 下 farm 由 B端客户决定 |

---

## 五、开放平台 API

### 5.1 端点分类

| 类别 | 前缀 | 示例 | 认证方式 |
|---|---|---|---|
| App API（内部） | `/api/v1/*` | `/api/v1/twin/overview` | Bearer token（用户登录态） |
| Open API（对外） | `/api/open/v1/*` | `/api/open/v1/twin/fever/predict` | `X-API-Key` header |

两套端点调用相同底层服务，接口契约、限流、鉴权独立。

**Open API 的 Shaping 规则**：Open API 请求也经过 Shaping 中间件，但 tier 来源不同：

| 端点 | Tier 来源 | 说明 |
|---|---|---|
| `/api/open/v1/*` | api tenant 的 `apiTier` | 按 API tier（free/growth/scale）限制端点可见性，不检查 farm tier |
| `/api/v1/*` | `getEffectiveTier(activeFarmTenantId)` | 按 farm 的 effective tier 限制功能 |

即：API 客户调用 Open API 时，受其 API tier 限制（如 free tier 只能调只读 single-cattle 端点），不受 farm tier 限制。API 客户通过 `accessibleFarmTenantIds` 获得数据访问范围后，返回数据的实际内容由该授权范围决定。

### 5.2 API 端点清单

```
free tier (捆绑 enterprise 订阅):
  ├── GET  /api/open/v1/twin/fever/:id        # 单头牛发热状态
  ├── GET  /api/open/v1/twin/estrus/:id       # 单头牛发情评分
  ├── GET  /api/open/v1/twin/digestive/:id    # 单头牛消化状态
  ├── GET  /api/open/v1/twin/health/:id       # 单头牛健康评分
  └── 限额: 1,000 calls/月，速率 10 calls/min

growth (¥500/月):
  ├── free 全部端点
  ├── GET  /api/open/v1/twin/fever/list
  ├── GET  /api/open/v1/twin/estrus/list
  ├── GET  /api/open/v1/twin/epidemic/summary
  ├── POST /api/open/v1/twin/health/batch
  └── 限额: 10,000 calls/月，超出 ¥0.01/call

scale (¥2,000/月):
  ├── growth 全部端点
  ├── GET  /api/open/v1/cattle/list
  ├── GET  /api/open/v1/fence/list
  ├── GET  /api/open/v1/alert/list
  ├── POST /api/open/v1/twin/fever/batch
  └── 限额: 100,000 calls/月，超出 ¥0.005/call
```

### 5.3 API 客户的数据隔离

| 授权模式 | 描述 | accessibleFarmTenantIds | 可调端点 |
|---|---|---|---|
| 自有数据 | 保险公司自己买了胶囊设备给牛戴 → 查自己的数据 | 已关联的 farm 列表 | 全部授权的端点 |
| 平台全量（受限） | 政府畜牧部门 → 查脱敏统计 | `null`（表示仅统计） | 仅聚合统计端点，不能查个体 |
| B端客户代调 | 代理商调用旗下牧场数据 | — | `b2b_admin` 用 Bearer token 直接调 App API，不走 Open API |

API 客户通过 `accessibleFarmTenantIds` 字段关联其可访问的 farm tenant（见 Section 2.2）。授权中间件在验证 API Key 后，查找对应的 api tenant，将 `accessibleFarmTenantIds` 注入请求上下文作为数据过滤条件。

**授权审批流程**（Phase 2 实现）：

```
发起方: api_consumer 在开发者门户提交授权申请
       (指定目标 farm tenant + 请求的端点范围)
审批方: farm owner（在 App "我的" → "API 授权管理"中审核）
      或 platform_admin（在 ops 后台审核）
有效期: 首次授权默认 12 个月，可续期
撤销:   farm owner 或 platform_admin 可随时撤销
通知:   授权状态变更通过 App 内消息通知双方
```

Phase 1 中 `accessibleFarmTenantIds` 仅支持 platform_admin 手动配置，无自助申请/审批流程。

### 5.4 与 App 内 `api_access` Feature Flag 的关系

```
enterprise tier App 用户:
  ├── UI 端: 全部功能 + 专属支持
  └── api_access Feature Flag 解锁:
        ├── 在"我的"页面显示 API Key（关联到该用户所在的 direct farm）
        ├── 自动获得 free tier 调用额度
        └── 可从 App 内升级到 growth/scale

api_consumer（外部第三方）:
  ├── 无 App UI
  ├── 注册时选择 api tier
  ├── 获得独立 API Key
  └── 在平台开发者门户管理
```

---

## 六、技术架构

### 6.1 分层架构图

```
┌──────────────────────────────────────────────────────────────┐
│ Flutter App                                                   │
│                                                               │
│  /twin  /map  /alerts  /fence  /mine  /ops/admin  /b2b/admin │
│   ↑owner/worker↑              ↑              ↑               │
│                            platform_admin   b2b_admin         │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ LockedOverlay + SubscriptionStatusCard (按 billingModel) │ │
│  └─────────────────────────────────────────────────────────┘ │
└──────────────────────────────────┬────────────────────────────┘
                                   │ Bearer token / API Key
┌──────────────────────────────────▼────────────────────────────┐
│ Express 5 Server                                              │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Shaping 中间件 (filter→limit→lock)    ← 业务模型无关      │ │
│  └───────────────────────┬─────────────────────────────────┘ │
│                          │ tier                               │
│  ┌───────────────────────▼─────────────────────────────────┐ │
│  │ 权限来源层                    ← 按 billingModel 分流      │ │
│  │  direct        → EntitlementStore (自助选 tier)          │ │
│  │  revenue_share → ContractStore (合同约定)                │ │
│  │  licensed      → subscriptionServiceStore (订阅服务激活)     │ │
│  │  api_usage     → ApiTierStore (API tier)               │ │
│  └───────────────────────┬─────────────────────────────────┘ │
│                          │                                    │
│  ┌───────────────────────▼─────────────────────────────────┐ │
│  │ TenantStore: partner / farm / api 三种类型               │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ 计量计费层 (Phase 2)                                     │ │
│  │  用量计量中间件 / 分润引擎 / 订阅服务管理器 / API 限流    │ │
│  └─────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

### 6.2 与现有代码的关系

| 层 | 现有模块 | 变化 |
|---|---|---|
| 路由 | `app_route.dart` | 新增 `/b2b/admin`（B端控制台） |
| Shell | `DemoShell` | b2b_admin 看到专用导航（用量看板、合同信息），无操作入口 |
| 认证 | `auth.js` | 新增 `b2b_admin`、`api_consumer` 角色 + token |
| 租户 | `tenantStore.js` | 扩展字段（type/billingModel/parentTenantId 等） |
| 租户 | `tenants.js` 路由 | 新增按 type 过滤、按 parentTenantId 查询子 tenant |
| 订阅 | `subscriptions.js`（计划中） | tier 继承逻辑（farm 从 parent partner 继承）、设备费计算 |
| 围栏/设备/告警 | 现有路由 + `auth.js` | **重点重构**：隔离维度从单一 `tenantId` 改为 farm tenant ID。引入 `farmContextMiddleware`（见下方）提取 `req.activeFarmTenantId`，Shaping 中间件使用该值查询 tier |
| 新增中间件 | `farmContextMiddleware.js` | Phase 1 实现：auth 中间件验证通过后执行，从 owner 关联的 farm 列表中取第一个（按 `createdAt` ASC）设为 `req.activeFarmTenantId`。注册顺序：auth → farmContext → shaping。Phase 2 扩展为从请求参数/session/header 中提取，支持多 farm 切换 |

**farmContextMiddleware 详细设计**：

```
// backend/middleware/farmContextMiddleware.js
// Phase 1 策略：取 owner 的第一个 farm
function farmContextMiddleware(req, res, next) {
  if (req.user.role === 'owner') {
    // Phase 1: owner 单 farm，取第一个
    const farms = tenantStore.findByOwnerId(req.user.id);
    req.activeFarmTenantId = farms.length > 0 ? farms[0].id : null;
  } else if (req.user.role === 'worker') {
    // worker: 从 user-farm 关联表取
    const assignments = workerFarmStore.findByUserId(req.user.id);
    req.activeFarmTenantId = assignments.length > 0 ? assignments[0].farmTenantId : null;
  } else {
    // platform_admin / b2b_admin / api_consumer 不需要 farm context
    req.activeFarmTenantId = null;
  }
  next();
}
```

在 server.js 中注册顺序（**三个中间件全部全局注册**，与订阅规格推荐的 per-route 注册不同——全局注册确保 `farmContextMiddleware` 执行时 `req.user` 已被 `authMiddleware` 注入，避免 per-route 混用时 `req.user.role` 抛出异常）：

```
app.use(authMiddleware);           // 1. 认证 + 注入 req.user（全局）
app.use(farmContextMiddleware);    // 2. 提取 activeFarmTenantId（全局）
app.use(shapingMiddleware);        // 3. 用 activeFarmTenantId 查 tier（全局）
```

注意：`shapingMiddleware` 全局注册时仅包装 `res.ok()` 方法，实际的 shaping 逻辑（filter→limit→lock）延迟到路由处理函数调用 `res.ok(data)` 时才执行——此时 per-route 的 feature key 中间件已设置完毕 `req.routeFeatureKeys`，shaping 可正确读取 tier 和 feature key 完成功能门控。

**附加变化**：

| 层 | 现有模块 | 变化 |
|---|---|---|
| API 前缀 | 所有路由 | 新增 `/api/v1/*` 前缀（保持 `/api/*` 兼容，两者并存）。Open API 使用独立 `/api/open/v1/*` 前缀。`ApiCache` 预加载列表需同步更新 |
| Shaping 中间件 | `feature-flag.js`（计划中） | 核心逻辑不改。新增：读取 `req.activeFarmTenantId` 调用 `getEffectiveTier()` 查询 tier。device_gate 在路由处理函数中实现（Section 4.1.1），不在 Shaping 中间件中 |

**Store 关系说明**：Section 6.1 架构图中的 `EntitlementStore` 即当前订阅计划中的 `subscriptions.js` / `subscriptionStore` 的扩展版本。`subscriptionStore` 的既有函数（`createTrial`、`getByTenantId`、`checkout`、`cancel`、`renew`）保留，但扩展为支持 `billingModel` 参数。`EntitlementStore` 在 Phase 1 仅实现 `direct` 分支（等价于当前 subscriptionStore 功能），`ContractStore` / `subscriptionServiceStore` / `ApiTierStore` 在 Phase 1 仅定义接口框架（返回静态数据），Phase 2 实现完整逻辑。

---

## 七、分阶段落地路径

### Phase 1：统一基础设施

- tenant 数据模型扩展：仅新增 Phase 1 通用字段（`type`, `parentTenantId`, `billingModel`, `entitlementTier`, `ownerId`）。Phase 2 专用字段（`contractId`, `revenueShareRatio`, `serviceKey`, `heartbeatAt` 等）推迟
- 角色体系升级：新增 `b2b_admin`、`api_consumer` 角色；保留 `ops` 名称（`ops → platform_admin` 改名推迟至 Phase 2）
- 订阅模型拆分（设备月费 + tier 月费）
- B2C 完整链路可用
- B2B2C 数据模型就绪（接口预留，partner/api tenant 可创建但 ContractStore/subscriptionServiceStore/ApiTierStore 仅静态数据）
- **owner 多 farm 约束**：Phase 1 明确声明 `ownerId` 唯一约束（一个 owner 只能绑定一个 farm tenant），后端 API 通过 `farmContextMiddleware` 提取单一 farm。多 farm 支持推迟至 Phase 2
- **不在 Phase 1**：多牧场切换 UI、跨 farm 聚合视图、B端管理后台（b2b_admin UI）、API 开放平台端点
- **b2b_admin Phase 1 降级方案**：b2b_admin 角色可在 Phase 1 登录（用于后端认证调试），但前端 `/b2b/admin` 路由显示"功能开发中，敬请期待"页面。该页面的基础 Shell（含退出登录）与 `platform_admin` 后台一致，但不展示任何数据管理功能

### Phase 2：B2B2C 核心能力

- B端管理后台（子用户管理 + 用量看板 + 合同信息）
- 分润引擎 + 对账看板
- 订阅服务激活 + 心跳监控
- API 开放平台上线

### Phase 3：精细化与合规

- 海外合规（本地收款→跨境结算）
- 数据审计接口
- 订阅服务安全加固
- 多租户部署隔离

---

## 八、可复用资产

以下资产在三种商业模型间完全共享：

| 资产 | 来源 | 复用范围 | 改动 |
|---|---|---|---|
| Feature Flag 定义（20 个 key） | 订阅服务 | 三种模型共享 | 小改：每 key 新增 `requiredDevices` 字段（订阅规格 `feature-flags.js` schema 需同步添加此字段，映射关系见本规格 Section 4.1.1 device_gate 规则表） |
| Shaping 中间件（filter→limit→lock） | 订阅服务 | 三种模型共享 | 不改 |
| LockedOverlay 组件 | 订阅服务 | 三种模型共享 | 不改 |
| SubscriptionRenewalBanner | 订阅服务 | 三种模型共享 | 不改 |
| SubscriptionExpiryDialog | 订阅服务 | 三种模型共享 | 不改 |
| tenantStore CRUD | 租户管理 | 三种模型共享 | 扩展字段 |
| ops 管理后台页面 | 租户管理 | 平台级租户管理 | 不改 |
| REST API 包络+分页 | 租户管理 | 所有新端点复用 | 不改 |
| Repository/Controller 模式 | 两模块共享 | 所有新模块遵循 | 不改 |
| requirePermission 中间件 | auth | 扩展 b2b_admin 权限集 | 中 |
| ApiCache 预加载 | 两模块共享 | 扩展新端点缓存 | 小 |
| applyMockShaping() | 订阅服务 | Mock 模式三种模型共享 | 不改 |

可复用比例：约 60% 代码完全共享，20% 需小改，20% 需新建。

---

**文档结束**
