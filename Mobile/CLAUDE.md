# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

智慧畜牧 App 是面向牧场主/养殖户的牛羊智慧管理移动应用，通过 GPS追踪器、瘤胃胶囊、加速度计三类 IoT 设备，实现牲畜定位管控、健康预警和行为分析。

**当前阶段**: Spring Boot 后端 MVP Phase 1 已完成（Identity + Ranch + IoT），Commerce 限界上下文设计规格已评审通过。前端使用 Flutter + Riverpod，后端 Mock API 使用 Node.js + Express（端口 3001）用于 Demo，Spring Boot 后端（`smart-livestock-server/`）用于 Live 模式。APP_MODE=live 时前端通过 HTTP 调后端 API，APP_MODE=mock 时使用本地假数据。

## 技术栈

- **前端**: Flutter / Dart SDK >=3.3.0（iOS/Android/Web 跨平台）
- **状态管理**: flutter_riverpod
- **路由**: go_router（39 条路由）
- **地图**: flutter_map + latlong2 + SmartTileProvider（三级瓦片降级）+ MBTiles 离线 + WGS-84/GCJ-02 坐标转换
- **图表**: fl_chart（时序曲线、柱状图等）
- **HTTP 客户端**: `http` 包（live 模式调用后端 API）
- **离线存储**: sqlite3 + sqlite3_flutter_libs（MBTiles 瓦片读取）+ path_provider
- **Mock Server**: Node.js + Express 5（`backend/`，端口 3001，Demo 阶段使用）
- **Spring Boot 后端**: Spring Boot 3.3 + Java 17 + PostgreSQL + Redis + RocketMQ（详见 [MVP 后端设计规格](../docs/superpowers/specs/2026-05-06-mvp-backend-design.md)）
- **实时通信** (待实现): MQTT (EMQX/Mosquitto)

## 目录结构

```
Mobile/
├── mobile_app/              # Flutter 前端应用
│   ├── lib/
│   │   ├── app/             # 应用层：路由、Shell、Session、模式切换、URL策略
│   │   ├── core/            # 核心：模型、权限、数据种子、API 缓存、地图配置
│   │   │   ├── models/      # demo_role, demo_models, view_state, subscription_tier, twin_models
│   │   │   ├── data/        # demo_seed（假数据）、generators（数据生成器）、twin_seed、twin_series_downsample
│   │   │   ├── api/         # api_cache（HTTP 缓存，live 模式预加载）、api_role、api_auth、api_http_client
│   │   │   ├── mock/        # mock_config, mock_scenarios
│   │   │   ├── map/         # map_config, coord_transform, mbtiles_tile_provider, smart_tile_provider
│   │   │   ├── utils/       # currency_formatter
│   │   │   ├── permissions/ # role_permission（权限判断）
│   │   │   └── theme/       # app_colors, app_spacing, app_typography, app_theme
│   │   ├── features/        # 功能模块（26 个）
│   │   │   ├── pages/       # 页面组件（twin_overview, map, alerts, fence, devices, stats 等）
│   │   │   ├── auth/        # 登录页
│   │   │   ├── admin/       # B端管理后台（platform_admin）
│   │   │   ├── b2b_admin/   # B端客户控制台（b2b_admin）
│   │   │   ├── tenant/      # 租户管理（详情、列表、设备、日志、统计、趋势图）
│   │   │   ├── subscription/# 订阅管理（套餐选择、支付确认）
│   │   │   ├── farm_switcher/# 牧场切换器
│   │   │   ├── farm_creation/ # 创建牧场向导
│   │   │   ├── fence/       # 围栏（含编辑、命中检测、多边形包含、统计）
│   │   │   ├── contract_management/ # 合同管理
│   │   │   ├── revenue/     # 对账分润
│   │   │   ├── api_authorization/ # API 授权管理
│   │   │   ├── subscription_service_management/ # 订阅服务管理
│   │   │   ├── worker_management/ # 牧工管理
│   │   │   └── {module}/    # 每个模块：domain/repository + data/mock+live + presentation/controller
│   │   └── widgets/         # 通用组件（metric_card, empty_state, status_tag, pagination_bar）
│   └── test/                # 测试文件（60 个）
├── backend/                 # Mock API Server（Node.js + Express，Demo 阶段使用）
│   ├── server.js            # 入口，端口 3001
│   ├── routes/              # 路由：auth, me, dashboard, map, alerts, fences, devices, tenants, subscription, b2b, farm, worker, profile, twin
│   ├── middleware/           # auth（token 校验 + 权限）、farmContext（牧场上下文）、feature-flag（功能门控）、requestContext、envelope
│   ├── data/                # 数据层：seed.js, fenceStore.js, tenantStore.js, contractStore.js, subscriptions.js, workerFarmStore.js, twin_seed.js, feature-flags.js
│   └── config/              # 运行时配置
├── docs/                    # 设计文档与 Demo 交付物
│   ├── api-contracts/       # API 契约定义
│   ├── demo/                # Demo 评审脚本、验收单、变更记录
│   └── superpowers/         # 规格文档、实施计划
├── dev.sh                   # 开发控制脚本（启动/停止/诊断）
└── AGENTS.md                # 代码风格与编码约定（供 agentic coding agents 参考）
```

## 常用命令

### 前端开发

```bash
cd mobile_app

flutter pub get                    # 安装依赖
flutter test                       # 运行所有测试（60 个测试文件）
flutter test test/widget_smoke_test.dart  # 运行单个测试文件
flutter test --name="owner"        # 按名称过滤
flutter run                        # 运行应用（需要模拟器或设备）
flutter run --dart-define=APP_MODE=mock   # Mock 模式（默认，本地假数据）
flutter run --dart-define=APP_MODE=live   # Live 模式（调用后端 API）
flutter analyze                    # 静态分析
flutter build web                  # 构建 Web 版本
```

### Web 端注意事项

Web 端默认走**同源相对路径 `/api/v1`**（`api_client.dart` 的 `_resolveBaseUrl()` 在 web 平台默认 `/api/v1`，浏览器自动用页面 host:port；部署侧 nginx 已反代 `/api/v1/` → app:8080）。因此 `build_web.sh` 构建**无需传 `API_BASE_URL`**，换部署域名/端口不必重建。

开发调试连特定后端时再显式覆盖：

```bash
# 连接远程 Spring Boot 后端
flutter run -d chrome --dart-define=APP_MODE=live --dart-define=API_BASE_URL=http://172.22.1.123:18080/api/v1

# 连接本地 Mock Server
flutter run -d chrome --dart-define=APP_MODE=live --dart-define=API_BASE_URL=http://127.0.0.1:3001/api
```

### Live 模式登录凭据

Live 模式显示手机号/密码登录表单，直接对接 Spring Boot 后端 JWT 认证。

| 角色 | 手机号 | 密码 | 说明 |
|------|--------|------|------|
| owner（牧场主） | 13800138000 | password123 | Demo 租户 owner，关联主牧场 |
| platform_admin（平台管理员） | 13800000000 | password123 | 平台级管理，无租户归属 |

### Mock Server

```bash
cd backend

npm install                        # 安装依赖
node server.js                     # 启动 Mock Server（端口 3001）
node --watch server.js             # 开发模式（文件变更自动重启）

# 快速验证端点
curl http://localhost:3001/api/auth/login -X POST -H "Content-Type: application/json" -d '{"role":"owner"}'
curl http://localhost:3001/api/me -H "Authorization: Bearer mock-token-owner"
curl http://localhost:3001/api/dashboard/summary -H "Authorization: Bearer mock-token-owner"
```

### dev.sh 开发控制脚本

```bash
cd Mobile
./dev.sh start [mock|live] [chrome|macos]  # 启动所有服务（默认 mock + chrome）
./dev.sh stop                              # 停止所有服务
./dev.sh restart [mock|live] [chrome|macos] # 重启所有服务
./dev.sh status                            # 查看服务状态
./dev.sh logs [backend|flutter]            # 查看实时日志
./dev.sh diagnose                          # 诊断：最近日志 + 关键错误行（排查白屏/WASM 等问题）
```

### 端到端验证

```bash
# 终端 1: 启动 Mock Server
cd backend && node server.js

# 终端 2: 启动 Flutter App（live 模式）
cd mobile_app && flutter run --dart-define=APP_MODE=live
```

## 前端架构

### 模块分层

每个功能模块遵循以下结构：

```
features/{module}/
├── domain/
│   └── {module}_repository.dart    # Repository 接口（同步方法）
├── data/
│   ├── mock_{module}_repository.dart  # Mock 实现（读取 demo_seed 假数据）
│   └── live_{module}_repository.dart  # Live 实现（读取 ApiCache → 后端 API 数据）
└── presentation/
    └── {module}_controller.dart    # Riverpod Notifier，根据 AppMode 切换 repo
```

当前功能模块（26 个）：`admin`、`alerts`、`api_authorization`、`auth`、`b2b_admin`、`contract_management`、`dashboard`、`devices`、`digestive`、`epidemic`、`estrus`、`farm_creation`、`farm_switcher`、`fence`、`fever_warning`、`highfi`、`livestock`、`mine`、`pages`、`revenue`、`stats`、`subscription`、`subscription_service_management`、`tenant`、`twin_overview`、`worker_management`

### 围栏模块（fence）

围栏是当前最复杂的模块，除了标准的 domain/data/presentation 三层外，还包含：

- `fence_dto.dart` — 数据传输对象
- `fence_edit_operations.dart` — 编辑操作（创建/移动/删除顶点）
- `fence_edit_session.dart` — 编辑会话状态管理
- `fence_item.dart` — 围栏业务对象
- `fence_polygon_contains.dart` — 多边形包含检测（射线法）
- `fence_state.dart` — 围栏状态枚举
- `fence_analytics.dart` — 围栏统计
- `fence_hit_detection.dart` — 两级优先级命中检测（优先选中围栏 > 包含点围栏，同优先级按距离排序）
- `presentation/widgets/` — 围栏专用 UI 组件

### 地图模块

- `core/map/map_config.dart` — 地图配置（城市预设、瓦片源 URL、缓存参数）
- `core/map/coord_transform.dart` — WGS-84 ↔ GCJ-02 坐标转换
- `core/map/mbtiles_tile_provider.dart` — MBTiles 离线瓦片读取（原生平台）
- `core/map/smart_tile_provider.dart` — 三级降级 TileProvider（tileserver-gl → MBTiles → 高德/OSM），健康检测自动切换
- 三级降级流程：自建 tileserver-gl（WGS-84）→ 本地 MBTiles 离线瓦片 → 高德（国内 GCJ-02）/ OSM（海外 WGS-84）
- 使用高德降级时自动应用 GCJ-02 坐标转换

### 应用入口与模式

- `lib/main.dart` → `DemoApp` → `DemoShell`
- `AppMode` (mock/live) 通过 `--dart-define=APP_MODE=xxx` 切换，默认 mock
- live 模式下 `main()` 在 `runApp` 前调用 `ApiCache.instance.init(role)` 预加载全部 API 数据
- `DemoApp` 接受 `overrides`（Provider 覆盖）和 `appMode` 参数，方便测试注入
- `DemoShell` 根据当前角色动态构建底部导航
- 路由定义集中在 `AppRoute` 枚举（`app/app_route.dart`），是路径、名称、标签的唯一来源（39 条路由）
- `GoRouter` 配置在 `app/app_router.dart`，通过 `refreshListenable` 监听 session 变化自动重定向

### Live 模式数据流

```
main.dart (async)
  → ApiCache.instance.init(role)        // 预加载：并发 GET 多个 API 端点，按角色过滤范围
  → runApp(DemoApp)

LiveXxxRepository.load()
  → ApiCache.instance.xxx               // 同步读取缓存
  → 若缓存未初始化 → fallback 到 MockXxxRepository
```

Repository 接口保持同步（返回 ViewData 而非 Future），通过启动时预加载避免 async 改造。

### 会话与认证

- `AppSession`（值对象）封装登录状态和角色，通过 `SessionController`（Riverpod Notifier）管理
- `LoginPage` 选择角色后调用 `sessionControllerProvider.notifier.login(role)`
- 路由守卫在 `app_router.dart` 的 `redirect` 回调中：未登录→`/login`，platform_admin→`/ops/admin`，b2b_admin→`/b2b/admin`
- 过期提示弹窗通过 `expiry_popup_handler.dart` 管理

### 牧场上下文（Multi-Farm）

- `farm_switcher` 模块提供牧场切换 UI
- Mock Server 通过 `farmContextMiddleware` 从 header 提取 `activeFarmTenantId`
- 各数据 Store 按 `farmTenantId` 过滤数据
- `ApiCache` 将预加载范围缩小到当前牧场

### 主题系统

- Material 3 主题，集中在 `core/theme/` 下四个文件：`app_colors`、`app_spacing`、`app_typography`、`app_theme`
- `AppTheme.light()` 生成 `ThemeData`，在 `DemoApp` 中注入 `MaterialApp.router`
- 使用主题 token（AppColors/AppSpacing/AppTypography）而非硬编码数值
- 字体本地打包：Roboto（英文）+ NotoSansSC（中文），无需网络加载

### 角色与权限

| 角色 | DemoRole / Token | 可见范围 |
|------|------------------|---------|
| owner（牧场主） | `mock-token-owner` | 全部页面 + 后台管理 + 牧工管理 + 订阅管理 |
| worker（牧工） | `mock-token-worker` | 看板/地图/告警/我的/围栏，仅确认告警 |
| platform_admin（平台管理员） | `mock-token-platform-admin` | 租户全量管理 + 合同 CRUD + 分润对账 + 订阅服务管理 + API 授权审批 |
| b2b_admin（B端客户管理员） | `mock-token-b2b-admin` | 概览/牧场管理/合同信息/对账/旗下牧工管理 |
| api_consumer（API 开发者） | `mock-token-api-consumer` | 仅通过 API 访问，无 App 端 |

前端权限判断在 `RolePermission` 类中；Mock Server 权限校验在 `middleware/auth.js` 的 `requirePermission()` 中。

### 页面状态

各页使用 `ViewState`（正常/加载/空/错误/无权限/离线）分支渲染；由仓储返回的数据与 Controller 决定，不再提供全局演示用手动下拉切换。

### 功能门控（Feature Flags / Shaping）

- Mock Server `middleware/feature-flag.js` 实现基于订阅 tier 的功能门控
- 前端 ApiCache 预加载时按 tier 过滤可见数据
- `subscription_tier.dart` 定义 tier 枚举（trial/basic/pro/enterprise）

## Mock Server 架构

### 认证机制

- 登录 `POST /api/auth/login` body: `{ role }` → 返回固定 token `mock-token-{role}`
- 中间件解析 Bearer token 确定角色和权限
- `requirePermission('xxx')` 工厂函数用于路由级权限校验
- Open API 路由（`/api/open/v1/*`）使用 API Key 认证 + 频率限制

### 响应格式

所有接口统一 `{ code, message, requestId, data }` 包络，列表接口使用 `{ items, page, pageSize, total }` 分页结构。

### 中间件链

```
cors → json → requestContext → envelope → auth → farmContext → shaping(feature-flag) → routes
```

- `requestContext` — 生成 requestId，注入 runtimeConfig
- `auth` — Bearer token 认证，注入 req.user
- `farmContext` — 从 header 提取 activeFarmTenantId
- `shaping` — 基于 tier 的功能门控，包装 res.ok() 过滤响应

### Store 模式

数据层使用内存 Store 模块（`backend/data/*Store.js`），每个 Store 暴露 CRUD + 查询方法，模块级变量持有数据数组。新建 Store 需提供 `reset()` 方法（测试隔离）。

当前 Stores: `seed.js`(基础种子)、`fenceStore.js`、`tenantStore.js`、`contractStore.js`、`subscriptions.js`、`workerFarmStore.js`、`twin_seed.js`、`feature-flags.js`

### 告警状态机

告警状态只能顺序推进：`pending → acknowledged → handled → archived`。服务端校验非法跳转返回 409 CONFLICT。

### API 路由

基础端点：auth(1) + me(1) + dashboard(1) + map(1) + alerts(5) + fences(4) + devices(1) + tenants(4) + profile(1)；数智孪生：`/api/twin/*`（overview、fever/digestive/estrus 列表与详情、epidemic summary/contacts）；商业模型扩展：`/api/subscription/*`（订阅计划、订阅状态）、`/api/b2b/*`（B端控制台）、`/api/farm/*`（牧场管理）、`/api/farms/*`（牧工管理）。Open API 路由（`/api/open/v1/*`）供第三方开发者使用。

### API 契约

完整端点定义见：`docs/api-contracts/mobile-app-mock-api-contract.md`

### 数据种子

`backend/data/seed.js` 与 Flutter 端 `demo_seed.dart` 保持对齐。

## 测试结构

```
mobile_app/test/（60 个测试文件）
├── widget_smoke_test.dart              # 基础 Widget 冒烟测试
├── widget_test.dart                    # 通用 Widget 测试
├── app_architecture_test.dart          # 架构约束测试（分层、依赖方向）
├── app_mode_switch_test.dart           # AppMode 切换测试
├── app_session_test.dart               # 会话状态测试
├── api_auth_test.dart                  # API 认证测试
├── api_base_url_test.dart              # API URL 配置测试
├── api_cache_role_scope_test.dart      # ApiCache 角色范围测试
├── api_live_contract_test.dart         # Live 模式合同接口测试
├── mock_repository_override_test.dart  # Mock Repository Provider 覆盖测试
├── mock_repository_state_test.dart     # Mock 数据状态测试
├── mock_shaping_test.dart              # Mock 功能门控测试
├── role_visibility_test.dart           # 角色可见性测试
├── state_persistence_test.dart         # 状态持久化测试
├── flow_smoke_test.dart                # 端到端流程冒烟测试
├── seed_data_test.dart                 # 种子数据验证测试
├── generator_test.dart                 # 数据生成器测试
├── fence_dto_test.dart                 # 围栏 DTO 测试
├── live_devices_repository_test.dart   # Live 设备仓储测试
├── twin_overview_pasture_context_test.dart  # 孪生总览牧场上下文测试
├── twin_series_downsample_test.dart    # 时序降采样测试
├── main_live_bootstrap_test.dart       # Live 模式启动引导测试
├── farm_switcher_controller_test.dart  # 牧场切换器测试
├── mbtiles_tile_provider_test.dart     # MBTiles 瓦片提供者测试
├── core/
│   ├── map/
│   │   ├── coord_transform_test.dart   # 坐标转换测试
│   │   └── smart_tile_provider_test.dart # 三级降级瓦片测试
│   └── subscription_tier_test.dart     # 订阅层级测试
├── features/
│   ├── b2b_admin/b2b_pages_test.dart   # B端后台测试
│   ├── farm_switcher/farm_switcher_test.dart # 牧场切换器测试
│   ├── fence/                          # 围栏模块测试（14 个文件）
│   ├── subscription/                   # 订阅模块测试
│   ├── tenant/                         # 租户管理测试（12 个文件）
│   └── worker_management/             # 牧工管理测试
├── highfi/                             # 高保真组件测试
│   ├── alerts_highfi_test.dart
│   └── dashboard_highfi_test.dart
└── theme/highfi_theme_test.dart        # 主题测试
```

## MVP 后端架构

MVP 阶段使用 **Spring Boot 3.3** 后端，采用 DDD 洋葱架构 + 充血模型。Phase 1 已完成。完整设计详见 [MVP 后端设计规格](../docs/superpowers/specs/2026-05-06-mvp-backend-design.md)。

核心分层：

- `domain/model/` — 聚合根、实体、值对象，纯业务规则，零框架依赖
- `domain/repository/` — Repository 接口（port）
- `domain/service/` — 领域服务，跨聚合编排
- `application/service/` — 用例编排、事务管理、事件发布
- `infrastructure/persistence/` — JPA 实现（adapter），domain ↔ JPA Entity 转换
- `interfaces/` — REST Controller + DTO，参数校验

所有业务表包含 `tenant_id`，Query 层统一注入租户条件。数据库迁移使用 Flyway。

## Issue 驱动工作流

GitHub Issues 是任务跟踪的入口，`docs/superpowers/plans/` 是实施细节的真相来源。每个 plan 文件包含 Issue 索引表和完成记录表。

当用户说"处理 issue #N"或类似指令时，按以下步骤执行：

1. **认领**: `gh issue edit <N> --add-assignee aime4eve`
2. **查找 Plan**: 在 `docs/superpowers/plans/*.md` 中搜索 `#N` 定位对应 plan 文件和具体小节
3. **阅读规格**: 读取 plan 中该 issue 的目标、涉及文件和验收标准
4. **实现**: 按计划开发，`flutter analyze` + `flutter test` 通过后提交
5. **关闭 Issue**: PR 正文写 `Closes #N`，合并后 GitHub 自动关闭
6. **同步 Plan**: 在 plan 文件的「完成记录」表中增加一行（完成日期、PR 链接、备注）

### Plan 文件约定

每个 plan 文件应包含：
- **Issue 索引表**: `| 优先级 | Issue | 标题 |` 格式，列出所有关联 issue
- **完成记录表**: `| 完成日期 | Issue | PR | 备注 |`，issue 关闭后立即更新
- 每个 issue 对应一个 `## #N — 标题` 小节，包含目标、涉及文件、验收标准

## 设计文档

- API 契约: [docs/api-contracts/mobile-app-mock-api-contract.md](docs/api-contracts/mobile-app-mock-api-contract.md)
- 设计规格: [docs/superpowers/specs/2026-03-26-smart-livestock-app-design.md](docs/superpowers/specs/2026-03-26-smart-livestock-app-design.md)
- 实施计划: [docs/superpowers/plans/2026-03-26-smart-livestock-app-implementation.md](docs/superpowers/plans/2026-03-26-smart-livestock-app-implementation.md)
- Demo 评审脚本: [docs/demo/lowfi-client-review-script.md](docs/demo/lowfi-client-review-script.md)
- Demo→MVP 欠账: [docs/demo/post-lowfi-follow-ups.md](docs/demo/post-lowfi-follow-ups.md)
- 编码约定: [AGENTS.md](AGENTS.md)

## 版本路线图

| 阶段 | 核心功能 | 状态 |
|------|---------|------|
| Demo Phase 1 | 订阅基础设施 + 功能门控 | 已完成 |
| Demo Phase 2a | 多牧场支持 + B端管理后台 + 牧场切换器 + 牧工管理 | 已完成 |
| MVP Phase 1 | 认证 + 租户/牧场 + 设备/牲畜 + 围栏/告警 + Dashboard/Map | 已完成 |
| MVP Phase 2a | Commerce（订阅计费 + 合同管理 + 分润对账 + 配额引擎） | 设计完成，实施中 |
| MVP Phase 2b | Health（温度/蠕动/发情/疫情分析 + 时序数据） | 待设计 |
| MVP Phase 2c | API 门户 + Analytics（统计聚合 + 趋势分析） | 待设计 |
| Phase 3 | IoT 真实接入（LoRa/NS + 真实传感器 + 时序分区） | 待设计 |