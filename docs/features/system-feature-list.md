# 智慧畜牧系统功能清单（统一版）

> 合并前端（Flutter）+ 后端（Spring Boot）代码分析，更新时间 2026-06-01

---

# 第一部分：前后端差异对比

## 1. 后端已实现但前端未对接的功能

| 功能领域 | 后端能力 | 前端状态 | 说明 |
|----------|---------|---------|------|
| **JWT refresh** | `POST /auth/refresh` 续签 | ❌ 未对接 | 前端无 token 自动续签逻辑 |
| **JWT logout** | `POST /auth/logout` | ❌ 未对接 | 前端仅清除本地 session |
| **修改密码** | `PUT /me/password` | ❌ 未对接 | 前端无修改密码页面 |
| **更新个人信息** | `PUT /me` | ❌ 未对接 | 前端个人页只读展示 |
| **租户自服务** | `GET/PUT /tenants/me` | ❌ 未对接 | 前端无租户信息编辑入口 |
| **租户阶段变更** | `PUT /admin/tenants/{id}/phase` | ❌ 未对接 | 前端无 phase 变更 UI |
| **租户状态变更** | `PUT /admin/tenants/{id}/status` | ⚠️ 部分 | 前端有用户启停，租户启停未确认 |
| **牲畜 CRUD** | `POST/PUT/DELETE /livestock` | ⚠️ 部分 | 前端有详情页，无新增/编辑/删除 UI |
| **围栏强制更新** | `PUT /fences/{id}/force` | ❌ 未对接 | 前端围栏编辑只走普通 PUT |
| **设备注册** | `POST /devices` | ❌ 占位 | 前端 FAB 仅弹 SnackBar |
| **设备激活/停用** | `PUT /devices/{id}/activate\|decommission` | ❌ 未对接 | 前端无激活/停用操作 |
| **设备许可证** | `GET/POST/PUT /device-licenses` | ❌ 未对接 | 前端无许可证管理页面 |
| **GPS 历史轨迹** | `GET /livestock/{id}/gps-logs` | ❌ 占位 | 前端"查看完整轨迹"仅跳转围栏页 |
| **地图概览** | `GET /map/overview` | ⚠️ 未确认 | 前端围栏页直接加载围栏+牲畜 |
| **合同签署** | `POST /admin/contracts/{id}/sign` | ❌ 未对接 | 前端合同页无签署操作 |
| **分润计算** | `POST /admin/revenue/calculate` | ❌ 未对接 | 前端无手动触发计算 UI |
| **分润重算** | `POST /admin/revenue/periods/{id}/recalculate` | ❌ 未对接 | 前端无重算按钮 |
| **功能门控管理** | `GET/PUT /admin/feature-gates` | ❌ 未对接 | 前端无 FeatureGate 配置页面 |
| **订阅 tier 变更** | `PUT /subscription/tier` | ⚠️ 间接 | 前端通过 checkout 流程间接变更 |
| **订阅取消** | `POST /subscription/cancel` | ❌ 未对接 | 前端无取消订阅操作 |
| **订阅用量查询** | `GET /subscription/usage` | ❌ 未对接 | 前端用量进度条用本地计算 |
| **合作方确认分润** | `POST /revenue/periods/{id}/confirm`（B端） | ⚠️ 未确认 | 前端 B 端对账页有确认按钮，需确认是否调用 |
| **平台确认分润** | `POST /admin/revenue/periods/{id}/confirm` | ❌ 未对接 | 前端无平台确认操作 |
| **审计日志查询** | `GET /admin/audit-logs` | ❌ 未对接 | 前端无审计日志页面 |
| **Open API（第三方）** | 8 个端点，API Key 认证 | ❌ 无前端 | 面向第三方开发者，无 App 内 UI |
| **API Portal 管理** | 5 个端点（审批/限流/作用域） | ❌ 未对接 | 前端无审批/限流设置 UI |
| **使用量分析** | 4+3 个端点（overview/trend） | ❌ 未对接 | 前端无使用量分析页面 |
| **瓦片管理（Admin）** | 7+3 个端点（区域/任务/下载） | ⚠️ 部分 | 前端有离线瓦片管理页，但仅读取本地状态 |
| **分析事件埋点** | `POST /analytics/events` | ❌ 未对接 | 前端无埋点上报 |
| **健康总览** | `GET /farms/{farmId}/health/overview` | ⚠️ 未对接 | 前端孪生首页用 Dashboard API |
| **重置用户密码** | `POST /admin/users/{userId}/reset-password` | ⚠️ 未确认 | 需确认前端是否有重置密码 UI |
| **订阅服务管理** | `CRUD /admin/subscription-services` | ⚠️ 部分 | 前端有 Controller，页面待确认 |

## 2. 前端已实现但后端缺失/不对等的功能

| 功能领域 | 前端实现 | 后端状态 | 说明 |
|----------|---------|---------|------|
| **数据统计页** | `StatsPage`（stats 模块） | ⚠️ 无独立端点 | 后端无 `/stats` 端点，可能由 Dashboard 聚合 |
| **离线围栏编辑** | 本地缓存 + 冲突解决页面 | ❌ 后端无感知 | 离线编辑是纯客户端能力，后端仅接受最终 PUT |
| **离线牲畜位置** | `LivestockPositionCache` | ❌ 后端无感知 | 纯客户端缓存 |
| **离线瓦片管理** | `OfflineTileManager` + MBTiles | ⚠️ 部分 | 后端有 tile 端点，但前端主要读本地 MBTiles |
| **三级瓦片降级** | SmartTileProvider 自动切换 | ❌ 后端无感知 | 纯前端逻辑 |
| **坐标转换** | WGS-84 ↔ GCJ-02 | ❌ 后端无对应 | 纯前端（降级到高德时使用） |
| **围栏命中检测** | 两级优先级 + 候选 BottomSheet | ❌ 后端无对应 | 纯前端交互逻辑 |
| **围栏编辑撤销/重做** | FenceEditSession + undo/redo 栈 | ❌ 后端无对应 | 纯前端编辑会话 |
| **多触点防护** | 阻止多点触控误操作 | ❌ 后端无对应 | 纯前端手势处理 |
| **牧场创建向导** | 3 步向导（基本信息→围栏→完成） | ✅ 有 API | 前端调用 `POST /farms` + `POST /fences` |
| **订阅套餐对比表** | FeatureComparisonTable + TierCard | ✅ 有 API | 前端展示，后端提供 `/subscription/plans` |

## 3. 前后端对齐但实现深度差异的功能

| 功能 | 前端实现深度 | 后端实现深度 | 差异说明 |
|------|------------|------------|---------|
| **告警** | 展示 P0 列表 + 状态流转 | 完整状态机 + 批量处理 + 筛选 | 前端仅展示首条 + P0 示例行，未充分使用列表分页和筛选 |
| **设备管理** | 列表 + 安装对话框（占位） | 完整 CRUD + 许可证 + 激活/停用 | 前端大量占位，未对接激活/停用/许可证 |
| **B端控制台** | 7 个页面 | 3 个应用端 API + 6 个管理端 API | 前端页面齐全但数据对接待确认 |
| **Owner 后台** | 概览 + 租户列表 Tab | 完整的 admin dashboard API | 前端后台较简，未用全部后端能力 |
| **健康模块** | 4 场景（发热/消化/发情/疫病）列表+详情 | 5 个 Controller + 4 个领域服务 + 6 张表 | 前端 UI 框架已搭好，数据来自 seed，实时分析待对接 |

---

# 第二部分：统一功能清单

## 一、系统全局能力

| 能力 | 前端 | 后端 | 状态 |
|------|------|------|------|
| **JWT 认证** | 手机号+密码登录 | BCrypt 校验 + JWT 签发 + refresh + logout | ✅ 登录已对接，refresh/logout 未对接 |
| **多角色** | 5 种角色路由守卫 | 5 种角色枚举 + 权限校验 | ✅ 已对接 |
| **多租户隔离** | FarmSwitcher 切换 | tenant_id 全表隔离 + FarmScopeInterceptor | ✅ 已对接 |
| **订阅与功能门控** | 23 个 FeatureFlag + 4 tier | FeatureGate 表 + QuotaInterceptor + 2 种 GateType | ✅ 门控已对接，管理端未对接 |
| **过期提醒** | ExpiryPopupHandler 弹窗 | SubscriptionStatus.trialEndsAt / currentPeriodEnd | ✅ 已对接 |
| **审计日志** | 无 UI | AuditLog + AuditLogEventListener 自动记录 | ❌ 后端已实现，前端无页面 |
| **API 频率限制** | 无 UI | RateLimitService（Redis + Lua） | ❌ 后端已实现，前端无感知 |
| **健康检查** | 无 | `GET /health` 存活探针 | ✅ 后端独立 |
| **跨平台** | iOS / Android / Web | Docker Compose 部署 | ✅ |

---

## 二、按限界上下文组织的功能矩阵

### 2.1 Identity — 身份与租户

| 功能 | 前端页面 | 后端 API | 对接状态 |
|------|---------|---------|---------|
| 手机号+密码登录 | LoginPage | `POST /auth/login` | ✅ |
| JWT 续签 | — | `POST /auth/refresh` | ❌ |
| 登出 | — | `POST /auth/logout` | ❌ |
| 获取当前用户 | MinePage | `GET /me` | ✅ |
| 更新个人信息 | — | `PUT /me` | ❌ |
| 修改密码 | — | `PUT /me/password` | ❌ |
| 获取当前租户 | — | `GET /tenants/me` | ❌ |
| 更新租户信息 | — | `PUT /tenants/me` | ❌ |
| 牧场列表 | FarmSwitcher | `GET /farms` | ✅ |
| 创建牧场 | FarmCreationWizardPage | `POST /farms` | ✅ |
| 牧场详情 | — | `GET /farms/{id}` | ✅ |
| 更新牧场 | — | `PUT /farms/{id}` | ✅ |
| 牧场成员列表 | WorkerListPage | `GET /farms/{id}/members` | ✅ |
| 添加牧场成员 | — | `POST /farms/{id}/members` | ⚠️ |
| 移除牧场成员 | — | `DELETE /farms/{id}/members/{userId}` | ⚠️ |
| **平台管理** | | | |
| 租户列表 | TenantListPage | `GET /admin/tenants` | ✅ |
| 创建租户 | TenantCreatePage | `POST /admin/tenants` | ✅ |
| 租户详情 | TenantDetailPage | `GET /admin/tenants/{id}` | ✅ |
| 更新租户 | TenantEditPage | `PUT /admin/tenants/{id}` | ✅ |
| 租户下牧场 | — | `GET /admin/tenants/{id}/farms` | ✅ |
| 租户状态变更 | — | `PUT /admin/tenants/{id}/status` | ⚠️ |
| 租户阶段变更 | — | `PUT /admin/tenants/{id}/phase` | ❌ |
| 用户列表 | TenantDetailPage 内 | `GET /admin/users` | ✅ |
| 创建用户 | — | `POST /admin/users` | ✅ |
| 用户详情 | — | `GET /admin/users/{id}` | ✅ |
| 更新用户 | — | `PUT /admin/users/{id}` | ⚠️ |
| 用户状态变更 | — | `PUT /admin/users/{id}/status` | ✅ |
| 重置密码 | — | `POST /admin/users/{id}/reset-password` | ⚠️ |
| 牧场管理 | — | `GET/POST /admin/farms` | ✅ |
| API Key 管理 | ApiAuthPage（简） | `CRUD /admin/api-keys` | ⚠️ |
| 审计日志 | — | `GET /admin/audit-logs` | ❌ |
| 管理仪表板 | AdminPage 概览 Tab | `GET /admin/dashboard` | ✅ |

### 2.2 Ranch — 牧场业务

| 功能 | 前端页面 | 后端 API | 对接状态 |
|------|---------|---------|---------|
| 牲畜列表 | — | `GET /farms/{id}/livestock` | ⚠️ |
| 新增牲畜 | — | `POST /farms/{id}/livestock` | ❌ |
| 牲畜详情 | LivestockDetailPage | `GET /livestock/{lid}` | ✅ |
| 更新/删除牲畜 | — | `PUT/DELETE /livestock/{lid}` | ❌ |
| 围栏列表 | FencePage 抽屉 | `GET /farms/{id}/fences` | ✅ |
| 创建围栏 | FenceFormPage | `POST /farms/{id}/fences` | ✅ |
| 更新围栏 | FencePage 编辑 | `PUT /farms/{id}/fences/{fid}` | ✅ |
| 强制更新围栏 | — | `PUT /fences/{fid}/force` | ❌ |
| 删除围栏 | FencePage 删除 | `DELETE /farms/{id}/fences/{fid}` | ✅ |
| 围栏越界检测 | — | FenceBreachDetector（自动） | ✅ |
| 告警列表 | AlertsPage | `GET /farms/{id}/alerts` | ✅ |
| 确认/处理/归档告警 | AlertsPage 按钮 | `POST /alerts/{id}/acknowledge\|handle\|archive` | ✅ |
| 批量处理告警 | SnackBar 占位 | `POST /alerts/batch-handle` | ❌ |
| 仪表板 | TwinOverviewPage | `GET /farms/{id}/dashboard` | ✅ |
| 地图概览 | FencePage | `GET /farms/{id}/map` | ⚠️ |
| 瓦片应用端 | — | 3 个端点 `/farms/{id}/tile-*` | ⚠️ |
| 瓦片管理端 | — | 7 个端点 `/admin/tiles` | ❌ |
| 分析埋点 | — | `POST /analytics/events` | ❌ |

### 2.3 IoT — 设备管理

| 功能 | 前端页面 | 后端 API | 对接状态 |
|------|---------|---------|---------|
| 设备列表 | DevicesPage | `GET /farms/{id}/devices` | ✅ |
| 注册设备 | FAB（占位） | `POST /farms/{id}/devices` | ❌ |
| 设备详情 | — | `GET /farms/{id}/devices/{did}` | ⚠️ |
| 激活/停用设备 | — | `PUT /devices/{id}/activate\|decommission` | ❌ |
| 设备许可证 | — | 4 个端点 `/device-licenses` | ❌ |
| 创建安装 | DevicesPage 对话框 | `POST /farms/{id}/installations` | ✅ |
| 卸载设备 | — | `PUT /installations/{id}/uninstall` | ❌ |
| GPS 位置/轨迹 | — | `GET /gps-logs/*` | ⚠️ |
| **Open API** | — | 8 个端点 `/api/v1/open/*` | ❌ |

### 2.4 Commerce — 商业化

| 功能 | 前端页面 | 后端 API | 对接状态 |
|------|---------|---------|---------|
| 当前订阅 | SubscriptionStatusCard | `GET /subscription` | ✅ |
| 套餐列表 | SubscriptionPlanPage | `GET /subscription/plans` | ✅ |
| 订阅结账 | SubscriptionCheckoutPage | `POST /subscription/checkout` | ✅ |
| 变更 tier | — | `PUT /subscription/tier` | ⚠️ |
| 取消订阅 | — | `POST /subscription/cancel` | ❌ |
| 订阅用量 | 本地进度条 | `GET /subscription/usage` | ❌ |
| 我的合同 | B2bContractPage | `GET /contracts/me` | ⚠️ |
| 分润周期 | B2bRevenuePage | `GET /revenue/periods` | ⚠️ |
| 合作方确认分润 | — | `POST /revenue/periods/{id}/confirm` | ⚠️ |
| 合同 CRUD | ContractsPage | 6 个端点 `/admin/contracts` | ⚠️ |
| 合同签署 | — | `POST /admin/contracts/{id}/sign` | ❌ |
| 订阅管理 | SubscriptionsPage | 3 个端点 `/admin/subscriptions` | ⚠️ |
| 分润管理 | RevenuePage | 5 个端点 `/admin/revenue` | ⚠️ |
| 功能门控 | — | 2 个端点 `/admin/feature-gates` | ❌ |
| 订阅服务 | — | 5 个端点 `/admin/subscription-services` | ⚠️ |
| 定时续费 | — | CommerceScheduler | ✅ |

### 2.5 Health — 健康分析

| 功能 | 前端页面 | 后端 API | 对接状态 |
|------|---------|---------|---------|
| 健康总览 | TwinOverviewPage（部分） | `GET /health/overview` | ⚠️ |
| 发热预警列表 | FeverWarningPage | `GET /health/fever` | ✅ |
| 发热详情 | FeverDetailPage | `GET /health/fever/{lid}` | ✅ |
| 消化分析列表 | DigestivePage | `GET /health/digestive` | ✅ |
| 消化详情 | DigestiveDetailPage | `GET /health/digestive/{lid}` | ✅ |
| 发情识别列表 | EstrusPage | `GET /health/estrus` | ✅ |
| 发情详情 | EstrusDetailPage | `GET /health/estrus/{lid}` | ✅ |
| 疫病防控概览 | EpidemicPage | `GET /health/epidemic` | ✅ |

### 2.6 Analytics + API Portal — 分析与开发者门户

| 功能 | 前端页面 | 后端 API | 对接状态 |
|------|---------|---------|---------|
| 使用量概览/趋势 | — | 4 个端点 `/analytics/usage` | ❌ |
| 管理端分析 | — | 3 个端点 `/admin/analytics` | ❌ |
| 我的 API Key | MineApiAuthPage（简） | 7 个端点 `/portal/keys` | ⚠️ |
| Portal 管理 | — | 5 个端点 `/admin/portal/keys` | ❌ |

### 2.7 纯前端能力（后端无对应）

| 能力 | 说明 |
|------|------|
| Material 3 主题系统 | AppColors/AppSpacing/AppTypography，Roboto + NotoSansSC |
| 三级瓦片降级 | SmartTileProvider（tileserver-gl → MBTiles → 高德/OSM） |
| 坐标转换 | WGS-84 ↔ GCJ-02 |
| 围栏命中检测 | 两级优先级 + 候选 BottomSheet |
| 围栏编辑 undo/redo | FenceEditSession 会话栈 |
| 多触点防护 | 编辑模式阻止多点触控 |
| 围栏呼吸动画 | 选中围栏高亮动画 |
| 离线围栏缓存 | FenceSyncService + 冲突解决页 |
| 离线牲畜位置 | LivestockPositionCache |
| 离线瓦片管理 | OfflineTileManager + MBTiles |
| 升级引导覆盖层 | LockedOverlay |
| 续费横幅 | SubscriptionRenewalBanner |
| 牧场创建向导 | 3 步向导（信息→围栏→完成） |
| 高保真组件库 | 6 个通用 Highfi 组件 |

---

## 三、对接状态汇总

| 状态 | 含义 | 数量（约） |
|------|------|------|
| ✅ 已对接 | 前后端完整对接 | ~40 |
| ⚠️ 部分/待确认 | 有对接但不完整，或需确认 | ~18 |
| ❌ 未对接 | 后端已实现，前端未对接 | ~42 |
| — | 仅后端有（无前端对应） | ~20 |
| 🔵 纯前端 | 后端无对应（客户端能力） | ~14 |

**结论**：后端 ~121 个 API 端点中，约 1/3 已完成前后端对接，1/3 有部分对接，1/3 完全未对接。最大的未对接区域集中在 **设备管理（IoT）、瓦片管理、API Portal、使用量分析** 四个领域。

---

## 四、统计数据

| 维度 | 前端 | 后端 |
|------|------|------|
| 代码规模 | 29 模块，~37 页面，46 路由 | 7 限界上下文，381 Java 文件，39 Controller |
| API 端点 | — | ~121 |
| 数据库 | — | 30+ 张表，23 个 Flyway 迁移 |
| 领域模型 | — | 59 个（聚合根+值对象+枚举） |
| 领域事件 | — | 31 个 |
| 角色 | 5 | 5 |
| 订阅 tier | 4 | 4 |
| FeatureFlag | 23 | FeatureGate 表 |
