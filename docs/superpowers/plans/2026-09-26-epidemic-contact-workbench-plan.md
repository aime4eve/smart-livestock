# 接触追踪三视图工作台实施计划

> Spec：`docs/superpowers/specs/2026-09-26-epidemic-contact-workbench-spec.md`
> 原型：`docs/prototypes/contact-tracing-unified-experience.html`（已确认，唯一视觉真源）
> 原则：先后端统一口径，再前端模型与组件，再三视图接入；每个 UI Task 都必须与原型截图对照。

## Task 0 · 保真基线与分支

1. 创建分支 `nix/epidemic-contact-workbench`。
2. 用 Playwright 以 390×844、DPR 2 截取统一原型基线：
   - 处置视图首屏。
   - 处置队列展开证据。
   - 记录视图首屏。
   - 记录视图 24h / 48h / 72h / all。
   - 链路视图图谱。
   - 高风险路径与证据列表。
   - 空 / 错误 / Premium 锁定态可使用原型局部补图或设计标注。
3. 基线保存到 `output/fidelity/epidemic-contact-workbench/prototype/*.png`。
4. 从原型生成元素清单，覆盖 AppBar、Tab、共享概览、四级卡、牛只卡、记录卡、链路图、底部操作栏。

验证：基线截图齐全；元素清单与原型 DOM 一一对应。

## Task 1 · 后端枚举、迁移与种子

1. 新增枚举：
   - `EpidemicDispositionTier`: `CRITICAL / OBSERVATION / TRACKING / ARCHIVE`。
   - `EpidemicDispositionAction`: `ISOLATE_NOTIFY_VET / IMMEDIATE_VET_CHECK / HEALTH_RECHECK / CONTINUE_TRACING / ARCHIVE_ONLY`。
   - `EpidemicDispositionStatus`: `PENDING / IN_PROGRESS / COMPLETED / CANCELLED`。
2. 新增 Flyway `V20260926100000__epidemic_contact_workbench.sql`：
   - 创建 `epidemic_dispositions`。
   - 创建枚举 CHECK、部分唯一索引和查询索引。
   - 按 Spec §8.1 写入 5 条幂等种子。
3. 扩展 ContactTrace 仓储查询：
   - 按 farm、时间窗、from/to 双向查询。
   - 按源头出边查询。
   - 不沿用 overview 的 20 条限制。
4. 新增 `EpidemicDispositionRepository` 和基础 JPA 实体。

验证：

- `./gradlew compileJava`。
- 新迁移在本地全新库执行成功。
- 种子 select 断言：5 条任务、枚举合法、时间顺序合理。
- 既有 contact trace 查询测试不回归。

## Task 2 · 后端聚合与四级分级服务

1. 新增 DTO：
   - `EpidemicWorkbenchResponse`
   - `EpidemicWorkbenchContext`
   - `EpidemicSource`
   - `EpidemicTierSummary`
   - `EpidemicLivestockWorkbenchItem`
   - `EpidemicHealthSignal`
   - `EpidemicEventItem`
   - `EpidemicNetworkGraph`
   - `EpidemicGraphNode`
   - `EpidemicGraphEdge`
   - `EpidemicGraphPath`
2. 新增 `EpidemicWorkbenchService`：
   - 解析源头：优先 query source，否则取最新 `markedAt`。
   - 拉取窗口内接触事件、健康快照、活跃健康/疫病告警、牲畜编码。
   - 复用现有三维评分公式计算事件风险。
   - 聚合每头牛的 `maxRiskScore`、`directSourceContact`、`shortestDepth`、`lastContactAt`。
   - 按 Spec §3.3 计算四级、动作和时限。
   - 构建 BFS 两跳图谱与路径累计风险。
   - 合并已有处置任务状态。
3. 阈值配置化：
   - `health.epidemic.workbench.window-hours=72`
   - `health.epidemic.workbench.critical-risk=70`
   - `health.epidemic.workbench.critical-no-health-risk=80`
   - `health.epidemic.workbench.observation-risk=40`
4. 新增：

   ```http
   GET /api/v1/farms/{farmId}/health/epidemic/workbench
   ```

5. 保留旧 `/health/epidemic` 和 `/health/epidemic/contacts/{livestockId}`。

验证：

- 单测覆盖：一级行 1、一级行 2、二级、三级、四级。
- 无健康快照、无围栏名、无活跃源头、多源头、窗口切换、路径断链均有测试。
- 排序测试：等级 → 风险 → 最近时间 → 编码。
- `compileJava` + 后端目标测试通过；既有失败集合不得扩大。

## Task 3 · 处置动作 API

1. 新增创建接口：

   ```http
   POST /api/v1/farms/{farmId}/health/epidemic/dispositions
   ```

   - 按 workbench 分级校验 `tier` 和 `actionCode`。
   - 已有 `PENDING / IN_PROGRESS` 任务时幂等返回。
2. 新增完成 / 取消接口：
   - `POST .../dispositions/{id}/complete`
   - `POST .../dispositions/{id}/cancel`
   - 记录 `completedBy / completedAt / cancelReasonCode`。
3. 源牛 `unmarkDiseased` 后：
   - 取消相关 `PENDING / IN_PROGRESS` 任务。
   - 保留历史完成记录。
4. 权限按 Spec §12 默认值：
   - OWNER / B2B_ADMIN 可处理一级任务。
   - WORKER 可标记观察、完成观察/追踪任务。
5. 服务端消息中英同步。

验证：

- 创建幂等、非法等级拒绝、完成/取消审计、重复完成拒绝。
- WORKER 与 OWNER 权限边界测试。
- 取消源头后活跃任务状态更新。

## Task 4 · Flutter 模型、仓储与控制器

1. 新增容错模型：
   - `EpidemicWorkbenchData`
   - `EpidemicSourceData`
   - `EpidemicTierData`
   - `EpidemicLivestockItem`
   - `EpidemicHealthData`
   - `EpidemicEventData`
   - `EpidemicNetworkData`
2. 新增 `EpidemicWorkbenchRepository` 与 API 实现。
3. 新增 `EpidemicWorkbenchController extends FarmScopedAsyncNotifier<EpidemicWorkbenchData>`：
   - `watchActiveFarmId()`。
   - 保存 `view / sourceLivestockId / window`。
   - `refresh / silentRefresh / changeWindow / selectSource`。
   - 创建、完成、取消处置后局部刷新。
4. 路由：
   - `/twin/epidemic` 解析 `view / sourceLivestockId / window`。
   - `/twin/epidemic/contacts/:livestockId` 重定向到 network 深链。
5. 订阅锁定继续复用 `FeatureFlags.epidemicAlert`。

验证：

- JSON 容错测试：字段缺失、null、类型兼容。
- controller 测试：牧场切换、窗口切换、动作后刷新、失败保留旧数据。
- `flutter analyze` 零新增问题。

## Task 5 · 共享组件

新增组件：

1. `EpidemicModeTabs`
2. `EpidemicSourceSummaryCard`
3. `EpidemicTierSummaryGrid`
4. `EpidemicLivestockQueueCard`
5. `EpidemicEvidenceToggle`
6. `EpidemicRiskEventCard`
7. `EpidemicRiskFactorChips`
8. `EpidemicNetworkGraphView`
9. `EpidemicPathCard`
10. `EpidemicBottomActionBar`

实现规则：

- 颜色、字号、圆角、阴影按 Spec §5。
- 所有等级、动作、时间、成因文案经 l10n。
- 数字和状态只消费 controller 的统一模型。
- 一级/二级色脊和 soft 胶囊必须可区分。

保真验证：

- 单组件 Flutter Web 截图与原型局部对照。
- 色值、边框、圆角、文本行数逐项核对。

## Task 6 · 三视图页面接入

### 6.1 处置视图

1. 共享概览 + 四级卡。
2. 一级 / 二级 / 三级 / 四级分组队列。
3. 展开接触证据。
4. 主动作和传播链跳转。
5. 已完成 / 已取消态。

验证：与原型首屏和展开态对照；点击传播链保留 `sourceLivestockId`、`window` 和目标牛上下文。

### 6.2 记录视图

1. 高/中/低数量。
2. 24h / 48h / 72h / all chips。
3. 风险事件列表。
4. 成因 chips。
5. “按牛只处置”跳转并定位到对应等级分组。

验证：四档窗口数字与后端一致；跳转后目标牛可见。

### 6.3 链路视图

1. 源头卡。
2. 一阶图谱。
3. 高风险路径。
4. 调查结论。
5. 证据列表。
6. 节点/边到牛只与事件上下文。

验证：图谱在 390 宽度无重叠；长牛号省略；点击节点/边不触发误跳。

## Task 7 · i18n 与可达性

1. 补齐 Spec §9 全部中英文案。
2. 执行 `flutter gen-l10n`。
3. 中英切换走查三视图。
4. 检查长文本：病种、牛号、围栏名、按钮文案、英文等级名。
5. 检查触控目标、语义标签、焦点顺序和颜色以外状态提示。

验证：`flutter gen-l10n` 无缺失；`flutter analyze` 零新增；无硬编码用户文案。

## Task 8 · 全量验证

1. `./gradlew compileJava`。
2. 后端目标测试：workbench 分级、处置幂等、旧接口兼容、迁移。
3. Flutter 目标测试 + `flutter analyze` + `flutter build web`。
4. Flutter Web 390×844 DPR 2 截图，与 Task 0 基线逐屏对比。
5. 长牛号、无围栏、空接触、单节点、超时任务、已完成任务、Premium 锁定逐项截图。
6. 输出最终截图到 `output/fidelity/epidemic-contact-workbench/flutter/*.png`。

验收：Spec §11 全部满足；偏差必须先修，不允许静默降级。

## Task 9 · dev 部署与集成冒烟

1. `cd smart-livestock-server && ./scripts/deploy.sh dev`。
2. 判活：
   - 本地与容器内 `main.dart.js` hash 一致。
   - 种子账号登录 200。
3. curl 新接口：
   - `/health/epidemic/workbench`
   - `windowHours=24 / 48 / 72 / 0`
   - `tier=CRITICAL`
   - `maxDepth=2`
4. curl 断言：
   - `tiers` 四级 key 完整。
   - 种子 5 头牛的 tier / action / status 非空。
   - `events[].riskScore`、`factorCodes` 非空。
   - `network.paths` 至少一条示例路径。
5. 浏览器走查：
   - 疫病防控 → 处置 → 证据 → 传播链。
   - 链路 → 打开处置队列。
   - 记录 → 按牛只处置。
   - 标记观察 → 状态刷新。
   - 完成/取消任务。
   - 中英文切换。
6. 截图和 curl 结果归档到 `output/fidelity/epidemic-contact-workbench/dev/`。

## Task 10 · 收尾

1. 用户 dev 集成测试。
2. 用户确认后提交并推送 `nix/epidemic-contact-workbench`。
3. PR 描述包含：
   - 元素清单勾选。
   - 四级分级规则摘要。
   - API 契约变更。
   - 保真截图对照。
   - curl 与测试证据。
4. test 环境部署等待用户明确通知。

## 风险与回退

| 风险 | 缓解 |
|---|---|
| 前后端分级口径不一致 | 等级、动作、时限全部后端下发；前端禁止重算 |
| 旧 overview 20 条截断造成漏报 | 新接口独立查询窗口全量；旧接口仅兼容 |
| 多跳图谱数据量增长 | V1 `maxDepth=2`，最大 3；超过阈值提示缩小窗口 |
| 处置任务重复创建 | 部分唯一索引 + 服务幂等 |
| 一级动作误用 | OWNER / B2B_ADMIN 确认；WORKER 动作受限 |
| 健康信号缺数据 | `healthSignal=false` 兜底，不猜测 |
| 保真走样 | Task 0 基线 + Task 5 组件对照 + Task 8 全屏对照 |
