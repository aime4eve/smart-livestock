# AGENT.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

## 5. Build / Deploy / Test 分工约定

**编译可以执行，部署必须由用户完成，集成测试仅在部署后执行。**

- **编译**：Agent 可自行执行（如 `./gradlew bootJar`、`flutter build web`），验证代码可构建。
- **部署**：一律由用户执行（`rsync`、`docker compose`、`ssh` 等部署操作，Agent 不碰）。Agent 改动涉及部署时，提供命令供用户执行即可，不要自行调用。
- **集成测试**：仅在用户确认部署完成后才执行；不得在部署前提前运行（避免对旧版本/无后端状态做无效验证）。
- **顺序**：编码 → 编译验证 → （用户部署）→ 用户确认 → 集成测试。

## 项目概述

智慧畜牧系统（Smart Livestock）是面向牧场主的牲畜管理平台，通过 IoT 设备（GPS 追踪器、瘤胃胶囊、加速度计）实现定位、健康预警和行为分析。仓库包含两个子项目：

- **Mobile/** — Flutter 移动端（已移除 Mock 模式，通过 ApiClient 对接 Spring Boot 后端）
- **smart-livestock-server/** — Spring Boot 后端（MVP Phase 1 + Phase 2a Commerce 已完成，DDD 洋葱架构）

Flutter 端已完成：订阅与功能门控、多牧场切换、B端管理后台、牧工管理、租户用户管理。Spring Boot 后端 Phase 1（Identity + Ranch + IoT）和 Phase 2a（Commerce）已实施完成，前端通过 JWT 认证对接真实后端。

## 当前工作重点

**后端实施集中在 `smart-livestock-server/` 目录（Spring Boot），前端维护集中在 `Mobile/` 目录。** PC/ 目录暂不维护。读取、搜索、修改后端代码时关注 `smart-livestock-server/`，前端代码关注 `Mobile/`。

---

## GitHub 仓库

- **仓库地址**: [https://github.com/aime4eve/smart-livestock](https://github.com/aime4eve/smart-livestock)
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

已完成的 PostgreSQL 设计（`database/init_postgresql.sql`，约 296KB）：users、devices、cattle、cattle_metadata、sensor_data 表，含空间索引和分区策略。详见 `backend-migration-database-design.md` 和 `backend-springboot-design.md`。注意：此为 PC 端早期设计，与 MVP 后端（`smart-livestock-server/`）的设计规格独立。

---

## 后端（smart-livestock-server/）

> MVP Phase 1（Identity + Ranch + IoT）和 Phase 2a（Commerce）已完成。5 个限界上下文，312 Java 文件，37 Controller，~130 API 端点，20+ 张表。

### 后端服务部署方式

- ssh agentic@172.22.1.123 远程登录服务器
- rsync 最新代码到 172.22.1.123
- docker compose build + up 部署更新

### 一键部署（本地执行）

```bash
cd smart-livestock-server
./gradlew bootJar -x test
rsync -avz --exclude='.git' --exclude='.gradle' --exclude='node_modules' --exclude='build/tmp' --exclude='build/classes' . agentic@172.22.1.123:~/smart-livestock-server/
# 清理旧 JAR，只保留最新版本号
ssh agentic@172.22.1.123 "cd ~/smart-livestock-server/build/libs && ls -t smart-livestock-server-*.jar | tail -n +2 | xargs rm -f"
ssh agentic@172.22.1.123 "cd ~/smart-livestock-server && docker compose build app && docker compose up -d app"
```

### 种子数据登录凭据

| 角色                    | 手机号         | 密码          | 说明                  |
| --------------------- | ----------- | ----------- | ------------------- |
| platform_admin（平台管理员） | 13800000000 | 123 | 平台级管理，无租户归属         |
| b2b_admin（B端管理员）      | 13900139000 | 123 | B端管理员，关联 Demo 租户（V13 seed） |
| owner（牧场主）            | 13800138000 | 123 | Demo 租户 owner，关联主牧场 |

### 角色旅程链

```
platform_admin → 创建租户 → 进入租户详情 → 新增用户（b2b_admin / owner / worker）
b2b_admin → 创建牧场 → 分配给 owner
owner → 管理牲畜、围栏、告警、牧工
```

牧场不由 owner 自行创建，由 b2b_admin 或 platform_admin 创建并分配。

### Seed 密码流程

Seed 迁移中的 BCrypt hash 必须严格遵循三步验证，不可跳过：

1. **生成时验证**：生成 hash 后立即用 `bcrypt.compare(plaintext, hash)` 确认匹配
2. **写入迁移**：确认匹配后写入 SQL 文件，不得跨迁移复制 hash（之前的 hash 可能本身就是错的）
3. **部署后验证**：部署后用 `curl` 调用 `/auth/login` 确认真实登录成功

历史教训：V4 hash 错误 → V5 "修复" 仍然错误 → V13 复制 V5 hash 延续错误。每一步都跳过了验证。

### 前端 Live 模式连接后端

```bash
cd Mobile/mobile_app
flutter run -d chrome --dart-define=APP_MODE=live --dart-define=API_BASE_URL=http://172.22.1.123:18080/api/v1
```

### 设计文档索引

| 文档         | 位置                                                               | 说明                                |
| ---------- | ---------------------------------------------------------------- | --------------------------------- |
| MVP 后端设计规格 | `docs/superpowers/specs/2026-05-06-mvp-backend-design.md`        | DDD 限界上下文、DB Schema、洋葱架构、API 总览   |
| Phase 1 实施计划 | `docs/superpowers/plans/2026-05-06-mvp-phase1-implementation.md` | 16 个 Task，TDD 流程                |
| 租户入驻设计 | `docs/superpowers/specs/2026-05-13-tenant-onboarding-design.md` | TenantPhase + Farm 创建向导 |
| 多区域地图瓦片设计 | `docs/superpowers/specs/2026-05-15-multi-region-map-tiles-design.md` | tileserver-gl + SmartTileProvider 三级降级 |
| Commerce 设计规格 | `docs/superpowers/specs/2026-05-18-commerce-context-design.md` | 订阅/合同/分润/配额引擎，已评审通过 |
| Commerce 实施计划 | `docs/superpowers/plans/2026-05-18-commerce-context-plan.md` | 11 个 Task |
| 前端适配计划 | `docs/superpowers/plans/2026-05-12-flutter-frontend-adaptation.md` | Flutter 对接 Spring Boot 后端 |
| API 契约总览   | `docs/api-contracts/api-overview.md`                             | 三端隔离、通用约定、Farm Scope              |
| App API    | `docs/api-contracts/app-api.md`                                  | `/api/v1/` 64 端点                  |
| Admin API  | `docs/api-contracts/admin-api.md`                                | `/api/v1/admin/` 30 端点            |
| Open API   | `docs/api-contracts/open-api.md`                                 | `/api/v1/open/` 17 端点              |
| Health 设计规格 | `docs/superpowers/specs/2026-05-31-health-context-design.md` | 温度/蠕动/发情/疫病分析引擎，已实施完成 |
| Analytics+Portal 设计规格 | `docs/superpowers/specs/2026-05-31-analytics-portal-context-design.md` | API Key 自管理 + 频率限制 + 统计聚合 + 趋势分析 |

### 技术栈

Spring Boot 3.3 + Java 17 + Gradle + PostgreSQL 16 + Redis 7 + RocketMQ 5.1 + Flyway + JPA/Hibernate + Spring Security + JWT + Lombok + JUnit 5 + Testcontainers

### 限界上下文

#### Phase 1 — 已完成

- **Identity**: Tenant、User、Farm、Role、ApiKey（JWT 认证 + 多租户隔离 + 5 种角色）
- **Ranch**: Livestock、Fence、Alert、Dashboard、Map（围栏越界检测 → 自动告警）
- **IoT**: Device、DeviceLicense、Installation、GpsLog（GPS 模拟数据）
- **Shared**: SecurityConfig、JwtAuthenticationFilter、TenantScope、AuditLog（已完整实现）

#### Phase 2a — 已完成

- **Commerce**: Subscription、Contract、RevenuePeriod、SubscriptionService、FeatureGate（完整 DDD 洋葱架构，80 Java 文件，11 测试类，7 Controller）

#### Phase 2b — 已完成

- **Health**: 温度/蠕动/发情/疫情分析引擎 + 时序数据

#### Phase 2c — 设计完成

- **Analytics + API Portal**: API Key 生命周期 + 开发者门户 + 频率限制 + 统计聚合 + 趋势分析
- **设计文档**: 

### 数据库表（20+ 张，17 个 Flyway 迁移）

| 迁移 | 表 | 限界上下文 |
|------|---|--------|
| V1 | tenants, farms, users, user_farm_assignments, api_keys | Identity |
| V2 | livestock, fences, alerts | Ranch |
| V3 | devices, device_licenses, installations, gps_logs | IoT |
| V6 | subscriptions, contracts, revenue_periods, subscription_services, feature_gates, notifications | Commerce |
| V13 | tile 相关表 + fence version | Ranch |
| V18 | audit_logs | Shared |

V4-V5: seed 数据 + 密码修复；V7-V8: subscription 修复 + hash 前缀修复；V9-V12: ranch/commerce/twin seed 数据；V13: tile 表 + fence version；V15: username 列清理；V16-V17: b2b_admin/worker/farm2 seed 数据。

### 后端 Controller（37 个）

| 分类 | Controller |
|------|-----------|
| App API | AuthController, MeController, TenantController, FarmController, B2bController, LivestockController, FenceController, AlertController, DashboardController, MapController, TileAppController, DeviceController, DeviceLicenseController, InstallationController, GpsLogController, HealthController, CommerceController, SubscriptionController |
| Admin API | TenantAdminController, FarmAdminController, UserAdminController, DashboardAdminController, AuditLogController, ApiKeyAdminController, TileAdminController, AdminSubscriptionController, AdminContractController, AdminFeatureGateController, AdminRevenueController, AdminServiceController, AnalyticsController |
| Open API | OpenLivestockController, OpenFenceController, OpenAlertController, OpenDeviceController, OpenDeviceRegisterController, OpenGpsController |

### 常用命令

```bash
cd smart-livestock-server
./gradlew compileJava              # 编译
./gradlew test                     # 全部测试（58 个测试类）
./gradlew test --tests "*.domain.model.*"  # 领域模型单元测试
./gradlew bootRun                  # 启动（需 PostgreSQL + Redis）
docker compose up -d               # 全栈启动（PostgreSQL + Redis + RocketMQ + App）
```

### 地图瓦片基础设施

- **tileserver-gl**: 自建瓦片服务，部署在 172.22.1.123:18080，提供 WGS-84 瓦片
- **MBTiles 离线**: 原生平台支持离线瓦片（`sample.mbtiles`，长沙 zoom 12-14）
- **SmartTileProvider**: 三级降级（tileserver-gl → MBTiles → 高德/OSM），健康检测自动切换
- **坐标转换**: WGS-84 ↔ GCJ-02（`coord_transform.dart`），高德降级时自动转换
- **部署指南**: `docs/tileserver-deployment-guide.md`

---

## Mobile 端

### 常用命令

```bash
# Flutter 前端
cd Mobile/mobile_app
flutter pub get
flutter test                           # 运行所有测试（24 个测试文件）
flutter test test/widget_smoke_test.dart  # 运行单个测试
flutter test --name="owner"            # 按名称过滤
flutter analyze                        # 静态分析
flutter run                            # Mock 模式（默认）
flutter run --dart-define=APP_MODE=live  # Live 模式（连接 Mock Server 或 Spring Boot）
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
- **路由**: go_router，`AppRoute` 枚举为路径唯一来源（42 条路由），含认证守卫重定向
- **模式切换**: `--dart-define=APP_MODE=mock|live`，mock 用本地假数据，live 通过 ApiCache 调后端 API
- **模块分层**: `features/{module}/domain/`（Repository 接口）→ `data/`（mock + live 实现）→ `presentation/`（Riverpod Notifier Controller）
- **功能模块**（29 个）: admin、alerts、api_authorization、auth、b2b_admin、contract_management、dashboard、devices、digestive、epidemic、estrus、farm_creation、farm_switcher、fence、fever_warning、highfi、livestock、mine、offline_fences、offline_livestock、offline_tiles、pages、revenue、stats、subscription、subscription_service_management、tenant、twin_overview、worker_management
- **地图**: flutter_map + SmartTileProvider（三级降级）+ MBTiles 离线 + WGS-84/GCJ-02 坐标转换
- **UI 语言**: 中文，变量名英文

### Mock Server 架构

- **端口**: 3001，纯内存无持久化
- **认证**: 固定 token `mock-token-{role}`（5 种角色，见角色表）
- **响应格式**: 统一 `{ code, message, requestId, data }` 包络，列表接口 `{ items, page, pageSize, total }`
- **Store 模式**: 数据层使用内存 Store 模块（`backend/data/*Store.js`），每个 Store 暴露 CRUD + 查询方法，模块级变量持有数据数组。新建 Store 需提供 `reset()` 方法（测试隔离）。当前 Stores: seed.js, fenceStore.js, tenantStore.js, contractStore.js, subscriptions.js, workerFarmStore.js, twin_seed.js, feature-flags.js
- **中间件链**: cors → json → requestContext → envelope → auth（Bearer token）→ farmContext（提取 activeFarmTenantId）→ shaping（tier 功能门控）
- **告警状态机**: pending → acknowledged → handled → archived，非法跳转返回 409
- **API 路由**: auth、me、dashboard、map、alerts、fences、devices、tenants、profile、twin（数智孪生）、subscription、b2b、farm、worker。Open API 路由（`/api/open/v1/`*）使用 API Key 认证 + 频率限制。
- **数据种子**: `backend/data/seed.js` 与 Flutter 端 `demo_seed.dart` 保持对齐

### 订阅与功能门控

- `SubscriptionTier` 枚举: basic、standard、premium、enterprise（后端 Commerce Phase 2 已实现配额引擎）
- `middleware/feature-flag.js` 基于 tier 控制功能可见性
- `ApiCache` 预加载时按 tier 范围过滤数据
- 锁定功能显示升级提示覆盖层

### 角色与权限

前端已移除 Mock 模式，通过 JWT 认证对接 Spring Boot 后端。

| 角色 | 可见范围 | Shell 类型 |
|------|---------|-----------|
| owner（牧场主） | 全部页面 + 后台管理 + 牧工管理 + 订阅管理 | 底部导航栏（4-5 Tab） |
| worker（牧工） | 看板/地图/告警/我的/围栏，仅确认告警 | 底部导航栏（4 Tab） |
| platform_admin（平台管理员） | 租户全量管理 + 用户管理 + 合同 CRUD + 分润对账 + 订阅服务管理 + API 授权审批 | 无 Shell，纯 Scaffold |
| b2b_admin（B端客户管理员） | 概览/牧场管理/合同信息/对账/旗下牧工管理 | 左侧 NavigationRail |
| api_consumer（API 开发者） | 仅 API 访问，无 App 端（开发者门户 MVP Phase 2 规划中） | — |

**旅程链**：platform_admin → 创建 b2b_admin → b2b_admin 创建牧场 → 分配给 owner。牧场不由 owner 自行创建。详见 `docs/customer-journey.md`。

### 代码风格

- 文件: `snake_case.dart`，类: `UpperCamelCase`，私有辅助类: `_ClassName`
- 所有主要 UI 元素必须有 `Key('descriptive-id')` 用于测试
- 主题 token（AppColors/AppSpacing/AppTypography）而非硬编码数值
- Provider 命名: `{module}RepositoryProvider`、`{module}ControllerProvider`

---

## 版本路线图

> Flutter Demo 阶段已完成：订阅基础设施 + 功能门控、多牧场支持 + B端管理后台 + 牧场切换器 + 牧工管理。
> Spring Boot 后端 MVP Phase 1 + Phase 2a Commerce 已完成，4 个限界上下文全部实施。

| 阶段                     | 核心功能                                                                   | 限界上下文                         | 状态  |
| ---------------------- | ---------------------------------------------------------------------- | ----------------------------- | --- |
| **MVP Phase 1** — 核心底座 | 认证(JWT) + 租户/牧场 + 设备/牲畜 + 围栏/告警 + Dashboard/Map + GPS 模拟               | Identity + Ranch + IoT        | ✅ 已完成 |
| **MVP Phase 2a** — Commerce | 订阅计费 + 合同管理 + 分润对账 + Tier 配额引擎 + Licensed 服务 + FeatureGate             | Commerce                      | ✅ 已完成 |
| **MVP Phase 2b — Health | 温度/蠕动/发情/疫情分析引擎 + 时序数据 | Health | ✅ 已完成 |
| **MVP Phase 2c — 平台扩展 | API Key 生命周期 + 开发者门户 + 频率限制 + 统计聚合 + 趋势分析 | Analytics + API Portal | 📐 设计完成 |
| **Phase 3** — IoT 真实接入 | 设备 license 入网 + LoRa/NS 平台对接 + 真实传感器数据 + 时序数据分区                        | IoT 扩展                        | ⏳ 待设计 |

**后端现状**：5 个限界上下文（Identity + Ranch + IoT + Commerce + Shared）、20+ 张表、~130 个 API 端点、37 个 Controller、312 个 Java 文件、58 个测试类。AuditLog 和 Auth refresh 已完整实现（不再是 stub）。

**前端现状**：已移除 Mock 模式，全部通过 ApiClient 异步对接 Spring Boot 后端（JWT 认证）。29 个功能模块、42 条路由。订阅系统（4 个 tier + 23 个 feature flag）、B端后台、租户管理（TenantDetailPage 含用户创建/启停）、健康模块（发热/消化/发情/疫病）UI 框架已搭好、离线模块（离线围栏/离线牲畜/离线瓦片）。地图支持三级瓦片降级（tileserver-gl → MBTiles → 高德/OSM）。客户旅程文档：`docs/customer-journey.md`。

---


## 牧场切换数据刷新规则

**所有使用 farm-scoped API（ApiClient 的 farmGet / farmPost / farmPut / farmDelete）的 Controller 必须遵守以下规则：**

1. **继承基类**：使用 FarmScopedNotifier 或 FarmScopedAsyncNotifier（定义在 core/api/farm_scoped_controller.dart），不要直接继承 Notifier / AsyncNotifier。
2. **在 build() 开头调用 watchActiveFarmId()**：这会声明对 activeFarmId 的依赖，确保牧场切换时自动重建并刷新数据。
3. **新 Controller checklist**：
   - Repository 使用 ApiClient.farmGet() 等方法？→ Controller 必须继承 FarmScoped* 基类
   - Repository 只用普通 get() / post()（如租户级 API）？→ 普通的 Notifier / AsyncNotifier 即可
4. **测试要求**：使用 ProviderContainer 的单元测试必须 override initialSessionProvider 提供有效 activeFarmId。

**违反此规则的典型症状**：牧场切换后页面数据不更新，仍显示旧牧场数据。
