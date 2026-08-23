# 项目概述与参考

> 本文件从 AGENTS.md 拆分而来，按需引用，不随会话全量加载。

## 仓库结构

智慧畜牧系统（Smart Livestock）是面向牧场主的牲畜管理平台，通过 IoT 设备（GPS 追踪器、瘤胃胶囊、加速度计）实现定位、健康预警和行为分析。

- **Mobile/mobile_app/** — Flutter Web/App（通过 ApiClient 对接 Spring Boot 后端）
- **smart-livestock-server/** — Spring Boot 后端（Phase 1-2c + Phase 3 blade 对接已实施，DDD 洋葱架构）
- **PC/** — Angular 历史遗留前端，暂不维护（架构细节见 `backend-migration-database-design.md`、`backend-springboot-design.md`）

**工作重点**：后端在 `smart-livestock-server/`，前端在 `Mobile/mobile_app/`，PC/ 暂不维护。

## GitHub 仓库

- 仓库：https://github.com/aime4eve/smart-livestock
- 默认分支：`master`，协议 HTTPS（已配置 gh credential helper）
- GitHub CLI `gh` 已认证（账号 `aime4eve`）

## 角色旅程链

```
platform_admin → 创建租户 → 进入租户详情 → 新增用户（b2b_admin / owner / worker）
b2b_admin → 创建牧场 → 分配给 owner
owner → 管理牲畜、围栏、告警、牧工
```

牧场不由 owner 自行创建，由 b2b_admin 或 platform_admin 创建并分配。详见 `docs/product/customer-journey.md`。

## 后端技术栈

Spring Boot 3.3 + Java 17 + Gradle + PostgreSQL 16 + Redis 7 + RocketMQ 5.1 + Flyway + JPA/Hibernate + Spring Security + JWT + Lombok + JUnit 5 + Testcontainers

## 限界上下文

| Phase | 上下文 | 内容 | 状态 |
|-------|--------|------|------|
| Phase 1 | Identity | Tenant、User、Farm、Role、ApiKey（JWT + 多租户隔离 + 5 角色） | ✅ |
| Phase 1 | Ranch | Livestock、Fence、Alert、Dashboard、Map（围栏越界 → 自动告警） | ✅ |
| Phase 1 | IoT | Device、DeviceLicense、Installation、GpsLog | ✅ |
| Phase 1 | Shared | SecurityConfig、JwtAuthenticationFilter、TenantScope、AuditLog | ✅ |
| Phase 2a | Commerce | Subscription、Contract、RevenuePeriod、SubscriptionService、FeatureGate | ✅ |
| Phase 2b | Health | 温度/蠕动/发情/疫情分析引擎 + 时序数据 | ✅ |
| Phase 2c | Analytics | API Key 生命周期 + 开发者门户 + 频率限制 + 统计聚合 + 趋势分析 | ✅ |
| Phase 3 | IoT 扩展 | blade 平台对接（设备注册 + 遥测采集 + datagen 适配）、设备健康管理 | 🔧 |
| AI/datagen | datagen + ai-platform | 合成数据控制台、GroundTruth、L1 异常检测、评估与前端异常展示 | ✅ |

## 数据库迁移摘要

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
| V20260817-18... | datagen 控制台与可配置仿真规则 | datagen |
| V20260822...100000 | 时序分区自动维护与查询索引 | Platform/IoT/Ranch |
| V20260822200000 | GPS ingestion outbox | IoT |
| V20260822210000 | GPS outbox source 约束 | IoT |
| V20260823100000 | Phase C 行为 feature/window/label/prediction 存储 | datagen |

> 关键迁移摘要，非完整列表。完整列表：`ls smart-livestock-server/src/main/resources/db/migration/`

## 后端 Controller

| 分类 | Controller |
|------|-----------|
| App API | Auth、Me、Tenant、Farm、B2b、Livestock、Fence、Alert、Dashboard、Map、Tile、Device、Installation、Telemetry、GpsLog、Health、Commerce 等 |
| Admin API | Tenant、Farm、User、Dashboard、AuditLog、ApiKey、Tile、Subscription、Contract、FeatureGate、Revenue、Service、Analytics、GPS Quality、Telemetry Import、DataGen 等 |
| Open API | Livestock、Fence、Alert、Device、DeviceRegister、Gps 等 |

> Controller/endpoint 的完整事实源是 `smart-livestock-server/src/main/java/` 与 `docs/api-contracts/`；上表只保留当前分类入口。

## 地图瓦片基础设施

- **tileserver-gl**: 自建瓦片服务，提供 WGS-84 瓦片
- **MBTiles 离线**: 原生平台支持离线瓦片（`sample.mbtiles`，长沙 zoom 12-14）
- **SmartTileProvider**: 三级降级（tileserver-gl → MBTiles → 高德/OSM），健康检测自动切换
- **坐标转换**: WGS-84 ↔ GCJ-02（`coord_transform.dart`），高德降级时自动转换
- **部署指南**: `docs/guides/tileserver-deployment-guide.md`
- **服务器配置**: `docs/guides/server-setup-guide.md`

## 设计文档索引

| 文档 | 位置 | 说明 |
|------|------|------|
| MVP 后端设计 | `docs/superpowers/specs/2026-05-06-mvp-backend-design.md` | DDD 限界上下文、DB Schema、洋葱架构、API 总览 |
| Phase 1 计划 | `docs/superpowers/plans/2026-05-06-mvp-phase1-implementation.md` | 16 个 Task，TDD 流程 |
| 租户入驻 | `docs/superpowers/specs/2026-05-13-tenant-onboarding-design.md` | TenantPhase + Farm 创建向导 |
| 多区域地图瓦片 | `docs/superpowers/specs/2026-05-15-multi-region-map-tiles-design.md` | tileserver-gl + SmartTileProvider 三级降级 |
| Commerce 设计 | `docs/superpowers/specs/2026-05-18-commerce-context-design.md` | 订阅/合同/分润/配额引擎 |
| Health 设计 | `docs/superpowers/specs/2026-05-31-health-context-design.md` | 温度/蠕动/发情/疫病分析引擎 |
| Phase C blade 对接 | `docs/superpowers/specs/2026-07-07-phase-c-blade-device-integration.md` | OAuth2 + Feign + 设备注册 + 遥测采集 |
| Phase 3 设计 | `docs/superpowers/specs/2026-07-08-phase3-blade-integration-device-health-spec.md` | 设备健康管理 + blade 集成 + datagen 适配 |
| blade 环境映射 | `docs/superpowers/specs/2026-07-21-blade-env-mapping-design.md` | dev/test ↔ blade dev/test 环境对应 |
| AI 路线图 | `docs/superpowers/specs/2026-06-19-ai-health-roadmap.md` | AI/datagen 双轨演进 |
| datagen 控制台 | `docs/superpowers/specs/2026-08-17-datagen-admin-console-design.md` | 仿真启停、设备范围、清理和审计 |
| datagen 规则 | `docs/superpowers/specs/2026-08-18-datagen-configurable-rules-design.md` | 按牧场配置仿真频率和异常概率 |
| datagen v2 / Phase C | `docs/superpowers/specs/2026-08-22-datagen-v2-behavior-and-phase-c-design.md` | 行为波形、窗口特征、多标签评估与真实数据适配 |
| GPS RTK 浏览优化 | `docs/superpowers/specs/2026-08-20-gps-quality-rtk-truth-points-browse-design.md` | RTK 真值点搜索、分组、排序 |
| Analytics+Portal | `docs/superpowers/specs/2026-05-31-analytics-portal-context-design.md` | API Key 自管理 + 频率限制 + 统计聚合 |
| API 契约总览 | `docs/api-contracts/api-overview.md` | 三端隔离、通用约定、Farm Scope |
| App API | `docs/api-contracts/app-api.md` | `/api/v1/` 端点 |
| Admin API | `docs/api-contracts/admin-api.md` | `/api/v1/admin/` 端点 |
| Open API | `docs/api-contracts/open-api.md` | `/api/v1/open/` 端点 |

## 版本路线图

| 阶段 | 核心功能 | 状态 |
|------|---------|------|
| MVP Phase 1 — 核心底座 | 认证(JWT) + 租户/牧场 + 设备/牲畜 + 围栏/告警 + Dashboard/Map + GPS | ✅ |
| MVP Phase 2a — Commerce | 订阅计费 + 合同管理 + 分润对账 + Tier 配额引擎 + Licensed 服务 + FeatureGate | ✅ |
| MVP Phase 2b — Health | 温度/蠕动/发情/疫情分析引擎 + 时序数据 | ✅ |
| MVP Phase 2c — 平台扩展 | API Key 生命周期 + 开发者门户 + 频率限制 + 统计聚合 + 趋势分析 | ✅ |
| Phase 3 — IoT 真实接入 | blade 平台对接、设备健康管理、AI 异常检测，持续迭代中 | 🔧 |
| AI/datagen 轨道 | Phase A/B 与 datagen v1 已闭环；Phase C C0-C5 仿真行为管道已 dev 验证，C6-C10 与真实数据效果验证继续推进 | 🔧 |
| 生产化 | 分区维护、索引加固、GPS outbox 已落地；test 验证与真实遥测扩量继续推进 | 🔧 |

## 前端角色与 Shell

| 角色 | 可见范围 | Shell 类型 |
|------|---------|-----------|
| owner（牧场主） | 全部页面 + 后台管理 + 牧工管理 + 订阅管理 | 底部导航栏（4-5 Tab） |
| worker（牧工） | 看板/地图/告警/我的/围栏，仅确认告警 | 底部导航栏（4 Tab） |
| platform_admin | 租户全量管理 + 用户管理 + 合同 CRUD + 分润对账 + 订阅服务管理 + API 授权审批 | 无 Shell，纯 Scaffold |
| b2b_admin | 概览/牧场管理/合同信息/对账/旗下牧工管理 | 左侧 NavigationRail |
| api_consumer | 仅 API 访问，无 App 端 | — |

## 订阅与功能门控

- `SubscriptionTier` 枚举: basic、standard、premium、enterprise（后端 Commerce 配额引擎）
- `FeatureGate` 基于 tier 控制功能可见性
- `ApiCache` 预加载时按 tier 范围过滤数据
- 锁定功能显示升级提示覆盖层
