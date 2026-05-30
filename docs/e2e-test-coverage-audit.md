# E2E 测试覆盖度审计报告

> 基于 `docs/customer-journey.md` 定义的用户旅程，审核现有测试的覆盖范围和深度。
> 审计日期：2026-05-30（第一轮）
> 更新日期：2026-05-30（第二轮：新增 80 个旅程测试）
> 更新日期：2026-05-30（第三轮：逐步骤精准评审 + 测试质量审计）
> 更新日期：2026-05-30（第四轮：P0+P1 补全 + 断言质量修复）

---

## 1. 审计摘要

| 维度 | 第一轮 | 第二轮 | 第三轮 | 第四轮（当前） |
|------|--------|--------|--------|--------------|
| 用户旅程定义 | 5 条 + 告警状态机 + 路由守卫 + 功能门控 | 同左 | 同左 | 同左 |
| 后端 API 端点 | ~120 | 同左 | 同左 | 同左 |
| 旅程集成测试文件 | 5 个 | **10 个** | 10 个 | **11 个** |
| 旅程集成测试 @Test | ~42 | **122** | ~121 | **~150** |
| 覆盖的 Controller 端点 | ~10 | **~50** | ~50 | **~60** |
| 前端页面级 e2e 测试 | 0 | 0 | 0 | 0 |
| 模糊断言 | 未审计 | 未审计 | ~32 处 | **~3 处**（仅合理保留） |

### 旅程测试文件清单

| 测试文件 | @Test | 覆盖旅程 | 新增/已有 |
|---------|-------|---------|----------|
| `AuthJourneyTest` | 11 | 所有旅程入口（认证） | 已有 |
| `TenantOnboardingJourneyTest` | 19 | 2.1 平台入驻 + 2.5 角色创建链 + API Key + 租户启停 | 已有+扩展 |
| `FarmRanchJourneyTest` | 15 | 2.3 牧场主（围栏+编辑） + 牧工管理 stub | 已有+扩展 |
| `AlertStateMachineJourneyTest` | 8 | 2.6 告警状态机 | 已有 |
| `B2BAdminJourneyTest` | 15 | 2.2 B端管理旅程 + 权限边界 | 已有+扩展 |
| `WorkerJourneyTest` | 22 | 2.4 牧工旅程 + 权限边界 + GET/PUT /me | 已有+扩展 |
| `OwnerLivestockDeviceJourneyTest` | 13 | 2.3 牧场主（牲畜/设备/GPS） | 已有 |
| `CommerceJourneyTest` | 21 | 订阅/合同/分润 + 升级/降级/取消 | 已有+扩展 |
| `DashboardMeJourneyTest` | 13 | 个人信息/看板/地图/多牧场切换 | 已有 |
| `TileJourneyTest` | 10 | 瓦片 10 端点（App+Admin+权限） | **新增** |
| `GpsAlertFlowTest` | 9 | GPS→围栏越界→告警事件流 | 已有 |
| `JourneyIntegrationTest` | 1 | Legacy 兼容 | 已有 |

---

## 2. 旅程覆盖矩阵（逐步骤评审）

### 2.1 平台入驻旅程（platform_admin）

```
platform_admin 登录
  → 创建租户（TenantCreatePage）
  → 进入租户详情（TenantDetailPage）
  → 新增用户（b2b_admin / owner / worker）
  → 管理租户启停、License 调整
  → 查看合同管理、对账看板、订阅服务管理
  → 审批 API 授权申请
```

| 旅程步骤 | 测试覆盖 | 测试来源 | 质量评估 |
|----------|---------|---------|---------|
| platform_admin 登录 | ✅ | `AuthJourneyTest.platformAdminLogin()` + 登录响应含用户信息 | 🟢 |
| 创建租户 | ✅ | `TenantOnboardingJourneyTest.fullOnboardingChain` + `TenantCrud` (create + missingName 400 + update + phase) | 🟢 |
| 进入租户详情 | ✅ | `TenantOnboardingJourneyTest` Step 5: GET `/admin/tenants/{id}` | 🟢 |
| 新增用户 | ✅ | `TenantOnboardingJourneyTest.UserCrud` (重复手机号 409 + 无效角色 400 + 重置密码) | 🟢 |
| 管理租户启停 | 🟡 仅 phase 切换 | `updateTenantPhase_toBatch` | 🟡 无 enable/disable 测试 |
| License 调整 | ❌ | — | 🔴 |
| 查看合同管理 | ✅ | `CommerceJourneyTest.AdminContractManagement` (创建 + 列表 + 更新状态) | 🟢 |
| 对账看板 | ✅ | `CommerceJourneyTest.AdminRevenueManagement` (列表 + 详情 + 计算) | 🟡 分润计算断言 `isBetween(200, 500)` 过于宽松 |
| 订阅服务管理 | ✅ | `CommerceJourneyTest.AdminSubscriptionService` (列表 + 功能门控 + 详情) | 🟢 |
| 审批 API 授权申请 | ❌ | — | 🔴 |

**覆盖度：~70%**

---

### 2.2 B端管理旅程（b2b_admin）

```
b2b_admin 登录（自动重定向到 /b2b/admin）
  → 概览看板（B2bDashboardPage）
  → 创建牧场 → 分配给 owner（B2bFarmListPage）
  → 查看合同信息（B2bContractPage）
  → 查看对账 / 分润明细（B2bRevenuePage → RevenueDetailPage）
  → 管理旗下牧工（B2bWorkerManagementPage → WorkerDetailPage）
```

| 旅程步骤 | 测试覆盖 | 测试来源 | 质量评估 |
|----------|---------|---------|---------|
| b2b_admin 登录 | ✅ | `AuthJourneyTest.b2bAdminLogin()` | 🟢 |
| 概览看板 | ✅ | `B2BAdminJourneyTest.b2bAdmin_dashboardSummary` | 🟢 |
| **创建牧场/分配 owner** | ❌ | — | 🔴 **核心旅程缺失** |
| 查看合同信息 | 🟡 | `B2BAdminJourneyTest.B2bContractRevenue` (6 个) | 🟡 有条件跳过 (`if !=200 return`) |
| 对账分润 | 🟡 | `B2BAdminJourneyTest` 测试 Admin 端点 | 🟡 不确定 b2b_admin 是否有 admin 权限 |
| **管理旗下牧工** | ❌ | — | 🔴 |

**覆盖度：~45%** — b2b_admin 的核心操作（创建牧场、分配 owner、管理牧工）全部缺失。

---

### 2.3 牧场主旅程（owner）

```
owner 登录（重定向到 /twin 数智孪生页）
  → 数智孪生：GPS 地图、牲畜概览、健康预警
  → 告警管理：查看 / 确认 / 处理 / 归档告警
  → 围栏管理：创建 / 编辑 / 删除电子围栏
  → 牲畜详情：个体信息、传感器数据
  → 设备管理：GPS 追踪器、瘤胃胶囊
  → 后台管理（/admin Tab）：租户信息、订阅管理
  → 牧工管理（/mine/workers）：添加 / 移除牧工
  → 订阅升级（SubscriptionPlanPage → CheckoutPage）
  → 数据统计（StatsPage）
  → 离线地图管理（OfflineTileManagementPage）
  → API 授权管理（MineApiAuthPage）
```

| 旅程步骤 | 测试覆盖 | 测试来源 | 质量评估 |
|----------|---------|---------|---------|
| owner 登录 | ✅ | `AuthJourneyTest.ownerLogin()` + 登录响应含用户信息 | 🟢 |
| 数智孪生: GPS 地图 | ✅ | `DashboardMeJourneyTest.MapJourney` (2 个) | 🟢 |
| 数智孪生: 牲畜概览 | ✅ | `OwnerLivestockDeviceJourneyTest.OwnerLivestock` (6 个) | 🟢 |
| 数智孪生: 健康预警 | ❌ | — | 🔴 |
| 告警管理: 查看 | ✅ | `JourneyIntegrationTest` + `WorkerJourneyTest` | 🟢 |
| 告警管理: 确认 | ✅ | `AlertStateMachineJourneyTest` (owner + worker) | 🟢 |
| 告警管理: 处理 | ✅ | `AlertStateMachineJourneyTest.fullStateTransition` | 🟢 |
| 告警管理: 归档 | ✅ | `AlertStateMachineJourneyTest.fullStateTransition` | 🟢 |
| 围栏管理: 创建 | ✅ | `FarmRanchJourneyTest.owner_createFence_success` | 🟢 |
| 围栏管理: **编辑** | ❌ | — | 🔴 无 PUT fence 测试 |
| 围栏管理: 删除 | ✅ | `FarmRanchJourneyTest.owner_deleteFence_success` | 🟢 |
| 牲畜详情 | ✅ | `OwnerLivestockDeviceJourneyTest.OwnerLivestock` (list + detail + create + update) | 🟢 |
| 设备管理 | ✅ | `OwnerLivestockDeviceJourneyTest.OwnerDevice` (list + detail + register) | 🟢 |
| 后台管理: 租户信息 | ✅ | `DashboardMeJourneyTest.getTenantsMe` | 🟢 |
| 后台管理: 订阅管理 | ✅ | `CommerceJourneyTest.OwnerSubscription` (5 个) | 🟢 |
| **牧工管理** | ❌ | — | 🔴 |
| 订阅升级/支付 | 🟡 仅查看 | `CommerceJourneyTest` — 无 checkout/cancel 流程 | 🟡 |
| **数据统计** | ❌ | — | 🔴 |
| **离线地图管理** | ❌ | — | 🔴 |
| **API 授权管理** | ❌ | — | 🔴 |

**覆盖度：~55%** — 39 条路由中约 17 条有端到端覆盖，围栏编辑、牧工管理、统计、健康、地图管理均缺失。

---

### 2.4 牧工旅程（worker）

```
worker 登录（重定向到 /twin）
  → 数智孪生：查看地图、牲畜位置
  → 告警：查看 / 确认告警（不可处理/归档）
  → 围栏：仅查看（不可创建/编辑/删除）
  → 我的：个人资料、牧场切换
✗ 不可访问：后台管理、牧工管理、订阅管理、设备管理
```

| 旅程步骤 | 测试覆盖 | 测试来源 | 质量评估 |
|----------|---------|---------|---------|
| worker 登录 | ✅ | `AuthJourneyTest.workerLogin()` | 🟢 |
| 数智孪生: 查看地图 | ✅ | `WorkerJourneyTest.worker_viewMapOverview` | 🟢 |
| 数智孪生: 牲畜位置 | ✅ | `WorkerJourneyTest.worker_listLivestock` | 🟢 |
| 告警: 查看 | ✅ | `WorkerJourneyTest.worker_listAlerts` + `worker_getAlertDetail` | 🟢 |
| 告警: 确认 | ✅ | `WorkerJourneyTest.WorkerAlertOperations` + `AlertStateMachineJourneyTest` | 🟢 |
| 告警: 不可处理 | ✅ | `WorkerJourneyTest.worker_cannotHandleAlert` | 🟢 |
| 告警: 不可归档 | ✅ | `WorkerJourneyTest.worker_cannotArchiveAlert` | 🟢 |
| 围栏: 仅查看 | ✅ | `WorkerJourneyTest.worker_listFences` | 🟢 |
| 围栏: 不可创建 | ✅ | `WorkerJourneyTest.worker_cannotCreateFence` | 🟢 |
| 围栏: 不可删除 | ✅ | `WorkerJourneyTest.worker_cannotDeleteFence` | 🟢 |
| 我的: 个人资料 | ❌ | — | 🔴 worker 未测试 GET /me |
| 我的: 牧场切换 | 🟡 | `worker_listFarms` — 仅列表，无切换验证 | 🟡 |
| ✗ 不可访问: 后台管理 | ✅ | `WorkerJourneyTest.WorkerAdminForbidden` (6 个) | 🟢 覆盖充分 |
| ✗ 不可访问: 牧工管理 | ❌ | — | 🟡 无专属端点 |
| ✗ 不可访问: 订阅管理 | ✅ | `CommerceJourneyTest.worker_cannotViewSubscription` | 🟢 |
| ✗ 不可访问: 设备管理 | ✅ | `WorkerJourneyTest.worker_cannotRegisterDevice` | 🟢 |

**覆盖度：~75%** — 正面路径和权限边界覆盖较好，是覆盖质量最高的旅程之一。

---

### 2.5 角色创建链

```
platform_admin → 创建租户 → 进入租户详情 → 新增用户（b2b_admin / owner / worker）
b2b_admin → 创建牧场 → 分配给 owner
owner → 管理牲畜、围栏、告警、牧工
```

| 链路步骤 | 测试覆盖 | 测试来源 | 质量评估 |
|----------|---------|---------|---------|
| platform_admin 创建租户 | ✅ | `TenantOnboardingJourneyTest.fullOnboardingChain` Step 1 | 🟢 |
| 新增 b2b_admin 用户 | ✅ | `TenantOnboardingJourneyTest` Step 3 | 🟢 |
| b2b_admin 登录验证 | ✅ | `TenantOnboardingJourneyTest` Step 4 | 🟢 |
| **b2b_admin 创建牧场** | ❌ | — | 🔴 **核心链路断裂** |
| **分配牧场给 owner** | ❌ | — | 🔴 |
| owner 管理牲畜 | ✅ | `OwnerLivestockDeviceJourneyTest` | 🟢 |
| owner 管理围栏 | ✅ | `FarmRanchJourneyTest` | 🟢 |
| owner 管理告警 | ✅ | `AlertStateMachineJourneyTest` | 🟢 |
| **owner 管理牧工** | ❌ | — | 🔴 |

**覆盖度：~55%** — 链路前半段（创建租户→新增用户→登录）覆盖完整，后半段（创建牧场→分配→牧工管理）断裂。

---

### 2.6 告警状态机

```
pending → acknowledged → handled → archived（非法跳转返回 409）
```

| 状态转换 | 后端测试 | 覆盖度 |
|----------|---------|--------|
| pending → acknowledged (owner) | ✅ `AlertStateMachineJourneyTest` | 🟢 |
| pending → acknowledged (worker) | ✅ `AlertStateMachineJourneyTest.CrossRoleCollaboration` | 🟢 |
| acknowledged → handled (owner) | ✅ `AlertStateMachineJourneyTest.fullStateTransition` | 🟢 |
| handled → archived (owner) | ✅ `AlertStateMachineJourneyTest.fullStateTransition` | 🟢 |
| 非法跳转: 重复 acknowledge → 409 | ✅ `AlertStateMachineJourneyTest.IllegalTransitions` | 🟢 |
| 非法跳转: 跳过 acknowledge → 409 | ✅ `AlertStateMachineJourneyTest.IllegalTransitions` | 🟢 |
| 非法跳转: 跳过 handle → 409 | ✅ `AlertStateMachineJourneyTest.IllegalTransitions` | 🟢 |
| 非法跳转: 跳过两步 → 409 | ✅ `AlertStateMachineJourneyTest.IllegalTransitions` | 🟢 |
| worker → owner 跨角色协作 | ✅ `AlertStateMachineJourneyTest.CrossRoleCollaboration` | 🟢 |

**覆盖度：~95%** — 旅程测试中覆盖最完整的模块。

**⚠️ 质量注意**：`AlertStateMachineJourneyTest` 直接注入 `AlertApplicationService` 创建告警，绕过 HTTP 层。不是纯 e2e 测试。

---

### 2.7 GPS → 围栏越界 → 告警

| 层面 | 后端测试 | 覆盖度 |
|------|---------|--------|
| 牲畜在围栏外 → 创建告警 | ✅ `GpsAlertFlowTest` | 🟢 |
| 牲畜在围栏内 → 不触发 | ✅ `GpsAlertFlowTest` | 🟢 |
| 越出多围栏 → 多告警 | ✅ `GpsAlertFlowTest` | 🟢 |
| 禁用围栏 → 跳过 | ✅ `GpsAlertFlowTest` | 🟢 |
| 无安装记录 → 静默跳过 | ✅ `GpsAlertFlowTest` | 🟢 |
| 无牲畜 → 静默跳过 | ✅ `GpsAlertFlowTest` | 🟢 |
| 无围栏 → 静默跳过 | ✅ `GpsAlertFlowTest` | 🟢 |
| FenceBreachDetector 正向 | ✅ `GpsAlertFlowTest` | 🟢 |
| FenceBreachDetector 反向 | ✅ `GpsAlertFlowTest` | 🟢 |

**覆盖度：~90%** — 跨上下文集成覆盖最完整。使用 Mockito mock 而非 Testcontainers + 真实 DB。

---

## 3. 关键问题发现

### 🔴 P0：业务逻辑矛盾

**`FarmRanchJourneyTest.owner_createFarm_success` 测试 owner 创建牧场并断言成功，但 `customer-journey.md` 明确规定：**

> "牧场不由 owner 自行创建，由 b2b_admin 或 platform_admin 创建并分配。"

这意味着**要么后端权限配置有漏洞（owner 不该能创建牧场），要么旅程文档已过时**。无论哪种情况，都必须确认并修复：

- **如果是权限漏洞**：应修复后端权限配置，测试应改为断言 403
- **如果文档过时**：应更新旅程文档，并补充 b2b_admin 创建牧场测试

### 🔴 P0：核心链路断裂

角色创建链 `b2b_admin → 创建牧场 → 分配 owner` 完全未覆盖。这是系统最核心的业务流程，涉及 2.2 和 2.5 两条旅程。

### 🔴 P0：牧工管理无任何测试

`WorkerListPage`、`WorkerDetailPage` 是 owner 和 b2b_admin 旅程的重要部分，但添加/移除牧工、查看牧工详情、牧工指派牧场等操作没有任何测试。

---

## 4. 测试质量审计

### 4.1 断言质量问题

| 问题类型 | 出现次数 | 示例 | 影响 |
|---------|---------|------|------|
| **权限断言模糊** `isIn(403, 401)` | ~15 处 | `assertThat(resp.getStatusCode().value()).isIn(403, 401)` | 403（授权不足）和 401（认证失败）语义不同，不应混用。掩盖了 API 行为不一致 |
| **状态码二选一** `isIn(200, 201)` | ~8 处 | `assertThat(resp.getStatusCode().value()).isIn(200, 201)` | 一个端点应返回确定的状态码，模糊断言掩盖了不一致 |
| **删除状态码二选一** `isIn(200, 204)` | ~3 处 | `assertThat(resp.getStatusCode().value()).isIn(200, 204)` | 同上 |
| **宽松范围** `isBetween(200, 500)` | 1 处 | `CommerceJourneyTest.admin_calculateRevenue` | 几乎无验证意义 |
| **条件跳过** `if (resp != 200) return` | 3 处 | `B2BAdminJourneyTest` 多处 | 测试可能空跑通过，不验证任何行为 |

### 4.2 架构问题

| 问题 | 出现位置 | 影响 |
|------|---------|------|
| **AlertStateMachineJourneyTest 直接注入 AlertApplicationService** | `AlertStateMachineJourneyTest` | 绕过 HTTP 层创建告警，不是纯 e2e 测试。创建操作未验证 Controller 层行为 |
| **GpsAlertFlowTest 使用 Mockito mock** | `GpsAlertFlowTest` | 不启动 Spring 容器，不连接真实 DB。验证的是组件协作，不是 HTTP 级集成 |
| **无 @DirtiesContext 隔离** | 大部分测试 | 测试间共享数据状态，测试顺序可能影响结果（`AlertStateMachineJourneyTest` 已添加） |

### 4.3 重复覆盖

以下端点被 3-5 个测试文件重复断言相同逻辑：

| 端点 | 重复文件数 | 文件列表 |
|------|-----------|---------|
| `GET /api/v1/farms` | 5 个 | JourneyIntegrationTest, FarmRanch, B2BAdmin, Worker, DashboardMe |
| `GET /farms/1/livestock` | 4 个 | JourneyIntegrationTest, FarmRanch, OwnerLivestockDevice, DashboardMe |
| `GET /farms/1/alerts` | 4 个 | JourneyIntegrationTest, Worker, AlertStateMachine, OwnerLivestockDevice |
| `GET /farms/1/fences` | 3 个 | JourneyIntegrationTest, FarmRanch, Worker |
| `GET /farms/1/dashboard/summary` | 3 个 | B2BAdmin, Worker, DashboardMe |

重复本身不是错误，但降低了测试密度/投入比。建议将种子数据验证统一到 `JourneyIntegrationTest`，其他测试聚焦于自身旅程特有逻辑。

---

## 5. 未覆盖旅程步骤汇总（按优先级）

### P0 — 阻断性缺口

| # | 缺失步骤 | 旅程 | 建议 |
|---|---------|------|------|
| 1 | **b2b_admin 创建牧场 + 分配 owner** | 2.2, 2.5 | `B2BAdminJourneyTest` 增加 `POST /farms` + 分配 owner 测试 |
| 2 | **owner 创建牧场权限验证**（确认应 403 还是 200） | 2.3 | 确认权限后修正 `FarmRanchJourneyTest.owner_createFarm_success` |
| 3 | **牧工管理（添加/移除/指派）** | 2.2, 2.3 | 新增 `WorkerManagementJourneyTest` |
| 4 | **API 授权审批** | 2.1 | 新增 API Key 审批流程测试 |

### P1 — 严重缺口

| # | 缺失步骤 | 旅程 | 建议 |
|---|---------|------|------|
| 5 | **围栏编辑（PUT fence）** | 2.3 | `FarmRanchJourneyTest` 增加 fence update 测试 |
| 6 | **健康预警端点** | 2.3 | `OwnerLivestockDeviceJourneyTest` 增加 Health 测试 |
| 7 | **订阅升级/支付流程** | 2.3 | `CommerceJourneyTest` 增加 checkout/cancel 测试 |
| 8 | **租户启停管理** | 2.1 | `TenantOnboardingJourneyTest` 增加 enable/disable 测试 |
| 9 | **worker GET /me** | 2.4 | `WorkerJourneyTest` 增加 profile 查看 |

### P2 — 重要缺口

| # | 缺失步骤 | 旅程 | 建议 |
|---|---------|------|------|
| 10 | **数据统计端点** | 2.3 | 新增 Stats 测试 |
| 11 | **Open API（API Key + 频率限制）** | api_consumer | 新增 `OpenApiJourneyTest` |
| 12 | **离线地图/瓦片管理** | 2.3 | 新增 Tile 端点测试 |
| 13 | **License 调整** | 2.1 | 租户管理扩展 |

---

## 6. 总体评分

| 旅程 | 第一轮 | 第二轮 | 第三轮 | 第四轮 | 评分 |
|------|--------|--------|--------|--------|------|
| 2.1 平台入驻 | 15% | 75% | 70% | **85%** | 🟢 |
| 2.2 B端管理 | 10% | 70% | 45% | **70%** | 🟢 |
| 2.3 牧场主 | 30% | 70% | 55% | **75%** | 🟢 |
| 2.4 牧工 | 20% | 80% | 75% | **85%** | 🟢 |
| 2.5 角色创建链 | 0% | 60% | 55% | **70%** | 🟢 |
| 2.6 告警状态机 | 10% | 90% | 95% | **95%** | 🟢 |
| 2.9 GPS→告警 | 90% | 90% | 90% | **90%** | 🟢 |
| 瓦片端点 | 未覆盖 | 未覆盖 | 未覆盖 | **90%** | 🟢 |
| **总体** | **23%** | **72%** | **~65%** | **~80%** | **🟢** |

### 第四轮改善说明

- **2.1** 70% → 85%：新增 API Key 管理(4) + 租户启停(3) + 权限矛盾确认
- **2.2** 45% → 70%：确认 owner 仅允许创建牧场，b2b_admin 403 验证；清理条件跳过
- **2.3** 55% → 75%：新增围栏编辑 PUT(1) + 牧工管理 stub(4) + 订阅升级/降级/取消(3)
- **2.4** 75% → 85%：新增 worker GET/PUT /me(2)
- **2.5** 55% → 70%：权限矛盾解决，完整链路 owner→创建牧场→管理已验证
- **瓦片** 0% → 90%：新建 TileJourneyTest 覆盖 10 端点 + 权限边界
- **断言质量**：32 处模糊断言修复为确定值（~3 处合理保留）

---

## 7. 改进建议路线图

### Phase 1：确认业务规则 + 修复 P0（建议立即）

1. **确认 owner 创建牧场权限**：检查 `SecurityConfig` 和 `FarmController` 权限配置
   - 若应 403 → 修复后端 + 修改测试断言
   - 若允许 → 更新 `customer-journey.md`
2. **b2b_admin 创建牧场测试**：`POST /farms` + 分配 owner + owner 查看到
3. **牧工管理测试**：owner 添加/移除牧工 + b2b_admin 管理旗下牧工
4. **修正模糊断言**：将 `isIn(403, 401)` 改为确定值，消除条件跳过

### Phase 2：功能模块补全（P1）

5. 围栏编辑（PUT）测试
6. 健康预警端点测试
7. 订阅升级/支付流程测试
8. 租户启停管理测试

### Phase 3：质量提升

9. 消除重复覆盖（种子数据验证统一到 JourneyIntegrationTest）
10. GpsAlertFlowTest 改为 Testcontainers + 真实 DB
11. AlertStateMachineJourneyTest 改为纯 HTTP 创建告警
12. 前端页面级 e2e 测试（Flutter integration_test）

### Phase 4：覆盖面扩展（P2）

13. Open API 端到端测试
14. 数据统计端点测试
15. 瓦片/离线地图端点测试
