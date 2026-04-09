# 智慧畜牧（Smart Livestock）

面向牧场主的牲畜管理平台：通过 IoT 设备（GPS 追踪器、瘤胃胶囊、加速度计等）实现定位、健康预警与行为分析。本仓库包含 **PC 端**与 **Mobile 端**两个彼此独立、不共享依赖的子项目。

**仓库：** [github.com/aime4eve/smart-livestock](https://github.com/aime4eve/smart-livestock) · 默认分支 `master`

---

## 当前维护重点

**活跃开发在 `Mobile/`。** `PC/` 为历史 Angular 前端与规划中的后端，当前不随主流程迭代；协作约定见 [`AGENTS.md`](./AGENTS.md) 与 [`CLAUDE.md`](./CLAUDE.md)。

---

## Mobile 端（Flutter + Mock API）

高保真 Demo 向 MVP 过渡：Flutter 使用 **本地 Mock 种子**（默认）或 **Node.js Mock Server**（Live 模式）拉取与内存种子对齐的数据；尚无生产级后端。

| 目录 | 说明 |
|------|------|
| [`Mobile/mobile_app/`](./Mobile/mobile_app/) | Flutter 应用（`flutter_riverpod` + `go_router`） |
| [`Mobile/backend/`](./Mobile/backend/) | Express Mock API，默认 **3001**，内存数据、统一 JSON 包络 `{ code, message, requestId, data }` |

### Demo 数据规模（Mock 与 Live 对齐）

- 牲畜约 **50** 头，耳标 `SL-2024-001`～`050`，数字孪生 ID `0001`～`0050`
- 围栏 **4** 个（放牧 A/B、休息区、隔离区）
- 告警 **18** 条（与看板/告警模块一致）
- 看板指标、孪生体温/消化/发情等见 `demo_seed.dart` 与 `backend/data/seed.js`
- Live 模式下地图轨迹由 `GET /api/map/trajectories` 按 `range=24h|7d|30d` **动态生成**；`ApiCache` 默认请求 `API_BASE_URL`（未设置时为 `http://localhost:3001/api`）

### 环境要求

- [Flutter SDK](https://docs.flutter.dev/get-started/install)（`pubspec.yaml`：`sdk >=3.3.0 <4.0.0`）
- [Node.js](https://nodejs.org/)（Mock Server）

### 快速开始

**方式一：一键脚本（在 `Mobile/` 目录）**

```bash
cd Mobile
./dev.sh start          # Mock Server + Flutter（Mock 数据）
./dev.sh start live     # Mock Server + Flutter（Live，连 3001）
./dev.sh stop
./dev.sh status
```

**方式二：手动**

```bash
cd Mobile/backend && npm install && node server.js

cd Mobile/mobile_app
flutter pub get
flutter run                              # 默认 APP_MODE=mock
flutter run --dart-define=APP_MODE=live  # 连接 Mock Server
```

常用校验：

```bash
cd Mobile/mobile_app
flutter analyze
flutter test
```

架构与模块说明见 [`Mobile/AGENTS.md`](./Mobile/AGENTS.md)。

---

## PC 端（Angular，归档说明）

| 目录 | 说明 |
|------|------|
| [`PC/frontend/`](./PC/frontend/) | Angular 19 独立组件 + 静态 JSON 数据 |
| `PC/` 后端 | Spring Boot 仍为骨架，前端未实际调用 API |

本地运行历史前端见 [`CLAUDE.md`](./CLAUDE.md) 中 PC 端命令。

---

## 版本方向（摘要）

| 阶段 | 内容 |
|------|------|
| Demo（当前 Mobile） | 高保真 UI、Mock Server、数智孪生等演示能力 |
| MVP 1.0 | GPS、电子围栏、基础告警、租户管理 |
| 后续 | 瘤胃监测、健康评分、行为与发情检测等（见 [`CLAUDE.md`](./CLAUDE.md)） |

---

## 文档索引

| 文档 | 说明 |
|------|------|
| [`AGENTS.md`](./AGENTS.md) | 协作与代码约束（全仓库） |
| [`CLAUDE.md`](./CLAUDE.md) | 项目上下文、命令与路线图 |
| [`Mobile/AGENTS.md`](./Mobile/AGENTS.md) | Flutter 模块、测试与风格 |
| [`Mobile/docs/superpowers/specs/2026-04-09-demo-data-enhancement-design.md`](./Mobile/docs/superpowers/specs/2026-04-09-demo-data-enhancement-design.md) | Demo 数据增强设计（草案） |
| [`Mobile/docs/superpowers/plans/2026-04-09-demo-data-enhancement.md`](./Mobile/docs/superpowers/plans/2026-04-09-demo-data-enhancement.md) | 实施计划（任务清单） |
