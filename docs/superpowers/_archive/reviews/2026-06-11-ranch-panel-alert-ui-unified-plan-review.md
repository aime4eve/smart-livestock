# 牧场面板告警 UI 统一计划 — 完成情况核查报告

> **核查日期**：2026-06-11
> **计划文件**：`docs/superpowers/plans/2026-06-10-ranch-panel-alert-ui-unified-plan.md`
> **总体状态：核心功能已实现 ~70%，但全部代码仍在工作树中（未提交），测试和部分 UI 细节缺失。**

---

## 阶段一：后端（Task 1-7）

| Task | 状态 | 详情 |
|------|------|------|
| **Task 1** — V26 迁移 | ✅ 完成 | `V26__alert_notification_model.sql` 已创建（未跟踪），包含 alert_read_status、fence_zones、alerts/fences 扩展列、数据迁移 |
| **Task 2** — Alert 模型重构 | ✅ 完成 | `AlertStatus` → `{ACTIVE, DISMISSED, AUTO_RESOLVED}`；`AlertType` 新增 `FENCE_APPROACH`/`ZONE_APPROACH`，重命名 `DIGESTIVE_ABNORMAL`；Alert 实体新增 dismiss/autoResolve；旧方法标记 @Deprecated 保留兼容 |
| **Task 3** — per-user 已读 | ✅ 完成 | `AlertReadStatusJpaEntity` + `SpringDataAlertReadStatusRepository` 已创建；`AlertApplicationService` 实现了 markRead/batchRead；`AlertReadStatusTest` 已创建 |
| **Task 4** — API 合约更新 | ⚠️ 部分完成 | `AlertController` 已新增 `/read`、`/dismiss`、`/batch-read`；旧端点 `/acknowledge`→markRead、`/handle`→dismiss 保留兼容；**缺失：`FenceZoneController` 未创建** |
| **Task 5** — Dashboard 扩展 | ✅ 完成 | `RanchOverviewDto` 含 `inFenceRate`、`fenceAlertSummary`、`healthAlertSummary`；`DashboardController` 已扩展 |
| **Task 6** — 缓冲带+自动解除 | ✅ 完成 | JTS 依赖已加；`FenceBreachDetector` 扩展了缓冲带检测；`BufferPolygonCalculator` 新建；`FenceBreachDetectorTest` 已扩展 |
| **Task 7** — 健康告警自动解除 | ✅ 完成 | `RanchCommandPort.resolveAlert()` + `RanchCommandPortImpl` 已实现 |

**后端小结：6/7 完整完成，Task 4 缺 FenceZoneController。所有变更均未提交。**

---

## 阶段二：前端模型层（Task 8-11）

| Task | 状态 | 详情 |
|------|------|------|
| **Task 8** — 数据模型+Mock | ⚠️ 部分完成 | `ranch_models.dart` 已扩展（`inFenceRate`、`FenceZoneData`、`fenceAlertSummary`/`healthAlertSummary`、`read`/`resolvedType`/`resolvedAt`/`copyWith`）；`ranch_models_test.dart` 已创建；**缺失：`test/fixtures/ranch_overview_mock.json` 未创建** |
| **Task 9** — Repository 扩展 | ✅ 完成 | `RanchRepository` 接口新增 `markRead`/`dismiss`/`batchRead`；`RanchApiRepository` 实现对齐 |
| **Task 10** — alerts 模块重构 | ✅ 完成 | `AlertStage` 已更新；`AlertsRepository`/`AlertsApiRepository`/`AlertsController` 方法全部重命名；保留旧方法做兼容路由 |
| **Task 11** — Controller 钻取状态 | ✅ 完成 | `RanchDrillLevel` 枚举、`_drillLevel`/`_selectedCategory`/`_selectedAlertId` 状态、`showDashboard`/`showCategoryList`/`showAlertDetail` 方法、乐观更新 copyWith 全部就位 |

**前端模型层小结：4 个 Task 基本完成，Task 8 缺 mock 固件。**

---

## 阶段三：前端 UI 层（Task 12-19）

| Task | 状态 | 详情 |
|------|------|------|
| **Task 12** — 卡片组件 | ⚠️ 部分完成 | `status_dashboard_card.dart` 和 `alert_card.dart` 已创建；**缺失：2 个 widget 测试文件均未创建** |
| **Task 13** — 辅助组件 | ✅ 完成 | `device_info_line.dart` 和 `auto_resolved_section.dart` 已创建 |
| **Task 14** — HealthBottomSheet 重写 | ⚠️ 部分完成 | 已重写为钻取架构（644行），四层切换逻辑完整（peek→dashboard→list→detail）；**缺失：`health_bottom_sheet_test.dart` 未创建** |
| **Task 15** — FenceAlertDetailSheet | ⚠️ 部分完成 | `fence_alert_detail_sheet.dart` 已创建；**缺失：`fence_alert_detail_test.dart` 未创建** |
| **Task 16** — 健康详情页改造 | ⚠️ 部分完成 | 三个页面（fever/digestive/estrus）已添加 `DeviceInfoLine`；**缺失：无"忽略此告警"按钮、无 markRead 调用、无能力边界说明文字** |
| **Task 17** — 缓冲带图层+Marker变色 | ⚠️ 部分完成 | `FenceBufferLayer` 已创建并集成到 ranch_page；**缺失：Marker 变色未实现** — `HealthMarker` 仅按 healthStatus 着色（NORMAL/WARNING/CRITICAL），无围栏状态感知（围栏外→红、缓冲带→橙） |
| **Task 18** — LivestockDetailSheet | ✅ 完成 | 状态标签已更新（ACTIVE/DISMISSED/AUTO_RESOLVED + 旧值兼容映射）；颜色映射完整 |
| **Task 19** — 全局回归 | ❌ 未完成 | 依赖 Task 14-18 全部完成，当前不满足 |

**前端 UI 层小结：1 个完整完成，5 个部分完成（组件代码写了但测试/细节缺失），1 个未开始。**

---

## 关键缺失项汇总

| 优先级 | 缺失项 | 影响范围 |
|--------|--------|---------|
| 🔴 高 | **全部代码未提交**（49 files, ±3019 lines，全在工作树） | 无版本记录，随时可丢失 |
| 🔴 高 | Task 16 — 详情页缺"忽略"按钮 + markRead + 能力边界说明 | 健康告警无法忽略、打开不标已读 |
| 🔴 高 | Task 17 — Marker 围栏状态变色未实现 | 地图上无法区分围栏外(红)/缓冲带(橙)/围栏内牲畜 |
| 🟡 中 | Task 4 — `FenceZoneController` 未创建 | fence-zones CRUD API 缺失 |
| 🟡 中 | Task 12/14/15 — 4 个 widget 测试未创建 | UI 组件无测试覆盖 |
| 🟡 中 | Task 8 — `ranch_overview_mock.json` 未创建 | 模型测试缺固件数据 |
| 🟡 中 | AlertDto 缺 `distance`/`direction` 字段（仅 RanchOverviewDto.AlertData 有） | 独立告警查询无距离/方向信息 |
| 🟢 低 | Task 19 — 全局回归+端到端冒烟 | 依赖前序完成 |

---

## 建议下一步

1. **先提交已完成的工作**，避免意外丢失
2. 优先补齐 🔴 高缺失项（Task 16 忽略按钮 + Task 17 Marker 变色）
3. 补齐 `FenceZoneController` 和 `AlertDto.distance/direction`
4. 补齐 widget 测试
5. 执行 Task 19 全局回归

---

## 已核查文件清单

### 后端（已变更，未提交）

- `smart-livestock-server/src/main/resources/db/migration/V26__alert_notification_model.sql` (新建)
- `smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/model/Alert.java` (修改)
- `smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/model/AlertStatus.java` (修改)
- `smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/model/AlertType.java` (修改)
- `smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/model/Fence.java` (修改)
- `smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/repository/AlertRepository.java` (修改)
- `smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/service/FenceBreachDetector.java` (修改)
- `smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/service/BufferPolygonCalculator.java` (新建)
- `smart-livestock-server/src/main/java/com/smartlivestock/ranch/application/AlertApplicationService.java` (修改)
- `smart-livestock-server/src/main/java/com/smartlivestock/ranch/application/FenceApplicationService.java` (修改)
- `smart-livestock-server/src/main/java/com/smartlivestock/ranch/application/RanchOverviewApplicationService.java` (修改)
- `smart-livestock-server/src/main/java/com/smartlivestock/ranch/application/dto/AlertDto.java` (修改)
- `smart-livestock-server/src/main/java/com/smartlivestock/ranch/application/dto/RanchOverviewDto.java` (修改)
- `smart-livestock-server/src/main/java/com/smartlivestock/ranch/infrastructure/persistence/entity/AlertReadStatusJpaEntity.java` (新建)
- `smart-livestock-server/src/main/java/com/smartlivestock/ranch/infrastructure/persistence/SpringDataAlertReadStatusRepository.java` (新建)
- `smart-livestock-server/src/main/java/com/smartlivestock/ranch/infrastructure/persistence/mapper/AlertMapper.java` (修改)
- `smart-livestock-server/src/main/java/com/smartlivestock/ranch/infrastructure/persistence/mapper/FenceMapper.java` (修改)
- `smart-livestock-server/src/main/java/com/smartlivestock/ranch/interfaces/AlertController.java` (修改)
- `smart-livestock-server/src/main/java/com/smartlivestock/ranch/interfaces/DashboardController.java` (修改)
- `smart-livestock-server/src/main/java/com/smartlivestock/ranch/interfaces/RanchOverviewController.java` (修改)
- `smart-livestock-server/src/main/java/com/smartlivestock/health/domain/port/RanchCommandPort.java` (修改)
- `smart-livestock-server/src/main/java/com/smartlivestock/health/infrastructure/acl/RanchCommandPortImpl.java` (修改)
- `smart-livestock-server/src/main/java/com/smartlivestock/health/infrastructure/acl/RanchQueryPortImpl.java` (修改)
- `smart-livestock-server/build.gradle` (修改)
- `smart-livestock-server/build.number` (修改)
- `smart-livestock-server/src/test/.../AlertTest.java` (修改)
- `smart-livestock-server/src/test/.../AlertApplicationServiceTest.java` (修改)
- `smart-livestock-server/src/test/.../AlertReadStatusTest.java` (新建)
- `smart-livestock-server/src/test/.../AlertStateMachineJourneyTest.java` (修改)
- `smart-livestock-server/src/test/.../FenceBreachDetectorTest.java` (修改)

### 前端（已变更，未提交）

- `Mobile/mobile_app/lib/features/ranch/domain/ranch_models.dart` (修改)
- `Mobile/mobile_app/lib/features/ranch/domain/ranch_repository.dart` (修改)
- `Mobile/mobile_app/lib/features/ranch/data/ranch_api_repository.dart` (修改)
- `Mobile/mobile_app/lib/features/ranch/presentation/ranch_controller.dart` (修改)
- `Mobile/mobile_app/lib/features/ranch/presentation/widgets/health_bottom_sheet.dart` (修改)
- `Mobile/mobile_app/lib/features/ranch/presentation/widgets/livestock_detail_sheet.dart` (修改)
- `Mobile/mobile_app/lib/features/ranch/presentation/widgets/status_dashboard_card.dart` (新建)
- `Mobile/mobile_app/lib/features/ranch/presentation/widgets/alert_card.dart` (新建)
- `Mobile/mobile_app/lib/features/ranch/presentation/widgets/device_info_line.dart` (新建)
- `Mobile/mobile_app/lib/features/ranch/presentation/widgets/auto_resolved_section.dart` (新建)
- `Mobile/mobile_app/lib/features/ranch/presentation/widgets/fence_alert_detail_sheet.dart` (新建)
- `Mobile/mobile_app/lib/features/ranch/presentation/widgets/fence_buffer_layer.dart` (新建)
- `Mobile/mobile_app/lib/features/alerts/domain/alerts_repository.dart` (修改)
- `Mobile/mobile_app/lib/features/alerts/data/alerts_api_repository.dart` (修改)
- `Mobile/mobile_app/lib/features/alerts/presentation/alerts_controller.dart` (修改)
- `Mobile/mobile_app/lib/features/pages/alerts_page.dart` (修改)
- `Mobile/mobile_app/lib/features/pages/fever_detail_page.dart` (修改)
- `Mobile/mobile_app/lib/features/pages/digestive_detail_page.dart` (修改)
- `Mobile/mobile_app/lib/features/pages/estrus_detail_page.dart` (修改)
- `Mobile/mobile_app/lib/features/pages/ranch_page.dart` (修改)
- `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart` (新建)
