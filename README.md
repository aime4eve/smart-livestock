# 智慧畜牧（Smart Livestock）

面向牧场主的牲畜管理平台：通过 IoT 设备（GPS 追踪器、瘤胃胶囊、加速度计等）实现定位、健康预警与行为分析。当前主线由 **Flutter 移动端** 与 **Spring Boot 后端**组成，PC 端仅保留历史归档。

**仓库：** [github.com/aime4eve/smart-livestock](https://github.com/aime4eve/smart-livestock) · 默认分支 `master`

---

## 当前维护重点

**活跃开发在 `Mobile/mobile_app/` 与 `smart-livestock-server/`。** 后端已覆盖 MVP Phase 1-2c 与 Phase 3 blade 对接、设备健康管理、GPS 质量检验和 datagen；`PC/` 为历史 Angular 前端，不随主流程迭代。

---

## 当前工程结构

| 目录 | 说明 |
|------|------|
| [`Mobile/mobile_app/`](./Mobile/mobile_app/) | Flutter Web/App，通过 `ApiClient` 对接 Spring Boot API |
| [`smart-livestock-server/`](./smart-livestock-server/) | Spring Boot 3.3 + Java 17 + PostgreSQL/Flyway + Redis/RocketMQ，DDD 洋葱架构 |
| [`PC/`](./PC/) | 历史 Angular 前端，归档不维护 |

### 常用验证

```bash
cd smart-livestock-server && ./gradlew compileJava

cd Mobile/mobile_app
HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze
HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter test
```

部署仍以后端目录脚本为准：`cd smart-livestock-server && ./scripts/deploy.sh dev|test`。环境细节见 [`docs/reference/deployment.md`](./docs/reference/deployment.md)。

架构与模块说明见 [`Mobile/AGENTS.md`](./Mobile/AGENTS.md)。

---

## 版本方向（摘要）

| 阶段 | 内容 |
|------|------|
| MVP Phase 1-2c | 认证/租户/牧场/设备/围栏/告警/地图、Commerce、Health、Analytics 已完成 |
| Phase 3 | blade 真实设备接入、设备健康管理、GPS 质量运营持续迭代中 |
| AI 双轨 | Phase A/B 与 datagen v1 已形成合成数据闭环；下一步是真实遥测验证与 datagen v2 / Phase C |

详细路线图见 [`docs/reference/project-overview.md`](./docs/reference/project-overview.md) 与 [`docs/superpowers/specs/2026-06-19-ai-health-roadmap.md`](./docs/superpowers/specs/2026-06-19-ai-health-roadmap.md)。

---

## 文档索引

| 文档 | 说明 |
|------|------|
| [`AGENTS.md`](./AGENTS.md) | 协作与代码约束（全仓库） |
| [`CLAUDE.md`](./CLAUDE.md) | 项目上下文、命令与路线图 |
| [`Mobile/AGENTS.md`](./Mobile/AGENTS.md) | Flutter 模块、测试与风格 |
| [`Mobile/docs/superpowers/specs/2026-04-09-demo-data-enhancement-design.md`](./Mobile/docs/superpowers/specs/2026-04-09-demo-data-enhancement-design.md) | Demo 数据增强设计（草案） |
| [`Mobile/docs/superpowers/plans/2026-04-09-demo-data-enhancement.md`](./Mobile/docs/superpowers/plans/2026-04-09-demo-data-enhancement.md) | 实施计划（任务清单） |
