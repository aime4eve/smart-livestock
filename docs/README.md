# 智慧畜牧系统文档索引

> 本文件是 `docs/` 目录的导航入口，更新日期：2026-11-01（product/ 四份事实源文档按 2026-11-01 代码基线对账刷新）

## 落位规则（新增文档先看这里）

1. **事实源优先**：代码、Flyway 迁移、部署验证记录优先于任何文档；文档之间的引用以本索引为准。
2. **落位表**：对外材料 → `docs/gtm/smart-livestock/`（GTM 源稿仓，本仓 `marketing/` 仅存指针）；交互原型与设计令牌 → `prototypes/`；一次性调研分析 → `research/`；常驻参考 → `reference/`；设计规格 → `superpowers/specs/`；实施计划 → `superpowers/plans/`。
3. **过程文档带日期前缀**（`YYYY-MM-DD-`）；过时或完成使命的文档移入 `archive/`，不删除（git 历史之外仍需可读的归档）。
4. 历史快照（如 `archive/features/`、`Mobile/docs/`）不作为当前完成状态的事实来源。

## 目录结构

### `product/` — 产品级文档（事实源）

| 文档 | 说明 |
|------|------|
| `smart-livestock-prd-v2.5.md` | 产品需求文档 v2.5（功能口径事实源，2026-11-18 基线 / release 769 / 0.7.1） |
| `system-architecture.md` | 系统架构设计（v2.0，2026-11-01 代码基线） |
| `customer-journey.md` | 客户旅程（platform_admin → b2b_admin → owner，2026-11-01 基线） |
| `user-journey-guide.md` | 用户旅程与权限说明（2026-11-01 代码基线） |

### `marketing/` — 对外材料（已迁出，指针目录）

全部对外/上市材料已于 2026-11-18 收编至 GTM 源稿仓：**[`docs/gtm/smart-livestock/`](../docs/gtm/smart-livestock/)**（本地检出：`/Volumes/DEV/00-products-dev/hkt-smart-agentic/docs/gtm/`）。本目录仅保留指针说明（见 [`marketing/README.md`](marketing/README.md)），目录结构：`brochure/`（方案书、介绍、告警监测说明）、`responses/`（客户答复批次）、根级（market-development-kit、technical-support-guide）。

> 新 GTM 材料一律在 docs/gtm 仓编辑（MR + /approve），不要在本工程仓新建；内部交互原型统一在 `prototypes/`。

### `prototypes/` — 交互原型与设计令牌（内部）

- 功能原型：`nix-*.html`、`nix20-*.html`、`datagen-console-prototype*`、`gps-quality-rtk-*-prototype*`、`2026-08-29-tb-device-autoconfig-wizard.html`、`health-detail-charts.html`、`livestock-management-ux-v2.html`
- 设计令牌：`design-tokens*.md`（由 `prototype-to-flutter-fidelity` skill 从原型提取）

### `research/` — 一次性调研与分析

GPS 抖动系列（`gps-jitter-*`、`GPS抖动的行业解决思路`）、瘤胃活动阈值校准与公开数据集机制（NIX-193）、CattleX OEM 询盘分析。

### `reference/` — 常驻参考（按需查阅）

| 文档 | 说明 |
|------|------|
| `project-overview.md` | 当前项目概述、上下文与路线图 |
| `deployment.md` | 当前部署、分区、outbox 与环境验证 |
| `lessons-learned.md` | 经验教训（五段式，AGENTS.md 速查的完整版） |
| `gps-quality-criteria.md` | GPS 质量判定标准 |
| `seed-data-landscape.md` | 种子数据全景 |
| `e2e-test-coverage-audit.md` | E2E 测试覆盖审计 |
| `code-statistics.md` | 代码行数统计 |
| `C15134_…LIS3DHTR_规格书_WJ51889.PDF` | RBC-100 加速度计规格书 |

### `deployment/` — 部署与交付

安装指南（`release-install-guide.md`）、运维指南、部署实战手册（86/223 双机复盘）、发布检查清单、签发工具部署（`license-issuer-deploy.md`）。

### `training/` — 培训手册

00 赋能手册、01 海外售前实战、02 售后支持、03 平台培训、04 GAT-100 项圈、05 RBC-100 瘤胃胶囊、06 培训签到表。

### `api-contracts/` — API 契约

`api-overview.md` / `app-api.md` / `admin-api.md` / `open-api.md` / `changelog.md` / `migration-guide.md`。

### `superpowers/` — 设计规格与实施计划（过程文档）

| 子目录 | 说明 |
|--------|------|
| `specs/` | 设计规格文档（活跃） |
| `plans/` | 实施计划文档（活跃） |
| `requirements/` | 需求脑暴（事件风暴、阿根廷场景） |
| `reviews/` | 2026-08 起的设计/计划评审 |
| `_archive/` | 2026-07 及更早的评审与质量报告（只读归档） |

### `testing/` — 测试用例

`market-beta-test-cases.md`（TC-H / TC-O 双机用例，§6 为权威步骤）。

### `reports/` — 周报与验证报告

工作周报、数据库 schema 评审、GPS outbox 基准、datagen v2 验证报告。

### `diagrams/` — 图表

- `architecture/`：当前版架构图（role-scenario v3 / runtime / system，含 archify 可再生成源）
- 数据流图：`telemetry-data-flow.*`

### `protocols/` — 硬件协议

瘤胃胶囊与牛羊追踪器的 LoRaWAN 上行 Payload 解析协议定义。

### `guides/` — 操作指南

`ONBOARDING.md`、`server-setup-guide.md`、`subscription-guide.md`、`tileserver-deployment-guide.md`、`tileserver-gl-implementation-overview.md`。

### 硬件资料地图（跨目录汇总）

> 智慧畜牧（BoviScout）硬件相关资料散落多个目录，此处按设备/用途汇总入口（2026-11-20 增）。**LoRaWAN 网关不纳入本仓硬件资料体系**（已裁决，见规划 v1.1 §11.2 决策 9 相关口径）。

| 类别 | 资料 | 位置 | 说明 |
|------|------|------|------|
| 设备协议 | 牛羊追踪器（GAT-100）LoRaWAN 上行 Payload 解析 | [`protocols/LoRaWAN 牛羊追踪器上行 Payload 解析协议定义.md`](protocols/LoRaWAN%20牛羊追踪器上行%20Payload%20解析协议定义.md) | 上行帧格式与解析口径 |
| 设备协议 | 瘤胃胶囊（RBC-100）LoRaWAN 上行 Payload 解析 | [`protocols/LoRa WAN瘤胃胶囊上行Payload解析协议定义.md`](protocols/LoRa%20WAN瘤胃胶囊上行Payload解析协议定义.md) | 上行帧格式与解析口径 |
| 元器件规格 | LIS3DHTR 姿态传感器（加速度计）规格书 | [`reference/C15134_…LIS3DHTR_规格书_WJ51889.PDF`](reference/) | RBC-100 加速度计（WJ51889） |
| 设备培训 | GAT-100 项圈（追踪器）培训手册 | [`training/04-gat-100-cattle-sheep-tracker-training.md`](training/04-gat-100-cattle-sheep-tracker-training.md) | 售前/售后培训 |
| 设备培训 | RBC-100 瘤胃胶囊培训手册 | [`training/05-rbc-100-rumen-capsule-training.md`](training/05-rbc-100-rumen-capsule-training.md) | 售前/售后培训 |
| 外部平台接入 | hkt-blade-device 对接：设备 ID 获取指南 | [`../business-platform/hkt-blade-device-docking/docs/device-id-acquisition.md`](../business-platform/hkt-blade-device-docking/docs/device-id-acquisition.md) | blade 设备入网前置 |
| 外部平台接入 | hkt-blade-device 对接：PoC 设备配置指南 | [`../business-platform/hkt-blade-device-docking/docs/poc-device-configuration-guide.md`](../business-platform/hkt-blade-device-docking/docs/poc-device-configuration-guide.md) | PoC 配置流程 |
| 接口契约 | hkt-blade-device 设备接口契约 | [`api-contracts/hkt-blade-device-interface.json`](api-contracts/hkt-blade-device-interface.json) | blade 设备数据维度/端点 |

### `archive/` — 归档

- `features/`：2026-05/06 历史功能快照（checklist 与前后端功能清单，不反映当前状态）
- `2026-05-27-issue48-status-review.md` 等一次性评估文档

---

> Flutter Demo 阶段（2026-03 至 2026-05）的历史归档文档见 [`Mobile/docs/`](../Mobile/docs/README.md)
