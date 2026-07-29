# NIX-79 设备遥测文件导入设计

> 日期：2026-07-29 · 工单：NIX-79 · 状态：待评审
> 原型：`docs/marketing/nix-79-telemetry-import-prototype.html`（已确认，令牌随本文锁定）

## 1. 背景与目标

blade 平台故障丢失设备遥测数据，运维手持平台导出的原始帧文件（xlsx，6 列：数据类型/帧计数器/数据(hex)/RSSI/SNR/创建时间），需要手工补录进系统。

目标：平台后台提供「遥测数据导入」页面，上传 xlsx → 解析 hex 帧 → 按现有 `TelemetryIngestionService.ingest()` 统一入口落库（devices 遥测日志 + gps_logs + 健康域事件下游），幂等可重复导入。

## 2. 决策记录（用户已确认）

| # | 决策点 | 结论 |
|---|--------|------|
| D1 | 功能归宿 | 平台后台（`/admin/*`）新增「遥测数据导入」独立页面，侧栏入口位于 GPS 质量检查旁 |
| D2 | 解码策略 | Java 移植解码器，以固件组包协议为准（`docs/protocols/LoRaWAN 牛羊追踪器上行 Payload 解析协议定义.md`），不用平台 JS（§9 已证实与固件不一致，实测解不出样例设备 GPS） |
| D3 | 设备覆盖 | 首版仅支持牛羊追踪器（`68 6B 74` 帧头 + 固件 TLV）；`001a0103ff000231` 等不匹配帧在预览中标记跳过，不产生错误数据 |
| D4 | 数据规范 | `gps_logs` + `device_telemetry_logs` 增加 `source` 列（Flyway 迁移，经验 #11）；DevEUI 未注册的设备整文件报错，不自动注册 |
| D5 | UI/UX | 页面内嵌三步流（上传 → 解析预览 → 导入结果），见原型 |
| D6 | 围栏告警 | MANUAL_IMPORT 来源的 GPS 点抑制围栏越界检测（logGps 穿透 source，GpsLogEventConsumer 按 source 过滤），历史补录不向牧场主补发历史告警 |

## 3. 总体链路

```
xlsx (blade 导出)
  → TelemetryImportService.parse / import            (新增, iot/application)
      ├─ 文件名提取 DevEUI → 设备匹配（必须已注册且 ACTIVE，否则整文件报错）
      ├─ 逐行：过滤下行 → hex 解析
      ├─ TrackerPayloadDecoder.decode(bytes)         (新增, iot 域内)
      │     └─ 固件协议 TLV → readings Map（复用 AccelerometerConverter 算 g 值/活动分类）
      ├─ 重复检测：device_telemetry_logs (device_id, report_time) 已存在 → 标记重复
      └─ import：按时间升序逐行 TelemetryIngestionService.ingest(deviceId, readings, ts, MANUAL_IMPORT)
            ├─ device_telemetry_logs（含历史值 battery/rssi/snr，source=MANUAL_IMPORT）
            ├─ gps_logs（TRACKER 且经纬度非 (0,0)，upsert 幂等，source=MANUAL_IMPORT）
            ├─ TelemetryReceivedEvent → 健康域（活动量/步数参与分析）
            └─ 不触发告警、不推同步游标、不污染设备运行时快照
```

## 4. 后端设计

### 4.1 API 端点（Admin API，新增）

`iot/interfaces/admin/TelemetryImportAdminController.java`，类级：

```java
@RestController
@RequestMapping("/api/v1/admin/telemetry-import")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
```

tenant 解析沿用 `GpsQualityAdminController` 先例：`TenantContext.getCurrentTenant()`，null 时 `FALLBACK_TENANT_ID = 1L`。

| 端点 | 方法 | 说明 |
|------|------|------|
| `/api/v1/admin/telemetry-import/parse` | POST multipart (`file`) | 解析预览，零持久化 |
| `/api/v1/admin/telemetry-import/import` | POST multipart (`file`) | 解析 + 落库 |

返回 `ApiResponse<TelemetryParseResultDto>` / `ApiResponse<TelemetryImportResultDto>`；异常走 `GlobalExceptionHandler`（ApiException → message key 经 MessageSource 解析）。

**TelemetryParseResultDto**：

```java
record TelemetryParseResultDto(
    int totalRows,        // 总数据行（不含表头）
    int uplinkRows,       // 上行行数
    int decodableRows,    // 可解码帧数
    int importableRows,   // 将导入（可解码 - 重复 - 无效）
    int gpsPointRows,     // 含有效 GPS 的行数
    int duplicateRows,    // (设备,时间) 已存在
    int skippedRows,      // 下行 + 非遥测/协议外帧
    int invalidRows,      // 行级错误（时间格式等）
    DeviceMatchDto device,          // 设备匹配结果
    List<Row> rows                  // 逐行预览（全量，前端截取展示）
) {
  record DeviceMatchDto(boolean matched, String devEui, String deviceCode,
                        String deviceType, String livestockName, String farmName,
                        String error) {}   // matched=false 时 error 给原因 key
  record Row(int rowNo, String frameCounter, Instant recordTime,
             Integer battery, BigDecimal latitude, BigDecimal longitude, Integer stepCount,
             String status,   // IMPORTABLE / DUPLICATE / SKIPPED_DOWNLINK / SKIPPED_UNSUPPORTED / INVALID
             String error) {}
}
```

**TelemetryImportResultDto**：

```java
record TelemetryImportResultDto(
    int telemetryCreated, int gpsCreated, int duplicateSkipped,
    int skippedRows, int invalidRows, int failedRows,
    String devEui, String deviceCode) {}
```

### 4.2 TelemetryImportService（新增，`iot/application`）

仿 `TrajectoryImportService`：**不挂类级 `@Transactional`**（逐行 ingest 各自带事务）；`MAX_ROWS = 5000`。

- `parse(MultipartFile, tenantId)`：readRows → 设备匹配 → 逐行 classify → 重复检测 → DTO，零持久化。
- `import(MultipartFile, tenantId)`：同管线，过滤出 IMPORTABLE 行，按 recordTime 升序，逐行 `ingest(..., MANUAL_IMPORT)`；单行异常计数 failedRows 并继续（不整体回滚）。

**文件读取**：POI `XSSFWorkbook` 第 0 个 sheet；表头探测（A 列 == "数据类型" 则跳过）；列：A 数据类型 / B 帧计数器 / C 数据 / D RSSI / E SNR / F 创建时间。仅支持 `.xlsx`（csv 不在需求内）。

**文件名 DevEUI 提取**：`^([0-9A-Fa-f]{16})` 前缀匹配；不匹配 → `VALIDATION_ERROR`（`error.telemetryImport.badFileName`）。

**设备匹配**：`deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted(eui, tenantId)` 过滤 `deletedAt == null`：
- 未找到 → `matched=false`，error=`error.telemetryImport.deviceNotRegistered`，整文件不可导入（D4）
- 设备 `status != ACTIVE` → `matched=false`，error=`error.telemetryImport.deviceNotActive`（ingest 对非 ACTIVE 抛 STATE_CONFLICT，前置拦截）
- `deviceType != TRACKER` → `matched=false`，error=`error.telemetryImport.unsupportedDeviceType`（D3）

**行分类**（优先级从上到下）：

| 状态 | 条件 |
|------|------|
| `SKIPPED_DOWNLINK` | A 列 ≠ "上行" |
| `INVALID` | hex 无法解析 / 时间为空或格式错误（**禁止 fallback now()**，经验 #10） |
| `SKIPPED_UNSUPPORTED` | 同步头非 `68 6B 74`，或 TLV 遇未知 type（注册帧/ACK 帧/其他型号） |
| `DUPLICATE` | 解码成功但 (device_id, report_time) 已存在于 device_telemetry_logs |
| `IMPORTABLE` | 其余；含非 (0,0) 经纬度的行计入 gpsPointRows |

**重复检测**（parse 与 import 共用）：文件行时间范围 [min,max] 内，新增 Repository 查询 `findReportTimesByDeviceIdAndReportTimeBetween(deviceId, min, max)` 一次取出，内存比对。（device_telemetry_logs 有 `uq_dtl_device_report_time` 但 JPA save 无 ON CONFLICT，前置检测既支撑预览又避免约束冲突；gps_logs 侧由既有 upsert 兜底。）

**时间解析**：支持 `yyyy-MM-dd HH:mm:ss[.SSSSSS]`（样例含微秒 `2026-07-27 20:16:47.828000`），`LocalDateTime.parse(...).toInstant(ZoneOffset.UTC)`（经验 #17，原值不换算）。

### 4.3 TrackerPayloadDecoder（新增，`iot/domain/service`）

按固件协议文档移植（非 JS）：

- 校验 `bytes[0..2] == 68 6B 74`；`bytes[3]`=special_type、`bytes[4]`=pack_sync_number（仅记录，不参与业务）
- 从 offset 5 起 TLV 循环，type 决定长度：

| type | 字段 | 长度 | readings 映射 |
|------|------|------|---------------|
| `0x01` | 软/硬件版本 | 2 | 不入 readings（仅调试日志） |
| `0x02` | 设备 ID | 6 | 不映射（设备按文件名 DevEUI 匹配） |
| `0x03` | 电量 | 1 | `battery` (Integer) |
| `0x09` / `0x0A` | 温度/湿度 | 3 | 跳过（倍数口径未确认，协议文档 §6.4） |
| `0x0B/0x0C/0x0D` | 三轴加速度 s16 | 2 | `accelXRaw/YRaw/ZRaw`（有符号值直接放入，Converter 直通） |
| `0x10` / `0x11` | 纬度/经度 | 4 | `latitude`/`longitude`（特殊 u32：>0x7FFFFFFF 取负，÷1e6 → BigDecimal） |
| `0x15` | 周期步数 u16 | 2 | **`stepCount`**（见 4.5） |
| `0x32` | 主动同步 | 1 | 跳过 |
| `0x39` | 运行模式配置 | 15 | 跳过 |
| `0x81/0x82/0x83` | 供电/工作模式/故障 | 1 | 跳过 |
| `0x84` | 防拆 | 1 | `antiDisassemblyStatus` (Integer) |
| `0xFF` | ACK | 1 | 跳过 |
| 其他 | — | — | 整帧 `SKIPPED_UNSUPPORTED`（TLV 无法继续） |

- 解码后复用 `iot/infrastructure/client/agenticplatform/util/AccelerometerConverter`（`toG` 0.004/digit、magnitude、motionIntensity、`classifyActivity` 1.15/1.5/2.5、roll/pitch）注入 `accelXG/YG/ZG`、`accelMagnitudeG`、`motionIntensity`、`activityClass`、`rollDegrees`、`pitchDegrees`——与平台链路数值口径完全一致。可见性若不足则调整该工具类为 public，不复制逻辑。
- RSSI/SNR 不在帧内，从 xlsx D/E 列进 readings（`rssi` Integer / `snr` BigDecimal）；空则缺省。
- 帧内无网关信息 → `gatewayId` 不设置。

### 4.4 TelemetryIngestionService 适配（最小改动）

新增枚举值 `TelemetrySource.MANUAL_IMPORT`（javadoc: 手工文件导入的历史数据）。现状分支（仅 `AGENTIC_PLATFORM` 触发告警检测 + 推游标）对新值天然满足隔离。另需两处显式适配：

1. **设备运行时快照隔离**：`updateDeviceRuntimeStatus`（battery/rssi/snr/gateway/lastOnlineAt=now）对 `MANUAL_IMPORT` **跳过**——历史数据不得把设备的"当前电量/在线时间"改写为历史值。
2. **遥测日志取历史值**：`logDeviceTelemetry` 目前从设备快照复制 battery/rssi/snr/gatewayId；改为 **readings 优先、快照兜底**，使导入行记录各自行携带的历史值（配合第 1 点否则导入行会带上当前快照值）。

两处均为 `TelemetryIngestionService` 内的小分支调整，不影响 AGENTIC_PLATFORM/DATAGEN 既有行为（这两个源的 readings 与快照值一致，优先级调换无差异）。

### 4.5 步数语义决策：直接注入 `stepCount`

- 平台链路的 `stepNumber` 是**累计值**，`computeStepDelta` 靠"本次−上次"差值注入 `stepCount`（周期增量，供健康域消费）。
- 固件 `0x15` 是**周期值**（上报后设备清零，协议文档 §6.9），且历史回填时 `findLatestByDeviceId` 基准错误（返回全局最新行而非前一行）。
- 结论：解码器把 `0x15` 直接映射为 `stepCount`，**不写 `stepNumber`**。`computeStepDelta` 因缺 key 直接返回，无副作用；`device_telemetry_logs.step_number` 对导入行留空（不与累计值混语义）。健康域 `TelemetryReceivedEvent` 正常拿到 `stepCount`。

### 4.6 Flyway 迁移（source 列，D4）

`V20260729120000__nix79_manual_import_source.sql`（命名沿用日期型约定）：

```sql
ALTER TABLE gps_logs
  ADD COLUMN IF NOT EXISTS source VARCHAR(20) NOT NULL DEFAULT 'AGENTIC_PLATFORM';
ALTER TABLE gps_logs
  ADD CONSTRAINT chk_gps_logs_source
  CHECK (source IN ('AGENTIC_PLATFORM','DATAGEN','HTTP','MANUAL_IMPORT'));

ALTER TABLE device_telemetry_logs
  ADD COLUMN IF NOT EXISTS source VARCHAR(20) NOT NULL DEFAULT 'AGENTIC_PLATFORM';
ALTER TABLE device_telemetry_logs
  ADD CONSTRAINT chk_dtl_source
  CHECK (source IN ('AGENTIC_PLATFORM','DATAGEN','HTTP','MANUAL_IMPORT'));
```

- 默认值按存量主来源回填为 `AGENTIC_PLATFORM`（dev 环境 datagen 数据误标可接受，无可靠区分手段）。
- `device_telemetry_logs` 为分区表，ADD COLUMN / CHECK 自动传播到分区；PG 11+ fast default 不重写表。
- 代码侧：`GpsLogJpaEntity` / `DeviceTelemetryLogJpaEntity` 加 `source` 字段；`logDeviceTelemetry` 写入 ingest 的 source；`GpsLogApplicationService.logGps` 增加 source 参数（重载保留旧签名=HTTP 源，梳理全部调用方逐个传入；upsert 分支同步更新 source 值）。

### 4.7 幂等

- 重复导入同一文件：telemetry 行被 (device_id, report_time) 前置检测为 DUPLICATE 跳过；gps 行由 `upsertByDeviceAndRecordedAt` ON CONFLICT 兜底。整体幂等，可安全重放。
- 文件内重复行（同帧计数/同时间）：按 (report_time) 去重，后到者计入 duplicateRows。

### 4.8 后端 i18n（messages_zh/en.properties 双语同步）

| key | zh | en |
|-----|----|----|
| `error.telemetryImport.badFileName` | 文件名须以 16 位设备 DevEUI 开头 | Filename must start with the 16-char device DevEUI |
| `error.telemetryImport.deviceNotRegistered` | 设备未注册：{0} | Device not registered: {0} |
| `error.telemetryImport.deviceNotActive` | 设备未激活：{0} | Device not active: {0} |
| `error.telemetryImport.unsupportedDeviceType` | 暂不支持的设备类型：{0} | Unsupported device type: {0} |
| `error.telemetryImport.tooManyRows` | 行数超过上限 {0} | Row count exceeds limit {0} |
| `error.telemetryImport.invalidTime` | 时间格式错误 | Invalid time format |
| `error.telemetryImport.invalidHex` | 报文 hex 解析失败 | Failed to parse payload hex |

行级 error 字段存 key，前端按 key 映射 l10n 文案（避免后端硬编码中文进 DTO 的历史问题）。

## 5. 前端设计（Mobile/mobile_app）

### 5.1 目录（新增，沿用 features/admin 惯例）

```
lib/features/admin/telemetry_import/
├── data/telemetry_import_api_repository.dart   # parse/import 两方法，static const _base = '/admin/telemetry-import'
├── domain/telemetry_import_models.dart         # 手写 fromJson（无 freezed）
└── presentation/
    ├── telemetry_import_controller.dart        # AsyncNotifier 状态机（步骤/文件/预览/结果）
    └── telemetry_import_page.dart              # 页面 + 三步流
```

- 文件选择：跨 feature 复用 `features/admin/gps_quality/data/web_file_utils.dart` 的 `pickFileBytesWithName(['xlsx'])`（条件导入机制现成；不复制文件）。
- 上传：`ApiClient.instance.uploadFile(path, bytes, fileName)`（multipart 字段名 `file`，超时 30s）。
- 页面保留 `@visibleForTesting final Uint8List? debugFileBytes` 测试钩子（先例）。

### 5.2 路由与侧栏

- `app_route.dart` 新增：`platformTelemetryImport('/admin/telemetry-import', 'platform-telemetry-import', '遥测数据导入')`
- `app_router.dart` ShellRoute 内平铺注册 GoRoute → `TelemetryImportPage()`；角色守卫已被 `/admin/` 前缀覆盖（仅 PLATFORM_ADMIN），无需改动。
- `main_shell.dart` `_PlatformAdminShell`：GPS 质量检查条目之后插入 `_IconSidebarItem(icon: Icons.upload_file_outlined, ...)`。
- 既有偏差说明：`_IconSidebarItem` 选中色硬编码蓝 `#1565C0`（全侧栏一致），原型绿色选中态**不在本工单修复**，保持现状一致。

### 5.3 页面三步流（组件视觉规格，对应原型）

| 组件 | 规格 |
|------|------|
| 步骤指示器 | 3 步圆点（22px 圆，active 描边 primary，done 填充 primary + ✓），连接线 32×2 |
| 上传区 | 虚线边框 2px border，圆角 12，hover 填 primarySoft；图标 40px；选中后显示等宽字体文件名 |
| 格式说明表 | 列字母(20px 粗体) + 列名(90px) + 必填/可选标签 + 说明文字 |
| 说明条 note | 左 3px 边条：蓝(info #EFF6FB/#33566B) 解码能力、琥珀(warning #FFFBEB/#7A5A18) 导入规则 |
| 统计条 | 6 项 stat（值 24px 700 + 标签 11px secondary）：总行数/上行帧/可解码/将导入(ok 绿)/重复跳过(warning)/非遥测跳过 |
| 设备匹配卡 | 左 4px 边条：matched=success 绿 / unmatched=danger 红 + 浅红底；等宽 EUI + 状态 tag + 设备元信息行 |
| 预览表 | DataTable，等宽 12px；状态 tag：将导入(t-ok 绿)/重复(t-dup 橙)/跳过(t-skip 灰)/错误(t-er 红)；默认展示前 8 行 + "完整 N 行已解析"提示 |
| 结果横幅 | 浅绿底 #EEF7EF + 左 3px success 边条 |
| 按钮 | FilledButton(primary) / OutlinedButton(border)；未匹配设备时导入按钮禁用 |

### 5.4 前端 i18n key（app_zh/app_en 同步，`AppLocalizations.of(context)!` 访问）

前缀 `telemetryImport*`（约 24 个）：`telemetryImportTitle`（遥测数据导入/Telemetry Import）、`telemetryImportStepUpload/Preview/Result`、`telemetryImportUploadTitle/Hint`、`telemetryImportFormatTitle`、各 stat 标签、`telemetryImportDeviceMatched/DeviceNotMatched`、`telemetryImportRowWillImport/Duplicate/SkipDownlink/SkipUnsupported/Invalid`、`telemetryImportConfirmAction({count})`、`telemetryImportDone({telemetry},{gps})`、`telemetryImportImportAnother`、`telemetryImportPreviewNote({total})` 等。`flutter gen-l10n` 无缺失 key、`flutter analyze` 无未定义引用。

### 5.5 设计令牌表（原型 :root ↔ Flutter，已锁定）

| 令牌 | 值 | Flutter 对应 |
|------|----|--------------|
| `--primary` / `--primary-dark` / `--primary-soft` | `#2F6B3B` / `#244F2D` / `#E3F0E4` | `AppColors.primary/primaryDark/primarySoft` |
| `--accent` | `#8BA95A` | `AppColors.accent` |
| `--surface` / `--surface-alt` / `--border` | `#F8F6F0` / `#FFFFFF` / `#D7D2C6` | `AppColors.surface/surfaceAlt/border` |
| `--text-primary` / `--text-secondary` | `#263126` / `#617061` | `AppColors.textPrimary/textSecondary` |
| `--success/--warning/--danger/--info` | `#4C9A5F` / `#D28A2D` / `#C2564B` / `#4A7F9D` | `AppColors.success/warning/danger/info` |
| `--xs..--xl` | 4 / 8 / 12 / 16 / 24 | `AppSpacing.xs..xl` |
| `--radius-sm/md/lg` | 4 / 8 / 12 | `BorderRadius.circular(4/8/12)`（散写，无全局 token） |
| `--shadow-sm/md/lg` | 0 1px 3px .08 / 0 2px 8px .15 / 0 20px 60px .2 | 卡片 elevation 0.8（主题既有） |

### 5.6 测试

- unit：`telemetry_import_models_test.dart`（fromJson 防御性解析）。
- widget：仿 `batch_import_preview_test.dart`，`_FakeRepo extends TelemetryImportApiRepository` 记录调用，`debugFileBytes` 钩子驱动三步流，断言全用 `find.byKey`（key 命名 `telemetry-import-*`）。
- 后端：`TrackerPayloadDecoderTest`（真实样例帧：0095690600028577 的周期上报帧 → 经纬度/步数/加速度断言；注册帧/ACK 帧/001a01 帧 → UNSUPPORTED；边界：空帧、截断帧、未知 type）；`TelemetryImportServiceTest`（分类/去重/设备匹配/整文件报错）；ingest 适配点的回归测试（MANUAL_IMPORT 不改快照、logDeviceTelemetry readings 优先）。

## 6. 下游影响

| 下游 | 行为 | 说明 |
|------|------|------|
| 健康域（TelemetryReceivedEvent） | 正常消费 | stepCount/activityClass 进入活动量分析——补录历史正是目的 |
| 告警 | 不触发 | 仅 AGENTIC_PLATFORM 触发；历史补录不产生拆机/低电告警 |
| 平台同步游标 | 不推进 | `lastTelemetrySyncedAt` 仅 AGENTIC_PLATFORM；不干扰恢复后的正常轮询 |
| 设备运行时快照 | 不更新（4.4-1） | battery/rssi/lastOnlineAt 保持实时链路口径 |
| 围栏越界检测 | **抑制**（D6） | logGps 增 source 参数穿透；`GpsLogEventConsumer` 对 `MANUAL_IMPORT` 来源的 GPS 点跳过围栏越界检测——历史补录只补数据，不向牧场主补发历史越界告警 |

## 7. 边界与异常

| 场景 | 处理 |
|------|------|
| 文件名无 DevEUI 前缀 | 整文件 400 `badFileName` |
| DevEUI 未注册/未激活/非 TRACKER | 预览设备卡红态 + 原因，导入按钮禁用；import 端点复验同样报错 |
| 全部行不可导入 | 预览可见分类统计；import 返回全零结果不报错 |
| 单行 ingest 失败 | 计数 failedRows 继续，结果中体现 |
| 超过 5000 行 | 400 `tooManyRows` |
| 时间含微秒 | 解析支持 `.SSSSSS`；入库 timestamp 精度内 |
| 混多个设备的帧（帧内 0x02 ID 与文件 DevEUI 不符） | 不校验一致性（帧 ID 仅 6 字节可能碰撞），按文件 DevEUI 归属；预览不展示帧内 ID |

## 8. 非目标（明确排除）

- 瘤胃胶囊（`0xC1` 在那协议）及其他设备型号的解码器（架构上 Decoder 可注册扩展，后续按协议文档增补）
- `001a0103ff000231` 设备帧的解码（协议未知，单独跟进）
- 嵌入 JS 引擎执行平台原版 decoder
- 导入历史记录列表（审计向，后续扩展）
- csv 格式支持、模板下载（blade 导出即 xlsx，无需模板）

## 9. 交付物清单（编码阶段）

1. 后端：`TelemetryImportAdminController`、`TelemetryImportService`、`TrackerPayloadDecoder`、DTO、`TelemetrySource.MANUAL_IMPORT`、`TelemetryIngestionService` 两处适配、`GpsLogApplicationService.logGps` source 参数、两个 JPA Entity 加 source 字段、Repository 新方法、Flyway 迁移、messages 双语 key、单测
2. 前端：feature 目录 4 文件、路由/侧栏注册、arb 双语 key、widget+unit 测试
3. 文档：`docs/api-contracts/admin-api.md` 增补两端点；`AGENTS.md` 经验判据若产生新教训则更新
