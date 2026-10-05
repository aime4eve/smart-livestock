# NIX-256 产出物评审报告（T0–T5b）

> 评审日期：2026-10-05
> 分支：`nix/256-drinking-physiology-p1`（评审基线 `64b5d402`，工作区干净）
> 范围：相对 master 全部 diff（184 文件、+53335 行，含 PDF 论文与证据文件），Task 0 → T5b 全部产出物
> 方法：5 个评审域并行（T3 检测内核 / T4 调度+T5a API / T1a 生理后端 / Flutter UI / T2 标定+证据链横向一致性），对照 spec（`docs/superpowers/specs/2026-10-04-drinking-detection-physiology-p1-spec.md`）、plan（`docs/superpowers/plans/2026-10-04-drinking-detection-physiology-p1-plan.md`）与 AGENTS.md 逐条核查；纯静态评审 + git 命令核实，未跑编译/测试。

## 总体判断

主体质量高：DDL 惯例、共享调度池（无新建 bean）、读时合并、F6 幂等/标签回填语义、Premium 校验复用既有订阅机制、i18n 中英对齐、farm-scoped 规则、cherry-pick 无夹带等均核查通过。

但有 **2 个 blocker 必须先闭环**，其中最严重的是：**生产内核实现的判据不是 L1 标定验证过的判据**（两个评审域独立命中同一问题）。

## 待用户裁决事项（汇总）

1. **B1+M1 收口方向**（推荐）：给 `calibrate.py` 加 `--merge-gap`/`--in-body-gate` 开关，按生产口径重跑网格——F 仍 ≥0.90 则把生产口径写进 spec §14 转正；掉门禁则改内核对齐标定口径。一次重跑同时解决 B1、M1、M3。
2. **M2 同类均值含本牛**：改代码对齐 spec，还是修 spec 明确"含本牛+豁免门槛"？
3. **M7 生理编辑/删除 UI**：P1 补列表行入口，还是删 repository 死代码 + 改规格卡？
4. **M4 保真豁免**：7 项 FAIL 是否正式豁免？缺失的 4 组对照（skeleton/no-data/backfill/locked）补不补？
5. **M5 配置键缺口**：补 `baseline-min-days`/`low-confidence` 后端键 + 下发，还是修 spec 删表述并改 Flutter 注释？

---

## 🔴 Blocker

### B1 · 深度判据多了 1.0°C 门槛，F=0.94 的标定证据对当前内核不成立

- 位置：`DrinkingEventDetectionService.java:234`（confirmed 要求 `rDepth >= 1`）、`:286-287`（`rDepth = (depthLine - trough) / DEPTH_CONFIDENCE_THRESHOLD_C`，常量 1.0，`:76`）
- 证据：标定口径（`scripts/drinking_calibration/combined_detector.py:53`、标定报告 §4）的深度判据是 `T[i+1] < mu_day − k·sigma_day`——**低于线即过，任意裕度**；spec §14 与类 javadoc（`:52-53`）写的也是 "trough below the same-local-day baseline μ_day − k·σ_day"。实现却要求 trough 低于 μ−kσ **再减 1.0°C** 才算确认事件。取值点也不同（Java 取谷底，Python 取下降后点）；斜率判据 Java 取下降段内最大相邻速率（`:275-284`），Python 要求触发对速率 ≥ S_th。
- 常量命名 `DEPTH_CONFIDENCE_THRESHOLD_C` 及 javadoc 自称仅供 confidence 启发式，实际充当判据门槛，掩盖了偏离。`slopeOnlyValleyNotDetected`/`depthJustMissingBecomesCandidate` 两个单测反而把偏离钉成了"特性"。
- 后果：系统性收紧灵敏度，Se 必然显著低于标定的 89.0%；**生产实现的不是被门禁验证过的那个算法**。
- 处置建议：改回 "trough < depthLine 即确认"（rDepth > 0），borderline 带的深度刻度另行定义；或若坚持 1°C 门槛，必须回 Python 网格重跑证明 F≥0.90 并同步修订 spec §14/plan 附录/类 javadoc。

### B2 · `PhysiologyEventJourneyTest` 从未运行过，且静态推断必挂

- 位置：`src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java:94-110`（insertDisposition）、`:276`、`:293`、`:302`
- 证据：
  1. T1a 提交说明自述 "journey test written for all T1a scenarios (Testcontainers — blocked locally, no Docker runtime)"——该测试从未执行。
  2. 测试 `entity.setCreatedAt(created)`（now−3 天），但 `EpidemicDispositionJpaEntity.java:82-86` 的 `@PrePersist onCreate()` 无条件覆写 `createdAt = Instant.now()`，持久化后 createdAt = 真实 now ≠ 期望的 now−3d。
  3. `dispositionWindowsMergeByStatus` 的 `:293`/`:302` 断言 `w.occurredAt()).isEqualTo(created)` 必然失败（差 3 天，Instant.equals 精确比较）。`:303` 的 `endedAt == completedAt` 不受影响。
  4. 全仓库无其他测试构造过 `EpidemicDispositionJpaEntity`，无已验证写法可借鉴。
- 依据：plan Task 1a 验证步骤要求 Testcontainers 四场景；AGENTS.md §7 #19（新写路径必须真库集成测试且跑通）、#25（收口验证）。当前 = T1a 验证步骤未达成，且测试带病。注意既有失败基线（19 个）不含此测试，跑红即是回归扩大。
- 修复方向：测试改用 JdbcTemplate/原生 SQL 直插处置单（推荐，不动疫病实体）；或 `onCreate()` 加 `if (createdAt == null)` 护栏（改疫病上下文实体，需知会疫病分支）。

---

## 🟠 Major

### M1 · 35–43°C 离体门卫丢弃的正是饮水谷底信号，与 L1 标定数据现实矛盾

- 位置：`DrinkingEventDetectionService.java:71-73,160`（`IN_BODY_MIN_TEMP=35.0` 过滤在检测前）
- 证据：Aubé 数据 48384 个 ruminal 点中 **2161 个（4.47%）<35°C，最低 21.4°C**；报告 §2 自己引用 "ruminal 39.8→28.8→38.3（典型 V 形）"。门卫把每次饮水的最深点全部删除后再检测：temp_drop/min_temp 被截断、slope 跨越被挖空区段、回升基准点上移。标定（Python 无此过滤）从未在"截断谷底"的信号上度量 F。已核实 `temperature_logs` 摄入端不过滤（35–43 仅在 `HealthApplicationService.java:56-60` 状态评估），库里有深谷数据、唯独检测器看不到。
- 依据：plan T3.3 确实写了"离体过滤（35–43°C 门卫）"——实现符合 plan，但 **plan 该条与 L1 数据现实矛盾**，数据侧是对的。
- 处置建议：门卫收紧为排离体形态（如 <30°C 或仅 >43°C），或按截断信号重跑标定；至少在 L2-pre 回放中量化该门卫的 Se 影响。

### M2 · 同类对比把目标牛自身计入 peerAvgPerDay 且豁免 ≥5 天样本门槛

- 位置：`DrinkingSummaryService.java:343-365`（target 不入 qualifiedPeers 但在 sampleDays>0 时加入 pool）；测试 `DrinkingSummaryServiceTest.java:388-406`
- 证据：spec §4 分组定义是四条件合取——"同牧场 + 同品种 + 同生理阶段 + 近 30 日有效样本 ≥5 天"，未对任何成员豁免；端点语义是"同类均值"（原型副标"同类成母牛均值 7.3 次/日"）。附带不一致：没有其他成员达 5 天时直接 `INSUFFICIENT_PEERS`（target 数据再好也不单独出均值），但一旦有一个 peer 达标，target 又以低至 1 个样本天进分母——"不够格独立成群、却够格拉低均值"。
- 测试注释（`:388`）写 "per the spec"——spec 原文并无此钉定，误引权威（经验 #5 反面）。
- 处置：代码对齐 spec（target 不计入或同样 ≥5 天），或用户裁决后修 spec §4。三方不一致，不能带病进 T7。

### M3 · gap=15 终版证据不可复现——生成器未入库

- 位置：`scripts/drinking_calibration/calibrate.py:142-144`（`run_combined` 不传 `merge_gap_min`，永远用默认 30）；`output/drinking-l1/results/grid_results_gap15.csv` 表头为小写、无 n_detected，与 calibrate.py 输出 schema 不同；`selection.json` 的 `merge_gap_min`/`F_6min`/`neighborhood_F_gap15` 等键 calibrate.py 从不写。
- 证据：报告 §4b 声明 "gap=15 下全网格复跑（125 组合×3 间隔）"，但任何已提交脚本都产不出该文件（`merge_gap_sweep.py` 只扫选定参数点且只打 stdout）。重跑 calibrate.py 会把 F_5min 退回 gap=30 的 0.9265，与文件内 0.94 冲突。
- 依据：plan T2.2 要求标定脚本可复现；报告"复现命令"对终版口径不成立。
- 处置：calibrate.py 加 `--merge-gap`（默认 15），重跑覆盖三份产物。

### M4 · 保真 ≥85% 门禁被作者自行豁免，且有 FAIL 未披露

- 位置：`output/fidelity/drinking/comparisons/` 与 `output/fidelity/physiology/comparisons/` 15 份报告逐一核对
- 证据：7 项 FAIL——drinking：card-normal **73.8%**、chart-overlay **84.6%**、note-box **65.0%**；physiology：form-empty **78.4%**、form-sheet **56.4%**、form-sheet-panel **73.8%**、form-sheet-panel-aligned **69.5%**。T5b 提交说明（64b5d402）逐项解释了 3 项 drinking FAIL（真实数据 vs 原型演示数据，可议）；但 T1b 提交说明（45064a80）只提 "sheet panel 73.8%"，并引用 "empty 93.3% PASS"——那是 `form-empty-box` 另一份报告，`form-empty.png` 78.4%、form-sheet 56.4%、aligned 69.5% **三处未披露**。覆盖缺口：state-skeleton（有截图无报告）、state-no-data / state-backfill（有基线无截图无报告）、card-locked vs locked-peer-card（有截图无报告）。
- 依据：plan T5.5"差异清零才提交"、T5 验证"6+2 屏对照图全过阈值"、spec §6 验收 1"≥85%（区域报告无 worst-region FAIL）"。豁免权在评审/用户，不在实现者自裁（AGENTS.md §3 feature 流程每阶段需确认）。

### M5 · spec 明列的 `baseline-min-days` / `low-confidence` 配置键在后端不存在

- 位置：`application.yml` 无此二键；Java 全库 grep 无 `baselineMinDays`/`lowConfidence`；Flutter `Mobile/mobile_app/lib/features/drinking/domain/drinking_models.dart:9-15` 硬编码 `kDrinkingBaselineMinDays = 3`、`kDrinkingLowConfidence = 0.5`，注释自称 "Front-end mirror of the backend config"——镜像了不存在的后端配置，正违反 spec F3"魔法数不入 UI 当权威"。`baseline-min-days=3` 是"基线建立中"状态门槛，`DrinkingSummaryService` 也未消费它。
- 依据：spec §4 参数清单明列 `baseline-min-days:3`；§15.2 命名 `health.drinking.low-confidence:0.5`。
- 处置：补两键进 yml + 服务端消费/下发，或修订 spec 删除并改 Flutter 注释。（三个评审域独立命中此项。）

### M6 · 48h 温度叠加图的谷点数据源只覆盖 [昨天, 今天]，左半段谷点系统性缺失

- 位置：`Mobile/mobile_app/lib/features/drinking/application/drinking_controller.dart:60-74`（`from: today−1d, to: today`）；消费方 `drinking_detail_section.dart:509-521`（谷点过滤窗口 = now−48h）
- 证据：代入求值——now=12:00 时图表窗口为 [D-2 12:00, D0 12:00]，事件只取到 [D-1 00:00, D0]，[D-2 12:00, D-1 00:00) 这 12 小时的谷点永远画不出来；代码注释 "yesterday's cover the tail of the 48h overlay chart" 与实际不符。
- 依据：规格卡 drinking-detail-section.md 图表 B + plan T5.3 钉死该图。
- 修法：`from` 改为 `today−2d`，一行修复。

### M7 · 生理记录 CRUD 的编辑/删除在 UI 层完全不可达

- 位置：`physiology_record_card.dart:226`（`_EventRow` 无任何手势入口）、`physiology_controller.dart:15-50`（Controller 只有 list/create）；`physiology_api_repository.dart:43-66` 的 `updateEvent`/`deleteEvent` 零调用方（死代码）。
- 依据：spec §10「CRUD 全量（A2）…PUT/{id} 编辑…DELETE/{id}」；规格卡 physiology-entry-sheet.md「编辑/删除（卡片行入口或长按，P1 从列表行操作）」。
- 判断：后端端点 + Flutter repository 都在，唯独列表行操作入口缺失。需范围裁决：补 UI 入口，或删死代码 + 改规格卡。

### M8 · 缺"构造发烧序列"的真库集成测试（spec 验收 #5 / plan Task 3.5 明确要求）

- 位置：`DrinkingEventJourneyTest.java:91-103`——setUp 刻意挑选无发热告警的牲畜"保持确定性"，全程无用例把 TEMPERATURE_ABNORMAL 告警或 physiology ILLNESS 落库后验证排除生效。
- 现状：仅内核单测 `valleysInsideFeverWindowAndBufferDropped`（合成 ExclusionWindow）。窗口装配路径（`activeWindowsForFarm` ∪ AlertBrief 拼装 + 6h buffer，`:615-648`）零端到端覆盖。
- 依据：spec §6 验收 5、plan Task 3.5、AGENTS 经验 #19。

---

## 🟡 Minor

**后端（饮水）**
- m-a · `scanTo` 硬编码 1h，与 `scanFrom` 用 `recalcOverlapHours` 不对称（`DrinkingEventDetectionService.java:589` vs `:584-586`）；运维调参后窗口取数口径歪斜。
- m-b · 重算重叠带的谷用前一日"残日"μ/σ 重判（`:472-474`，温度点下界 = from−overlap−2h），前一日日批用全日 μ/σ 判过的边界谷在重算时口径退化，可能消失/新生。建议查询下界前移到前一日 00:00。
- m-c · PATCH label 放行 UNLABELED 重置，超出 spec §15.2 契约（CONFIRMED|REJECTED）——语义合理（撤销），建议 spec 补一句。
- m-d · POST /manual 无幂等，同 device 同 start 双击撞 UNIQUE → DataIntegrityViolation → 500（`DrinkingEventService.java:82-104`）；对照生理事件侧"双击幂等返回已有行"惯例，建议 catch 后查询返回。
- m-e · 新集成测试自述"本机 compile-only"，Testcontainers 不可本机运行——标记闭环关键语义测试可能从未真绿，需核实 CI/dev 执行记录（#19 收口含义）。
- m-f · sample-day 规则新增"≥24 温度点"判据（`DrinkingSummaryService.java:93-99,172-174`，已配置化 `sample-day-min-points` 值得肯定），spec §4 未定义——实现合理但 spec 未记录，应回写。
- m-g · 基线/同类均值窗口包含进行中的"今天"（`:200`,`:326-329`）——当日饮水次数是半天数据却作样本日进分母，spec 未钉"近 30 日"是否含当天。
- m-h · F6 重叠删除边界（from−1h/to+1h）无测试钉定——缺"余量内删除、余量外存活"的精确边界用例。
- m-i · peer comparison 每请求查询扇出 ~32N（50 头牧场 ≈1600 次 SQL，`:340-348,369-387`）——Premium 低频可暂接受，技术债记录，后续改 `GROUP BY date` 一次聚合。

**后端（生理）**
- m-j · `createEvent` 对 null body 防御不一致（`PhysiologyEventService.java:96-98`）：前两行有三元防御，第三行直接 `request.note()` → NPE 500 而非 400。
- m-k · 权限校验手写 SecurityContextHolder 而非项目惯例 `@PreAuthorize`（`PhysiologyEventController.java:73-83`；对照 `AlertController.java:95,130`）——功能等价但偏离 spec §10 B2 惯例。
- m-l · `updateEvent` 并发撞唯一索引时 500 而非 409（`:147-159` 只做事先查重，无 `DataIntegrityViolationException` 兜底；create 路径 `:119-128` 有）。
- m-m · PUT 无法清空备注（`if (note != null)` 保留旧值）——语义模糊，可文档化或允许显式清空。
- m-n · IN_PROGRESS 分支无测试；配对单测无显式"跨多头牛隔离"用例（结构上由 per-livestock 查询保证，风险低）。
- m-o · 种子 occurred_at 带时分秒（`NOW() - INTERVAL '128 days'`），非 B3 的 Asia/Shanghai 零点语义——种子仅驱动原型展示，无实害。
- m-p · `currentStage` 不过滤 source——未来若出现 ALERT_CONFIRM 的 CALVING/DRY_OFF 行会参与阶段推导；当前无 ALERT_CONFIRM 写入口，无实害。

**Flutter**
- m-q · 48h 叠加图未画发热阴影区——plan 钉死的 `HorizontalRangeAnnotation` 未实现（`drinking_detail_section.dart:27-35` 类注释自报偏离，理由记录在案但属"钉死项被 Task 内削减"，应回 plan 层裁决）。
- m-r · "数据补传中"状态（第 5 态）整体未实现（`drinking_models.dart:341-342` 只有 4 态；ARB 文案已备）——spec §3.3 五态 + 验收 2 按字面无法全过，需显式记录。
- m-s · 生理侧零测试覆盖（`test/features/physiology/` 不存在）——farm 切换重建、六形态、未来日期拒绝/500 字上限全部无断言保护，与饮水侧不对称。
- m-t · `livestock_detail_real_api_test.dart:26-39` 后端不在时静默 SKIP（print + return），CI 恒绿假通道——建议用 test 包 skip 机制语义化。

**标定/证据**
- m-u · 标定脚本陈旧注释与默认值为已废弃的 30min（`combined_detector.py:15-16,22`、`calibrate.py:7`）——下次复跑极易走错口径（M3 的温床）。

## ⚪ Nit

- n1 · σ 口径 ddof 差：Java 总体方差 ddof=0（`DrinkingEventDetectionService.java:382-387`）vs 标定 pandas std ddof=1（`data_io.py:75`），n≈288/日时差异 ~0.17%，可忽略。
- n2 · trough 游进条件 Java 严格 `<`（`:262`）vs 标定 `<=`（`combined_detector.py:56`）——等温平台期 troughAt 取更早点，minTemp 不变仅时间戳差。
- n3 · `mergeEvents` javadoc 称 "chain-merge" 措辞夸大——实际与标定一致（对最早 start 比距离，长链会断开），行为正确。
- n4 · 35–43°C 门卫与摄入侧重复定义（`:72-73` vs `HealthApplicationService.java:59-60`），注释自称 "shared" 实为复制，值漂移无防护。
- n5 · 标签快照键仅 eventStartAt（`:498-506`）——同一 start 并存 CONFIRMED 事件行与 REJECTED 候选行会互相覆盖，现实罕见。
- n6 · 调度 cron 按服务器本地时区触发（UTC 容器里 03:40 = 上海 11:40）；窗口由 `Instant.now()` 推导仍正确，只是触发偏晚；spec 只钉表达式，不算偏差。
- n7 · admin 回算无范围上限（from=2020 会同步跑数年）——管理员专用 + 同步语义已在 javadoc 声明，可接受。
- n8 · mini-bars 柱高 count*4 封顶 38——原型 9→38（非线性），实现 9→36；>9 次/日全部压平丢区分度（Cardot 7.3±2.8，10+ 完全可能）。
- n9 · 饮水补录备注 UI 上限 200 字 vs 后端/DDL 500 字（生理侧 UI=500 一致）——UI 更严不算 bug，口径不齐且 hint 把 200 写死成"规格"。
- n10 · 死 ARB key：`healthDrinkingWeekBars` 无引用建议删；`healthDrinkingStateBackfill` 因 m-r 预留可留。
- n11 · 规格卡两个预埋件未落地且未记录（二期告警行、premium-strip 预埋条、谷点双向联动 note-box）——规格卡与 plan 口径缝，需确认是收敛还是漏项。
- n12 · 谷点 painter 未用 plan 钉死的 `FlDotCirclePainter`（自绘 `_ValleyDotPainter` 为画降幅标签，功能等价；`livestock_detail_page.dart` 倒是用了钉死件）——同一 feature 两套实现。
- n13 · 阴影/骨架渐变色硬编码字面量散落 4 处（`0x0F263126` 等），建议沉淀 `AppColors.shadowCard` 或共享装饰。
- n14 · 原型版本标注三处不一致（HTML title v1.0 / spec·plan 称 v1.2 / drinking 规格卡称 v1.3）；同文件注释"手机壳 280px"实际 390px。
- n15 · compose 的 `SPRING_TASK_SCHEDULING_POOL_SIZE=8` 已冗余（显式 SchedulerPoolConfig bean 后 Boot 调度自动配置退避），无害但注释层面误导。
- n16 · healthStatus deprecation 仅 javadoc 无 `@Deprecated` 注解——符合 spec §9 原文，仅提示无编译期告警。

---

## ✅ 已核对无问题清单（按域）

**T3 检测内核**
- 斜率判据 Δt 归一（dt≤0 或 >30min 的乱序/断档对跳过）✓；回升确认 120min 窗口 bestRise ≥ 0.7×D 与标定同构 ✓；15min 合并语义与标定逐行一致（start-to-start `< 15`，最早 start/最深谷/最大 drop/最高 confidence）✓
- 牛日边界 Asia/Shanghai；谷归属 start 本地日；跨午夜经 2h 前缀 + 回看 + 归属过滤无重复计数；单测精确锁定 ✓
- 参数默认值 = plan 附录（0.06/0.5/120/0.7/15/0.5/6/1），全部 `health.drinking.*` + env 覆盖；k>2 告警落实 ✓
- 排除窗口装配：activeWindowsForFarm ∪ TEMPERATURE_ABNORMAL（AlertBrief createdAt/resolvedAt 零 DTO 改动）；ACTIVE 开端口、AUTO_RESOLVED/DISMISSED 闭窗；resolved-since 过滤数学上不漏窗；6h 退热缓冲统一装配（检测与统计共用，防口径漂移）✓
- DATAGEN 透传不排除（用户裁决 2026-10-05）单测 + journey 双覆盖 ✓；候选行不合并、按 trough 去重 ✓；`isCounted` 与修订后 spec §15.3 逐字一致 ✓
- §15.4 标签跨重算：只删非 MANUAL 行、删除前快照、重插回填、未重检出复活——journey 三阶段用例真实有效 ✓
- DDL 惯例五项全中；UNIQUE(device_id, event_start_at, algorithm_version) 与技术方案 §6.1 一致；不分区声明与 PartitionMaintenanceService 兼容 ✓
- 写接口三角色对齐生理事件惯例；farm 归属校验 + 跨牲畜 IDOR 防护 ✓；`error.drinking.*` 11 键三 bundle 对齐，journey 断言具体本地化文案 ✓

**T4 调度 + T5a API**
- cron 配置 + `@ConditionalOnProperty` 与 plan 逐字一致；ApplicationContextRunner 锁定开关三态 ✓
- 每日批 = 昨日 Asia/Shanghai 牛日（纯函数 + 跨午夜单测精确到纳秒）；全群 = active capsule bindings 按 farm 集合；activeWindowsForFarm 每农场取一次（B4 防 N+1）✓
- delete+insert 同事务（跨 bean 调用，自调用陷阱已规避）；UNIQUE 键兜底；重跑无重复行有集成测试 ✓
- admin 端点路径/权限（PLATFORM_ADMIN/B2B_ADMIN，对齐 TileAdminController）/参数校验（未来日拒绝、未知设备 404、OWNER/WORKER 403）✓
- summary 三层口径：days∈{1,7,30} 校验；weekly 检出数直加（F4 第一层）；baseline 发热覆盖严格 <50%（50.0 整排除有单测）；`countedPerDay` 跨 UTC 16:00 午夜归属有单测；抽算复核 weekly 48/7=6.86、baseline 8.00、peer 6.57 全对 ✓
- Premium 校验复用既有 `HealthSubscriptionPort.hasFeature` → TenantContext → feature_gates（health_score/estrus_detect 同机制）；403 先于任何数据查询（无存在性 oracle）；journey 含降级→403→中文文案→恢复全链路 ✓
- 三端点路径钉死；farm 归属双重校验（跨牧场 404 有测试）；DTO 形状与 spec §4/§9 及原型 3c 溯源表一致；days=1 分层 null 有测试 ✓
- T4 未新建 scheduler bean/executor（GpsIngestionTaskScheduler/SynthesisRunner 的 executor 全部来自 cherry-pick 三部曲）✓

**T1a 生理事件流后端**
- DDL 与 spec §8 逐字一致（TIMESTAMP/双外键/双 CHECK/updated_at/无 ended_at/partial unique/索引）；seed 两牛在 V9 存在、NOT EXISTS 幂等 ✓
- 零钩子：git diff 证实 `EpidemicWorkbenchService` 无任何改动；`EpidemicDispositionJpaRepository` 仅追加 2 个只读查询 ✓
- 处置单路四状态（PENDING/IN_PROGRESS→活动、COMPLETED→completed_at 止、CANCELLED 含 SOURCE_UNMARKED→无窗口）✓
- 手动路栈式配对（排序+同时刻 ILLNESS 优先、嵌套内层先闭、多余 RECOVERY 忽略、残留开口）7 个纯单测；半开区间重叠判定正确 ✓
- B4 防 N+1 两路各一次 IN 批量 ✓；CRUD 契约（409/未来拒绝/时区断言精确到 `2026-09-10`→`2026-09-09T16:00:00Z`/note 501 拒绝）✓
- POST 幂等（先查 + 竞态兜底重读获胜行；非事务化 save 理由有注释且正确）✓
- farm 隔离双层（FarmScopeInterceptor + service 二次校验）✓；healthStatus 双 javadoc deprecated 零数据迁移 ✓；currentStage + 305 天隐含干奶可配（F7）✓
- spec §8 "最近 RECOVERY" vs "栈式匹配"措辞张力：实现按栈式（规范性语句）正确，建议 spec 下轮加"（嵌套情形以栈式匹配为准）"半句

**Flutter UI**
- §5 farm-scoped 规则：四个 Controller 均继承 `FarmScopedAsyncNotifier` 且 build() 第一行 `watchActiveFarmId()`；有 farm 切换重建测试 ✓
- i18n：grep 中文命中全部是文档注释；ZH/EN 新增 ~140 组 key 逐一对齐（占位符类型一致）；`e.toString()` 裸露已核实安全（ApiException.toString() 返回服务端 i18n message）✓
- 生理卡六形态齐全；饮水 4 态 + Premium LockedOverlay（403→锁定卡不进错误态，有测试）✓
- fl_chart 规格：主温度线 fever w2、谷点 r4 `#2C6486` 白描边 1.5 ✓；时刻分布/mini-bars 自绘符合钉死 ✓
- 标记闭环 UI 完整：PATCH 乐观刷新、POST manual 预校验、confidence<0.5「待核实」、候选「待标记」分组确认转正、`_isCounted` 与 §15.3 逐字一致、三角色权限门控 ✓
- 设计令牌与 spec §2 逐值一致；卡片 r12/p12、chip r999、字号表与规格卡逐项相符 ✓；语义色品牌绿 + 窗口中 fever 橙（B5）✓
- Riverpod 惯例（命名/ref.watch vs ref.read/Key）齐备；测试断言实质（调用次数、合并逻辑、RenderFlex 溢出遍历）非假绿 ✓
- 时区口径：wire 全部 `yyyy-MM-dd`（B3）；事件渲染 `toLocal()` 无 `toUtc()` 往返（#17 同向）✓
- 挂载可达性：详情卡→点击滚动到分节（GlobalKey + ensureVisible）、分节为健康卡第四分节 ✓

**T2 标定 + 证据链横向**
- cherry-pick 三提交（c6cd5350/22136330/92ed1f64）与疫病分支原版逐字节一致，无夹带 ✓
- datagen/iot/platform 改动 = 调度器修复三部曲内容，是 T4 共享池前置，合理 ✓
- 报告数字 ↔ 产物逐值相符（gap 扫描六值、选定行 F=0.93999/TP650/FP3/Se 89.0%/PPV 99.5%、k 轴单调、三方法复现 |ΔF|≤0.2pp）✓
- 两处勘误（merge-gap 30→15、Aubé 5-min 非 10-min）在报告/plan 附录/spec §14 三处一致 ✓
- 数据集 DOI 10.57745/H2SPNR + Etalab 2.0 许可钉入报告 §1；数据集本体未入 git ✓
- design-tokens 三枚 --drinking 令牌与原型 CSS :root 逐值一致 ✓；规格卡抽查 8 组数值全对 ✓
- 标定脚本确定性可复现（无随机源、repo 相对路径、requirements 声明）✓；合并语义 Python/Java 同口径 ✓
- 原型基线 8 屏齐全 ✓

---

## 共性主题与建议

1. **"spec 未记录、实现自辩"的口径漂移**是本次评审的最大共性（B1/M2/m-c/m-f/m-g/m-q/m-r）：实现偏离都有注释自辩，但 plan 钉死的目的就是防止 Task 内现场决策。建议在 plan 附录补一节"已批准偏离清单"逐项转正，否则每轮评审都会再撞一次。
2. **标定口径 ↔ 生产口径的同构性**需要一次性收口（B1/M1/M3/m-u/n1/n2）：推荐给 calibrate.py 加 `--merge-gap`/`--in-body-gate` 开关按生产口径重跑网格，F 仍 ≥0.90 则把生产口径写进 spec §14 作为正典，掉门禁则改内核。
3. **测试债务**：B2（journey 必挂）+ m-e（标记闭环测试可能从未真跑）+ M8（发烧排除零端到端）+ m-s（生理侧零测试）——T7 用户验收前需要在有 Docker 的环境跑通全部新集成测试。
4. 修复优先级建议：B1（内核判据）→ B2+M8（测试闭环）→ M6（一行修复）→ M2/M5/M7（裁决项）→ M3/M4（证据链）→ minor 批量。
