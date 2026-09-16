# 告警体验升级 V2 · 实施计划（plan）

> 状态：待用户确认（阶段 3/4）
> spec：`docs/superpowers/specs/2026-09-16-alert-experience-v2-spec.md`（已锁定）
> 原型：`docs/prototypes/livestock-alert-experience-v2-prototype.html`（已确认）
> 约定：每个含 UI 的 Task 完成后做一次**保真对照**（Flutter 截图/调试页面 vs 原型对应屏），偏差记录进提交说明；全部 Task 完成后统一走 dev 冒烟。

---

## Task 0 · 视觉保真准备
- 从原型提取《规格卡》：token 映射表（spec §1）、四屏组件清单、尺寸/字号/色值速查（spec §4）；
- 确认 Flutter 侧无缺失颜色（AppColors.info=0xFF4A7F9D 等逐一核对）；
- 产物：本文件附录 A 规格卡（实施时随 Task 引用）。
- 保真验证：无 UI，跳过。

## Task 1 · 后端：summary 端点
1. `AlertSummaryDto`（ranch/application/dto）：`ActiveSummary(total,unread,critical,warning,info,byGroup,byGroupUnread)` + `AlertSummaryResponse(active,resolved)`；
2. `SpringDataAlertReadStatusRepository` 增未读计数 JPQL（跨实体子查询，@Query 返回 long）；
3. `SpringDataAlertRepository` 增分组计数查询（或 service 内单查询+内存分组——告警量级小，选 JPQL 一次取 `status,severity,type,count` 聚合行）；
4. `AlertApplicationService.getAlertSummary(farmId,userId)`：聚合 + 类型组映射 + Redis 缓存（key `alerts:summary:{farmId}:{userId}`，TTL 10s）；
5. 读/忽略/批量已读/autoResolve 写路径末尾删缓存 key；
6. `AlertController` 增 `GET /alerts/summary`。
- 验证：compileJava + 新增 `AlertSummaryTest`（单测：分组映射/未读子查询 mock/缓存命中）；保真验证：无 UI，跳过。

## Task 2 · 后端：/alerts 真分页
1. `SpringDataAlertRepository` 增 `findByFarmIdAndOptionalFilters(farmId, statusList, severity, Pageable)`（@Query，status 传集合实现 RESOLVED=DISMISSED∪AUTO_RESOLVED）+ 对应 count 方法（或返回 `Page`）；
2. `AlertRepository` port 增分页方法（返回 items+total 的记录或 Page 映射）；`JpaAlertRepositoryImpl` 实现；
3. `AlertApplicationService.listByFarmPaged(farmId,userId,status,severity,page,size)`：read 富化（复用 findReadAlertIdsByUserId）+ deviceCode 富化（复用 deviceCodes）；
4. `AlertController` 重接（status=RESOLVED 翻译为集合；page/pageSize 边界处理）；`OpenAlertController` 同步；
5. **测试修复**：`AlertReadStatusTest`/`AlertApplicationServiceTest` 补 `@Mock IoTQueryPort`（既有 NPE 地雷）；受影响单测更新；`listByFarmWithReadStatus`/`findByFarmIdRecent` 若无其他调用方则删除。
- 验证：compileJava+TestJava；目标测试（Alert 相关 + JourneyIntegrationTest/WorkerJourneyTest/DashboardMeJourneyTest 编译层）；对比既有失败基线不扩大。保真验证：无 UI。

## Task 3 · 前端：模型与控制器
1. 新 `RanchAlertSummary`（features/alerts/domain/alert_summary.dart）+ `alertSummaryControllerProvider`（FarmScopedAsyncNotifier，GET /alerts/summary，fromJson 容错）；
2. `alerts_api_repository.loadAlerts` 支持 page/pageSize/status(RESOLVED)/severity 透传；`AlertsListData` 增 total 语义说明；
3. `AlertsController`：`silentRefresh()`（不置 AsyncLoading）、`loadMore()`（追加 items、页码推进）、severity 过滤即 API 参数、默认 pageSize=50、`_filterStatus` 映射 RESOLVED；
4. ranch 30s Timer 追加 summary 静默刷。
- 验证：analyze 零新增；controller 单测（分页推进/RESOLVED 映射）。保真：无 UI。

## Task 4 · 前端：五个新组件（保真重点）
`features/alerts/presentation/widgets/` 下新建：
1. `alert_summary_header.dart`（hero 两格+三格+对账行，回调 onSeverityToggle/onClearFilter）；
2. `refresh_hint.dart`（state: refreshing/paused/ok）；
3. `fence_status_card.dart`（聚合输入=List<RanchAlertData>+livestockMarkers，内部按(牲畜,围栏)去重；展开/收起；行/底部回调）；
4. `unread_badge.dart`；
5. `load_more_footer.dart`（shown/total/active/resolved + onLoadMore + loading 态）。
- 保真验证：组件单测/黄金页（临时调试路由或 widget test）逐项对照原型屏 1/3 的尺寸字号色值；`flutter test` 相关用例。

## Task 5 · 前端：告警中心页重构
1. 汇总区换 AlertSummaryHeader（数据=summary provider，独立于列表过滤）；移除 AlertSummaryStrip 引用与 alertSummaryPending 文案；
2. 默认 tab=活跃；tab→status 映射；severity 三格点击=controller.setFilterSeverity；
3. 列表接 loadMore + LoadMoreFooter；切换筛选重置；
4. AutoRefreshListener 包 body（批量模式/弹层打开时暂停；onTick=silentRefresh+summary 静默刷）；
5. 空状态按 spec 4.6；
6. 全部已读联动 summary。
- 保真验证：对照原型屏 1（含对账行文案）与屏 4（空状态）截图。

## Task 6 · 前端：牧场页
1. 底部告警 tab 角标 + 概览三卡数字/红点改接 summary（byGroup/byGroupUnread/active.unread）；
2. 告警 tab 顶部插 FenceStatusCard（overview.alerts+livestockMarkers 聚合）；
3. 事件行点击带 category 预筛选跳告警中心（补 NIX-52 遗留）。
- 保真验证：对照原型屏 2/3。

## Task 7 · l10n + 静态检查 + 测试
1. arb 新增 15 key（zh 模板+en 同步，占位符类型一致）+ gen-l10n；
2. `flutter analyze` 零新增；
3. widget 测试：汇总三格加总显示、聚合卡去重计数、未读徽标 0 隐藏、分页 footer 文案；既有 alerts/ranch 测试修复。
- 保真验证：文案与原型逐字对照。

## Task 8 · 部署 dev + 冒烟验收
1. build_web.sh → deploy.sh dev；
2. 冒烟清单（spec §7 验收对照逐条）：summary 加总恒等式、未读三处联动、>200 条 total 真实、聚合卡去重数、30s 刷新不打断、analyze/gen-l10n/测试全绿证据；
3. 附 before/after 数字对照（dev 实测）。

## Task 9 · 收尾
1. 用户 dev 集成测试；
2. 通过后 git 提交（与围栏计数/详情按钮/设备告警信息三笔一起或分批）；知识库沉淀（结论+踩坑）；
3. test 环境部署等用户通知。

---

## 附录 A · 规格卡（Task 0 产物速查）
- 汇总 hero：数字 24/w700；label 9；padding 10,12,8；竖分隔 1px border；活跃 primary、未读 danger、未读 0 透明度 .55
- 三格：26px 高、圆角 6、背景 surface、点 6px、数字 11/w700、标签 9；选中=primary 边框+primarySoft 底
- 对账行/刷新条/页脚 meta：8px textSecondary
- 聚合卡：圆角 12、边框 rgba(194,86,75,.25)；头部图标 30×30 圆角 9；明细点 8px；编号 10/w600 宽 64
- UnreadBadge：≥15×15 胶囊、白字 8/w700
- 加载按钮：10/w600 primary、primarySoft 底、圆角 8、padding 7/18
