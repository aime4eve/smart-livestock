# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

智慧畜牧系统（Smart Livestock）是面向牧场主的牲畜管理平台，通过 IoT 设备（GPS 追踪器、瘤胃胶囊、加速度计）实现定位、健康预警和行为分析。仓库包含两个独立子项目：

- **PC/** — Angular 19 前端 + 规划中的 Spring Boot 后端（数据库设计阶段，当前从静态 JSON 加载数据）
- **Mobile/** — Flutter 移动端 + Node.js Mock API Server

两个子项目各自独立开发，不共享代码或依赖。

## 当前工作重点

**PC/ 目录暂不维护，所有开发工作集中在 Mobile/ 端。** 读取、搜索、修改代码时仅关注 Mobile/ 目录，不要主动分析或修改 PC/ 下的文件。

---

## GitHub 仓库

- **仓库地址**: https://github.com/aime4eve/smart-livestock
- **默认分支**: `master`
- **Git 协议**: HTTPS（已配置 gh credential helper，push/pull 免输密码）
- **GitHub CLI**: `gh` 已安装并认证（账号 `aime4eve`）

### 常用 Git 操作

```bash
git push origin master        # 推送到远程
git pull                      # 拉取最新
gh pr list                    # 查看 Pull Requests
gh issue list                 # 查看 Issues
gh pr create                  # 创建 PR
```

---

## PC 端

### 常用命令

```bash
# 安装全部依赖（根目录 workspaces 管理 frontend + backend）
cd PC && npm run install:all

# 同时启动前后端
npm start

# 仅前端
cd frontend && npm start          # ng serve，默认 localhost:4200

# 构建前端
cd frontend && npm run build

# 运行前端测试
cd frontend && npm test           # Karma + Jasmine
```

后端 Spring Boot 尚未实现（仅保留 entity/dto/repository/service 骨架 Java 文件），当前前端从 `frontend/src/assets/data/*.json` 静态文件加载数据。

### 架构

- **独立组件模式**（无 NgModule），Standalone Components + `app.config.ts`
- **路由**: `app.routes.ts` — `/home`（首页）、`/map`（地图监控）、`/cattle-register`（牛只管理）、`/device-register`（设备管理）
- **数据流**: JSON 文件 → Service（BehaviorSubject 缓存）→ Component
- **地图**: Leaflet（动态 import，SSR 安全），中心点长沙附近 (28.2458, 112.8519)
- **图表**: Chart.js，显示瘤胃温度和蠕动次数时序曲线
- **环境**: `environments/` 中 `apiUrl` 指向 `localhost:3000/api`（实际未调用）

### 关键 Service 依赖关系

```
CattleService ←→ LocationService（GPS 坐标）
              ←→ SensorService（温度/蠕动数据，链式查找：安装记录→温度日志→蠕动日志）
              ←→ CapsuleService（胶囊设备 CRUD）
```

### 数据模型

- `cattle.ts`: `Cattle`（地图用，含坐标）、`CattleDTO`（数据层，含品种/体重/胶囊状态）、`HealthStatus`（healthy/warning/critical）
- `capsule.ts`: `Capsule`（胶囊设备，含状态：库存/已安装/已过期）
- `sensor.ts`: `Sensor`、`TemperatureLog`、`PeristalticLog`、`CapsuleInstallation`

### 数据库设计

已完成的 PostgreSQL 设计（`database/init_postgresql.sql`，约 296KB）：users、devices、cattle、cattle_metadata、sensor_data 表，含空间索引和分区策略。详见 `backend-migration-database-design.md` 和 `backend-springboot-design.md`。

---

## Mobile 端

### 常用命令

```bash
# Flutter 前端
cd Mobile/mobile_app
flutter pub get
flutter test                           # 运行所有测试
flutter test test/widget_smoke_test.dart  # 运行单个测试
flutter test --name="owner"            # 按名称过滤
flutter analyze                        # 静态分析
flutter run                            # Mock 模式（默认）
flutter run --dart-define=APP_MODE=live  # Live 模式（连接 Mock Server）
flutter build web

# Mock Server
cd Mobile/backend
npm install
node server.js                         # 启动（端口 3001）
node --watch server.js                 # 开发模式
node --test test/*.test.js             # 运行全部后端测试

# 一键启动（Mobile 根目录）
cd Mobile && ./dev.sh start [mock|live]
./dev.sh stop
./dev.sh status
```

### 前端架构（Flutter）

- **状态管理**: flutter_riverpod，严格使用 ConsumerWidget，禁用 setState/ChangeNotifier
- **路由**: go_router，`AppRoute` 枚举为路径唯一来源（34 条路由），含认证守卫重定向
- **模式切换**: `--dart-define=APP_MODE=mock|live`，mock 用本地假数据，live 通过 ApiCache 调 Mock Server
- **模块分层**: `features/{module}/domain/`（Repository 接口）→ `data/`（mock + live 实现）→ `presentation/`（Riverpod Notifier Controller）
- **功能模块**（19 个）: admin、alerts、auth、b2b_admin、dashboard、devices、digestive、epidemic、estrus、farm_switcher、fence、fever_warning、highfi、livestock、mine、stats、subscription、tenant、twin_overview、worker_management
- **UI 语言**: 中文，变量名英文

### Mock Server 架构

- **端口**: 3001，纯内存无持久化
- **认证**: 固定 token `mock-token-{role}`（5 种角色，见角色表）
- **响应格式**: 统一 `{ code, message, requestId, data }` 包络，列表接口 `{ items, page, pageSize, total }`
- **Store 模式**: 数据层使用内存 Store 模块（`backend/data/*Store.js`），每个 Store 暴露 CRUD + 查询方法，模块级变量持有数据数组。新建 Store 需提供 `reset()` 方法（测试隔离）。当前 Stores: seed.js, fenceStore.js, tenantStore.js, contractStore.js, subscriptions.js, workerFarmStore.js, twin_seed.js, feature-flags.js
- **中间件链**: cors → json → requestContext → envelope → auth（Bearer token）→ farmContext（提取 activeFarmTenantId）→ shaping（tier 功能门控）
- **告警状态机**: pending → acknowledged → handled → archived，非法跳转返回 409
- **API 路由**: auth、me、dashboard、map、alerts、fences、devices、tenants、profile、twin（数智孪生）、subscription、b2b、farm、worker。Open API 路由（`/api/open/v1/*`）使用 API Key 认证 + 频率限制。
- **数据种子**: `backend/data/seed.js` 与 Flutter 端 `demo_seed.dart` 保持对齐

### 订阅与功能门控

- `SubscriptionTier` 枚举: trial、basic、pro、enterprise
- `middleware/feature-flag.js` 基于 tier 控制功能可见性
- `ApiCache` 预加载时按 tier 范围过滤数据
- 锁定功能显示升级提示覆盖层

### 角色与权限

| 角色 | DemoRole / Token | 可见范围 |
|------|------------------|---------|
| owner（牧场主） | `mock-token-owner` | 全部页面 + 后台管理 + 牧工管理 + 订阅管理 |
| worker（牧工） | `mock-token-worker` | 看板/地图/告警/我的/围栏，仅确认告警 |
| platform_admin（平台管理员） | `mock-token-platform-admin` | 租户全量管理 + 合同 CRUD + 分润对账 + 订阅服务管理 + API 授权审批 |
| b2b_admin（B端客户管理员） | `mock-token-b2b-admin` | 概览/牧场管理/合同信息/对账/旗下牧工管理 |
| api_consumer（API 开发者） | `mock-token-api-consumer` | 仅 API 访问，无 App 端（开发者门户 Phase 2b 规划中） |

### 代码风格

- 文件: `snake_case.dart`，类: `UpperCamelCase`，私有辅助类: `_ClassName`
- 所有主要 UI 元素必须有 `Key('descriptive-id')` 用于测试
- 主题 token（AppColors/AppSpacing/AppTypography）而非硬编码数值
- Provider 命名: `{module}RepositoryProvider`、`{module}ControllerProvider`

---

## 版本路线图

| 阶段 | 核心功能 |
|------|---------|
| Phase 1 (已完成) | 订阅基础设施 + 功能门控 |
| Phase 2a (已完成) | 多牧场支持 + B端管理后台 + 牧场切换器 + 牧工管理 |
| Phase 2b (设计中) | 分润对账 + 订阅服务管理 + 合同 CRUD + API 平台 + 开发者门户 |
| MVP V1.0 | GPS 定位 + 电子围栏 + 基础告警 + 历史轨迹 + 租户管理后台 |
| V1.5 | 瘤胃温度/蠕动监测 + 健康评分 |
| V2.0 | 步态分析 + 行为统计 + 发情检测 |
