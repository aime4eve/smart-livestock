# NIX-21 缺口补齐 — GPS 质量检验高保真对齐 设计文档

> 日期：2026-07-20
> 前置：`2026-07-18-nix21-batch-import-and-quality-check-refactor.md`（NIX-21 主方案，已实施）
> 高保真：`docs/marketing/nix-21-batch-import-prototype.html`
> 性质：对照高保真原型逐项核查后的缺口补齐，不涉及数据库 Schema 变更

## 1. 背景与缺口清单

NIX-21 主体已实施（设备分组列表、时间轴、静态报告、批量导入三步骨架、模板下载、RTK点/路线管理、静态对比）。对照高保真原型核查后，剩余缺口 8 项 + 原型外桩 1 项：

| # | 缺口 | 层 | 现状 |
|---|------|----|------|
| 1 | 列表页状态筛选 + EUI/设备编号搜索 | 前端 | `_statusFilter`/`_euiFilter` 字段已声明未接线；后端 `GET /checks?status&eui` 已支持 |
| 2 | 列表页头"批量注册"按钮（存在待注册设备时显示） | 前端 | 未实现 |
| 3 | 批量导入预览步骤是假桩 | 前端+后端 | `_parsePreview()` 塞 `'parsing...'` 假数据；后端无 parse-only 端点 |
| 4 | "手动注册/批量注册"接错端点 | 前端 | 全部调 `retry-row`（重建检验）；真正的 `POST /batch/retry-registration` 是死代码 |
| 5 | 动态报告缺 inOrder/meanError/p50 + 路线匹配图 | 前端 | 模型字段已解析，UI 未展示；passes 经纬度已解析，无渲染 |
| 6 | DEVICE_PENDING/FAILED 详情页"删除设备"按钮 | 前端+后端 | 无 UI 无端点 |
| 7 | 批量导入预览删行后提交 | 前端+后端 | 删除按钮存在但无实际数据可删 |
| 8 | 对比 Tab 动态对比是桩 | 前端+后端 | `comparison_tab.dart:196-217` 注释明确的桩 |

## 2. 已确认的语义决策

- **"删除设备"按钮语义 = 仅删检验记录**：删除该设备（EUI）名下的全部质量检验记录，devices 表设备记录保留。按钮文案仍按原型显示"删除设备"，确认对话框中说明实际行为。
- **动态对比纳入本次范围**：按路线维度对比多设备的动态检验质量。
- **批量导入预览采用无状态两次上传方案**：parse 端点只解析不落库；提交时重新上传同一文件并携带 `excludeRows` 排除行号。不引入服务端会话/暂存表。

## 3. 后端设计

所有端点位于 `GpsQualityAdminController`（base `/api/v1/admin/gps-quality`，PLATFORM_ADMIN）。无 Flyway 迁移。

### 3.1 新增端点：批量导入解析（parse-only）

```
POST /batch/parse
Content-Type: multipart/form-data
参数：file（.xlsx）
```

行为：复用 `GpsQualityBatchImportService` 的解析逻辑，逐行解析 + 预检，**不创建设备、不注册 blade、不落库**。逐行预检规则：

| 预检状态 | 条件 |
|---------|------|
| `OK` | EUI 合法且设备已存在且已激活（blade 注册完成） |
| `WARN` | EUI 合法但设备不存在或未激活（导入时将创建/注册，可能失败） |
| `ERROR` | EUI 格式无效、检验类型无法识别、真值点/路线不存在、时间格式无效 |

响应：

```json
{
  "totalRows": 8,
  "okCount": 5, "warnCount": 2, "errorCount": 1,
  "rows": [
    {
      "rowIndex": 1,
      "eui": "847A000000000F03",
      "deviceCode": "DEV-GPS-001",
      "testType": "STATIC",
      "refName": "11号点 - 北门",
      "rtkPointId": 11, "routeId": null,
      "startedAt": "2026-07-18T09:00:00Z", "endedAt": "2026-07-18T10:00:00Z",
      "preStatus": "OK", "message": null
    }
  ]
}
```

时间字段遵循既有约定（naive 时间按 UTC 原样解析，不猜时区，复用 `parseInstant`）。

### 3.2 改造端点：批量导入支持排除行

```
POST /batch/import
Content-Type: multipart/form-data
参数：file（.xlsx），excludeRows（可选，逗号分隔的行号，对应 parse 返回的 rowIndex）
```

行为：解析后跳过 `excludeRows` 中的行，其余按现有逻辑执行（findOrCreateByEui → blade 注册 → 创建检验）。不传 `excludeRows` 时行为与现状完全一致（向后兼容）。

### 3.3 新增端点：按设备删除检验

```
DELETE /checks/by-device/{deviceId}
响应：{ "deleted": 12 }
```

行为：删除 `deviceId` 名下全部 `gps_quality_tests` 记录（含各状态）。报告为实时计算（基于 gps_logs），无子表引用，直接批量 DELETE。设备记录本身不删。

### 3.4 新增端点：动态质量对比

```
GET /comparison/dynamic?routeId={routeId}
```

行为：查询该路线下所有 READY 状态的动态检验，按设备分组取每台设备最新一条，逐台计算/返回动态报告摘要。响应：

```json
{
  "routeId": 5, "routeName": "线路1",
  "devices": [
    {
      "deviceId": 12, "deviceCode": "DEV-GPS-001", "checkId": 64,
      "coverage": 0.833, "matchedCount": 5, "missedCount": 1, "ambiguousCount": 0,
      "inOrder": true, "meanError": 7.8, "p50": 6.2, "p95": 12.1,
      "startedAt": "...", "endedAt": "..."
    }
  ]
}
```

复用 `DynamicQualityReportService` 的计算结果，不重复实现算法。

### 3.5 既有端点（本次不改）

- `POST /batch/retry-registration`：已存在，本次仅把前端接过来。
- `POST /batch/retry-row`：保留给"编辑并重试"（EditRetryDialog）使用，批量结果页的注册类按钮不再调它。
- `GET /checks?status&eui`：筛选参数已支持，本次仅前端接线。

## 4. 前端设计

模块：`Mobile/mobile_app/lib/features/admin/gps_quality/`。所有新增文案走 `AppLocalizations`，`app_zh.arb` / `app_en.arb` 同步补齐。

### 4.1 列表页筛选与搜索（缺口 #1）

文件：`presentation/quality_check_list.dart`

- 设备分组列表上方加搜索栏：`TextField`（搜索 EUI 或设备编号）+ 状态下拉（全部 / READY / 待注册 DEVICE_PENDING / 失败 FAILED）。
- 接线已声明的 `_statusFilter`/`_euiFilter`：传给列表 provider 的 query 参数（后端筛选），或在前端对分组结果过滤（与原型行为一致——原型为前端过滤）。**采用前端过滤**：分组列表数据量小，避免改动 provider 签名和分页逻辑。
- 搜索匹配规则：EUI 或设备编号包含子串（大小写不敏感），与原型一致。

### 4.2 列表页头"批量注册"按钮（缺口 #2）

文件：`presentation/quality_check_list.dart`

- 当当前列表中存在任何 `DEVICE_PENDING` 检验时，详情面板头部显示"批量注册"按钮（原型位置：检验详情标题栏右侧，info 蓝色）。
- 点击调 `retryRegistration()`（不带 checkIds，对全部待注册检验重试注册），完成后刷新列表。

### 4.3 注册动作接线修正（缺口 #4）

文件：`presentation/quality_check_list.dart`、`presentation/batch_import_dialog.dart`、`data/gps_quality_api_repository.dart`

| 位置 | 现状 | 改为 |
|------|------|------|
| 列表页 DEVICE_PENDING 概览卡"手动注册"（`pending-register-btn`） | 循环调 `retryRow` | 调 `retryRegistration(checkIds=[该设备待注册检验ids])` |
| 批量导入结果页每行"手动注册 blade" | 调 `retryRow` | 调 `retryRegistration(checkIds=[该行checkId])` |
| 批量导入结果页底部"批量注册 blade"（`batch-register-all-btn`） | 循环调 `retryRow` | 调 `retryRegistration()`（全部） |
| 结果页"编辑并重试"（failed 行） | 调 `retryRow` | **保持不变** |

`retryRegistration()` 已有仓库层实现（`gps_quality_api_repository.dart:249`），直接接线。操作完成后刷新检验列表。

### 4.4 批量导入真实预览（缺口 #3、#7）

文件：`presentation/batch_import_dialog.dart`、`data/gps_quality_api_repository.dart`

- 上传步骤选中文件后：调 `POST /batch/parse`，进入预览步骤。
- 预览步骤：汇总卡（总行数/可出报告 OK/待注册 WARN/失败 ERROR）+ 真实行表格（行号/EUI/设备编号/类型/真值点或路径/时段/预检状态标签），每行末尾"✕"删除按钮（仅前端移除该行，记录其 rowIndex 到 `_excludedRows`）。
- 提交：重新上传同一文件 + `excludeRows`，调 `POST /batch/import`。ERROR 行前端默认自动排除（不可取消排除，与原型"失败行不可提交"语义一致）。
- 结果步骤：维持现有实现（汇总 + 明细 + 每行操作按钮），仅注册按钮按 4.3 修正。
- 删除 `_parsePreview()` 假桩。

### 4.5 动态报告补齐（缺口 #5）

文件：`presentation/quality_check_list.dart`（`_DynamicReportCard`）

- 指标卡补齐：`inOrder`（顺序正确 ✅/❌）、`meanError`（平均误差）、`p50`——模型字段已存在，仅加展示。
- 新增"路线匹配图"：仿照 `widgets/scatter_chart.dart` 的 CustomPainter 风格，绘制：
  - 路线 RTK 点序列（按 sequenceNo 编号连线 + 点位标签）
  - 匹配轨迹点（`passes` 的经纬度，按经过顺序连线）
  - 匹配/遗漏/歧义点用不同颜色标记
  - 自适应经纬度范围缩放，不引入地图瓦片依赖

### 4.6 "删除设备"按钮（缺口 #6）

文件：`presentation/quality_check_list.dart`

- DEVICE_PENDING 概览卡、FAILED 详情卡各加红色"删除设备"按钮（原型位置）。
- 点击弹确认对话框：说明"将删除该设备名下的全部 N 条质量检验记录（设备本身保留），此操作不可恢复"。
- 确认后调 `DELETE /checks/by-device/{deviceId}`，完成后清空选中并刷新列表。

### 4.7 动态对比（缺口 #8）

文件：`presentation/comparison_tab.dart`、`data/gps_quality_api_repository.dart`、`domain/gps_quality_models.dart`

- 复用现有静态对比的交互骨架：选择动态路线 → 调 `GET /comparison/dynamic?routeId=` → 对比表。
- 表格列：设备编号 / EUI / 覆盖率 / 匹配点 / 遗漏点 / 歧义点 / 顺序正确 / 平均误差 / P50 / P95 / 检验时段。
- 覆盖率、误差类指标最优行高亮（与静态对比风格一致）。
- 新增模型 `DynamicComparisonResult` / `DynamicComparisonRow`。

## 5. 影响面与兼容性

- **无数据库变更**，无 Flyway 迁移。
- `POST /batch/import` 的 `excludeRows` 为可选参数，旧调用方（不传）行为不变。
- `retry-row` 端点保留，仅前端调用点收窄到 EditRetryDialog。
- 不触碰真值参照 Tab、静态报告、静态对比、时间轴的既有实现。
- 种子数据：无需新增（复用 dev 库现有 RTK 点 1-20、路线与设备）。

## 6. 验收标准

1. 列表页可按状态筛选、按 EUI/设备编号搜索，结果与高保真一致。
2. 存在待注册设备时列表详情头部出现"批量注册"按钮，点击后待注册检验转为 READY（blade 平台可达时）并刷新。
3. 批量导入：上传 xlsx → 预览显示真实解析行（OK/WARN/ERROR 统计与行状态正确）→ 删除部分行 → 提交 → 结果页统计与被删行一致；ERROR 行不参与提交。
4. 批量结果页与列表页的"手动注册/批量注册"按钮触发的是 `POST /batch/retry-registration`（可通过网络请求确认），"编辑并重试"仍走 `retry-row`。
5. 动态报告展示顺序正确、平均误差、P50，并渲染路线匹配图（RTK 点序列 + 匹配轨迹）。
6. DEVICE_PENDING/FAILED 详情可点"删除设备"，确认后该设备检验清空、设备保留、列表刷新。
7. 对比 Tab 选动态路线后展示多设备动态对比表。
8. `flutter analyze` 无新增告警；`flutter gen-l10n` 无缺失 key；后端 `./gradlew compileJava` 通过。
9. 部署 dev 后 curl 验证：parse 端点返回预检行、import + excludeRows 跳过指定行、by-device 删除返回条数、comparison/dynamic 返回设备摘要。
