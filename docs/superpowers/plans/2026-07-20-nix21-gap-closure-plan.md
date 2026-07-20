# NIX-21 缺口补齐 — 实施计划

> 日期：2026-07-20
> Spec：`docs/superpowers/specs/2026-07-20-nix21-gap-closure-spec.md`（已确认）
> 高保真：`docs/marketing/nix-21-batch-import-prototype.html`
> 顺序：后端端点 → 后端编译 → 前端仓库层 → 前端各页面 → i18n/分析 → 部署 dev → curl 验证

## Task 1 — 后端：POST /batch/parse（parse-only 预检）

**文件**：
- `smart-livestock-server/src/main/java/com/smartlivestock/iot/interfaces/admin/GpsQualityAdminController.java`
- `GpsQualityBatchImportService`（同域 application 层）

**改动**：
- Controller 新增 `parseBatch(@RequestParam("file") MultipartFile file)`，路由 `POST /batch/parse`。
- Service 抽取/复用现有 xlsx 解析逻辑（`import` 的解析部分），新增 `ParseResultDto { totalRows, okCount, warnCount, errorCount, rows[] }`，行 DTO 含 `rowIndex/eui/deviceCode/testType/refName/rtkPointId/routeId/startedAt/endedAt/preStatus/message`。
- 预检规则（不落库、不注册）：
  - ERROR：EUI 格式无效 / 检验类型无法识别 / 真值点或路线不存在 / 时间格式无效
  - WARN：EUI 合法但设备不存在或未激活
  - OK：设备已存在且已激活
- 时间解析复用现有 `parseInstant`（naive 按 UTC，不猜时区）。

**验证**：`./gradlew compileJava -q` 通过；curl 上传模板 xlsx 返回正确预检统计。

## Task 2 — 后端：POST /batch/import 增加 excludeRows

**文件**：同上 Controller + Service。

**改动**：
- `importBatch` 增加可选参数 `@RequestParam(value="excludeRows", required=false) String excludeRows`（逗号分隔行号）。
- 解析后跳过命中行号再执行现有 findOrCreateByEui → 注册 → 建检验流程。不传参数行为不变。

**验证**：编译通过；curl 带 `excludeRows=2,3` 导入，结果行数 = 总行 - 2。

## Task 3 — 后端：DELETE /checks/by-device/{deviceId}

**文件**：Controller + `GpsQualityTestService` + 对应 Repository。

**改动**：
- 新增 `DELETE /checks/by-device/{deviceId}`，批量删除该 deviceId 全部 `gps_quality_tests`，返回 `{ "deleted": N }`。
- Repository 用 `@Modifying @Query` 批量 DELETE（参考既有 deleteByRouteId 风格）。

**验证**：编译通过；curl 先查某设备检验数，删除后返回条数一致，再查为 0。

## Task 4 — 后端：GET /comparison/dynamic?routeId=

**文件**：Controller + `DynamicQualityReportService`（复用计算）。

**改动**：
- 查询该 routeId 下全部 READY 动态检验，按设备分组取每设备最新一条。
- 每条复用现有动态报告计算，返回摘要数组（deviceId/deviceCode/checkId/coverage/matchedCount/missedCount/ambiguousCount/inOrder/meanError/p50/p95/startedAt/endedAt）。

**验证**：编译通过；curl 路线 5（dev 库"线路1"）返回设备摘要数组。

## Task 5 — 前端：仓库层 + 模型

**文件**：
- `Mobile/mobile_app/lib/features/admin/gps_quality/data/gps_quality_api_repository.dart`
- `domain/gps_quality_models.dart`

**改动**：
- 新增 `parseBatch(file)` → `BatchParseResult`（含 rows 列表）。
- `importBatch` 增加可选 `excludeRows` 参数。
- 新增 `deleteChecksByDevice(deviceId)` → 返回删除条数。
- 新增 `fetchDynamicComparison(routeId)` → `DynamicComparisonResult`。
- 新增模型：`BatchParseResult`/`BatchParseRow`、`DynamicComparisonResult`/`DynamicComparisonRow`。

**验证**：`flutter analyze` 通过（此时新成员暂无调用方，允许）。

## Task 6 — 前端：列表页（筛选/搜索 + 批量注册 + 注册接线 + 删除设备）

**文件**：`presentation/quality_check_list.dart`

**改动**：
- 分组列表上方加搜索 TextField + 状态下拉（全部/READY/待注册/失败），接线 `_statusFilter`/`_euiFilter`，对分组结果前端过滤（EUI 或设备编号子串、大小写不敏感）。
- 存在 DEVICE_PENDING 检验时，详情面板头部显示"批量注册"按钮 → `retryRegistration()`（全部）→ 刷新。
- `pending-register-btn`（DEVICE_PENDING 概览卡"手动注册"）改调 `retryRegistration(checkIds=[该设备待注册检验ids])`。
- DEVICE_PENDING 概览卡、FAILED 详情卡（`failed-check-card`）各加红色"删除设备"按钮 → 确认对话框（说明仅删检验、设备保留、不可恢复）→ `deleteChecksByDevice` → 清选中刷新。
- 所有 UI 元素加 `Key('descriptive-id')`；文案全部进 arb。

**验证**：`flutter analyze` 通过；新增/更新 widget 测试覆盖筛选与按钮可见性。

## Task 7 — 前端：批量导入真实预览

**文件**：`presentation/batch_import_dialog.dart`

**改动**：
- 删除 `_parsePreview()` 假桩；选文件后调 `parseBatch` 进入预览。
- 预览：汇总卡（总数/OK/WARN/ERROR）+ 真实行表格（行号/EUI/设备编号/类型/真值引用/时段/预检状态）；每行"✕"删除（记录 rowIndex 到排除集）；ERROR 行默认排除且不可恢复。
- 提交：重传同一文件 + `excludeRows` 调 `importBatch`。
- 结果页每行"手动注册 blade"与底部"批量注册 blade"（`batch-register-all-btn`）改调 `retryRegistration`；"编辑并重试"保持 `retryRow` 不变。

**验证**：`flutter analyze` 通过；widget 测试覆盖预览渲染与排除逻辑。

## Task 8 — 前端：动态报告补齐 + 路线匹配图

**文件**：
- `presentation/quality_check_list.dart`（`_DynamicReportCard`）
- 新增 `presentation/widgets/route_match_chart.dart`

**改动**：
- 指标卡补 `inOrder`（顺序正确 ✅/❌）、`meanError`、`p50`。
- `RouteMatchChart`：CustomPainter 绘制 RTK 点序列（按 sequenceNo 连线+编号标签）+ passes 匹配轨迹（经纬度连线），匹配/遗漏/歧义分色，自适应缩放，风格对齐 `scatter_chart.dart`。

**验证**：`flutter analyze` 通过；widget 测试渲染不抛异常。

## Task 9 — 前端：对比 Tab 动态对比

**文件**：`presentation/comparison_tab.dart`

**改动**：
- 删除 196-217 行桩；选动态路线 → `fetchDynamicComparison` → 对比表（设备编号/EUI/覆盖率/匹配/遗漏/歧义/顺序/平均误差/P50/P95/时段）。
- 覆盖率与误差类指标最优行高亮，风格对齐静态对比。

**验证**：`flutter analyze` 通过。

## Task 10 — i18n + 静态检查

**改动**：
- `app_zh.arb` / `app_en.arb` 同步补齐全部新 key（禁止只写一种语言）。
- 后端如需新增对外消息，`messages_zh.properties` / `messages_en.properties` 同步。
- 运行 `flutter gen-l10n`、`flutter analyze`、`flutter test`、`./gradlew compileJava -q`。

**验证**：全部通过，无新增告警。

## Task 11 — 部署 dev + curl 验证

```bash
cd smart-livestock-server && ./scripts/deploy.sh dev
```

部署后逐项 curl 验证（token 用 platform_admin 13800000000/123，`data.accessToken`）：
1. `POST /batch/parse` 返回预检行与统计
2. `POST /batch/import` 带 excludeRows 跳过指定行
3. `DELETE /checks/by-device/{id}` 返回删除条数
4. `GET /comparison/dynamic?routeId=5` 返回设备摘要
5. `POST /batch/retry-registration` 带 checkIds 正常响应

**验证**：以上 curl 全部符合预期后，交付用户集成测试。

## 备注

- 本地改动暂不 git commit，待集成测试通过后按流程提交 + PR。
- test 环境（18080）部署需用户另行通知，本次只发 dev（19080）。
