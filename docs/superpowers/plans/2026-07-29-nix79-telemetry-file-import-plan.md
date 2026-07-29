# NIX-79 设备遥测文件导入实施计划

> 日期：2026-07-29 · 工单：NIX-79 · spec：`docs/superpowers/specs/2026-07-29-nix79-telemetry-file-import-design.md`（已确认，含 D1-D6）
> 原型：`docs/marketing/nix-79-telemetry-import-prototype.html`（已确认）

## Task 0 — 视觉保真准备

- [ ] 原型基准截图归档：用 playwright 对 `#step1/#step2/#step3` 截图，存 `docs/marketing/nix-79-telemetry-import-prototype/`（step1/2/3.png），作为保真验证基准
- [ ] 核对 spec §5.5 令牌表与 `Mobile/mobile_app/lib/core/theme/app_colors.dart`、`app_spacing.dart` 一致（已勘察一致，复核即可）
- [ ] 已知偏差登记：`_IconSidebarItem` 选中色硬编码蓝 `#1565C0`（全侧栏一致，不修）；圆角/阴影无全局 token 按原型值散写
- 验证：截图文件生成且与原型渲染一致

## Task 1 — 后端：source 列迁移 + source 穿透 + 围栏抑制（D4/D6）

TDD：先写消费者抑制逻辑的测试，再实现。

- [ ] `TelemetrySource` 增加 `MANUAL_IMPORT`（`iot/domain/model/TelemetrySource.java`）
- [ ] Flyway `V20260729120000__nix79_manual_import_source.sql`：`gps_logs` + `device_telemetry_logs` 各加 `source VARCHAR(20) NOT NULL DEFAULT 'AGENTIC_PLATFORM'` + CHECK 约束（4 枚举值）（分区表自动传播，PG fast default 不重写表）
- [ ] `GpsLog` 领域模型 / `GpsLogJpaEntity` / Mapper 加 `source`；`SpringDataGpsLogRepository.upsertByDeviceAndRecordedAt` 原生 SQL 同步带 source（INSERT 与 ON CONFLICT UPDATE 两侧）
- [ ] `DeviceTelemetryLog` 领域模型 / JpaEntity / Mapper 加 `source`
- [ ] `GpsLogApplicationService.logGps(...)` 增 `TelemetrySource source` 参数（唯一调用方 `TelemetryIngestionService:246`，一并改）；`GpsLog` 构造带 source
- [ ] `GpsLogUpdatedEvent` 增 `source` 字段（Jackson 序列化；消费端缺省按 AGENTIC_PLATFORM 处理，兼容在途消息）
- [ ] `GpsLogEventConsumer.onMessage`：`source == "MANUAL_IMPORT"` → 整条消息早退（**围栏告警与 `livestock.updatePosition` 一并跳过**——历史点不得回写牲畜当前位置）
- 验证：`./gradlew compileJava` 通过；`GpsLogEventConsumer` 相关测试通过（新增 MANUAL_IMPORT 抑制用例 + 既有 AGENTIC_PLATFORM 用例不回归）

## Task 2 — 后端：TrackerPayloadDecoder（固件协议移植，D2/D3）

TDD：先用真实样例帧写测试 fixtures，再实现。

- [ ] 新增 `iot/domain/service/TrackerPayloadDecoder.java`：同步头校验 → offset 5 TLV 循环 → `Optional<DecodedTrackerFrame>`（字段见 spec §4.3 映射表）；未知 type / 截断 / 非同步头 → empty
- [ ] `DecodedTrackerFrame.toReadings()`：battery、latitude/longitude（特殊 u32 ÷1e6）、`stepCount`（0x15 周期值直映，**不写 stepNumber**，spec §4.5）、accelXRaw/YRaw/ZRaw（s16 有符号直放）、antiDisassemblyStatus
- [ ] 复用 `AccelerometerConverter`（iot/.../agenticplatform/util/）注入 g 值/magnitude/motionIntensity/activityClass/roll/pitch；可见性不足则调 public，不复制逻辑
- [ ] 单测 `TrackerPayloadDecoderTest`：
  - 0095690600028577 真实周期帧 → lat 28.246777 / lng 112.851138 / step 27 / accel (-921,-665,-1280) / battery 99（断言到小数位）
  - `61 00...` 注册帧、13 字节 ACK 帧、`001a0103ff000231` 样例帧（special_type=02、含 0x8A/0x30）→ empty
  - 空数组、截断帧、(0,0) 坐标帧边界
- 验证：`./gradlew test --tests "*TrackerPayloadDecoder*"` 通过

## Task 3 — 后端：TelemetryIngestionService 适配（spec §4.4）

- [ ] `updateDeviceRuntimeStatus` 调用点对 `MANUAL_IMPORT` 跳过（快照隔离：battery/rssi/snr/gateway/lastOnlineAt 不被历史值污染）
- [ ] `logDeviceTelemetry`：battery/rssi/snr/gatewayId 改 readings 优先、设备快照兜底；写入 source 列
- [ ] `extractAndLogGps` 把 source 传给 logGps（接 Task 1 签名）
- [ ] 回归测试：AGENTIC_PLATFORM 行为不变（快照仍更新、告警/游标分支不变）；MANUAL_IMPORT 快照不变、telemetry log 行携带 readings 历史值与 source=MANUAL_IMPORT
- 验证：`./gradlew test --tests "*TelemetryIngestion*"` 通过

## Task 4 — 后端：TelemetryImportService + Controller + DTO + i18n

TDD：先写行分类矩阵与设备匹配的测试。

- [ ] `DeviceTelemetryLogRepository` 新增 `findReportTimesByDeviceIdAndReportTimeBetween(deviceId, min, max)`（分区表范围查询，前置重复检测）
- [ ] `iot/application/TelemetryImportService.java`（不挂类级 @Transactional；MAX_ROWS=5000）：
  - 文件名 `^([0-9A-Fa-f]{16})` 提取 DevEUI；`findAllByDevEuiAndTenantIdIncludeDeleted` 匹配，过滤软删；未注册/非 ACTIVE/非 TRACKER → 整文件报错（D4）
  - POI 读 xlsx 第 0 sheet，表头探测；行分类矩阵（spec §4.2）：SKIPPED_DOWNLINK / INVALID（hex、时间——禁 fallback now()，经验 #10）/ SKIPPED_UNSUPPORTED / DUPLICATE / IMPORTABLE
  - 时间解析支持 `yyyy-MM-dd HH:mm:ss[.SSSSSS]` → `toInstant(ZoneOffset.UTC)`（经验 #17）
  - import：IMPORTABLE 行按时间升序逐行 `ingest(..., MANUAL_IMPORT)`，单行失败计数继续
- [ ] `iot/interfaces/admin/TelemetryImportAdminController.java`：`/api/v1/admin/telemetry-import/parse|import`，multipart，`@PreAuthorize("hasRole('PLATFORM_ADMIN')")`，tenant fallback 1L（沿用 GpsQualityAdminController 先例）
- [ ] DTO：`TelemetryParseResultDto`（含 DeviceMatchDto + Row 列表）、`TelemetryImportResultDto`（spec §4.1）
- [ ] messages_zh/en.properties 双语同步 7 个 `error.telemetryImport.*` key（spec §4.8）
- [ ] 单测 `TelemetryImportServiceTest`：分类矩阵、整文件报错三态、重复检测、时间解析（含微秒）、import 幂等重放
- 验证：`./gradlew compileJava && ./gradlew test --tests "*TelemetryImport*"` 通过

## Task 5 — 前端：模型 + repository + 路由 + 侧栏 + i18n

- [ ] `lib/features/admin/telemetry_import/`：`domain/telemetry_import_models.dart`（手写 fromJson）、`data/telemetry_import_api_repository.dart`（`static const _base = '/admin/telemetry-import'`，parse/import 两方法走 `ApiClient.uploadFile`）
- [ ] `app_route.dart` 增 `platformTelemetryImport('/admin/telemetry-import', ...)`；`app_router.dart` ShellRoute 平铺注册；`main_shell.dart` GPS 质量检查后插 `_IconSidebarItem(icon: Icons.upload_file_outlined, ...)`
- [ ] `app_zh.arb` / `app_en.arb` 同步 `telemetryImport*` key（spec §5.4）
- 验证：`flutter gen-l10n` 无缺失 key；`flutter analyze` 通过

## Task 6 — 前端：页面三步流 + 测试

- [ ] `presentation/telemetry_import_controller.dart`（AsyncNotifier 状态机：步骤/文件/预览/结果）
- [ ] `presentation/telemetry_import_page.dart`：Scaffold + AppBar + 页面内嵌三步流（组件规格 spec §5.3）；`@visibleForTesting debugFileBytes` 钩子；文件选择复用 `features/admin/gps_quality/data/web_file_utils.dart`；全部 key 命名 `telemetry-import-*`
- [ ] 测试：`telemetry_import_models_test.dart`（fromJson）；widget 测试仿 `batch_import_preview_test.dart`（_FakeRepo + debugFileBytes 驱动三步流，断言设备卡/统计条/状态 tag/未注册禁用态）
- [ ] **保真验证**：运行 `prototype-to-flutter-fidelity` skill，对照 Task 0 基准截图逐组件核对（上传区/统计条/设备卡/预览表 tag 配色/结果横幅），偏差点修复
- 验证：`flutter analyze` 通过；`flutter test test/features/admin/telemetry_import/` 通过

## Task 7 — 文档 + 编译部署 + 集成验证

- [ ] `docs/api-contracts/admin-api.md` 增补两个端点契约
- [ ] 后端 `./gradlew build` 通过；前端 `build_web.sh` 构建
- [ ] `./scripts/deploy.sh dev` 部署
- [ ] **部署后**集成验证（不得提前）：
  - curl `parse`：真实样例 `0095690600028577-历史数据.xlsx` → 统计与分类符合预期（可解码/将导入/跳过计数合理，设备已匹配）
  - curl `import` → 库内验证：telemetry/gps 行数、source=MANUAL_IMPORT、设备快照未被改写、`lastTelemetrySyncedAt` 未推进、无新告警
  - 重复 import 同一文件 → 全量 DUPLICATE 跳过，无约束冲突
  - `001a0103ff000231-历史数据.xlsx` → 设备未注册或全帧 SKIPPED_UNSUPPORTED，无脏数据
  - 前端页面走查三步流
- [ ] 用户集成测试 → 提交 git + 合并 PR + 关闭 NIX-79

## 备注

- 无新增表/枚举落库以外的 seed 需求（source 列默认值即回填，AGENTS.md §7.2 不涉及）
- 经验引用：#10（时间禁 fallback now()）、#11（source 列）、#17（UTC 原值）已在对应 Task 标注
- 部署顺序约定：先后端迁移+代码，再前端构建，一次 `deploy.sh dev` 完成；集成测试全部在部署后执行
