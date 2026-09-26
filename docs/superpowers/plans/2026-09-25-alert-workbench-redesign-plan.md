# 告警工作台方案 A 高保真实施计划

> Spec：`docs/superpowers/specs/2026-09-25-alert-workbench-redesign-spec.md`
> 已确认交互原型：`docs/prototypes/alert-workbench-redesign-interactive-prototype.html`
> 方案对照存档：`docs/prototypes/alert-workbench-redesign-prototype.html`
> 原则：先保真基线，再后端口径，再共享前端组件，再牧场 Tab / 告警中心接入；每个 UI Task 结束都必须做截图对照。

## Task 0 · 保真基线与分支

1. 从当前已确认分支创建 `nix/246-alert-workbench`。
2. 用 Playwright 以 410×760、DPR 2 截取交互原型基线：
   - 牧场概览。
   - 牧场围栏。
   - 牧场告警 Tab。
   - 告警中心 all。
   - 告警中心 immediate / field / observe / resolved 筛选。
   - 围栏越界详情。
   - 健康 AI 观察详情。
   - 设备离线详情。
   - 今日已处理详情。
   - AI 排行。
3. 基线存入 `output/fidelity/alert-workbench/prototype/*.png`。
4. 建立元素清单：每屏记录四桶瓷砖、上下文条、资产 chips、卡片色脊、未读胶囊、详情五层、底部动作栏。

验证：基线图齐全可辨；清单覆盖原型全部交互状态。

## Task 1 · 后端枚举、迁移与设备离线

1. `AlertType` 增加 `DEVICE_OFFLINE`。
2. Flyway 重建 `alerts.type` CHECK，允许当前 Java 枚举全集，并补 `DEVICE_OFFLINE` 索引。
3. 新增设备信号只读端口，返回安装中 ACTIVE 设备的 `deviceId / farmId / livestockId / deviceCode / lastSeenAt`。
4. 新增设备离线调度：
   - 超过 2 小时无信号开 `WARNING` 单。
   - 幂等键 `(farmId, deviceId, DEVICE_OFFLINE, ACTIVE)`。
   - 恢复上报后 `AUTO_RESOLVED`。
   - 调度间隔 `alerts.device-offline.poll-ms`，默认 10 分钟。
5. 种子迁移选择一台已安装 ACTIVE 设备置为超过 2 小时无信号，并生成一条 ACTIVE `DEVICE_OFFLINE` 种子。
6. 后端 `messages_zh / messages_en / messages.properties` 同步 `alert.device.offline`。

验证：`./gradlew compileJava`；新增迁移在全新库执行；设备开单、幂等、自动恢复单测通过。

## Task 2 · 后端工作台聚合 API

1. 新增 DTO：`WorkbenchResponse`、`WorkbenchSummary`、`BucketSummary`、`AssetSummary`、`Asset`、`Reason`、`AiView`、`WorkbenchItem`。
2. 新增 `AlertWorkbenchService`：
   - 拉取农场告警、read 状态、牲畜、围栏、设备编码。
   - 复用健康 episodes 获取 AI band / finding / assessedAt。
   - 按 Spec §2.2 计算四桶。
   - 按 Spec §2.3 聚合资产。
   - 按 severity → unread → occurredAt 排序。
   - 支持 `bucket / asset CSV / fenceId / page / pageSize`。
3. 新增 `GET /farms/{farmId}/alerts/workbench`。
4. `dismiss` 与 `batch-handle` 权限扩展到 `WORKER`。
5. 保持旧 `/alerts`、`/alerts/summary`、read、dismiss、batch-read 不删除。

验证：`compileJava` + `test` 目标集；新增测试覆盖四桶映射、围栏牛去重、AI watch 未开单进 observe、设备离线、分页 total、WORKER dismiss、旧端点兼容。既有 19 个失败基线不得扩大。

## Task 3 · Flutter 模型与控制器

1. 新增 `AlertWorkbenchData`、`WorkbenchSummary`、`WorkbenchItem`、`WorkbenchReason`、`WorkbenchAi` 等容错模型。
2. 新增 `AlertWorkbenchRepository` 与 API 实现。
3. 新增 `AlertWorkbenchController extends FarmScopedAsyncNotifier<AlertWorkbenchData>`：
   - `watchActiveFarmId()`。
   - `bucket / asset / fenceId` 过滤。
   - `refresh / silentRefresh / loadMore`。
   - `markRead / dismiss` 后刷新工作台与概览摘要。
4. `/alerts` 路由解析新旧参数并映射到 controller。
5. 全局“牧场”角标继续使用未读总数；告警中心与牧场 Tab 共享同一数据源。

验证：`flutter analyze` 零新增；controller 测试覆盖过滤、分页、静默刷新、牧场切换。

## Task 4 · 共享工作台组件与统一详情 V2

新增组件：

1. `AlertWorkbenchSummaryTiles`：四桶瓷砖，红 / 橙 / 白 / 白状态。
2. `AlertWorkbenchFilterChips`：四桶与资产筛选。
3. `AlertWorkbenchCard`：色脊、图标、标题、资产、未读点、标签、证据摘要。
4. `AlertWorkbenchContextStrip`：概览 / 围栏 / 告警来源上下文。
5. `AlertWorkbenchDetailSheet`：
   - 风险头。
   - 下一步建议渐变卡。
   - 关键指标三格。
   - 证据列表。
   - 生命周期。
   - 底部固定动作栏。
6. `AiRankingSheet`：AI 档位排行与空态。

实现规则：

- 颜色、字号、圆角、阴影严格按 Spec §3。
- 动作按钮高度 32，主操作固定底部。
- 已处理详情不显示处理动作。
- 详情优先消费列表传入的 `WorkbenchItem`，避免卡片与详情数字不一致。

保真验证：Flutter Web 410×760 DPR 2 截图与 Task 0 基线并排对照；偏差超过 2px 必须修正或在 PR 说明原因。

## Task 5 · 告警中心替换

1. `/alerts` 页面替换为完整工作台。
2. 保留 appbar 批量入口与全部已读能力。
3. 四桶汇总 + 四桶筛选 + 资产筛选 + 分页列表。
4. `category=fence|health|device` 兼容映射。
5. `fenceId` 作为围栏上下文过滤。
6. 空态、加载失败、加载更多按原型状态实现。
7. 旧 `AlertsPage` 专用列表、旧 summary header、旧类型 chips、旧详情弹层从该页面移除；仍被其他页面复用的逻辑先保留，不 unrelated refactor。

保真验证：all / immediate / field / observe / resolved 五屏与原型对照；旧 deep link 冒烟通过。

## Task 6 · 牧场告警 Tab 接入

1. 牧场页内部三签保持概览 / 围栏 / 告警。
2. 告警签替换为紧凑工作台：上下文条、四桶、资产 chips、每桶前 3、AI 摘要入口。
3. 概览围栏 / 健康 / 设备入口点击后带上下文进入 `/alerts`。
4. 围栏页“去处置”进入 `/alerts?asset=fence&fenceId=...`。
5. 全局“牧场”底部角标继续显示未读；告警中心处理未读后同步减少。
6. 30 秒静默刷新不打断滚动；弹层 / 批量时暂停。

保真验证：概览 → 告警、围栏 → 告警、牧场告警 Tab 就地处理、处理后返回列表数字减少，四条链路截图或录屏留证。

## Task 7 · i18n 与静态检查

1. `app_zh.arb` / `app_en.arb` 同步新增：
   - 四桶名称、副标、空态。
   - 资产类型。
   - 上下文条。
   - 下一步建议。
   - 证据 / 生命周期。
   - 底部动作。
   - AI 排行与空态。
   - 设备离线。
2. `flutter gen-l10n`。
3. `flutter analyze` 零新增。
4. 检查无硬编码用户文案。

验证：中英切换走查告警 Tab、中心、详情；placeholder 类型一致。

## Task 8 · 高保真全量验证

1. `./gradlew compileJava`。
2. 后端目标测试，失败集合不扩大。
3. Flutter 目标测试 + `flutter analyze` + `flutter build web`。
4. Flutter Web 410×760 DPR 2 截图，与 `output/fidelity/alert-workbench/prototype/*.png` 逐屏对比。
5. 检查文本不溢出、不遮挡；四桶瓷砖、详情底部动作栏、空态、长标题、中英文均无布局破坏。
6. 输出最终截图到 `output/fidelity/alert-workbench/flutter/*.png`。

验收：Spec §11 全部通过；任何 1:1 偏差必须先修实现；确因 Flutter 平台差异无法完全一致时，记录原因并回到原型裁决，不允许静默降级。

## Task 9 · dev 部署与集成验证

1. `cd smart-livestock-server && ./scripts/deploy.sh dev`。
2. 部署判活：`main.dart.js` 本地与容器 hash 一致；种子账号登录 200。
3. curl 冒烟：
   - `/alerts/workbench?bucket=all&asset=all`
   - `bucket=immediate`
   - `asset=fence&fenceId=...`
   - `asset=livestock,herd`
   - `resolved`
4. 确认返回 `summary.buckets`、`summary.assets`、`items[].reasons` 业务字段非空。
5. 浏览器走查：
   - 概览 → 告警。
   - 围栏 → 告警。
   - 牧场告警 Tab → 详情 → 已读 / 处理。
   - 告警中心筛选 → 详情 → 返回数字同步。
   - AI 排行 → 详情。
   - 设备离线种子 → 详情。
   - WORKER / OWNER 权限差异。
6. 中英文切换走查。

验证：截图与 curl 结果归档到 `output/fidelity/alert-workbench/dev/`。

## Task 10 · 收尾

1. 用户 dev 集成测试。
2. 用户确认通过后提交并推送 `nix/246-alert-workbench`。
3. PR 描述附元素清单、保真截图、curl 证据、测试结果。
4. test 环境部署等待用户明确通知。

## 风险与回退

| 风险 | 缓解 |
|---|---|
| 工作台聚合重复计算导致数字不一致 | summary、items、详情都来自同一 service 返回 |
| `DEVICE_OFFLINE` 调度误报 | 只监控 active installation 的 ACTIVE 设备；使用最新信号最大值；恢复自动关单 |
| 权限扩展影响安全面 | 仅扩展 dismiss / batch-handle；操作者继续落库可审计 |
| 旧告警中心深链断链 | 保留 `/alerts` 路由与 category 映射 |
| 1:1 保真走样 | Task 0 基线、Task 8 全屏对照、Task 9 dev 走查三层拦截 |
