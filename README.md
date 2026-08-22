# 智慧畜牧（Smart Livestock）

面向牧场主的牲畜管理平台：通过 IoT 设备（GPS 追踪器、瘤胃胶囊、加速度计等）实现定位、健康预警与行为分析。当前主线由 **Flutter 移动端** 与 **Spring Boot 后端**组成，PC 端仅保留历史归档。

**仓库：** [github.com/aime4eve/smart-livestock](https://github.com/aime4eve/smart-livestock) · 默认分支 `master`

---

## 当前状态与维护重点

**活跃开发在 `Mobile/mobile_app/` 与 `smart-livestock-server/`。**

- 后端：MVP Phase 1-2c 已完成；Phase 3 blade 对接、设备健康管理、GPS 质量运营持续迭代中。
- AI/datagen：Phase A/B 与 datagen v1 已在合成数据链路闭环，下一步是真实遥测验证与 datagen v2。
- 可靠性：时序分区自动维护与 GPS outbox 解耦已落地；真实遥测扩量前继续推进生产化加固。
- `PC/` 为历史 Angular 前端，不随主流程迭代。

---

## 当前工程结构

| 目录 | 说明 |
|------|------|
| [`Mobile/mobile_app/`](./Mobile/mobile_app/) | Flutter Web/App，通过 `ApiClient` 对接 Spring Boot API |
| [`smart-livestock-server/`](./smart-livestock-server/) | Spring Boot 3.3 + Java 17 + PostgreSQL/Flyway + Redis/RocketMQ，DDD 洋葱架构 |
| [`docs/`](./docs/) | 部署、架构、spec/plan、API 契约、测试与经验文档 |
| [`PC/`](./PC/) | 历史 Angular 前端，归档不维护 |

### 常用验证

```bash
cd smart-livestock-server && ./gradlew compileJava

cd Mobile/mobile_app
HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze
HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter test
```

目标测试示例：`./gradlew test --tests 'com.smartlivestock.iot.*'`。当前全量后端测试存在 19 个既有失败（14 个 Testcontainers Docker 环境初始化 + 5 个 `AlertReadStatusTest` mock 债务），不要误判为新回归。

部署以后端目录脚本为准：`cd smart-livestock-server && ./scripts/deploy.sh dev`。dev 可由 Agent 执行；test 环境必须等用户通知后再执行。部署后检查 `/health`。

架构与模块说明见 [`Mobile/AGENTS.md`](./Mobile/AGENTS.md)。

---

## 版本方向（摘要）

| 阶段 | 内容 |
|------|------|
| MVP Phase 1-2c | 认证/租户/牧场/设备/围栏/告警/地图、Commerce、Health、Analytics 已完成 |
| Phase 3 | blade 真实设备接入、设备健康管理、GPS 质量运营持续迭代中 |
| AI 双轨 | Phase A/B 与 datagen v1 已形成合成数据闭环；下一步是真实遥测验证与 datagen v2 / Phase C |
| 生产化 | 分区自动维护、索引加固、GPS outbox 已落地；真实遥测扩量前持续加固 |

详细路线图见 [`docs/reference/project-overview.md`](./docs/reference/project-overview.md) 与 [`docs/superpowers/specs/2026-06-19-ai-health-roadmap.md`](./docs/superpowers/specs/2026-06-19-ai-health-roadmap.md)。

---

## 文档索引

| 文档 | 说明 |
|------|------|
| [`AGENTS.md`](./AGENTS.md) | 协作与代码约束（全仓库） |
| [`docs/reference/project-overview.md`](./docs/reference/project-overview.md) | 项目概述、上下文、路线图 |
| [`docs/reference/deployment.md`](./docs/reference/deployment.md) | 部署、分区、GPS outbox、环境与验证 |
| [`docs/superpowers/specs/2026-06-19-ai-health-roadmap.md`](./docs/superpowers/specs/2026-06-19-ai-health-roadmap.md) | AI/datagen 双轨路线图 |
| [`docs/api-contracts/api-overview.md`](./docs/api-contracts/api-overview.md) | API 契约入口 |
| [`Mobile/AGENTS.md`](./Mobile/AGENTS.md) | Flutter 模块、测试与风格 |

`docs/features/*` 与 `Mobile/docs/*` 中的功能清单是历史快照，不作为当前完成状态的事实来源；以代码、Flyway、测试记录和 `docs/reference/*` 为准。
