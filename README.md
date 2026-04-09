# 智慧畜牧（Smart Livestock）

面向牧场主的牲畜管理平台：通过 IoT 设备（GPS 追踪器、瘤胃胶囊、加速度计等）实现定位、健康预警与行为分析。本仓库包含 **PC 端**与 **Mobile 端**两个彼此独立、不共享依赖的子项目。

**仓库地址：** [github.com/aime4eve/smart-livestock](https://github.com/aime4eve/smart-livestock) · 默认分支 `master`

---

## 当前维护重点

**活跃开发在 `Mobile/`。** `PC/` 为历史 Angular 前端与规划中的后端，当前不随主流程迭代；详细约定见仓库根目录 [`AGENTS.md`](./AGENTS.md) 与 [`CLAUDE.md`](./CLAUDE.md)。

---

## Mobile 端（Flutter + Mock API）

高保真 Demo 向 MVP 过渡阶段：Flutter 应用可在 **本地 Mock 数据**（默认）或 **Node.js Mock Server**（Live 模式）下运行，尚无生产级后端。

| 目录 | 说明 |
|------|------|
| [`Mobile/mobile_app/`](./Mobile/mobile_app/) | Flutter 应用（`flutter_riverpod` + `go_router`） |
| [`Mobile/backend/`](./Mobile/backend/) | Express Mock API，默认端口 **3001**，内存数据、统一 JSON 包络 |

### 环境要求

- [Flutter SDK](https://docs.flutter.dev/get-started/install)（`pubspec.yaml` 要求 Dart SDK `>=3.3.0 <4.0.0`）
- [Node.js](https://nodejs.org/)（用于 Mock Server）

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
# Mock Server
cd Mobile/backend
npm install
node server.js

# 另开终端：Flutter（在 mobile_app 目录）
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

开发与架构说明见 [`Mobile/AGENTS.md`](./Mobile/AGENTS.md)。

---

## PC 端（Angular，归档说明）

| 目录 | 说明 |
|------|------|
| [`PC/frontend/`](./PC/frontend/) | Angular 19 独立组件 + 静态 JSON 数据 |
| `PC/` 后端 | Spring Boot 仍为骨架，前端未实际调用 API |

如需本地运行历史前端，可参考 [`CLAUDE.md`](./CLAUDE.md) 中 PC 端命令（`npm run install:all`、`npm start` 等）。

---

## 版本方向（摘要）

| 阶段 | 内容 |
|------|------|
| Demo（当前 Mobile） | 高保真 UI、Mock Server、数智孪生等演示能力 |
| MVP 1.0 | GPS、电子围栏、基础告警、租户管理 |
| 后续 | 瘤胃监测、健康评分、行为与发情检测等（见 [`CLAUDE.md`](./CLAUDE.md) 路线图） |

---

## 文档索引

- [`AGENTS.md`](./AGENTS.md) — 协作与代码约束（全仓库）
- [`CLAUDE.md`](./CLAUDE.md) — 项目上下文、PC/Mobile 命令与路线图
- [`Mobile/AGENTS.md`](./Mobile/AGENTS.md) — Flutter 模块结构、测试与风格
