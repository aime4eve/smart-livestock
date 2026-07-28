# NIX-68 GPS 线路检验（LINE）实施计划

依据：`docs/superpowers/specs/2026-07-28-nix68-track-line-inspection-spec.md`（已评审修订，§1.4 范围声明确认分期）
原型：`docs/marketing/nix-68-track-line-inspection-prototype.html`（v3，已确认）
完成后归档：本计划复制到 `docs/superpowers/plans/2026-07-28-nix68-track-line-inspection-plan.md`

## Task 0 — 视觉保真准备

- 从原型 `:root` 提取 38 个设计令牌（spec §9 令牌表），确认 Flutter 侧落点：新增线路检验主题色 `--c-line:#0F766E`、分级色（EXCELLENT/USABLE/MARGINAL/UNAVAILABLE），MARGINAL 色以令牌 `#C2410C` 为准统一（spec §12 已注明与前端旧值 `#B45309` 的差异）。
- 保真验证基准：原型 5 个界面（真值管理标准轨迹视图、导入向导 3 步、地图预览、新建检验、报告/对比）。

## Task 1 — Flyway 迁移

新建 `smart-livestock-server/src/main/resources/db/migration/V20260728100000__nix68_track_line_inspection.sql`：
- `gps_quality_tests` 加 `track_line_id BIGINT REFERENCES standard_track_lines(id) ON DELETE SET NULL`；`chk_test_type_truth` 按 `V20260722100000:15-20` 同写法 DROP+ADD，放开 LINE 分支
- 索引：`idx_gqt_device_type_time(device_code, test_type, created_at DESC)`、`idx_gqt_track_line(track_line_id)`
- 新表 5 张：`standard_track_lines`（名称/状态 CANDIDATE|SELECTED/点数/全长/来源文件名/导入时间/tenant）、`standard_track_line_points`（line_id/sequence_no/lng/lat，无时间戳）、`gps_quality_line_points`（检验时点列快照）、`gps_quality_line_results`（统计+分级快照）、`gps_quality_line_deviations`（逐点偏差快照，含 segment_no）
- 无种子数据（标准轨迹来自用户导入，同 NIX-22 §5.4）
- 验证：`./gradlew compileJava` 通过；部署后查 `flyway_schema_history`

## Task 2 — 后端 domain 层

- `TestType.java` 追加 `LINE`（VARCHAR(10) 无需扩列）
- `GpsQualityTest.java` 加 `trackLineId` 字段 + getter/setter + 含 trackLineId 构造器，Javadoc（:13-14、:57）更新覆盖 LINE
- 新增 domain model：`StandardTrackLine`、`StandardTrackLinePoint`（DDD 四层：model + repository 接口 + SpringData + JpaImpl + JpaEntity）
- 新增 `TrackLineCalculator`（纯算法无 IO）：点到折线段最短距离（等距圆柱局部投影，<几 km 误差 <0.1%）、聚合 mean/p50/p95/max + 15/25/40m 占比、分级沿用 `QualityGrade` 阈值（p95≤15 且 samples≥10 → EXCELLENT 等，spec D10）
- 单测 `TrackLineCalculatorTest`：折角处投影、端点外垂足退化、空点列、分级边界

## Task 3 — 后端 application + interfaces 层

- `StandardTrackLineService`：parse 预检 → import 落库两段式（对齐 `/trajectory/parse|import`）；RTK XLSX 解析（单 sheet"线路追踪"、8 列单行、坐标列按 \n 切分逐行 trim 兼容 \r\n、`经度,纬度,高程` 三元组忽略高程、上限 20000 点）；清洗=去连续重复点；全长实算；元数据（开始/结束时间、长度列）不采信、解析失败不阻断；名称默认取"名称"列
- `TrackLineCheckService`：`GET /line-checks/devices`（时间窗内有 gps_logs 的设备+点数+首末时间）；`POST /line-checks`（逐设备建 LINE test + 点列快照 + 同步计算 + 结果快照，status=READY，不引入 DEVICE_PENDING——spec §6.5 负载结论：最坏场景 <10s）
- `TrackLineReportService`：`/tests/{id}/line-report`（仅统计摘要）+ `/line-report/track`（点列快照）+ `/line-report/deviations?limit=`；`GET /checks/summary?deviceCode=`（4 类型最近一次检验聚合，不动 `/checks`）；`GET /comparison/line`（不传 deviceCode 只回统计表+标准轨迹点列，设备轨迹点按 deviceCode 逐个加载）
- 端点挂 `GpsQualityAdminController`（或同前缀新 Controller），沿用 PLATFORM_ADMIN / ApiResponse / TenantContext fallback / parseInstant UTC 面值
- 验证：编译通过；`TrackLineCalculatorTest` 绿

## Task 4 — 前端：真值管理 Tab 加"标准轨迹"

`Mobile/mobile_app/lib/features/admin/gps_quality/presentation/truth_reference_tab.dart` 增第三类真值：
- 分类页签：RTK 真值点 / 动态路线 / **标准轨迹**
- 标准轨迹视图：工具栏（导入、合成置灰标注二期）+ 候选表格（名称/点数/全长/导入时间/状态/操作：预览、选定、删除）+ 管理规则说明
- 导入向导 3 步 dialog（参照 `trajectory_import_dialog.dart`）：上传 XLSX → 解析预览（原始/去重点数、实算全长、起终点、前 8 点）→ 导入结果
- 地图预览弹窗：flutter_map + 离线瓦片 + PolylineLayer（参照 `lib/features/livestock/presentation/widgets/trajectory_sheet.dart:618-650`）
- 数据层：`gps_quality_api_repository.dart` 加 track-lines 端点方法 + providers
- 保真验证：对照原型界面 ①②③ 逐项核对令牌（颜色/间距/圆角）

## Task 5 — 前端：检验列表统一报告 + LINE 报告面板

`quality_check_list.dart`：
- 新增"检验结果汇总"区（`/checks/summary`）：静态/动态/轨迹/线路 4 行（最近检验时间、分级徽章、关键指标），"查看报告"= 设选中 checkId 落入既有 `_buildReport` 分派
- `_buildReport`（:693-710）if 链在 TRAJECTORY 分支后追加 LINE 分支 → 新 `LineReportPanel`（内联右栏，非弹窗）：指标卡 + flutter_map 对比（绿色标准线 vs 红色设备轨迹）+ 逐点偏差明细表（走拆分后的子端点）
- 既有 STATIC/DYNAMIC/TRAJECTORY 三分支零改动
- 保真验证：对照原型界面 ④⑤

## Task 6 — 前端：质量对比加第 4 段

`comparison_tab.dart`：
- `SegmentedButton<int>`（:40）3 段扩 4 段，新增"线路检验"
- 线路对比视图：条件条（标准轨迹下拉 + 时间范围 + 设备 chip 多选）→ 同图叠加地图（绿色标准线 + 多设备多色轨迹）+ 横向对比表（样本数/mean/p50/p95/max/分级）
- 前 3 段及其端点不动

## Task 7 — i18n + 静态检查

- `app_zh.arb` / `app_en.arb` 同步新增 `gpsQualityLine*` keys（双语对齐，spec §8.8）
- `flutter gen-l10n` 无缺失 key；`flutter analyze` 无未定义引用
- 后端 `messages_zh/en.properties` 如需新增错误消息则双语同步

## Task 8 — 端到端验证（spec §11 验收标准）

- 编译：`./gradlew compileJava` + `flutter analyze` 全绿
- 部署 dev：`./scripts/deploy.sh dev`
- 集成测试（部署后执行）：导入 `轨迹检验线路1/2/3.xlsx` → 3 条候选，点数 430/387/406、全长 1177/1192/1192m 与实算一致；选定一条 → 发起 LINE 检验 → READY + 快照一致；删除候选后历史报告仍可完整打开；三类既有检验回归无变化

## 不做（spec §10 实现边界）

合成算法（二期，仅入口预留）、方向校验、多格式导入识别、动态检验任何改动
