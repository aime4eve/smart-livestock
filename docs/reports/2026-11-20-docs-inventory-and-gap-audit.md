# 智慧畜牧（BoviScout）资料全景台账与一致性缺口审计

> **日期**：2026-11-20
> **范围**：本仓（L3-smart-livestock）研发流程全链资料 + GTM 源稿仓（hkt-smart-agentic/docs/gtm/smart-livestock）商用支持资料
> **方法**：目录全量盘点 + git 最后提交日期对账 + 与 master 代码基线（2026-11-18, release 769 / BoviScout 0.7.1）交叉比对
> **性质**：一次性盘点报告；日常导航以 `docs/README.md` 为准

---

## 一、总体规模

| 区域 | 文件数 | 最新基线 |
|---|---|---|
| 本仓 docs/（md 316 + 原型/图 120+） | ≈440 | 2026-11-18 |
| 其中 superpowers/（specs 78 / plans 72 / reviews 12 / requirements 8 / archive 52） | 227 | 2026-11-12 |
| Mobile/docs/（历史快照，不作事实源） | — | 归档 |
| GTM 仓 smart-livestock/ | 31 | 2026-11（活跃） |

---

## 二、研发流程线台账（需求 → 设计 → 编译 → 部署 → 测试）

### 1. 需求 / 产品事实源 — `docs/product/`

| 文档 | 基线 | 一致性判断 |
|---|---|---|
| smart-livestock-prd-v2.4.md（3091 行） | 2026-11-01 | ⚠️ 落后约 3 周：11-01 后合入 NIX-430（APNs 推送，PRD 标注"未实现"已过时）、NIX-412 系列（缓冲带围栏）、NIX-198/200/237/400/410/415/416 修复、版本 0.7.1 (769) |
| system-architecture.md | 2026-11-01 | ⚠️ 同上，推送通道与围栏几何需补 |
| customer-journey.md / user-journey-guide.md | 2026-11-01 | ⚠️ 推送通知旅程缺失 |
| 对账审计 | 2026-11-01 | reports/2026-11-01-prd-v2.4-sync-audit.md、2026-11-01-product-docs-sync-audit.md 可作下次刷新模板 |

### 2. 设计（spec / plan / 原型）

- `docs/superpowers/specs|plans`：150 份，覆盖 2026-05 → 2026-11-11（最新：fence-from-device-track）。机制健康，feature 流程闭环（requirements → spec → plan → review → fidelity）。
- `docs/prototypes/`：55 份 HTML 原型 + design-tokens（2026-11-18 刷新）。
- `docs/diagrams/`：66 份架构图，README 2026-11-03。
- `docs/api-contracts/`：9 份，app-api 2026-11-14、admin/open-api 2026-11-03，含 changelog——**维护机制最好的一块**。

### 3. 编译 / CI

- 规则集中在 AGENTS.md §1/§5b：precheck-ci.sh（本地复刻双流水线）、remote-integration-test.sh（123 借 Docker）、push 后盯绿。
- `scripts/` + `.github/` + `.gitlab-ci.yml`（2026-11-18 迁 GitLab 布局）。
- ⚠️ 缺口：没有独立的"编译/CI 操作手册"文档，规则散在 AGENTS.md 与 lessons-learned；新人需读代码仓配置才能拼出全貌。

### 4. 部署 — `docs/deployment/`（8 份）

- release-deployment-playbook / release-install-guide / release-operations-guide / release-checklist / tenant-onboarding-guide / license-issuer-deploy / 86-223 升级交接（2026-11-02）。
- `docs/reference/deployment.md` 常驻参考（2026-10-20）。
- ⚠️ 小缺口：四环境全量部署链的"实操判据"（main.dart.js md5、种子登录 200）在 AGENTS.md/lessons #23，deployment/ 手册内未内嵌交叉引用。

### 5. 测试 — `docs/testing/`（67 份）

- 按批次目录归档（ios-journey、super-admin-context、dev-baseline-learning、estrus-explanation、fence-track-e2e），最新 2026-11-12。
- e2e 覆盖审计 reference/e2e-test-coverage-audit.md。
- ⚠️ 已知债：后端 19 个既有失败（14 Testcontainers + 5 AlertReadStatusTest）无独立跟踪文档，只在 AGENTS.md 记载。

---

## 三、商用支持线台账（GTM 仓 + 本仓残留）

### GTM 仓 `docs/gtm/smart-livestock/`（2026-11-18 收编，MR 流程）

| 目录 | 内容 | 状态 |
|---|---|---|
| brochure/ | 中英方案册 html、市场测试版方案介绍、告警监测体系说明 v0.6.1（xlsx+pdf） | ✅ 活跃；⚠️ 告警口径"以 master 为准（2026-10-22 审计）"，11 月告警/围栏/推送变更后需复核 |
| one-pager/ | solution-one-pager-en.md | ✅（G 组裁决后放行） |
| website-copy/ | iot-cattle-tracking-lorawan-vs-cellular-vs-satellite.md + assets | ✅ |
| faq/ | 仅 README | ⚠️ **空壳**，FAQ 待建 |
| roi-talktrack/ | 仅 README | ⚠️ **空壳**，ROI 话术待建 |
| responses/ | 蛆病答复 v1.0、HKT 连续性检查清单 v1.1（中英三格式）、customer-response-2026-11 批次 4 组（瘤胃滞留/联合试点/能力演示/健康发情算法） | ✅ 完整且双语 |
| 根级 | market-development-kit.md、technical-support-guide.md | ✅ |

### 本仓商用残留

| 位置 | 内容 | 判断 |
|---|---|---|
| docs/marketing/ | 仅指针 README（指向 GTM 仓） | ✅ 机制正确 |
| docs/training/（8 份） | 赋能指南、售前海外 playbook、售后 playbook、平台/GAT-100/RBC-100 培训、签到表 | ✅ 2026-11-18 刷新；⚠️ 培训与 GTM 宣传口径（版本 0.7.1、推送能力）联动待核 |
| docs/guides/（8 份） | 用户手册 GUIDE-LVS-001（11-18 迁入）、订阅指南、iOS 构建安装、tileserver、运维登记单 | ✅；⚠️ 用户手册是否覆盖 11 月新功能（围栏缓冲带、推送）待核 |

---

## 三b. 硬件设备资料台账（2026-11-20 补入）

本项目硬件体系 = 自研两款终端（GAT-100 牛羊追踪器、RBC-100 瘤胃胶囊）+ LoRaWAN 网关（**用户裁决 2026-11-20：网关资料不纳入梳理**）+ ThingsBoard/Blade 接入链。资料分布：

| 类别 | 资料 | 位置 | 状态 |
|---|---|---|---|
| 通信协议 | LoRaWAN 牛羊追踪器上行 Payload 解析协议定义 | docs/protocols/ | ✅ 常驻 |
| 通信协议 | LoRaWAN 瘤胃胶囊上行 Payload 解析协议定义 | docs/protocols/ | ✅ 常驻 |
| 器件规格 | LIS3DHTR 姿态传感器规格书（RBC-100 加速度计） | docs/reference/ | ✅ 唯一一份器件级 datasheet |
| 设备培训 | GAT-100 追踪器培训、RBC-100 瘤胃胶囊培训 | docs/training/04、05 | ✅ 2026-11-18 刷新 |
| 设备接入 | hkt-blade-device-docking（设备 ID 获取、POC 配置指南、标定脚本） | business-platform/hkt-blade-device-docking/docs/ | ✅ |
| 设备接入 | TB 设备自动配置（design/tokens/plan/wizard 原型） | docs/superpowers/ + prototypes/ | ✅ |
| 设备对接契约 | hkt-blade-device-interface.json | docs/api-contracts/ | ✅ |
| 算法-硬件交叉 | bolus 活动阈值报告、GPS 抖动系列（5 设备实测验证）、饮水检测 L1 标定 | docs/research/ | ✅ |
| 公开数据集 | strathclyde-bolus（rumination SVM 论文+样本数据） | data/datasets/ | ✅ |

**硬件资料缺口**：

| # | 缺口 | 说明 |
|---|---|---|
| G8 | **无设备级产品规格书**（GAT-100 / RBC-100） | 仓内只有通信协议 + 一份器件 PDF + 培训材料；对标竞品所需的市场宣传口径规格（续航/精度/防护等级/工作温度/质保等）不成文，散在培训与 GTM 方案册里 |
| G9 | 硬件资料无统一索引 | protocols/、reference/、training/、business-platform 四处分布，docs/README.md 的 protocols 节仅 2 行，无"硬件资料地图" |

> 说明：仓外还有两大硬件知识源——wiki-iot 竞品库与 spec-benchmark skill 的设备规格基准库（GAT/RBC/耳标/网关全覆盖）。补 G8 时应优先用 spec-benchmark 流程做规格对标后成文，落到 GTM 仓或 docs/product/，避免与本仓重复。

---

## 四、一致性缺口清单（按优先级）

| # | 缺口 | 位置 | 建议 |
|---|---|---|---|
| G1 | docs/README.md marketing 节仍列 5 个本仓已删文件（solution-introduction 等），索引与实际脱节 | docs/README.md | 改为指向 GTM 仓指针（同 docs/marketing/README.md） |
| G2 | PRD v2.4 / 架构 / 旅程四件套为 11-01 基线，NIX-430 推送、NIX-412 围栏缓冲带、0.7.1 版本未入 | docs/product/ | 按 11-01 对账审计模板做 v2.5 增量刷新（master 11-18 基线） |
| G3 | GTM 告警监测体系说明 v0.6.1 口径基于 2026-10-22 审计，11 月告警链路变更后未复核 | GTM brochure/ | 与 G2 同批：以 master 代码重审 13 种告警定义 |
| G4 | faq/、roi-talktrack/ 两个目录空壳 | GTM 仓 | 立项补建（solution-benchmark / spec-benchmark skill 可支撑） |
| G5 | 后端 19 个既有测试失败无跟踪工单/文档 | AGENTS.md 记载 | 建独立 debt 跟踪文档或工单 |
| G6 | 编译/CI 操作无成文手册（规则散在 AGENTS.md §5b + lessons） | — | 可选：并入 reference/ 新增 ci-handbook.md |
| G7 | 四环境部署判据（md5/种子登录）未在 deployment/ 手册内交叉引用 | docs/deployment/ | 小改：playbook 补引 lessons #23 |
| G8 | GAT-100 / RBC-100 无设备级产品规格书 | 仓内分散 | 用 spec-benchmark 对标流程成文，落 GTM 仓 |
| G9 | 硬件资料四处分布、无索引 | docs/ + business-platform | docs/README.md 增"硬件资料地图"节 |

## 五、结论

研发线资料**结构完整、机制健康**（事实源分层 + 落位规则 + 对账审计传统），主要问题是 **11-01 基线后的三周增量未回灌**（G2/G3）；商用线**收编 GTM 仓方向正确**，短板是 **faq 与 roi-talktrack 空壳**（G4）和**索引残留**（G1）。硬件线"协议+培训+接入"三件已有，缺**设备级规格书（G8）与硬件资料索引（G9）**，仓外 spec-benchmark 基准库可直接支撑。

建议刷新顺序：G1（5 分钟）→ G2+G3（一批对账）→ G8+G9（硬件规格对标成文+索引）→ G4（立项）→ G5-G7（择机）。

> 用户裁决（2026-11-20）：LoRaWAN 网关设备资料**不纳入**本次梳理范围（GAT-100 / RBC-100 两款终端仍纳入）。
