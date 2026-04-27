# 智慧畜牧系统统一商业模型设计

> **文档编号**: SL-BIZ-2026-001
> **版本**: v1.0
> **编制日期**: 2026-04-28
> **状态**: 草案
> **受众**: 产品经理 + 技术团队
> **关联文档**:
> - 订阅服务设计规格: `docs/superpowers/specs/2026-04-24-subscription-service-design.md`
> - 订阅服务实施计划: `docs/superpowers/plans/2026-04-27-subscription-service-implementation.md`
> - 商业模式评审报告: `docs/superpowers/reviews/2026-04-28-subscription-service-plan-review.md`
> - 机器学习需求说明书: `docs/2026-04-27-机器学习需求说明书.md`

---

## 概述

本设计文档定义智慧畜牧系统的统一商业模型，同时支撑三种商业通道：

| 通道 | 计费方 | 付费方 | 计费方式 |
|---|---|---|---|
| B2C 直订阅 | 平台 | 牧场主 | 设备月费 + tier 月费 |
| B2B 云托管分润 | B端客户 | B端客户的最终用户 | 设备月费 + tier 月费，平台按合同比例分润 |
| B2B 独立部署 | 平台 | B端客户 | License 年费（含设备和 tier） |

核心设计原则：**tenant 统一为"付钱给我们的实体"**，而非"牧场运营单元"。

---

## 一、核心实体定义

| 实体 | 定义 | 对应角色 | 计费关系 |
|---|---|---|---|
| **平台** | 我们 | `platform_admin` (原 ops) | — |
| **B端客户** | 合作商/代理商，和我们签合同 | `b2b_admin`（新增） | 按旗下牧场主实付订阅费 × 合同分润比，和我们分账 |
| **牧场主** | 养殖户，B端客户发展的最终用户 | `owner`（保留） | 按牛数 × 设备月费向 B端客户付费。可拥有多个牧场 |
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

```
// === 层级关系 ===
type: 'partner' | 'farm' | 'api',    // 默认 'farm'（兼容现有种子数据）
parentTenantId: string | null,       // farm 归属哪个 partner

// === 商业模式 ===
billingModel: 'direct' | 'revenue_share' | 'licensed' | 'api_usage',

// === partner 专用 ===
contractId: string | null,
revenueShareRatio: float | null,      // 分润比例，如 0.15

// === licensed partner 专用 ===
deploymentType: 'cloud' | 'on_premise' | null,
licenseKey: string | null,
heartbeatAt: datetime | null,

// === api 专用 ===
apiTier: 'free' | 'growth' | 'scale' | null,
apiKey: string | null,
apiCallQuota: int | null,             // 月调用量上限

// === farm 专用 ===
ownerId: string | null,               // 牧场主 user id
```

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
| `owner`（保留） | 自己的 1~N 个 farm | /twin（App 主页） | 自己 farm 的牛/设备/围栏/告警 |
| `worker`（保留） | 被分配到的 farm(s) | /twin | 分配到的 farm，权限受订阅 tier 限制 |
| `api_consumer`（新增） | 自己的 api tenant | 无 UI（仅 API） | 无，纯接口调用 |

### 3.2 绑定关系

```
platform_admin  → tenantId = null（看全部）
b2b_admin       → tenantId = partner tenant id
owner           → 不绑定 tenant，而是 ownerId 字段（可跨 farm）
worker          → 关联表：{ userId, farmTenantId }
api_consumer    → tenantId = api tenant id
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
| `auth.js` 中间件 | 新增 `b2b_admin`、`api_consumer` 角色，`requirePermission` 扩展权限集 |
| `users` 种子数据 | 新增 b2b_admin 和 api_consumer 示例用户 |
| `TOKEN_MAP` | 新增 `mock-token-b2b-admin`、`mock-token-api-consumer` |
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
  └── 消化健康             → health_score

GPS + 胶囊（双配）:
  ├── 上述全部
  ├── 发情检测             → estrus_detect
  ├── 个体健康评分         → health_score（需多传感器融合）
  └── 疫病预警             → epidemic_alert

无设备:
  └── 基础档案管理         → livestock_detail, device_management
```

### 4.2 三层计费结构

#### Layer 1: 设备月费

计费单元：每头牛 × 佩戴的设备

- GPS 追踪器: ¥c /牛/月
- 瘤胃胶囊: ¥d /牛/月
- farm 总费用 = ∑(每头牛的设备配置月费)

面向所有 farm tenant，用途：B2C 散户直接付平台 / B2B 牧场主付 B端客户。

#### Layer 2: 订阅 Tier

在设备月费之上叠加的增值功能：

| Tier | 月费 | 设备费之外包含的服务 |
|---|---|---|
| basic | ¥0 | 基础版（设备月费单独算） |
| standard | ¥299 | 历史轨迹 + 告警历史 |
| premium | ¥699 | 健康评分 + 发情 + 疫病 |
| enterprise | 定制 | 全部 + API 访问 + 专属支持 |

Tier 绑定于 partner tenant 或 direct farm tenant。非 direct 模式的 farm 继承 parent partner 的 tier。

注意：premium 及以上 tier 包含的 ML 功能（健康评分、发情检测、疫病预警）需要双配设备数据才能实际生效。数据不满足条件时，前端显示"需要安装瘤胃胶囊"而非"升级套餐"。

#### Layer 3: API 增值

独立于设备费，按 API 调用量计费：

| Tier | 月调用配额 | 超出单价 | 开放端点 |
|---|---|---|---|
| free (捆绑 enterprise) | 1,000 calls | 不可超出 | /twin/* 只读 |
| growth (¥500/月) | 10,000 calls | ¥0.01/call | 全部 twin |
| scale (¥2,000/月) | 100,000 calls | ¥0.005/call | 全部 + 写入 |

面向 api tenant（外部第三方）。enterprise App 用户通过 Feature Flag `api_access` 获得 free tier。

### 4.3 三种商业模式下的计费路径

| | B2C 直订阅 | B2B 云托管分润 | B2B 独立部署 |
|---|---|---|---|
| 谁付设备月费？ | 牧场主 → 平台 | 牧场主 → B端客户 | B端客户 → 平台（License 一口价含设备） |
| 谁付订阅 Tier？ | 牧场主 → 平台 | B端客户 → 平台（enterprise 合同价） | B端客户 → 平台（License 年费含 tier） |
| 平台收入来源 | 设备月费 + tier 月费 | B端客户 enterprise 合同费 + 分润 | License 年费 |
| 谁选 tier？ | 牧场主自主 | B端客户（旗下 farm 统一） | B端客户（License 捆绑） |
| API 增值 | enterprise tier 含 free API | B端客户可额外开通 API tier | 可额外开通 |

### 4.4 对当前订阅规格的影响

| 原规格内容 | 变化 |
|---|---|
| 四层 tier（basic/standard/premium/enterprise） | 保留，语义扩展：tier 是"增值服务层"，设备费独立计算 |
| 混合计费（基础月费 + 牲畜阶梯加价） | 拆分为两条公式：设备月费 = ∑(牛 × 设备配置单价)；tier 月费 = 固定月费 |
| tier 绑定 tenant | partner/direct 类型 tenant 绑定 tier，farm 类型继承 parent |
| Feature Flag 定义（20 个 key） | 新增设备依赖约束 |
| 价格展示 | direct 模式显示价格；非 direct 模式显示"由经销商管理" |
| 试用机制 | 仅 direct farm 新注册时触发；partner 下 farm 由 B端客户决定 |

---

## 五、开放平台 API

### 5.1 端点分类

| 类别 | 前缀 | 示例 | 认证方式 |
|---|---|---|---|
| App API（内部） | `/api/v1/*` | `/api/v1/twin/overview` | Bearer token（用户登录态） |
| Open API（对外） | `/api/open/v1/*` | `/api/open/v1/twin/fever/predict` | `X-API-Key` header |

两套端点调用相同底层服务，接口契约、限流、鉴权独立。

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

| 授权模式 | 描述 | 实现 |
|---|---|---|
| 自有数据 | 保险公司自己买了胶囊设备给牛戴 → 查自己的数据 | `api_consumer` 绑定自己的 `api tenant`，只能查关联的 farm |
| 平台全量（受限） | 政府畜牧部门 → 查脱敏统计 | `api tenant` 无关联 farm，只能调聚合统计端点 |
| B端客户代调 | 代理商调用旗下牧场数据 | `b2b_admin` 用 Bearer token 直接调 App API，不走 Open API |

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
│  │  licensed      → LicenseStore (License 激活)            │ │
│  │  api_usage     → ApiTierStore (API tier)               │ │
│  └───────────────────────┬─────────────────────────────────┘ │
│                          │                                    │
│  ┌───────────────────────▼─────────────────────────────────┐ │
│  │ TenantStore: partner / farm / api 三种类型               │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ 计量计费层 (Phase 2)                                     │ │
│  │  用量计量中间件 / 分润引擎 / License 管理器 / API 限流    │ │
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
| 围栏/设备/告警 | 现有路由 | 隔离维度从 tenantId 改为 farm tenantId |
| Shaping 中间件 | `feature-flag.js`（计划中） | 不改，数据驱动 |

---

## 七、分阶段落地路径

### Phase 1：统一基础设施

- tenant 数据模型扩展（type/billingModel/parentTenantId）
- 角色体系升级（platform_admin/b2b_admin/owner/worker/api_consumer）
- 订阅模型拆分（设备月费 + tier 月费）
- B2C 完整链路可用
- B2B2C 数据模型就绪（接口预留）

### Phase 2：B2B2C 核心能力

- B端管理后台（子用户管理 + 用量看板 + 合同信息）
- 分润引擎 + 对账看板
- License 激活 + 心跳监控
- API 开放平台上线

### Phase 3：精细化与合规

- 海外合规（本地收款→跨境结算）
- 数据审计接口
- License 安全加固
- 多租户部署隔离

---

## 八、可复用资产

以下资产在三种商业模型间完全共享：

| 资产 | 来源 | 复用范围 | 改动 |
|---|---|---|---|
| Feature Flag 定义（20 个 key） | 订阅服务 | 三种模型共享 | 不改 |
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
