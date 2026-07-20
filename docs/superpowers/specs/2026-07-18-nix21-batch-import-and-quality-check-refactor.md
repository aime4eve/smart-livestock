# NIX-21 GPS 质量检验重构 + 批量导入 — 方案设计文档

| 字段 | 值 |
|---|---|
| 工单 | NIX-21 GPS质量检查增加批量导入设备的功能 |
| 优先级 | Urgent |
| 类型 | 架构重构 + 功能增强 |
| 前置依赖 | NIX-20 会话-检验模型（已实施，但本次将其废弃） |
| 设计日期 | 2026-07-18 |
| 状态 | 待评审 |
| 原型 | `docs/marketing/nix-21-batch-import-prototype.html` |

---

## 1. 问题分析

### 1.1 NIX-20 遗留问题

NIX-20 引入了「会话-检验」二层模型。实际使用中发现三层问题：

**模型问题：** 会话是多余的。`gps_logs` 天然以设备 + 时间标识数据，不需要人为定义「采集窗口」。1:N 模型极少被用到。

**代码问题：** 现有 `batch_create_session_dialog.dart` 已损坏。NIX-20 迁移后 `rtkPointId` 被后端静默丢弃，`createDynamicSession()` 调用不存在的端点。

**UI 问题：** 左-右分栏（会话列表→详情+检验列表）的复杂度远超需求。每条检验需要点击两层才能看到报告。

### 1.2 NIX-21 需求

1. 按 Excel 格式批量导入设备 GPS 检验数据
2. 导入数据在后端解析（不再前端解析 `excel` 包）
3. 支撑静态和动态两种检验的批量导入
4. 静态：按设备 + RTK 真值点 + 时间范围
5. 动态：按设备 + 路径 + 时间范围
6. 设备未在 blade 注册时自动尝试注册，失败时提供手动入口

### 1.3 核心设计决策（与确认记录）

| 决策 | 说明 |
|------|------|
| **EUI 为主标识** | 设备 EUI 是硬件身份证，GPS 质量检验的必填输入。设备编号（deviceCode）是其他业务（围栏、健康）的别名，在此场景为选填，不填则自动 `GPS-{EUI}` |
| **会话模型废弃** | 去掉 `gps_quality_sessions` 表，检验成为唯一实体 |
| **检验实时出报告** | 不预设复杂校验，查询 gps_logs 时有数据出报告，无数据显示「该时段无设备数据」 |
| **Blade 注册是必需前置** | 检验前设备必须完成 blade 注册才能取到 GPS 数据。批量导入中自动处理 |
| **同一 EUI 重复导入** | 不设 dev_eui 唯一约束。去重策略：同一租户内，同 (EUI + 检验时段) 组合只创建一条检验 |

---

## 2. 检验状态机

```
                ┌────────────────────┐
                │  EUI 传入           │
                └────────┬───────────┘
                         │
                   ┌─────▼──────┐
                   │  findOrCreateByEui() │
                   └─────┬──────┘
                         │
                    ┌────▼────┐
                    │  设备处理  │
                    └────┬────┘
                         │
            ┌────────────┼────────────┐
            ▼            ▼            ▼
       ┌─────────┐ ┌──────────┐ ┌────────┐
       │ ACTIVE  │ │ INVENTORY│ │ 失败    │
       └────┬────┘ └────┬─────┘ └───┬────┘
            │           │           │
       ┌────▼────┐ ┌───▼─────┐ ┌───▼────┐
       │  READY  │ │DEVICE_  │ │ FAILED │
       │         │ │PENDING  │ │        │
       └────┬────┘ └───┬─────┘ └───┬────┘
            │           │           │
            │     ┌─────▼─────┐    │
            │     │ 手动/批量  │    │
            │     │ blade 注册│    │
            │     └─────┬─────┘    │
            │           │          │
            │     ┌─────▼─────┐    │
            │     │成功→READY  │    │
            │     │失败→PENDING│    │
            │     └───────────┘    │
            │                      │
            └──────────┬───────────┘
                       ▼
                  ┌──────────┐
                  │ 查看报告   │
                  │ 有数据→报告 │
                  │ 无数据→提示 │
                  └──────────┘
```

**状态定义：**

| 状态 | 含义 | 能否出报告 | 用户操作 |
|------|------|-----------|---------|
| `READY` | 设备 ACTIVE，检验已就绪 | ✅ 可查 gps_logs 出报告 | 查看报告 |
| `DEVICE_PENDING` | blade 注册未完成 | ❌ 无法取 GPS 数据 | 批量注册 / 手动注册 / 删除 |
| `FAILED` | 创建失败（EUI 格式无效等） | ❌ 无设备 | 编辑并重试（修正后调用 retry-row）/ 删除 |

---

## 3. 数据库重构

### 3.1 当前 Schema（NIX-20 遗留）

```
gps_quality_sessions                      gps_quality_tests
├── id BIGSERIAL PK                       ├── id BIGSERIAL PK
├── device_id BIGINT FK → devices         ├── session_id BIGINT FK → sessions  ← 要删
├── started_at TIMESTAMPTZ                ├── test_type VARCHAR(10)
├── ended_at TIMESTAMPTZ                  ├── rtk_point_id BIGINT FK → rtk
├── status VARCHAR(20)                    ├── route_id BIGINT FK → routes
├── note TEXT                             ├── test_started_at TIMESTAMPTZ  ← 改名
├── created_at, updated_at                ├── test_ended_at TIMESTAMPTZ    ← 改名
                                          └── created_at, updated_at
```

另有 `rtk_calibration_sessions` 遗留旧表。

### 3.2 目标 Schema

```
gps_quality_tests（改造后）
├── id              BIGSERIAL PK
├── device_code     VARCHAR(100) NOT NULL       -- 用户填写/自动 "GPS-{EUI}"
├── device_id       BIGINT FK → devices(id)     -- 解析后的设备 ID
├── batch_import_id BIGINT                       -- 批量导入批次 ID（NULL = 手动创建）
├── test_type       VARCHAR(10) NOT NULL         -- STATIC / DYNAMIC
├── rtk_point_id    BIGINT FK → rtk_ref_points  -- 静态真值点
├── route_id        BIGINT FK → dyn_test_routes -- 动态路线
├── started_at      TIMESTAMPTZ NOT NULL         -- 检验时段起
├── ended_at        TIMESTAMPTZ                  -- 检验时段止
├── status          VARCHAR(20) DEFAULT 'READY'  -- READY / DEVICE_PENDING / FAILED
├── error_message   TEXT                         -- 失败原因
├── created_at, updated_at
```

### 3.3 迁移 SQL

```sql
ALTER TABLE gps_quality_tests ADD COLUMN device_code VARCHAR(100);
ALTER TABLE gps_quality_tests ADD COLUMN device_id BIGINT REFERENCES devices(id);
ALTER TABLE gps_quality_tests ADD COLUMN batch_import_id BIGINT;
ALTER TABLE gps_quality_tests ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'READY';
ALTER TABLE gps_quality_tests ADD COLUMN error_message TEXT;

UPDATE gps_quality_tests t SET device_code = d.device_code, device_id = s.device_id, status = 'READY'
FROM gps_quality_sessions s, devices d WHERE t.session_id = s.id AND s.device_id = d.id;

ALTER TABLE gps_quality_tests RENAME COLUMN test_started_at TO started_at;
ALTER TABLE gps_quality_tests RENAME COLUMN test_ended_at TO ended_at;
ALTER TABLE gps_quality_tests DROP CONSTRAINT IF EXISTS fk_gqt_session;
ALTER TABLE gps_quality_tests DROP COLUMN session_id;
DROP TABLE IF EXISTS gps_quality_sessions CASCADE;
DROP TABLE IF EXISTS rtk_calibration_sessions CASCADE;
ALTER TABLE gps_quality_tests ALTER COLUMN device_code SET NOT NULL;
CREATE INDEX idx_gqt_device_id ON gps_quality_tests(device_id);
CREATE INDEX idx_gqt_status ON gps_quality_tests(status);
CREATE INDEX idx_gqt_type ON gps_quality_tests(test_type);
```

**种子数据影响范围：** 无。唯一有种子数据的表是 `rtk_reference_points`（33 个点）——不受影响。

---

## 4. API 设计

### 4.1 新增端点：批量导入

```
POST /api/v1/admin/gps-quality/batch/import
Content-Type: multipart/form-data
Params: file: .xlsx

Response: {
  "code": "OK",
  "data": {
    "batchId": 1001,
    "totalRows": 8,
    "totalSuccess": 5,
    "totalPending": 2,
    "totalFailed": 1,
    "rows": [
      { "rowIndex": 0, "status": "SUCCESS", "eui": "847A...", "checkId": 201, "message": "..." },
      { "rowIndex": 3, "status": "DEVICE_PENDING", ... },
      { "rowIndex": 7, "status": "FAILED", ... }
    ]
  }
}
```

`status` 取值：`SUCCESS` | `DEVICE_PENDING` | `FAILED`

### 4.2 新增端点：下载模板

```
GET /api/v1/admin/gps-quality/batch/template
→ .xlsx 文件流，列：设备EUI | 设备编号(选填) | 检验类型 | 真值点/路径 | 开始时间 | 结束时间
```

### 4.3 改造端点：手动创建检验

```
POST /api/v1/admin/gps-quality/checks

Body: { "eui": "...", "deviceCode": "...", "checkType": "STATIC/DYNAMIC",
        "rtkPointId": ..., "routeId": ..., "startedAt": "...", "endedAt": "..." }
```

处理逻辑与批量导入单行相同。

### 4.4 改造端点：检验列表

```
GET /api/v1/admin/gps-quality/checks?status=xxx&eui=xxx&page=0&size=20
→ Spring Data Page 格式。扁平化列表，不再按会话分组。
```

### 4.5 改造端点：质量报告

```
GET /api/v1/admin/gps-quality/checks/{checkId}/report?excludeSuspect=false
```

当 `check.status != READY` 时返回设备状态说明。

### 4.6 保留端点（无需改动）


| 端点 | 说明 |
|------|------|
| `RTK 点 CRUD` (`/rtk-points`) | 与检验无关 |
| `动态路线 CRUD` (`/dynamic-routes`) | 与检验无关 |
| `设备列表` (`/devices`) | 与检验无关 |
| `动态报告` (`/checks/{id}/dynamic-report`) | 仅改查询链路（去掉 session 中转） |

---

### 4.7 新增端点：批量重试 blade 注册

```
POST /api/v1/admin/gps-quality/batch/retry-registration
Content-Type: application/json

Body:
{
  "checkIds": [104, 105]         // 选填，不传则重试所有 DEVICE_PENDING 的检验
}
```

**请求说明：**

| 字段 | 必填 | 说明 |
|------|------|------|
| `checkIds` | ❌ | 指定要重试的检验 ID 列表；不传则后端查询所有 status=DEVICE_PENDING 的检验 |

**处理逻辑：**

1. 查出所有目标检验的 deviceId
2. 调用 `DeviceApplicationService.registerWithPlatform(deviceId)` 逐条重试 blade 注册
3. 注册成功 → 设备 ACTIVE → 检验 status 更新为 READY
4. 注册失败 → 保持 DEVICE_PENDING，记录失败原因

**响应：**

```json
{
  "code": "OK",
  "data": {
    "total": 2,
    "succeeded": 1,
    "failed": 1,
    "results": [
      {
        "checkId": 104,
        "eui": "F1C2000000D88",
        "deviceCode": "DEV-GPS-004",
        "status": "SUCCESS",
        "message": "设备 ACTIVE，检验已就绪"
      },
      {
        "checkId": 105,
        "eui": "9A3300000BEE",
        "deviceCode": "GPS-9A3300000BEE",
        "status": "FAILED",
        "message": "Blade 注册失败：平台拒绝，EUI 无对应 license"
      }
    ]
  }
}
```

**前端对应：** 批量导入结果面板中的「📡 批量注册 blade」按钮调用此端点。同时支持逐条「手动注册」调用同一端点（传单个 checkId）。

---

### 4.8 新增端点：编辑失败数据并重试

```
POST /api/v1/admin/gps-quality/batch/retry-row
Content-Type: application/json

Body: {
  "eui": "847A000000000F03",       // 修正后的 EUI（必填）
  "deviceCode": "DEV-GPS-001",    // 选填
  "checkType": "STATIC",          // STATIC / DYNAMIC
  "rtkPointId": 5,                // 静态时必填
  "routeId": null,                // 动态时必填
  "startedAt": "2026-07-18T09:00:00Z",
  "endedAt": "2026-07-18T10:00:00Z"
}
```

**说明：** 对批量导入中 FAILED 的检验行，用户修正数据后调用此端点重试。处理逻辑与单条创建（§4.3 `POST /checks`）完全一致：EUI → 查库 → 创建设备 → blade 注册 → 创建检验。成功后检验列表自动更新，原失败行从列表中移除。

**前端对应：** 批量导入结果面板中的「❌ 导入失败的数据」区域，每条提供「编辑并重试」和「删除」两个操作。「编辑并重试」打开编辑对话框修改 EUI 后调此端点。

---

### 4.9 新增端点：删除批次

```
DELETE /api/v1/admin/gps-quality/batch/{batchId}
```

删除指定批次的全部检验记录。删除范围：仅删除 `gps_quality_tests` 中 `batch_import_id = {batchId}` 的行，不删除关联设备（设备可能被其他功能使用）。

**响应：**

```json
{
  "code": "OK",
  "data": {
    "deletedCount": 6
  }
}
```

**前端对应：** 批量导入后顶部横幅的「🗑 删除本次」按钮调此端点。

**手动创建的单条检验：** 不生成 `batch_import_id`，无批次追踪。用户可在左侧列表中直接定位新创建的行，通过详情面板的「删除此条」单独删除。

---


---

## 5. 设备处理逻辑（核心）

### 5.1 `findByDevEui()` 新增

**现状：** `DeviceRepository` 没有按 EUI 查询的方法。

**需补：**

| 层 | 文件 | 改动 |
|----|------|------|
| 接口 | `DeviceRepository.java` | 声明 `Optional<Device> findByDevEui(String devEui)` |
| Spring Data | `SpringDataDeviceRepository.java` | 加方法（JPA 按方法名推导 `WHERE dev_eui = ?1`） |
| 实现 | `JpaDeviceRepositoryImpl.java` | 委托 `springDataRepo.findByDevEui(eui).map(DeviceMapper::toDomain)` |

### 5.2 `findOrCreateByEui()` 新增

在 `DeviceApplicationService` 中新增轻量方法，专供 GPS 质量检验使用：

```java
/**
 * Find or create a device by EUI.
 *
 * <p>Unlike {@link #registerDevice(RegisterDeviceCommand)}, this method does
 * NOT require deviceCode to be unique upfront — if not provided, it auto-generates
 * "GPS-{eui}". Still attempts blade registration via activateOnPlatform().
 *
 * @param eui         hardware identifier (required, min 4 chars)
 * @param deviceCode  business alias (optional, auto-gen if null)
 * @param tenantId    tenant context
 * @return DeviceDto with status ACTIVE (registered) or INVENTORY (failed)
 * @throws ApiException if EUI format is invalid
 */
@Transactional
public DeviceDto findOrCreateByEui(String eui, String deviceCode, Long tenantId) {
    // 0. Tenant-scoped lookup (not global)
    Optional<Device> existing = deviceRepository.findByDevEuiAndTenantId(eui, tenantId);
    // 1. Validate EUI
    if (eui == null || eui.isBlank() || eui.length() < 4) {
        throw new ApiException(ErrorCode.VALIDATION_ERROR,
            "error.invalidEuiFormat", new Object[]{eui});
    }

    // 2. Lookup by EUI (tenant-scoped)
    Optional<Device> existing = deviceRepository.findByDevEuiAndTenantId(eui, tenantId);
    if (existing.isPresent()) {
        Device device = existing.get();
        // Retry blade registration if still INVENTORY
        if (device.getStatus() == DeviceStatus.INVENTORY) {
            try {
                activateOnPlatform(device);
                device.activate();
                deviceRepository.save(device);
            } catch (Exception e) {
                log.warn("Blade re-registration failed for EUI {}: {}", eui, e.getMessage());
            }
        }
        return DeviceDto.from(device);
    }

    // 3. Create new device
    String resolvedCode = (deviceCode != null && !deviceCode.isBlank())
        ? deviceCode : "GPS-" + eui;

    Device device = new Device();
    device.setDevEui(eui);
    device.setDeviceCode(resolvedCode);
    device.setSerialNo(eui);
    device.setDeviceType(DeviceType.TRACKER);
    device.setTenantId(tenantId);
    // status = INVENTORY (from constructor)
    Device saved = deviceRepository.save(device);

    // 4. Attempt blade registration
    try {
        activateOnPlatform(saved);
        saved.activate();
        saved = deviceRepository.save(saved);
    } catch (Exception e) {
        log.warn("Blade registration failed for EUI {}: {}", eui, e.getMessage());
    }

    return DeviceDto.from(saved);
}
```

### 5.3 设备状态 → 检验状态映射

| `Device.status` | `QualityCheck.status` | 说明 |
|-----------------|----------------------|------|
| ACTIVE | READY | 可取 GPS 数据，可出报告 |
| INVENTORY | DEVICE_PENDING | 未注册到 blade，无法取数据 |
| （设备创建失败） | FAILED | EUI 格式无效等 |

---

## 6. 对现有功能的影响

### 6.1 质量报告

**当前链路：** `test → session.getDeviceId() → gpsLogs`（2 次 DB 查询）

**重构后链路：** `check.getDeviceId() → gpsLogs`（1 次 DB 查询）

无需 SQL JOIN。`ComparisonResult` 中原 `session.getDeviceId()` 直接改为 `test.getDeviceId()`（列已拉平）。

### 6.2 质量对比

**当前：** `testRepository.findByRtkPointId()` → for each test: `sessionRepository.findById()`（N+1 隐患）

**重构后：** `checkRepository.findByRtkPointId()` → 直接 `check.getDeviceId()`，无 N+1。

### 6.3 动态报告

同质量报告，去掉 session 中转。

### 6.4 前端页面

**当前结构（NIX-20）：**

```
GPS 质量检查页面
├── 会话
├── 真值参照
├── 质量对比
└── 质量报告
    ├── [左] 会话列表
    │   ├── 会话1（含检验标签: 静×2, 动×1）
    │   ├── 会话2（含检验标签: 静×3）
    │   └── ...
    └── [右] 选中会话详情
        ├── 会话信息 + 时间轴
        ├── 检验列表（选中其中一条）
        └── 报告（散点图 + 统计）
```

**重构后：**

```
GPS 质量检查页面
├── 质量检验（按设备分组，每条设备在左侧显示一次）
├── 真值参照（不变）
├── 质量对比（不变）
    ├── [左] 设备列表（按 EUI 分组）
    │   ├── 提示条：「左侧按设备分组，点击查看时间轴」
    │   ├── 搜索/过滤条件（EUI 关键字 + 状态下拉），过滤后选中设备若不符条件则自动清除选中
    │   ├── [📡 批量注册] 按钮（当任何设备中存在 DEVICE_PENDING 时出现，一键重试所有）
    │   └── 设备行（EUI + 设备编号 | 检验总数 + 静态/动态计数 | 整体状态标签）
    └── [右] 选中设备视图
        ├── 设备概览
        │   ├── 设备标识（EUI + 设备编号）
        │   ├── 统计（总检验数 · 时间跨度 · 整体质量分档）
        │   └── 全部就绪 / ⚠️待注册 / ❌失败 状态标签
        ├── 时间轴（视觉比例色块条）
        │   ├── 每个检验为一个色块，宽度与检验时段时长成正比
        │   ├── 静态=蓝色 #DBEAFE，动态=琥珀色 #FEF3C7
        │   ├── 当前选中的检验有绿色边框（2px var(--primary)），其他半透明
        │   ├── 点击任意色块切换当前检验
        │   └── 底部时间轴标签（起始时间 → 结束时间）
        ├── 当前检验报告
        │   ├── 静态检验：有效点数 | P95 | P50 | 平均误差 | 抖动直径 | 15m占比 + 散点图
        │   ├── 动态检验：路线覆盖 | 匹配/总点 | 遗漏点 | 歧义点 | 顺序正确 + 路线匹配图
        │   └── 报告随时间轴点击即时切换
        ├── DEVICE_PENDING: 红色警告 + 手动注册按钮 + 删除按钮
        └── FAILED: 错误信息 + 编辑并重试按钮（打开编辑对话框修正 EUI 后调 retry-row 端点）+ 删除按钮

**新增 UI 元素：**新增 UI 元素：** 搜索/过滤条、检验列表每行显示状态 + 质量等级、DEVICE_PENDING 状态下显示批量注册/手动注册按钮；FAILED 状态下显示编辑并重试按钮（打开编辑对话框修正 EUI 后调 retry-row 端点）。

**「创建检验」手动入口：** 点击左上角「+ 创建」按钮 → 弹窗（输入 EUI/deviceCode/类型/真值/时间）→ 后端处理（同批量导入逻辑一致）。

---

## 7. 批量导入 Service 设计

### 7.1 `GpsQualityBatchImportService.java`

```java
@Service
@RequiredArgsConstructor
public class GpsQualityBatchImportService {

    private final DeviceApplicationService deviceService;
    private final GpsQualityCheckRepository checkRepository;
    // Apache POI for Excel parsing

    @Transactional
    public BatchImportResult importFromExcel(MultipartFile file) {
        // 1. Parse Excel with Apache POI
        List<ImportRow> rows = parseExcel(file);

        // 2. Process each row
        List<RowResult> results = new ArrayList<>();
        // Dedup set: track (eui + timeWindow) within this batch
        Set<String> seenInBatch = new HashSet<>();
        for (int i = 0; i < rows.size(); i++) {
            ImportRow row = rows.get(i);
            // Dedup: skip if same (eui, startedAt) already seen in this batch
            String dedupKey = row.eui() + "|" + row.startedAt();
            if (!seenInBatch.add(dedupKey)) {
                results.add(RowResult.skipped(i, "本批已有相同 EUI+时段，跳过重复"));
                continue;
            }
            // Dedup: skip if existing check with same (eui, startedAt, testType) found
            if (checkRepository.existsByEuiAndTimeRange(row.eui(), row.startedAt(), row.checkType())) {
                results.add(RowResult.skipped(i, "历史已有相同检验，跳过重复"));
                continue;
            }
            try {
                // a. Find or create device (tenant-scoped)
                DeviceDto device = deviceService.findOrCreateByEui(
                    row.eui(), row.deviceCode(), tenantContext.getCurrentTenant());

                // b. Resolve truth reference
                Long refId = resolveTruthReference(row);

                // c. Create quality check
                GpsQualityCheck check = createCheck(device, row, refId);

                // d. Determine status
                CheckStatus status = device.status() == DeviceStatus.ACTIVE
                    ? CheckStatus.READY : CheckStatus.DEVICE_PENDING;

                results.add(RowResult.success(i, device, check, status));
            } catch (Exception e) {
                results.add(RowResult.failed(i, e.getMessage()));
            }
        }

        return new BatchImportResult(rows.size(), results);
    }
}
```

### 7.2 Apache POI 解析

```java
private List<ImportRow> parseExcel(MultipartFile file) {
    try (Workbook wb = new XSSFWorkbook(file.getInputStream())) {
        Sheet sheet = wb.getSheetAt(0);
        List<ImportRow> rows = new ArrayList<>();
        for (int i = 1; i <= sheet.getLastRowNum(); i++) {  // skip header
            Row r = sheet.getRow(i);
            if (r == null) continue;
            rows.add(new ImportRow(
                getCellString(r, 0),  // EUI
                getCellString(r, 1),  // deviceCode
                getCellString(r, 2),  // checkType
                getCellString(r, 3),  // truthRef
                getCellLocalDateTime(r, 4),  // startedAt
                getCellLocalDateTime(r, 5)   // endedAt
            ));
        }
        return rows;
    }
}
```

### 7.3 真值基准解析

```java
private Long resolveTruthReference(ImportRow row, Long checkTypeId) {
    if ("STATIC".equals(row.checkType())) {
        return rtkPointRepository.findByPointLabel(row.truthRef())
            .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                "RTK point not found: " + row.truthRef()))
            .getId();
    } else {
        return dynamicTestRouteRepository.findByName(row.truthRef())
            .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                "Route not found: " + row.truthRef()))
            .getId();
    }
}
```

---

## 8. 前端改动清单

| 文件 | 改动 |
|------|------|
| `api_client.dart` | 新增 `uploadFile()` 方法（`MultipartRequest`，设置 `Authorization` header） |
| `gps_quality_api_repository.dart` | 新增 `batchImport()`, `downloadBatchTemplate()`, `createCheck()`, `fetchChecks()`；删除 `createSession()`, `createDynamicSession()`, `createTest()` |
| `gps_quality_providers.dart` | 新增 `checksProvider`（替代 `gpsSessionsProvider` + `sessionTestsProvider`）；删除 `calibrationSessionsProvider` |
| `gps_quality_models.dart` | 新增 `QualityCheck` 模型（替代 `GpsQualitySession` + `CalibrationSession`）；新增 `CheckStatus` 枚举 |
| `gps_quality_page.dart` | 修改 tab 标签"会话-检验"→"质量检验"；顶部工具栏增加 [📡 批量注册] 按钮（条件显示，仅 checks 中有 DEVICE_PENDING 时可见）；新增批量导入后置横幅（含 batchId 追踪 + 查看/删除/忽略） |
| `session_test_tab.dart` | 重写为 `quality_check_list.dart`：**左侧按设备分组列表** + 搜索过滤 + 右侧面板（设备概览 + 视觉时间轴色块条 + 当前检验报告）。时间轴色块按时长比例分配宽度，蓝色=静态检验，琥珀色=动态检验，点击切换查看报告。详情面板三种状态：READY（报告）/ DEVICE_PENDING（手动注册）/ FAILED（编辑并重试+删除） |
| `batch_create_session_dialog.dart` | 重写为 `batch_import_dialog.dart`：上传 Excel → 后端解析 → 预览 → 提交 |
| （新文件） | `create_check_dialog.dart`：手动创建单条检验弹窗（EUI 必填 + deviceCode 选填 + 检验类型切换 + 真值选择 + 时间范围） |
| （新文件） | `edit_retry_dialog.dart`：编辑失败数据并重试弹窗（从 FAILED 详情面板 / 批量导入失败列表两种入口打开，修正 EUI 后调 retry-row 端点） |
| （新文件） | `core/widgets/date_time_input_field.dart`：统一日期时间输入控件（替代 `_CompactTimeField` + `_DateTimeRow`，支持直接键盘输入 + 📅 Picker 兜底 + 校验反馈 + 自动格式化） |
| `comparison_tab.dart` | 适配新模型 |
| `dynamic_report_tab.dart` | 适配新模型 |
| `app_zh.arb` + `app_en.arb` | 补充新翻译键 |
| 删除 `batch_create_session_dialog.dart` | 由 `batch_import_dialog.dart` 替代 |
| 删除 `rtk_calibration_tab.dart` | 保留但改名 |

---

## 9. 错误处理

| 场景 | 行状态 | 行为 | 用户操作 |
|------|--------|------|---------|
| EUI 为空或格式不合法 | FAILED | 不创建设备，不创建检验 | 编辑并重试（修正 EUI）/ 删除该行 |
| 本地 EUI 已存在(ACTIVE) | SUCCESS | 复用 deviceId，创建检验 ✅ | 无感 |
| 本地 EUI 已存在(INVENTORY) | SUCCESS/DEVICE_PENDING | 重试 blade 注册，成功→READY，失败→PENDING | 批量注册 / 手动注册 |
| 新 EUI + blade 注册成功 | SUCCESS | 创建 ACTIVE 设备 + READY 检验 | 无感 |
| 新 EUI + blade 注册失败 | DEVICE_PENDING | 创建 INVENTORY 设备，检验待注册 | 批量注册 / 手动注册 / 删除 |
| 真值点/路径名称查不到 | FAILED | 不创建检验 | 检查 Excel 后重试 |
| 时间格式解析失败 | FAILED | 不创建检验 | 检查 Excel 后重试 |
| Apache POI 文件解析失败 | — | 整体返回错误，0 条创建 | 检查文件格式后重试 |
| FAILED 行编辑并重试 | SUCCESS/FAILED | 调用 retry-row 端点重新处理，通过则创建检验，失败则提示原因 | 自动：失败行移除 / 重试后仍失败则显示新错误 |

---

## 10. 实现计划（8 Tasks）

### Task 1: 数据库迁移
- 新建 Flyway 迁移
- `gps_quality_tests` 加列 + 回填 + 改名
- 删 `gps_quality_sessions` + 删 `rtk_calibration_sessions`

### Task 2: 后端基础设施
- `DeviceRepository` / `SpringDataDeviceRepository` / `JpaDeviceRepositoryImpl` 加 `findByDevEui()`
- `DeviceApplicationService` 加 `findOrCreateByEui()`
- `GpsQualityTest` 领域模型 + JPA 实体改造（去 sessionId，加 deviceCode/deviceId/status/errorMessage）
- 新建 `GpsQualityCheckRepository`
- 新建 `GpsQualityCheck` 领域模型（或复用 `GpsQualityTest` 改名）

### Task 3: 批量导入
- `BatchImportResultDto.java`
- `GpsQualityBatchImportService.java`（Apache POI 解析 + `findOrCreateByEui` + 创建 check）
- 控制器：`POST /batch/import`, `GET /batch/template`

### Task 4: 手动创建 + 列表 + 报告/对比改造
- 控制器：`POST /checks`, `GET /checks`
- `GpsQualityReportService` 改造
- `DynamicQualityReportService` 改造

### Task 5: 前端 API 层
- `ApiClient.uploadFile()`
- `GpsQualityApiRepository` 更新

### Task 6: 前端 UI — 控件统一化
- 新建 `core/widgets/date_time_input_field.dart`（`DateTimeInputField` 组件）
- 替换 `batch_create_session_dialog.dart` 中的 `_CompactTimeField`
- 替换 `session_test_tab.dart` 中的 `_DateTimeRow`
- 删除两处内联日期控件代码
- l10n 补充翻译键

### Task 6b: 前端 UI — 页面重构
- 重构页面为扁平检验列表
- 批量导入对话框
- 手动创建弹窗
- 状态相关 UI（DEVICE_PENDING 提示、手动注册按钮）

### Task 7: 测试
- `GpsQualityBatchImportServiceTest`（Excel 解析 + 设备处理）
- `GpsQualityJourneyTest` 扩展（批量导入 API）
- `DeviceApplicationService` 新增方法测试

---

## 11. 参考

- 原型：`docs/marketing/nix-21-batch-import-prototype.html`
- NIX-20 设计：`docs/superpowers/specs/2026-07-17-nix20-session-test-model-redesign.md`
- 设备注册：`DeviceApplicationService.java`
- 现有批量对话框：`batch_create_session_dialog.dart`
- 会话-检验模型原型：`docs/marketing/nix20-session-test-model-prototype.html`
