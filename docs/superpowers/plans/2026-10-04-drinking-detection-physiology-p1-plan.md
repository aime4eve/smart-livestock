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
2. `DrinkingEventDetectionService`（health.application.service）：纯函数核心（输入温度点列 → 事件列表）+ 两判据（FallST 斜率 ∧ μ−kσ）+ 2h 回升确认 + 30min 合并；参数读 `health.drinking.*` 配置（**全部配置化，四轮 F3**：`baseline-min-days:3`/`recalc-overlap-hours:1`/`recovery-window-min:120`/`merge-gap-min:30`/`k-sigma:10`/`fall-threshold:<T2>`）；**牛日边界 = Asia/Shanghai 日历日**（F5，跨午夜按本地日归属）。温度点列直接复用 `TemperatureLogJpaRepository.findByDeviceIdAndRecordedAtBetweenOrderByRecordedAtAsc`（已核实现成）。
3. 排除窗口：`PhysiologyQueryPort.activeWindowsForFarm`（读时合并，含处置单路）∪ `TEMPERATURE_ABNORMAL` 告警窗口（`AlertBrief.createdAt/resolvedAt` 拼装，已核实零 DTO 改动）；离体过滤（35–43°C 门卫）+ source 过滤（排除 DATAGEN）。
4. 输入查询：`temperature_logs` 按 device 分组取当日+前 2h 点列（复用现有仓储查询，不新造轮子）。
5. 真库集成测试（Testcontainers，教训 #19）：正常 V 形谷两连发合并为一、发烧序列不产假阳性（排除窗口生效）、离体点丢弃、DATAGEN 不入库、跨日边界。

**验证**：`./gradlew compileJava` + 新测试全绿；既有失败基线（19 个）不扩大。

## Task 4 · 调度器 + 手动回算 API

1. `DrinkingEventScheduler`：cron `0 40 3 * * *`（配置 `health.drinking.analysis-cron`）+ `@ConditionalOnProperty` enabled 开关，**走共享调度池**——`SchedulerPoolConfig` 已提供全局唯一显式 taskScheduler（8 线程 + 心跳探针兜底），`@Scheduled` 自动路由；**不新建 scheduler bean**（多 bean 混杂是 09-30 静默死亡根因注释点名的模式，`@Scheduled` 也无法路由第二个 bean——二轮评审 N4 修正，此前"独立 executor"是对 92ed1f64 教训的误读）。
2. 每日批：昨日全量在体设备 → 检测（排除窗口经 `activeWindowsForFarm` 一次取全群，B4）→ upsert（UNIQUE 键幂等，重跑安全）。
3. 手动回算/批量触发 API（运维，管理员权限；路径对齐 TileAdminController 惯例）：`POST /api/v1/admin/drinking-recalculate`（body：`deviceId` 可选 + `from`/`to` 必填）+ `@PreAuthorize("hasAnyRole('PLATFORM_ADMIN','B2B_ADMIN')")`——带 deviceId=单设备补传后重算；**省略 deviceId=按日期范围全群重算（P5，T6 的 30 天回放直接复用此端点）**；不做页面。
4. 幂等与补传（**F6 重算删除语义**）：同 device 同窗口重算 = 事务内先 `DELETE WHERE device_id=? AND event_start_at >= from−1h AND event_start_at < to+1h`（重叠删除，1h 余量配置 `health.drinking.recalc-overlap-hours`）再插入——时间戳漂移不会绕过 UNIQUE 键。

**验证**：dev 部署后手动触发批任务，curl 检查 `drinking_events` 有真实通道数据、重跑无重复行；`actuator/health` 401→种子登录 200 判活（#23）。

## Task 5 · API + Flutter 组件（保真核心 Task）

1. farm-scoped API（**F1 三端点，UI 数字全部有契约来源**，路径钉死前缀 `/api/v1/farms/{farmId}/livestock/{livestockId}`）：`GET .../drinking-events?from=&to=`（事件明细）、`GET .../drinking-summary?date=&days=1|7|30`（**三层口径**：daily/weekly/rolling30dBaseline+sampleDays）、`GET .../drinking-peer-comparison`（**Premium 服务端校验**——实施前核实项目既有订阅校验机制复用点；分组=同牧场+同品种+同生理阶段+有效样本 ≥5 天）——**聚合口径按 spec §4 两层定义实现**（检出数直加 vs 基线剔除发热覆盖 ≥50% 的日）——curl 真实数据冒烟（#25：200 且业务字段非空）。
2. Flutter 规格卡克隆：`DrinkingCard`（详情页健康 Tab 插入体温趋势卡同级）、`DrinkingDetailSection`（健康详情页第四分节）、状态卡组件（5 态）、Premium 锁定卡（复用/新建 LockedOverlay 组件）、图层 chips。
3. 图表实现**钉死（减少 Task 内现场决策）**：体温曲线叠加用 fl_chart `LineChart`——主温度线 + 第二数据列谷点（`FlDotCirclePainter` 白描边）+ 发热区间 `HorizontalRangeAnnotation`；时刻分布与 mini-bars 自绘（对齐项目既有自绘图惯例）；分段切换/图层开关状态管理走 Riverpod（farm-scoped 规则 §5：`watchActiveFarmId()`）。
4. i18n：spec §5 文案表（含四轮 F3：UI 无学术引用、发热口径精确句式）入 `app_zh.arb`/`app_en.arb`；实现对照**原型数据溯源表**（3c 节）逐数字核对端点字段。
5. 每 Task 内增量截图对照：Flutter Web build → 同尺寸截图 vs 基线 → `compare_screenshots.py` ≥85%，差异清零才提交。

**验证**：`flutter analyze` 零问题；gen-l10n 无缺失；6+2 屏对照图全过阈值，落 `output/fidelity/drinking/comparisons/`；主旅程走查（详情卡→详情分节→图层开关→锁定态）截图留证。

## Task 6 · L2 真实数据回放报告

1. dev/test 真实通道（THINGSBOARD/AGENTIC_PLATFORM）历史数据回放 30 天——**经 Task 4.3 批量触发端点**（省略 deviceId，指定 30 天范围），顺带验证该端点本身。
2. 检查三项：检出频次量级 vs 牲畜类别（泌乳牛对照 Cardot 7.3±2.8，其他类别自建分布）；V 形形态人工抽查 20 例；DATAGEN 零混入。
3. 报告落 `docs/research/`（含边界样张验证：0 次日/全发热周/英文长文案/textScale 1.3）。

**验证**：报告产出且三项有结论；异常样本清单回灌 T3 参数微调（如需改参数，同一次提交更新 spec/plan/配置）。

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

- 定参：`S_th = <待 T2>` °C/步（Δt 归一）、`k = <待 T2>`、`R_th = <待 T2>`、退热缓冲 6h（L2 复核）。
