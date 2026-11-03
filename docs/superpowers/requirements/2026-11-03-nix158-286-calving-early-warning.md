# NIX-158/286 分娩预警（临产自动预测）需求单

> **工单归属（2026-11-03 评审核正）**：本单归属本项目 **NIX-158**《分阶段实现产犊备产与 15 小时预警验证》与 **NIX-286**《繁殖闭环 P2/P3》的组合范围；原文件名中的 "NIX-335" 系编号冲突——Linear 全局 NIX-335 是智慧停车"传感器失效订单运营闭环"工单（已完成），与本项目无关，**不得引用其状态作为本需求证据**。

- 立单日期：2026-11-03（2026-11-03 评审核实后修订 v2）
- 来源：海外客户询盘核实（客户问询发情检测与分娩预警是否已上线）。代码核实发现：发情检测为**规则链已实现，真实效果与正式生产使用待验证**；**临产自动预警在生产代码中不存在**，仅有人工生理事件记录（CALVING 里程碑）与 datagen 仿真标签（CALVING_RISK）。而对外资料（`IoT_Global_Trade_HQ` user-manual v1.0、solution-one-pager）已宣传"产犊提醒：体温与行为变化，约 15 小时前预警"。按"资料即产品——资料缺陷视同产品缺陷"原则立本单补齐能力。
- 优先级建议：高（直接影响对外承诺兑现，销售在谈客户以此功能为决策因素）
- 评审依据：`ai-memory/10-Projects/02-smart-livestock/2026-11-03-发情分娩对外答复与NIX335评审核实.md`（只读核查，结论"对外答复不能原样外发"）

## 现状核实（2026-11-03，代码证据）

| 项 | 现状 | 证据 |
|---|---|---|
| 发情检测 | ⚠️ **规则链已实现，真实效果待验证**：步数增幅×0.4 + 体温增量×0.3 + 距离增量×0.3，≥70 分自动生成 ESTRUS 告警；阈值单测证明规则分支，不证明真实发情识别准确率（PRD v2.4 仍将准确率与现场连续运行列为待完成） | `EstrusAnalysisService`、`HealthAlertBridgeService`（`ESTRUS_ALERT_THRESHOLD=70`）、`HealthAlertBridgeServiceTest` |
| 分娩自动预警 | ❌ 不存在 | `AlertType.java` 无 CALVING 类型；`CALVING` 仅为人工事件（`V20261004120000__create_physiology_events.sql`，注释 "manual physiology event stream"）与 datagen 仿真标签（`BehaviorDatasetGenerator` → `CALVING_RISK`） |
| 生理事件管理 | ✅ 人工录入 CALVING/BREEDING 等，可推导泌乳/干奶阶段 | `PhysiologyQueryService` |
| 个体基线 | ⚠️ 快照自动建档默认 `38.50℃`，生产写入只把快照基线复制到温度日志，**无个体基线自动学习/更新路径** | `HealthSnapshotJpaRepository`、`HealthApplicationService` |
| 档位门控 | `estrus_detect`：basic/standard 锁，premium/enterprise 开；`ai_anomaly` 无门控（见追加 1） | `V31__health_detail_charts_seed.sql` feature_gates |

## 需求描述

### 功能目标

对每头佩戴 RBC-100 瘤胃胶囊（可选搭配 GAT-100 项圈）的母牛，自动识别临产征兆并在预计分娩前发出预警。**提前量口径分阶段（对齐 NIX-158）**：阶段一先基于真实产犊标签输出风险提示；阶段二用真实数据评估可实现提前量；实测分布出来前，**对外一律表述为"路线图/待真实数据验证能力"，不得保留"约提前 15 小时"的既成能力口吻**（与 NIX-158 及培训手册红线一致）。

### 检测信号（只使用已确认可采集的数据）

1. **体温特征曲线**：临产前体温先降后回升（数据源：RBC-100 瘤胃体温序列 + `baselineTemp` 个体基线）。**前置缺口**：现基线机制为静态默认值、无自动学习，须先落地个体基线工单（见"前置工程缺口"）。
2. **活动/休息模式变化**：活动量下降、休息-起立切换频繁（步数 `stepCount`、距离 `distanceMeters`、若配 GAT-100 加三轴运动特征）。**前置缺口**：标准 RBC-100 胶囊解码不输出步数/距离（`DecodedRumenFrame` 仅温度/胃动力/电量/三轴原始值/上报周期），三轴派生目前只对 TRACKER 生效——活动特征派生与双设备数据充分性是本单前置项。
3. **综合评分 + 阈值告警**：参照 `EstrusAnalysisService` 模式新增 `CalvingPredictionService`（domain 层），输出临产风险分与预计分娩时间窗；达到阈值由 `HealthAlertBridgeService` 同步生成新告警类型（如 `CALVING_WARNING`），接入告警工作台（现排序为严重度→未读→时间；若需"按建议动作排序"属工作台改造，单列验收项，不得写成既有能力）。

### 前置工程缺口（本单启动的前置工单，缺一不可对外兑现）

1. **个体基线自动学习**（独立工单：`2026-11-03-individual-baseline-auto-learning.md`）——发情评分与临产预测共同的前提。
2. **RBC-100 活动特征派生 / 双设备数据充分性评估**——决定"胶囊单独"还是"胶囊+项圈"才够输入。
3. **明确时间窗与样本归一化**——现发情窗口取"最近 7 条/3 条"记录数，无时间窗、未按样本数归一化，需先定口径。
4. **FCM/APNs 后台推送**（独立工单：`2026-11-03-push-notification-fcm-apns.md`）——提前预警送不到人就没有价值；前台刷新与后台/杀进程系统通知是不同验收项。
5. **真实 RBC 全链路验证 + 真实数据效果验收**——本单最终验收标准是**真实数据评估报告**，不是"功能上线"；datagen 仿真只可用于管道预研。

### 约束与验收标准

- **新增枚举/告警类型需同步迁移 CHECK 约束**（参考 `V20260709120000__phase3_device_extension.sql` 中 `alert_type` CHECK 列表，`V20260925100000` 同步过告警工作台白名单）。
- **feature gate**：新增 `calving_warning` feature_key，档位对齐 `estrus_detect`（basic/standard 锁、premium/enterprise 开），Flyway seed 迁移 + 前端功能门控同步。
- **多来源 source 字段**：新写路径带合法 `source`，区分真实遥测与 datagen（沿用 estrus_scores 的约束模式）。
- **真实效果验收只用真实数据**：效果结论必须来自真实采集遥测评估，禁止仿真结果冒充（AGENTS.md 红线）。
- **i18n**：告警文案与建议走 MessageSource 双语 + Flutter AppLocalizations 中英 arb 同步。
- **通知链路**：前台实时性复用现有信号通道（App 前台 SSE/轮询）；**后台/锁屏系统推送是独立验收项**，归属 FCM/APNs 独立工单，本单不含。
- **测试**：domain 评分单测 + 真库集成测试（新写路径不能只有 mock 单测，见经验 #19）+ 部署 dev 后端到端冒烟（告警生成 → App 可见）。

## 2026-11-03 评审追加范围（答复口径核实发现的缺口）

> 评审核正：原"发情检测/档位门控/双模式/定价均核实可兑现"过度概括——发情仅规则链且真实效果未验证；ONPREM 许可仍带 tier/expiresAt；后端功能门控未全闭环；试用为 PREMIUM 档非全部功能。以下缺口并入本单或另立工单：

### 追加 1：AI 异常检测补 PREMIUM 档 feature_gate

- 现状：`AI_ANOMALY` 告警类型与评分字段已存在（`V40__add_ai_anomaly_integration.sql`），但 `V31` 的 feature_gates 种子只配了 temperature_monitor / peristaltic_monitor / health_score / estrus_detect / epidemic_alert 五个键，**`ai_anomaly` 无档位门控**（默认全档开放）。
- 需求：新增 `ai_anomaly` feature_key seed，档位对齐 `epidemic_alert`（basic/standard 锁、premium/enterprise 开），与商务口径"AI 异常检测属 PREMIUM"对齐，避免宣传卖点白送低档订阅。
- 验收：Flyway 迁移 + 前端功能门控同步；低档租户访问 AI 异常页面/接口被门控拦截。

### 追加 2（移交独立工单）：手机离线推送（FCM/APNs）

- 已按评审意见从本单拆出，独立为 `2026-11-03-push-notification-fcm-apns.md`。拆分理由：该能力横跨发情/疫病/临产/订阅横幅多个业务的触达，是平台基础设施而非繁殖单一需求；验收（App 退后台/被杀后系统通知可达、点击直达详情）在独立工单闭环。本单只依赖其交付，不重复验收。

### 追加 3：检测信号数据源对齐（对外口径可兑现性）

- 现状：对外答复口径中"社交行为异常""采食、走动、休息比例"两项**无数据源支撑**——这些特征**不进入生产发情评分**（评分输入只有步数增幅/体温增量/移动距离），无动物间社交互动信号，无采食行为字段；躺卧/起立统计口径统一为：**可选 P2 增强（三轴数据派生），落地前对外不承诺**。
- 需求（按优先级）：
  1. **必做（本单）**：临产预警信号设计只使用已确认可采集的数据——瘤胃体温序列（先降后回升）、步数/距离（活动减少）、三轴运动特征（需 GAT-100 或胶囊活动数据，以前置缺口 2 评估结论为准）。对外文案同步修订：删"社交行为异常"；"采食…比例"改为"活动与休息模式的近期变化"。
- 验收：对外材料（user-manual、one-pager、营销邮件）中的检测信号描述与本单实现的数据源逐项对得上；`00_Capability_Claims_Matrix.xlsx` 能力口径基准同步更新。

## 交付物

1. `CalvingPredictionService` + 阈值配置 + 告警桥接
2. Flyway 迁移：alert_type CHECK 扩展、feature_gates seed（`calving_warning` + 追加 1 的 `ai_anomaly`）、（如需）评分结果表
3. 前端：健康详情/告警工作台的临产预警展示与确认闭环
4. 资料回刷：user-manual、one-pager 与实现核对，含追加 3 的信号描述修订与"约 15 小时"口径降级（资料超前宣传问题随之消除）
5. **真实数据提前量分布评估报告**（阶段二验收物；实测前对外只讲"路线图/待验证"）

## 关联

- 正式工单：NIX-158（分阶段产犊备产与 15 小时预警验证）、NIX-286（繁殖闭环 P2/P3）、NIX-156（发情增强与繁殖收益闭环）
- 独立前置工单：个体基线自动学习、FCM/APNs 推送（同日另立）
- 复用：发情告警桥接机制；Phase C 行为波形管道（CALVING_RISK 标签可作预研训练素材，不得作效果证据）
- 关联资料：`IoT_Global_Trade_HQ/02_Product_Specs_Certification/06_Software_Platform/Livestock_SaaS_App/user-manual_v1.0_Draft.md`（"产犊提醒 ~15 小时"条目需随本单降级口径修订）
- 评审核实记录：`ai-memory/10-Projects/02-smart-livestock/2026-11-03-发情分娩对外答复与NIX335评审核实.md`
