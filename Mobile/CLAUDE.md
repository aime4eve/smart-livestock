# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

智慧畜牧 App 是面向牧场主/养殖户的牛羊智慧管理移动应用，通过 GPS追踪器、瘤胃胶囊、加速度计三类 IoT 设备，实现牲畜定位管控、健康预警和行为分析。

**当前阶段**: 高保真 Demo → MVP 过渡期。前端使用 Flutter + Riverpod，后端 Mock API 使用 Node.js + Express（端口 3001）。APP_MODE=live 时前端通过 HTTP 调用 Mock Server，APP_MODE=mock 时使用本地假数据。

## 技术栈

- **前端**: Flutter / Dart SDK >=3.3.0（iOS/Android/Web 跨平台）
- **状态管理**: flutter_riverpod
- **路由**: go_router
- **地图**: flutter_map + latlong2（Leaflet 的 Flutter 封装）
- **图表**: fl_chart（时序曲线、柱状图等）
- **HTTP 客户端**: `http` 包（live 模式调用 Mock Server）
- **Mock Server**: Node.js + Express 5（`backend/`，端口 3001）
- **MVP 后端** (待实现): AdonisJS v6 + TypeScript
- **数据库** (待实现): PostgreSQL + 时序数据接口抽象
- **实时通信** (待实现): MQTT (EMQX/Mosquitto)

## 目录结构

```
Mobile/
├── mobile_app/              # Flutter 前端应用
│   ├── lib/
│   │   ├── app/             # 应用层：路由、Shell、Session、模式切换
│   │   ├── core/            # 核心：模型、权限、数据种子、API 缓存
│   │   │   ├── models/      # demo_role, demo_models, view_state
│   │   │   ├── data/        # demo_seed（假数据）
│   │   │   ├── api/         # api_cache（HTTP 缓存，live 模式启动时预加载）、api_role
│   │   │   ├── mock/        # mock_config, mock_scenarios
│   │   │   ├── permissions/ # role_permission（权限判断）
│   │   │   └── theme/       # app_colors, app_spacing, app_typography, app_theme
│   │   ├── features/        # 功能模块
│   │   │   ├── pages/       # 页面（twin_overview, map, alerts, fence, devices, stats 等）
│   │   │   ├── auth/        # 登录页
│   │   │   └── {module}/    # 每个模块：domain/repository + data/mock+live + presentation/controller
│   │   └── widgets/         # 通用组件（metric_card, empty_state, status_tag）
│   └── test/                # 测试文件
├── backend/                 # Mock API Server（Node.js + Express）
│   ├── server.js            # 入口，端口 3001
│   ├── routes/              # 路由：auth, me, dashboard, map, alerts, fences, devices, tenants, profile, twin
│   ├── middleware/           # auth（token 校验 + 权限）, envelope（统一响应包络）
│   └── data/seed.js         # 假数据（与 demo_seed.dart 对齐）
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
flutter test                       # 运行所有测试
flutter test test/widget_smoke_test.dart  # 运行单个测试文件
flutter test --name="owner"        # 按名称过滤
flutter run                        # 运行应用（需要模拟器或设备）
flutter run --dart-define=APP_MODE=mock   # Mock 模式（默认，本地假数据）
flutter run --dart-define=APP_MODE=live   # Live 模式（调用 Mock Server）
flutter analyze                    # 静态分析
flutter build web                  # 构建 Web 版本
```

### Web 端注意事项

Web 端默认请求 `http://127.0.0.1:3001/api`（避免浏览器将 `localhost` 解析到 IPv6）。若仍连不上可显式指定：
```bash
flutter run -d chrome --dart-define=APP_MODE=live --dart-define=API_BASE_URL=http://127.0.0.1:3001/api
```

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
│   └── live_{module}_repository.dart  # Live 实现（读取 ApiCache → Mock Server 数据）
└── presentation/
    └── {module}_controller.dart    # Riverpod Notifier，根据 AppMode 切换 repo
```

当前功能模块：`alerts`、`dashboard`、`devices`、`digestive`、`epidemic`、`estrus`、`fence`、`fever_warning`、`highfi`、`livestock`、`mine`、`stats`、`twin_overview`

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

### 应用入口与模式

- `lib/main.dart` → `DemoApp` → `DemoShell`
- `AppMode` (mock/live) 通过 `--dart-define=APP_MODE=xxx` 切换，默认 mock
- live 模式下 `main()` 在 `runApp` 前调用 `ApiCache.instance.init('owner')` 预加载全部 API 数据
- `DemoApp` 接受 `overrides`（Provider 覆盖）和 `appMode` 参数，方便测试注入
- `DemoShell` 根据当前角色动态构建底部导航
- 路由定义集中在 `AppRoute` 枚举（`app/app_route.dart`），是路径、名称、标签的唯一来源
- `GoRouter` 配置在 `app/app_router.dart`，通过 `refreshListenable` 监听 session 变化自动重定向

### Live 模式数据流

```
main.dart (async)
  → ApiCache.instance.init('owner')   // 预加载：并发 GET 多个 API 端点
  → runApp(DemoApp)

LiveXxxRepository.load()
  → ApiCache.instance.xxx             // 同步读取缓存
  → 若缓存未初始化 → fallback 到 MockXxxRepository
```

Repository 接口保持同步（返回 ViewData 而非 Future），通过启动时预加载避免 async 改造。

### 会话与认证

- `AppSession`（值对象）封装登录状态和角色，通过 `SessionController`（Riverpod Notifier）管理
- `LoginPage` 选择角色后调用 `sessionControllerProvider.notifier.login(role)`
- 路由守卫在 `app_router.dart` 的 `redirect` 回调中：未登录→`/login`，ops→`/ops/admin`，非 owner 访问 `/admin`→`/twin`

### 主题系统

- Material 3 主题，集中在 `core/theme/` 下四个文件：`app_colors`、`app_spacing`、`app_typography`、`app_theme`
- `AppTheme.light()` 生成 `ThemeData`，在 `DemoApp` 中注入 `MaterialApp.router`
- 使用主题 token（AppColors/AppSpacing/AppTypography）而非硬编码数值

### 角色与权限

| 角色   | DemoRole 枚举 | 可见导航              | 权限特点                   |
| ---- | ----------- | ----------------- | ---------------------- |
| 牧场主  | `owner`     | 孪生/地图/告警/我的/围栏/后台 | 完整权限，可编辑围栏、处理告警        |
| 牧工   | `worker`    | 孪生/地图/告警/我的/围栏    | 仅可确认告警，不可处理/归档；孪生场景仅查看 |
| 平台运维 | `ops`       | 仅租户管理后台           | 无底部导航，独立页面             |

前端权限判断在 `RolePermission` 类中；Mock Server 权限校验在 `middleware/auth.js` 的 `requirePermission()` 中。

### 页面状态

各页使用 `ViewState`（正常/加载/空/错误/无权限/离线）分支渲染；由仓储返回的数据与 Controller 决定，不再提供全局演示用手动下拉切换。

## Mock Server 架构

### 认证机制

- 登录 `POST /api/auth/login` body: `{ role }` → 返回固定 token `mock-token-{role}`
- 中间件解析 Bearer token 确定角色和权限
- `requirePermission('xxx')` 工厂函数用于路由级权限校验

### 响应格式

所有接口统一 `{ code, message, requestId, data }` 包络，列表接口使用 `{ items, page, pageSize, total }` 分页结构。

### 告警状态机

告警状态只能顺序推进：`pending → acknowledged → handled → archived`。服务端校验非法跳转返回 409 CONFLICT。

### API 契约

完整端点定义见：`docs/api-contracts/mobile-app-mock-api-contract.md`

基础端点：auth(1) + me(1) + dashboard(1) + map(1) + alerts(5) + fences(4) + devices + tenants(4) + profile(1)；数智孪生扩展：`/api/twin/*`（overview、fever/digestive/estrus 列表与详情、epidemic summary/contacts）

## 测试结构

```
mobile_app/test/
├── widget_smoke_test.dart              # 基础 Widget 冒烟测试
├── widget_test.dart                    # 通用 Widget 测试
├── app_architecture_test.dart          # 架构约束测试（分层、依赖方向）
├── app_mode_switch_test.dart           # AppMode 切换测试
├── mock_repository_override_test.dart  # Mock Repository Provider 覆盖测试
├── mock_repository_state_test.dart     # Mock 数据状态测试
├── role_visibility_test.dart           # 角色可见性测试
├── state_persistence_test.dart         # 状态持久化测试
├── flow_smoke_test.dart                # 端到端流程冒烟测试
├── seed_data_test.dart                 # 种子数据验证测试
├── generator_test.dart                 # 数据生成器测试
├── fence_dto_test.dart                 # 围栏 DTO 测试
├── live_devices_repository_test.dart   # Live 设备仓储测试
├── twin_overview_pasture_context_test.dart  # 孪生总览牧场上下文测试
├── twin_series_downsample_test.dart    # 时序降采样测试
├── features/
│   └── fence/                          # 围栏模块测试
├── highfi/                             # 高保真组件测试
└── theme/                              # 主题测试
```

## MVP 后端架构约束（规划）

MVP 阶段将用 **AdonisJS v6** 替换 Mock Server，遵循以下分层：

- `app/models/*` — Lucid Active Record 模型，只负责持久化结构，不写业务规则
- `app/validators/*` — VineJS 校验器，只负责接口契约（DTO）
- `app/controllers/*` — 只做参数校验和调用 service，不写业务规则
- `app/services/*` — 负责规则、聚合与领域逻辑
- `app/middleware/*` — auth、tenant 隔离等横切关注点
- `database/migrations/*` — Lucid 迁移文件，进 git
- `database/seeders/*` — 初始化数据（对齐现有 `data/seed.js`）
- `start/routes.ts` — 路由注册，统一 `/api/v1/` 前缀
- `start/kernel.ts` — 全局与具名中间件注册

云端部署时，所有业务表包含 `tenant_id`，Lucid 基类 Repository 统一注入租户条件。

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

| 阶段   | 版本   | 核心功能                                                                     |
| ---- | ---- | ------------------------------------------------------------------------ |
| Demo | 当前   | 高保真 UI + Mock Server API；**数智孪生四场景（发热/消化/发情/疫病）已 Mock 落地**，默认首页为 `/twin` |
| MVP  | V1.0 | GPS定位 + 电子围栏 + 基础告警 + 历史轨迹 + 租户管理后台                                      |
| 进阶   | V1.5 | 瘤胃温度/蠕动监测 + 健康评分（Demo 已用 Mock 预演 UI，真实 IoT 在后续版本）                        |
| 完整   | V2.0 | 步态分析 + 行为统计 + 发情检测（Demo 已用 Mock 预演发情/疫病 UI）                              |
