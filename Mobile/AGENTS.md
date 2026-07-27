# Mobile/AGENTS.md — Flutter 移动端专属规则

> 公共规则（行为准则、i18n、Seed、部署分工、工作流分级、经验判据）见根目录 `AGENTS.md`。
> 项目概述、角色权限、订阅与功能门控见 `docs/reference/project-overview.md`。
> 本文件只维护 Mobile 端独有的架构与约定。

## 目录结构

```
mobile_app/lib/
├── app/
│   ├── app_route.dart          # AppRoute enum — 路径唯一来源
│   ├── app_router.dart         # GoRouter config + 认证守卫重定向
│   ├── demo_app.dart           # Root widget（ProviderScope + MaterialApp.router）
│   ├── demo_shell.dart         # Shell：role-based 底部导航 + B2B admin rail
│   └── session/                # AppSession value object + SessionController
├── core/
│   ├── api/
│   │   ├── api_client.dart     # ApiClient singleton（base URL, JWT, farm-scoped CRUD）
│   │   ├── api_exception.dart  # sealed ApiException 层级
│   │   ├── farm_scoped_controller.dart  # FarmScopedNotifier 基类（见根目录「牧场切换规则」）
│   │   └── jwt_storage.dart    # JWT 持久化
│   ├── map/                    # SmartTileProvider 三级降级 + MBTiles + 坐标转换
│   ├── models/                 # core_models, subscription_tier, user_role, view_state
│   ├── permissions/role_permission.dart
│   └── theme/                  # AppColors / AppSpacing / AppTypography
├── features/{module}/          # 每个模块: domain/(接口) → data/(API实现) → presentation/(Notifier)
│   # 模块: admin, ai_anomaly, alerts, auth, b2b_admin, devices, fence, livestock,
│   # mine, ranch, subscription, tenant, worker_management, offline_*, health 相关等
└── widgets/                    # 共享组件（metric_card, empty_state, pagination_bar 等）
```

## 代码风格

- **文件**：`snake_case.dart`；**类**：`UpperCamelCase`；**私有辅助类**：`_ClassName`
- 所有主要 UI 元素必须有 `Key('descriptive-id')` 用于测试
- 主题 token（AppColors/AppSpacing/AppTypography）而非硬编码数值
- Provider 命名：`{module}RepositoryProvider`、`{module}ControllerProvider`
- 导入顺序：Flutter SDK → 第三方（flutter_riverpod, go_router, http）→ 项目（hkt_livestock_agentic/）

## Widget 约定

- `const` 构造 + `super.key`（不用 `Key? key`）
- 读 provider 用 `ConsumerWidget`（不用 `StatelessWidget`）
- `ref.watch()` 在 `build()`；`ref.read()` 在回调
- Models：immutable value objects（`const` 构造 + `final` 字段）

## 状态管理

- `flutter_riverpod` 专用，**禁用** `setState` / `ChangeNotifier`
- `Provider` 只读依赖；`NotifierProvider` 可变状态
- `ViewState` enum（normal/loading/empty/error/forbidden/offline）控制 UI 切换
- `ApiException` sealed 层级统一错误处理

## Farm-Scoped API

- `ApiClient` farm-scoped 方法（`farmGet/farmPost/farmPut/farmDelete`）自动拼 `/farms/{activeFarmId}`
- 使用 farm-scoped API 的 Controller 必须继承 `FarmScopedNotifier`（详见根目录「牧场切换数据刷新规则」）

## 测试

- `flutter_test` only；按 `Key` 查找 widget（不用 text）
- `DemoApp(overrides:)` 支持注入 provider
- 测试文件镜像源文件结构：`{feature}/{aspect}_test.dart`
- `ProviderContainer` 单测必须 override `initialSessionProvider` 提供有效 `activeFarmId`
