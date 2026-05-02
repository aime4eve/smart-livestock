# 统一商业模型 Phase 2b 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成 B2B2C 全部核心能力上线：分润引擎、订阅服务管理、合同 CRUD、b2b_admin 牧工管理、租户字段落地、Store 真实化、Open API 端点、API 授权审批、开发者门户。

**Architecture:** E8（字段落地）先行，其是其余模块的基础；E9（Store 真实化）紧随其后；E4/E5/E6/G1 可在 E8+E9 就绪后并行；E7 仅依赖 E8 字段新增（不依赖 E9，因现有 workerRoutes.js 直接读 tenantStore）；G3 依赖 G1 端点和数据模型；G2 依赖 G1 端点就绪。

**Tech Stack:** Flutter 3.x / flutter_riverpod / go_router, Node.js + Express 5, Vue 3 + Vite + Pinia + Vue Router 4

**被实施规格:** `docs/superpowers/specs/2026-05-02-unified-business-model-phase2b-design.md`

**前置计划:** `docs/superpowers/plans/2026-04-29-unified-business-model-phase2a.md`（Phase 2a 已完成）

**真相来源:** Issue 的 **open/closed** 以 GitHub 为准；本文件记录范围说明、依赖与 **关闭后** 的归档信息。

---

## Issue 索引

| 优先级 | Issue | 标题 |
|--------|-------|------|
| P0 | E8 | Phase 2 专用字段落地 — tenant 模型字段补全 + tenantStore 扩展 |
| P0 | E9 | Store 真实化 — 5 个新 Store + contractStore 扩展 |
| P0 | E6 | 合同 CRUD — contractStore 写操作 + platform_admin 后台 |
| P0 | E7 | b2b_admin 旗下 worker 管理 |
| P0 | E5 | 订阅服务管理 — 生命周期 + 心跳端点 + platform_admin 后台 |
| P0 | E4 | 分润引擎 + 对账看板 |
| P0 | G1 | Open API 端点 `/api/open/v1/*` + 认证中间件 + 限流 |
| P0 | G3 | API 数据访问授权审批流程 |
| P0 | G2 | 开发者门户（Vue 3 SPA） |
| P1 | 集成 | 全量集成测试 + 回归验证 |

### 完成记录

| 完成日期 | Issue | PR | 备注 |
|----------|-------|-----|------|
| 2026-05-02 | E8 | feat/ubm-phase2b-foundation | Phase 2 字段落地：11 新字段 + 2 新租户 + tenantStore 扩展 + 28 tests |
| 2026-05-02 | E9 | feat/ubm-phase2b-foundation | Store 真实化：5 个新 Store（contract CRUD/revenue/subscriptionService/apiKey/apiTier/apiAuthorization）+ 273 tests 全通过 |
| 2026-05-02 | E5 | feat/ubm-phase2b-modules | 订阅服务管理端点（6 个）+ server.js 骨架 + Flutter 前端 + auth/shaping 全局适配 |
| 2026-05-02 | E4 | feat/ubm-phase2b-modules | 分润对账端点（4 个）+ Flutter 对账看板（platform_admin + b2b_admin） |
| 2026-05-02 | E6 | feat/ubm-phase2b-modules | 合同 CRUD 端点（5 个）+ Flutter 合同管理前端 + getById 优化 |
| 2026-05-02 | E7 | feat/ubm-phase2b-modules | b2b_admin 牧工管理：workerRoutes canManageFarm 扩展 + Flutter 页面 + 侧边栏 5 项 |
| 2026-05-02 | G1 | feat/ubm-phase2b-modules | Open API 平台：apiKeyAuth + rateLimit 中间件 + 12 个端点 + farmContext/shaping 适配 |
| 2026-05-02 | G3 | feat/ubm-phase2b-modules | API 授权审批：5 个端点 + Flutter 前端（platform_admin/owner 双视图） |
| 2026-05-02 | G2 | feat/ubm-phase2b-modules | Vue 3 开发者门户（7 页面 + API client + Pinia stores + vitest）+ server.js 静态托管 |

---

## 范围界定（Scope）

**本计划覆盖:**
- E8: tenant 模型 7 个新字段落地 + tenantStore 新增 4 个查询/更新方法
- E9: 5 个新 Store（revenueStore / subscriptionServiceStore / apiKeyStore / apiTierStore / apiAuthorizationStore）+ contractStore 写方法扩展
- E6: 合同 CRUD 完整端点（6 个）+ platform_admin 后台合同管理页面
- E7: workerRoutes 权限扩展 + b2b_admin 侧边栏 3→5 项 + 牧工管理页面
- E5: 订阅服务 CRUD + 心跳端点 + 定时扫描 + platform_admin 后台订阅管理页面
- E4: 分润计算引擎 + 结算周期 CRUD + 对账确认 + 对账看板（platform_admin + b2b_admin）
- G1: Open API Router + apiKeyAuth 中间件 + rateLimit 中间件 + 12 个端点 + 全局中间件适配
- G3: 授权审批数据模型 + 5 个端点 + platform_admin/owner/developer-portal 三方 UI
- G2: 独立 Vue 3 SPA 项目（developer-portal/），含 7 个页面 + 组件 + vitest 测试
- seed.js 数据扩展（tenant_p002、tenant_f_p002_001、权限点新增）
- 全量测试：后端 7 个新测试文件 + Flutter widget 测试 + Vue 3 vitest 测试

**本计划不覆盖:**
- 自助注册（G2 `/register` 为占位页面）
- Phase 3 的 advanced tier 或更多端点
- 真实数据库持久化（仍为内存 Store）
- 真实的 MQTT/IoT 设备集成

---

## 依赖关系

```
E8 (字段落地)
  ├── E9 (Store 真实化)
  │     ├── E4 (分润引擎) ─────────────────────┐
  │     ├── E5 (订阅服务管理) ──────────────────┤
  │     ├── E6 (合同 CRUD) ────────────────────┤──→ 集成测试
  │     └── G1 (Open API 端点) ────────────────┤
  │           ├── G3 (授权审批) ────────────────┤
  │           └── G2 (开发者门户，依赖 G1 端点) ──┘
  └── E7 (b2b worker 管理) ───────────────────┘
```

E8 须先行（字段定义是其余模块的基础）。E9 依赖 E8（Store 引用新字段）。E4/E5/E6/G1 在 E9 完成后可并行。E7 仅依赖 E8 字段新增（tenant.workerQuota/workerLimit 等，但 E7 实现不需要这些字段——canManageFarm() 直接读 tenant.parentTenantId）。G3 依赖 G1 数据模型。G2 依赖 G1 端点就绪。

---

## 建议执行波次

> **策略**: 串行夯实基础 → 并行推进模块 → 串行收尾集成。每波有明确"完成线"（全部测试 PASS），不积累未验证的 Task。

| 波次 | Issue | 策略 | 完成标准 |
|------|-------|------|---------|
| **第一波** | E8 → E9 | 串行，亲自做（字段定义 + Store 是所有上层依赖的基础） | `node --test test/*.test.js` 全部 PASS |
| **第二波** | E4, E5, E6, G1 | 4 个并行 Agent（后端优先于前端：先 Store + Routes → 测试通过 → 再 Flutter 页面） | 各模块 `node --test` + `flutter analyze` 通过 |
| **第三波** | E7, G3, G2 | 2-3 个并行 Agent（G2/G3 依赖 G1 端点就绪，须在第二波之后） | 全量回归 `node --test test/*.test.js` + `flutter test` PASS |

### 每波关键约束

1. **Task 完成即测试**: 每个 Task 完成后立即跑 `node --test test/*.test.js`（后端）或 `flutter test`（前端），不积累多个 Task 再验证。
2. **后端优先于前端**: 每个 Epic 先做完后端（Store + Routes + 测试），再做 Flutter/Vue 前端。API 端点确定了，Repository 接口签名就确定了，避免返工。
3. **对照修复标注**: 计划中标注的 P0-1、P1-4、P1-6、P1-8、P2-9~P2-13 等修复点，实施时逐条确认不遗漏。
4. **seed 修改后手动验证**: E8.1 改完 seed 后启动 server.js 用 curl 验证 `/api/v1/me`、`/api/v1/tenants` 等关键端点，不单纯依赖单元测试。

### 时间线参考

```
Day 1-2: E8.1 → E8.2 (字段落地 + 测试)
Day 2-3: E9.1 → E9.5 (5 个 Store TDD)
────── 第一波完成线 ──────
Day 4:   E4.1 + E5.1 + E6.1 + G1.1 (4 个后端并行)
Day 5:   E4.2 + E5.2 + E6.2 + G1.2 (4 个前端并行)
────── 第二波完成线 ──────
Day 6:   E7.1 → E7.2 (b2b worker)
Day 7:   G3.1 → G3.2 (授权审批)
Day 7-8: G2.1 → G2.3 (开发者门户)
Day 8:   INT.1 → INT.5 (全量集成 + 回归)
```

---

## 文件结构

### 后端 — 新建

| 文件 | Epic | 职责 |
|------|------|------|
| `backend/data/revenueStore.js` | E9 | 分润结算内存 Store（结算周期 CRUD + 计算逻辑） |
| `backend/data/subscriptionServiceStore.js` | E9 | 订阅服务内存 Store（CRUD + 心跳 + 状态扫描） |
| `backend/data/apiTierStore.js` | E9 | API 用量计量 Store（tier 查询 + 配额 + 用量追踪） |
| `backend/data/apiKeyStore.js` | E9 | API Key 管理 Store（生成/轮换/撤销/验证） |
| `backend/data/apiAuthorizationStore.js` | E9 | API 授权审批 Store |
| `backend/middleware/apiKeyAuth.js` | G1 | Open API 认证中间件（X-API-Key 解析） |
| `backend/middleware/rateLimit.js` | G1 | 速率限制中间件（按 apiTier） |
| `backend/routes/revenueRoutes.js` | E4 | 分润对账路由（4 个端点） |
| `backend/routes/subscriptionServiceRoutes.js` | E5 | 订阅服务管理路由（6 个端点含 heartbeat） |
| `backend/routes/contractRoutes.js` | E6 | 合同 CRUD 路由（6 个端点） |
| `backend/routes/openApiRoutes.js` | G1 | Open API 端点（12 个端点 + router 中间件栈） |
| `backend/routes/apiAuthorizationRoutes.js` | G3 | API 授权审批路由（5 个端点） |
| `backend/test/revenueStore.test.js` | E4 | revenueStore 单元测试 |
| `backend/test/subscriptionServiceStore.test.js` | E5 | subscriptionServiceStore 单元测试 |
| `backend/test/apiKeyStore.test.js` | E9 | apiKeyStore 单元测试 |
| `backend/test/apiTierStore.test.js` | E9 | apiTierStore 单元测试 |
| `backend/test/apiAuthorizationStore.test.js` | E9+G3 | apiAuthorizationStore 单元 + 集成测试 |
| `backend/test/open-api.test.js` | G1 | Open API 认证 + 端点集成测试 |
| `backend/test/rate-limit.test.js` | G1 | rateLimit 中间件测试 |

### 后端 — 修改

| 文件 | Epic | 变更 |
|------|------|------|
| `backend/data/seed.js` | E8+E9 | 新增 tenant_p002、tenant_f_p002_001、tenant 新字段（contractId/revenueShareRatio/deploymentType/serviceKey/heartbeatAt/apiTier/apiKey/apiCallQuota/accessibleFarmTenantIds/deviceConfigRatio/livestockCount）、api_consumer 权限扩展、b2b_admin 权限扩展、platform_admin 权限扩展 |
| `backend/data/tenantStore.js` | E8 | createTenant 参数扩展；新增 findByServiceKey/findByApiKey/updateTenantField |
| `backend/data/contractStore.js` | E6+E9 | 新增 create/update/terminate/list 方法 |
| `backend/middleware/auth.js` | E5+G1 | PUBLIC_PATHS 新增 heartbeat + open 路径；匹配策略扩展（endsWith + startsWith 混合）；requirePermission 新增权限点 |
| `backend/middleware/farmContext.js` | G1 | api_consumer 显式分支（`if (req.apiConsumer)`） |
| `backend/middleware/feature-flag.js` | G1 | shaping 中间件新增 `req.apiTier` 分叉逻辑 |
| `backend/middleware/farmContext.js` | G1 | api_consumer 显式分支（`if (req.apiConsumer) { req.activeFarmTenantId = null; return next(); }`） |
| `backend/middleware/feature-flag.js` | G1 | shaping 中间件新增 `req.apiTier` 分叉逻辑（在 farmTier 逻辑之前拦截 Open API 请求） |
| `backend/routes/registerApiRoutes.js` | E4+E5+E6+G1+G3 | 注册 5 个新路由模块 + openApiRouter |
| `backend/routes/workerRoutes.js` | E7 | canManageFarm() 新增 b2b_admin 分支 |
| `backend/test/contractStore.test.js` | E9 | 扩展测试覆盖 create/update/terminate/list |
| `backend/server.js` | E5 (主导) + E6/E4/G1 (增量) | E5.1 锁定骨架（区段结构 + 中间件顺序 + TODO 占位）；后续 Task 仅增量追加 ROUTE_DEFINITIONS / 取消 TODO 注释 |

### 前端 — 新建（Flutter）

| 目录/文件 | Epic | 职责 |
|----------|------|------|
| `lib/features/revenue/domain/revenue_repository.dart` | E4 | 对账仓储接口 |
| `lib/features/revenue/data/mock_revenue_repository.dart` | E4 | Mock 实现 |
| `lib/features/revenue/data/live_revenue_repository.dart` | E4 | Live 实现 |
| `lib/features/revenue/presentation/revenue_controller.dart` | E4 | Riverpod Notifier |
| `lib/features/contract_management/domain/contract_management_repository.dart` | E6 | 合同管理仓储接口 |
| `lib/features/contract_management/data/mock_contract_management_repository.dart` | E6 | Mock 实现 |
| `lib/features/contract_management/data/live_contract_management_repository.dart` | E6 | Live 实现 |
| `lib/features/contract_management/presentation/contract_management_controller.dart` | E6 | Riverpod Notifier |
| `lib/features/subscription_service_management/domain/subscription_service_repository.dart` | E5 | 订阅服务仓储接口 |
| `lib/features/subscription_service_management/data/mock_subscription_service_repository.dart` | E5 | Mock 实现 |
| `lib/features/subscription_service_management/data/live_subscription_service_repository.dart` | E5 | Live 实现 |
| `lib/features/subscription_service_management/presentation/subscription_service_controller.dart` | E5 | Riverpod Notifier |
| `lib/features/api_authorization/domain/api_authorization_repository.dart` | G3 | API 授权仓储接口 |
| `lib/features/api_authorization/data/mock_api_authorization_repository.dart` | G3 | Mock 实现 |
| `lib/features/api_authorization/data/live_api_authorization_repository.dart` | G3 | Live 实现 |
| `lib/features/api_authorization/presentation/api_authorization_controller.dart` | G3 | Riverpod Notifier |

### 前端 — 新建（Vue 3 开发者门户）

| 文件 | 职责 |
|------|------|
| `developer-portal/package.json` | 项目配置 |
| `developer-portal/vite.config.js` | Vite 构建配置 |
| `developer-portal/index.html` | 入口 HTML |
| `developer-portal/src/main.js` | Vue 应用入口 |
| `developer-portal/src/App.vue` | 根组件 |
| `developer-portal/src/router/index.js` | Vue Router 配置（6 个路由） |
| `developer-portal/src/api/client.js` | HTTP 客户端（Fetch API 封装） |
| `developer-portal/src/stores/auth.js` | Pinia 认证状态（token 持有） |
| `developer-portal/src/stores/dashboard.js` | Pinia 仪表盘数据 |
| `developer-portal/src/views/LoginView.vue` | 登录页（api_consumer 凭据） |
| `developer-portal/src/views/RegisterView.vue` | 注册占位页 |
| `developer-portal/src/views/DashboardView.vue` | 用量仪表盘 |
| `developer-portal/src/views/ApiKeysView.vue` | API Key 查看/轮换 |
| `developer-portal/src/views/EndpointsView.vue` | API 文档浏览 |
| `developer-portal/src/views/AuthorizationsView.vue` | 授权申请/状态查看 |
| `developer-portal/src/views/SettingsView.vue` | 账户设置 |
| `developer-portal/src/components/AppLayout.vue` | 顶部导航 + 侧边栏 |
| `developer-portal/src/components/MetricCard.vue` | 指标卡片 |
| `developer-portal/src/components/UsageChart.vue` | 用量趋势图 |
| `developer-portal/src/components/ApiKeyDisplay.vue` | Key 显示组件 |
| `developer-portal/src/assets/styles.css` | 全局样式（复用 AppColors） |
| `developer-portal/test/LoginView.test.js` | 登录页测试 |
| `developer-portal/test/DashboardView.test.js` | 仪表盘测试 |
| `developer-portal/test/ApiKeysView.test.js` | Key 管理测试 |

### 前端 — 修改（Flutter）

| 文件 | Epic | 变更 |
|------|------|------|
| `lib/app/app_route.dart` | E4+E5+E6+E7+G3 | 新增路由枚举：revenue/b2bAdminRevenue/platformRevenue/platformContracts/platformSubscriptions/platformApiAuth/mineApiAuth/b2bWorkerManagement |
| `lib/app/app_router.dart` | E4+E5+E6+E7+G3 | 注册新路由 + 权限守卫 |
| `lib/widgets/demo_shell.dart` | E4+E7 | platform_admin 后台导航扩展（对账/合同/订阅/API授权）；b2b_admin 侧边栏 3→5 项 |
| `lib/core/api/api_cache.dart` | E4+E5+E6+G3 | 新增 revenue/subscriptionServices/contracts/apiKeys/apiAuthorizations 缓存字段 |
| `lib/core/permissions/role_permission.dart` | E4+E5+E6+E7+G3 | 新增 canViewRevenue/canManageContracts/canViewApiAuthorizations 等 |
| `lib/features/mine/presentation/mine_page.dart` | G3 | 新增"API 授权管理"入口（owner 可见） |
| `lib/features/b2b_admin/presentation/b2b_shell.dart` | E4+E7 | 侧边栏扩展：对账 + 牧工管理 |
| `lib/features/admin/presentation/admin_page.dart` | E4+E5+E6+G3 | 后台导航扩展 |

---

## 实施任务

### E8: Phase 2 专用字段落地

#### Task E8.1: tenant 模型字段补全 + seed 数据

**Files:**
- Modify: `backend/data/seed.js` — 所有 tenant 对象新增 Phase 2 字段；新增 tenant_p002、tenant_f_p002_001；新增权限点
- Modify: `backend/data/tenantStore.js` — createTenant 扩展参数 + 新增 3 个方法

- [x] **Step 1: 扩展 seed.js 中现有 tenant 的 Phase 2 字段**

为现有 tenant 对象补充以下字段（不适用时设为 null）：

```javascript
// 现有 tenant 对象逐一新增：
// tenant_001 (farm, billingModel='direct'):
//   contractId: null, revenueShareRatio: null,
//   deploymentType: null, serviceKey: null, heartbeatAt: null,
//   apiTier: null, apiKey: null, apiCallQuota: null, accessibleFarmTenantIds: null
//
// tenant_p001 (partner, billingModel='revenue_share'):
//   contractId: 'contract_001', revenueShareRatio: 0.15,
//   deploymentType: 'cloud', serviceKey: null, heartbeatAt: null,
//   apiTier: null, apiKey: null, apiCallQuota: null, accessibleFarmTenantIds: null
//   deviceConfigRatio: null, livestockCount: null
//
// tenant_a001 (api, billingModel='api_usage'):
//   contractId: null, revenueShareRatio: null,
//   deploymentType: null, serviceKey: null, heartbeatAt: null,
//   apiTier: 'growth', apiKey: null, apiCallQuota: 10000, accessibleFarmTenantIds: ['tenant_001']
//   deviceConfigRatio: null, livestockCount: null
//
// 现有 farm tenant (tenant_002~tenant_006):
//   contractId: null, revenueShareRatio: null,
//   deploymentType: null, serviceKey: null, heartbeatAt: null,
//   apiTier: null, apiKey: null, apiCallQuota: null, accessibleFarmTenantIds: null
//   deviceConfigRatio: null, livestockCount: null
//
// tenant_f_p001_001 (partner 旗下 farm，分润计算数据源):
//   contractId: null, revenueShareRatio: null,
//   deploymentType: null, serviceKey: null, heartbeatAt: null,
//   apiTier: null, apiKey: null, apiCallQuota: null, accessibleFarmTenantIds: null
//   deviceConfigRatio: { gpsRatio: 0.8, capsuleRatio: 0.2 },
//   livestockCount: 150
```

> **P1-4 修复**: 现有 `generateAnimals()` 生成的牛只对象缺少 `farmTenantId` 字段。Open API 端点（G1）依赖此字段做数据隔离（通过 `cattle.farmTenantId` 与 `req.accessibleFarmTenantIds` 比对）。需在 `generateAnimals()` 中为每头牛添加 `farmTenantId: 'tenant_001'`（当前所有模拟牛只属于华东示范牧场）。在 result.push 的对象中新增 `farmTenantId: 'tenant_001'` 字段。

- [x] **Step 2: 在 seed.js 中新增 tenant_p002（licensed partner）和 tenant_f_p002_001（旗下 farm）**

```javascript
// 添加到 tenants 数组：
{
  id: 'tenant_p002',
  name: '独立部署客户A',
  type: 'partner',
  parentTenantId: null,
  billingModel: 'licensed',
  entitlementTier: 'premium',
  contractId: null,
  revenueShareRatio: null,
  deploymentType: 'on_premise',
  serviceKey: null,
  heartbeatAt: null,
  apiTier: null, apiKey: null, apiCallQuota: null, accessibleFarmTenantIds: null,
  ownerId: null,
  status: 'active',
  licenseUsed: 0, licenseTotal: 0,
  deviceConfigRatio: null, livestockCount: null,
  contactName: '赵九', contactPhone: '13800000008',
  contactEmail: null, region: '西南', remarks: null,
  createdAt: '2026-05-01T00:00:00+08:00',
  updatedAt: '2026-05-01T00:00:00+08:00',
  lastUpdatedBy: '系统初始化',
},
{
  id: 'tenant_f_p002_001',
  name: '独立部署客户A合作牧场',
  type: 'farm',
  parentTenantId: 'tenant_p002',
  billingModel: 'licensed',
  entitlementTier: null,
  contractId: null, revenueShareRatio: null,
  deploymentType: null, serviceKey: null, heartbeatAt: null,
  apiTier: null, apiKey: null, apiCallQuota: null, accessibleFarmTenantIds: null,
  ownerId: null,
  status: 'active',
  licenseUsed: 0, licenseTotal: 300,
  deviceConfigRatio: { gpsRatio: 0.7, capsuleRatio: 0.3 },
  livestockCount: 280,
  contactName: '钱十', contactPhone: '13800000009',
  contactEmail: null, region: '西南', remarks: null,
  createdAt: '2026-05-01T00:00:00+08:00',
  updatedAt: '2026-05-01T00:00:00+08:00',
  lastUpdatedBy: '系统初始化',
}
```

- [x] **Step 3: 扩展 seed.js 中用户权限点**

```javascript
// platform_admin 新增:
'contract:manage', 'revenue:view', 'revenue:calculate',
'subscription-service:manage', 'api-key:manage',
'api-authorization:review', 'worker:manage:subfarm'

// b2b_admin 新增:
'revenue:view', 'worker:manage:subfarm'

// api_consumer 新增:
'api:access', 'api-authorization:request'
```

- [x] **Step 4: 扩展 tenantStore.createTenant() 接受新字段**

```javascript
// tenantStore.js createTenant 参数扩展：
const {
  // ... existing fields
  contractId = null,
  revenueShareRatio = null,
  deploymentType = null,
  serviceKey = null,
  heartbeatAt = null,
  apiTier = null,
  apiKey = null,
  apiCallQuota = null,
  accessibleFarmTenantIds = null,
  deviceConfigRatio = null,
  livestockCount = null,
} = body || {};
// 创建 tenant 对象时包含以上字段
```

- [x] **Step 5: tenantStore 新增 3 个方法**

```javascript
// tenantStore.js 新增：
function findByServiceKey(keyHash) {
  return tenants.find((t) => t.serviceKey === keyHash) ?? null;
}

function findByApiKey(keyHash) {
  return tenants.find((t) => t.apiKey === keyHash) ?? null;
}

// P2-12 修复：updateTenantField 使用允许列表防止拼写错误静默添加无效字段
const SYNCABLE_FIELDS = [
  'contractId', 'revenueShareRatio', 'deploymentType', 'serviceKey',
  'heartbeatAt', 'apiTier', 'apiKey', 'apiCallQuota', 'accessibleFarmTenantIds',
  'deviceConfigRatio', 'livestockCount',
];

function updateTenantField(id, field, value) {
  const tenant = findById(id);
  if (!tenant) return { error: 'not_found' };
  if (!SYNCABLE_FIELDS.includes(field)) return { error: 'field_not_allowed' };
  tenant[field] = value;
  tenant.updatedAt = new Date().toISOString().replace('Z', '+08:00').replace(/\.\d{3}/, '');
  return { tenant };
}

module.exports = {
  // ... existing exports
  findByServiceKey,
  findByApiKey,
  updateTenantField,
};
```

- [x] **Step 6: 运行现有测试确保无回归**

```bash
cd Mobile/backend && node --test test/*.test.js
```
Expected: 全部 PASS

- [x] **Step 7: Commit**

```bash
git add backend/data/seed.js backend/data/tenantStore.js
git commit -m "feat(E8): add Phase 2 tenant fields, seed data, and tenantStore extensions"
```

---

#### Task E8.2: tenantStore 扩展单元测试

**Files:**
- Modify: `backend/test/tenantStore.test.js`

- [x] **Step 1: 添加 findByServiceKey / findByApiKey / updateTenantField 测试用例**

```javascript
// 在 tenantStore.test.js 中新增测试：

// test('findByServiceKey returns tenant matching key hash', ...)
// test('findByServiceKey returns null when no match', ...)
// test('findByApiKey returns tenant matching key hash', ...)
// test('findByApiKey returns null when no match', ...)
// test('updateTenantField updates single field and returns tenant', ...)
// test('updateTenantField returns error for unknown id', ...)
// test('updateTenantField rejects field not in SYNCABLE_FIELDS allowlist (P2-12)', ...)
// test('updateTenantField accepts all SYNCABLE_FIELDS values', ...)
```

- [x] **Step 2: 添加 createTenant 接受新字段的测试**

```javascript
// test('createTenant accepts Phase 2 fields (contractId, deploymentType, etc.)', ...)
```

- [x] **Step 3: 运行测试**

```bash
cd Mobile/backend && node --test test/tenantStore.test.js
```
Expected: 全部 PASS

- [x] **Step 4: Commit**

```bash
git add backend/test/tenantStore.test.js
git commit -m "test(E8): add tenantStore extension tests"
```

---

### E9: Store 真实化

#### Task E9.1: contractStore 扩展（写操作）

**Files:**
- Modify: `backend/data/contractStore.js`

- [x] **Step 1: 为 contractStore 添加 create / update / terminate / list 方法**

```javascript
// contractStore.js 扩展：

// P0-2 修复：使用懒加载模块级变量避免循环 require（tenantStore → seed → contractStore）
let _tenantStore = null;
function _getTenantStore() {
  if (!_tenantStore) _tenantStore = require('./tenantStore');
  return _tenantStore;
}

const _contracts = [
  // P2-9 修复：现有 seed 合同补全 Phase 2 字段
  {
    id: 'contract_001',
    partnerTenantId: 'tenant_p001',
    status: 'active',
    effectiveTier: 'standard',
    revenueShareRatio: 0.15,
    startedAt: '2026-01-01T00:00:00+08:00',
    expiresAt: '2027-01-01T00:00:00+08:00',
    signedBy: '王五',
    createdAt: '2026-01-01T00:00:00+08:00',
    updatedAt: '2026-01-01T00:00:00+08:00',
    terminatedAt: null,
  },
];
let _nextId = _contracts.length + 1;

function reset() {
  // P2-13：重置为初始 seed 数据（测试隔离用）
  _contracts.length = 0;
  _contracts.push({
    id: 'contract_001', partnerTenantId: 'tenant_p001', status: 'active',
    effectiveTier: 'standard', revenueShareRatio: 0.15,
    startedAt: '2026-01-01T00:00:00+08:00', expiresAt: '2027-01-01T00:00:00+08:00',
    signedBy: '王五', createdAt: '2026-01-01T00:00:00+08:00',
    updatedAt: '2026-01-01T00:00:00+08:00', terminatedAt: null,
  });
  _nextId = 2;
}

function create(body) {
  const { partnerTenantId, effectiveTier, revenueShareRatio, expiresAt, signedBy } = body || {};
  if (!partnerTenantId || !effectiveTier || revenueShareRatio == null) {
    return { error: 'validation_error', message: '缺少必填字段' };
  }
  const now = new Date().toISOString().replace('Z', '+08:00').replace(/\.\d{3}/, '');
  const contract = {
    id: `contract_${String(_nextId++).padStart(3, '0')}`,
    partnerTenantId, effectiveTier, revenueShareRatio, signedBy: signedBy ?? null,
    status: 'active',
    startedAt: now, expiresAt: expiresAt ?? null,
    createdAt: now, updatedAt: now, terminatedAt: null,
  };
  _contracts.push(contract);
  _getTenantStore().updateTenantField(partnerTenantId, 'contractId', contract.id);
  _getTenantStore().updateTenantField(partnerTenantId, 'revenueShareRatio', revenueShareRatio);
  return { contract };
}

function update(id, body) {
  const contract = _contracts.find((c) => c.id === id);
  if (!contract) return { error: 'not_found' };
  const { effectiveTier, revenueShareRatio, expiresAt, signedBy } = body || {};
  if (effectiveTier !== undefined) contract.effectiveTier = effectiveTier;
  if (revenueShareRatio !== undefined) {
    contract.revenueShareRatio = revenueShareRatio;
    _getTenantStore().updateTenantField(contract.partnerTenantId, 'revenueShareRatio', revenueShareRatio);
  }
  if (expiresAt !== undefined) contract.expiresAt = expiresAt;
  if (signedBy !== undefined) contract.signedBy = signedBy;
  contract.updatedAt = new Date().toISOString().replace('Z', '+08:00').replace(/\.\d{3}/, '');
  return { contract };
}

function terminate(id) {
  const contract = _contracts.find((c) => c.id === id);
  if (!contract) return { error: 'not_found' };
  contract.status = 'expired';
  contract.terminatedAt = new Date().toISOString().replace('Z', '+08:00').replace(/\.\d{3}/, '');
  contract.updatedAt = contract.terminatedAt;
  return { contract };
}

function list(query) {
  const { partnerId, status, page = '1', pageSize = '20' } = query || {};
  let filtered = _contracts.slice();
  if (partnerId) filtered = filtered.filter((c) => c.partnerTenantId === partnerId);
  if (status) filtered = filtered.filter((c) => c.status === status);
  const p = Math.max(1, parseInt(page, 10) || 1);
  const ps = Math.max(1, parseInt(pageSize, 10) || 20);
  const total = filtered.length;
  const items = filtered.slice((p - 1) * ps, p * ps);
  return { items, page: p, pageSize: ps, total };
}

module.exports = { getByPartnerTenantId, create, update, terminate, list, reset };
```

- [x] **Step 2: 更新 contractStore 测试**

```bash
cd Mobile/backend && node --test test/contractStore.test.js
```

- [x] **Step 3: Commit**

```bash
git add backend/data/contractStore.js backend/test/contractStore.test.js
git commit -m "feat(E9): extend contractStore with CRUD operations"
```

---

#### Task E9.2: revenueStore

**Files:**
- Create: `backend/data/revenueStore.js`
- Create: `backend/test/revenueStore.test.js`

- [x] **Step 1: 编写 revenueStore.test.js（先写测试）**

```javascript
// 测试场景：
// test('calculate generates RevenuePeriod for all partners with contracts', ...)
// test('calculate covers both licensed and revenue_share billingModel partners', ...)
// test('calculate formula: totalDeviceFee = Σ(farm.livestockCount × deviceUnitPrice)', ...)
// test('calculate revenueShareAmount = totalDeviceFee × ratio', ...)
// test('calculate snaps livestockCount and deviceConfigRatio from farm data', ...)
// test('calculate with mode=monthly only (realtime not implemented)', ...)
// test('getPeriods returns paginated list', ...)
// test('getPeriod filters by partnerTenantId', ...)
// test('confirm sets confirmedByPlatform when platform_admin', ...)
// test('confirm sets confirmedByPartner when matching b2b_admin tenantId', ...)
// test('status transitions to settled when both confirmed', ...)
```

- [x] **Step 2: 运行测试验证它们失败**

```bash
cd Mobile/backend && node --test test/revenueStore.test.js
```
Expected: FAIL (revenueStore 尚未存在)

- [x] **Step 3: 实现 revenueStore.js**

核心实现要点：
- **P1-8 修复**: 设备单价使用命名常量（而非内联魔法数字），便于后续调整：
  ```javascript
  const DEVICE_UNIT_PRICES = { GPS_PER_CATTLE: 15, CAPSULE_PER_CATTLE: 30 };
  ```
- `calculate(period, mode='monthly')` — 遍历所有有合同（`contractId != null`）的 partner tenant（覆盖 `'licensed'` 和 `'revenue_share'` 两种 billingModel），对其旗下每个 farm 计算 `deviceFee = livestockCount × (gpsRatio × DEVICE_UNIT_PRICES.GPS_PER_CATTLE + capsuleRatio × DEVICE_UNIT_PRICES.CAPSULE_PER_CATTLE)`，汇总得 `totalDeviceFee`，乘以 contract 的分润比；快照当前 deviceConfigRatio 和 livestockCount
- `getPeriods(query)` — 分页列表，支持 partnerTenantId 过滤
- `getPeriod(id)` — 单周期 + farm 明细
- `confirm(id, role, tenantId)` — 按角色设置 confirmedByPlatform 或 confirmedByPartner，双方都 true → settled
- `reset()` — **P2-13**: 清空所有结算周期数据（测试隔离用）

- [x] **Step 4: 运行测试验证通过**

```bash
cd Mobile/backend && node --test test/revenueStore.test.js
```
Expected: PASS

- [x] **Step 5: Commit**

```bash
git add backend/data/revenueStore.js backend/test/revenueStore.test.js
git commit -m "feat(E9): add revenueStore with settlement calculation and period management"
```

---

#### Task E9.3: subscriptionServiceStore

**Files:**
- Create: `backend/data/subscriptionServiceStore.js`
- Create: `backend/test/subscriptionServiceStore.test.js`

- [x] **Step 1: 编写测试（TDD）**

```javascript
// 测试场景：
// test('create generates serviceKey with SL-SUB-XXXX format', ...)
// test('create stores only keyHash (SHA-256), not raw key', ...)
// test('raw serviceKey returned only once at creation', ...)
// test('heartbeat updates lastHeartbeatAt and returns ok status', ...)
// test('heartbeat with invalid key returns error', ...)
// test('heartbeat auto-recovers degraded status to active', ...)
// test('heartbeat syncs tenant.heartbeatAt', ...)
// test('scan detects overdue heartbeats and transitions to grace_period', ...)
// test('scan transitions grace_period to degraded when beyond grace days', ...)
// test('renew extends expiresAt', ...)
// test('revoke changes status to revoked', ...)
// test('getByPartnerTenantId filters correctly', ...)
```

- [x] **Step 2: 运行验证失败**

```bash
cd Mobile/backend && node --test test/subscriptionServiceStore.test.js
```

- [x] **Step 3: 实现 subscriptionServiceStore.js**

核心实现：
- `create(body)` — 生成 serviceKey（格式 `SL-SUB-XXXX-XXXX`），SHA-256 哈希存储，同步 tenant.serviceKey
- **注意**: 使用 `crypto.createHash('sha256')` 进行哈希，需确认 Node.js ≥ 18（`crypto` 为内置模块）
- **P2-11 修复**: `heartbeat(rawServiceKey, instanceInfo)` — 路由处理函数传入**原始** serviceKey，Store 内部必须先 `crypto.createHash('sha256').update(rawServiceKey).digest('hex')` 计算哈希，再与存储的 `keyHash` 比对验证。不要直接比较原始值。
- `scan()` — 全量扫描：active 超 24h → grace_period；grace_period 超 15 天 → degraded
- `renew(id, newExpiresAt)` — 更新 expiresAt
- `revoke(id)` — status → revoked
- `list(query)` — 分页，按 partner 过滤
- `reset()` — **P2-13**: 清空所有订阅服务数据（测试隔离用）

- [x] **Step 4: 运行测试验证通过**

- [x] **Step 5: Commit**

```bash
git add backend/data/subscriptionServiceStore.js backend/test/subscriptionServiceStore.test.js
git commit -m "feat(E9): add subscriptionServiceStore with heartbeat and status scanning"
```

---

#### Task E9.4: apiKeyStore + apiTierStore

**Files:**
- Create: `backend/data/apiKeyStore.js`
- Create: `backend/data/apiTierStore.js`
- Create: `backend/test/apiKeyStore.test.js`
- Create: `backend/test/apiTierStore.test.js`

- [x] **Step 1: 编写 apiKeyStore 测试**

```javascript
// test('generate creates key with sl_apikey_ prefix', ...)
// test('generate stores keyHash (SHA-256), not raw key', ...)
// test('generate returns raw key only once', ...)
// test('validate returns { apiTenantId, apiTier } for valid key', ...)
// test('validate returns null for invalid key', ...)
// test('rotate creates new active key, old key enters rotating status', ...)
// test('rotate 24h auto-revoke: scanRevokeRotatingKeys revokes expired rotating keys', ...)
// test('revoke immediately changes status to revoked', ...)
// test('listByTenantId returns all keys for an api tenant', ...)
// test('two keys simultaneously valid during rotation period', ...)
```

- [x] **Step 2: 编写 apiTierStore 测试**

```javascript
// test('getByTenantId returns ApiTier object', ...)
// test('getByTenantId returns null for non-api tenant', ...)
// test('incrementUsage increases usedThisMonth', ...)
// test('incrementUsage allows over-quota calls', ...)
// test('checkQuota returns remaining count', ...)
// test('resetMonthlyUsage resets at month boundary', ...)
```

- [x] **Step 3: 运行验证失败**

- [x] **Step 4: 实现 apiKeyStore.js**

核心实现：
- `generate(apiTenantId)` — 生成 `sl_apikey_<uuid>`，SHA-256 哈希存储，返回原始 key
- `validate(rawKey)` — hash → 查 keyHash → 取 apiTenantId → 查 apiTierStore.getByTenantId() → 返回 `{ apiTenantId, apiTier }`
- `rotate(apiTenantId)` — 新 Key active，旧 Key rotating（24h 后自动 revoked）
- `revoke(keyId)` — 立即撤销
- `scanRevokeRotatingKeys()` — 超 24h 的 rotating key → revoked
- `listByTenantId(apiTenantId)` — 返回该 tenant 的所有 Keys
- `reset()` — **P2-13**: 清空所有 API Key 数据（测试隔离用）

- [x] **Step 5: 实现 apiTierStore.js**

> **P1-5 修复**: apiTierStore 需初始化 tenant_a001 的 seed 数据，否则 `apiKeyStore.validate()` 返回 null tier。在 Store 模块中内置初始 seed：

```javascript
const _initialTiers = [
  {
    apiTenantId: 'tenant_a001',
    tier: 'growth',
    monthlyQuota: 10000,
    usedThisMonth: 0,
    overageUnitPrice: 0.01,
    resetAt: null,
  },
];
```

核心实现：
- `getByTenantId(apiTenantId)` — 返回 ApiTier 对象
- `incrementUsage(apiTenantId, count)` — 用量增加
- `checkQuota(apiTenantId)` — 剩余配额
- `resetMonthlyUsage()` — 月初自动重置
- `reset()` — **P2-13**: 重置为初始 seed（测试隔离用）

- [x] **Step 6: 运行测试验证通过**

- [x] **Step 7: Commit**

```bash
git add backend/data/apiKeyStore.js backend/data/apiTierStore.js \
        backend/test/apiKeyStore.test.js backend/test/apiTierStore.test.js
git commit -m "feat(E9): add apiKeyStore and apiTierStore for Open API key management"
```

---

#### Task E9.5: apiAuthorizationStore

**Files:**
- Create: `backend/data/apiAuthorizationStore.js`
- Create: `backend/test/apiAuthorizationStore.test.js`

- [x] **Step 1: 编写测试**

```javascript
// test('create authorization record with pending status', ...)
// test('approve changes status and updates accessibleFarmTenantIds', ...)
// test('reject changes status to rejected', ...)
// test('revoke removes farmTenantId from accessible list', ...)
// test('list filters by apiTenantId / farmTenantId / status', ...)
```

- [x] **Step 2: 实现 apiAuthorizationStore.js**

核心实现：
- `create(body)` — 新建 pending 授权
- `approve(id, reviewedBy)` — status → approved，追加 accessibleFarmTenantIds
- `reject(id, reviewedBy)` — status → rejected
- `revoke(id)` — status → revoked，移除 accessibleFarmTenantIds
- `list(query)` — 分页，支持 farmTenantId/status/apiTenantId 过滤
- `reset()` — **P2-13**: 清空所有授权数据（测试隔离用）

- [x] **Step 3: 运行测试**

- [x] **Step 4: Commit**

```bash
git add backend/data/apiAuthorizationStore.js backend/test/apiAuthorizationStore.test.js
git commit -m "feat(E9): add apiAuthorizationStore for data access authorization"
```

---

### E6: 合同 CRUD

#### Task E6.1: contractRoutes 端点

**Files:**
- Create: `backend/routes/contractRoutes.js`
- Modify: `backend/routes/registerApiRoutes.js`
- Modify: `backend/server.js`

- [ ] **Step 1: 实现 contractRoutes.js**

```javascript
// 端点：
// GET    /contracts              — 列表（分页，?partnerId=&status=），权限: platform_admin
// POST   /contracts              — 创建合同，权限: platform_admin (contract:manage)
// GET    /contracts/:id          — 详情，权限: platform_admin + b2b_admin（仅自己的）
// PUT    /contracts/:id          — 编辑，权限: platform_admin
// POST   /contracts/:id/terminate — 终止，权限: platform_admin
// GET    /b2b/contract/current   — 当前 b2b_admin 自己的合同（保留 Phase 2a）
// GET    /b2b/contract/usage-summary — 用量汇总（保留 Phase 2a）
```

- [ ] **Step 2: 注册到 registerApiRoutes.js**

```javascript
const contractRoutes = require('./contractRoutes');
// ...
app.use(`${prefix}/contracts`, contractRoutes);
```

- [ ] **Step 3: 在 server.js ROUTE_DEFINITIONS 区段追加 E6 端点行**

将 E6-TODO 注释替换为：

```javascript
  // --- E6 合同管理 ---
  ['GET',    '/contracts'],
  ['POST',   '/contracts'],
  ['GET',    '/contracts/:id'],
  ['PUT',    '/contracts/:id'],
  ['POST',   '/contracts/:id/terminate'],
```

- [ ] **Step 4: 编写集成测试并验证**

```bash
cd Mobile/backend && node --test test/contractStore.test.js
```

- [ ] **Step 5: Commit**

```bash
git add backend/routes/contractRoutes.js backend/routes/registerApiRoutes.js \
        backend/server.js
git commit -m "feat(E6): add contract CRUD endpoints"
```

---

#### Task E6.2: 合同管理 Flutter 前端（platform_admin 后台）

**Files:**
- Create: `lib/features/contract_management/domain/contract_management_repository.dart`
- Create: `lib/features/contract_management/data/mock_contract_management_repository.dart`
- Create: `lib/features/contract_management/data/live_contract_management_repository.dart`
- Create: `lib/features/contract_management/presentation/contract_management_controller.dart`
- Create: `lib/features/admin/presentation/contract_management_page.dart`
- Modify: `lib/app/app_route.dart`
- Modify: `lib/app/app_router.dart`
- Modify: `lib/widgets/demo_shell.dart`
- Modify: `lib/core/api/api_cache.dart`

- [ ] **Step 1: 定义 Repository 接口**

```dart
// contract_management_repository.dart
abstract class ContractManagementRepository {
  ViewData<List<Map<String, dynamic>>> getContracts({String? partnerId, String? status});
  Future<bool> createContract(Map<String, dynamic> body);
  Future<bool> updateContract(String id, Map<String, dynamic> body);
  Future<bool> terminateContract(String id);
}
```

- [ ] **Step 2: 实现 Mock/Live Repository + Controller**

- [ ] **Step 3: 创建合同管理页面**

列表页：状态筛选（active/suspended/expired）+ 分页；创建/编辑表单（partner + tier + 分润比 + 到期日 + 签约人）；详情页 + 终止按钮。

- [ ] **Step 4: 创建 b2b_admin 合同详情升级**

修改 b2b_admin 合同页面，数据来源从 `/api/v1/b2b/contract/current` 扩展到 `/api/v1/contracts/:id`，显示更多字段（签约人、生效日期、到期日等）。

- [ ] **Step 5: 注册路由 + 扩展后台导航**

```dart
// app_route.dart 新增：
platformContracts('/admin/contracts', 'platform-contracts', '合同管理'),
```

- [ ] **Step 6: RolePermission 新增 canManageContracts()**

- [ ] **Step 7: Commit**

---

### E7: b2b_admin 旗下 worker 管理

#### Task E7.1: workerRoutes 权限扩展

**Files:**
- Modify: `backend/routes/workerRoutes.js`

- [ ] **Step 1: 修改 canManageFarm() 新增 b2b_admin 分支**

> **P1-6 修复**: `workerRoutes.js` 的 `canManageFarm()` 使用**角色检查**（非权限点），seed.js 中 b2b_admin 新增的 `'worker:manage:subfarm'` 权限点仅用于前端 `RolePermission.canManageSubfarmWorkers()` 做页面/按钮可见性控制，后端权限仍由角色逻辑保证。两者独立运作。

```javascript
function canManageFarm(req, farmId) {
  if (req.userRole === 'platform_admin') return true;
  const farm = tenantStore.findById(farmId);
  if (req.userRole === 'b2b_admin') {
    return farm?.parentTenantId === req.user.tenantId;
  }
  if (req.userRole === 'owner') {
    return farm?.ownerId === req.user.userId;
  }
  return false;
}
```

- [ ] **Step 2: 运行 worker-routes 测试验证**

```bash
cd Mobile/backend && node --test test/worker-routes.test.js
```

- [ ] **Step 3: Commit**

```bash
git add backend/routes/workerRoutes.js
git commit -m "feat(E7): extend workerRoutes canManageFarm for b2b_admin"
```

---

#### Task E7.2: b2b_admin 侧边栏 + 牧工管理页面

> **P1-7 修复**: b2b_admin 侧边栏在 `lib/features/b2b_admin/presentation/b2b_shell.dart`（不是 `demo_shell.dart`）。计划文件总表中的 `demo_shell.dart` 覆盖 E4 的 platform_admin 后台导航扩展，此处仅涉及 b2b_shell。

**Files:**
- Modify: `lib/features/b2b_admin/presentation/b2b_shell.dart` — 侧边栏 3→5 项
- Modify: `lib/app/app_route.dart` — 新增 b2bWorkerManagement 路由
- Modify: `lib/app/app_router.dart` — 注册路由
- Modify: `lib/core/permissions/role_permission.dart` — 新增 canManageSubfarmWorkers()
- Create: `lib/features/b2b_admin/presentation/worker_management_page.dart`

- [ ] **Step 1: b2b_shell 侧边栏新增导航项**

```dart
// 侧边栏新增：
// 概览 → 牧场管理 → 合同信息 → 对账（E4 后启用）→ 牧工管理（E7）
```

- [ ] **Step 2: 创建牧工管理页面**

显示旗下 farm 列表 → 点击进入 farm worker 列表（复用 WorkerListPage 组件）+ 分配/移除操作。

- [ ] **Step 3: RolePermission 新增 canManageSubfarmWorkers()**

- [ ] **Step 4: Commit**

---

### E5: 订阅服务管理

#### Task E5.1: subscriptionServiceRoutes 端点

**Files:**
- Create: `backend/routes/subscriptionServiceRoutes.js`
- Modify: `backend/routes/registerApiRoutes.js`
- Modify: `backend/middleware/auth.js` — PUBLIC_PATHS 新增 heartbeat
- Modify: `backend/server.js` — ROUTE_DEFINITIONS + 定时器启动

- [ ] **Step 1: 实现 subscriptionServiceRoutes.js**

```javascript
// 端点：
// GET    /subscription-services          — 列表（分页），权限: platform_admin
// POST   /subscription-services          — 创建，权限: platform_admin
// GET    /subscription-services/:id      — 详情，权限: platform_admin
// POST   /subscription-services/:id/renew — 续期，权限: platform_admin
// POST   /subscription-services/:id/revoke — 吊销，权限: platform_admin
// POST   /subscription-services/heartbeat — 心跳（PUBLIC PATH，凭 serviceKey）
```

- [ ] **Step 2: auth.js PUBLIC_PATHS 扩展**

> **P0-1 修复**: 全局中间件中 `req.path` 为完整路径（如 `/api/v1/subscription-services/heartbeat` 或 `/api/open/v1/twin/fever/123`），而非 Router 内部去掉挂载前缀后的路径。因此 `endsWith` 匹配对 heartbeat 后缀有效（路径末尾匹配），但 Open API 需用 `startsWith` 前缀匹配完整路径前缀 `/api/open/`。将后缀匹配与前缀匹配分离为两个数组。

```javascript
const PUBLIC_PATHS = [
  '/auth/login', '/auth/refresh', '/auth/logout',
  '/subscription-services/heartbeat',  // 新增（endsWith 匹配）
];

const PUBLIC_PREFIXES = [
  '/api/open/',                        // 新增（startsWith 前缀匹配）
];

// authMiddleware 匹配策略（修复后）：
// if (PUBLIC_PATHS.some((p) => req.path.endsWith(p)) ||
//     PUBLIC_PREFIXES.some((p) => req.path.startsWith(p))) {
//   return next();
// }
```

- [ ] **Step 3: server.js 骨架重构 + 定时器启动**

> **Q1 协调策略**: E5.1 是第一个动 server.js 的 Task，在此一次性锁定中间件注册顺序和区段结构。后续 Task（E6.1/E4.1/G1.2）只在 `ROUTE_DEFINITIONS` 数组和 `registerApiRoutes.js` 中做增量追加，不再调整 server.js 骨架。

将 server.js 重组织为以下区段结构：

```javascript
const express = require('express');
const cors = require('cors');
const path = require('path');                          // E5.1 新增

const { buildRuntimeConfig } = require('./config/runtimeConfig');
const { envelopeMiddleware } = require('./middleware/envelope');
const { requestContext } = require('./middleware/requestContext');
const { authMiddleware } = require('./middleware/auth');
const { farmContextMiddleware } = require('./middleware/farmContext');
const { shapingMiddleware } = require('./middleware/feature-flag');
const { registerApiRoutes } = require('./routes/registerApiRoutes');
const subscriptionStore = require('./data/subscriptions');
const subscriptionServiceStore = require('./data/subscriptionServiceStore');  // E5.1 新增
const apiKeyStore = require('./data/apiKeyStore');      // E5.1 新增

const app = express();
const PORT = 3001;

// ===== 基础中间件 =====
app.use(cors());
app.use(express.json());
app.use(requestContext(buildRuntimeConfig()));
app.use(envelopeMiddleware);

// ===== 全局中间件链 =====
// 顺序约束（不可变）: auth → farmContext → shaping
// auth: 跳过 /api/open/* (startsWith) + /subscription-services/heartbeat (endsWith)
// farmContext: 跳过 req.apiConsumer（api_consumer 无 farm context）
// shaping: req.apiTier 分叉 → Open API 用 apiTier 门控, App API 用 farm tier 门控
app.use(authMiddleware);
app.use(farmContextMiddleware);
app.use(shapingMiddleware);

// ===== App API 路由 (/api/v1/*) =====
registerApiRoutes(app, '/api');
registerApiRoutes(app, '/api/v1');

// ===== Open API 路由 (/api/open/v1/*) =====
// G1.2-TODO: const openApiRouter = require('./routes/openApiRoutes');
// G1.2-TODO: app.use('/api/open/v1', openApiRouter);

// ===== 开发者门户静态托管 =====
app.use('/developer', express.static(path.join(__dirname, '../developer-portal/dist')));

// ===== 启动时全量扫描 =====
subscriptionServiceStore.scan();                        // 订阅服务状态扫描
apiKeyStore.scanRevokeRotatingKeys();                   // API Key 轮换撤销扫描

// ===== 定时任务 =====
setInterval(() => subscriptionServiceStore.scan(), 60_000);         // 每 60s
setInterval(() => apiKeyStore.scanRevokeRotatingKeys(), 3_600_000); // 每 3600s

// ===== seed trial subscriptions（已有逻辑，保留） =====
const allTenants = tenantStore.getAll();
// ... (不变)

// ===== 404 fallback =====
app.use((req, res) => {
  res.fail(404, 'RESOURCE_NOT_FOUND', `路由不存在: ${req.method} ${req.path}`);
});

// ===== ROUTE_DEFINITIONS =====
// 仅用于启动时打印已知路由，非功能性
const ROUTE_DEFINITIONS = [
  // --- Phase 2a 现有端点 (56 个) ---
  // ... (保持现有全部端点不变)

  // --- E5 订阅服务管理 ---
  ['GET',    '/subscription-services'],
  ['POST',   '/subscription-services'],
  ['GET',    '/subscription-services/:id'],
  ['POST',   '/subscription-services/:id/renew'],
  ['POST',   '/subscription-services/:id/revoke'],
  ['POST',   '/subscription-services/heartbeat'],

  // E6-TODO: contracts 端点
  // E4-TODO: revenue 端点
  // G1-TODO: open API 端点
];
// ... (ROUTE_TABLE + listen 逻辑不变)
```

> **实施注意**: 实际编辑时保留现有 56 个端点不变，只在数组末尾追加 E5 端点行和 TODO 注释行。`tenantStore` 如已在 imports 中存在则不需重复添加。

- [ ] **Step 4: 编写集成测试**

- [ ] **Step 5: Commit**

```bash
git add backend/routes/subscriptionServiceRoutes.js backend/routes/registerApiRoutes.js \
        backend/server.js
git commit -m "feat(E5): add subscription service endpoints + server.js skeleton"
```

---

#### Task E5.2: 订阅服务管理 Flutter 前端

**Files:**
- Create: `lib/features/subscription_service_management/` (domain + data + presentation)
- Create: `lib/features/admin/presentation/subscription_service_page.dart`
- Modify: `lib/app/app_route.dart` + `lib/widgets/demo_shell.dart`

- [ ] **Step 1: 实现三层架构（Repository + Controller）**

- [ ] **Step 2: 创建订阅服务管理页面**

列表页：状态标签（active/宽限/已降级/已吊销/已过期）+ 心跳状态；创建表单：partner + tier + 到期日 + 设备配额；详情页 + 续期/吊销按钮。

- [ ] **Step 3: 注册路由 + 扩展后台导航**

- [ ] **Step 4: b2b_admin 合同页展示订阅服务状态**

在 b2b_admin 合同页面，当 tenant.billingModel === 'licensed' 时显示订阅服务状态（只读：active/宽限/已降级/已吊销/已过期）。

- [ ] **Step 5: RolePermission 新增 canManageSubscriptionServices()**

- [ ] **Step 6: Commit**

---

### E4: 分润引擎 + 对账看板

#### Task E4.1: revenueRoutes 端点

**Files:**
- Create: `backend/routes/revenueRoutes.js`
- Modify: `backend/routes/registerApiRoutes.js`
- Modify: `backend/server.js`

- [ ] **Step 1: 实现 revenueRoutes.js**

```javascript
// 端点：
// GET    /revenue/periods            — 列表（分页，?partnerId=），权限: platform_admin + b2b_admin
// GET    /revenue/periods/:id        — 详情 + farm 明细，权限: platform_admin + b2b_admin
// POST   /revenue/periods/:id/confirm — 确认对账，权限: platform_admin + b2b_admin
// POST   /revenue/calculate          — 手动触发月结算，权限: platform_admin
// 数据隔离：b2b_admin 仅看 partnerTenantId === 自己 tenantId
```

- [ ] **Step 2: 在 registerApiRoutes.js 注册 revenueRoutes + server.js ROUTE_DEFINITIONS 追加**

```javascript
// registerApiRoutes.js 新增:
const revenueRoutes = require('./revenueRoutes');
app.use(`${prefix}/revenue`, revenueRoutes);

// server.js ROUTE_DEFINITIONS 区段: 将 E4-TODO 注释替换为:
  // --- E4 分润对账 ---
  ['GET',    '/revenue/periods'],
  ['GET',    '/revenue/periods/:id'],
  ['POST',   '/revenue/periods/:id/confirm'],
  ['POST',   '/revenue/calculate'],
```

- [ ] **Step 3: 编写集成测试**

- [ ] **Step 4: Commit**

```bash
git add backend/routes/revenueRoutes.js backend/routes/registerApiRoutes.js \
        backend/server.js
git commit -m "feat(E4): add revenue settlement endpoints"
```

---

#### Task E4.2: 对账看板 Flutter 前端

**Files:**
- Create: `lib/features/revenue/` (domain + data + presentation)
- Create: `lib/features/admin/presentation/revenue_page.dart`
- Create: `lib/features/b2b_admin/presentation/revenue_page.dart`
- Modify: `lib/app/app_route.dart` + `lib/widgets/demo_shell.dart`

- [ ] **Step 1: 实现三层架构**

- [ ] **Step 2: 创建 platform_admin 对账看板页面**

全局结算周期列表（状态标签）+ 详情（分润汇总表 + 手动触发结算按钮）+ 确认按钮。

- [ ] **Step 3: 创建 b2b_admin 对账页面**

仅显示自己 partner 的周期 + 详情页 + 确认按钮。

- [ ] **Step 4: 注册路由 + 扩展导航**

```dart
// app_route.dart 新增：
platformRevenue('/admin/revenue', 'platform-revenue', '对账看板'),
b2bAdminRevenue('/b2b/admin/revenue', 'b2b-admin-revenue', '对账'),
```

- [ ] **Step 5: RolePermission 新增 canViewRevenue() 和 canCalculateRevenue()**

- [ ] **Step 6: Commit**

---

### G1: Open API 端点

#### Task G1.1: apiKeyAuth + rateLimit 中间件 + 全局中间件适配

**Files:**
- Create: `backend/middleware/apiKeyAuth.js`
- Create: `backend/middleware/rateLimit.js`
- Modify: `backend/middleware/farmContext.js` — api_consumer 显式分支
- Modify: `backend/middleware/feature-flag.js` — apiTier 分叉逻辑
- Create: `backend/test/rate-limit.test.js`

- [ ] **Step 1: 实现 apiKeyAuth 中间件**

```javascript
// apiKeyAuth.js
const apiKeyStore = require('../data/apiKeyStore');

function apiKeyAuthMiddleware(req, res, next) {
  const apiKey = req.headers['x-api-key'];
  if (!apiKey) return res.fail(401, 'AUTH_REQUIRED', '缺少 API Key');
  const result = apiKeyStore.validate(apiKey);
  if (!result) return res.fail(401, 'AUTH_INVALID', 'API Key 无效');
  req.apiConsumer = { tenantId: result.apiTenantId, tier: result.apiTier };
  req.apiTier = result.apiTier;
  // inject accessibleFarmTenantIds from tenantStore
  const tenantStore = require('../data/tenantStore');
  const tenant = tenantStore.findById(result.apiTenantId);
  req.accessibleFarmTenantIds = tenant?.accessibleFarmTenantIds ?? [];
  next();
}
```

- [ ] **Step 2: 实现 rateLimit 中间件**

```javascript
// rateLimit.js — 内存滑动窗口
const RATE_LIMITS = {
  free:     { perMinute: 10 },
  growth:   { perMinute: 100 },
  scale:    { perMinute: 1000 },
};

function rateLimitMiddleware(req, res, next) {
  const tier = req.apiTier || 'free';
  const limit = RATE_LIMITS[tier]?.perMinute || 10;
  // 滑动窗口实现：按 apiTenantId 记录时间戳
  // 超限返回 429：res.fail(429, 'RATE_LIMITED', '请求频率超限，请稍后重试')
  // 响应头: X-RateLimit-Limit / X-RateLimit-Remaining / X-RateLimit-Reset
  next();
}
```

- [ ] **Step 3: 编写 rateLimit 中间件测试**

- [ ] **Step 4: 修改 farmContextMiddleware — api_consumer 显式分支**

在 `backend/middleware/farmContext.js` 中，在现有 owner/worker 分支之前插入 api_consumer 显式处理：

```javascript
if (req.apiConsumer) { req.activeFarmTenantId = null; return next(); }
```

- [ ] **Step 5: 修改 shapingMiddleware — apiTier 分叉**

在 `backend/middleware/feature-flag.js` 中，在现有 `res.ok` 覆写开头插入 `req.apiTier` 分叉：

```javascript
res.ok = function(data, message) {
  if (req.apiTier) {
    const shaped = applyApiTierShaping(data, req.apiTier, featureKeys);
    return originalOk(shaped, message);
  }
  // 现有 App API 使用 farm tier 逻辑...
};
```

- [ ] **Step 6: Commit**

---

#### Task G1.2: Open API 路由 + 端点实现

**Files:**
- Create: `backend/routes/openApiRoutes.js`
- Modify: `backend/routes/registerApiRoutes.js` — 注册 openApiRouter
- Modify: `backend/middleware/auth.js` — PUBLIC_PREFIXES 新增 `/api/open/`
- Modify: `backend/server.js` — 取消 G1.2-TODO 注释 + ROUTE_DEFINITIONS 追加

- [ ] **Step 1: 实现 openApiRoutes.js**

```javascript
// openApiRouter 内部中间件栈:
// apiKeyAuth → rateLimit → 路由处理函数

// 端点：
// GET  /open/v1/twin/fever/:id       — 单头牛发热状态
// GET  /open/v1/twin/estrus/:id      — 单头牛发情评分
// GET  /open/v1/twin/digestive/:id   — 单头牛消化状态
// GET  /open/v1/twin/health/:id      — 单头牛健康评分
// GET  /open/v1/twin/fever/list      — (growth+)
// GET  /open/v1/twin/estrus/list     — (growth+)
// GET  /open/v1/twin/epidemic/summary — (growth+)
// POST /open/v1/twin/health/batch    — (growth+)
// GET  /open/v1/cattle/list          — (scale)
// GET  /open/v1/fence/list           — (scale)
// GET  /open/v1/alert/list           — (scale)
// POST /open/v1/twin/fever/batch     — (scale)
// POST /open/v1/register             — 返回 501

// 每个端点需校验 accessibleFarmTenantIds（通过 cattle.farmTenantId）
// free tier 只允许 GET 单个资源；growth/scale 允许列表和批量
```

- [ ] **Step 2: 取消 server.js 中 G1.2-TODO 注释 + ROUTE_DEFINITIONS 追加**

```javascript
// server.js — 将 2 行 G1.2-TODO 注释替换为实际代码:
const openApiRouter = require('./routes/openApiRoutes');
app.use('/api/open/v1', openApiRouter);

// server.js ROUTE_DEFINITIONS 区段: 将 G1-TODO 注释替换为:
  // --- G1 Open API ---
  ['GET',    '/open/v1/twin/fever/:id'],
  ['GET',    '/open/v1/twin/estrus/:id'],
  ['GET',    '/open/v1/twin/digestive/:id'],
  ['GET',    '/open/v1/twin/health/:id'],
  ['GET',    '/open/v1/twin/fever/list'],
  ['GET',    '/open/v1/twin/estrus/list'],
  ['GET',    '/open/v1/twin/epidemic/summary'],
  ['POST',   '/open/v1/twin/health/batch'],
  ['GET',    '/open/v1/cattle/list'],
  ['GET',    '/open/v1/fence/list'],
  ['GET',    '/open/v1/alert/list'],
  ['POST',   '/open/v1/twin/fever/batch'],
  ['POST',   '/open/v1/register'],
```

- [ ] **Step 3: 编写 Open API 集成测试**

```bash
cd Mobile/backend && node --test test/open-api.test.js
```

- [ ] **Step 4: Commit**

```bash
git add backend/routes/openApiRoutes.js backend/routes/registerApiRoutes.js \
        backend/middleware/auth.js backend/server.js
git commit -m "feat(G1): add Open API endpoints with apiKeyAuth and rateLimit"
```

---

### G3: API 数据访问授权审批流程

#### Task G3.1: apiAuthorizationRoutes 端点

**Files:**
- Create: `backend/routes/apiAuthorizationRoutes.js`
- Modify: `backend/routes/registerApiRoutes.js`

- [ ] **Step 1: 实现 apiAuthorizationRoutes.js**

```javascript
// 端点：
// GET   /api-authorizations       — 列表，权限: platform_admin + owner
// POST  /api-authorizations       — 提交申请，权限: api_consumer
// POST  /api-authorizations/:id/approve — 审批通过，权限: platform_admin + owner
// POST  /api-authorizations/:id/reject  — 拒绝
// POST  /api-authorizations/:id/revoke  — 撤销
```

- [ ] **Step 2: 注册路由**

- [ ] **Step 3: 编写集成测试**

- [ ] **Step 4: Commit**

---

#### Task G3.2: API 授权管理 Flutter 前端

**Files:**
- Create: `lib/features/api_authorization/` (domain + data + presentation)
- Create: `lib/features/admin/presentation/api_authorization_page.dart`
- Modify: `lib/features/mine/presentation/mine_page.dart` — 新增入口
- Modify: `lib/app/app_route.dart`

- [ ] **Step 1: 实现三层架构**

- [ ] **Step 2: platform_admin 后台 API 授权管理页面**

授权列表（状态筛选）+ 审批操作（通过/拒绝/撤销）。

- [ ] **Step 3: owner App MinePage 新增入口**

"API 授权管理"入口，按 farm 维度展示授权请求 + 审批操作。

- [ ] **Step 4: 注册路由 + 扩展导航**

- [ ] **Step 5: RolePermission 新增 canReviewApiAuthorizations() / canRequestApiAuthorization()**

- [ ] **Step 6: Commit**

---

### G2: 开发者门户（Vue 3 SPA）

#### Task G2.1: 项目脚手架 + 基础组件

> **P2-10 修复**: `developer-portal/` 位于 `Mobile/` 目录内（即 `Mobile/developer-portal/`），与 `Mobile/backend/` 和 `Mobile/mobile_app/` 平级。AGENTS.md 明确所有活跃开发在 `Mobile/` 下。server.js 中静态托管路径应为 `path.join(__dirname, '../developer-portal/dist')`。

**Files:**
- Create: `developer-portal/package.json`
- Create: `developer-portal/vite.config.js`
- Create: `developer-portal/index.html`
- Create: `developer-portal/src/main.js`
- Create: `developer-portal/src/App.vue`
- Create: `developer-portal/src/router/index.js`
- Create: `developer-portal/src/api/client.js`
- Create: `developer-portal/src/stores/auth.js`
- Create: `developer-portal/src/components/AppLayout.vue`
- Create: `developer-portal/src/assets/styles.css`

- [ ] **Step 1: 初始化 Vue 3 + Vite 项目**

```bash
mkdir -p developer-portal/src/{router,api,stores,views,components,assets}
mkdir -p developer-portal/test
```

```json
// package.json
{
  "name": "smart-livestock-developer-portal",
  "version": "1.0.0",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "test": "vitest run"
  },
  "dependencies": {
    "vue": "^3.4",
    "vue-router": "^4",
    "pinia": "^2"
  },
  "devDependencies": {
    "vite": "^5",
    "@vitejs/plugin-vue": "^5",
    "vitest": "^1",
    "@vue/test-utils": "^2",
    "jsdom": "^24"
  }
}
```

- [ ] **Step 2: 实现 AppLayout 组件（顶部导航 + 侧边栏）**

侧边栏：仪表盘 / API Keys / 端点文档 / 授权管理 / 设置

- [ ] **Step 3: 实现 API 客户端 (Fetch 封装)**

```javascript
// src/api/client.js
const API_BASE = '/api/v1';

async function apiGet(path, token) {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const body = await res.json();
  if (body.code !== 'OK') throw new Error(body.message);
  return body.data;
}
```

- [ ] **Step 4: 实现 Pinia auth store**

含 `login(token)` / `logout()` / `isAuthenticated` + 登录时设置 `mock-token-api-consumer`

- [ ] **Step 5: 实现 Pinia dashboard store**

含 quota、usedThisMonth、recentUsage 等字段，封装 `/api/v1/subscription/usage` 调用。

- [ ] **Step 6: Commit**

---

#### Task G2.2: 页面实现（Login / Dashboard / ApiKeys / Endpoints / Authorizations / Settings / Register）

**Files:**
- Create: 7 个 view 文件 + 2 个额外 component 文件

- [ ] **Step 1: LoginView — 输入凭据登录**

Mock 环境直接使用 `mock-token-api-consumer`，调用 `/api/v1/me` 确认身份。

- [ ] **Step 2: RegisterView — 占位页面**

显示"请联系平台管理员申请 API 访问权限"。

- [ ] **Step 3: DashboardView — 用量仪表盘**

显示调用量、配额剩余、使用趋势（通过 `/api/v1/subscription/usage` 类端点）。

- [ ] **Step 4: ApiKeysView — Key 查看/轮换**

显示 Key 前缀 + 后 4 位，支持轮换操作。组件：ApiKeyDisplay。

- [ ] **Step 5: EndpointsView — API 文档浏览**

按 tier 分组展示可用端点。

- [ ] **Step 6: AuthorizationsView — 授权申请/状态**

显示自己的授权申请列表 + 状态 + 提交新申请表单。

- [ ] **Step 7: SettingsView — 账户设置**

显示 api_consumer 基本信息。

- [ ] **Step 8: Commit**

---

#### Task G2.3: Vue 3 组件测试（vitest）

**Files:**
- Create: `developer-portal/test/LoginView.test.js`
- Create: `developer-portal/test/DashboardView.test.js`
- Create: `developer-portal/test/ApiKeysView.test.js`

- [ ] **Step 1: 编写 LoginView 测试**

```javascript
// 测试登录表单渲染、输入绑定、提交逻辑
```

- [ ] **Step 2: 编写 DashboardView 测试**

```javascript
// 测试仪表盘数据显示（mock API 响应）
```

- [ ] **Step 3: 编写 ApiKeysView 测试**

```javascript
// 测试 Key 列表显示和轮换按钮
```

- [ ] **Step 4: 运行测试**

```bash
cd developer-portal && npx vitest run
```

- [ ] **Step 5: 配置 vite.config.js 支持测试**

```javascript
// vite.config.js
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
export default defineConfig({
  plugins: [vue()],
  test: { environment: 'jsdom' },
  build: { outDir: 'dist' },
  server: { port: 5173 },
});
```

- [ ] **Step 6: Commit**

---

### 集成: 全量测试 + 回归验证

#### Task INT.1: 后端全量测试

- [ ] **Step 1: 运行所有后端测试**

```bash
cd Mobile/backend && node --test test/*.test.js
```
Expected: 全部 PASS（新增 7 个测试文件 + 原有 16 个测试文件）

- [ ] **Step 2: 修复任何失败的测试**

---

#### Task INT.2: Flutter 前端全量测试

- [ ] **Step 1: 运行 flutter analyze**

```bash
cd Mobile/mobile_app && flutter analyze
```
Expected: 无新增 issue

- [ ] **Step 2: 运行所有 Flutter 测试**

```bash
cd Mobile/mobile_app && flutter test
```
Expected: 全部 PASS

- [ ] **Step 3: 编写新页面 widget smoke 测试（可选）**

---

#### Task INT.3: 开发者门户构建验证

- [ ] **Step 1: 构建开发者门户**

```bash
cd developer-portal && npm run build
```
Expected: 成功生成 `dist/` 目录

- [ ] **Step 2: 验证 Mock Server 托管**

```bash
cd Mobile/backend && node server.js
# 浏览器访问 http://localhost:3001/developer
```
Expected: 显示开发者门户首页

---

#### Task INT.4: 手动端到端验证

- [ ] **Step 1: platform_admin 登录**

验证后台新增页面：对账看板、合同管理、订阅服务管理、API 授权管理。

- [ ] **Step 2: b2b_admin 登录**

验证侧边栏 5 项 + 牧工管理 + 对账。

- [ ] **Step 3: owner 登录**

验证 MinePage "API 授权管理"入口。

- [ ] **Step 4: api_consumer 登录开发者门户**

验证登录 → 仪表盘 → API Keys → 授权申请。

- [ ] **Step 5: curl 验证 Open API 端点**

```bash
# 生成 API Key（通过 platform_admin 后台）
# curl -H "X-API-Key: sl_apikey_xxx" http://localhost:3001/api/open/v1/twin/fever/animal_001
```

---

#### Task INT.5: 最终 Commit + 更新计划完成记录

- [ ] **Step 1: 最终全量 commit**

```bash
git add -A
git commit -m "feat: Phase 2b complete — revenue engine, subscription services, contract CRUD, Open API, developer portal"
```

- [ ] **Step 2: 更新本计划文件的完成记录表**

---

## 测试策略

| Epic | 后端测试 | 前端测试 |
|------|---------|---------|
| E8 | tenantStore 扩展单元 | — |
| E9 | contractStore/revenueStore/subscriptionServiceStore/apiKeyStore/apiTierStore/apiAuthorizationStore 全量单元 | — |
| E6 | contract CRUD API 集成 | 合同管理 widget 测试 |
| E7 | worker 路由权限扩展测试 | b2b_admin 牧工管理 widget 测试 |
| E5 | subscriptionServiceStore + heartbeat API 集成 | 订阅服务管理 widget 测试 |
| E4 | revenueStore + revenue API 集成 | 对账看板 widget 测试 |
| G1 | Open API 认证 + 限流 + 端点集成 | — |
| G2 | — | Vue 3 组件测试（vitest） |
| G3 | apiAuthorization Store + API 集成 | 授权管理 widget 测试 |
| 回归 | `node --test test/*.test.js` 全部 PASS | `flutter test` 全部 PASS |

---

## 横切关注点

### 配套修改清单

| 模块 | 改动 | Epic |
|------|------|------|
| `auth.js` | PUBLIC_PATHS 后缀匹配 + PUBLIC_PREFIXES 前缀匹配（分离为两个数组，全局中间件 req.path 为完整路径）；新增权限点 | E5, G1 |
| `registerApiRoutes.js` | 新增 6 个路由模块注册 | E4, E5, E6, G1, G3 |
| `server.js` | **E5.1 锁定骨架结构**（区段注释 + 中间件顺序 + G1.2-TODO 占位 + E4/E6/G1-TODO 占位），后续 Task 仅增量追加 ROUTE_DEFINITIONS 和取消 TODO 注释 | E5, E6, E4, G1 |
| `seed.js` | 新增 tenant_p002 + tenant_f_p002_001；所有 tenant 补全 Phase 2 字段；generateAnimals() 新增 farmTenantId；权限点新增 | E8 |
| `farmContext.js` | api_consumer 显式分支（提前到 G1.1 实施） | G1 |
| `feature-flag.js` | shaping 中间件 req.apiTier 分叉（提前到 G1.1 实施） | G1 |
| `workerRoutes.js` | canManageFarm() 新增 b2b_admin 分支 | E7 |
| `AppRoute` + `AppRouter` | 新增 6+ 路由 | E4, E5, E6, E7, G3 |
| `DemoShell` | 导航扩展 | E4, E5, E6, E7, G3 |
| `ApiCache` | 新增缓存字段 | E4, E5, E6, G3 |
| `RolePermission` | 新增权限判断方法 | E4, E5, E6, E7, G3 |
| `MinePage` | 新增 API 授权管理入口 | G3 |

---
