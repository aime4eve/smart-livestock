# Flutter 前端全量适配 Spring Boot 后端 — 设计规格

> **状态**: 已修订（评审 P0 问题已修正）
> **日期**: 2026-05-23
> **范围**: Phase 1 (Identity + Ranch + IoT) + Commerce Phase 2a
> **前置依赖**: Spring Boot 后端 MVP Phase 1 + Commerce 已部署（172.22.1.123:18080）
> **关联文档**: [前端适配计划（旧，已被本文档取代）](../plans/2026-05-12-flutter-frontend-adaptation.md) · [API 契约总览](../../api-contracts/api-overview.md) · [MVP 后端设计规格](2026-05-06-mvp-backend-design.md)

---

## 1. 目标

Flutter App 彻底移除 Mock 模式，全面对接 Spring Boot 真实后端。后端已实现的 Phase 1 + Commerce 功能走真实数据，未实现的 Health/Analytics/API Portal 保留 UI 入口并提示"开发中"。Mock 数据迁移为数据库种子数据。

## 2. 关键决策

| # | 决策 | 选择 | 理由 |
|---|------|------|------|
| D1 | 对齐方向 | 后端驱动，前端对齐后端 API | 后端为真实业务逻辑来源 |
| D2 | 范围 | Phase 1 + Commerce（后端已实现） | Health/Analytics/API Portal 作为独立子项目后续实施 |
| D3 | Mock 模式 | 彻底删除（代码 + Mock Server） | 减少复杂度，单一数据源 |
| D4 | 登录方式 | 手机号 + 密码，仅 live 模式 | 后端 JWT 认证 |
| D5 | 权限控制 | 双层：前端 JWT role 路由守卫 + 后端 403 | UX 最佳 + 安全兜底 |
| D6 | 牧场切换 | 路由不感知 farmId，控制器管理状态 | 移动端标准模式 |
| D7 | 迁移策略 | 模块逐个迁移，每个模块一个 PR | 可验证、风险低 |
| D8 | 未实现模块 | 保留入口，提示"功能开发中，敬请期待" | 不丢失导航结构 |
| D9 | 种子数据 | Mock 数据迁移为 Flyway SQL 种子脚本 | 保持 demo 体验 |

## 3. 子项目分解

本次设计覆盖 P0。P1~P3 各自独立 brainstorming。

| 优先级 | 子项目 | 后端状态 | 前端工作 |
|--------|--------|----------|----------|
| P0 | Phase 1 + Commerce 前端对齐 | 已实现 | 移除 mock、登录改造、全部模块 API 对接 |
| P1 | Health Phase 2b | 待设计 | 后端设计 + 实现 + 前端对接 |
| P2 | Analytics Phase 2c | 待设计 | 后端设计 + 实现 + 前端对接 |
| P3 | API Portal Phase 2c | 待设计 | 后端设计 + 实现 + 前端对接 |

## 4. 模块迁移顺序

按依赖关系排列，每个模块（M）一个 PR，Phase 内可并行。

```
Phase A — 基础设施（所有模块的前置依赖）
  M1.  Auth 层重写（手机号+密码登录 → JWT）
  M2.  移除 APP_MODE 编译参数，固定 live-only
  M3.  API Client 重构（统一请求/响应处理、JWT 自动注入、401 自动刷新）
  M4.  Farm Switcher 改造（控制器管理 activeFarmId，API 路径注入）

Phase B — 核心功能模块（依赖 Phase A）
  M5.  Dashboard
  M6.  Map
  M7.  Alerts
  M8.  Fences
  M9.  Livestock
  M10. Devices

Phase C — Commerce 模块（依赖 Phase B 的 ranch 基础）
  M11. Subscription
  M12. Contract
  M13. Revenue
  M14. B2B Admin
  M15. Worker Management
  M15a. Admin Subscription Management

Phase D — 平台管理（依赖 Phase A）
  M16. Admin 后台
  M17. API Key 管理
  M18. Platform Admin 视图

Phase E — 收尾
  M19. Profile / Me
  M19a. Farm Creation（创建牧场向导）
  M20. 种子数据迁移（Mock 数据 → Flyway SQL）
  M21. 清理：删除所有 mock 代码、Mock Server + 同步更新 api-overview.md §5
  M22. 未实现模块占位（Health/Analytics/API Portal）
```

依赖链：
- M1 → M3（Auth 先于 API Client）
- M3 + M4 → M5~M10（API Client 和 Farm Switcher 先于所有业务模块）
- Phase B 模块之间可并行
- M16/M17/M18 依赖 M3 但不依赖 Phase B

## 5. Auth 层设计（M1）

### 5.1 登录流程

```
用户打开 App
  → LoginPage（手机号 + 密码表单）
  → POST /api/v1/auth/login { phone, password }
  → 成功：解析响应提取 accessToken + user 对象
     - user 对象（来自 AuthTokenDto.user）含: id, username, name, phone, role, tenantId, active
     - 同时解码 JWT 提取 role/tenantId/userId 做交叉校验
  → 加载 farm 列表 GET /api/v1/farms
  → 设置 activeFarmId（默认第一个农场）
  → 进入主页
```

后端登录响应实际结构（`AuthTokenDto`）：

```json
{
  "code": "OK", "message": "success", "requestId": "uuid",
  "data": {
    "accessToken": "eyJhbGciOi...",
    "user": {
      "id": 2, "username": "owner1", "name": "张三",
      "phone": "13800138000", "role": "OWNER",
      "tenantId": 1, "active": true
    }
  }
}
```

注意：后端当前未返回 `refreshToken` 和 `expiresIn`。

### 5.2 JWT 管理

| 机制 | 说明 |
|------|------|
| 存储 | accessToken 存 `flutter_secure_storage` |
| 自动注入 | API Client 拦截器在每个请求 header 加 `Authorization: Bearer {accessToken}` |
| Token 过期 | 401 + AUTH_TOKEN_EXPIRED → 清除会话 → 跳转登录页重新认证 |
| 登出 | 清除本地 accessToken → 跳转登录页 |

**Refresh Token 策略**：后端当前未实现 refresh token 轮换。JWT accessToken 有效期 1 小时。前端策略为 accessToken 过期后强制重新登录。后续后端补充 refresh token 实现时，前端增加自动刷新逻辑。

### 5.3 Session 模型

```dart
class AppSession {
  String accessToken;
  String userId;      // user.id（登录响应提供，非 JWT sub）
  String tenantId;    // user.tenantId（登录响应提供）
  String role;        // user.role（登录响应提供，如 "OWNER"）
  String phone;       // user.phone（登录响应提供）
  String userName;    // user.name（登录响应提供）
  String username;    // user.username（登录响应提供）
}
```

所有字段直接从登录响应的 `user` 对象提取，无需额外 `GET /me` 调用。

### 5.4 登录页 UI

- 两个字段：手机号（数字键盘）、密码（可切换明文）
- 一个"登录"按钮
- 无"注册"入口（Phase 1 用户由管理员创建）
- 错误提示：手机号格式错误 / 密码错误 / 网络异常

### 5.5 删除内容

- `DemoRole` 枚举
- `mock-token-*` 相关逻辑
- 角色选择 UI

## 6. API Client 设计（M3）

### 6.1 替换 ApiCache

现有 `ApiCache` 是 Mock 时代的启动时批量预加载设计。替换为标准按需请求的 `ApiClient`。

### 6.2 ApiClient 职责

| 职责 | 说明 |
|------|------|
| 请求构建 | 统一 base URL、Content-Type、JSON 序列化 |
| JWT 注入 | 每个请求自动附加 `Authorization: Bearer {token}` |
| Farm Scope 注入 | 写操作路径自动拼接 `/farms/{farmId}/...` |
| Token 过期 | 401 + AUTH_TOKEN_EXPIRED → 清除会话 → 跳转登录页（后端当前无 refresh token） |
| 响应解析 | 解包 `{ code, message, requestId, data }` 包络 |
| 错误映射 | HTTP 状态码 → 业务异常类型 |

### 6.3 错误映射

| HTTP | code | 前端行为 |
|------|------|---------|
| 401 | AUTH_TOKEN_EXPIRED | 清除会话 → 跳转登录页 |
| 401 | AUTH_INVALID_TOKEN | 强制登出 |
| 403 | AUTH_FORBIDDEN | 提示"无权限访问" |
| 403 | TENANT_DISABLED | 提示"租户已禁用" |
| 404 | RESOURCE_NOT_FOUND | 提示"资源不存在" |
| 409 | STATE_CONFLICT | 提示具体冲突信息 |
| 4xx 其他 | VALIDATION_ERROR 等 | 显示 message 字段 |
| 5xx | INTERNAL_ERROR | 提示"服务器异常，请稍后重试" |

### 6.4 Repository 层改造 — 同步转异步

当前所有 repository 接口均为同步（如 `List<T> loadAll()`），数据来自 `ApiCache` 的同步 getter。替换为 `ApiClient` 后，所有方法必须改为 `Future<>` 返回类型。

**影响范围：** 全部模块的 repository 接口、controller 调用、UI 层 loading 状态。

**改造方案（M3 中一次性完成）：**

```dart
// 改造前（同步）
abstract class FenceRepository {
  List<FenceItem> loadAll();
}

// 改造后（异步）
abstract class FenceRepository {
  Future<List<FenceItem>> loadAll();
}
```

每个模块的改造步骤：
1. Repository 接口方法返回类型加 `Future<>`
2. Controller 调用处加 `await`
3. UI 层增加 `FutureBuilder` 或 Riverpod `AsyncValue` 处理 loading/error/data 三态
4. 删除 `*_mock_repository.dart`，仅保留唯一的 repository 实现（直接调 ApiClient）

**统一 loading 状态处理：** 使用 Riverpod 的 `AsyncValue` 模式（`whenData`/`whenLoading`/`whenError`），所有 ConsumerWidget 统一使用此模式处理异步数据。

## 7. Farm Scope 设计（M4）

### 7.1 切换流程

```
用户切换农场
  → FarmController 更新 activeFarmId（Riverpod StateNotifier）
  → 所有 API 请求路径自动注入 /farms/{activeFarmId}/...
  → 页面重新拉取数据
  → 无路由跳转
```

### 7.2 状态管理

```dart
class FarmController extends StateNotifier<FarmState> {
  String? activeFarmId;
  List<Farm> farms;

  void switchFarm(String farmId) {
    activeFarmId = farmId;
  }

  Future<void> loadFarms() async {
    farms = await apiClient.get('/farms');
    if (farms.isNotEmpty && activeFarmId == null) {
      activeFarmId = farms.first.id;
    }
  }
}
```

### 7.3 导航结构

路由保持现有结构，不加 farmId 前缀：`/dashboard`、`/alerts`、`/fence`、`/devices` 等。

唯一新增路由场景：创建牧场 — `GET /farms` 列表为空时引导进入 `/farm/create`。

**注意**：`api-overview.md` §5.2 中的 GoRouter `/{farmId}/dashboard` 路由模式需更新为本文档的控制器管理模式，在 Phase E 收尾时同步修改。

### 7.4 删除内容

- `POST /farm/switch-farm` 调用
- `activeFarmTenantId` header 逻辑

## 8. 角色权限设计（M1 联动）

### 8.1 权限来源

```
Mock（已删除）：解析 mock-token-{role} → 提取 role
Live：登录响应 user.role（如 "OWNER"、"WORKER"）→ 存入 AppSession
     同时可解码 JWT payload { sub, tid, role } 做交叉校验
```

### 8.2 角色路由守卫

| 角色 | 可见页面 | 看不到的页面 |
|------|---------|-------------|
| owner | Dashboard、Map、Alerts、Fences、Livestock、Devices、Stats、Twin（开发中）、Subscription、Mine、Admin | — |
| worker | Dashboard、Map、Alerts（仅确认）、Fences（只读）、Mine | Admin、Subscription、Stats |
| platform_admin | Admin（租户/用户/农场管理）、合同管理、对账看板、订阅服务管理、API 授权 | Dashboard、Map、Alerts |
| b2b_admin | B2B 控制台、牧场管理、合同信息、对账、牧工管理 | Alerts、Fences、Devices |
| api_consumer | 无 App 端页面 | 全部 |

### 8.3 实现

- GoRouter `redirect` 函数检查 AppSession 的 `role` 字段
- 底部导航栏根据 role 动态生成 tab 列表
- 敏感操作按钮根据 role 条件渲染
- 后端 `@PreAuthorize` 兜底

## 9. 核心功能模块对齐（Phase B）

### M5. Dashboard

| 前端组件 | 后端 API | 说明 |
|---------|---------|------|
| 看板概览 | `GET /farms/{farmId}/dashboard/summary` | totalLivestock、activeDevices、activeAlerts、healthyLivestock |

UI 调整：数智孪生入口（发热/消化/发情/疫病）保留，标注"开发中"。

### M6. Map

| 前端组件 | 后端 API | 说明 |
|---------|---------|------|
| 地图概览 | `GET /farms/{farmId}/map/overview` | livestockPositions、fences、trajectories |

SmartTileProvider 三级降级保留。

### M7. Alerts

| 前端组件 | 后端 API | 说明 |
|---------|---------|------|
| 告警列表 | `GET /farms/{farmId}/alerts?page=&pageSize=` | 分页 |
| 告警详情 | `GET /farms/{farmId}/alerts/{alertId}` | 含 livestockInfo、fenceInfo |
| 确认 | `POST /farms/{farmId}/alerts/{alertId}/acknowledge` | pending → acknowledged |
| 处理 | `POST /farms/{farmId}/alerts/{alertId}/handle` | acknowledged → handled |
| 归档 | `POST /farms/{farmId}/alerts/{alertId}/archive` | handled → archived |
| 批量处理 | `POST /farms/{farmId}/alerts/batch-handle` | — |

告警状态机已与后端一致，无需大改。

### M8. Fences

| 前端组件 | 后端 API | 说明 |
|---------|---------|------|
| 围栏列表 | `GET /farms/{farmId}/fences` | 含 center、radius/polygon |
| 创建 | `POST /farms/{farmId}/fences` | 圆形/多边形 |
| 详情 | `GET /farms/{farmId}/fences/{fenceId}` | — |
| 更新 | `PUT /farms/{farmId}/fences/{fenceId}` | — |
| 删除 | `DELETE /farms/{farmId}/fences/{fenceId}` | — |

UI 调整：围栏表单 API 路径加 farmId，数据格式适配 GeoJSON（`{ lng, lat }`）。

### M9. Livestock

| 前端组件 | 后端 API | 说明 |
|---------|---------|------|
| 牲畜列表 | `GET /farms/{farmId}/livestock` | 分页，支持 status 过滤 |
| 牲畜详情 | `GET /farms/{farmId}/livestock/{id}` | 含设备安装信息 |
| 新增 | `POST /farms/{farmId}/livestock` | — |
| 更新 | `PUT /farms/{farmId}/livestock/{id}` | — |
| 删除 | `DELETE /farms/{farmId}/livestock/{id}` | 软删除 |

UI 调整：牲畜详情页的设备安装信息适配 Installation 模型。

### M10. Devices

| 前端组件 | 后端 API | 说明 |
|---------|---------|------|
| 设备列表 | `GET /farms/{farmId}/devices` | 分页 |
| 新增 | `POST /farms/{farmId}/devices` | — |
| 详情 | `GET /farms/{farmId}/devices/{id}` | — |
| 更新 | `PUT /farms/{farmId}/devices/{id}` | — |
| 激活 | `PUT /farms/{farmId}/devices/{id}/activate` | — |
| 退役 | `PUT /farms/{farmId}/devices/{id}/decommission` | — |
| License 列表 | `GET /device-licenses` | 租户级 |
| License 详情 | `GET /device-licenses/{id}` | — |
| 安装记录 | `GET /farms/{farmId}/installations` | — |
| GPS 最新 | `GET /farms/{farmId}/gps-logs/latest` | 全部设备最新位置 |
| GPS 历史 | `GET /farms/{farmId}/livestock/{livestockId}/gps-logs` | 单头轨迹 |

UI 调整：增加 License 管理入口，安装/卸载适配 Installation API。

## 10. Commerce 模块对齐（Phase C）

> 以下端点已对照后端 7 个 Commerce Controller 源码逐一核实。

### M11. Subscription（SubscriptionController，6 端点）

| 前端组件 | 后端 API | 说明 |
|---------|---------|------|
| 订阅状态 | `GET /api/v1/subscription` | 当前状态 + effectiveTier |
| 套餐列表 | `GET /api/v1/subscription/plans` | 返回 SubscriptionTier 枚举定价 |
| 结算升级 | `POST /api/v1/subscription/checkout` | 创建订阅/升级 |
| 切换套餐 | `PUT /api/v1/subscription/tier` | 直接升降级 |
| 取消 | `POST /api/v1/subscription/cancel` | — |
| 使用量/配额 | `GET /api/v1/subscription/usage` | 返回使用量摘要 + tier 配额 + 数据保留天数 |

UI 调整：mock `feature-flag.js` 的 tier 功能门控逻辑迁移为前端订阅状态 → 配额检查 → UI 锁定/解锁。详见 §16 Feature Flag 映射。

### M12. Contract（CommerceController app + AdminContractController admin）

**App 端（CommerceController，3 端点）：**

| 前端组件 | 后端 API | 说明 |
|---------|---------|------|
| 当前合同 | `GET /api/v1/contracts/me` | 当前租户的合同（partner 视角） |
| 对账列表 | `GET /api/v1/revenue/periods` | 当前租户分润周期 |
| 确认对账 | `POST /api/v1/revenue/periods/{id}/confirm` | partner 确认 |

**Admin 端（AdminContractController，6 端点）：**

| 前端组件 | 后端 API | 说明 |
|---------|---------|------|
| 合同列表 | `GET /api/v1/admin/contracts` | 全部合同 |
| 创建合同 | `POST /api/v1/admin/contracts` | 创建草稿 |
| 合同详情 | `GET /api/v1/admin/contracts/{id}` | — |
| 更新草稿 | `PUT /api/v1/admin/contracts/{id}` | 修改计费模型/tier/分润比例 |
| 签署合同 | `POST /api/v1/admin/contracts/{id}/sign` | 草稿 → 已签 |
| 合同状态 | `PUT /api/v1/admin/contracts/{id}/status` | 暂停/恢复/终止 |

### M13. Revenue（AdminRevenueController admin，5 端点）

**注意：App 端的对账列表/确认已在 M12 CommerceController 覆盖。以下为 admin 端点。**

| 前端组件 | 后端 API | 说明 |
|---------|---------|------|
| 全部对账 | `GET /api/v1/admin/revenue/periods` | 跨租户 |
| 对账详情 | `GET /api/v1/admin/revenue/periods/{id}` | — |
| 触发计算 | `POST /api/v1/admin/revenue/calculate` | 按合同触发月度计算 |
| 确认对账 | `POST /api/v1/admin/revenue/periods/{id}/confirm` | 平台确认 |
| 重新计算 | `POST /api/v1/admin/revenue/periods/{id}/recalculate` | — |

### M14. B2B Admin

| 前端组件 | 后端 API | 说明 |
|---------|---------|------|
| B2B 概览 | 复用 `GET /contracts/me` + `GET /revenue/periods` | 聚合展示 |
| 牧场管理 | `GET /farms` + `POST /farms` | 租户下农场 CRUD |
| 牧工管理 | `GET /farms/{farmId}/members` + `POST/DELETE` | 成员管理 |

### M15. Worker Management

| 前端组件 | 后端 API | 说明 |
|---------|---------|------|
| 成员列表 | `GET /farms/{farmId}/members` | — |
| 添加 | `POST /farms/{farmId}/members` | — |
| 移除 | `DELETE /farms/{farmId}/members/{userId}` | — |

### M15a. Admin Subscription Management（AdminSubscriptionController + AdminServiceController，7 端点）

| 前端组件 | 后端 API | 说明 |
|---------|---------|------|
| 订阅列表 | `GET /api/v1/admin/subscriptions` | 含 status/tier 过滤 + 分页 |
| 订阅详情 | `GET /api/v1/admin/subscriptions/{id}` | — |
| 订阅状态 | `PUT /api/v1/admin/subscriptions/{id}/status` | 暂停/恢复/取消 |
| 服务列表 | `GET /api/v1/admin/subscription-services` | 全部 licensed 服务 |
| 创建服务 | `POST /api/v1/admin/subscription-services` | 分配新服务 |
| 服务详情 | `GET /api/v1/admin/subscription-services/{id}` | — |
| 服务状态 | `PUT /api/v1/admin/subscription-services/{id}/status` | 激活/撤销 |
| 服务配额 | `PUT /api/v1/admin/subscription-services/{id}/quota` | 调整设备配额 |

## 11. 平台管理对齐（Phase D）

### M16. Admin 后台

| 前端组件 | 后端 API | 说明 |
|---------|---------|------|
| 租户列表 | `GET /admin/tenants` | 跨租户 |
| 租户详情 | `GET /admin/tenants/{tenantId}` | — |
| 创建租户 | `POST /admin/tenants` | — |
| 启用/禁用 | `PUT /admin/tenants/{tenantId}/status` | — |
| 用户列表 | `GET /admin/users` | 跨租户 |
| 用户详情 | `GET /admin/users/{userId}` | — |
| 创建用户 | `POST /admin/users` | — |
| 重置密码 | `POST /admin/users/{userId}/reset-password` | — |
| 农场列表 | `GET /admin/farms` | 跨租户 |
| 农场详情 | `GET /admin/farms/{farmId}` | — |

注意 admin 端点前缀 `/api/v1/admin/` 与 app 端点 `/api/v1/` 不同。

### M17. API Key 管理

| 前端组件 | 后端 API | 说明 |
|---------|---------|------|
| Key 列表 | `GET /admin/api-keys` | — |
| 创建 Key | `POST /admin/api-keys` | 首次返回完整 key |
| 启用/禁用 | `PUT /admin/api-keys/{keyId}/status` | — |
| 撤销 | `DELETE /admin/api-keys/{keyId}` | — |

UI 调整：创建 Key 成功后弹窗显示完整 key 并提示"仅此一次"。

### M18. Platform Admin 视图

整合 M16 + M17，`platform_admin` 角色的统一管理入口。

## 12. Profile / Me（M19）

| 前端组件 | 后端 API | 说明 |
|---------|---------|------|
| 个人信息 | `GET /me` | — |
| 更新信息 | `PUT /me` | — |
| 改密码 | `PUT /me/password` | — |
| 租户信息 | `GET /tenants/me` | — |
| 登出 | 清除本地 accessToken → 跳转登录页 | 后端无 logout 端点 |

## 12a. Farm Creation（M19a）

| 前端组件 | 后端 API | 说明 |
|---------|---------|------|
| 创建牧场 | `POST /farms` | name、latitude、longitude、areaHectares |
| 牧场列表 | `GET /farms` | 确认创建成功 |

前端 `farm_creation` 模块（3 步向导：基本信息 → 围栏绘制 → 完成）适配后端 `POST /farms` API，创建后自动设为 activeFarmId 并跳转 dashboard。

## 13. 种子数据迁移（M20）

将 Mock Server 的 demo 数据迁移为 Flyway SQL 迁移脚本：

| 迁移脚本 | 数据 | 说明 |
|---------|------|------|
| V4（已有） | 种子用户、Demo 租户 | 保留，密码对齐 CLAUDE.md 凭据 |
| V9 | Ranch 数据 | 牲畜、围栏、告警 |
| V10 | IoT 数据 | 设备、License、安装、GPS |
| V11 | Commerce 数据 | 订阅、合同、分润 |
| V12 | Twin 概览数据 | 牧区统计、场景摘要、待办任务（JSON 配置或轻量表） |

Twin 详细健康数据（温度时序、蠕动、发情、疫病）在 P1（Health 子项目）中创建 Health 表后迁移。

## 14. 清理清单（M21）

### 删除的文件/目录

- `Mobile/backend/` — 整个 Mock Server
- 所有 `*_mock_repository.dart` 文件
- `api_cache.dart` 及 `ApiCache` 相关代码
- `DemoRole` 枚举及相关 mock 类型
- `APP_MODE` 编译参数相关代码
- `Mobile/mobile_app/lib/core/api/` 中 mock 相关辅助文件

### 删除的概念

- `APP_MODE=mock|live` 编译参数
- mock token 体系（`mock-token-{role}`）
- header-based farm scope（`activeFarmTenantId`）
- `ApiCache` 批量预加载模式
- Mock Server feature-flag 中间件

## 15. 未实现模块占位（M22）

以下模块保留完整 UI 代码，入口正常显示，点击后显示"功能开发中，敬请期待"：

- `fever_warning` — 发热预警
- `digestive` — 消化管理
- `estrus` — 发情识别
- `epidemic` — 疫病防控
- `stats` — 数据统计
- `mine/api-auth` 中的 API 开发者门户部分

各模块在 P1/P2/P3 子项目中逐一激活，替换占位为真实 API 对接。

## 16. Feature Flag 映射（M11 联动）

前端现有 21 个 feature flag，基于 `SubscriptionTier` 做门控，使用 4 种 shape：
- `none`：所有 tier 可用
- `lock`：指定 tier 及以上可用，以下显示 LockedOverlay
- `limit`：根据 tier 限制数值（如数据保留天数）
- `filter`：根据 tier 过滤数据范围

后端配额系统对应关系：

| 前端 Feature Flag | Shape | 后端对应 | API |
|---|---|---|---|
| gpsLocation | lock | tier 配额 | `GET /subscription/usage` |
| fence | lock | tier 配额 | 同上 |
| trajectory | lock | tier 配额 | 同上 |
| temperatureMonitor | lock | tier 配额 | 同上（Health P1 实现后激活） |
| peristalticMonitor | lock | tier 配额 | 同上 |
| healthScore | lock | tier 配额 | 同上 |
| estrusDetect | lock | tier 配额 | 同上 |
| epidemicAlert | lock | tier 配额 | 同上 |
| gaitAnalysis | lock | tier 配额 | 同上 |
| behaviorStats | lock | tier 配额 | 同上 |
| apiAccess | lock | tier 配额 | 同上 |
| stats | lock | tier 配额 | 同上（Analytics P2 实现后激活） |
| dashboardSummary | none | 所有 tier 可用 | — |
| dataRetentionDays | limit | tier 配额 `dataRetentionDays` | `GET /subscription/usage` |
| alertHistory | lock | tier 配额 | 同上 |
| dedicatedSupport | lock | tier 配额 | 同上 |
| deviceManagement | lock | tier 配额 | 同上 |
| livestockDetail | lock | tier 配额 | 同上 |
| profile | none | 所有 tier 可用 | — |
| tenantAdmin | lock | tier 配额 | 同上 |

**改造方案：**
1. `LockedOverlay` 组件保留，改为从 `GET /subscription/usage` 获取当前 tier 配额判断
2. 删除 mock `feature-flags.js` 数据源
3. 前端登录后调一次 `/subscription` 获取 tier，缓存在内存中用于 feature flag 判断
4. 配额检查失败时（后端返回 403 QUOTA_EXCEEDED）前端自动显示升级提示
