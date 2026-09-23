# 健康整合最终形态 Spec（NIX-246）评审意见

> 编号说明：spec/本评审/plan 原自称 "NIX-245"，该编号已被 USD 按头定价工单占用，2026-09-23 起统一改号 NIX-246。

| 字段 | 值 |
|---|---|
| 评审对象 | [2026-09-23-health-integration-final-spec.md](../specs/2026-09-23-health-integration-final-spec.md) |
| 实现蓝本 | [health-scenario-alert-integration-prototype.html](../../prototypes/health-scenario-alert-integration-prototype.html)（原型六屏 + 说明面板） |
| 评审日期 | 2026-09-23 |
| 评审人 | Kimi Code Agent |
| 评审方式 | spec ⇄ 原型逐屏比对 + spec 每条后端契约/前端改造假设对照实际代码核实（后端 `smart-livestock-server/`、前端 `Mobile/mobile_app/`），关键结论均已落地到文件与行号 |
| 结论 | **有条件通过** — 两项 P0（"处理=已读"与告警状态机冲突、AI 链路前提未成立）必须在 spec 修订中解决；P1 清单澄清后方可进入 plan 阶段 |

---

## 评审总结

Spec 的信息架构裁决（孪生并入牧场、四场景管理台、详情页融合病程、告警中心作通知枢纽）与原型六屏高度一致，设计令牌表与原型 `:root` 逐值吻合，可被保真流程解析。后端契约依赖的数据底座经核实**真实存在**：`health_snapshots`、`anomaly_scores`、`GROUP_HEALTH` 健康类告警分组（`AlertApplicationService.java:41-42`）、已读/忽略/批量已读 API、密接追踪表与端点、EPIDEMIC 枚举占位。spec 的两处现状判断也准确：EPIDEMIC 类型从未被创建（全仓无开单路径）、健康率存在 >100% 口径 bug。

但核实发现 spec 有**两处与代码事实直接冲突的硬伤**（P0），以及一批实施前必须澄清的定义缺口（P1）：对账行判定规则、详情页常态/多病程形态、疫情全场单与牛级聚合的模型冲突、密接数据无写入路径、S5 排行页无原型蓝本、门控矩阵遗漏、"零删除"与"禁用词"两条裁决互相打架等。多数问题属于"spec 写得比代码现状乐观"，修订成本低，但不修会直接导致实施做错或卡住。

**按严重度排列的发现**：

| 级别 | 编号 | 标题 |
|---|---|---|
| P0 | F1 | "处理 = 标记已读"裁决与告警状态机冲突，按此实施自愈与对账全失效 |
| P0 | F2 | AI 评估链路当前被注释禁用，spec 未声明此前提与依赖 |
| P1 | F3 | 健康率修复写"实现时定位"过于含糊，根因与位置已可确定且不止一处 |
| P1 | F4 | 自愈任务引用不存在的方法名与形态；事件驱动缺口应写明 |
| P1 | F5 | "✓ 对上了"判定规则缺失；开单不去重，X≠Y 是常态 |
| P1 | F6 | 详情页常态（无病程）与多病程并存形态未定义 |
| P1 | F7 | 疫情全场单与 episodes 牛级聚合模型冲突 |
| P1 | F8 | 密接追踪无运行时写入路径，"保留"的是空壳 |
| P1 | F9 | S5"谁最需要关注"排行页无原型蓝本 |
| P1 | F10 | 门控矩阵不完整；"零删除"裁决与"禁用词"规范直接冲突 |
| P1 | F11 | 路由方案不完整：管理台 URL、密接深链去向未定义 |
| P2 | F12 | AI 档位映射实施方未决 + finding 词表键与枚举对不上 |
| P2 | F13 | 发情管理台"异常"口径未定义（现状是全量有分的牛） |
| P2 | F14 | 告警中心现状描述不准；spec 漏写原型已有的"只看未读"与日期分组 |
| P2 | F15 | 迁移连带的 i18n 债务未点名（/twin 硬编码中文、疫病风险等级中文比较） |
| P2 | F16 | 围栏聚合"实现取简"有性能陷阱；旧端点退役策略缺失 |
| P2 | F17 | 地图红点数据源、详情页锚点定位、详情级 Controller 未走 FarmScoped 基类 |
| P2 | F18 | §5.4"Phase 3 决定"悬空引用，spec 无 phase 划分 |
| P3 | F19 | 底部导航红点现无实现，IA 变更表未列 |
| P3 | F20 | 展开态五格统计原型未实际绘制，保真验证缺对照 |
| P3 | F21 | 字段/枚举细节出入若干（assessedAt、AlertStatus、source 自由文本、"仿真"豁免范围） |

---

## P0 — 阻断级（与代码事实冲突，按现状实施会做错）

### F1："处理 = 标记已读"裁决与告警状态机冲突

**位置**：spec §8 裁决记录第 11 条、§4 S3a 操作行；原型 3a 操作行注脚"处理 = 标记已读并归入'今日已处理'"。

**代码事实**：

- "已读"是 **per-user 阅读标记**：写 `alert_read_status` 表，`Alert.status` 不变（`AlertController.java:86-91` → `markRead`；`AlertApplicationService.java:77-82` 读回时 join 阅读状态）。
- 真正让单据离开 ACTIVE 的是 **dismiss**：ACTIVE→DISMISSED、`resolvedType=MANUAL_DISMISS`，且**仅 OWNER/B2B_ADMIN 可调**（`AlertController.java:94-100` 的 `@PreAuthorize`）。
- 自愈链路按 ACTIVE 匹配：`HealthAlertBridgeService.syncRule()` 状态回落时调 `RanchCommandPort.resolveAlert(livestockId, type)`，只查 `status=ACTIVE` 的单（`RanchCommandPortImpl.java:40-49`）。
- `AlertStatus` 枚举只有 `ACTIVE / DISMISSED / AUTO_RESOLVED`，没有"已处理"。

**后果**：若按裁决把"处理"实现为 markRead——单据永远是 ACTIVE，自愈比对反复命中、对账行"活跃健康单 Y 张"永不收敛、告警中心数字只增不减；若实现为 dismiss——则普通牧场角色（非 OWNER）点"处理"会被 403 拒绝，原型操作行对一线员工不可用。两条路都是错的。

**建议**：spec 修订时重新定义"处理"：(a) 状态语义 = dismiss（ACTIVE→DISMISSED），"归入今日已处理"由 `resolvedAt/resolvedType` 派生查询，不新增状态机；(b) 明确角色矩阵——dismiss 权限是否下放到农场员工角色，还是"处理"对非 OWNER 降级为 markRead 并在 UI 区分；(c) 同步修订原型注脚文案。

### F2：AI 评估链路当前被禁用，spec 全部 AI 元素的前提未成立

**位置**：spec §4 S1（AI 单行卡）、S2（行内 AI 徽章）、S3a（AI 观察三格）、S5（AI 排行）、§5.3（档位映射）。

**代码事实**：`HealthApplicationService.processTelemetry()` 中 `healthAnomalyService.assess()` 调用**整段被注释禁用**（`HealthApplicationService.java:146-153`），注释原文："REQUIRES_NEW transaction corruption under backlog caused all telemetry processing to fail. TODO: move assess() to async scheduler."即现网遥测不会触发 AI 评估，`anomaly_scores` 无新增产出，AI 徽章/观察/排行全部只能吃到历史存量（且多为 DATAGEN 来源）。

spec 关联栏提到"NIX-243（AI 链路恢复，PR #110）"，但正文未声明 NIX-245 对 NIX-243 的**硬依赖与先后关系**，§5 后端契约也未把"恢复评估调度"列为任务。

**建议**：spec 显式写明：(a) 前置依赖——NIX-243 合入并验证 AI 评分恢复产出，否则 S2/S3a/S5 的 AI 列以空态/降级文案交付（需补空态设计）；(b) 顺带修正 AGENTS.md 已警示的"合成数据不得混充生产效果"——AI 档位展示的数据来源标注（RULE/AI/DATAGEN）策略。

---

## P1 — 高优先级（进入 plan 前必须澄清/修订）

### F3：健康率修复"实现时定位"过于含糊，根因与位置已可确定

**位置**：spec §5.7"修 105% 的根因（分子含已恢复/重复计数，实现时定位）"。

**代码事实**：健康率有**三处**实现，口径不一——

- `HealthApplicationService.getOverview()`（`:449-453`）与 `getStats()`（`:915-919`）：分子 = farm 下**全部** `health_snapshots` 中 NORMAL 的数量，分母 = 活体牲畜数，**未过滤已删除牲畜遗留的陈旧快照** → healthyCount > total 时 rate > 1.0。105% 根因即此。
- `HealthQueryPortAdapter.getHealthOverview()`（`:53-72`）与 `RanchOverviewApplicationService.buildHealthOverview()`（`:268-318`）：**已修复**，用 activeLivestockIds 过滤快照，注释明确 "otherwise healthyCount / total can exceed 1.0"。

**风险**："实现时定位"把已确定的信息重新变成未知数，且若只修 `/health/overview` 一处，牧场页（ranch 侧已修）与健康接口仍不同源——直接违反 spec §1"三屏数字同源"目标。

**建议**：spec 直接写明：统一修复 `getOverview` 与 `getStats` 两处（套用 activeLivestockIds 过滤模式），并明确"观察态算健康"的枚举集合落在哪个共享函数，避免三处各自实现再次漂移。

### F4：自愈任务引用不存在的方法名与形态

**位置**：spec §5.6"复用 NIX-243 的 resolveAlertsBySource 模式"。

**代码事实**：`resolveAlertsBySource` 在 main 代码中**不存在**（全仓仅 spec 文档自身命中）。等价的既有模式是 `RanchCommandPort.resolveAlert(livestockId, alertType)`（`RanchCommandPortImpl.java:40-49`，按 (livestock, type, ACTIVE) 批量 autoResolve），由 `HealthAlertBridgeService.syncRule()` 在遥测摄入时**事件驱动**触发。health 模块**没有任何 `@Scheduled`**。

事件驱动模型有固有缺口：设备停报 → 无摄入事件 → 状态不回流 → 残留 ACTIVE 单永不关闭。spec 的每小时兜底扫描正是补这个缺口，**方向正确**，但应写明：(a) 复用的具体类与方法名；(b) 这是 health 模块首个定时任务——调度器归属、多实例部署下的并发、与事件驱动路径重复 autoResolve 的幂等性（`autoResolve()` 对非 ACTIVE 单是否安全）。

### F5："✓ 对上了"判定规则缺失；开单不去重，X≠Y 是常态

**位置**：spec §4 S1 对账行、S2 对账条；§5.1 数据源。

**代码事实**：`RanchCommandPortImpl.createAlert()`（`:25-37`）**直接 save，不按 (livestock, type, ACTIVE) 去重**；AI 侧仅有 Redis TTL 去重键（`HealthAnomalyService.java` 第 6 步），TTL 过期可再开。且 AI 开单把 `abrupt_change/circadian_disruption` 映射为 `TEMPERATURE_ABNORMAL`（`:151-157`）——与规则引擎开的是**同一 type**。一头发烧牛同时持有规则单 + AI 单两张 ACTIVE 是预期内情形。

**后果**：对账行"场景异常 X 只 · 活跃健康单 Y 张 ✓ 对上了"中 X（快照口径的异常牛数）与 Y（ACTIVE 单数）天然多对多，"对上"若无定义，上线即常红，反而损害信任。

**建议**：spec 定义对账语义——例如按 (livestock, 场景族) 去重后比对（X = 异常牛数，Y' = 有 ACTIVE 单的牛数，单牛多单折叠），或对"开单去重"立新规（同牛同 type 有 ACTIVE 不再开）。两者择一或组合，但必须写进 spec。

### F6：详情页常态与多病程并存形态未定义

**位置**：spec §4 S3a；原型仅画了"发烧牛单病程卡"一态。

**缺口**：(a) **健康牛**（无 ACTIVE 健康单）进入详情页时，健康区显示什么——现有"体温/活动量/反刍三格卡"（`livestock_detail_page.dart:819-873`）是保留为常态态还是被区块取代？(b) 同时发烧 + 发情高分等多场景并存时，病程卡多张并存还是只显示最严重一张？排序规则？(c) 单牛同 type 多张 ACTIVE 单（见 F5）时，一张病程卡如何承载多单、头部"N 张活跃单"与卡的关系？这是详情页最高频的两种形态，spec 未覆盖，plan 无法拆任务。

### F7：疫情全场单与 episodes 牛级聚合模型冲突

**位置**：spec §5.1（episodes 按牛聚合，scene 含 epidemic）、§5.5（全场 EPIDEMIC 预警单）。

**代码事实**：EPIDEMIC 预警单是 **farm 级**——`AlertApplicationService.createAlert(farmId, type, ...)` 重载即 livestockId=null（`:55-59`）。而 episodes 端点声明的返回模型是"每头牛一条 {livestockId, ...}"。全场单进不了牛级聚合：scene=epidemic 时 episodes 返回什么？疫病管理台对账条原型是"全场异常率 0.0% · 阈值 10% ✓ 安全"（与其他三台"N 只·M 张"不同构），spec §5.1 却写"管理台四页共用"。另外恢复判定"率回落 <5% 自动解决"（§5.5）对全场单无快照状态可比对，需专用判定逻辑，与 §5.6 自愈任务的关系未说明。同场已有 ACTIVE 疫情单不重复开的去重键（farmId+type+ACTIVE）也应写明。

### F8：密接追踪无运行时写入路径，"保留"的是空壳

**位置**：spec §2（疫病管理台"密接示例"）、§4 S3a 未提但原型屏 5 与说明面板均展示密接；§8 未涉及。

**代码事实**：`contact_traces` 表、实体、风险评分（`HealthApplicationService.java:860-881`）、四个端点（`EpidemicController.java:17-40`）齐全，但**没有任何运行时写入方**——只有 V21/V31 种子 INSERT 和 mark/unmark 的 UPDATE。生产数据下密接名单永空。

**建议**：spec 明确本期范围——补采集/写入路径（GPS  proximity 计算是新功能，工作量不小），还是明示"UI 保留、数据空态"，并把空态文案列入 §6。

### F9：S5"谁最需要关注"排行页无原型蓝本

spec 头部声明原型"1:1 为实现蓝本"，§3 令牌依赖 prototype-to-flutter-fidelity 解析；但原型六屏**不含排行页**，只有入口文案"谁最需要关注 ›"。按 AGENTS.md feature 工作流（HTML 原型 → spec → plan），S5 缺第一环：无视觉规格、无令牌来源、保真验证无对照。**建议**：补原型第七屏，或将 S5 降级为"复用管理台行组件的简单列表"并在 spec 写明豁免保真对照。

### F10：门控矩阵不完整；"零删除"与"禁用词"两条裁决直接冲突

- **遗漏**：现有"疫病密接追踪整页 Premium+"（`epidemic_contact_page.dart:23-25`）未列入 §7 矩阵；密接迁入详情页疫病区块后 Premium+ 门控是否随迁，无裁决。
- **冲突**：裁决 #6"详情页现有功能零删除"vs §6 禁用词（评分百分比/有效样本/模型名不上界面）。现有 `AnomalyScoreCard`（三场景详情页均挂载，Standard+）直接展示 `score*100%`、`nEff"有效样本"`、`capabilityUsed"评估方式"`（`anomaly_score_card.dart:66-78`）。迁入详情页 AI 观察区块后，这些技术字段是删（违反零删除）还是留（违反说人话）？spec 未裁决。**建议**：补一条裁决，例如"AI 观察区块按原型三格交付；贡献度/样本数/能力等技术字段本期移除出 UI，数据仍由端点返回保留"。

### F11：路由方案不完整

**代码事实**：/twin 现有 **9 条**子路由（`app_router.dart:164-230`）：/twin、/twin/fever、/twin/fever/:id、/twin/digestive、/twin/digestive/:id、/twin/estrus、/twin/estrus/:id、/twin/epidemic、/twin/epidemic/contacts/:id。spec §2 只覆盖 "/twin 及子路由重定向" 与 "/twin/{scene}/{id} → /livestock/{id}" 两类，未定义：

- 四个**管理台**自身的 URL——驻留 /twin/fever 等（/twin 已删，路径语义悬空）还是迁新路径（如 /health/fever）？入口从牧场页概览场景卡进入，路由是 IA 的一部分，应写明。
- /twin/epidemic/contacts/:id（密接追踪页）的去向——退役重定向到 /livestock/{id} 疫病区块，还是保留（与 F8、F10 联动）？
- 深链重定向带"健康区锚点"参数（如 /livestock/{id}?section=health）的路由契约未写（与 F17 联动）。

建场向导落点改 /ranch 一条与现状核对无误（现 `farm_creation_wizard_page.dart:47-51` 为 `go('/twin')`）。

---

## P2 — 中优先级（plan 阶段前补齐可避免返工）

### F12：AI 档位映射实施方未决 + finding 词表键与枚举对不上

- §5.3"前端，或后端 band 字段"二选一未决。档位将在详情页、管理台徽章、S5 排行、告警中心**四处**展示，前端映射会让口径漂移风险常驻；建议收敛为**后端 band 字段**唯一来源，与 §5.2 aiAlertCount 同源。另注意现状只有 0.7（开单）与 0.85（CRITICAL 分界）两个阈值，0.3 档是全新逻辑。
- finding 词表（§5.3）的映射键写的是中文"骤升"，实际枚举值为 `abrupt_change / circadian_disruption / multivariate / normal`（`AnomalyScoreJpaEntity` 注释与 `mapAnomalyTypeToAlertType` 可证）。词表应以枚举值为键逐个给出译名；`normal` 档的"发现"文案（显示什么还是不显示）未定义。

### F13：发情管理台"异常"口径未定义

现有发情列表是**全部 score>0 的牛按分降序**（`HealthApplicationService.java:644-670`），无 NORMAL 过滤。S2"只列异常与相关牛"对发情需要新阈值（多少分算"高分/待配种"）；而 §5.7 又说"estrus 高分不计入异常"（健康率口径）——两个口径各自合理但需分别写清，避免实施把健康率口径误套到管理台过滤上。

### F14：告警中心现状描述不准；spec 漏写原型已有元素

- spec §2/S4 称移除"顶部统计块"，原型屏 4 注解说移除"活跃/未读/三级别/对账行"；实际代码里统计头是**三级别 cells + 一行对账文案**（`alert_summary_header.dart:70-78`），没有"活跃/未读 hero"——移除对象应据实写，避免实施时找不到对照物。
- 原型有而 spec 未写：发热管理台 appbar 的**"只看未读"**按钮（屏 2）、告警中心列表的**日期分组头**（屏 4"今天 3 条"）。实施以原型还是 spec 为准，需一句话约定（建议：spec 补录）。

### F15：迁移连带的 i18n 债务未点名

- /twin 页五格统计与场景卡标题**硬编码中文**（`twin_overview_page.dart:139-147,163-190`），迁入牧场页概览时必须同步入 arb——§6 虽要求"全量 i18n"，建议把"迁移内容先还债"列为显式任务，否则保真验证过了、i18n 校验挂了。
- `EpidemicAnalysisService.assessRiskLevel()` 返回硬编码中文"警戒/关注/正常"（`:53-59`），前端 `epidemic_page.dart:102` 按中文串比较——疫病屏改造必须一并改为枚举 key + MessageSource/l10n，否则英文版直接破。

### F16：围栏聚合"实现取简"有陷阱；旧端点退役策略缺失

- §5.8"或复用 summary + 前端分组；实现取简"：`GET /alerts` 无 groupBy、有分页（`AlertController.java:29-54`），前端分组需全量拉取，72 条可行、上千条即破。建议直接定为后端聚合或限定时间窗+上限，不要留给实施"取简"。
- episodes 端点上线的"管理台四页共用"后，旧四列表端点（/health/fever、/health/digestive、/health/estrus、/health/epidemic）与三个 detail DTO 端点的去留、其他消费方（DashboardController、ranch overview）是否切换，应有退役/兼容策略，哪怕一句"旧端点保留一期，下迭代下线"。

### F17：地图红点数据源、详情页锚点定位、FarmScoped 基类缺口

- S1"有活跃健康单的牛加红点"：现 marker 以整点变色表达健康状态（`livestock_map_marker.dart:6-15`），无独立 badge；红点标志需随地图数据源下发（episodes 或 summary 扩展），spec 未指出来源。
- "健康条目直达详情页健康区锚点"（S4）在 Flutter 需滚动定位机制（ScrollController/ensureVisible），且详情页 30s 自动刷新（`livestock_detail_page.dart:43-69`）会重建区块——锚点定位与自动刷新竞态需说明。
- 详情级 Controller（Livestock/Fever/Digestive/Estrus/Anomaly detail）目前**未继承** FarmScoped* 基类（family 按 livestockId 键），按 AGENTS.md §5 规则，本次详情页大改应一并处理牧场切换刷新。

### F18：§5.4"Phase 3 决定"悬空引用

spec 全文无 phase 划分，"Phase 3 决定"无从落地。合并端点 vs 前端并行取数应在本 spec 裁决（§5.4 已写明倾向合并，直接定即可）；若执意推迟，应写明裁决时机与裁决人。

---

## P3 — 低优先级（补全项）

### F19：底部导航红点现无实现

原型屏 1 底部"牧场"tab 有 badge 8，§5.9 提到"导航红点"；实际 `main_shell.dart:128-145` 仅两个 FilledButton 式 tab、无角标机制。IA 变更表（§2）未列此项新增。

### F20：展开态五格统计原型未实际绘制

S1"面板展开态顶部露出五格统计"在原型屏 1 中仅有 sublabel 文字提及，画面未画出展开态——保真验证缺对照物，且五格与四张告警卡同屏的排布未定义。

### F21：字段/枚举细节出入

- `anomaly_scores` 无 `assessedAt` 字段，`AiAnomalySummary.assessedAt` 实际映射 `createdAt`（`HealthAnomalyService.java:147`）——spec 写 DTO 时直接用 createdAt 语义即可。
- `AlertStatus` 为 ACTIVE/DISMISSED/AUTO_RESOLVED；spec §5.6 的 "AUTO_RESOLVE" 是方法名不是状态值，措辞建议对齐。
- `Alert.source` 是自由文本 String（实际值 RULE/AI/DATAGEN），非枚举——按 source 筛选需容忍自由文本。
- "仿真/DATAGEN 改'演示数据'"（§6）：现"仿真"字样仅存在于 `/admin/datagen` 管理员控制台（app_zh.arb:3865-4034），业务页本无；建议明示控制台豁免，避免实施误改管理员工具文案。

---

## 核对无误、值得肯定的点

1. 原型六屏与 spec §4 组件规格逐屏一致；§3 令牌表与原型 `:root` 逐值吻合（含 badge/reconcile 两个派生令牌），保真流程可解析。
2. spec 对现状的关键判断准确：EPIDEMIC 有枚举零创建（`AlertType.java:10`，全仓无创建路径）；健康率 >100% 确实存在；用药记录功能不存在（前端 grep 无命中，裁决"本期移除"是清理原型超前两不是砍功能）。
3. 数据底座齐全：episodes 所需的 alerts + health_snapshots + anomaly_scores + 时序仓库全部在位；GROUP_HEALTH 健康类筛选常量已内置，可直接复用。
4. 深链重定向基础好：9 条 /twin 子路由与三张场景详情页真实存在，重定向前提成立。
5. i18n 基线良好：app_zh/app_en.arb key 集合零差异，后端 messages 三 properties 齐备，新增 key 走既有同步流程即可。
6. 裁决记录（§8）13 条完整可追溯，与原型说明面板的冲突裁决表一致。

---

## 复核附记（2026-09-23，ZCode 独立核实）

对本评审 34 项代码断言（后端 A1-A20 + 前端/原型 B1-B14）做了独立核实：**31 项完全属实**（行号偏差 ±10 内），spec 转述逐条准确，"有条件通过"结论成立。三处细节修正（已落入 spec v1.1）：

1. **F21/A19 source 值集**：字面量 "AI" 从未作为 source 写入——AI 开单写的是遥测源字符串（AGENTIC_PLATFORM/THINGSBOARD 等，`HealthAnomalyService.java:123-125`），按 source='AI' 筛选会**全部漏掉**。比评审表述更严重，spec v1.1 已升级为 origin 枚举列方案（§5.10/裁决 22）。注意 nix/243 分支的 source 约束修复合并时需对齐。
2. **F12/A14 枚举表述**：abrupt_change 等四值是 String 列的注释约定非真枚举；全仓无 finding 字段。"词表以实际值为键"结论仍成立。
3. **F15/B13 补一处**："仿真"另见于 app_zh.arb:4741（admin 网关页脚注，区间外），语义仍属管理员侧。

另两项评审未覆盖：farm 级 `createAlert(farmId,...)` 重载当前无调用方（死代码，F7 实施时需接上）；**NIX-245 工单号冲突**（已改号 NIX-246）。

**处置**：spec 已修订至 v1.1（逐条回应 F1-F21，新增裁决 14-22）；plan 已同步改号并对齐 v1.1；进 plan 实施前的前置 = NIX-243 合并验证 + 原型补第七屏与展开态。
