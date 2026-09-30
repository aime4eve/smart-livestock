# 智慧畜牧（Smart Livestock）

面向牧场主的牲畜管理平台：通过 IoT 设备（GPS 追踪器、瘤胃胶囊、加速度计等）实现定位、健康预警与行为分析。当前主线由 **Flutter 移动端** 与 **Spring Boot 后端**组成，PC 端仅保留历史归档。

**仓库：** [github.com/aime4eve/smart-livestock](https://github.com/aime4eve/smart-livestock) · 默认分支 `master` · 应用标识 `hkt-livestock-agentic`

---

## 当前状态与维护重点（截至 2026-09-28）

**活跃开发在 `Mobile/mobile_app/` 与 `smart-livestock-server/`。**

- **Phase 3 / IoT**：blade 对接与设备健康管理持续迭代；2026-09 落地牲畜信号同步链路（信号投影 API + 事务性信号事件 outbox + SSE 推送 + 统一同步 UI，围栏统计切换到信号源）、遥测采集幂等（重复帧跳过）、HKT-DeviceHub 共享遥测通道接入。
- **产品体验**：统一告警工作台（NIX-245）、疫病接触追踪工作台、牧场总览晨间看板（NIX-246）、图表统一读数层与告警体验 v2 已上线。
- **数据治理**：围栏 GPS 行走轨迹导入（GPX / RTK XLSX + 包络算法，NIX-213）、设备档案规则管理（NIX-214）、网关位置/通信距离/覆盖诊断（NIX-219/220）已落地。
- **AI/datagen**：Phase A/B 与 datagen v1 合成链路闭环，NIX-243 已恢复 L1 异常检测自动链路；Phase C C0-C5 行为管道 dev 验证通过，C6-C10 与真实遥测效果验证推进中。
- **可靠性**：时序分区自动维护、GPS outbox、遥测幂等已落地；真实遥测扩量前继续生产化加固。
- `PC/` 为历史 Angular 前端，不随主流程迭代。

---

## 当前工程结构

| 目录 | 说明 |
|------|------|
| [`Mobile/mobile_app/`](./Mobile/mobile_app/) | Flutter Web/App（应用标识 `hkt-livestock-agentic`），通过 `ApiClient` 对接 Spring Boot API |
| [`smart-livestock-server/`](./smart-livestock-server/) | Spring Boot 3.3 + Java 17 + PostgreSQL/Flyway + Redis/RocketMQ，DDD 洋葱架构 |
| [`business-platform/`](./business-platform/) | 对接验证与实验工程：blade 设备采集对接 PoC、MQTT 解码、开放平台 |
| [`license-issuer/`](./license-issuer/) | 许可证签发工具（License 服务、签发脚本与验证向量） |
| [`tooling/`](./tooling/) | MBTiles 离线瓦片生成/导入脚本 |
| [`docs/`](./docs/) | 部署、架构、spec/plan、API 契约、产品与营销、测试与经验文档 |
| [`.agents/skills/`](./.agents/skills/) | 项目级 Agent 技能：deploy、api-smoke-test、create-migration、seed-verify |
| [`PC/`](./PC/) | 历史 Angular 前端，归档不维护 |

### 常用验证

```bash
cd smart-livestock-server && ./gradlew compileJava

cd Mobile/mobile_app
HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze
HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter test
```

目标测试示例：`./gradlew test --tests 'com.smartlivestock.iot.*'`。当前全量后端测试存在 19 个既有失败（14 个 Testcontainers Docker 环境初始化 + 5 个 `AlertReadStatusTest` mock 债务），不要误判为新回归。

部署以后端目录脚本为准：`cd smart-livestock-server && ./scripts/deploy.sh dev`。dev 可由 Agent 执行；test 环境必须等用户通知后再执行。部署后以种子账号登录 200 判活（`/actuator/health` 需认证，502→401 属启动中正常轨迹）；前端生效以容器内 `main.dart.js` md5 对比本地为准。

架构与模块说明见 [`Mobile/AGENTS.md`](./Mobile/AGENTS.md)。

---

## 版本方向（摘要）

| 阶段 | 内容 |
|------|------|
| MVP Phase 1-2c | 认证/租户/牧场/设备/围栏/告警/地图、Commerce、Health、Analytics 已完成 |
| Phase 3 — IoT 真实接入 | blade 平台对接、设备健康管理持续迭代；2026-09 新增牲畜信号同步链路与遥测幂等 |
| 产品与数据治理 | 统一告警工作台、疫病接触追踪工作台、总览晨间看板、图表统一读数层；围栏轨迹导入、设备档案规则、网关通信距离与覆盖诊断 |
| AI 双轨 | Phase A/B 与 datagen v1 闭环；L1 异常检测自动链路已恢复；Phase C C0-C5 dev 验证，C6-C10 与真实数据验证推进 |
| 生产化 | 分区自动维护、索引加固、GPS outbox、遥测幂等已落地；真实遥测扩量前持续加固 |

详细路线图见 [`docs/reference/project-overview.md`](./docs/reference/project-overview.md) 与 [`docs/superpowers/specs/2026-06-19-ai-health-roadmap.md`](./docs/superpowers/specs/2026-06-19-ai-health-roadmap.md)。

---

## 文档索引

| 文档 | 说明 |
|------|------|
| [`AGENTS.md`](./AGENTS.md) | 协作与代码约束（全仓库） |
| [`docs/reference/project-overview.md`](./docs/reference/project-overview.md) | 项目概述、上下文、路线图 |
| [`docs/reference/deployment.md`](./docs/reference/deployment.md) | 部署、分区、GPS outbox、环境与验证 |
| [`docs/product/user-journey-guide.md`](./docs/product/user-journey-guide.md) | 用户旅程指南（2026-09-20 基线 + 按角色时序图） |
| [`docs/marketing/`](./docs/marketing/) | 对外上市材料（方案介绍、Market Beta、开发套件、技术支持，2026-09-28 刷新） |
| [`docs/superpowers/specs/2026-06-19-ai-health-roadmap.md`](./docs/superpowers/specs/2026-06-19-ai-health-roadmap.md) | AI/datagen 双轨路线图 |
| [`docs/api-contracts/api-overview.md`](./docs/api-contracts/api-overview.md) | API 契约入口 |
| [`Mobile/AGENTS.md`](./Mobile/AGENTS.md) | Flutter 模块、测试与风格 |
| [`.agents/skills/`](./.agents/skills/) | 项目级 Agent 技能（部署、冒烟、迁移、种子验证） |

`docs/archive/features/*` 与 `Mobile/docs/*` 中的功能清单是历史快照，不作为当前完成状态的事实来源；以代码、Flyway、测试记录和 `docs/reference/*` 为准。
