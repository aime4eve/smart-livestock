# 智慧畜牧系统（Smart Livestock）— 新成员入职指南

> 本文档由 `/understand` 自动生成于 2026-05-20，基于代码库知识图谱。

---

## 1. 项目概述

**智慧畜牧**是面向牧场主的牲畜管理平台，通过 IoT 设备（GPS 追踪器、瘤胃胶囊、加速度计）实现定位、健康预警与行为分析。

**核心语言：** Java 17、Dart、JavaScript/TypeScript、SQL、YAML、Markdown
**核心框架：** Spring Boot 3.3、Flutter（Riverpod + Go Router）、Express、Angular（归档）

**仓库结构：**

| 子项目 | 目录 | 状态 |
|--------|------|------|
| Spring Boot 后端 | `smart-livestock-server/` | 活跃开发（Phase 2 Commerce 实施中） |
| Flutter 移动端 | `Mobile/mobile_app/` | 活跃开发 |
| Node.js Mock API | `Mobile/backend/` | Demo 阶段使用 |
| Angular 前端 | `PC/` | 已归档，不再维护 |
| 设计文档 | `docs/` | 持续更新 |

---

## 2. 架构层

后端采用 **DDD 洋葱架构**，前端采用 **Riverpod 分层模式**。知识图谱识别出 10 个架构层：

### 后端（Spring Boot）

| 层 | 说明 | 关键文件 |
|----|------|----------|
| **领域层** (74 files) | 聚合根、值对象、领域事件、仓储接口 | `Contract.java`, `User.java`, `Tenant.java`, `Livestock.java`, `Fence.java`, `Alert.java`, `Subscription.java` |
| **应用层** (33 files) | 业务编排、DTO、Command | `AuthApplicationService.java`, `CreateFarmCommand.java`, `LoginCommand.java` |
| **基础设施层** (149 files) | Controller、JPA、Security、Flyway、测试 | `SecurityConfig.java`, `docker-compose.yml`, `Dockerfile`, Flyway V1-V3 迁移 |

四个限界上下文：
- **Identity** — 租户、用户、牧场、角色、API Key
- **Ranch** — 牲畜、围栏、告警、Dashboard、Map
- **IoT** — 设备、License、安装、GPS 日志
- **Commerce**（实施中）— 订阅、合同、分润、配额

### 前端（Flutter）

| 层 | 说明 | 关键文件 |
|----|------|----------|
| **展示层** (148 files) | 26 个功能模块的 UI 页面 | `app_router.dart`, `demo_shell.dart`, `app_route.dart` |
| **领域层** (29 files) | Repository 接口定义 | `alerts_repository.dart`, `fence_repository.dart` |
| **数据层** (86 files) | Mock/Live 双模式实现 | `api_cache.dart`, `demo_seed.dart` |
| **测试层** (60 files) | Widget/集成/角色权限测试 | 60 个测试文件 |

### Mock API（Node.js Express）

50 个文件，提供完整 API 模拟，包含认证、功能门控中间件、内存数据 Store。

### 文档层（130 files）

API 契约文档、DDD 设计规格、实施计划、评审报告。

---

## 3. 关键概念

### 后端核心模式

- **DDD 洋葱架构**：领域层（纯业务逻辑）→ 应用层（编排）→ 基础设施层（技术实现），依赖方向从外向内
- **聚合根**：`User`, `Tenant`, `Farm`, `Livestock`, `Fence`, `Alert`, `Device`, `Subscription`, `Contract` — 每个聚合根管理自己的领域事件和不变量
- **事件驱动**：GPS 越界 → `FenceBreachDetector` → `GpsLogEventHandler` → 自动告警
- **三端 API 隔离**：App API（64 端点）、Admin API（30 端点）、Open API（17 端点）

### 前端核心模式

- **Mock/Live 双模式**：`--dart-define=APP_MODE=mock|live` 切换数据源
- **Riverpod 状态管理**：每个功能模块包含 domain（Repository 接口）→ data（Mock + Live 实现）→ presentation（Controller + Page）
- **三级瓦片降级**：tileserver-gl → MBTiles 离线 → 高德/OSM
- **WGS-84 ↔ GCJ-02 坐标转换**：高德降级时自动转换

### 多租户隔离

- **Farm Scope 硬约束**：所有牧场数据接口通过 `activeFarmTenantId` 过滤
- **5 种角色**：owner（牧场主）、worker（牧工）、platform_admin（平台管理员）、b2b_admin（B端客户管理员）、api_consumer（API 开发者）

---

## 4. 导览路线

建议按以下顺序了解代码库：

### Step 1: 项目全景
阅读 `CLAUDE.md`，了解项目全貌和当前工作重点。

### Step 2: 双端应用入口
- **后端入口**：`SmartLivestockApplication.java` — Spring Boot 启动类
- **前端入口**：`Mobile/mobile_app/lib/main.dart` — Flutter 应用入口

### Step 3: 共享内核
理解 DDD 基础设施：`AggregateRoot`、`DomainEvent`、`ErrorCode`。

### Step 4: 安全认证
`SecurityConfig` → `JwtAuthenticationFilter` → `JwtTokenProvider` 的认证链。

### Step 5: 数据库迁移
Flyway V1-V3 迁移脚本，理解 12 张表的 Schema 设计。

### Step 6: 领域模型
核心聚合根：`User`、`Tenant`、`Livestock`、`Fence`、`Alert`。

### Step 7: GPS 越界告警流
核心业务流程：`FenceBreachDetector` → `GpsLogEventHandler` → `AlertApplicationService`。

### Step 8: REST 接口层
27 个 Controller 的三端隔离架构，API 契约文档。

### Step 9: Flutter 路由体系
`app_router.dart` 的路由树、认证守卫和角色重定向。

### Step 10: 地图瓦片
`SmartTileProvider` 三级降级 + MBTiles 离线 + 坐标转换。

### Step 11: Commerce 限界上下文
Phase 2 新增：`Subscription`、`Contract`、`RevenuePeriod`、`SubscriptionService`。

### Step 12: 容器化部署
`docker-compose.yml` 全栈编排：PostgreSQL + Redis + RocketMQ + Spring Boot + tileserver-gl。

---

## 5. 快速开始

### 后端

```bash
cd smart-livestock-server
docker compose up -d          # PostgreSQL + Redis + RocketMQ + App
./gradlew test                # 运行测试
```

**种子数据登录：**
- owner：`13800138000` / `password123`
- platform_admin：`13800000000` / `password123`

### 前端

```bash
cd Mobile
./dev.sh start                # Mock 模式
./dev.sh start live           # Live 模式（连 Mock Server 3001）
```

### 前端连接真实后端

```bash
cd Mobile/mobile_app
flutter run -d chrome --dart-define=APP_MODE=live --dart-define=API_BASE_URL=http://172.22.1.123:18080/api/v1
```

---

## 6. 复杂度热点

以下区域逻辑较复杂，建议在有上下文后再深入：

| 文件/区域 | 说明 |
|-----------|------|
| MVP 后端设计规格 (`docs/superpowers/specs/2026-05-06-mvp-backend-design.md`) | DDD 六限界上下文、11 表 Schema、API 总览 |
| API 契约总览 (`docs/api-contracts/api-overview.md`) | 三端隔离、111 端点完整定义 |
| `docker-compose.yml` | 全栈 5 服务编排 |
| `app_router.dart` | 39 条路由 + 认证守卫 |
| `demo_shell.dart` | 角色动态导航 + 牧场切换器 |
| `api_cache.dart` | Live/Mock 数据规范化 + 预加载 |
| 围栏 CRUD 计划 | 12 个 Task 的完整重构方案 |
| 统一商业模型 Phase 1/2a/2b | 26 + 20 + Task 大规模基础设施改造 |

---

## 7. 关键设计文档索引

| 文档 | 位置 |
|------|------|
| MVP 后端设计规格 | `docs/superpowers/specs/2026-05-06-mvp-backend-design.md` |
| API 契约总览 | `docs/api-contracts/api-overview.md` |
| App API（64 端点） | `docs/api-contracts/app-api.md` |
| Admin API（30 端点） | `docs/api-contracts/admin-api.md` |
| Open API（17 端点） | `docs/api-contracts/open-api.md` |
| Commerce 设计规格 | `docs/superpowers/specs/2026-05-18-commerce-context-design.md` |
| 前端适配计划 | `docs/superpowers/plans/2026-05-12-flutter-frontend-adaptation.md` |
| 租户入驻设计 | `docs/superpowers/specs/2026-05-13-tenant-onboarding-design.md` |

---

*本指南基于 940 个源文件的知识图谱自动生成，涵盖 1,408 个节点和 1,639 条关系边。*
