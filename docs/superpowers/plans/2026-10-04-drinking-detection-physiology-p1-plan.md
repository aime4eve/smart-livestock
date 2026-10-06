# 饮水行为检测 + 生理事件流 P1 实施计划

> Spec：`docs/superpowers/specs/2026-10-04-drinking-detection-physiology-p1-spec.md`（经两轮评审修订，**待用户确认**——确认后才进编码）
> 原型：`docs/prototypes/drinking-event-detection-prototype.html` v1.2（六屏）+ `docs/prototypes/physiology-events-p1-prototype.html` v1.2（两屏）——**UI 唯一事实源，已冻结**；壳宽已按三轮评审 P7 从 280 调整为 **390 逻辑视口**（与 compare_screenshots 默认及兄弟 plan 惯例一致，实现数值与原型同值可比）
> 设计令牌：`docs/design-tokens.md`（34 枚，skill 脚本提取，含 `--drinking` 三枚新增）
> 原则：生理事件流地基先行（T1a/T1b）→ L1 标定定参（T2）→ 检测内核（T3）→ 调度与回算（T4）→ API+Flutter 保真实现（T5）→ 真实回放（T6）→ 部署验收（T7）；每个 UI Task 走 prototype-to-flutter-fidelity 三阶段（规格卡→组件库克隆→截图对照），`compare_screenshots.py --target-width 390` ≥85%。
> 分支：`nix/256-drinking-physiology-p1`——**基座策略（三轮评审 P1，git 已核验）**：`SchedulerPoolConfig`（92ed1f64）不在 master（仅存在于 `nix/epidemic-mark-diseased`，该分支领先 master 27 提交）→ 自 master 建分支后 **cherry-pick 调度器修复三部曲 `c6cd5350`、`22136330`、`92ed1f64`**（可选附 `851608b4` 死因调查 docs）；跳过 build bump 与疫病业务提交；若疫病分支先行合并 master 则直接自最新 master 建分支并跳过 cherry-pick。T1 数据依赖已核验成立：`EpidemicWorkbenchService` 与 `V20260926100000` 迁移均在 master。
> 执行纪律：子智能体逐 Task 串行，不并发；每 Task 完成先过本 plan 验证步骤，再由主智能体评审后才进下一个。

## Task 0 · 保真基线与分支

1. 自 `master` 创建分支 `nix/256-drinking-physiology-p1`，随后 cherry-pick `c6cd5350 22136330 92ed1f64`（顺序保持）——`SchedulerPoolConfig` 就位是 T4 的前置； cherry-pick 冲突时以疫病分支版本为准。
2. 浏览器截取原型基线（**Playwright 390×844、DPR 2**，对齐兄弟 plan 惯例；截图对象为二轮评审修订后的最新原型，含状态屏）：
   - 饮水原型 6 屏 → `output/fidelity/drinking/prototype/screen-0{1..6}.png`
   - 生理小原型 2 屏 → `output/fidelity/physiology/prototype/screen-0{1..2}.png`
3. 提取规格卡：`docs/design-tokens.md` 已有令牌表；补充组件规格卡 `docs/superpowers/plans/spec-cards/drinking-*.md`、`physiology-*.md`（组件树 + 数值表 + 文案表，从原型 CSS 逐条提取，ZH/EN 文案表直接引用 spec §5 与原型 3b 节）。
4. 元素清单：饮水侧（详情卡/详情分节两图/5 状态态/锁定卡/图层 chips/告警行）+ 生理侧（记录卡三行/状态覆盖卡/sheet 六 chips/日期/备注/保存）与原型 DOM 一一对应。

**验证**：基线截图齐全（390×844）；规格卡数值与 `docs/design-tokens.md` 无冲突；元素清单逐项可勾；`git log` 确认三个 cherry-pick 提交在位且编译通过。

## Task 1a · 生理事件流 P1 后端（下篇地基）

1. Flyway 迁移（create-migration skill）：`physiology_events` 表——**对齐仓库 DDL 惯例**（范本 `V20260926100000__epidemic_contact_workbench.sql`：`TIMESTAMP` 非 TIMESTAMPTZ、`REFERENCES livestock/users(id)` 外键、`CHECK (event_type IN (...))`/`CHECK (source IN ('MANUAL','ALERT_CONFIRM'))`、`updated_at DEFAULT NOW()`）+ `uq_physiology_manual_dup` partial unique + demo 牧场 seed（2 头成母牛 CALVING，source=MANUAL）。**无 ended_at 列**（窗口结束权威=配对 RECOVERY）；**处置单侧不落本表**（读时合并，N3）。
2. 领域模型：`PhysiologyEvent`（聚合根）、`PhysiologyEventType` 枚举（六值）、`PhysiologySource`（MANUAL/ALERT_CONFIRM）、`PhysiologyWindow`/`PhysiologyStage` DTO（spec §9 已定义形状，含 sourceType 窗口出处标签）。
3. 端口与实现（**读时合并，N3**）：`PhysiologyQueryPort.activeWindows` / `activeWindowsForFarm`（B4，每日批防 N+1）/ `currentStage`——实现内部 UNION 两路：①手动 `physiology_events` 的 ILLNESS 按 §8 规则栈式配对 RECOVERY；②实时 JOIN `epidemic_dispositions`（`status IN ('PENDING','IN_PROGRESS')`→活动窗口起点=created_at；COMPLETED→completed_at 止；CANCELLED 含 SOURCE_UNMARKED 软删→无窗口）。**零钩子零同步**：不改 `EpidemicWorkbenchService`（N1 幂等重入、N2 第 4 写入口两个问题随之消失，N1 正确性证据=created=false 路径直接 return 不落库）。
4. 录入 API（CRUD 全量，A2；路径钉死）：`POST/PUT/DELETE/GET /api/v1/farms/{farmId}/livestock/{livestockId}/physiology-events`——PUT/DELETE 仅 MANUAL 来源（来源非 MANUAL 即 409）；未来 occurred_at 拒绝；时区 Asia/Shanghai 零点转 UTC（B3）；note ≤500；服务端校验错误走 `ApiException(VALIDATION_ERROR, "error.physiology.*")` + `messages_zh/en.properties` 六组 key（spec §5 后端表，B1 加重项）。
5. healthStatus 处置：`Livestock.healthStatus` javadoc 标记 deprecated（注明以 PhysiologyQueryPort/告警为准），不迁移数据。

**验证（T1a）**：`./gradlew compileJava` + Testcontainers 集成测试（全新库迁移；activeWindows 读时合并四场景：手动持续中/手动配对结束/处置单活动与完成/CANCELLED 含 SOURCE_UNMARKED 无窗口；MANUAL 防重幂等；跨日时区单例；后端校验 key 中英双 properties 对齐）。

## Task 1b · 生理记录卡 Flutter（下篇 UI）

1. 规格卡先行（Task 0 产物）→ 组件克隆：牲畜详情页"生理记录"卡 + 录入 sheet（按小原型 v1.2 克隆；`FarmScopedAsyncNotifier` + `watchActiveFarmId()`）。
2. **六形态**（A3）：正常/空态/加载骨架/错误态/权限降级（无写权限隐藏"＋ 记录"）/窗口中 chip；语义色走品牌绿（B5 裁决）。
3. i18n：`health.physiology.*` 14 组 key 入 ARB（spec §5）。

**验证（T1b）**：`flutter analyze` 零问题 + gen-l10n 无缺失；6 形态截图 vs 原型 `compare_screenshots.py --target-width 390` ≥85%，对照图落 `output/fidelity/physiology/comparisons/`。

## Task 2 · L1 标定（Aubé 开放数据集）

1. 下载 Aubé 2025 数据集（10min RT + 视频标注 730 事件）→ `output/drinking-l1/dataset/`（不入 git）。**确切数据集 URL 与开放许可在下载时钉入标定报告**（检索路径：entrepot.recherche.data.gouv.fr / pndb.fr 搜 "detecting drinking bouts reticulorumen temperature"）。
2. 标定脚本 `scripts/drinking_calibration/`（**Python 3 + pandas**，requirements.txt 声明依赖）：实现 FallST/Cow-dT/参考实现，网格搜索 `S_th`（斜率归一按 Δt）× `k`（μ−kσ）× `R_th`（回升幅度比）；输出 Se/PPV/F 报告 + 选定参数。
3. 间隔泛化实验：10min 原始 vs 重采样 5/6min 两组分别标定，确认参数对 Δt 归一后稳定。
4. 选定参数回填本 plan 附录与 spec（"参数定值"小节），作为 T3 的配置默认值（`health.drinking.*` 配置项，可运维调整）。

**验证**：报告落 `docs/research/2026-xx-drinking-l1-calibration-report.md`；F ≥ 0.90（未达标则回 spec 评审，不带病进 T3）。

## Task 3 · drinking_events + 检测内核

1. Flyway 迁移：`drinking_events` 表——**DDL 惯例五项**（`TIMESTAMP`、`REFERENCES devices/livestock` 外键、`temp_drop/min_temp NUMERIC(10,2)`、`updated_at`；source 沿用动态口径不加 CHECK）——完整 DDL 见技术方案 §6.1（已按仓库范本修订）。
2. `DrinkingEventDetectionService`（health.application.service）：纯函数核心（输入温度点列 → 事件列表）+ 两判据（FallST 斜率 ∧ μ−kσ）+ 2h 回升确认 + 15min 合并；参数读 `health.drinking.*` 配置（**全部配置化，四轮 F3**，定值见 spec §14/T2 标定：`baseline-min-days:3`/`recalc-overlap-hours:1`/`recovery-window-min:120`/`merge-gap-min:15`/`k-sigma:0.5`/`fall-threshold:0.06`/`recovery-ratio:0.7`）；**牛日边界 = Asia/Shanghai 日历日**（F5，跨午夜按本地日归属）。温度点列直接复用 `TemperatureLogJpaRepository.findByDeviceIdAndRecordedAtBetweenOrderByRecordedAtAsc`（已核实现成）。
3. 排除窗口：`PhysiologyQueryPort.activeWindowsForFarm`（读时合并，含处置单路）∪ `TEMPERATURE_ABNORMAL` 告警窗口（`AlertBrief.createdAt/resolvedAt` 拼装，已核实零 DTO 改动）；离体过滤（35–43°C 门卫）。**source 透传不排除**（用户裁决 2026-10-05，spec §4/§15：DATAGEN 事件带 source 标记入库、可演示）。
3b. **标记闭环数据面（spec §15.1/15.2）**：`drinking_events` 建 `label`（UNLABELED/CONFIRMED/REJECTED）、`source`（透传 + MANUAL/ALGORITHM_CANDIDATE 两新值）、`confidence` 三列；检测时写置信度（降幅/斜率/回升比裕度归一纯函数）与 borderline 候选行（`candidate-tolerance:0.5`）；标记 API：PATCH label（确认/误报）+ POST manual 补录漏报（三角色可写，权限对齐生理事件）。
4. 输入查询：`temperature_logs` 按 device 分组取当日+前 2h 点列（复用现有仓储查询，不新造轮子）。
5. 真库集成测试（Testcontainers，教训 #19）：正常 V 形谷两连发合并为一、发烧序列不产假阳性（排除窗口生效）、离体点丢弃、DATAGEN 事件带 source 标记入库、候选行不计统计、label 翻转改统计口径（REJECTED 剔除）、跨日边界。

**验证**：`./gradlew compileJava` + 新测试全绿；既有失败基线（19 个）不扩大。

## Task 4 · 调度器 + 手动回算 API

1. `DrinkingEventScheduler`：cron `0 40 3 * * *`（配置 `health.drinking.analysis-cron`）+ `@ConditionalOnProperty` enabled 开关，**走共享调度池**——`SchedulerPoolConfig` 已提供全局唯一显式 taskScheduler（8 线程 + 心跳探针兜底），`@Scheduled` 自动路由；**不新建 scheduler bean**（多 bean 混杂是 09-30 静默死亡根因注释点名的模式，`@Scheduled` 也无法路由第二个 bean——二轮评审 N4 修正，此前"独立 executor"是对 92ed1f64 教训的误读）。
2. 每日批：昨日全量在体设备 → 检测（排除窗口经 `activeWindowsForFarm` 一次取全群，B4）→ upsert（UNIQUE 键幂等，重跑安全）。
3. 手动回算/批量触发 API（运维，管理员权限；路径对齐 TileAdminController 惯例）：`POST /api/v1/admin/drinking-recalculate`（body：`deviceId` 可选 + `from`/`to` 必填）+ `@PreAuthorize("hasAnyRole('PLATFORM_ADMIN','B2B_ADMIN')")`——带 deviceId=单设备补传后重算；**省略 deviceId=按日期范围全群重算（P5，T6 的 30 天回放直接复用此端点）**；不做页面。
4. 幂等与补传（**F6 重算删除语义**）：同 device 同窗口重算 = 事务内先 `DELETE WHERE device_id=? AND event_start_at >= from−1h AND event_start_at < to+1h`（重叠删除，1h 余量配置 `health.drinking.recalc-overlap-hours`）再插入——时间戳漂移不会绕过 UNIQUE 键。

**验证**：dev 部署后手动触发批任务——**仿真数据在流（用户裁决后 source 全放行），curl 检查 `drinking_events` 有事件、source 标记正确（dev 全部应为 DATAGEN）、重跑无重复行**；可选加验：Aubé 真牛序列以 MANUAL_IMPORT 限窗灌入→检出对照已知答案→清理；`actuator/health` 401→种子登录 200 判活（#23）。

## Task 5 · API + Flutter 组件（保真核心 Task）

1. farm-scoped API（**F1 三端点，UI 数字全部有契约来源**，路径钉死前缀 `/api/v1/farms/{farmId}/livestock/{livestockId}`）：`GET .../drinking-events?from=&to=`（事件明细）、`GET .../drinking-summary?date=&days=1|7|30`（**三层口径**：daily/weekly/rolling30dBaseline+sampleDays）、`GET .../drinking-peer-comparison`（**Premium 服务端校验**——实施前核实项目既有订阅校验机制复用点；分组=同牧场+同品种+同生理阶段+有效样本 ≥5 天）——**聚合口径按 spec §4 两层定义实现**（检出数直加 vs 基线剔除发热覆盖 ≥50% 的日）——curl 真实数据冒烟（#25：200 且业务字段非空）。
2. Flutter 规格卡克隆：`DrinkingCard`（详情页健康 Tab 插入体温趋势卡同级）、`DrinkingDetailSection`（健康详情页第四分节）、状态卡组件（5 态）、Premium 锁定卡（复用/新建 LockedOverlay 组件）、图层 chips。
3. 图表实现**钉死（减少 Task 内现场决策）**：体温曲线叠加用 fl_chart `LineChart`——主温度线 + 第二数据列谷点（`FlDotCirclePainter` 白描边）+ 发热区间 `HorizontalRangeAnnotation`；时刻分布与 mini-bars 自绘（对齐项目既有自绘图惯例）；分段切换/图层开关状态管理走 Riverpod（farm-scoped 规则 §5：`watchActiveFarmId()`）。
4. i18n：spec §5 文案表（含四轮 F3：UI 无学术引用、发热口径精确句式）入 `app_zh.arb`/`app_en.arb`；实现对照**原型数据溯源表**（3c 节）逐数字核对端点字段。
4b. **标记闭环 UI（spec §15.2，原型外新增——无原型屏，按行级轻量交互实现、不新开屏）**：事件行确认/误报操作（PATCH label）、详情分节"漏报补录"入口（POST manual）、低置信"待核实"标记（confidence<0.5）、候选行"待标记"分组（确认即转正）；文案入 ARB。
5. 每 Task 内增量截图对照：Flutter Web build → 同尺寸截图 vs 基线 → `compare_screenshots.py` ≥85%，差异清零才提交。

**验证**：`flutter analyze` 零问题；gen-l10n 无缺失；6+2 屏对照图全过阈值，落 `output/fidelity/drinking/comparisons/`；主旅程走查（详情卡→详情分节→图层开关→锁定态）截图留证。

## Task 6 · L2 回放报告（用户裁决 2026-10-05 后分两段）

1. **L2-pre（本期可做，仿真数据全链路）**：dev/test 30 天回放——经 Task 4.3 批量触发端点（省略 deviceId，指定 30 天范围），顺带验证端点；**标记闭环演练**：打标签 → 导出 CSV → `calibrate.py --labels` 出建议报告（验证 spec §15 机制本身跑通）；V 形形态人工抽查 20 例。
2. **L2-real（顺延）**：真实通道（THINGSBOARD/AGENTIC_PLATFORM）30 天回放——**当前温度/蠕动全部为 DATAGEN 仿真，无真实数据可放**；待 86/223 生产环境核实有真实设备数据、或试点设备接入后执行。报告仅采信真实 source 事件；频次量级对照 Cardot 7.3±2.8（泌乳牛）。
3. 报告落 `docs/research/`（含边界样张验证：0 次日/全发热周/英文长文案/textScale 1.3）。

**验证**：L2-pre 报告产出且三项有结论（回放/标记演练/形态抽查）；L2-real 触发条件与顺延状态在报告显式记录；异常样本清单回灌 T3 参数微调（如需改参数，同一次提交更新 spec/plan/配置）。

## Task 7 · 部署 dev → 用户集成测试 → L3 试点方案

1. `deploy.sh dev`（前端 build_web 两步走，#7）；判活：`actuator/health` 502→401 轨迹 + 种子登录 200；前端生效看容器内 `main.dart.js` md5（#23）。
2. 用户集成测试（真机/浏览器主旅程）。
3. L3 试点方案文档（水表/摄像头 96h 协议仿 Aubé）落 `docs/research/`——对外准确率口径在 L3 前保持"试点验证方案"。

**验证**：用户验收通过 → 合并 PR → 关闭 NIX-256。

## 风险与回滚

| 风险 | 缓解 |
|---|---|
| L1 未达 F≥0.90 | T2 是 T3 的门禁：不达标回 spec 评审（参数结构/判据组合），不带病推进 |
| 处置单投影与疫病分支并行开发冲突 | T1 的投影钩子基于 master 现有 `EpidemicWorkbenchService` 接口；疫病分支合流后回归一遍投影测试 |
| 温度点 5/6min 口径差影响斜率 | T2 已做间隔泛化实验，参数按 Δt 归一 |
| Flutter 健康组件库从零建 | T5 先建 LockedOverlay/状态卡两个通用件再组装，规格卡先行防凭记忆实现 |

## 附录（T2 完成后回填）

- 定参（2026-10-05 L1 标定，merge-gap=15 终版口径，门禁 F≥0.90 达成）：`S_th = 0.06 °C/min`（Δt 归一；5-min 数据等效 0.30°C/步，6-min 0.36°C，10-min 0.60°C）、`k = 0.5`（k 轴单调：k=1→0.9346、k=2→0.9010、k=3→0.8317 破门禁，配置防误设大值）、`R_th = 0.7`（L1 近乎不敏感 0.5~0.8 差 ≤0.15pp，防御性默认）、`merge-gap = 15min`（**改定**：敏感性扫描 gap={0,10,15,20,25,30}→F={82.45,93.76,94.00,93.90,93.27,92.65}；原 30 系对 Aubé"30 min apart"分辨下限句的误读，把 Se 压在 86.7% 天花板；gap=0 FP 211 个证明合并必须存在）、退热缓冲 6h（L2 复核）。选定参数 F：5/6/10-min = **0.9400**/0.9390/0.9270（5-min：TP 650/FP 3，Se 89.0%/PPV 99.5%）。详见 `docs/research/2026-10-05-drinking-l1-calibration-report.md`。
- 勘误：Aubé 数据集温度为 5-min 间隔（非 10-min）；饮水信号在 `ruminal_temperature` 列（`corrected_temperature` 列已被平滑，F≈1%）——平台 `temperature_logs` 存原始通道温度，同口径无此问题。
- **生产口径转正（评审 B1 收口，2026-10-05）**：内核深度判据（谷底 ≤ μ−kσ−1.0°C）与 35–43°C 门卫经生产口径全网格重跑验证：F=0.928/0.9209@5/6-min 门禁通过（10-min 0.8756 如实记录、平台无此档）——内核保留，详见 spec §14.1 与 `output/drinking-l1/results-production/`；复现 `calibrate.py --merge-gap 15 --in-body-gate --depth-margin 1.0`。

### 附录二：保真对照 FAIL/区域不达标 正式豁免清单（用户裁决 2026-10-06，②A）

> R2 评审 N6/M4 收口：spec §6"≥85%（无 worst-region FAIL）"按字面判定的全部不达标项，经用户逐批裁决豁免如下。豁免≠通过：豁免项以"已核实的差异定性 + 证据指针"入档，不再作为门禁阻塞。

| # | 对照项 | 分值 | 豁免定性（已核实证据） |
|---|---|---|---|
| 1 | card-normal（饮水卡常态） | 73.8% | 数据态数值/文案差异已被用户 2026-10-05 裁决"A"接受；结构 token 无漂移 |
| 2 | form-sheet-panel（生理录入面板） | 73.8% | 同上，用户 2026-10-05 已接受 |
| 3 | chart-overlay（48h 叠加图） | 84.6% | fl_chart LineChart 平滑曲线 vs 原型手绘曲线的形态差，谷值点数据实测一致（M6 修复后取数窗完整） |
| 4 | note-box（数据说明框） | 65.0% | 原型演示文案 vs 实现版精简文案（AGENTS 红线：无学术引用），内容语义等价 |
| 5 | form-empty / form-sheet / aligned（生理表单三态） | 56–78% | 原型演示形态（全屏 sheet 摆位）vs 实现版平台 sheet 惯例，用户 10-05 已见六形态实截并接受面板形态 |
| 6 | card-locked / peer-locked-view（锁定态两份） | 79.9/77.6% | 独立演示卡 vs 上下文内 UpgradeOverlay 的取景差异（`locked-views.FRAMING.md` 逐项量化） |
| 7 | state-no-data content 区 / state-skeleton summary_strip 区 | 84.5% ×2 | 距阈值 0.5pp，噪声级；整体 89.6/86.1 |
| 8 | state-skeleton bottom_nav 区 | 69.0% | **已核实**（2026-10-06）：Flutter 骨架态该横带含浅蓝图表占位框+Overview 选中态，原型同带近乎全空白（99.6% 白）——内容存在性/取景差异，非布局缺陷（R2 N6 先核实再定项） |

### 附录三：R2 修复批记录（2026-10-06，用户裁决 ①③④执行）

- 证据链（0fbebc30）：L1 正典 results/ 已 git 恢复至 d416af19；"逐数一致"改实测口径（6-min 15 行 TP−1、0.9201 门禁不变）；spec §14.1 复现命令补 --out；selection.json 补口径元数据；labels 建议加 epsilon(0.5pp)+现产平局优先（N7）；label_drill [:16] 修（N4）；vspot 补 drop_vs_pre_max 列（N16）。
- 后端（c836b14e）：PATCH label 白名单 CONFIRMED/REJECTED（m-c）；生理 PUT note 空串=显式清空/null=保留（N17）；journey javadoc 失实自述修正+build.gradle 执行债指针（N1 代码侧）。
- Flutter（caef03ef）：updateEvent 空串直达 wire（N17）；生理测试改 byKey 查找（n-i）；发病提示仅 ILLNESS 显示（n-h）。
- N5 英文样张重截（滚轮+700ms+叶子节点 rect 配方）：Drinking Behavior 分节 + 发热长文案逐字完整无截断；ui-en-home 换为真实主页看板。
- 顺带批（③A）：m-u/n-j/n-e/n-a/r1-n4 注释互指。
- journey 实跑债：本机无 docker 命令，绑定 T7 dev 部署后冒烟（与评审建议一致）。

### 附录四：图表标签可读性修正（用户裁决 2026-10-06"修复"）

用户集成测试反馈"柱状图中文字看不清楚"。核对：实现与原型 v1.3 逐值一致（7.5px），缺陷在原型设计本身——CJK 字形在 7.5px 物理尺寸笔画塌缩，且 48h/分布图文字画在 X 向拉伸画布里（~1.15× 横向变形）。修正（原型 v1.4 + Flutter 同步，豁免该处像素对照）：

- SVG/CustomPainter 全部图表标签 7.5 → **9.5px**（落原型自身说明文字尺寸档）：分布图带标签×3、轴刻度×4、48h 图发热标签×2、谷值温度标注×2；
- 带标签色 #4C7A52 → **#3D6743**（对带底色对比度 4.4 → 5.3:1，过 AA）；
- Flutter 文字移出 `scale(sx,1)` 画布（x 预乘 sx），消除横向字形拉伸。

### 附录五：m-q 发热阴影区裁决记录（NIX-259，2026-10-06）

用户令"做 259"，m-q 按实现路线落地：48h 温度×饮水图补发热时段时间跨度色带（`--fever` #D97B29 @ 12% 透明度），数据源为 `DrinkingEventDetectionService.feverWindowsForLivestock`（含 6h 退热缓冲），经 drinking-events 列表端点以 `{events, feverWindows}` 复合体下发（服务端将开放窗 end 截断到查询窗 to）。本 plan 原文出现的 "HorizontalRangeAnnotation" 系笔误——原型（屏 2 SVG `<rect>` 时间跨度色带）与实现（fl_chart `RangeAnnotations.verticalRangeAnnotations`）均为时间跨度色带（vertical annotation）。原型带内"发热期·已排除"小标签由图例项"发热期+6h 缓冲"承载（fl_chart 范围注解无标签能力，退化方案照录）。
