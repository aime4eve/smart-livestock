# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

智慧畜牧系统（Smart Livestock）是面向牧场主的牲畜管理平台，通过 IoT 设备（GPS 追踪器、瘤胃胶囊、加速度计）实现定位、健康预警和行为分析。仓库包含两个独立子项目：

- **PC/** — Angular 19 前端 + 规划中的 Spring Boot 后端（数据库设计阶段，当前从静态 JSON 加载数据）
- **Mobile/** — Flutter 移动端 + Node.js Mock API Server

两个子项目各自独立开发，不共享代码或依赖。

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

# 一键启动（Mobile 根目录）
cd Mobile && ./dev.sh start [mock|live]
./dev.sh stop
./dev.sh status
```

### 前端架构（Flutter）

- **状态管理**: flutter_riverpod，严格使用 ConsumerWidget，禁用 setState/ChangeNotifier
- **路由**: go_router，`AppRoute` 枚举为路径唯一来源，含认证守卫重定向
- **模式切换**: `--dart-define=APP_MODE=mock|live`，mock 用本地假数据，live 通过 ApiCache 调 Mock Server
- **模块分层**: `features/{module}/domain/`（Repository 接口）→ `data/`（mock + live 实现）→ `presentation/`（Riverpod Notifier Controller）
- **UI 语言**: 中文，变量名英文

### Mock Server 架构

- **端口**: 3001，纯内存无持久化
- **认证**: 固定 token `mock-token-{role}`（owner/worker/ops 三角色）
- **响应格式**: 统一 `{ code, message, requestId, data }` 包络，列表接口 `{ items, page, pageSize, total }`
- **告警状态机**: pending → acknowledged → handled → archived，非法跳转返回 409
- **API 路由**: auth、me、dashboard、map、alerts、fences、tenants、profile、twin（数智孪生）
- **数据种子**: `backend/data/seed.js` 与 Flutter 端 `demo_seed.dart` 保持对齐

### 角色与权限

| 角色 | 可见范围 |
|------|---------|
| owner（牧场主） | 全部页面 + 后台管理 |
| worker（牧工） | 看板/地图/告警/我的/围栏，仅确认告警 |
| ops（运维） | 仅租户管理后台，无底部导航 |

### 代码风格

- 文件: `snake_case.dart`，类: `UpperCamelCase`，私有辅助类: `_ClassName`
- 所有主要 UI 元素必须有 `Key('descriptive-id')` 用于测试
- 主题 token（AppColors/AppSpacing/AppTypography）而非硬编码数值
- Provider 命名: `{module}RepositoryProvider`、`{module}ControllerProvider`

---

## 版本路线图

| 阶段 | 核心功能 |
|------|---------|
| Demo（当前 Mobile） | 高保真 UI + Mock Server，数智孪生四场景 |
| MVP V1.0 | GPS 定位 + 电子围栏 + 基础告警 + 租户管理 |
| V1.5 | 瘤胃温度/蠕动监测 + 健康评分 |
| V2.0 | 步态分析 + 行为统计 + 发情检测 |
