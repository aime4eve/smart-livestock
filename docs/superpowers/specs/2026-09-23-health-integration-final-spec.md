# 健康整合最终形态 Spec（NIX-246）

> 状态：v1.2（2026-09-24：S1 概览按方案 D「晨报看板」重定义——裁决 23；其余沿用 v1.1）
> 原型（视觉蓝本）：`docs/prototypes/health-scenario-alert-integration-prototype.html`（八屏：原六屏 + 屏 1b 概览展开态 + 屏 6 AI 排行；**屏 1/1b 2026-09-24 按方案 D 重绘**；三方案对照稿 `docs/prototypes/ranch-overview-redesign-prototype.html` 存档）
> 关联：NIX-243（AI 链路恢复，PR #110——**本 spec 的硬前置**，见 §0）、NIX-244（LINK_QUALITY 约束，另行修复）
> 评审：`docs/superpowers/reviews/2026-09-23-health-integration-final-spec-review.md`（21 条发现；v1.1 每处以 (F#) 标注回应）

## 0. 前置依赖与降级策略（F2，P0）

- **硬依赖**：NIX-243（PR #110）合入 master 并在真实环境验证 `HealthAnomalyScheduler` 恢复 `anomaly_scores` 产出后，S2/S3a/S5 的 AI 元素方可交付。
- NIX-243 未就绪期间：AI 单行卡、AI 档位徽章、AI 观察三格、S5 排行页以**空态交付**——空态文案见 §6；不展示历史存量评分（多为 DATAGEN 来源，AGENTS.md 禁止合成数据混充效果）。
- AI 元素的数据来源标注：按 §5.10 `origin` 列（RULE/AI）区分，"演示数据"标注策略见 §6。

## 1. 目标（一句话）

一次发烧 = 一条病程 = 一个工作台条目 = 详情页一张病程卡；三屏数字同源；界面说人话。

## 2. 信息架构变更

| 原页面 | 去向 |
|---|---|
| 数智孪生页 /twin | 删除；内容迁入牧场页概览页签；/twin 及 9 条子路由重定向（映射表见 §2.1）；建场向导落点改 /ranch |
| 发热/消化/发情详情页（3 张） | 退役；全部内容迁入牲畜详情页对应区块；深链 /twin/{scene}/{id} → /livestock/{id}?section=health |
| 发热/消化/发情/疫病场景列表页（4 张） | 升级为管理台：只列异常与相关牛，正常牛折叠；新路由 /health/fever、/health/digestive、/health/estrus、/health/epidemic（F11） |
| 牲畜详情页 | 升级为唯一牛级详情：病程卡内嵌 + 消化/发情区块 + 位置/通讯距离/设备绑定（原样保留重排） |
| 告警中心 | 移除三级别统计 cells + 对账行（现 `alert_summary_header` 实际形态，F14）；两行三标签页（围栏放牧/动物健康/设备健康）；健康条目直达详情页；围栏牛×围栏聚合（后端聚合，§5.8） |
| 疫病密接追踪整页 /twin/epidemic/contacts/:id | 退役重定向 /livestock/{id}?section=health（密接数据本期空态，见 §5.9/F8）；Premium+ 门控随迁详情页疫病区块（F10） |
| 底部导航 | 新增"牧场"tab 未读红点（badge 机制现无实现，属新增；数据源 = summary 未读数）（F19） |

### 2.1 /twin 旧路由重定向映射（9 条，F11）

| 旧路由 | 去向 |
|---|---|
| /twin | /ranch |
| /twin/fever、/twin/digestive、/twin/estrus、/twin/epidemic | /health/fever、/health/digestive、/health/estrus、/health/epidemic |
| /twin/fever/:id、/twin/digestive/:id、/twin/estrus/:id | /livestock/{id}?section=health |
| /twin/epidemic/contacts/:id | /livestock/{id}?section=health |

深链锚点契约：`?section=health` 由详情页解析后滚动定位健康区（定位机制与 30s 自动刷新的竞态处理见 §5.11）。

## 3. 设计令牌（原型 :root，prototype-to-flutter-fidelity 解析）

| 令牌 | 值 | 用途 |
|---|---|---|
| --primary | #2F6B3B | 主色/选中态 |
| --danger / --warning / --success / --info | #C2564B / #D28A2D / #4C9A5F / #4A7F9D | 警戒三色/信息 |
| --estrus / --fever / --digestive / --epidemic | #C25689 / #D97B29 / #8D6E4F / #2E7D74 | 四场景主题色 |
| --badge-bg | #C2564B（danger 派生） | 场景卡活跃单角标 |
| --reconcile-bg / --reconcile-text | rgba(76,154,95,.08) / #3D7D4E（success 派生） | 对账行（方案 D 起仅不一致态，改 warning 派生琥珀色） |
| --radius-sm/md/lg | 8/12/16px | 圆角三级 |
| --shadow-card / --shadow-sheet | 同告警 V2 | 卡片/面板阴影 |
| 间距 | --xs..--xxl = 4/8/12/16/24/32px | AppSpacing 对齐 |
| **方案 D 新增（裁决 23）** | Hero 渐变 `#1C3F25 → #2F6B3B → #3E7F4C`（135°） | Hero 晨报卡背景 |
| | Hero 环形进度 `#8FD694` / 轨道 `rgba(255,255,255,.22)` | 健康率环形 |
| | 瓷砖渐变（红）`#B3453B → #C9664F` | 围栏告警瓷砖 |
| | 瓷砖渐变（橙）`#C07A22 → #DB9C40` | 健康告警瓷砖 |
| | Hero chip 底 `rgba(255,255,255,.12)` | 卡内小指标 |

除方案 D 渐变外无全新色相；「新增/迁入/融合」标注色仅评审用，**不进实现**。

## 4. 组件规格（按屏）

**S1 牧场页·概览（方案 D「晨报看板」，裁决 23）**：上拉面板三页签不变（概览/围栏/告警）。概览自上而下四段（1:1 蓝本 = 原型屏 1/1b，展开态同构、无五格统计）：
1. **Hero 晨报卡**（深绿渐变 135°、白字、--shadow-elev）：首行日期 + 牧场名（**不接天气 API**）；主体左侧按健康率生成标题（≥95%「牧场一切平稳」，否则「N 只需要关注」）+ 副标（"56/58 只健康 · N 个围栏需要巡查"，围栏数 = 活跃围栏告警按围栏去重）；右侧健康率环形进度（#8FD694，径 62-76px 按屏宽）；底部两枚 chip：头在养 / 设备在线率。
2. **需要处理**段：小节标题（红色左标条）右侧"共 N 起"；一行三色瓷砖（等分、点击进对应告警分类）：**红**=围栏（渐变红底白字大数字 + 未读白底角标）、**橙**=健康（渐变橙底）、**白**=设备（数字 0 时灰数字 + 绿色"正常"小字，>0 时升为橙底）；每枚一行小字副标（"2 个围栏越界"/"发热为主"）。
3. **健康管理**段：2×2 场景卡（图标底 ×场景主题色 12% 透明、名称、右上状态胶囊——平稳=绿 / N 只异常=橙 / 含严重=红）；卡底一行人话副标（"2 只发烧 · 4 只低热，1 只持续超 6 小时"/"反刍频率均在正常区间"）；点击 → /health/{scene}。
4. **AI 观察**段：单卡（🤖 + 标题 + "谁最需要关注 ›"入口 → S5 + 摘要句"N 只持续观察 · …"+ 右侧档位胶囊）；NIX-243 未就绪时空态（文案 §6）。
对账提示（§5.4 口径）**仅当场景异常数 ≠ 活跃单数时出现**（warning 派生琥珀条："场景异常 N 只 · 活跃健康单 M 张 · 差 K（可能有单未开出，建议巡检）"），一致时不渲染。地图标记：有活跃健康单（origin 任一）的牛加红点（数据源见 §5.1 hasActiveHealthAlert）。

**S2 管理台（×4）**：对账条 → 异常牛行（图标/编号/当前值+持续+趋势箭头/AI 档位徽章/单据级别 pill/未读绿点）→ "今天已恢复"组（降透明度；由 resolvedAt/resolvedType=MANUAL_DISMISS/AUTO_RESOLVED 派生查询，F1）→ 折叠"展开全部"。appbar 含**"只看未读"按钮**（原型屏 2 已有，补录入 spec，F14）。发情管理台语气为配种提醒，对账条口径见 §5.7（F13）。疫病管理台：安全状态条 + 监测规则卡 + 密接示例（密接本期空态文案，F8）。

**S3a 详情页·健康区**（形态定义，F6）：
- **常态（无 ACTIVE 健康单）**：保留现有体温/活动量/反刍三格卡为常态态，+ AI 观察三格（可用时）；无病程卡。
- **病程态（≥1 张 ACTIVE 健康单）**：每张单一张病程卡纵向排列，排序 = severity（CRITICAL>WARNING）→ 场景固定序（fever→digestive→estrus）；头部"活跃单 N"= ACTIVE 健康单总数（同牛同 type 经 §5.5 去重后仅一张，跨 type 可多张）。
- 病程卡内容：四格值（当前/基线/持续/最高）+ 72h 趋势图（发烧段标红）+ AI 观察三格（结论档位/发现/更新）+ 一句话解释 + 时间线（开单→AI→待处理）+ 操作行 + 门控条。
- **操作行（F1，P0）**：处理（primary，= **dismiss**：ACTIVE→DISMISSED，"归入今日已处理"由 resolvedAt 派生查询，不新增状态机）/ 忽略（= markRead，仅驱动未读状态）/ 定位 / 轨迹。**权限**：dismiss 的 @PreAuthorize 从 OWNER/B2B_ADMIN 扩展到 WORKER（一线员工本就承担告警确认）；markRead 保持全员。原型注脚"处理 = 标记已读"同步改为"处理 = 关闭该单"。
- 消化区块：三格值 + 胃蠕动曲线 + **强度热力图（Standard+，迁移）**。发情区块：评分曲线（Premium+）。位置卡（末次定位+轨迹）、通讯距离卡、设备绑定卡（绑定/解绑/电量/信号/DevEUI）原样保留。30s 自动刷新保留（锚点竞态见 §5.11）。

**S4 告警中心**：Appbar（全部已读）→ 两行三标签页（上：图标+名称；下：大数字；未读红角标；选中绿底）→ 列表（**含日期分组头**，如"今天 3 条"，原型屏 4 已有，补录入 spec，F14）。健康条目 = 通知行（点击 → /livestock/{id}?section=health）；围栏 tab = 牛×围栏聚合卡（默认聚合，点开明细，数据来自 §5.8 后端聚合）；设备 tab = 现有形态。

**S5 AI 排行**："谁最需要关注"列表：按 AI 档位降序（警惕>留意>平稳），行 = 编号/档位徽章/发现/更新时间，点击进详情页。**原型缺第七屏，进 plan 前补画后按屏实施**（F9，裁决 21）；未补前 S5 不开工。

## 5. 后端契约

1. **病程聚合端点** `GET /farms/{farmId}/health/episodes?scene=fever|digestive|estrus&include=recovered`：每头牛一条 = {livestockId, code, 当前值组, 持续, 趋势, 状态, 活跃单（type/severity/unread）, AI{score,band,finding,createdAt}}（F21：字段名直接用 createdAt 语义）。数据源：alerts（ACTIVE 健康类）+ health_snapshots + anomaly_scores 最新 + 时序摘要。**发热/消化/发情三页共用；疫病页不走本端点**（F7，见 §5.6）。每行附 `hasActiveHealthAlert` 布尔（S1 地图红点数据源，F17）。
2. **健康总览扩展**：`GET /health/overview` 的 sceneSummary 各加 `activeAlertCount`，AI 卡加 `aiAlertCount`（与 /alerts/summary 同表同源，按 origin='AI' 过滤，见 §5.10）。
3. **AI 档位映射（后端 band 字段唯一来源，F12）**：`band` 由后端下发（steady <0.3 / watch 0.3-0.7 / alert ≥0.7），episodes 与 summary 同源，前端不做映射。0.3 为新增阈值常量（`ai.band.steady-threshold`，现状仅 0.7 开单与 0.85 CRITICAL 两档）。finding 词表以实际取值为键（String 列约定值）：`abrupt_change`→体温突然升高、`circadian_disruption`→作息规律异常、`multivariate`→多项指标同时跑偏；`normal` 不显示"发现"文案（显示"指标平稳"）。
4. **详情页聚合（定案：合并端点，F18）**：fever/digestive/estrus detail DTO 合并为详情页 health 区块单端点，减请求数。
5. **开单去重（新规，F5）**：`RanchCommandPortImpl.createAlert()` 内部增加 (livestockId, type, status=ACTIVE) 查重——同牛同 type 已有 ACTIVE 不再开（规则与 AI 两个入口统一收敛，替代现有上游 hasActiveAlert 单点判断与 AI 侧仅 Redis TTL 的去重）。
6. **疫情（farm 级，F7）**：7 天窗口异常率 >10% → 全场 EPIDEMIC 预警单（接 `AlertApplicationService.createAlert(farmId,...)` 现有无调用方重载，livestockId=null）；去重键 = (farmId, EPIDEMIC, ACTIVE)；恢复判定由 §5.7 自愈任务专用分支处理（率回落 <5% → autoResolve）；**疫病管理台走专用端点** `GET /farms/{farmId}/health/epidemic/summary`（异常率/阈值/安全状态/密接计数），与其他三台不同构（原型即如此）。
7. **自愈任务（F4 更正）**：新增 `HealthAlertReconcileScheduler`（health 模块**首个** @Scheduled 任务，每小时）：比对快照状态与 ACTIVE 健康单，已恢复按类型映射调 `RanchCommandPort.resolveAlert(livestockId, alertType)`（现有方法，仅匹配 ACTIVE，重复调用幂等）；farm 级疫情单走率回落分支。多实例部署并发防护沿用项目现有调度策略（若无则 plan 阶段引入 ShedLock/单实例约束）。~"复用 resolveAlertsBySource 模式"表述作废（该方法不存在）~。
8. **健康率修复（定位明确，F3）**：统一修复 `HealthApplicationService.getOverview()` 与 `getStats()` 两处——套用 `HealthQueryPortAdapter` 已有的 activeLivestockIds 过滤模式；"观察态算健康"的枚举集合收敛到共享函数（单一实现，三处调用），消除 ranch 侧与 health 接口不同源。
9. **密接追踪（F8）**：本期**不补采集/写入路径**（GPS proximity 属新功能，另立工单）；UI 保留、数据空态（文案见 §6）。现有 mark/unmark 与四端点保留。
10. **origin 列（source 筛选重设计，F21）**：alerts 新增 `origin` 枚举列（RULE/AI）。AI 开单写 origin=AI（source 自由文本保留遥测源做溯源——**现状 source 从无字面 "AI" 值，AI 单写的是遥测源字符串，按 source='AI' 筛选会全部漏掉**）；规则单写 origin=RULE。历史回填：健康类单 source='RULE'→RULE，其余非空→AI；fence 单（source='DATAGEN'）→RULE。健康类筛选/GROUP_HEALTH 联动改按 origin。**注意与 NIX-243 的 source 约束修复合并时对齐**。
11. **围栏聚合（定案：后端聚合，F16）**：/alerts/summary 扩展（或新端点）返回牛×围栏聚合，前端不拉全量列表分组（GET /alerts 分页接口不适合前端聚合）。**旧端点退役策略**：/health/fever、/health/digestive、/health/estrus、/health/epidemic 四列表端点与三个 detail DTO 端点保留一期（DashboardController、ranch overview 等内部消费方不切换），下迭代评估下线。
12. **详情页锚点与刷新竞态（F17）**：`?section=health` 用 ScrollController.ensureVisible 定位；30s 自动刷新重建区块后仅在"本次会话首次"或"用户手动进入"时重新定位，刷新不抢占滚动位置。详情级五个 Controller（livestock/fever/digestive/estrus/anomaly detail）本次一并迁移 FarmScopedAsyncNotifier 基类（AGENTS.md §5），family 键含 farmId 维度。

## 6. 文案规范（人话原则，全量 i18n 中英双语）

- 禁用词上界面：评分百分比（主文案）、有效样本、模型名（health_l1/nEff/capability）、"仿真/DATAGEN"（改"演示数据"）。**处置（F10 冲突裁决）**：现 `AnomalyScoreCard` 的 score%/nEff/capabilityUsed 字段移出 UI（改造成"AI 观察三格"），数据仍由端点返回不删——"零删除"指**功能与数据零删除，展示形态可重组**（裁决 20）。"仿真"改写仅限业务页；/admin/datagen 管理员控制台与 admin 网关页脚注**豁免**（F21）。
- AI 空态文案（F2）："AI 观察暂未开启，恢复后自动展示"（排行页同义）。
- **方案 D 文案生成规则（裁决 23）**：Hero 标题按健康率生成——≥95%「牧场一切平稳」/ 其余「N 只需要关注」；Hero 日期行 = 日期 + 牧场名（不接天气）；瓷砖副标一句话点主要矛盾（"2 个围栏越界"/"发热为主"/"正常"）；场景卡副标 = 人话摘要（发热拆发烧/低热/持续超时；平稳场景固定语"反刍频率均在正常区间"等）；对账提示仅不一致时出现。
- 密接空态文案（F8）："暂无密接记录——接入位置采集并标记病牛后自动生成"。
- **i18n 还债显式任务（F15）**：孪生页迁移内容（五格统计、场景卡标题硬编码中文）入 arb；`EpidemicAnalysisService.assessRiskLevel()` 改返回枚举值（如 VIGILANT/WATCH/NORMAL）+ MessageSource，前端 `epidemic_page` 改按枚举比较（现按中文串比较，英文版必破）。
- AI 三档状态词 + 一句话解释常驻详情页；管理台徽章只用档位词。
- 术语表见原型说明面板；新增 key 走 app_zh/app_en.arb 同步，gen-l10n 零缺失。

## 7. 门控保留矩阵

| 功能 | 档位 | 新家 |
|---|---|---|
| 发烧时长统计图 | Standard+ | 详情页病程卡门控条 |
| 消化强度热力图 | Standard+ | 详情页消化区块 |
| 发情评分曲线 | Premium+ | 详情页发情区块 |
| AI 观察区块 | Standard+ | 详情页 + 管理台徽章（徽章不门控，卡片详情门控） |
| **密接追踪**（原整页 Premium+，F10 补） | Premium+ | 详情页疫病区块 + 疫病管理台密接卡（门控随迁） |

## 8. 裁决记录（2026-09-23；1-13 为 v1.0 原裁决，14-22 为 v1.1 评审修订，23-24 为 2026-09-24 v1.2）

1. 孪生并入牧场（非互跳）2. A+B 一次到位 3. 详情页融合不跳转 4. 疫情本期补开单 5. 命名"发热管理/消化管理" 6. ~~详情页现有功能零删除~~（修订为裁决 20）7. 告警中心统计块移除、两行标签页 8. 场景一行四格紧凑 9. 界面说人话 10. 用药记录本期移除 11. ~~处理=已读~~（修订为裁决 14）12. 围栏牛×围栏聚合 13. 健康率观察态算健康
14. **处理 = dismiss**（F1/P0）：状态语义 ACTIVE→DISMISSED（resolvedType=MANUAL_DISMISS），dismiss 权限扩展到 WORKER；markRead 保留为"忽略"仅驱动未读；"今日已处理"由 resolvedAt 派生。
15. **NIX-243 硬前置**（F2/P0）：AI 元素依赖评估调度恢复产出，未就绪一律空态，不吃历史存量。
16. **开单去重新规**（F5）：同牛同 type 有 ACTIVE 不再开，规则+AI 统一在 createAlert 内收敛；对账行按"牛级折叠"比较（异常牛数 vs 有 ACTIVE 单牛数），相等 ✓，不等显示差异提示（驱动巡检），不视常红为错。
17. **详情页双态**（F6）：健康牛保留三格卡常态；病程态按 severity→场景序多卡排列。
18. **疫病页独立**（F7）：farm 级全场单 + 专用 summary 端点，不与三页共用 episodes。
19. **band 后端唯一来源**（F12）+ finding 词表以约定值为键 + normal 档显示"指标平稳"。
20. **零删除重定义**（F10）：功能与数据零删除、展示形态可重组；AI 技术字段（评分%/有效样本/评估方式）移出 UI，端点数据保留。
21. **原型补齐后再进 plan**（F9/F20）：~~第七屏 S5 排行页与 S1 展开态画面补画~~ **2026-09-23 已补并经用户确认**（屏 6 排行页 + 屏 1b 展开态），本前置关闭。
22. **origin 枚举列**（F21）：AI 筛选不依赖 source 自由文本；历史回填规则见 §5.10。
23. **概览视觉 = 方案 D「晨报看板」**（2026-09-24）：A+C 整合——Hero 晨报卡（渐变+健康率环形+两枚 chip）+ 一行三色告警瓷砖（红围栏/橙健康/白设备）+ 2×2 场景卡（胶囊+人话副标）+ AI 摘要卡。**五格统计取消**（裁决 21 的展开态五格作废，数字并入 Hero/瓷砖小标题/告警中心标签页）；对账提示由"常驻 ✓"改为**仅不一致时显示**（琥珀警示，修订裁决 16 的展示形态、口径不变）；场景入口保留一行四格还是 2×2 → 2×2（方案 D 内含）。背景：dash 四卡布局经三轮用户否决（"不美观/凌乱"），三方案高保真（A 晨报/B 分组/C 看板）用户选定 A+C 整合（对照稿 ranch-overview-redesign-prototype.html 存档）。
24. **Hero 标题生成规则**：健康率 ≥95% →「牧场一切平稳」；否则「N 只需要关注」（N = 总数×(1-健康率) 取整）。副标固定结构"X/Y 只健康 · N 个围栏需要巡查"。
