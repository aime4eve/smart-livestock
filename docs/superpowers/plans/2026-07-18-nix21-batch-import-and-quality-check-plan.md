# NIX-21 GPS 质量检验重构 + 批量导入 — 实施计划

> **For agentic workers:** Use task-by-task implementation with checkbox tracking. Each task has verification criteria that must pass before proceeding to the next.

**Goal:** 重构 GPS 质量检查模块：废弃会话模型、新增视觉时间轴和设备分组、新增批量导入（后端解析 + 自动 blade 注册）、新增编辑重试、新增批次追踪、统一日期输入控件。

**Architecture:** 后端 Spring Boot 3.3 / Java 17，前端 Flutter（Riverpod），数据库 PostgreSQL 16。后端按 DDD 四层架构，新增 `GpsQualityBatchImportService` 作为应用服务，`DeviceApplicationService` 新增 `findOrCreateByEui` 方法。

**Spec:** `docs/superpowers/specs/2026-07-18-nix21-batch-import-and-quality-check-refactor.md`
**Prototype:** `docs/marketing/nix-21-batch-import-prototype.html`
**前依赖:** NIX-20 会话-检验模型（已存在，本次将其废弃）

---

## File Structure

### smart-livestock-server 后端 — 新建

| File | Responsibility |
|------|---------------|
| `iot/application/GpsQualityBatchImportService.java` | 批量导入核心服务：Apache POI 解析 + 逐行设备处理 + 检验创建 + 去重 |
| `iot/interfaces/admin/dto/BatchImportResultDto.java` | 批量导入逐行结果 DTO |

### smart-livestock-server 后端 — 修改

| File | Change |
|------|--------|
| `build.gradle` | 加 `poi-ooxml` 依赖 |
| `domain/repository/DeviceRepository.java` | 加 `findByDevEuiAndTenantId()` |
| `infrastructure/persistence/SpringDataDeviceRepository.java` | 加 JPA 派生方法 |
| `infrastructure/persistence/JpaDeviceRepositoryImpl.java` | 加委托 |
| `application/DeviceApplicationService.java` | 加 `findOrCreateByEui()` |
| `domain/model/GpsQualityTest.java` | 去 sessionId，加 deviceCode/deviceId/status/errorMessage/batchImportId |
| `domain/repository/GpsQualityTestRepository.java` | 适配新模型，加 `existsByEuiAndTimeRange(eui, startedAt, checkType)` 去重查询 + 加 `findByDeviceIdOrderByStartedAt()` 设备时间线查询 |
| `infrastructure/persistence/entity/GpsQualityTestJpaEntity.java` | 同步领域模型变更 |
| `infrastructure/persistence/JpaGpsQualityTestRepositoryImpl.java` | 适配新查询 |
| `infrastructure/persistence/SpringDataGpsQualityTestRepository.java` | 加 JPA 派生方法 |
| `domain/model/GpsQualitySession.java` | 删除（废弃） |
| `domain/repository/GpsQualitySessionRepository.java` | 删除（废弃） |
| `infrastructure/persistence/entity/GpsQualitySessionJpaEntity.java` | 删除（废弃） |
| `infrastructure/persistence/JpaGpsQualitySessionRepositoryImpl.java` | 删除（废弃） |
| `infrastructure/persistence/SpringDataGpsQualitySessionRepository.java` | 删除（废弃） |
| `application/GpsQualityReportService.java` | 去掉 session 依赖，直接从 test 取 deviceId |
| `application/DynamicQualityReportService.java` | 同上 |
| `interfaces/admin/GpsQualityAdminController.java` | 加 `/batch/import`、`/batch/template`、`/batch/retry-registration`、`/batch/retry-row`、`/batch/{batchId}`、`/checks`、`/checks/{id}/report` 端点；删 `/sessions` 端点 |
| `interfaces/admin/dto/GpsQualitySessionDto.java` | 删除 |
| `interfaces/admin/dto/ComparisonDto.java` | 适配新模型：去 session 关联，直接取 test.deviceId |
| `interfaces/admin/dto/QualityReportDto.java` | 适配新模型：去 session 关联，加 check.status 字段反映 DEVICE_PENDING/FAILED 状态 |
| `interfaces/admin/dto/GpsQualityTestDto.java` | 适配新模型：加 deviceCode/deviceId/status/errorMessage 字段，去 sessionId |
| | `src/main/resources/application.yml` | 配置 multipart 文件大小限制 |
| `com/smartlivestock/shared/common/ErrorCode.java` | 加 `INVALID_EUI_FORMAT`、`BATCH_IMPORT_ROW_SKIPPED` 错误码 |
| `src/main/resources/messages_zh.properties` | 加批量导入相关错误消息 |
| `src/main/resources/messages_en.properties` | 同上，英文版 |
| `src/main/resources/db/migration/V20260718XXXX__refactor_gps_quality_remove_sessions.sql` | 新建迁移文件 |

### Mobile/mobile_app 前端 — 新建

| File | Responsibility |
|------|---------------|
| `lib/core/widgets/date_time_input_field.dart` | 统一日期时间输入控件 |
| `lib/features/admin/gps_quality/presentation/batch_import_dialog.dart` | 批量导入对话框（3 步流程） |
| `lib/features/admin/gps_quality/presentation/create_check_dialog.dart` | 手动创建单条检验弹窗 |
| `lib/features/admin/gps_quality/presentation/edit_retry_dialog.dart` | 编辑失败数据并重试弹窗 |

### Mobile/mobile_app 前端 — 修改

| File | Change |
|------|--------|
| `lib/core/api/api_client.dart` | 加 `uploadFile()` 方法（multipart） |
| `lib/features/admin/gps_quality/data/gps_quality_api_repository.dart` | 加 `batchImport()`、`downloadBatchTemplate()`、`createCheck()`、`fetchChecks()`、`retryRow()`、`retryRegistration()`、`deleteBatch()`；删 `createSession()`、`createDynamicSession()`、`createTest()`、`fetchSessions()` |
| `lib/features/admin/gps_quality/data/gps_quality_providers.dart` | 加 `checksProvider`（替代 sessionsProvider+testsProvider） |
| `lib/features/admin/gps_quality/domain/gps_quality_models.dart` | 加 `QualityCheck` 模型 + `CheckStatus` 枚举；删 `GpsQualitySession` |
| `lib/features/admin/gps_quality/presentation/gps_quality_page.dart` | Tab 改 3 个、顶部加 [📡 批量注册] 条件按钮、加导入后横幅 |
| `lib/features/admin/gps_quality/presentation/session_test_tab.dart` | 重写为 quality_check_list：设备分组列表 + 搜索过滤 + 详情面板（时间轴色块条 + 报告） |
| `lib/features/admin/gps_quality/presentation/comparison_tab.dart` | 适配新模型 |
| `lib/features/admin/gps_quality/presentation/dynamic_report_tab.dart` | 删除内容（合并入质量检验详情） |
| `lib/features/admin/gps_quality/presentation/batch_create_session_dialog.dart` | 删除由 batch_import_dialog.dart 替代 |
| `lib/features/admin/gps_quality/presentation/rtk_calibration_tab.dart` | 保留但改名 |
| `lib/l10n/app_zh.arb` + `app_en.arb` | 补充翻译键 |

---

## Task 1: 数据库迁移

**文件：** 新建 `V20260718XXXXXX__refactor_gps_quality_remove_sessions.sql`

**操作：**
- [ ] `gps_quality_tests` 加列：`device_code`、`device_id`、`batch_import_id`、`status`、`error_message`、`started_at`（原名 test_started_at）、`ended_at`（原名 test_ended_at）
- [ ] 回填：`UPDATE gps_quality_tests SET device_code = ..., device_id = ..., status = 'READY' FROM gps_quality_sessions, devices`
- [ ] 改名：`RENAME COLUMN test_started_at TO started_at`
- [ ] 删约束/列：`DROP CONSTRAINT fk_gqt_session`、`DROP COLUMN session_id`
- [ ] 删表：`DROP TABLE IF EXISTS gps_quality_sessions CASCADE; DROP TABLE IF EXISTS rtk_calibration_sessions CASCADE;`
- [ ] 加 NOT NULL/索引：`ALTER COLUMN device_code SET NOT NULL`、建 `idx_gqt_device_id`、`idx_gqt_status`、`idx_gqt_type`

**验证：** `./gradlew compileJava` 编译通过，启动后 Flyway 校验通过

---

## Task 2: 后端基础设施

### 2a. 设备处理

**文件：** `DeviceRepository` / `SpringDataDeviceRepository` / `JpaDeviceRepositoryImpl` / `DeviceApplicationService`

- [ ] `DeviceRepository` 加 `Optional<Device> findByDevEuiAndTenantId(String devEui, Long tenantId)`
- [ ] `SpringDataDeviceRepository` 加 JPA 派生方法
- [ ] `JpaDeviceRepositoryImpl` 加委托
- [ ] `DeviceApplicationService` 加 `findOrCreateByEui(eui, deviceCode, tenantId)` — 查找/创建设备 + `activateOnPlatform()` 尝试 blade 注册
- [ ] `registerDevice()` 不动（保留 OpenAPI 注册路径）

### 2b. 领域模型改造

**文件：** `GpsQualityTest` / `GpsQualityTestJpaEntity` / `GpsQualityTestRepository`

- [ ] 去掉 `sessionId` 字段
- [ ] 加 `deviceCode`（String）、`deviceId`（Long）、`status`（String/枚举）、`errorMessage`（String?）、`batchImportId`（Long?）
- [ ] 适配 Repository 接口和 JPA 实现

### 2c. 清理废弃模型

**文件：** `GpsQualitySession`（领域模型 + JPA 实体 + Repository 接口 + 两个实现）

- [ ] 删除这 4 个文件

**验证：** `./gradlew compileJava` 编译通过

---

## Task 3: 批量导入

### 3a. Apache POI 依赖

**文件：** `build.gradle`
- [ ] 加 `implementation 'org.apache.poi:poi-ooxml:5.2.5'`

### 3b. DTO

**文件：** `BatchImportResultDto.java`
- [ ] 定义 `BatchImportResult`（batchId, totalRows, totalSuccess, totalPending, totalFailed, rows）
- [ ] 定义 `RowResult`（rowIndex, status: SUCCESS/DEVICE_PENDING/FAILED, eui, deviceCode, deviceId, checkId, message）

### 3c. 核心服务

**文件：** `GpsQualityBatchImportService.java`
- [ ] `importFromExcel(MultipartFile)` — 解析 Excel → 逐行处理 → 返回结果
- [ ] 行内去重：相同(EUI + startedAt)跳过
- [ ] 历史去重：已有相同(EUI + startedAt + testType)检验跳过
- [ ] Apache POI 解析列：EUI、deviceCode、checkType、truthRef、startedAt、endedAt
- [ ] 真值解析：`rtkPointRepository.findByPointLabel(name)` / `dynamicTestRouteRepository.findByName(name)`
- [ ] 设备处理：调用 `DeviceApplicationService.findOrCreateByEui()`
- [ ] 检验创建：根据所有解析结果创建 `GpsQualityTest`，设置 `batchImportId`

### 3d. Controller 端点

**文件：** `GpsQualityAdminController.java`
- [ ] `POST /batch/import` — multipart file → 批量导入
- [ ] `GET /batch/template` — 下载 .xlsx 模板
- [ ] `POST /batch/retry-registration` — 批量重试 blade 注册（传 checkIds 或不传则全重试）
- [ ] `POST /batch/retry-row` — 编辑失败数据后重试
- [ ] `DELETE /batch/{batchId}` — 删除批次
- [ ] 删旧端点：`/sessions`、`/sessions/{id}/tests`

### 3e. Multipart 配置

**文件：** `application.yml`
- [ ] `spring.servlet.multipart.max-file-size: 10MB`
- [ ] `spring.servlet.multipart.max-request-size: 10MB`

**验证：** `./gradlew compileJava` 通过

---

## Task 4: 手动创建 + 列表 + 报告/对比改造

### 4a. 手动创建 + 列表

**文件：** `GpsQualityAdminController.java`
- [ ] `POST /checks` — 单条创建（与导入单行逻辑一致）
- [ ] `GET /checks` — 扁平列表（?status=xxx&eui=xxx&deviceId=xxx&page=0&size=20）

### 4b. 报告/对比改造

**文件：** `GpsQualityReportService.java` / `DynamicQualityReportService.java` / `ComparisonDto.java` / `QualityReportDto.java`
- [ ] `generate(testId)` — 去 session 中转，直接从 test 取 `deviceId`
- [ ] 状态 != READY 时返回状态说明而非报错
- [ ] `generateComparison(rtkPointId)` — 去 session 中转
- [ ] `DynamicQualityReportService` 同上

**验证：** `./gradlew compileJava` 编译通过

---

## Task 5: 前端 API 层

### 5a. ApiClient 扩展

**文件：** `api_client.dart`
- [ ] 加 `uploadFile(String path, List<int> bytes, String fileName)` — multipart/form-data 上传

### 5b. Repository 适配

**文件：** `gps_quality_api_repository.dart`
- [ ] 加 `batchImport()` — 上传文件调用 batch/import
- [ ] 加 `downloadBatchTemplate()` — 调用 batch/template
- [ ] 加 `createCheck()` — 手动创建
- [ ] 加 `fetchChecks()` — 列表查询
- [ ] 加 `retryRow()` — 失败数据重试
- [ ] 加 `deleteBatch()` — 删除批次
- [ ] 删 `createSession()` / `createDynamicSession()` / `createTest()`

### 5c. Provider 适配

**文件：** `gps_quality_providers.dart`
- [ ] 加 `checksProvider`（替代 `gpsSessionsProvider` + `sessionTestsProvider`）
- [ ] 删 `calibrationSessionsProvider`

### 5d. 模型适配

**文件：** `gps_quality_models.dart`
- [ ] 加 `QualityCheck` 模型（deviceCode/deviceId/checkType/rtkPointId/routeId/startedAt/endedAt/status/errorMessage）
- [ ] 加 `CheckStatus` 枚举（READY / DEVICE_PENDING / FAILED）
- [ ] 删 `GpsQualitySession`

---

## Task 6: 前端 UI — 日期输入控件统一

**文件：** `core/widgets/date_time_input_field.dart`（新建）

- [ ] `DateTimeInputField` widget：
  - `TextField` + `TextEditingController`，支持直接输入 `yyyy-MM-dd HH:mm`
  - suffixIcon = `Icons.event`，点击触发 `showDatePicker` + `showTimePicker`
  - 输入错误时红色下划线提示
  - 失焦后自动格式化
- [ ] 替换 `batch_create_session_dialog.dart` 中的 `_CompactTimeField` → `DateTimeInputField`
- [ ] 替换 `session_test_tab.dart` 中的 `_DateTimeRow` → `DateTimeInputField`
- [ ] 删除两处内联日期控件代码
- [ ] l10n 补充翻译键

**验证：** `flutter analyze` 无错误

---

## Task 6b: 前端 UI — 页面重构

**文件说明：** 核心 UI 改动，从会话分栏改为设备分组 + 时间轴

- [ ] `gps_quality_page.dart`：
  - Tab 改 3 个（删「动态报告」Tab）
  - 顶部工具栏加 [📡 批量注册] 条件按钮（存在 DEVICE_PENDING 时显示）
  - 批量导入完成后顶部显示横幅（含 batchId 追踪 + 查看/删除/忽略）
- [ ] `session_test_tab.dart` 重写为 `quality_check_list.dart`：
  - 左侧：按设备分组列表（EUI + 设备编号 + 检验计数 + 类型分布 + 状态标签）
  - 右侧：设备概览（设备名 + 检验数 + 时间跨度 + 整体质量）+ 视觉时间轴色块条（蓝色/琥珀色色块，比例时长，点击切换）+ 当前检验报告（静态或动态区分展示）
  - 搜索/过滤条
  - DEVICE_PENDING 状态下详情面板显示批量注册/手动注册按钮
  - FAILED 状态下详情面板显示编辑并重试按钮
- [ ] `batch_create_session_dialog.dart` → `batch_import_dialog.dart`：3 步（上传→预览→结果）
- [ ] `create_check_dialog.dart`：手动创建弹窗（EUI 必填 + deviceCode 选填 + 类型切换 + 真值选择 + 时间范围）
- [ ] `edit_retry_dialog.dart`：编辑失败数据并重试弹窗（FAILED 详情面板 / 导入失败列表两种入口）
- [ ] `comparison_tab.dart` / `dynamic_report_tab.dart` 适配新模型
- [ ] `app_zh.arb` + `app_en.arb` 补充翻译键

**验证：** `flutter build web` 构建通过，原型功能可交互

---

## Task 7: 测试

### 7a. 后端单元测试

- [ ] `GpsQualityBatchImportServiceTest` — Excel 解析、行内去重、历史去重、设备处理、真值解析
- [ ] `DeviceApplicationService` 新增方法测试 — `findOrCreateByEui` 的查找/创建/注册逻辑
- [ ] `GpsQualityReportService` 改造后测试 — 去 session 后路径正常

### 7b. 后端集成测试

- [ ] 扩展 `GpsQualityJourneyTest` — 批量导入 API 上传 Excel、结果解析、注册重试、失败重试、批次删除

**验证：** `./gradlew test` 全部通过

---

## 依赖关系

```
Task 1 (DB迁移)
  │
  ├──→ Task 2a (设备处理)
  ├──→ Task 2b (模型改造)
  │     │
  │     └──→ Task 2c (清理废弃)
  │
  ├──→ Task 3a (POI依赖) → Task 3b (DTO) → Task 3c (核心服务) → Task 3d (Controller) → Task 3e (配置)
  │
  ├──→ Task 4a (手动创建+列表) → Task 4b (报告改造)
  │
  └──→ Task 5a (ApiClient) → Task 5b (Repository) → Task 5c (Provider) → Task 5d (模型)
        │
        └──→ Task 6 (日期控件) → Task 6b (页面重构)
              │
              └──→ Task 7 (测试)
```

---

## Git

**分支名：** `codex/nix-21-gps-batch-import`

提交策略：每个 Task 完成后独立提交，提交信息前缀 `feat(nix-21):` 或 `fix(nix-21):`。
