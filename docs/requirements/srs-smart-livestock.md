# SRS-总纲：智慧畜牧（SmartLivestock / BoviScout）软件需求规格说明书

> 文件名不带版本号；版本演进见下方"修订记录"与 git 历史。
> 基线：master b10492b3（2026-11-20）/ release 769 / 0.7.1；PRD 校准基准：docs/product/smart-livestock-prd-v2.5.md（2026-11-18 基线）。

## 修订记录

| 日期 | 说明 |
|------|------|
| 2026-11-21 | 首版编制：四源合一（archive/features × PRD v2.5 × Mobile 早期史料 × superpowers/requirements），算法依据取自 docs/research/，需求债盘点取自 docs/superpowers/_archive/reviews/ 48 份评审 |

## 1. 文档目的与范围

本 SRS 将分散于功能清单、PRD、早期需求史料、需求工单四类来源的需求合并为带编号、可追溯、标注实现状态的需求规格：

- 收录范围：后端/前端/系统功能清单（as-built）、PRD v2.5（as-planned + as-built 校准）、Mobile 早期需求 7 份（谱系保留）、superpowers/requirements 8 份（近期增量需求）、docs/research/ 算法依据。
- 不收录：GTM/商用资料（另行核对任务）、测试用例规格（另册 TC 编号）。
- 实现状态口径：已实现（代码核实，附证据路径）、部分实现、规划未实现（PRD 审计核实）、谱系-规划/被取代（早期史料被现方案取代但不断链）。

## 2. 编号体系

- 功能需求：REQ-<域>-NNN，域代码：IDT（Identity/租户）、CMC（Commerce/订阅商业化）、RCH（Ranch/牲畜/围栏/告警）、IOT（IoT/设备/GPS）、HLT（Health/健康 AI）、PLT（Platform/通知）、NFR（非功能）。
- 需求债：REQ-DEBT-NNN，专项见 srs-requirements-debt.md。
- 每条需求带：来源（S1–S5 源标识，见 §3）、优先级（P0 必须 / P1 重要 / P2 规划）、验收标准、实现状态（含核实证据）。

## 3. 需求来源标识

| 源 | 内容 |
|----|------|
| S1 | docs/archive/features/ 5 份功能清单（backend/frontend/system-feature-list、feature-checklist.csv、system-feature-document）——as-built 底稿 |
| S2 | docs/product/smart-livestock-prd-v2.5.md + docs/reports/2026-11-20-prd-v2.5-sync-audit.md——校准基准与未实现项核实 |
| S3 | Mobile/docs/requirements/ 3 份 + Mobile/docs/product/ 4 份——2026-03/04 早期需求史料（谱系） |
| S4 | docs/research/ 16 份 + docs/research/papers/——算法需求依据（饮水/活动阈值/GPS 质量/仿真参数） |
| S5 | docs/superpowers/requirements/ 8 份——近期增量需求工单 |

## 4. 模块文件索引

| 文件 | 域 | 内容 |
|------|----|------|
| srs-module-identity-commerce.md | IDT / CMC | 租户、用户、牧场成员、API Key、订阅、配额门控、合同分润、Licensed |
| srs-module-ranch-iot.md | RCH / IOT | 牲畜管理、电子围栏、GPS 定位、设备接入、安装、告警中心 |
| srs-module-health-ai.md | HLT | 健康监测、发热/发情/分娩/饮水/活动、异常检测、个体基线、仿真评估 |
| srs-module-platform-nfr.md | PLT / NFR | 推送通知、国际化、安全、性能、GDPR、部署、离线 |
| srs-requirements-debt.md | DEBT | 需求债专项盘点（48 份评审 → REQ-DEBT-NNN） |

## 5. 需求谱系说明（不断链）

早期需求（S3）按以下方式并入：已被现方案实现/取代的，在对应 REQ 的"来源"列引用并在本节登记谱系；仍为规划或独立价值的，单列 REQ 并标 谱系-规划。

| 史料 | 谱系去向 |
|------|----------|
| Mobile/docs/requirements/2026-03-27-虚拟围栏应用需求分析.md | → REQ-RCH-002/003 系列（围栏/轨迹/竞品差异化）；竞品分析与页面规划已由 PRD §2/§6.3 取代 |
| Mobile/docs/requirements/2026-04-21-backend-infra-requirements.md | → 后端基础设施需求已由 PRD §4 + 架构评审落地取代（DDD 分层、Flyway、事件流）；验收标准并入 REQ-IDT 系列 |
| Mobile/docs/requirements/2026-04-27-机器学习需求说明书.md | → REQ-HLT-015 谱系源（数据基础设施→已实现；ML 模型矩阵→部分被 AI 路线图取代） |
| Mobile/docs/product/2026-03-24-牛羊监测订阅服务定价设计.md（含指南） | → REQ-CMC-001 谱系源；现行口径以 PRD §3 为准 |
| Mobile/docs/product/2026-04-02-牛羊追踪与健康监测AI模型算法矩阵.md | → REQ-HLT-015 谱系源（性能指标口径仍有效） |
| Mobile/docs/product/2026-04-10-研发项目立项书.md | → 项目目标谱系源（REQ-NFR-001 引用总体目标） |
| Mobile/docs/product/digital-twin-livestock.md | → 数智孪生概念谱系源（PRD §6.4 模块 B） |
| docs/superpowers/requirements/事件风暴.md | → REQ-CMC-002/004/005/006 领域事件清单（S1–S6/C1–C4/R1–R2/L1–L5，Commerce 16 个领域事件已落库，S1 证实） |
| docs/superpowers/requirements/阿根廷.md | → 国际化/市场准入输入（REQ-NFR-005 系引用） |
| docs/superpowers/requirements/2026-11-03-nix158-286-calving-early-warning.md | → REQ-HLT-020/025 前置需求单（分娩预警闭环） |
| docs/superpowers/requirements/2026-11-03-push-notification-fcm-apns.md | → REQ-PLT-002/003（APNs 已实现、FCM 未实现） |

## 6. 需求汇总统计

| 域 | REQ 数 | 已实现 | 部分实现 | 规划未实现 | 谱系保留 |
|----|--------|--------|----------|------------|----------|
| IDT | 8 | 8 | 0 | 0 | 0 |
| CMC | 10 | 9 | 0 | 1 | 0 |
| RCH | 14 | 13 | 0 | 1 | 0 |
| IOT | 12 | 10 | 0 | 2 | 0 |
| HLT | 23 | 16 | 1 | 4 | 2 |
| PLT | 5 | 3 | 0 | 2 | 0 |
| NFR | 8 | 6 | 2 | 0 | 0 |
| 合计 | 80 | 65 | 3 | 10 | 2 |

需求债：REQ-DEBT-001～010 台账 10 项（8 项未闭环 + 2 项部分闭环）；另有 2 项重点评审意见（deep-review I8 索引、AI 路线图模拟器数据风险）经代码核实已闭环，不占 DEBT 编号，详见 srs-requirements-debt.md。

## 7. 与其他产物的关系

- 测试用例规格（TC 编号）另册编制，按 REQ 编号建立双向追溯。
- docs/reports/2026-11-20-docs-inventory-and-gap-audit.md 为时点审计快照，与本 SRS 冲突时以本 SRS 的代码核实结论为准。
- 追溯矩阵最终由 traceability-matrix.md 汇总（本团队后续任务）。
