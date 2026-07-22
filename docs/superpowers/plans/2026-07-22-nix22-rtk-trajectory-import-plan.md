# NIX-22 RTK 轨迹导入动态检验 — 实施计划

> **For agentic workers:** Use task-by-task implementation with checkbox tracking. Each task has verification criteria that must pass before proceeding to the next.

**Goal:** 新增第三种检验类型 TRAJECTORY（轨迹动态）：从文件导入「设备EUI + 采集时间 + RTK经纬度（+ 可选设备经纬度）」，缺省设备坐标时按 EUI+时间从 gps_logs 配对（±60s 可调），配对快照固化，产出配对报告并纳入质量对比。

**Architecture:** 后端 Spring Boot 3.3 / Java 17（DDD 四层），前端 Flutter（Riverpod），DB PostgreSQL 16 + Flyway。XLSX 解析复用现有 Apache POI；CSV 用手写轻量解析器（不新增依赖）。

**Spec:** `docs/superpowers/specs/2026-07-22-nix22-rtk-trajectory-import-spec.md`（已确认，含 D1-D11 决策）
**Prototype:** `docs/marketing/nix-22-rtk-trajectory-import-prototype.html`（v2，已确认，变更点 ①~⑥）
**前依赖:** NIX-20（路线动态）、NIX-21（批量导入重构），均已实施

---

## File Structure

### smart-livestock-server 后端 — 新建

| File | Responsibility |
|------|---------------|
| `db/migration/V20260722100000__nix22_trajectory_track_points.sql` | 更新 chk_test_type_truth + 建 gps_quality_track_points |
| `iot/domain/model/GpsQualityTrackPoint.java` | 轨迹点领域模型（配对快照） |
| `iot/domain/repository/GpsQualityTrackPointRepository.java` | 仓储接口 |
| `iot/infrastructure/persistence/entity/GpsQualityTrackPointJpaEntity.java` | JPA 实体 |
| `iot/infrastructure/persistence/SpringDataGpsQualityTrackPointRepository.java` | Spring Data 接口 |
| `iot/infrastructure/persistence/JpaGpsQualityTrackPointRepositoryImpl.java` | 仓储实现 |
| `iot/domain/service/TrajectoryPairingService.java` | 纯领域服务：单行配对规则 + 统计聚合（可单测） |
| `iot/application/TrajectoryImportService.java` | 导入应用服务：文件解析（POI + CSV）→ 行校验 → 配对 → 按设备建检验 + 快照落库 |
| `iot/application/TrajectoryReportService.java` | 报告应用服务：读快照聚合 + 静动态对比 |
| `iot/interfaces/admin/dto/TrajectoryParseResultDto.java` | parse 响应 DTO（spec §6.2） |
| `iot/interfaces/admin/dto/TrajectoryImportResultDto.java` | import 响应 DTO（spec §6.3） |
| `iot/interfaces/admin/dto/TrajectoryQualityReportDto.java` | 报告 DTO（spec §6.4） |
| `src/test/.../TrajectoryPairingServiceTest.java` | 配对算法 + 统计 + 分级单测 |

### smart-livestock-server 后端 — 修改

| File | Change |
|------|--------|
| `iot/domain/model/TestType.java` | 加 `TRAJECTORY` |
| `iot/domain/service/GpsQualityCalculator.java` | 加 `determineTrajectoryGrade()`（不动静态/动态方法） |
| `iot/domain/repository/GpsQualityTestRepository.java` + 实现 | 加 `existsTrajectoryByDeviceAndWindow(deviceCode, startedAt, endedAt)` 去重查询 |
| `iot/interfaces/admin/GpsQualityAdminController.java` | 加 `/trajectory/template`、`/trajectory/parse`、`/trajectory/import`、`/tests/{id}/trajectory-report`、`/comparison/trajectory` 5 端点 |
| `iot/interfaces/admin/dto/TrajectoryComparisonDto.java` | 轨迹对比 DTO（逐设备最近一次 TRAJECTORY 检验） |
| `shared/common/ErrorCode.java` + `messages_zh/en.properties` | 加轨迹导入错误码（INVALID_TRAJECTORY_ROW 等），双语同步 |

### Mobile/mobile_app 前端 — 新建

| File | Responsibility |
|------|---------------|
| `features/admin/gps_quality/presentation/trajectory_import_dialog.dart` | 3 步导入向导（复刻 batch_import_dialog 结构） |
| `features/admin/gps_quality/presentation/trajectory_report_panel.dart` | 轨迹动态报告面板（配对概览 + 分布 + 明细 + 静动态对比） |
| `features/admin/gps_quality/presentation/widgets/trajectory_chart.dart` | 轨迹对比图（RTK 实线 vs 设备虚线 + 配对连线 + 未配对点） |

### Mobile/mobile_app 前端 — 修改

| File | Change |
|------|--------|
| `domain/gps_quality_models.dart` | 加 TrajectoryReport 等模型；QualityCheck.checkType 支持 'TRAJECTORY' |
| `data/gps_quality_api_repository.dart` | 加 template/parse/import/trajectory-report 4 个调用 |
| `data/gps_quality_providers.dart` | 加 trajectory import/report providers |
| `presentation/quality_check_list.dart` | ①工具条加 🛰 入口 ②设备分组加紫色「轨迹」标记 ③时间轴加「轨」段 ④报告区 TRAJECTORY 分派 |
| `presentation/comparison_tab.dart` | ⑤动态来源列加「路线/轨迹」标记 |
| `lib/l10n/app_zh.arb` / `app_en.arb` | `gpsQualityTrajectory*` 系列 key，双语同步 |

---

## Phase A — 数据库迁移

### Task A1: Flyway 迁移

**文件**: `smart-livestock-server/src/main/resources/db/migration/V20260722100000__nix22_trajectory_track_points.sql`

**内容**（spec §5.1 + §5.2 原文 SQL）：
1. DROP + 重建 `chk_test_type_truth`，允许 `(TRAJECTORY AND rtk_point_id IS NULL AND route_id IS NULL)`
2. 建 `gps_quality_track_points`（含 chk_track_match CHECK、UNIQUE(test_id, sequence_no)、idx_gtp_test 索引、ON DELETE CASCADE）

**Verify**:
- [ ] `./gradlew compileJava` 不受影响（纯 SQL）
- [ ] 部署后 `\d gps_quality_track_points` 结构正确；插入 TRAJECTORY 检验不违反 CHECK；插入 STATIC 无 rtk_point_id 违反 CHECK（回归）
- [ ] 无种子数据（spec §5.4）

---

## Phase B — 领域层（纯 Java，先写测试）

### Task B1: TestType + 领域模型

- `TestType` 加 `TRAJECTORY`
- 新建 `GpsQualityTrackPoint` 领域模型（字段对齐 spec §5.2，matchSource 枚举 FILE/GPS_LOG/UNPAIRED）

**Verify**: [ ] 编译通过

### Task B2: TrajectoryPairingService（纯领域服务）

无 IO 依赖，输入输出均为值对象：
- `pairRow(...)`：单行配对（spec §4.1 算法：FILE 直取 / GPS_LOG 最近邻 ±T / UNPAIRED；等距取较早——spec §4.2）
- `aggregate(points)`：统计聚合（totalPoints/filePaired/logPaired/unpaired/pairRate/mean/p50/p95/max；分位数退化规则沿用现有约定：paired<5 时 p50 用 max、<20 时 p95 用 max）
- `determineTrajectoryGrade(stats)`：spec §6.5 分级表（独立方法，不动 `determineGrade`/`determineDynamicGrade`——放在 `GpsQualityCalculator` 或本服务内，随实现选更内聚处）

**测试先行** `TrajectoryPairingServiceTest`：
- [ ] FILE 行直接用文件坐标，timeDiff=0
- [ ] GPS_LOG：容差内取最近；等距取较早；超容差 UNPAIRED
- [ ] 聚合：未配对不参与误差统计；pairRate 计算正确
- [ ] 分级：原型示例（p95=12.4m, pairRate=87.5%, paired=21）→ EXCELLENT；paired<4 → UNAVAILABLE

**Verify**: [ ] `./gradlew test --tests "*TrajectoryPairingServiceTest"` 全绿

---

## Phase C — 应用服务 + API

### Task C1: 文件解析（TrajectoryImportService · parse 部分）

- XLSX：复用 POI（参考 `GpsQualityBatchImportService` 的 Workbook 遍历）
- CSV：手写轻量解析（UTF-8、逗号分隔、引号包裹字段），不新增依赖
- 表头自动检测（spec §3.2）；行级校验：EUI 非空、时间格式（`yyyy-MM-dd HH:mm[:ss]` / ISO-8601，按 UTC+8 → Instant）、RTK 坐标范围、E/F 成对（D6）、文件内重复行（同 EUI+同采集时间，后者记「重复行」）
- 单文件 ≤5000 行

**Verify**: [ ] 单测覆盖 6 列各种缺省/错误组合 + 表头有无 + csv/xlsx 两格式

### Task C2: parse/import/报告应用服务

- `parse(file, toleranceSec)`：校验 + 完整配对预览（EUI→device 解析，批量按设备预载 gps_logs 时间窗数据避免 N+1），**不落库**，返回 `TrajectoryParseResultDto`
- `import(file, toleranceSec)`：重新配对 → 按设备分组（D7 去重：同 EUI 同 min/max 窗口已存在 TRAJECTORY → SKIPPED_DUPLICATE）→ 建 GpsQualityTest（startedAt/endedAt=采集时间 min/max，status=READY，note=文件名+容差）→ 轨迹点快照落库（D2，单事务）
- `TrajectoryReportService.report(testId)`：读快照聚合（B2）+ 静动态对比（同设备最近 STATIC 报告 p95/grade/delta，无则 null）

**Verify**: [ ] 应用服务单测（mock 仓储）覆盖：多设备分组、去重跳过、UNPAIRED 快照、报告聚合与对比

### Task C3: Controller + DTO

`GpsQualityAdminController` 加 4 端点（spec §6.1）：`/trajectory/template`（CSV 下载）、`/trajectory/parse`、`/trajectory/import`（multipart）、`/tests/{id}/trajectory-report`（非 TRAJECTORY 返回 400）。错误码 + messages 双语。

**Verify**: [ ] `./gradlew compileJava` 通过；[ ] 部署后 curl 四端点（见 Phase E）

### Task C4: 质量对比扩展

真实 Tab 3 为「静态（按真值点）/ 动态（按路线）」分段切换（spec D10 已修正）。新增 `GET /comparison/trajectory`：每台设备最近一次 READY TRAJECTORY 检验的对比数据；前端分段切换器加第三段「轨迹」。

**Verify**: [ ] 含 TRAJECTORY 检验的设备出现在 `/comparison/trajectory` 响应中；静态/动态两段回归不变

---

## Phase D — 前端

### Task D1: 模型 + Repository + Providers

- `gps_quality_models.dart`：TrajectoryReport/TrajectoryPoint/TrajectoryParseResult/TrajectoryImportResult 模型（fromJson）
- repository：4 个新端点调用（multipart 上传对齐现有 batch import 写法）
- providers：trajectoryImportProvider、trajectoryReportProvider(testId)

**Verify**: [ ] `flutter analyze` 无新告警

### Task D2: 导入向导（trajectory_import_dialog.dart）

3 步 stepper（复刻 `batch_import_dialog.dart` 结构）：上传（格式说明表 + 模板下载 + UTC+8 时钟提示）→ 校验与配对预览（统计条 + 容差调整后重新 parse + 行级明细标红）→ 导入结果（逐设备卡片）→ 完成后 `ref.invalidate(checksProvider)`

**Verify**: [ ] widget 测试：三步流转 + 失败行展示

### Task D3: 报告面板 + 轨迹图

- `trajectory_report_panel.dart`：标题行（类型标记 + Grade + 文件名/时间窗）→ 配对概览 chips → 轨迹对比图 → 误差分布 + 静动态对比卡（null 时显示无静态数据）→ 逐样本明细表（含未配对清单）
- `widgets/trajectory_chart.dart`：参考 `route_match_chart.dart` 的 CustomPainter 绘制双轨迹 + 配对连线 + 未配对标记

**Verify**: [ ] widget 测试：概览数值渲染、未配对样本不参与统计展示

### Task D4: 检验列表集成（原型 ①②③④）

`quality_check_list.dart`：
- ① 工具条加 `trajectory-import-btn`（`Icons.satellite_alt`）
- ② 设备分组加 TRAJECTORY 类型标记（`Color(0xFF7C3AED)`，轨迹）
- ③ 时间轴加紫色「轨」段 + tooltip
- ④ `_buildReport` 加 TRAJECTORY 分派 → TrajectoryReportPanel

**Verify**: [ ] 现有 widget 测试不红；新增轨迹类型渲染测试

### Task D5: 质量对比 + i18n

- `comparison_tab.dart`：SegmentedButton 扩为 3 段（静态/动态/轨迹），轨迹段展示对比表（⑤）
- `app_zh.arb` / `app_en.arb` 双语同步 `gpsQualityTrajectory*` 系列；`flutter gen-l10n` 无缺失

**Verify**: [ ] `flutter gen-l10n` + `flutter analyze` 通过；[ ] `./build_web.sh` 构建成功

---

## Phase E — 验证与交付

### Task E1: 编译验证

- [ ] `cd smart-livestock-server && ./gradlew compileJava` + 全部新增单测绿
- [ ] `cd Mobile/mobile_app && ./build_web.sh` 成功

### Task E2: 部署 dev + 集成测试（部署完成后执行）

- [ ] `./scripts/deploy.sh dev`
- [ ] `curl` 验证：template 下载返回 CSV；parse 返回配对预览 JSON；import 创建检验；trajectory-report 返回完整报告
- [ ] 浏览器验证：🛰 入口 → 3 步导入 → 设备分组出现「轨迹」→ 时间轴「轨」段 → 配对报告 → 质量对比来源标记
- [ ] 回归：静态/路线动态报告、批量导入、对比 Tab 无变化

### Task E3: 提交

- [ ] `codex/` 分支提交（含原型 + spec + plan + 代码 + 迁移），推送 + PR + 关闭工单

---

## 风险与注意

| 风险 | 缓解 |
|------|------|
| 时钟基准不一致导致大量 UNPAIRED | 导入向导 step1 明示 UTC+8 基准；预览步即暴露配对率，容差可调 |
| gps_logs 大表 N+1 查询 | parse/import 按设备批量预载时间窗数据（C2） |
| chk_test_type_truth 重建失败（存量脏数据） | 迁移前 dev/test 库核查：存量只有 STATIC/DYNAMIC 且满足旧约束 |
| 前端图表复杂度 | trajectory_chart 复用 route_match_chart 的 CustomPainter 骨架，不引新库 |
