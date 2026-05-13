# 租户入驻流程设计 — Phase 1

> Issue #40: 构建 MVP
> 状态: 设计完成，待实施

## 背景

当前后端 MVP Phase 1 的 Identity + Ranch + IoT 三个限界上下文已实现（Task 1-14），但缺少完整的"租户入驻到日常使用"端到端流程。owner 用户登录后如果没有预置牧场数据，会看到空白界面，无法完成自助创建。

本设计补齐这个缺口，使 Phase 1 能够支撑从"管理员开通"到"owner 日常使用"的完整闭环。

### 竞品参考

基于 Cattler、AgriLiv、TraceX、LoRa 畜牧系统方案的竞品分析，本设计纳入了以下洞察：

- 电子围栏是用户购买的首要动机之一（Navynav） → Phase 1 对应：向导 Step 2 将围栏绘制作为自然步骤而非可选额外操作
- 设备激活是用户旅程中摩擦最大的环节（TraceX） → 由 #44 Phase 3 接续，Phase 1 用简化的单设备注册
- 告警推送而非事后查看才是核心价值（Cattler） → 由 #45 Phase 2 接续
- 多角色协作是牧场管理的刚需（AgriLiv） → 由 #47 Phase 2 接续

---

## 1. 完整客户旅程（4 幕）

```
第一幕：管理员开通（admin 后台，已实现）
  ① platform_admin 创建租户（POST /api/v1/admin/tenants）
  ② platform_admin 创建 owner 用户（POST /api/v1/admin/users）
  ③ 将手机号+密码通知给牧场主

第二幕：首次登录 + 牧场创建（Flutter App）
  ④ owner 用手机号+密码登录（POST /api/v1/auth/login）
  ⑤ 前端 GET /farms → 空列表
  ⑥ Dashboard 显示空状态引导卡片
  ⑦ owner 点击 → 进入向导式牧场创建：
     Step 1: 牧场名 / 面积 / 地图选中心点 → POST /farms（完成 ⑧ 牧场创建与 owner 关联）
     Step 2: 在地图上绘制围栏（可跳过）→ POST /farms/{id}/fences
     Step 3: 完成
  ⑧ Step 1 成功即完成牧场创建 + 自动写入 user_farm_assignments
  ⑨ 向导结束 → ApiCache 重拉 /farms + 设 activeFarmId + 拉 farm-scoped 数据 → Dashboard 正常渲染

第三幕：设备 + 牲畜（简化版，无网关概念）
  ⑩ owner 注册设备（POST /farms/{id}/devices，单个注册）
  ⑪ owner 添加牲畜（POST /farms/{id}/livestock）
  ⑫ owner 安装设备到牲畜（POST /farms/{id}/installations）

第四幕：日常使用
  ⑬ 地图查看 / 告警处理 / 围栏管理
  ⑭ 创建更多牧场（牧场切换器中操作）
```

### Phase 1 边界

- **仅保证 owner 单人闭环**，成员邀请（邀请 worker）为 Phase 2
- **设备注册为单个注册**，网关概念和批量激活为 Phase 3
- **告警仅在 App 内查看**，推送/SMS/WhatsApp 通知渠道为 Phase 2
- **管理员代开通路径**，自助注册为 Phase 2

### Phase 2/3 待做项（已记录 GitHub Issues）

| Issue | 内容 | 阶段 |
|-------|------|------|
| #44 | 网关概念 + 批量设备激活 | Phase 3 |
| #45 | 告警通知渠道配置 | Phase 2 |
| #46 | 自助注册 + 试用 | Phase 2 |
| #47 | 扩展角色体系 manager/vet | Phase 2 |
| —（待建 Issue） | 成员邀请（从 stub 改真实实现） | Phase 2（与 #47 同期） |

---

## 2. 后端改动

后端已有 90% 的端点可直接使用，Phase 1 只需 2 项实质改动 + 1 项文档标注。

### 2.1 端点路径说明

App 侧的牧场操作走 JWT 租户上下文，不是 URL 里的 tenantId：

| 操作 | 端点 | 租户来源 |
|------|------|---------|
| 创建牧场 | `POST /api/v1/farms` | JWT tid claim → TenantContext |
| 列举牧场 | `GET /api/v1/farms` | JWT tid claim → TenantContext |
| 创建围栏 | `POST /api/v1/farms/{farmId}/fences` | path farmId |
| 注册设备 | `POST /api/v1/farms/{farmId}/devices` | path farmId |
| 添加牲畜 | `POST /api/v1/farms/{farmId}/livestock` | path farmId |
| 安装设备 | `POST /api/v1/farms/{farmId}/installations` | path farmId |

### 2.2 改动 1：创建牧场自动关联 owner

**当前行为**：`FarmApplicationService.createFarm()` 只 save 牧场，不写 `user_farm_assignments`。

**目标行为**：创建牧场时，如果请求者是该租户下的 owner，自动写入一条 `user_farm_assignments` 记录。

**改动点**：
- `FarmController.createFarm()`（App 侧，`POST /api/v1/farms`）从 SecurityContext 取 userId，传入 Service
- `FarmApplicationService` 增加 `UserRepository` + `UserFarmAssignmentRepository` 依赖（`UserFarmAssignmentJpaEntity` 和 `SpringDataUserFarmAssignmentRepository` 已存在）
- `createFarm()` 方法内增加：校验 userId 是该 tenant 的 owner → 写 user_farm_assignments（userId, farmId, OWNER, ACTIVE）

**两条入口区分**：
- App 侧 `FarmController`（`POST /api/v1/farms`）：传入 JWT userId，仅当该用户为本租户 owner 时写分配
- Admin 侧 `FarmAdminController`（`POST /api/v1/admin/farms`）：请求者为 platform_admin，无"当前租户 owner"语义。Service 接受可选 `ownerUserId` 参数，为 null 时跳过自动分配，避免误把 platform_admin 写进分配表

**边界情况**：
- 非 owner 用户（如 worker）调 `POST /farms` → 由现有权限校验拒绝，不走到自动关联逻辑
- 重复分配（同一 userId + farmId） → `user_farm_assignments` 表有 UNIQUE(user_id, farm_id) 约束，写入前先查询，已存在则跳过

**已有基础设施**：`user_farm_assignments` 表已在 `V1__create_identity_tables.sql` 中定义；`UserFarmAssignmentJpaEntity` 和 `SpringDataUserFarmAssignmentRepository` 已存在，但缺少 domain 层的 Repository 接口和 Mapper，需补充。

**注意**：当前 `FarmScopeInterceptor` 只校验"牧场是否属于 JWT 里的租户"，不查 `user_farm_assignments`。写入分配表是为数据模型一致性和后续 Phase 2"按牧场授权"做准备。

### 2.3 改动 2：Dashboard 统计字段

**当前 App 实际读取路径**：`GET /farms/{farmId}/dashboard` → `LiveDashboardRepository` → `ApiCache.dashboardMetrics`

统计字段必须落在 App 实际读取的端点上。当前 `DashboardController.summary` 已返回以下字段：

```json
{
  "livestockCount": 45,
  "fenceCount": 5,
  "onlineDeviceCount": 0,
  "activeAlertCount": 12,
  "healthSummary": { ... }
}
```

Phase 1 需确保：
- `onlineDeviceCount` 由真实设备服务计算（当前为占位 0），而非硬编码
- 前端 `ApiCache._normalizeDashboardMetrics` 的字段映射与上述键名一致
- 避免在 `GET /farms/{id}` 单独返回统计导致前端需增加额外请求

### 2.4 文档标注：成员管理为 Phase 1 stub

`POST /farms/{farmId}/members` 和 `GET /farms/{farmId}/members` 当前返回 stub 响应。在代码注释和 API 契约文档中标注：

```
// Phase 1 stub — 成员邀请在 Phase 2 实现（与 #47 扩展角色同期）
// Phase 1 仅保证 owner 单人闭环
```

### 2.5 不需要改动的端点（已实现可直接使用）

| 操作 | 端点 | 状态 |
|------|------|------|
| 登录 | `POST /api/v1/auth/login` | 已实现 |
| 创建租户 | `POST /api/v1/admin/tenants` | 已实现 |
| 创建用户 | `POST /api/v1/admin/users` | 已实现 |
| 创建围栏 | `POST /api/v1/farms/{farmId}/fences` | 已实现 |
| 注册设备 | `POST /api/v1/farms/{farmId}/devices` | 已实现 |
| 添加牲畜 | `POST /api/v1/farms/{farmId}/livestock` | 已实现 |
| 安装设备 | `POST /api/v1/farms/{farmId}/installations` | 已实现 |
| GPS 模拟 | GpsSimulator @Scheduled | 已实现 |

---

## 3. 前端改动

### 3.1 Dashboard 空状态引导

**数据源**：不修改 DashboardController（只负责 DashboardViewData），通过 `FarmSwitcherController` / `ApiCache.myFarms` 判断是否有牧场。

**实现方式**：
- DashboardPage 中 `ref.watch(farmSwitcherControllerProvider)` 检测 `!hasFarms`
- 有牧场 → 正常渲染 Dashboard 内容
- 无牧场 → 渲染空状态引导卡片（"您还没有牧场，点击创建第一个牧场" + 创建按钮）
- Live 模式下 `ApiCache.init` 已拉 `GET /farms`，无需额外 fetch
- 点击创建按钮 → 跳转牧场创建向导

**Mock 模式适配**：当前 `FarmSwitcherController._mockState` 固定有两家牧场，需为"新租户演示"场景留 mock 分支或单独开关。

### 3.2 牧场创建向导（3 步）

新建 `FarmCreationWizardPage`，向导内维护自己的状态机（step 1→2→3）。

**Step 1 — 基本信息 + 地图选点**
- 牧场名称（必填）、面积（可选）
- 地图点击选中心点（复用 map_config.dart 的 MapConfig.defaultCenter，默认长沙）
- 调用 `POST /api/v1/farms` → 后端创建牧场 + 自动关联 owner
- **关键顺序依赖**：Step 1 成功后，必须先将新 farmId 设为 `ApiCache.activeFarmId`，再进入 Step 2

**Step 2 — 绘制围栏（可跳过）**
- **不是直接复用 FenceController**（它依赖已有 fenceId 的 FenceItem 加载逻辑）
- 而是新建一层"草稿多边形绘制"组件：
  - 底层复用 `fence_edit_operations`（顶点移动/插入/删除/平移）
  - 底层复用 `fence_edit_session`（撤销/重做栈）
  - 不依赖 FenceItem 的加载逻辑，使用临时草稿状态
- 绘制完成 → 生成 vertices JSON → `POST /api/v1/farms/{farmId}/fences`（复用 ApiCache.createFenceRemote）
- 提供"稍后设置"跳过按钮
- **前端工作量说明**：不止"纯复用"，需要组合现有方法 + 新建向导状态机 + 草稿围栏管理层

**Step 3 — 完成**
- 显示创建成功摘要（牧场名、面积、围栏数）
- [进入牧场] 按钮 → 触发 `ApiCache.init`（重拉 `/farms` + 设 activeFarmId + 拉 farm-scoped 数据），然后跳转主 Dashboard
- 仅 go 到 Dashboard 可能仍读到旧的空 myFarms/metrics，必须先刷新缓存

### 3.3 统计卡片数据源

Dashboard 正常显示时，统计卡片数据来自 `GET /farms/{farmId}/dashboard` 增强的统计字段（后端改动 2）。前端在 `LiveDashboardRepository` 解析新增字段即可，无需额外请求。

### 3.4 设备-牲畜绑定

**现状**：
- 后端：`POST /farms/{farmId}/installations` 已实现
- Flutter：几乎没有 installations 相关代码，需完整新建

**前端需新建**：
- ApiCache 中增加 `createInstallation()` HTTP 调用
- 设备管理页面增加"安装到牲畜"UI 入口（选择设备 → 选择牲畜 → 确认安装）
- 安装成功后刷新 devices 缓存和地图数据

### 3.5 前端改动汇总

| 改动 | 新建/改动 | 依赖 |
|------|----------|------|
| Dashboard 空状态 | 改动 DashboardPage | FarmSwitcherController |
| 牧场创建向导 | 新建 WizardPage + 草稿围栏组件 | 后端改动 1（自动关联） |
| 围栏绘制 | 复用底层编辑能力，新建草稿管理层 | 后端无（fences API 已有） |
| 统计卡片 | 改动 LiveDashboardRepository 解析 | 后端改动 2（/dashboard 字段对齐 + onlineDeviceCount 真实计算） |
| 设备-牲畜绑定 | 新建 installations HTTP + UI 入口 | 后端无（API 已有）；Flutter 需完整新建 |
| Mock 模式适配 | 改动 FarmSwitcherController | 无 |

---

## 4. 实施范围总结

### Phase 1 实施

**后端（2 项改动）：**
1. `FarmApplicationService.createFarm()` — 自动写入 `user_farm_assignments`（需补充 domain 层 Repository 接口和 Mapper，JPA 层已存在）
2. `GET /farms/{farmId}/dashboard` — 确认统计字段（livestockCount / onlineDeviceCount / activeAlertCount / fenceCount）与前端解析对齐；onlineDeviceCount 改为真实计算（当前占位 0）

**前端（5 项改动）：**
1. DashboardPage 空状态引导卡片
2. FarmCreationWizardPage 三步向导
3. 草稿围栏绘制组件
4. FarmSwitcherController Mock 模式适配
5. installations API 调用 + UI 入口

### 不需要改动的部分

- 认证流程（登录、JWT、SecurityConfig）
- 管理员开通（创建租户、创建用户）
- 围栏 CRUD API
- 设备注册 API
- 牲畜 CRUD API
- GPS 模拟数据
- Docker Compose 部署
- CI/CD Pipeline

---

## 5. 验收标准

### E2E 验收：新租户 owner 完整流程

| 步骤 | 操作 | 预期结果 |
|------|------|---------|
| 1 | platform_admin 创建租户 + owner 用户 | 租户和用户创建成功 |
| 2 | owner 登录（手机号+密码） | JWT 返回，token 含 tid 和 role=OWNER |
| 3 | 登录后加载 Dashboard | farms 为空 → 显示"创建第一个牧场"引导卡片 |
| 4 | 点击创建 → 填写牧场名+地图选点 → 提交 | POST /farms 成功，返回 farmId；user_farm_assignments 自动写入 |
| 5 | 进入 Step 2 围栏绘制 → 跳过 | 直接到 Step 3 |
| 6 | Step 3 → 进入牧场 | ApiCache 刷新，Dashboard 正常显示统计卡片（数据为 0） |
| 7 | 注册设备 + 添加牲畜 + 安装设备到牲畜 | 三个操作均成功，地图上显示设备位置 |
| 8 | 返回 Dashboard | livestockCount=1, deviceCount≥1 等统计更新 |

### 边界情况

| 场景 | 预期行为 |
|------|---------|
| worker 用户登录（无牧场） | 权限校验拒绝创建牧场操作，不触发自动关联 |
| Step 1 创建牧场成功，Step 2 围栏 POST 失败 | 牧场已创建且可用，围栏未创建但牧场正常工作 |
| owner 已有一个牧场，再创建第二个 | 第二个牧场也自动关联 owner（UNIQUE 约束允许同一用户分配到不同牧场） |
| platform_admin 通过 admin 端点创建牧场 | 不触发自动关联（ownerUserId 为 null 时跳过） |
| Mock 模式新租户演示 | FarmSwitcherController 返回空牧场列表，触发引导卡片 |
