# 统一商业模型 Phase 2b 设计规格

> **文档编号**: SL-BIZ-2026-003
> **版本**: v1.3
> **编制日期**: 2026-05-02
> **修订日期**: 2026-05-03
> **状态**: 已实现（G2 开发者门户进行中）
> **受众**: 产品经理 + 技术团队
> **评审报告**: `docs/superpowers/reviews/2026-05-02-unified-business-model-phase2b-review-r2.md`
> **前置文档**:
> - `docs/superpowers/specs/2026-04-28-unified-business-model-design.md` (v1.3) — 父规格
> - `docs/superpowers/specs/2026-04-29-unified-business-model-phase2a-design.md` (v1.3) — Phase 2a 规格
> **前置计划**: `docs/superpowers/plans/2026-04-29-unified-business-model-phase2a.md`（Phase 2a 已完成）
> **修订记录**:
> - v1.3 (2026-05-03): Post-Phase-2b UX 优化与功能修复：B2B admin 4 页面重写（概览/对账/合同/牧工管理）、新建牧场功能（ApiCache+Repository+Controller+表单对话框）、对账数据修复（后端 seed 自动生成周期 + ApiCache 预加载 + fromJson 字段映射）、对账三态 UI（confirmed/partially_confirmed/pending）+ 实时确认（confirm 调真实 API + 缓存刷新）
> - v1.2 (2026-05-02): 按 R2 评审报告修复 P1-R2-1~P1-R2-4（auth.js 匹配策略、分润公式设备配置维度、heartbeat 白名单路径、validate() 歧义消除）+ P2-R2-1~P2-R2-5（Mock 登录流程、twin 数据源 farmTenantId、定时器启动恢复、依赖关系图 G2 位置、vitest 配置）
> - v1.1 (2026-05-02): 按评审报告修复 P0-1~P0-4（设备单价、heartbeat 认证白名单、validate() 跨 Store 查询、中间件架构）+ P1-1~P1-7（同步时机、workerRoutes 文件列表、默认值策略、seed 数据统一、开发者门户目录、多 farm 过滤、删除 LoginPage api_consumer）+ P2-2/P2-5（货币单位、tenant_p002 旗下 farm）
> - v1.0 (2026-05-02): 初稿

---

## 概述

Phase 2b 是统一商业模型 Phase 2 的第二个子阶段，完成 B2B2C 全部核心能力和 API 开放平台上线。

### 交付清单（7 大模块）

| Epic | 名称 | 类型 |
|------|------|------|
| E4 | 分润引擎 + 对账看板 | 新功能 |
| E5 | 订阅服务管理（独立部署客户） | 新功能 |
| E6 | 合同 CRUD（platform_admin 后台） | 扩展 |
| E7 | b2b_admin 旗下 worker 管理 | 扩展 |
| E8 | Phase 2 专用字段落地 | 基础设施 |
| E9 | Store 真实化 | 基础设施 |
| G1 | Open API 端点 `/api/open/v1/*` | 新功能 |
| G2 | 开发者门户（Vue 3 SPA） | 新前端项目 |
| G3 | API 数据访问授权审批流程 | 新功能 |

### 依赖关系

```
E8 (字段落地)
  ├── E9 (Store 真实化)
  │     ├── E4 (分润引擎)
  │     ├── E5 (订阅服务管理)
  │     ├── E6 (合同 CRUD)
  │     └── G1 (Open API 端点)
  │           ├── G3 (授权审批)
  │           └── G2 (开发者门户，依赖 G1 端点就绪)
  └── E7 (b2b worker 管理，仅依赖 E8 中已有的 parentTenantId 字段（Phase 2a 已有），不依赖 E9，因现有 workerRoutes.js 直接读 tenantStore)
```

E8 须先行（字段定义是其余模块的基础）。E9 依赖 E8（Store 引用新字段）。E4/E5/E6/G1 可并行。E7 仅依赖 E8 中已有的 `parentTenantId` 字段（Phase 2a 已有），不依赖 E9（现有 workerRoutes.js 直接读取 tenantStore）。G2 依赖 G1 端点就绪。G3 依赖 G1 数据模型。

---

## E4: 分润引擎 + 对账看板

### 4.1 分润计算模型

**计费方**：平台。**付费方**：B端客户（按合同分润比）。**计费方式**：设备月费 + tier 月费，平台按合同比例分润。

**计算方式**：按月汇总。每月 1 日自动结算上月。

**设备配置单价**（Mock 环境占位值，与父规格端到端计费示例一致）：

| 设备类型 | 单价 |
|---------|------|
| GPS 追踪器 | ¥15/牛/月 |
| 瘤胃胶囊 | ¥30/牛/月 |

```
partner 旗下所有 farm 月设备费 = ∑(每个 farm 的牛数 × 该 farm 设备配置单价)
分润金额 = partner 旗下所有 farm 月设备费 × revenueShareRatio
```

**设备配置单价说明（Phase 2b 简化模型）**：每头牛的设备配置单价由 farm 级别的**设备配置比例**估算。例如某 farm 有 100 头牛，其中 70% 佩戴 GPS（¥15/月）、30% 佩戴胶囊（¥30/月），则该 farm 的设备配置单价 = 0.7×15 + 0.3×30 = ¥19.5/牛/月。Farm 设备配置比例从 seed 数据中读取（见 9.4 seed 中 `deviceConfigRatio` 字段）。按牛维度的精确设备配置（每头牛的实际佩戴）留到后续阶段实现。

所有金额单位统一为**元**。

**架构预留**：`revenueStore.calculate()` 接口接受 `mode: 'monthly' | 'realtime'`，Phase 2b 仅实现 `'monthly'`，phase 2c 再实现 `'realtime'`。

### 4.2 数据模型

```
RevenuePeriod（结算周期）:
  id, partnerTenantId, period ("2026-05"),
  status: 'pending' | 'calculated' | 'confirmed' | 'settled',
  totalDeviceFee: number,        // 旗下所有 farm 月设备费合计（单位：元）
  revenueShareRatio: float,      // 快照当时合同分润比（如 0.15）
  revenueShareAmount: number,    // 分润金额 = totalDeviceFee × ratio（单位：元）
  confirmedByPlatform: bool,     // 平台确认
  confirmedByPartner: bool,      // B端客户确认
  calculatedAt, confirmedAt, settledAt

前端三态显示模型（b2b_revenue_page.dart）：
  'confirmed'             → 已结算（绿色）  — settled 或双方都确认
  'partially_confirmed'   → 已确认（蓝色）  — 仅一方确认
  'pending'               → 待确认（橙色）  — 双方都未确认
  RevenuePeriod.fromJson 根据 confirmedByPlatform + confirmedByPartner 映射到三态。```

RevenueFarmItem（单 farm 明细）:
  id, revenuePeriodId, farmTenantId, farmName,
  livestockCount,                // 结算时的牛数快照
  deviceConfigRatio: {           // 设备配置比例快照（来自 seed）
    gpsRatio: float,             //   GPS 占比（如 0.7）
    capsuleRatio: float          //   胶囊占比（如 0.3）
  },
  deviceFee: number,             // 该 farm 月设备费 = livestockCount × (gpsRatio×15 + capsuleRatio×30)，单位：元
  shareAmount: number            // deviceFee × ratio（单位：元）
```

### 4.3 端点设计

| 端点 | 方法 | 说明 | 权限 |
|------|------|------|------|
| `/api/v1/revenue/periods` | GET | 结算周期列表（分页，支持 `?partnerId=` 过滤） | platform_admin, b2b_admin |
| `/api/v1/revenue/periods/:id` | GET | 单周期详情 + farm 明细 | platform_admin, b2b_admin |
| `/api/v1/revenue/periods/:id/confirm` | POST | 确认对账 | platform_admin, b2b_admin |
| `/api/v1/revenue/calculate` | POST | 手动触发月结算（body: `{ period }`） | platform_admin |

**数据隔离**：platform_admin 看全局，b2b_admin 仅看 `partnerTenantId === 自己 tenantId` 的周期。

**对账确认逻辑**：双方各自点击确认后设置对应 `confirmedBy*` 字段。双方都确认后 status → `'settled'`。全透明：双方看到相同的对账数据。

**前端确认链路**（Live 模式）：`RevenueController.confirmPeriod()` → `LiveRevenueRepository.confirmPeriod()` → `ApiCache.confirmRevenuePeriodRemote('b2b_admin', periodId)` (POST API) → `ApiCache.refreshRevenuePeriods('b2b_admin')` (GET 刷新缓存) → Controller 刷新 UI。

### 4.4 对账看板 UI

**platform_admin 后台**（新增"对账看板"子页面）：
- 全局结算周期列表（三态状态标签：已结算/已确认/待确认）
- 点击进入详情（各 partner 分润汇总表 + 手动触发结算按钮）
- 确认对账按钮（确认后实时刷新列表）

**b2b_admin 端**（侧边栏第 4 个导航项"对账"）：
- 仅显示自己 partner 的周期
- 详情页 + 确认对账按钮
- 确认后实时刷新列表（`confirmPeriod` 调用 `POST /revenue/periods/:id/confirm`，成功后 `refreshRevenuePeriods` 更新缓存）
- 三态状态标签：已结算（绿色）/ 已确认（蓝色）/ 待确认（橙色）
- 筛选：全部 / 待确认 / 已结算
- 指标卡片：累计分润 / 待确认数 / 已结算数
- 数据与 platform_admin 一致（全透明）

### 4.5 seed 数据

```javascript
// server.js 启动时自动生成 revenue 周期（不再为空）：
const revenueStore = require('./data/revenueStore');
['2026-01', '2026-02', '2026-03', '2026-04'].forEach((p) => {
  revenueStore.calculate(p, 'monthly');
});
// 2026-01, 2026-02: 双方确认 → settled
['2026-01', '2026-02'].forEach((period) => {
  const periods = revenueStore.getPeriods({}).items;
  const match = periods.find(p => p.period === period);
  if (match) {
    revenueStore.confirm(match.id, 'platform_admin', null);
    revenueStore.confirm(match.id, 'b2b_admin', 'tenant_p001');
  }
});
// 2026-03: 仅平台预确认（b2b_admin 可手动确认使其 settled）
{
  const periods = revenueStore.getPeriods({}).items;
  const match = periods.find(p => p.period === '2026-03');
  if (match) { revenueStore.confirm(match.id, 'platform_admin', null); }
}
// 2026-04: pending（双方都未确认）
```

**ApiCache 预加载**：b2b_admin 初始化时 `GET /revenue/periods` 获取数据存入 `_revenue` 缓存，LiveRevenueRepository 从缓存读取。

---

## E5: 订阅服务管理

> 命名说明：避免与未来 IoT 设备 License 管理重名，本模块管理的是**独立部署客户的平台订阅服务激活和生命周期**。

### 5.1 生命周期

```
创建订阅服务
  → 分配给 licensed partner tenant
  → tenant.deploymentType = 'on_premise' | 'cloud'
  → 激活（首次心跳到达）
    → 运行中（每 24h 心跳）
      → 心跳中断 → 宽限期（15 天，通知 platform_admin，前端显示"即将过期"）
        → 宽限期内恢复 → 正常运行
        → 宽限期过期 → 降级为基础版
  → 续期 / 吊销 / 到期
```

### 5.2 数据模型（subscriptionServiceStore）

```
SubscriptionService:
  id, partnerTenantId,
  serviceKey: string,              // 格式 SL-SUB-XXXX-XXXX，仅生成时返回一次
  keyHash: string,                 // SHA-256 哈希，用于存储和验证
  status: 'active' | 'grace_period' | 'degraded' | 'revoked' | 'expired',
  effectiveTier: 'standard' | 'premium' | 'enterprise',
  deviceQuota: int,                // 设备数上限
  activatedAt,                     // 首次激活时间
  lastHeartbeatAt,                 // 最近心跳时间
  heartbeatIntervalHours: 24,
  gracePeriodDays: 15,
  degradedAt,
  expiresAt,
  createdAt, revokedAt
```

**安全存储**：仅存储 `keyHash`（SHA-256），原始 `serviceKey` 仅生成时一次性返回。

**tenant 模型同步**：`tenant.serviceKey` 存储哈希（与 subscriptionServiceStore.keyHash 同步），`tenant.heartbeatAt` 存储最近心跳时间（与 subscriptionServiceStore.lastHeartbeatAt 同步）。

### 5.3 端点设计

| 端点 | 方法 | 说明 | 权限 |
|------|------|------|------|
| `/api/v1/subscription-services` | GET | 列表（分页，按 partner 过滤） | platform_admin |
| `/api/v1/subscription-services` | POST | 创建，body: `{ partnerTenantId, effectiveTier, expiresAt, deviceQuota }` | platform_admin |
| `/api/v1/subscription-services/:id` | GET | 详情 + 心跳状态 | platform_admin |
| `/api/v1/subscription-services/:id/renew` | POST | 续期，更新 expiresAt | platform_admin |
| `/api/v1/subscription-services/:id/revoke` | POST | 吊销 | platform_admin |
| `/api/v1/subscription-services/heartbeat` | POST | 独立部署实例发送心跳 | 无需 Bearer token（凭 serviceKey），见下方认证说明 |

**认证例外说明**：heartbeat 端点不要求 Bearer token。需在 `auth.js` 的 `PUBLIC_PATHS` 中添加 `'/subscription-services/heartbeat'`（当前 `endsWith` 匹配策略对该后缀路径天然生效——请求路径如 `/api/v1/subscription-services/heartbeat`，其 `req.path` 的结尾精确匹配该后缀）。如未来改为 Router 内部注册（Express Router 内部 `req.path` 为去掉挂载前缀后的路径，则需依实际路径调整）。认证逻辑移至路由处理函数内部（通过 serviceKey hash 验证）。

### 5.4 心跳端点详细设计

```
POST /api/v1/subscription-services/heartbeat
Request:  { serviceKey, instanceId, version, cattleCount, deviceCount }
Response: {
  status: 'ok' | 'grace_period' | 'degraded' | 'expired' | 'revoked',
  tier: 'standard' | 'premium' | 'enterprise' | 'basic',
  message: null | '宽限期内，还有 N 天恢复' | '订阅服务已过期，请联系续期'
}
```

**后端心跳处理逻辑**：

1. 查找 serviceKey → 验证 hash
2. 更新 `lastHeartbeatAt`
3. 若当前 status = `'degraded'` → 自动恢复为 `'active'`（恢复心跳自动复原），同步 `tenant.entitlementTier` 为原 tier
4. 检查是否宽限期过期：status = `'grace_period'` 且 `now - lastHeartbeatAt > gracePeriodDays` → status → `'degraded'`，`tenant.entitlementTier` → `'basic'`
5. 后台定时扫描（Mock: `setInterval` 60s）：所有 status = `'active'` 的记录，若 `now - lastHeartbeatAt > heartbeatIntervalHours` → status → `'grace_period'`，通知 platform_admin。**启动恢复**：server 启动时立即执行一次全量扫描（处理"重启前已超时但因进程终止未触发状态变更"的记录），随后启动 setInterval 定时器。同理 apiKeyStore 的 24h 轮换撤销也在启动时执行一次扫描。

### 5.5 前端 UI

**platform_admin 后台**（新增"订阅服务管理"子页面）：
- 列表页：状态标签（active/宽限/已降级/已吊销/已过期）+ 心跳状态指示
- 创建表单：选择 partner tenant + tier + 到期日 + 设备配额
- 详情页 → 续期/吊销按钮
- 心跳实时状态 + 最近心跳时间

**b2b_admin 端**：合同页面展示订阅服务状态（仅 licensed 模式的 partner 可见），只读。

---

## E6: 合同 CRUD

### 6.1 ContractStore 扩展

Phase 2a 中 ContractStore 仅有只读 `getByPartnerTenantId()`。Phase 2b 新增写操作：

```
Contract:
  id, partnerTenantId,
  status: 'active' | 'suspended' | 'expired',
  effectiveTier: 'standard' | 'premium' | 'enterprise',
  revenueShareRatio: float,
  startedAt, expiresAt, signedBy,
  createdAt, updatedAt, terminatedAt
```

新增方法：`create()` / `update()` / `terminate()` / `list()`。

**数据所有权**：`revenueShareRatio` 以 ContractStore 为权威来源。tenant 模型的 `revenueShareRatio` 和 `contractId` 字段在合同创建/更新时同步写入（只读快照）。Mock 环境中所有 Store 为内存对象，同步是即时的——contractStore 修改后 tenant 快照在同一请求中更新，b2b_admin 通过 `GET /b2b/contract/current` 下次请求获取最新值。

### 6.2 端点设计

| 端点 | 方法 | 说明 | 权限 |
|------|------|------|------|
| `/api/v1/contracts` | GET | 合同列表（分页，支持 `?partnerId=` `?status=` 过滤） | platform_admin |
| `/api/v1/contracts` | POST | 创建合同，body: `{ partnerTenantId, effectiveTier, revenueShareRatio, expiresAt, signedBy }` | platform_admin |
| `/api/v1/contracts/:id` | GET | 合同详情 | platform_admin, b2b_admin |
| `/api/v1/contracts/:id` | PUT | 编辑合同（续签/变更分润比等） | platform_admin |
| `/api/v1/contracts/:id/terminate` | POST | 终止合同 | platform_admin |
| `/api/v1/b2b/contract/current` | GET | 当前 b2b_admin 自己的合同（保留 Phase 2a 端点） | b2b_admin |
| `/api/v1/b2b/contract/usage-summary` | GET | 用量汇总（保留 Phase 2a 端点） | b2b_admin |

### 6.3 前端 UI

**platform_admin 后台**（新增"合同管理"子页面）：
- 列表页：状态筛选（active/suspended/expired）
- 创建/编辑表单：选择 partner + tier + 分润比 + 到期日 + 签约人
- 详情页 + 终止操作

**b2b_admin 端**：合同页升级为可查看详情（数据来源从 `/api/v1/b2b/contract/current` 扩展到 `/api/v1/contracts/:id`），显示更多字段。

---

## E7: b2b_admin 旗下 worker 管理

### 7.1 权限扩展

Phase 2a 中 `/api/v1/farms/:farmId/workers` 端点权限仅限 owner 和 platform_admin。Phase 2b 扩展到 b2b_admin。

**权限校验逻辑变更**（修改 `backend/routes/workerRoutes.js` 的 `canManageFarm()` 函数）：

```
role === 'owner'          → 检查 farm.ownerId === userId
role === 'b2b_admin'      → 检查 farm.parentTenantId === user.tenantId   // 新增
role === 'platform_admin' → 不限制
```

**涉及文件**：

| 文件 | 改动 |
|------|------|
| `backend/routes/workerRoutes.js` | `canManageFarm()` 新增 `b2b_admin` 分支（当前仅检查 `platform_admin` 和 `owner`） |

### 7.2 B端侧边栏扩展

b2b_admin 侧边栏从 Phase 2a 的 3 项扩展到 5 项：

```
概览 → 牧场管理 → 合同信息 → 对账（E4 新增）→ 牧工管理（E7 新增）
```

### 7.3 牧工管理 UI

- 点击"牧工管理"导航项 → 显示旗下 farm 列表
- 点击某 farm → 进入该 farm 的 worker 列表（复用 Phase 2a WorkerListPage 组件）
- 支持分配/移除操作
- **不在 E7 范围**：b2b_admin 创建新 worker 用户账号（需用户注册能力，留到后续阶段）

### 7.4 权限点扩展

seed.js 中 b2b_admin 的 permissions 新增 `'worker:manage'`（仅限旗下 farm）。

### 7.5 新建牧场功能（Post-Phase-2b 新增）

b2b_admin 可在"旗下牧场"页面新建牧场：

**后端**：复用 `POST /api/v1/b2b/farms`（Phase 2a 已实现），body: `{ name, ownerName?, contactPhone?, region? }`。

**前端实现链路**：
1. `ApiCache.createB2bFarmRemote()` — POST `/b2b/farms`，成功后 GET `/b2b/dashboard` 刷新缓存
2. `B2bRepository.createFarm()` — mock/live 双路径，mock 模式追加到 `_mockCreatedFarms` 列表
3. `B2bDashboardController.createFarm()` — 调 repo 成功后 `ref.invalidateSelf()` 刷新页面
4. `B2bFarmListPage` — ConsumerStatefulWidget，新建牧场对话框（4 字段表单 + 验证 + loading 状态）

**表单字段**：牧场名称（必填）、负责人（可选）、联系电话（可选）、所在地区（可选）。

---

## E8: Phase 2 专用字段落地

### 8.1 tenant 模型字段补全

父规格 Section 2.2 定义的所有 Phase 2 字段在 Phase 2b 落地。

**现有 tenant 默认值策略**：所有新字段默认为 `null`（非 farm 类型的 tenant 不适用这些字段）。`tenantStore.createTenant()` 需扩展参数以接受新字段。

**字段补全清单**：

```
// === partner 专用 ===
contractId: string | null,            // 关联合同 ID
revenueShareRatio: float | null,      // 分润比例快照（contractStore 为权威来源）

// === licensed partner 专用 ===
deploymentType: 'cloud' | 'on_premise' | null,
serviceKey: string | null,            // 订阅服务密钥哈希（subscriptionServiceStore 为权威来源）
heartbeatAt: datetime | null,         // 最近心跳时间

// === api 专用 ===
apiTier: 'free' | 'growth' | 'scale' | null,
apiKey: string | null,                // API Key 哈希（apiKeyStore 为权威来源）
apiCallQuota: int | null,             // 月调用量上限
accessibleFarmTenantIds: string[] | null,  // 可访问的 farm tenant 列表
```

### 8.2 数据所有权约定

| 字段 | 权威来源 | tenant 字段角色 | 同步时机 |
|------|---------|---------------|---------|
| `revenueShareRatio` | contractStore | 只读快照 | 合同创建/更新时同步 |
| `serviceKey` | subscriptionServiceStore | 仅存哈希 | 订阅服务创建/更新时同步 |
| `heartbeatAt` | subscriptionServiceStore | 心跳时间镜像 | 每次心跳到达时同步 |
| `apiKey` | apiKeyStore | 仅存哈希 | Key 生成/轮换时同步 |
| `apiCallQuota` | apiTierStore | tier 配额镜像 | tier 变更时同步 |
| `accessibleFarmTenantIds` | 审批记录 | 授权列表 | 审批通过/撤销时同步 |

### 8.3 tenantStore 扩展

新增查询方法：

| 方法 | 说明 |
|------|------|
| `findByServiceKey(keyHash)` | 按订阅服务 Key 哈希查找 |
| `findByApiKey(keyHash)` | 按 API Key 哈希查找 |
| `findByParentTenantId(id)` | 已有（Phase 2a），保持不变 |
| `updateTenantField(id, field, value)` | 通用字段更新（供 Store 同步使用） |

---

## E9: Store 真实化

### 9.1 各 Store 演进

| Store | Phase 2a 状态 | Phase 2b 新增能力 |
|-------|--------------|-----------------|
| `contractStore` | 只读 `getByPartnerTenantId()` | `create()` / `update()` / `terminate()` / `list()` |
| `subscriptionServiceStore` | 不存在 | 完整 CRUD + 心跳处理 + 状态扫描 |
| `apiTierStore` | 不存在 | tier 查询 + 配额校验 + 用量追踪 |
| `apiKeyStore` | 不存在 | Key 生成/轮换/撤销/验证、同时持有 2 Key 24h 过渡 |
| `revenueStore` | 不存在 | 结算周期 CRUD + 确认 + 手动触发结算 |

### 9.2 apiKeyStore 详细设计

```
ApiKey:
  id, apiTenantId,
  keyHash: string,                   // SHA-256 哈希
  keyPrefix: string,                 // sl_apikey_ 前缀（用于 UI 展示）
  keySuffix: string,                 // 后 4 位明文（用于 UI 识别）
  status: 'active' | 'rotating' | 'revoked',
  createdAt, rotatedAt, revokedAt

方法:
  generate(apiTenantId)              // 生成新 Key，返回原始 Key（仅此一次）
  rotate(apiTenantId)                // 轮换：新 Key active，旧 Key 进入 rotating（24h 后自动 revoked）
  revoke(keyId)                      // 手动撤销
  validate(rawKey)                   // 验证原始 Key → 返回 { apiTenantId, apiTier }
                                     //   实现：hash rawKey → 查 apiKeyStore 匹配 → 拿 apiTenantId
                                     //         → 查 apiTierStore.getByTenantId(apiTenantId) 获取 ApiTier 对象
                                     //         → 取 ApiTier.tier 字段 → 组合返回 { apiTenantId, apiTier: tierValue }
  listByTenantId(apiTenantId)        // 某 api tenant 的所有 Key
```

**Key 格式**：`sl_apikey_<uuid>`，UUID v4。存储时仅存 SHA-256 哈希。

**轮换机制**：调用 `rotate()` 时新 Key 立即生效（status='active'），旧 Key 变为 `'rotating'`，24h 后自动变为 `'revoked'`。此期间 2 个 Key 同时有效，给 API 客户过渡时间。

### 9.3 apiTierStore 设计

```
ApiTier:
  apiTenantId,
  tier: 'free' | 'growth' | 'scale',
  monthlyQuota: int,                 // 月调用配额
  usedThisMonth: int,                // 当月已用
  overageUnitPrice: float,           // 超出单价
  resetAt                            // 配额重置时间（每月 1 日）

方法:
  getByTenantId(apiTenantId)
  incrementUsage(apiTenantId, count) // 调用后 +1，超出配额仍允许（按超出单价计费）
  checkQuota(apiTenantId)            // 返回剩余配额
```

### 9.4 种子数据扩展

```javascript
// 扩展现有 tenant_a001（API 客户）的 Phase 2 字段
// 现有 seed.js 中已有 tenant_a001（type='api', billingModel='api_usage'）
// Phase 2b 在其上扩展：
//   apiTier: 'growth',
//   apiCallQuota: 10000,
//   accessibleFarmTenantIds: ['tenant_001'],
//   // 其他 Phase 2 字段为 null

// 现有 api_consumer 用户（u_005, tenantId='tenant_a001'）保持不变
// 权限集中新增 'api:access'

// 新增 licensed partner tenant（演示订阅服务管理）
{
  id: 'tenant_p002',
  name: '独立部署客户A',
  type: 'partner',
  parentTenantId: null,
  billingModel: 'licensed',
  entitlementTier: 'premium',
  deploymentType: 'on_premise',
  contractId: null,
  revenueShareRatio: null,
  serviceKey: null,
  heartbeatAt: null,
  status: 'active',
  contactName: '赵九',
  contactPhone: '13800000008',
  region: '西南',
  createdAt: '2026-05-01T00:00:00+08:00',
  updatedAt: '2026-05-01T00:00:00+08:00',
  lastUpdatedBy: '系统初始化',
}

// 为 tenant_p002 创建旗下 farm（演示分润计算）
{
  id: 'tenant_f_p002_001',
  name: '独立部署客户A合作牧场',
  type: 'farm',
  parentTenantId: 'tenant_p002',
  billingModel: 'licensed',
  entitlementTier: null,              // 继承 parent
  ownerId: null,                      // 无独立 owner（属于 B端客户）
  status: 'active',
  contactName: '钱十',
  contactPhone: '13800000009',
  region: '西南',
  licenseUsed: 0,
  licenseTotal: 300,
  // Phase 2b 新增：设备配置比例（用于分润计算）
  deviceConfigRatio: { gpsRatio: 0.7, capsuleRatio: 0.3 },
  livestockCount: 280,                // 牛只数（用于分润公式）
  createdAt: '2026-05-01T00:00:00+08:00',
  updatedAt: '2026-05-01T00:00:00+08:00',
  lastUpdatedBy: '系统初始化',
}

// 新增 API 开发者（free tier 试用）
// tenant_a002: type='api', billingModel='api_usage', apiTier='free', apiCallQuota=1000,
//   accessibleFarmTenantIds=['tenant_001']

// 新增 Enterprise 牧场（已开启 API 访问）
// tenant_008: type='farm', entitlementTier='enterprise', apiTier='free', apiCallQuota=1000,
//   accessibleFarmTenantIds=['tenant_008']
```

---

### Free Tier 触发路径

free tier 有两条独立的触发路径，代码层面统一处理（apiTierStore 不区分来源）：

**路径 1 — API 开发者试用**：api_consumer 注册后自动获得 free tier。种子数据 `tenant_a002` 演示此路径。现有 `tenant_a001`（growth）演示已升级状态。

**路径 2 — Enterprise 订阅增值权益**：enterprise 牧场主手动开启 API 访问后获得 free tier。系统在 farm tenant 上设置 `apiTier='free'`，生成 API Key，apiTierStore 创建对应记录。种子数据 `tenant_008` 演示此路径。

**降级处理**：enterprise 订阅降为 pro/basic 时，API 访问挂起（403 + 升级提示），API Key 不删除，升级后自动恢复。Demo 阶段简化为降级即挂起。

---

## G1: Open API 端点

### 端点的 Shaping 分叉

Open API 请求经过 Shaping 中间件，但 tier 来源不同：

| 端点前缀 | Tier 来源 | 说明 |
|---------|----------|------|
| `/api/open/v1/*` | api tenant 的 `apiTier`（从 `X-API-Key` 解析） | 按 API tier 限制端点可见性 |
| `/api/v1/*` | `getEffectiveTier(activeFarmTenantId)` | 按 farm effective tier 限制 |

### 认证与中间件架构

Phase 2b 引入两套认证体系（Bearer token + API Key），需在现有全局中间件链上扩展：

**当前全局中间件链**（`server.js`）：

```
app.use(authMiddleware);           // 1. Bearer token 认证
app.use(farmContextMiddleware);    // 2. 提取 activeFarmTenantId
app.use(shapingMiddleware);        // 3. 功能门控
```

**Phase 2b 扩展策略**：

Open API 端点 `/api/open/v1/*` 使用独立 Express Router，包含自己的中间件栈（apiKeyAuth + rateLimit + shaping 适配）。全局中间件通过路径判断跳过 Open API 请求：

```
server.js 扩展后:

1. 全局中间件：
   app.use(authMiddleware);           // 跳过 /api/open/v1/*（白名单扩展）
   app.use(farmContextMiddleware);    // 跳过含 req.apiConsumer 的请求
   app.use(shapingMiddleware);        // 检测 req.apiTier 分叉

2. Open API Router（在全局中间件之后注册）：
   const openApiRouter = express.Router();
   openApiRouter.use(apiKeyAuthMiddleware);   // X-API-Key 认证
   openApiRouter.use(rateLimitMiddleware);    // 速率限制（按 apiTier）
   // shaping 由全局 shapingMiddleware 处理（检测 req.apiTier 分叉）
   app.use('/api/open/v1', openApiRouter);
```

**全局中间件适配清单**：

| 中间件 | 改动 | 说明 |
|--------|------|------|
| `authMiddleware` | (1) `PUBLIC_PATHS` 新增 `'/subscription-services/heartbeat'` + `'/open/'`（见下方匹配策略）；(2) 匹配策略从纯 `endsWith` 扩展为：`PUBLIC_PATHS` 中不以 `/` 结尾的条目使用 `endsWith` 匹配（现有行为，如 `'/auth/login'`），以 `/` 结尾的条目使用 `startsWith` 前缀匹配（新增，如 `'/open/'` 匹配所有 `/api/open/v1/*`）。注意 request path 不含 `/api` 或 `/api/v1` 挂载前缀（从 Router 内部看是 `/open/v1/...`）；authMiddleware 中的匹配逻辑需适配 request path（Express Router 内部 `req.path` 为去掉挂载前缀后的路径，如 `/open/v1/twin/fever/123`） | Open API 请求不要求 Bearer token；heartbeat 凭 serviceKey 验证 |
| `farmContextMiddleware` | 新增 `if (req.apiConsumer) { req.activeFarmTenantId = null; return next(); }` | API 消费者无 farm context |
| `shapingMiddleware` | 新增 `req.apiTier` 分叉逻辑：`req.apiTier` 存在时用 apiTier 做 Open API 功能门控，否则按 farm tier（当前代码无此分叉，需新增） | 新增分叉 |

**Open API Router 内部中间件注册**：

```
openApiRouter.use(apiKeyAuthMiddleware);   // 解析 X-API-Key → req.apiConsumer, req.apiTier
openApiRouter.use(rateLimitMiddleware);    // 按 req.apiTier 限流
// 路由处理函数（见下方端点清单）
```

此设计确保：
- Open API 请求不经过 Bearer token 校验
- Open API 使用独立的限流规则
- Shaping 中间件自动按 apiTier 分叉（已在横切关注点描述）
- 不改变现有 `/api/v1/*` 路由的行为

### 认证方案

- App API（`/api/v1/*`）：现有 Bearer token（不变）
- Open API（`/api/open/v1/*`）：`X-API-Key` header

**Open API 认证中间件**（`backend/middleware/apiKeyAuth.js`）：

```javascript
function apiKeyAuthMiddleware(req, res, next) {
  const apiKey = req.headers['x-api-key'];
  if (!apiKey) return res.fail(401, 'AUTH_REQUIRED', '缺少 API Key');

  const result = apiKeyStore.validate(apiKey);
  if (!result) return res.fail(401, 'AUTH_INVALID', 'API Key 无效');

  req.apiConsumer = { tenantId: result.apiTenantId, tier: result.apiTier };
  req.apiTier = result.apiTier;
  next();
}
```

### 端点清单

```
free tier — API 试用层（零费用。触发路径：① api_consumer 注册后自动获得；② enterprise 牧场主手动开启 API 访问后获得。详见"Free Tier 触发路径"小节）:
  GET  /api/open/v1/twin/fever/:id        — 单头牛发热状态
  GET  /api/open/v1/twin/estrus/:id       — 单头牛发情评分
  GET  /api/open/v1/twin/digestive/:id    — 单头牛消化状态
  GET  /api/open/v1/twin/health/:id       — 单头牛健康评分
  限额: 1,000 calls/月，速率 10 calls/min

growth (¥500/月):
  free 全部端点
  GET  /api/open/v1/twin/fever/list
  GET  /api/open/v1/twin/estrus/list
  GET  /api/open/v1/twin/epidemic/summary
  POST /api/open/v1/twin/health/batch
  限额: 10,000 calls/月，超出 ¥0.01/call

scale (¥2,000/月):
  growth 全部端点
  GET  /api/open/v1/cattle/list
  GET  /api/open/v1/fence/list
  GET  /api/open/v1/alert/list
  POST /api/open/v1/twin/fever/batch
  限额: 100,000 calls/月，超出 ¥0.005/call
```

### Rate Limit 中间件

| Tier | 速率限制 | 响应头 |
|------|---------|--------|
| free | 10 calls/min | `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` |
| growth | 100 calls/min | 同上 |
| scale | 1000 calls/min | 同上 |

超限返回 `429 Too Many Requests`，body: `{ code: 429, message: '请求频率超限，请稍后重试' }`。

### 数据隔离

Open API 请求的数据隔离通过 `accessibleFarmTenantIds` 实现。apiKeyAuth 中间件将 `accessibleFarmTenantIds` 注入 `req`。**twin 数据关联说明**：twin 数据（发热/消化/发情）以牛只为单位（`cattleId`），牛只对象包含 `farmTenantId` 字段。路由处理函数通过牛只数据中的 `farmTenantId` 与 `req.accessibleFarmTenantIds` 比对实现隔离。实现时需确保对应的存储（如 `cattleStore`）可按 `cattleId` 反查 `farmTenantId`——如当前 mock 实现中 cattle 模型已含 `farmTenantId` 字段（见 `seed.js`）。路由处理函数据此过滤数据：

```javascript
// 在 /api/open/v1/twin/fever/:id 路由处理函数中
const cattle = cattleStore.findById(req.params.id);
if (!cattle || !req.accessibleFarmTenantIds.includes(cattle.farmTenantId)) {
  return res.fail(404, 'NOT_FOUND', '牛只不存在或无权访问');
}
```

### 注册端点（Phase 2b 预留）

```
POST /api/open/v1/register
Phase 2b: 返回 501 Not Implemented
Phase 3: 自助注册 + 审批流程
```

---

## G2: 开发者门户（Vue 3 SPA）

### 项目结构

```
developer-portal/                # 位于 Mobile/developer-portal/（在 Mobile 项目内）
├── index.html
├── package.json
├── vite.config.js
├── src/
│   ├── main.js
│   ├── App.vue
│   ├── router/index.js
│   ├── api/                     # HTTP 客户端（封装 fetch）
│   ├── stores/                  # Pinia 状态管理
│   ├── views/
│   │   ├── LoginView.vue
│   │   ├── RegisterView.vue
│   │   ├── DashboardView.vue
│   │   ├── ApiKeysView.vue
│   │   ├── EndpointsView.vue
│   │   ├── AuthorizationsView.vue
│   │   └── SettingsView.vue
│   ├── components/
│   │   ├── AppLayout.vue        # 顶部导航 + 侧边栏
│   │   ├── MetricCard.vue
│   │   ├── UsageChart.vue
│   │   └── ApiKeyDisplay.vue
│   └── assets/
│       └── styles.css
└── test/
```

### 路由结构

```
/login              → LoginView（api_consumer 凭据登录）
/register           → RegisterView（Phase 2b: 提示联系平台管理员）
/dashboard          → DashboardView（用量仪表盘：调用量、配额、趋势图）
/api-keys           → ApiKeysView（Key 查看/轮换）
/endpoints          → EndpointsView（API 文档浏览）
/authorizations     → AuthorizationsView（数据访问申请/审批状态）
/settings           → SettingsView（账户设置）
```

### 技术栈

| 层 | 选择 |
|---|------|
| 框架 | Vue 3 (Composition API + `<script setup>`) |
| 构建 | Vite |
| 路由 | Vue Router 4 |
| 状态 | Pinia |
| HTTP | Fetch API（封装 `api/` 模块） |
| 测试 | vitest + @vue/test-utils |
| UI | 自定义 CSS（复用 AppColors 色板：`#2E7D32` primary 等） |

### 与 Mock Server 集成

Mock Server 通过 `express.static` 托管开发者门户构建产物：

```javascript
// Mobile/backend/server.js
app.use('/developer', express.static(path.join(__dirname, '../developer-portal/dist')));
```

门户页面通过同源 API 请求 `/api/open/v1/*` 和 `/api/v1/*`，无需跨域配置。

### 登录流程

1. api_consumer 在门户 `/login` 输入凭据
2. Mock 环境：门户直接设置 `Authorization: Bearer mock-token-api-consumer` header（Mock token 已在 `auth.js` 的 `TOKEN_MAP` 中注册，无需通过 `/auth/login` 交换）；Live 环境（后续阶段）：`POST /api/v1/auth/login` 获取 Bearer token
3. 门户用 Bearer token 调用 `/api/v1/me` 确认身份
4. 门户各页面通过 Pinia store 持有 token 并发起 API 请求

### Phase 2b 占位页面

- `/register`：显示"请联系平台管理员申请 API 访问权限"，不做自助注册
- `/authorizations`：显示已授权的 farm 列表（只读，Phase 2b 授权由 platform_admin 手动配置）

---

## G3: API 数据访问授权审批流程

### 完整流程

```
发起方: api_consumer 在开发者门户（/authorizations）提交授权申请
        指定目标 farm tenant + 请求的端点范围
审批方: platform_admin 在后台"API 授权管理"审批
        或 farm owner 在 App"我的" → "API 授权管理"审批自己 farm 的请求
有效期: 首次授权默认 12 个月，可续期
撤销:   platform_admin 或 farm owner 可随时撤销
通知:   授权状态变更通过 App 内消息通知双方（Phase 2b: Mock 内存储，不实际推送）
```

### 数据模型

```
ApiAuthorization（授权记录）:
  id, apiTenantId, farmTenantId,
  requestedScopes: string[],      // 请求的端点范围，如 ['twin:fever', 'twin:estrus']
  status: 'pending' | 'approved' | 'rejected' | 'revoked',
  requestedAt, reviewedAt, reviewedBy,
  expiresAt,                      // approved 后 = reviewedAt + 12 months
  remarks
```

### 端点设计

| 端点 | 方法 | 说明 | 权限 |
|------|------|------|------|
| `/api/v1/api-authorizations` | GET | 授权列表（platform_admin 看全局，owner 看自己所有 farm 的，支持 `?farmTenantId=` 过滤单 farm） | platform_admin, owner |
| `/api/v1/api-authorizations` | POST | 提交授权申请（api_consumer 在门户发起） | api_consumer |
| `/api/v1/api-authorizations/:id/approve` | POST | 审批通过 | platform_admin, owner |
| `/api/v1/api-authorizations/:id/reject` | POST | 拒绝 | platform_admin, owner |
| `/api/v1/api-authorizations/:id/revoke` | POST | 撤销已通过的授权 | platform_admin, owner |

**审批通过后的副作用**：将 `farmTenantId` 追加到 api tenant 的 `accessibleFarmTenantIds` 列表中。撤销时移除。

### 前端 UI

**platform_admin 后台**（新增"API 授权管理"子页面）：
- 授权列表（状态筛选：待审批/已通过/已拒绝/已撤销）
- 审批操作：通过/拒绝
- 已通过的授权可撤销

**owner App**（MinePage 新增"API 授权管理"入口）：
- 显示请求访问自己所有 farm 的授权（按 farm 维度展示，支持按 farm 过滤）
- 审批操作：通过/拒绝
- 已通过的授权可撤销

**开发者门户**（`/authorizations`）：
- 显示自己的授权申请列表及状态
- 提交新申请：选择 farm tenant + 端点范围
- 已通过的授权显示到期时间

---

## 横切关注点

### 配套修改清单

| 模块 | 改动 | 原因 |
|------|------|------|
| `auth.js` middleware | (1) `PUBLIC_PATHS` 新增 + 匹配策略从纯 `endsWith` 扩展为 `endsWith` + `startsWith` 混合；(2) `requirePermission` 新增权限点 | Open API 和 heartbeat 跳过 Bearer 校验 |
| `registerApiRoutes.js` | 新增 `subscriptionServiceRoutes`、`revenueRoutes`、`contractRoutes`、`openApiRoutes`、`apiAuthorizationRoutes` 注册 | Phase 2b 新路由挂载 |
| TOKEN_MAP / seed.js | 新增 api_consumer、licensed partner 等用户和 tenant | 演示数据覆盖新角色 |
| `apiKeyAuth.js` middleware | 新建 Open API 认证中间件 | G1 |
| `rateLimit.js` middleware | 新建速率限制中间件 | G1 |
| `RolePermission.dart` | 新增 `canViewRevenue()`、`canManageContracts()`、`canViewApiAuthorizations()` 等 | 前端权限守卫 |
| `AppRoute` + `AppRouter` | platform_admin 后台新增：对账看板、合同管理、订阅服务管理、API授权管理；b2b_admin 新增：对账、牧工管理 | 新页面路由 |
| `DemoShell` | platform_admin 后台导航扩展；b2b_admin 侧边栏 3→5 项 | UI 导航 |
| `ApiCache` | 新增 `revenue`、`subscriptionServices`、`contracts`、`apiKeys`、`apiAuthorizations` 缓存字段 | live 模式预加载 |
| `farmContextMiddleware` | api_consumer 明确设为 `activeFarmTenantId = null` | 避免 api_consumer 请求走 farm 逻辑 |
| shaping middleware | 检测 `req.apiTier` 分叉：Open API 用 apiTier，App API 用 farm tier | 功能门控 |
| MinePage | 新增"API 授权管理"入口（owner 可见） | G3 |

### 权限点新增

```
// seed.js permissions 新增
'revenue:view',                    // b2b_admin, platform_admin
'contract:manage',                 // platform_admin
'subscription-service:manage',     // platform_admin
'api-key:manage',                  // platform_admin
'api-authorization:review',        // platform_admin, owner
'api-authorization:request',       // api_consumer
'worker:manage:subfarm',           // b2b_admin（旗下 farm）
```

### 后端新建文件

| 文件 | 职责 |
|------|------|
| `backend/data/revenueStore.js` | 分润结算内存 Store |
| `backend/data/subscriptionServiceStore.js` | 订阅服务内存 Store |
| `backend/data/apiTierStore.js` | API 用量计量 Store |
| `backend/data/apiKeyStore.js` | API Key 管理 Store |
| `backend/data/apiAuthorizationStore.js` | API 授权审批 Store |
| `backend/middleware/apiKeyAuth.js` | Open API 认证中间件 |
| `backend/middleware/rateLimit.js` | 速率限制中间件 |
| `backend/routes/revenueRoutes.js` | 分润对账路由 |
| `backend/routes/subscriptionServiceRoutes.js` | 订阅服务管理路由 |
| `backend/routes/contractRoutes.js` | 合同 CRUD 路由（扩展 contractStore） |
| `backend/routes/openApiRoutes.js` | Open API 端点 `/api/open/v1/*` |
| `backend/routes/apiAuthorizationRoutes.js` | API 授权审批路由 |
| `backend/test/revenueStore.test.js` | |
| `backend/test/subscriptionServiceStore.test.js` | |
| `backend/test/apiKeyStore.test.js` | |
| `backend/test/apiTierStore.test.js` | |
| `backend/test/apiAuthorization.test.js` | |
| `backend/test/open-api.test.js` | |
| `backend/test/rate-limit.test.js` | |

### 前端新建文件（Flutter）

| 文件 | 职责 |
|------|------|
| `lib/features/revenue/` | 对账看板（domain/data/presentation 三层） |
| `lib/features/contract_management/` | 合同 CRUD 管理 |
| `lib/features/subscription_service_management/` | 订阅服务管理 |
| `lib/features/api_authorization/` | API 授权管理（owner 端 + platform_admin 端） |

### 前端新建项目（Vue 3）

| 目录 | 职责 |
|------|------|
| `developer-portal/`（位于 `Mobile/developer-portal/`） | 完整 Vue 3 SPA（约 7 个页面 + 组件） |

### 测试策略

| Epic | 后端测试 | 前端测试 |
|------|---------|---------|
| E4 | revenueStore 单元 + revenue API 集成 | 对账看板 widget 测试 |
| E5 | subscriptionServiceStore 单元 + heartbeat API 集成 | 订阅服务管理 widget 测试 |
| E6 | contractStore 扩展单元 + contract CRUD API 集成 | 合同管理 widget 测试 |
| E7 | worker 路由权限扩展测试 | b2b_admin 牧工管理 widget 测试 |
| E8 | tenantStore 扩展单元 | 全量回归 |
| E9 | 各 Store 全量单元 | 全量回归 |
| G1 | Open API 认证 + 限流 + 端点集成测试 | — |
| G2 | — | Vue 3 组件测试（vitest） |
| G3 | apiAuthorization Store 单元 + API 集成 | 授权管理 widget 测试 |
| 回归 | `node --test test/*.test.js` 全部 PASS | `flutter test` 全部 PASS |

### 与父规格的关系

- 本 spec 是 Phase 1 父规格 (`2026-04-28-unified-business-model-design.md` v1.3) 和 Phase 2a 规格的延续
- 父规格 Section 七 Phase 2 描述补充：API 开放平台上线已纳入 Phase 2b（此前安排在 Phase 2）
- 父规格中标注"Phase 2 实现"且 Phase 2a 未覆盖的内容以本 spec 为准
- 已定义的概念（`getEffectiveTier`、Shaping 中间件、Feature Flag、tenant 数据模型等）不重复定义

---

**文档结束**
