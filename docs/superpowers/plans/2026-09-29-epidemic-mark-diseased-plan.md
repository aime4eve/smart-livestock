# 疫病"标记患病"入口实施计划

> Spec：`docs/superpowers/specs/2026-09-29-epidemic-mark-diseased-entry-spec.md`（四项裁决已锁定）
> 原型：`docs/prototypes/2026-09-29-epidemic-mark-diseased-prototype.html`（7 屏，唯一视觉真源，令牌已沿用项目现有）
> 原则：先接触判定内核（两轨共用），再常驻轨，再即时轨与标记语义，再种子，最后前端三入口与保真；每个 UI Task 与原型截图对照。
> 分支：`nix/epidemic-mark-diseased`（自 `master` 新建；当前修复分支另行合流）

## Task 0 · 保真基线与分支

1. 合并/等待 `fix/health-scene-card-overflow` 进 master（8 提交含疫病空态修复），自 master 建 `nix/epidemic-mark-diseased`。
2. Playwright 390×844、DPR 2 截取原型 7 屏基线 → `output/fidelity/epidemic-mark-diseased/prototype/*.png`。
3. 元素清单：弹层（grab/标题/who/病种 chips/其他输入/hint/双按钮）、详情页动作行两态、源头徽标+信息条、空态、告警动作、升级弹层、概览副文两段式。

验证：基线截图齐全；元素清单与原型 DOM 一一对应。

## Task 1 · 后端接触判定内核（两轨共用）

1. 新增 `ContactAnalysisService`（health.application.service）：
   - 输入：farmId、livestockId（或全群）、窗口 `Instant cutoff`。
   - 读取 `gps_logs`（经现有 GPS 仓储/查询端口）做牛对轨迹对齐；参数化阈值：`distance≤30m`、`累计≥5min`、窗口默认 72h（配置 `health.contact.*`）。
   - 产出：`List<ContactAnalysisResult>`（from/to/proximityMin/durationMinutes/lastContactAt + 复用 `calculateTimeScore/DistanceScore/DurationScore` 打分）。
2. 幂等 upsert 规则：仅覆盖**未标记**（markedAt IS NULL）的 from→to 行；已标记行不动。
3. 单测（Testcontainers 真库，教训 #19）：构造两条牛交错轨迹→断言接触行/距离/时长；阈值边界（29m/31m、4min/6min）各一例；已标记行不被覆盖。

验证：`./gradlew compileJava` + 新测试绿；既有 contact trace 测试不回归。

## Task 2 · 常驻轨：ContactAnalysisScheduler

1. 每日 02:00（`health.contact.analysis-cron`）逐牧场执行 Task 1 内核，写接触池。
2. 结构化日志：farmId、窗口、分析行数、耗时；窗口内无 GPS → INFO 跳过（非失败）。
3. 手动触发端点（管理侧）便于验证，不加面向用户的 UI。

验证：本地/容器手动触发后 `contact_traces` 未标记行非空且字段合理；重复触发结果稳定（幂等）；日志字段齐全。

## Task 3 · 即时轨：markDiseased 两段式改造

1. `markDiseased(farmId, livestockId, diseaseType, windowHours)`：
   - ① 跑同口径即时分析（upsert 未标记行）② 标记该牛出向行 `diseaseType/markedAt`。
2. 响应体从 `Void` 改为 `{contactsGenerated: int}`；0 时附提示码 `error.epidemicNoGpsWindow`（HTTP 仍 200）。
3. Controller `MarkDiseaseRequest` 增加 `windowHours`（1–720 钳制，可空）。
4. `unmarkDiseased` 行为不变（Controller 已有 `cancelActiveBySource`）。
5. 单测：标记后 traces 带 markedAt；重复标记=重算再标记；contactsGenerated 正确。

验证：`compileJava` + 测试绿；curl 冒烟（有 GPS 牛/无 GPS 牛两例）。

## Task 4 · 迁移种子（演练数据）

1. `V2026xxxx__epidemic_drill_seed.sql`：按 farm 1 现存牛群（按 id 顺序前 4 头，无 deleted）动态构造演练源头+接触，`disease_type='疫情演练'`。
2. **行数校验 fail-loudly**：插入后 `DO $$ ... IF NOT EXISTS ... RAISE EXCEPTION`（杜绝 V31 式静默 0 行）。
3. 幂等：存在 `疫情演练` 行则跳过。

验证：本地全新库迁移通过；test 部署后演练行非空；重复执行幂等。

## Task 5 · 前端 MarkDiseasedSheet 共享弹层

1. `features/epidemic/presentation/widgets/mark_diseased_sheet.dart`：按原型 P1/P2——grab、标题、who、5 病种 chips（选中态 danger-soft/danger）、"其他"输入、hint、取消/确认。
2. 病种常量 + ARB 全量 key（spec §8 表）；`contactsGenerated` toast 两态文案；成功跳 `/twin/epidemic?sourceLivestockId=`。
3. 提交 busy 态防重（教训：busy 泄漏永久禁用——用 try/finally）。
4. `epidemicRepositoryProvider.markDiseased` 签名同步（windowHours）。

验证：analyze/gen-l10n 无缺失；414 宽视口渲染与原型 P1/P2 对照截图一致。

## Task 6 · 牲畜详情页入口（两态）

1. 详情页健康信息卡底部动作行：
   - 未标记态：`🦠 标记疑似患病`（P1）；已标记态：徽标+信息条+`查看疫病工作台/取消染病标记`（P3）。
   - 取消二次确认弹窗（明示连带取消处置单数）→ `DELETE` 后刷新。
2. 已标记态数据源：牲畜维度"是否源头/病种/标记时间/接触数"——后端补轻量查询（复用 workbench context 或 `findByFromLivestockId...markedAt != null`）。
3. 权限：非 OWNER/B2B_ADMIN 隐藏按钮；免费用户点击走 P6 升级弹层（复用 `subscriptionControllerProvider` + `checkTierAccess(FeatureFlags.epidemicAlert)`）。

验证：三角色（OWNER/普通/免费）可达性倒查；两态截图与 P1/P3 对照。

## Task 7 · 工作台空态增强 + 疫病告警动作

1. `_NoSourceState` 加"去选择病牛"主按钮（P4，跳围栏页牛只列表）+ 文案按 spec §8 更新。
2. EPIDEMIC 类告警卡动作区加"标记为源头"（P5，预填牛只直接弹 Sheet）；告警详情/列表两处都挂（对照 #25 全挂载点盘点）。
3. 免费用户同走升级引导。

验证：两入口真机/浏览器走查截图；告警非 EPIDEMIC 类不显示该动作。

## Task 8 · 概览疫病卡两段式副文（P7）

1. `ranch_page.dart` 场景卡疫病副文：`epiOver && 无标记源头` 时 `sceneEpidemicFootAbove` 换新 key（`· 未标记源头` 红字段）。
2. "无标记源头"判定：概览 scene 响应补 `hasMarkedSource` 布尔（后端 workbench/scene 聚合已有 traces 可判）。

验证：有/无源头两数据态截图对照 P7；analyze 通过。

## Task 9 · 收口

1. 视觉保真：`prototype-to-flutter-fidelity` 流程对 7 屏逐一对照（元素+令牌+间距）。
2. 编译：`flutter analyze`、`gen-l10n`、`compileJava` 全绿。
3. 部署 dev：`build_web.sh` + `deploy.sh dev`；`release.sh` 发新版（b758）→ 部署 test（用户授权）→ 重打 APK/IPA。
4. 端到端验收（spec §9）：三入口主旅程、双轨数据、种子非空、权限/订阅、回归（工作台既有功能、概览卡）。
5. 集成测试（用户真机）→ PR 合并 master → 关工单。

## 依赖与顺序

Task 1 → 2 → 3 →（4 可并行）→ 5 → 6 → 7 → 8 → 9。前端 5-8 依赖 3 的响应字段；6 依赖 2 的轻量查询可与 3 并行。
