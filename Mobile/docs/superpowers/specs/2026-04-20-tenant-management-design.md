# 租户管理模块设计方案（修订版）

## 概述

本设计基于当前 `Mobile/` 已实现代码与 `2026-04-20` 评审意见修订，目标是让租户管理模块在现有架构下可直接实施，避免接口、状态管理与 UI 风格不一致导致返工。

## 当前代码基线（已确认）

- Ops 登录后被路由强制进入 `/ops/admin`，当前页面为占位态。
- 后端仅已实现 4 个租户端点：`GET /api/tenants`、`POST /api/tenants`、`POST /api/tenants/:id/status`、`POST /api/tenants/:id/license`。
- 所有接口统一响应包络：`{ code, message, requestId, data }`。
- `ApiCache.init()` 已预加载 `/tenants?pageSize=100` 并写入 `ApiCache.tenants`。
- 现有 Controller 模式为**同步方法 + ViewData**，非 `async Future<void>` Controller 流程。
- 详情页已有主流样式是**垂直卡片堆叠**（非 Tab 导航）。

## 修订原则（P0）

1. **状态管理对齐**：采用同步 `Notifier<ViewData>` 与 `state = repository.load(...)` 模式。
2. **State 拆分**：列表、详情、设备、日志、统计拆为独立 Provider，避免大一统 `TenantState`。
3. **API 对齐**：严格对齐现有包络、分页结构、参数名（`licenseTotal`）。
4. **路由对齐**：保留 `AppRoute.opsAdmin`，子路由使用 path 参数，不新增大量枚举值。
5. **UI 对齐**：详情页使用卡片堆叠；删除操作简化为单次确认弹窗（含原因输入）。

## 模块结构

```
mobile_app/lib/features/tenant/
├── domain/
│   ├── tenant.dart
│   ├── tenant_repository.dart
│   ├── tenant_operation.dart
│   ├── tenant_query.dart
│   └── tenant_view_data.dart
├── data/
│   ├── mock_tenant_repository.dart
│   └── live_tenant_repository.dart
└── presentation/
    ├── tenant_list_controller.dart
    ├── tenant_detail_controller.dart
    ├── tenant_devices_controller.dart
    ├── tenant_logs_controller.dart
    └── tenant_stats_controller.dart
```

页面放置在 `features/tenant/presentation/pages/`，避免继续堆到 `features/pages/`。

## 路由设计

- `AppRoute` 仅保留现有 `opsAdmin('/ops/admin')` 作为入口枚举。
- 在 `app_router.dart` 中为 `opsAdmin` 增加子路由：
  - `/ops/admin`：租户列表页
  - `/ops/admin/create`：创建租户页
  - `/ops/admin/:id`：租户详情页
  - `/ops/admin/:id/edit`：编辑租户页

说明：子路由使用 path 参数，不新增 `opsTenantCreate/opsTenantDetail/opsTenantEdit` 枚举项。

## 状态管理设计（对齐现有模式）

### Repository Provider

`tenantRepositoryProvider` 按 `appModeProvider` 在 Mock/Live 实现间切换。

### Controller 与 ViewData

- Controller 采用同步方法（`void`），不在 Controller 层暴露 `Future` 接口。
- ViewData 按场景拆分：
  - `TenantListViewData`
  - `TenantDetailViewData`
  - `TenantDevicesViewData`
  - `TenantLogsViewData`
  - `TenantStatsViewData`

### Provider 拆分

- `tenantListControllerProvider`
- `tenantDetailControllerProvider(id)`（`NotifierProvider.family`）
- `tenantDevicesControllerProvider(id)`
- `tenantLogsControllerProvider(id)`
- `tenantStatsControllerProvider(id)`

说明：避免单个 `TenantState` 同时承载列表/详情/日志/统计，减少不必要 rebuild。

## 数据模型（分阶段）

## Phase 1（与现有后端字段对齐）

`Tenant` 最小字段集：

- `id`
- `name`
- `status`（`active | disabled`）
- `licenseUsed`
- `licenseTotal`

## Phase 2（后端扩展后引入）

- `contactName/contactPhone/contactEmail`
- `region`
- `remarks`
- `createdAt/updatedAt/lastUpdatedBy`

说明：当前后端 seed 仅包含基础 5 字段，扩展字段必须先补 Mock Server 再落前端。

## API 设计（修订后）

## 已实现端点（可直接联调）

1. `GET /api/tenants`
2. `POST /api/tenants`
3. `POST /api/tenants/:id/status`
4. `POST /api/tenants/:id/license`

## 待补齐端点（Phase 1 前置）

1. `GET /api/tenants/:id`
2. `PUT /api/tenants/:id`
3. `DELETE /api/tenants/:id`
4. `GET /api/tenants/:id/devices`
5. `GET /api/tenants/:id/logs`
6. `GET /api/tenants/:id/stats`

## 包络与分页规范（必须）

所有成功响应：

```json
{
  "code": "OK",
  "message": "success",
  "requestId": "req_xxx",
  "data": {}
}
```

列表型 `data`：

```json
{
  "items": [],
  "page": 1,
  "pageSize": 20,
  "total": 0
}
```

## 关键接口对齐

- 创建租户请求参数：`{ name, licenseTotal }`（当前后端能力）
- 调整配额参数：`licenseTotal`（禁止使用 `newQuota`）
- 状态切换与配额调整返回：更新后的完整 `Tenant`（放在包络 `data` 内）

## 列表页设计（/ops/admin）

### 布局

- 顶部操作区：搜索框 + 状态筛选 + 排序选择 + 新建按钮。
- 内容区：租户卡片列表。
- 底部：通用分页组件（Phase 1 必做）。

### 字段展示（Phase 1）

- 租户名称
- 状态标签
- License 使用：`used/total` + 进度条

说明：联系人、创建时间等信息在后端字段扩展前不在列表强依赖。

### 交互细节

- 搜索：输入防抖 300ms，仅单字段关键词（名称）。
- 状态筛选：`all/active/disabled`（下拉选择）。
- 排序：`licenseUsage`（Phase 1）；`createdAt/updatedAt` 待后端字段扩展后启用。
- 分页默认值统一 `pageSize=20`。

## 创建/编辑设计

## 创建页（/ops/admin/create）

Phase 1 字段：

- 租户名称（必填）
- 初始 License（必填，映射 `licenseTotal`）

Phase 2 扩展字段：

- 联系人、地区、备注

## 编辑页（/ops/admin/:id/edit）

- Phase 1 仅支持编辑名称（如业务允许）或保持只读。
- 是否允许改名作为明确业务规则：默认允许，但需后端校验唯一性。

## 详情页设计（/ops/admin/:id）

采用**垂直卡片堆叠**，不使用 4-Tab。

卡片分区：

1. 基本信息卡片（名称、状态、License）
2. 设备列表卡片（Phase 2）
3. 操作日志卡片（Phase 2）
4. 统计概览卡片（Phase 2）

删除流程：单次 `AlertDialog`，包含确认文案与原因输入框，不做二次弹窗链路。

## 统计与图表策略

- 30 天趋势图默认降采样到 7-10 点，复用现有降采样思路。
- 统计卡片用双列 `Grid` 展示，保证小屏可读性。

## ApiCache 集成

`ApiCache.init()` 增加并保持租户数据预加载能力：

- 启动时加载租户列表写入 `ApiCache.tenants`。
- 租户写操作（创建/状态/License）成功后触发租户缓存刷新。
- Live 仓库读取缓存失败时可回退 Mock 仓库，但必须保持 live 分支代码路径。

## 错误处理与反馈

- 不实现自动重试（Demo 阶段保持一致性）。
- 成功/失败反馈统一用 `SnackBar` 术语与组件。
- 页面状态统一使用 `ViewState`：`normal/loading/empty/error/forbidden/offline`。
- 空态图标优先复用现有通用图标（如 `Icons.inbox_outlined`）。

## 实施阶段与优先级

## Phase 1（MVP）

1. 前端租户模块骨架（domain/data/presentation）
2. 列表页 + 创建页 + 详情页（基本信息卡片）
3. 状态切换与 License 调整
4. 通用分页组件
5. 后端补齐 6 个缺失端点中的详情/编辑/删除最小闭环

## Phase 2（增强）

6. 设备/日志/统计接口与页面卡片
7. seed 扩展到联系人/地区/备注/时间戳
8. 搜索/过滤/排序后端参数完整支持（`status/search/sort/order`）
9. 日志存储机制设计并落地

## Phase 3（可视化与体验）

10. 图表降采样策略完善
11. 细化骨架屏与空状态视觉
12. 性能与测试覆盖优化

## 验收标准

- 架构：无大一统 `TenantState`，Controller 均为同步 `state = ...` 写法。
- API：全部接口包络、分页结构、字段命名与后端一致。
- UI：详情页无 Tab 依赖，移动端可单手完成核心流程。
- 行为：创建、状态切换、License 调整均可在 Mock 与 Live 模式运行。

---

**设计版本**：v1.1（评审修订）
**设计日期**：2026-04-20
**状态**：可进入实施（需先完成 Phase 1 前置端点）
