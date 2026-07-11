# AGENT.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

DO NOT send optional commentary.

用中文输出。

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

**编译和部署均可由 Agent 执行，集成测试仅在部署完成后执行。**

- **编译**：Agent 可自行执行（如 `./gradlew bootJar`、`flutter build web --no-wasm-dry-run`），验证代码可构建。
- **部署**：Agent 可自行执行（`./scripts/deploy.sh dev|test`，包含 rsync、docker compose build/up、镜像清理）。用户也可手动执行。
- **集成测试**：仅在部署完成后执行；不得在部署前提前运行（避免对旧版本/无后端状态做无效验证）。
- **顺序**：编码 → 编译验证 → 部署（Agent 或用户）→ 集成测试。

## 6. 代码实现通用规范

**所有新增或修改的代码实现，必须同时满足以下两条强制要求：**

### 6.1 国际化规范（i18n）

- 所有面向用户的文本（UI 标题、按钮、提示、错误信息、空状态文案等）必须通过国际化资源引用，禁止硬编码中文/英文字符串。
- Flutter 端：使用 `AppLocalizations`（`flutter gen-l10n` 生成的 `app_localizations.dart`），文案写入 `lib/l10n/app_*.arb`（中文 `app_zh.arb`、英文 `app_en.arb`），并通过 `context.l10n.xxx` 访问；新增 key 时中英文 arb 必须同步补齐，不得只写一种语言。
- 后端端（Spring Boot）：错误码、校验消息、业务提示等对外返回的文案应通过 `MessageSource`（`messages_zh.properties` / `messages_en.properties`）管理，按请求 `Accept-Language` 返回对应语言；新增消息 key 时两份 properties 同步维护。
- PC 端：遵循现有 i18n 方案（i18n pipe / service），不直接写入字面文案。
- 校验：新增/修改功能后，运行 `flutter gen-l10n` 确认无缺失 key，`flutter analyze` 不报未定义翻译引用；后端编译通过且 properties 双语对齐。
- 禁止：仅写中文文案而把英文留空或复制中文占位；禁止在 Dart/Java 源码中直接出现面向用户的字面量字符串。

### 6.2 种子数据规范（Seed Data）

- 当新增功能、表、枚举或业务规则导致现有种子数据不足以验证逻辑时，必须同步生成或修改种子数据，使新功能可直接通过种子账号/数据被验证。
- 后端：通过新增 Flyway 迁移（`V{n}__*.sql`）写入种子数据，遵循现有 seed 迁移风格（命名、列顺序、BCrypt hash 三步验证流程，见「Seed 密码流程」）；不得在 Java 代码中临时 `INSERT` 或硬编码演示数据。
- Flutter 端：种子数据由后端 Flyway 迁移统一管理，前端无需维护独立的 Mock 数据层。
- 逻辑合理：种子数据必须符合业务约束（外键引用真实存在、状态机合法、时间字段顺序合理、配额/订阅 tier 与功能门控匹配），不得构造自相矛盾或无法被正常流程读取的数据。
- 校验：种子数据写入后，至少通过编译 + 单元测试/脚本确认可被正确加载和查询；涉及登录凭据的，部署后用 `curl` 调用 `/auth/login` 验证。

## 项目概述

智慧畜牧系统（Smart Livestock）是面向牧场主的牲畜管理平台，通过 IoT 设备（GPS 追踪器、瘤胃胶囊、加速度计）实现定位、健康预警和行为分析。仓库包含两个子项目：

- **Mobile/** — Flutter 移动端（已移除 Mock 模式，通过 ApiClient 对接 Spring Boot 后端）
- **smart-livestock-server/** — Spring Boot 后端（Phase 1-2c + Phase 3 blade 对接已实施，DDD 洋葱架构）

Flutter 端已完成：订阅与功能门控、多牧场切换、B端管理后台、牧工管理、租户用户管理。Spring Boot 后端 Phase 1（Identity + Ranch + IoT）、Phase 2a（Commerce）、Phase 2b（Health）、Phase 2c（Analytics + Portal）、Phase 3（blade 设备对接）均已实施，前端通过 JWT 认证对接真实后端。

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

## PC 端（历史遗留，暂不维护）

Angular 独立组件前端，从 `frontend/src/assets/data/*.json` 静态文件加载数据，后端仅保留骨架。架构细节见 `backend-migration-database-design.md` 和 `backend-springboot-design.md`。

---

## 后端（smart-livestock-server/）

> Phase 1-3 已实施。限界上下文：Identity、Ranch、IoT、Commerce、Health、Analytics、Shared。具体文件/Controller/端点数请用 `find`/`rg` 实时统计，不在此维护。

### 后端服务部署方式

单台服务器（172.22.1.123，32 核 / 126GB 内存）运行两套完全隔离的 docker-compose stack：

| 环境 | 角色 | 端口段（nginx 入口） | compose 文件 | 项目名 | env 文件 |
|------|------|---------------------|-------------|--------|---------|
| **test**（测试环境） | 现有 stack，改名为 test | `18080` | `docker-compose.test.yml` | `smart-livestock-server` | `.env` |
| **dev**（开发环境） | 新建 stack | `19080` | `docker-compose.dev.yml` | `sl-dev` | `.env.dev` |

两套 stack 共享同一份 Dockerfile 和构建产物，各自独立的 PostgreSQL / Redis / RocketMQ / volume，互不干扰。设计文档：`docs/superpowers/specs/2026-07-01-dev-test-env-isolation-design.md`

### 一键部署（本地执行）

统一部署脚本 `scripts/deploy.sh`，接受环境参数：

```bash
cd smart-livestock-server
./scripts/deploy.sh dev    # 部署到 dev 环境（端口 19080）
./scripts/deploy.sh test   # 部署到 test 环境（端口 18080）
```

脚本内部流程：编译 bootJar → rsync 同步代码（排除 .git/.gradle/.env/.env.dev 等）→ 远程清理旧 JAR → docker compose build + up → docker image prune。

注意事项：
- `.env`（test）和 `.env.dev`（dev）在远程手动维护，不随 rsync 覆盖
- tile-worker 的 Dockerfile 需要联网下载 docker-ce-cli，若服务器无法访问 download.docker.com，dev stack 可复用 test 已构建的镜像（`docker tag smart-livestock-server-tile-worker:latest sl-dev-tile-worker:latest`）
- Flutter 连接环境通过运行参数切换，不改代码：`--dart-define=API_BASE_URL=http://172.22.1.123:19080/api/v1`（dev）或 `:18080`（test）

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

### Flyway 迁移命名规范

**新增 Flyway 迁移使用时间戳版本号**，格式 `V{YYYYMMDDHHmmss}__description.sql`，避免多对话并行创建时版本号冲突。

- V1-V41 已有迁移保持原样（整数版本号），不改名
- V20260701... 及以后的新迁移用时间戳格式（Flyway 按数字排序，时间戳天然大于 41）
- 安装 pre-commit hook 防止重复版本号：`cp smart-livestock-server/scripts/check-flyway-duplicates.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit`

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
| **Phase C blade 对接设计** | `docs/superpowers/specs/2026-07-07-phase-c-blade-device-integration.md` | **第三方平台集成（OAuth2 + Feign + 设备注册 + 遥测采集），已实施** |
| **Phase 3 实施设计** | `docs/superpowers/specs/2026-07-08-phase3-blade-integration-device-health-spec.md` | **设备健康管理 + blade 集成用户旅程 + datagen 适配 + 数据采集分流** |
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

- **Commerce**: Subscription、Contract、RevenuePeriod、SubscriptionService、FeatureGate（完整 DDD 洋葱架构）

#### Phase 2b — 已完成

- **Health**: 温度/蠕动/发情/疫情分析引擎 + 时序数据

#### Phase 2c — 已实施

- **Analytics + API Portal**: API Key 生命周期 + 开发者门户 + 频率限制 + 统计聚合 + 趋势分析

### 数据库迁移与表

| 迁移 | 表 | 限界上下文 |
|------|---|--------|
| V1 | tenants, farms, users, user_farm_assignments, api_keys | Identity |
| V2 | livestock, fences, alerts | Ranch |
| V3 | devices, device_licenses, installations, gps_logs | IoT |
| V6 | subscriptions, contracts, revenue_periods, subscription_services, feature_gates, notifications | Commerce |
| V13 | tile 相关表 + fence version | Ranch |
| V18 | audit_logs | Shared |
| V20-V21 | health 相关表 + seed | Health |
| V22-V23 | analytics/portal 表 + seed | Analytics |
| V26 | alert/notification model | Ranch |
| V38-V41 | datagen + AI anomaly | IoT/Health |
| V20260709... | Phase 3 device extension + seed | IoT |
| V20260710... | bugfix 迁移（时区/精度/数据清理） | 各上下文 |

> 以上为关键迁移摘要，非完整列表。

> 迁移命名规范：V1-V41 为整数版本号（历史遗留，不改名），V20260701... 及以后用时间戳格式。新增迁移参考 `scripts/check-flyway-duplicates.sh`。具体迁移列表请 `ls smart-livestock-server/src/main/resources/db/migration/`。

### 后端 Controller

| 分类 | Controller |
|------|-----------|
| App API | AuthController, MeController, TenantController, FarmController, B2bController, LivestockController, FenceController, AlertController, DashboardController, MapController, TileAppController, DeviceController, DeviceLicenseController, InstallationController, GpsLogController, HealthController, CommerceController, SubscriptionController |
| Admin API | TenantAdminController, FarmAdminController, UserAdminController, DashboardAdminController, AuditLogController, ApiKeyAdminController, TileAdminController, AdminSubscriptionController, AdminContractController, AdminFeatureGateController, AdminRevenueController, AdminServiceController, AnalyticsController |
| Open API | OpenLivestockController, OpenFenceController, OpenAlertController, OpenDeviceController, OpenDeviceRegisterController, OpenGpsController |

### 常用命令

```bash
cd smart-livestock-server
./gradlew compileJava              # 编译
./gradlew test                     # 全部测试
./gradlew test --tests "*.domain.model.*"  # 领域模型单元测试
./gradlew bootRun                  # 启动（需 PostgreSQL + Redis）
docker compose up -d               # 全栈启动（PostgreSQL + Redis + RocketMQ + App）
```

### 地图瓦片基础设施

- **tileserver-gl**: 自建瓦片服务，部署在 172.22.1.123:18080，提供 WGS-84 瓦片
- **MBTiles 离线**: 原生平台支持离线瓦片（`sample.mbtiles`，长沙 zoom 12-14）
- **SmartTileProvider**: 三级降级（tileserver-gl → MBTiles → 高德/OSM），健康检测自动切换
- **坐标转换**: WGS-84 ↔ GCJ-02（`coord_transform.dart`），高德降级时自动转换
- **部署指南**: `docs/guides/tileserver-deployment-guide.md`
- **服务器配置指南**: `docs/guides/server-setup-guide.md`

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
flutter run                            # 运行
flutter build web                          # 默认
./build_web.sh                             # 推荐（抑制 WASM dry-run 误报）

```

### 前端架构（Flutter）

- **状态管理**: flutter_riverpod，严格使用 ConsumerWidget，禁用 setState/ChangeNotifier
- **路由**: go_router，`AppRoute` 枚举为路径唯一来源，含认证守卫重定向
- **模块分层**: `features/{module}/domain/`（Repository 接口）→ `data/`（Api Repository 实现）→ `presentation/`（Riverpod Notifier Controller）
- **功能模块**: admin、ai_anomaly、alerts、api_authorization、auth、b2b_admin、contract_management、dashboard、devices、digestive、epidemic、estrus、farm_creation、farm_switcher、fence、fever_warning、highfi、livestock、mine、offline_fences、offline_livestock、offline_tiles、pages、ranch、revenue、stats、subscription、subscription_service_management、tenant、twin_overview、worker_management
- **地图**: flutter_map + SmartTileProvider（三级降级）+ MBTiles 离线 + WGS-84/GCJ-02 坐标转换
- **UI 语言**: 中文，变量名英文

### 订阅与功能门控

- `SubscriptionTier` 枚举: basic、standard、premium、enterprise（后端 Commerce Phase 2 已实现配额引擎）
- `FeatureGate` 基于 tier 控制功能可见性（后端 Commerce 实现）
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

**旅程链**：platform_admin → 创建 b2b_admin → b2b_admin 创建牧场 → 分配给 owner。牧场不由 owner 自行创建。详见 `docs/product/customer-journey.md`。

### 代码风格

- 文件: `snake_case.dart`，类: `UpperCamelCase`，私有辅助类: `_ClassName`
- 所有主要 UI 元素必须有 `Key('descriptive-id')` 用于测试
- 主题 token（AppColors/AppSpacing/AppTypography）而非硬编码数值
- Provider 命名: `{module}RepositoryProvider`、`{module}ControllerProvider`

---

## 版本路线图

> Flutter Demo 阶段已完成：订阅基础设施 + 功能门控、多牧场支持 + B端管理后台 + 牧场切换器 + 牧工管理。
> Spring Boot 后端 Phase 1-3 已实施，全部限界上下文落地。

| 阶段                     | 核心功能                                                                   | 限界上下文                         | 状态  |
| ---------------------- | ---------------------------------------------------------------------- | ----------------------------- | --- |
| **MVP Phase 1** — 核心底座 | 认证(JWT) + 租户/牧场 + 设备/牲畜 + 围栏/告警 + Dashboard/Map + GPS 模拟               | Identity + Ranch + IoT        | ✅ 已完成 |
| **MVP Phase 2a** — Commerce | 订阅计费 + 合同管理 + 分润对账 + Tier 配额引擎 + Licensed 服务 + FeatureGate             | Commerce                      | ✅ 已完成 |
| **MVP Phase 2b — Health | 温度/蠕动/发情/疫情分析引擎 + 时序数据 | Health | ✅ 已完成 |
| **MVP Phase 2c — 平台扩展 | API Key 生命周期 + 开发者门户 + 频率限制 + 统计聚合 + 趋势分析 | Analytics + API Portal | ✅ 已实施 |
| **Phase 3** — IoT 真实接入 | blade 平台对接（设备注册 + 遥测采集 + datagen 适配）、设备健康管理、AI 异常检测已落地，持续迭代中 | IoT 扩展 | 🔧 进行中 |

**后端现状**：限界上下文（Identity + Ranch + IoT + Commerce + Health + Analytics + Shared）全部实施。AuditLog 和 Auth refresh 已完整实现。具体文件/Controller/测试数请用 `find`/`rg` 实时统计，不在此维护。

**前端现状**：已移除 Mock 模式，全部通过 ApiClient 异步对接 Spring Boot 后端（JWT 认证）。订阅系统（4 个 tier + feature flag）、B端后台、租户管理（TenantDetailPage 含用户创建/启停）、健康模块（发热/消化/发情/疫病）、AI 异常检测、离线模块（离线围栏/离线牲畜/离线瓦片）。地图支持三级瓦片降级（tileserver-gl → MBTiles → 高德/OSM）。客户旅程文档：`docs/product/customer-journey.md`。

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

---

## 经验判据速查（每次会话生效）

> 完整五段式（现象/误判/根因/解决/判据）见 `docs/reference/lessons-learned.md`，遇下列症状先查编号再翻原文。

**环境 / 工具类**
1. Flutter/工具 UTF-8 解码失败，path 含 `._` → 先删 `._*`（AppleDouble 污染），别怀疑工具本身 — #1
2. 沙箱内 Flutter 任何命令崩（写不了 `~/.dart-tool`）→ `HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true`；`analyze` 加 `--no-pub`，`pub get` 需 `--offline` — #4
3. `/Volumes/DEV` 上任何工具读到不该读的文件 / git 报 `non-monotonic index` → 先 `find . -name '._*' | head` 扫描 AppleDouble 污染 — #2

**部署 / 前端类**
4. 前端入口/功能"缺失"，代码里 grep 到 key → 先 grep 容器内 `main.dart.js` 是否有对应 key，不一致则是 nginx 镜像未重建 — #6
5. 后端 API curl 正常但前端看不到变化 → 前端未重新构建部署（`build_web.sh` + `deploy.sh` 两步缺一不可）— #7

**后端 / 数据库类**
6. 接口返回空列表 → 先核代码 glob 与挂载路径一致，再进容器 `ls` 数据卷确认数据存在，不要在代码里继续改路径 — #3
7. `@Query` 查询返回空且无报错 → 检查 JPQL 参数名是否与保留字冲突（FROM/SELECT/WHERE 等）— #8
8. 第三方平台时间字段不带时区标识 → 直接用原始数值不做换算（`toInstant(ZoneOffset.UTC)`），不要猜对方时区；前端查询也不做 `toUtc()`，保持同一基准 — #17
9. 同步/采集数据量持续增长不收敛 → 检查时间解析是否 fallback 到 `now()`，导致 cursor 去重失效 — #10
10. 多数据源写入同一张表无法区分 → 必须有 `source` 来源标记字段 — #11
11. Flyway checksum mismatch → 先查 `flyway_schema_history` 记录再对比 git 文件，迁移必须提交到 git — #12
12. `numeric field overflow` → 根据错误信息 precision/scale 定位列，差值/累加列至少 DECIMAL(10,2) — #13
13. GPS 轨迹查询返回空（`gps_logs` 有数据）→ 先查 active installation 是否存在，再查时间格式是否被 URL 编码破坏 — #14

**代码审查 / 逻辑类**
14. 评审路由/分档/状态机逻辑 → 从 design 原文时态主语倒推，代入调用方参数逐步求值，不要从阈值数字联想 — #5
15. 修复一个功能后必须端到端走完整链路（安装→激活→解绑→刷新），不要只测一步就认为修好了 — #15
16. `farmGet`/`farmPost` 等调用返回 404 且 URL 中 farmId 与路径粘连 → suffix 缺前导 `/` — #16
---

## Agent 自主性与确认规则

**原则：分析清楚就动手，只在真正需要用户决策时才停下来问。**

### 直接执行，不问用户

- 可逆操作：文件移动/重命名、代码编辑、git add/commit/push
- 意图明确的请求：用户说了做什么就做什么，不要求二次确认方案
- 标准工作流步骤：编译 → 部署 → 验证 → 提交 → 推送，一气呵成
- 遗留文件处理：发现非本次产生的未提交改动，直接纳入提交，列出即可

### 才需要问用户

- 不可逆/破坏性操作：删数据、drop 表、`git reset --hard`、`rm -rf`
- 意图真的模糊：存在两种合理解读，选错代价大（如删除 vs 归档）
- 违反用户明确约束：如 test 环境部署需用户通知后才可执行
- Agent 自己解不了的阻塞：缺少凭据、权限不足、外部依赖不可用
