# E2E 测试覆盖度审计报告

> 基于 `docs/customer-journey.md` 定义的用户旅程，审核现有测试的覆盖范围和深度。
> 审计日期：2026-05-30

---

## 1. 审计摘要

| 维度 | 数值 |
|------|------|
| 用户旅程定义 | 5 条旅程 + 告警状态机 + 路由守卫 + 功能门控 |
| 后端 API 端点 | ~120（App 65 + Admin 43 + Open 12） |
| 后端测试文件 | 35 个 Java 文件，~260 @Test |
| 前端测试文件 | 21 个 Dart 文件，~149 test/testWidgets |
| **真正的 e2e/集成旅程测试** | **1 个**（`JourneyIntegrationTest`） |
| **HTTP 级 API 端点测试** | **仅 JourneyIntegrationTest 使用的 TestRestTemplate** |
| **前端页面级 e2e 测试** | **0 个**（全部是 widget 级或纯逻辑测试） |

### 结论

**覆盖严重不足。** 35 个 Controller、~120 个 API 端点、39 条路由、5 条用户旅程，仅 1 个集成测试覆盖了部分旅程步骤。大部分测试是领域模型单元测试和应用服务单元测试，验证了业务规则的正确性，但没有验证「用户从 A 操作到 B 的完整链路」。

---

## 2. 旅程覆盖矩阵

### 2.1 平台入驻旅程（platform_admin）

```
platform_admin 登录 → 创建租户 → 租户详情 → 新增用户 → 管理启停/License → 合同/对账/订阅服务 → API授权审批
```

| 旅程步骤 | 后端测试 | 前端测试 | 覆盖度 | 缺口分析 |
|----------|---------|---------|--------|---------|
| platform_admin 登录 | ✅ JourneyIntegrationTest.setUp() | ❌ 无 | 🟡 部分 | 后端验证了登录可获取 token，但未独立测试登录失败/错误密码 |
| 创建租户 | ❌ 无 HTTP 测试 | ❌ 无 | 🔴 无 | `TenantAdminController` 8 个端点无任何 Controller 测试 |
| 进入租户详情 | ❌ 无 | ✅ tenant_detail_page_test (6) | 🟡 前端部分 | 后端 GET /admin/tenants/{id} 无 HTTP 测试 |
| 新增用户 | ❌ 无 HTTP 测试 | ❌ 无 | 🔴 无 | `UserAdminController` 7 个端点无 HTTP 测试 |
| 管理启停/License | ❌ 无 | ❌ 无 | 🔴 无 | 租户状态切换 + License 调整无覆盖 |
| 合同管理 | 🟡 ContractApplicationServiceTest (8) | ❌ 无 | 🟡 仅领域层 | 无 HTTP 级合同 CRUD 测试 |
| 对账看板 | 🟡 RevenueApplicationServiceTest (7) | ❌ 无 | 🟡 仅领域层 | 无 HTTP 级对账查询测试 |
| 订阅服务管理 | 🟡 SubscriptionApplicationServiceTest (12) | ❌ 无 | 🟡 仅领域层 | 无 HTTP 级订阅服务管理测试 |
| API授权审批 | 🟡 ApiKeyApplicationServiceTest (4) | ❌ 无 | 🟡 仅领域层 | 无 HTTP 级审批流程测试 |

**旅程覆盖度：🟡 15%** — 仅登录入口有 e2e 验证，核心管理操作（创建租户/用户/启停）完全未覆盖。

### 2.2 B端管理旅程（b2b_admin）

```
b2b_admin 登录 → 概览看板 → 创建牧场/分配owner → 合同信息 → 对账分润 → 牧工管理
```

| 旅程步骤 | 后端测试 | 前端测试 | 覆盖度 | 缺口分析 |
|----------|---------|---------|--------|---------|
| b2b_admin 登录 | ✅ JourneyIntegrationTest.setUp() | ❌ 无 | 🟡 部分 | 同 platform_admin，仅验证 token 获取 |
| 概览看板 | ❌ 无 | ❌ 无 | 🔴 无 | `DashboardAdminController` 2 端点无测试 |
| 创建牧场/分配 owner | ❌ 无 HTTP 测试 | ❌ 无 | 🔴 无 | 核心旅程步骤，`FarmAdminController` 5 端点无 HTTP 测试 |
| 合同信息 | 🟡 应用服务测试 | ❌ 无 | 🟡 仅领域层 | b2b_admin 合同查看路由无 HTTP 测试 |
| 对账分润 | 🟡 应用服务测试 | ❌ 无 | 🟡 仅领域层 | `AdminRevenueController` 6 端点无 HTTP 测试 |
| 牧工管理 | ❌ 无 | ❌ 无 | 🔴 无 | 完全无覆盖 |

**旅程覆盖度：🟡 10%** — b2b_admin 是牧场创建的关键角色，但其核心操作完全无 e2e 覆盖。

### 2.3 牧场主旅程（owner）

```
owner 登录 → 数智孪生 → 告警管理 → 围栏管理 → 牲畜详情 → 设备管理 → 后台管理 → 牧工管理 → 订阅升级 → 统计 → 离线地图 → API授权
```

| 旅程步骤 | 后端测试 | 前端测试 | 覆盖度 | 缺口分析 |
|----------|---------|---------|--------|---------|
| owner 登录 | ✅ JourneyIntegrationTest | ❌ 无登录页测试 | 🟡 部分 | 登录页 widget 无任何测试 |
| 数智孪生 | ❌ 无 | ❌ 无 | 🔴 无 | `MapController` 2 端点 + `HealthController` 1 端点无测试 |
| 告警管理 | 🟡 JourneyIntegrationTest (确认+拒绝各1) | ❌ 无 | 🟡 部分 | 完整状态流（pending→ack→handle→archive）未验证 |
| 围栏管理 | 🟡 FenceTest (4) + FenceBreachDetectorTest (4) | ✅ fence tests (51) | 🟢 较好 | 前后端都有覆盖，是覆盖最好的模块 |
| 牲畜详情 | 🟡 LivestockTest (3) | ❌ 无 | 🟡 仅领域层 | `LivestockController` 6 端点无 HTTP 测试 |
| 设备管理 | 🟡 DeviceTest (12) + DeviceLicenseTest (6) | ❌ 无 | 🟡 仅领域层 | `DeviceController` 7 端点无 HTTP 测试 |
| 后台管理 | ❌ 无 | ❌ 无 | 🔴 无 | owner 端 /admin 子路由无测试 |
| 牧工管理 | ❌ 无 | ❌ 无 | 🔴 无 | 完全无覆盖 |
| 订阅升级 | 🟡 SubscriptionTest (38) + FeatureGateTest (7) | ✅ locked_overlay (8) | 🟢 较好 | 前后端都有，但无升级支付 e2e 流程 |
| 数据统计 | ❌ 无 | ❌ 无 | 🔴 无 | `StatsPage` 无测试 |
| 离线地图 | ❌ 无 | ✅ smart_tile_provider (5) + coord_transform (4) | 🟡 前端部分 | 后端 `TileController` 3 端点无 HTTP 测试 |
| API授权 | 🟡 应用服务测试 | ❌ 无 | 🟡 仅领域层 | 无 HTTP 级测试 |

**旅程覆盖度：🟡 30%** — 围栏和订阅是亮点，但数智孪生、牧工管理、后台管理、统计完全空白。

### 2.4 牧工旅程（worker）

```
worker 登录 → 数智孪生(只看) → 告警(确认) → 围栏(只读) → 我的
```

| 旅程步骤 | 后端测试 | 前端测试 | 覆盖度 | 缺口分析 |
|----------|---------|---------|--------|---------|
| worker 登录 | ✅ JourneyIntegrationTest.setUp() | ❌ 无 | 🟡 部分 | |
| 数智孪生(只读) | ❌ 无 | ❌ 无 | 🔴 无 | worker 角色能看到的孪生数据无验证 |
| 告警确认 | ✅ JourneyIntegrationTest (1 个确认) | ❌ 无 | 🟡 部分 | 仅确认 1 条 pending 告警，未测试查看列表 |
| 围栏只读 | ❌ 无 | ✅ route_guard_test 验证无编辑权限 | 🟡 部分 | 前端验证了 UI 权限，后端无 fence API 权限测试 |
| 我的页面 | ❌ 无 | ❌ 无 | 🔴 无 | |

**旅程覆盖度：🟡 20%** — 登录和基本权限有验证，但 worker 的核心操作路径未覆盖。

### 2.5 角色创建链

```
platform_admin → 创建租户 → 新增用户(b2b_admin) → b2b_admin 创建牧场 → 分配给 owner → owner 管理牧工
```

| 链路步骤 | 后端测试 | 前端测试 | 覆盖度 |
|----------|---------|---------|--------|
| platform_admin 创建租户 | ❌ 无 | ❌ 无 | 🔴 无 |
| 新增 b2b_admin 用户 | ❌ 无 | ❌ 无 | 🔴 无 |
| b2b_admin 创建牧场 | ❌ 无 | ❌ 无 | 🔴 无 |
| 分配牧场给 owner | ❌ 无 | ❌ 无 | 🔴 无 |
| owner 管理牧工 | ❌ 无 | ❌ 无 | 🔴 无 |

**旅程覆盖度：🔴 0%** — 这是系统的核心业务流程，完全无 e2e 测试覆盖。

### 2.6 告警状态机

```
pending → acknowledged → handled → archived（非法跳转返回 409）
```

| 状态转换 | 后端测试 | 覆盖度 |
|----------|---------|--------|
| pending → acknowledged | ✅ JourneyIntegrationTest | 🟡 仅 owner 视角 |
| acknowledged → handled | ❌ 无 | 🔴 无 |
| handled → archived | ❌ 无 | 🔴 无 |
| 非法跳转 409 | ❌ 无 | 🔴 无 |
| worker 确认 → owner 处理（跨角色协作） | ❌ 无 | 🔴 无 |

**覆盖度：🔴 10%** — 告警是核心业务流程，4 个状态转换仅验证了 1 个。

### 2.7 路由守卫

| 规则 | 前端测试 | 覆盖度 |
|------|---------|--------|
| worker 无 admin Tab | ✅ route_guard_test | 🟢 |
| worker 4 Tab | ✅ route_guard_test | 🟢 |
| platform_admin 无 App 导航 | ✅ route_guard_test | 🟢 |
| b2b_admin 无 App 导航 | ✅ route_guard_test | 🟢 |
| owner 5 Tab | ✅ route_guard_test | 🟢 |
| 未登录 → /login 重定向 | ❌ 无 | 🔴 无 |
| worker 访问 /admin → 重定向 /twin | ❌ 无 | 🔴 无 |
| worker 访问 /mine/workers → 重定向 | ❌ 无 | 🔴 无 |

**覆盖度：🟡 55%** — 导航栏可见性覆盖好，但重定向逻辑未测试。

### 2.8 功能门控

| 层面 | 后端测试 | 前端测试 | 覆盖度 |
|------|---------|---------|--------|
| Tier 权限判断 | ✅ QuotaApplicationServiceTest (14) | ✅ subscription_tier_test (26) | 🟢 好 |
| 配额拦截器 | ✅ QuotaInterceptorTest (9) | — | 🟢 好 |
| 锁定功能覆盖层 | — | ✅ locked_overlay_test (8) | 🟢 好 |
| 功能 flag 定义 | — | ✅ subscription_tier_test 内 FeatureFlags 组 | 🟢 好 |

**覆盖度：🟢 80%** — 功能门控是覆盖最好的维度。

### 2.9 GPS → 围栏越界 → 告警

| 层面 | 后端测试 | 覆盖度 |
|------|---------|--------|
| 完整事件流（GPS更新→越界检测→创建告警） | ✅ GpsAlertFlowTest (9) | 🟢 好 |
| 牲畜在围栏内不触发 | ✅ GpsAlertFlowTest | 🟢 |
| 越出多围栏创建多告警 | ✅ GpsAlertFlowTest | 🟢 |
| 禁用围栏跳过 | ✅ GpsAlertFlowTest | 🟢 |
| 无安装记录/无牲畜/无围栏 边界条件 | ✅ GpsAlertFlowTest | 🟢 |

**覆盖度：🟢 90%** — GPS-告警事件流是覆盖最完整的跨上下文集成。

---

## 3. 按测试层级分析

### 3.1 后端测试层级分布

| 测试层级 | 文件数 | @Test 数 | 占比 | 说明 |
|---------|--------|---------|------|------|
| **领域模型单元测试** | 14 | ~170 | 65% | 纯业务规则，覆盖充分 |
| **应用服务单元测试** | 10 | ~60 | 23% | 用例编排，Mock 依赖 |
| **集成/端到端测试** | 2 | ~11 | 4% | JourneyIntegrationTest + GpsAlertFlowTest |
| **基础设施测试** | 1 | 14 | 5% | Mapper RoundTrip |
| **Web 层测试** | 2 | 15 | 6% | QuotaInterceptor + FarmIdPathParser |
| **HTTP 级 Controller 测试** | **0** | **0** | **0%** | ❌ **35 个 Controller 无任何 HTTP 测试** |

### 3.2 前端测试层级分布

| 测试层级 | 文件数 | test 数 | 占比 | 说明 |
|---------|--------|---------|------|------|
| **纯逻辑单元测试** | 6 | ~55 | 37% | subscription_tier, role_permission, fence_logic, coord_transform |
| **Widget 测试** | 12 | ~70 | 47% | route_guard, locked_overlay, fence_edit, tenant_detail |
| **冒烟测试** | 3 | ~6 | 4% | widget_smoke, widget_test |
| **页面级 e2e 测试** | **0** | **0** | **0%** | ❌ **39 条路由无页面级测试** |
| **认证流 e2e 测试** | **0** | **0** | **0%** | ❌ **登录/登出无测试** |

---

## 4. 关键缺口清单（按优先级排序）

### P0 — 阻断性缺口（核心业务流程无验证）

| # | 缺口 | 影响旅程 | 建议测试 |
|---|------|---------|---------|
| 1 | **角色创建链 e2e** | 2.5 全链 | `platform_admin 创建租户 → 创建 b2b_admin → b2b_admin 创建牧场 → 分配 owner → owner 看到牧场` |
| 2 | **告警状态机完整 e2e** | 2.6 全链 | `pending → acknowledged(worker) → handled(owner) → archived(owner) + 非法跳转 409` |
| 3 | **认证 API e2e** | 所有旅程入口 | `登录成功/失败/错误密码/未注册手机 → token 验证 → 过期处理` |
| 4 | **租户 CRUD e2e** | 2.1 核心操作 | `创建/查询/更新/启停租户 → 权限隔离验证（b2b_admin 不能操作其他租户）` |

### P1 — 严重缺口（主要功能无端到端验证）

| # | 缺口 | 影响旅程 | 建议测试 |
|---|------|---------|---------|
| 5 | **牧场 CRUD e2e** | 2.2 核心操作 | `b2b_admin 创建牧场 → owner 查看到 → 切换牧场 → 数据隔离` |
| 6 | **用户管理 e2e** | 2.1 | `platform_admin 创建/启停/重置密码 → b2b_admin 创建 worker` |
| 7 | **围栏 API e2e** | 2.3 核心操作 | `创建/编辑/删除围栏 → 越界触发告警 → 权限验证（worker 不可操作）` |
| 8 | **前端登录页 e2e** | 所有旅程入口 | Flutter widget 测试：登录表单 → 选择角色 → 提交 → 重定向 |
| 9 | **前端路由重定向 e2e** | 2.7 | `未登录访问任何页 → 重定向 /login → worker 访问 /admin → 重定向 /twin` |
| 10 | **多牧场切换 e2e** | 2.3 | `owner 切换牧场 → 牲畜/围栏/告警数据随牧场切换` |

### P2 — 重要缺口（功能完整性）

| # | 缺口 | 影响旅程 | 建议测试 |
|---|------|---------|---------|
| 11 | **设备/安装 e2e** | 2.3 | `注册设备 → 分配 License → 安装到牲畜 → GPS 数据上报` |
| 12 | **订阅升级 e2e** | 2.3 | `basic → standard 升级 → 功能门控变化 → 配额更新` |
| 13 | **合同签署 e2e** | 2.1 / 2.2 | `创建合同 → 签署 → 状态变更` |
| 14 | **分润计算 e2e** | 2.2 | `订阅计费 → 分润期间计算 → 对账明细` |
| 15 | **Open API e2e** | API 消费者 | `API Key 认证 → 频率限制 → 数据查询` |
| 16 | **牧工管理 e2e** | 2.3 | `owner 添加/移除牧工 → worker 登录看到指派牧场` |
| 17 | **Dashboard/统计 e2e** | 2.3 | `看板汇总数据 → 统计页面数据源` |

---

## 5. 测试深度分析

### 5.1 JourneyIntegrationTest 深度评估

当前的唯一 e2e 测试 `JourneyIntegrationTest.fullCustomerJourney()` 存在以下深度问题：

| 维度 | 现状 | 建议 |
|------|------|------|
| **粒度** | 1 个巨型测试方法包含 7 个步骤 | 拆分为独立的旅程测试，每个步骤独立验证 |
| **断言深度** | 主要验证 `status == 200` + 数据计数 | 需增加：字段值验证、关联数据一致性、分页正确性 |
| **负面场景** | 仅 1 个权限拒绝（worker 处理告警） | 需增加：未认证访问、跨租户访问、越权操作 |
| **数据验证** | 验证了种子数据数量 | 需增加：创建/更新后数据持久化验证 |
| **边界条件** | 无 | 需增加：空列表、分页边界、非法参数 |

### 5.2 前端测试深度评估

| 维度 | 现状 | 建议 |
|------|------|------|
| **页面渲染** | route_guard 仅验证导航栏 Key | 需要页面级测试验证实际内容渲染 |
| **用户交互** | 几乎无 | 需要 tap → 等待响应 → 验证状态变化 |
| **数据流** | 无 Repository → Controller → UI 验证 | 需要 mock API → 验证 UI 呈现 |
| **认证流** | SessionController 被 override | 需要测试真实登录流程 |

---

## 6. 总体评分

| 旅程 | 覆盖度 | 评分 |
|------|--------|------|
| 2.1 平台入驻旅程 | 15% | 🔴 |
| 2.2 B端管理旅程 | 10% | 🔴 |
| 2.3 牧场主旅程 | 30% | 🟡 |
| 2.4 牧工旅程 | 20% | 🔴 |
| 2.5 角色创建链 | 0% | 🔴 |
| 2.6 告警状态机 | 10% | 🔴 |
| 2.7 路由守卫 | 55% | 🟡 |
| 2.8 功能门控 | 80% | 🟢 |
| 2.9 GPS→告警事件流 | 90% | 🟢 |
| **总体** | **23%** | **🔴** |

---

## 7. 改进建议路线图

### Phase 1：核心旅程 e2e（建议优先）

1. **后端 Controller HTTP 测试骨架** — 为 35 个 Controller 建立 `@WebMvcTest` 或 `TestRestTemplate` 测试基类
2. **角色创建链 e2e** — `platform_admin → 租户 → 用户 → 牧场 → owner`
3. **告警状态机 e2e** — 4 个状态转换 + 跨角色协作 + 非法跳转
4. **认证 API e2e** — 登录/登出/token 验证/权限拒绝

### Phase 2：功能模块 e2e

5. **牧场 CRUD + 切换 e2e**
6. **围栏 API e2e**（已有良好的单元测试基础）
7. **设备/安装 e2e**
8. **订阅/门控 e2e**（已有良好的单元测试基础）

### Phase 3：前端页面 e2e

9. **登录页 widget 测试**
10. **路由重定向 e2e**
11. **核心页面渲染测试**（告警列表、围栏列表、牧场切换）

### Phase 4：跨端 e2e

12. **前端 → 后端 全链路测试**（Flutter integration_test + Spring Boot Testcontainers）
13. **Open API 端到端**（API Key → 频率限制 → 数据查询）
