# 设备平台注册流程优化

对设备录入和激活流程进行重构，对齐 blade 平台 `deviceId` 获取规范，将平台注册结果与设备激活状态绑定。

参考文档：`business-platform/hkt-blade-device-docking/docs/device-id-acquisition.md`

---

## 一、业务需求

### 1.1 添加设备

- 前端表单录入 **设备编号（deviceCode）、序列号（serialNo）、EUI（devEui）**。
- **serialNo 和 devEui 至少一个非空**；deviceCode 为必填（展示用编号）。
- 点击保存时，调用 blade 平台 **方式一**（`SN → license 查询 → registerDevice → deviceId`）。
- 平台注册 **成功** → 设备状态为 **已激活（ACTIVE）**，后续可绑定牲畜。
- 平台注册 **失败** → 设备状态为 **未激活（INVENTORY）**，不可绑定牲畜。

### 1.2 手动激活（注册到 blade 平台）

- 未激活的设备，前端提供"激活"操作入口。
- 激活 = **从 blade 平台获取 deviceId**：
  - 先用 EUI 反查（方式二）→ 查到直接绑定 platformDeviceId
  - 未查到再走注册（方式一）
- 激活成功 → platformDeviceId 已绑定，status = ACTIVE。
- 激活失败 → 抛错，设备保持 INVENTORY。

### 1.3 设备在线/离线状态（onlineStatus）

- 设备的 **在线/离线状态来自 blade 平台**，权威字段为 `pageDevices` 接口返回的 `onlineStatus`（`1` = 在线，其他 = 离线）。
- smart-livestock 本地映射：`onlineStatus == 1` → `runtimeStatus = "online"`；否则 → `"offline"`。`runtimeStatus` 只有这两个值，不再有 `"low_battery"`。
- 遥测同步服务定期同步 `onlineStatus` → `runtimeStatus`。
- `TelemetryIngestionService.computeRuntimeStatus()` 标记为 **deprecated**，不再本地推算在线状态（包括 low_battery），改为以 blade `onlineStatus` 为准。
- `activateOnPlatform()` 中 EUI 反查命中时，返回的 `DeviceDetailResp` 已含 `onlineStatus`，应顺带同步本地 `runtimeStatus`，无需等下一轮遥测轮询。
- 用户侧的"激活"操作 = 平台注册（获取 platformDeviceId），不是"设为在线"。

### 1.4 多环境 blade 平台地址

- blade 平台有 dev 和 test 两套环境，IP/端口不同。
- smart-livestock-server 通过 **环境变量** 配置 blade 平台地址，部署到 dev/test 时自动匹配。
- Dev 和 test 的 `.env` 文件各自维护对应的 blade 地址。

### 1.5 dev/test 环境一致性保障

- **代码层面**：同一套代码、同一套 Flyway 迁移文件，两个环境无差异。
- **数据层面**：不做环境特定的数据迁移（见第六章说明）。dev 环境的 HKT 系列设备已在运行时注册到 blade 平台，platform_device_id 已有值；test 环境的 TST 系列设备按用户要求不做数据迁移，可通过新的 activate 流程在运行时注册。
- **dev_eui 交叉风险**：test 环境的 TST-17/21/22 与 dev 环境的 HKT-11/21/22-01 共享相同的 dev_eui（`00956906000285d8` 等）。因此 **不能使用 dev_eui 匹配的 SQL UPDATE 做环境特定数据迁移**——会同时命中两个环境。

---

## 二、设备标识字段定义

设备有三个标识字段，语义不同，不可混用：

| 字段 | 含义 | 示例 | blade 用途 | 允许为空 |
|------|------|------|-----------|---------|
| `deviceCode` | 应用层编号（用户自定义展示用） | `TST-17` | 不使用 | ❌ 必填 |
| `serialNo`（**新增**） | 设备出厂序列号 | `TST-17` 或厂家编号 | license 查询参数 `deviceSn` | ✅ 可空 |
| `devEui` | LoRaWAN EUI（16字符 hex） | `00956906000285d8` | 注册标识符 `deviceIdentifier`；EUI 反查 `keyword` | ✅ 可空 |

**校验规则**：`serialNo` 和 `devEui` 至少一个非空，否则拒绝创建（`deviceCode` 一定非空）。

**标识符解析规则**（不互相回退）：

- **SN 解析**：`serialNo` 非空则用 `serialNo`；为空则无 SN，license 查询跳过。
- **EUI 解析**：`devEui` 非空则用 `devEui`；为空则从 license 返回值获取（`license.getDeviceEui()`）；license 也未返回则注册失败。

---

## 三、状态机语义

设备有两个独立的状态维度：

| 字段 | 类型 | 含义 | 来源 |
|------|------|------|------|
| `status` | 枚举（INVENTORY/ACTIVE/DECOMMISSIONED） | 设备**生命周期状态** | 本地状态机 |
| `runtimeStatus` | 字符串（online/offline） | 设备**运行时在线状态** | blade 平台 `onlineStatus` |
| `batteryLevel` | 整数（0-100） | 设备**电量百分比** | blade 平台遥测 `battery` |

**生命周期状态机**（`status` 字段）：

```
INVENTORY（未注册）  →  ACTIVE（已注册）  →  DECOMMISSIONED（已退役）
```

- **INVENTORY**：设备已录入本地，但未在 blade 平台注册（无 `platformDeviceId`），不可安装到牲畜。
- **ACTIVE**：设备已在 blade 平台注册（有 `platformDeviceId`），可安装到牲畜、接收遥测数据。
- **DECOMMISSIONED**：设备已退役。
- 从 INVENTORY 到 ACTIVE 的唯一途径是 **成功获取 blade `deviceId`**。

**运行时在线状态**（`runtimeStatus` 字段，**独立于 `status`**）：

| blade `onlineStatus` | `runtimeStatus` | 含义 |
|---|---|---|
| 1 | `online` | 设备在线 |
| 非 1 | `offline` | 设备离线 |

- 运行时状态由 blade 平台 `pageDevices` 接口返回的 `onlineStatus` 权威决定，**只有 `online` 和 `offline` 两个值**。
- **"低电量"不作为独立状态**，电量直接展示 blade 平台返回的原始百分比值（`batteryLevel` 字段），不做阈值派生。
- 设备可以在 `status = ACTIVE` 的同时 `runtimeStatus = offline`（已注册但暂时离线）。
- **去掉 `DeviceStatus.OFFLINE` 枚举值**——在线/离线统一用 `runtimeStatus` 表达，不再用 `status` 枚举表达。

---

## 四、接口变更

### 4.1 添加设备 `POST /api/v1/farms/{farmId}/devices`

**请求体**（新增 `serialNo` 字段 + 校验）：

```json
{
  "deviceCode": "TST-17",          // 必填，应用层编号
  "deviceType": "TRACKER",
  "serialNo": "TST-17",            // 新增，设备序列号，与 devEui 至少一个非空
  "devEui": "00956906000285d8"     // LoRaWAN EUI，与 serialNo 至少一个非空
}
```

**处理流程**：

```
1. 校验：deviceCode 非空；serialNo 和 devEui 至少一个非空 → 否则 400
2. 创建设备到本地 DB（status = INVENTORY）
3. 调用 doPlatformRegistration(device)
   ├─ 成功 → device.activate() → status = ACTIVE
   └─ 失败 → 记录 warn 日志，status 保持 INVENTORY
4. 返回 DeviceDto（含实际 status）
```

### 4.2 激活设备 `PUT /api/v1/farms/{farmId}/devices/{deviceId}/activate`

**处理流程**（重写）：

```
1. 查设备，校验存在
2. 已是 ACTIVE → 幂等返回（避免重复 activate 抛 STATE_CONFLICT）
3. 非 INVENTORY → 拒绝（DECOMMISSIONED 不可激活）
4. 无 platformDeviceId → 调用 activateOnPlatform(device) 获取 blade platformDeviceId
   有 platformDeviceId → 跳过平台注册
5. device.activate() → status = ACTIVE
6. 保存并返回
7. 步骤 4 失败 → 抛 ApiException，设备保持 INVENTORY
```

### 4.3 DevicePageReq 新增字段

`DevicePageReq.java` 新增 `keyword` 字段，支持 EUI 反查：

```java
private String keyword;  // 新增：用于 blade pageDevices 模糊搜索
```

### 4.4 Controller 新增校验

`DeviceController.registerDevice()` 增加参数校验，**使用 i18n key**：

```java
String deviceCode = (String) body.get("deviceCode");
String serialNo = (String) body.get("serialNo");
String devEui = (String) body.get("devEui");
if (deviceCode == null || deviceCode.isBlank()) {
    return ResponseEntity.badRequest()
            .body(ApiResponse.error(ErrorCode.VALIDATION_ERROR,
                    "error.deviceCodeRequired"));
}
if ((serialNo == null || serialNo.isBlank()) && (devEui == null || devEui.isBlank())) {
    return ResponseEntity.badRequest()
            .body(ApiResponse.error(ErrorCode.VALIDATION_ERROR,
                    "error.deviceSnOrEuiRequired"));
}
```

`OpenDeviceRegisterController.registerDevice()` 同理，同时修复现有硬编码中文 `"serialNo 不能为空"` → 改为 i18n key `error.deviceSnOrEuiRequired`。

---

## 五、核心代码变更

### 5.1 DeviceApplicationService

#### `registerDevice()` 修改

```java
@Transactional
public DeviceDto registerDevice(RegisterDeviceCommand command) {
    if (deviceRepository.findByDeviceCode(command.deviceCode()).isPresent()) {
        throw new ApiException(ErrorCode.DUPLICATE_RESOURCE,
                "error.deviceCodeDuplicate", new Object[]{command.deviceCode()});
    }
    Device device = new Device();
    device.setTenantId(command.tenantId());
    device.setDeviceCode(command.deviceCode());
    device.setSerialNo(command.serialNo());
    device.setDeviceType(command.deviceType());
    device.setDevEui(command.devEui());
    Device saved = deviceRepository.save(device);

    // 录入即注册：success → ACTIVE, failure → stay INVENTORY
    try {
        doPlatformRegistration(saved);
        saved.activate();
        saved = deviceRepository.save(saved);
    } catch (Exception e) {
        log.warn("Platform registration failed for device {}: {}", saved.getId(), e.getMessage());
    }
    return DeviceDto.from(saved);
}
```

#### 新增 `activateOnPlatform()`

```java
/**
 * 激活时获取 platformDeviceId：先反查（方式二），未命中再注册（方式一）。
 * 成功后 device.platformDeviceId 已设置。失败抛出 ApiException。
 */
private void activateOnPlatform(Device device) {
    String eui = device.getDevEui();

    // 方式二：EUI 反查（仅当 devEui 非空时）
    if (eui != null && !eui.isBlank()) {
        DevicePageReq pageReq = new DevicePageReq();
        pageReq.setKeyword(eui);
        pageReq.setCurrent(1);
        pageReq.setSize(1);
        try {
            InternalResponse<DevicePageResp> pageResp = platformDeviceClient.pageDevices(pageReq);
            if (pageResp != null && pageResp.isOk() && pageResp.getData() != null
                    && pageResp.getData().getTotal() != null && pageResp.getData().getTotal() > 0) {
                DeviceDetailResp record = pageResp.getData().getRecords().get(0);
                device.bindPlatformDeviceId(Long.parseLong(record.getDeviceId()));
                // Sync runtimeStatus from blade onlineStatus (1=online, otherwise offline)
                device.setRuntimeStatus(
                        record.getOnlineStatus() != null && record.getOnlineStatus() == 1
                                ? "online" : "offline");
                return;
            }
        } catch (Exception e) {
            log.debug("EUI reverse lookup failed for device {}: {}", device.getId(), e.getMessage());
        }
    }

    // 方式一：SN → license → register
    doPlatformRegistration(device);
    // 方式一成功后 registerDevice 响应不含 onlineStatus，初始化为 offline
    if (device.getRuntimeStatus() == null) {
        device.setRuntimeStatus("offline");
    }
}
```

#### `doPlatformRegistration()` 修改

```java
private void doPlatformRegistration(Device device) {
    String sn = device.getSerialNo();      // 用 serialNo 查 license（非 deviceCode）
    String eui = device.getDevEui();
    String platformTypeCode = PLATFORM_TYPE_CODES.getOrDefault(device.getDeviceType(), "CATTLE_TRACKER");

    // Step 1: License 校验（用 serialNo 查，有 SN 时执行）
    if (sn != null && !sn.isBlank()) {
        try {
            InternalResponse<LicenseStatusResp> licenseResp =
                    platformLicenseClient.getLicenseStatusBySn(sn);
            if (licenseResp != null && licenseResp.isOk() && licenseResp.getData() != null) {
                LicenseStatusResp license = licenseResp.getData();
                if (Boolean.FALSE.equals(license.getIsValid())) {
                    throw new ApiException(ErrorCode.AGENTIC_PLATFORM_LICENSE_INVALID,
                            "error.agenticPlatformLicenseInvalid", new Object[]{sn});
                }
                if (license.getDeviceTypeCode() != null && !license.getDeviceTypeCode().isBlank()) {
                    platformTypeCode = license.getDeviceTypeCode();
                }
                if (license.getDeviceEui() != null && !license.getDeviceEui().isBlank()) {
                    eui = license.getDeviceEui();
                }
            }
        } catch (ApiException e) {
            throw e;
        } catch (Exception e) {
            log.debug("License query failed for SN={}: {}", sn, e.getMessage());
        }
    }

    // EUI 必须有值才能注册
    if (eui == null || eui.isBlank()) {
        throw new ApiException(ErrorCode.AGENTIC_PLATFORM_REGISTRATION_FAILED,
                "error.agenticPlatformRegistrationFailed",
                new Object[]{"no devEui available for registration"});
    }

    // Step 2: 平台注册
    DeviceRegistrationReq req = new DeviceRegistrationReq();
    req.setDeviceIdentifier(eui);
    req.setDeviceTypeCode(platformTypeCode);
    String tenantIdStr = device.getTenantId() != null ? device.getTenantId().toString() : "000000";
    req.setUser(LoginUser.from("smart-livestock-server", tenantIdStr));

    InternalResponse<DeviceRegistrationResp> regResp;
    try {
        regResp = platformDeviceClient.registerDevice(req);
    } catch (Exception e) {
        throw new ApiException(ErrorCode.AGENTIC_PLATFORM_REGISTRATION_FAILED,
                "error.agenticPlatformRegistrationFailed", new Object[]{e.getMessage()});
    }

    if (regResp == null || !regResp.isOk() || regResp.getData() == null
            || regResp.getData().getDeviceId() == null) {
        throw new ApiException(ErrorCode.AGENTIC_PLATFORM_REGISTRATION_FAILED,
                "error.agenticPlatformRegistrationFailed", new Object[]{"no deviceId returned"});
    }

    // Step 3: 绑定
    Long platformDeviceId = Long.parseLong(regResp.getData().getDeviceId());
    device.bindPlatformDeviceId(platformDeviceId);
}
```

#### `activateDevice()` 重写

```java
@Transactional
public DeviceDto activateDevice(Long id) {
    Device device = deviceRepository.findById(id)
            .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                    "error.deviceNotFound", new Object[]{id}));

    // 已激活则幂等返回
    if (device.getStatus() == DeviceStatus.ACTIVE) {
        return DeviceDto.from(device);
    }
    // 非 INVENTORY 不可激活（DECOMMISSIONED 等）
    if (device.getStatus() != DeviceStatus.INVENTORY) {
        throw new ApiException(ErrorCode.STATE_CONFLICT, "iot.deviceActivateWrongStatus",
                new Object[]{device.getStatus()});
    }

    // 无 platformDeviceId → 先注册到 blade 平台
    if (device.getPlatformDeviceId() == null) {
        activateOnPlatform(device);
    }

    // 从 INVENTORY 转为 ACTIVE
    device.activate();
    Device saved = deviceRepository.save(device);
    return DeviceDto.from(saved);
}
```

#### `markOffline()` **删除**

去掉 `DeviceStatus.OFFLINE` 后，在线/离线由 `runtimeStatus` 表达，`Device.markOffline()` 和 `DeviceApplicationService.markOffline()` 不再需要，直接删除。

#### `registerWithPlatform()` 调整

```java
@Transactional
public DeviceDto registerWithPlatform(Long localDeviceId) {
    Device device = deviceRepository.findById(localDeviceId)
            .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                    "error.deviceNotFound", new Object[]{localDeviceId}));

    if (device.getPlatformDeviceId() != null) {
        return DeviceDto.from(device);
    }

    activateOnPlatform(device);
    if (device.getStatus() == DeviceStatus.INVENTORY) {
        device.activate();
    }
    Device saved = deviceRepository.save(device);
    return DeviceDto.from(saved);
}
```

### 5.2 Device 领域模型

**新增 `serialNo` 字段**：

```java
private String serialNo;
public String getSerialNo() { return serialNo; }
public void setSerialNo(String serialNo) { this.serialNo = serialNo; }
```

**删除 `markOffline()` 方法**。

**修改 `activate()` 状态机约束**：

```java
public void activate() {
    if (status != DeviceStatus.INVENTORY) {
        throw new ApiException(ErrorCode.STATE_CONFLICT,
            "Device must be in INVENTORY status to activate, current: " + status);
    }
    this.status = DeviceStatus.ACTIVE;
    registerEvent(new DeviceActivatedEvent(getId(), deviceCode));
}
```

**修改 `decommission()` 状态机约束**：

```java
public void decommission() {
    if (status != DeviceStatus.ACTIVE) {
        throw new ApiException(ErrorCode.STATE_CONFLICT,
            "Device must be in ACTIVE status to decommission, current: " + status);
    }
    this.status = DeviceStatus.DECOMMISSIONED;
}
```

### 5.2a DeviceStatus 枚举

```java
public enum DeviceStatus {
    INVENTORY,
    ACTIVE,
    // OFFLINE removed — runtime online/offline is expressed by runtimeStatus
    DECOMMISSIONED
}
```

### 5.3 DeviceJpaEntity — 修复 runtimeStatus 持久化（既有 bug）

**当前问题**：DB 列 `runtime_status` 存在（V20260709150000），但 `DeviceJpaEntity` 未声明此字段，`DeviceMapper` 不映射，导致 `runtimeStatus` **完全不持久化**——服务重启后所有设备 runtimeStatus 丢失（变为 null），前端全显示离线。

**修复**：

```java
@Column(name = "serial_no", length = 128)
private String serialNo;

@Column(name = "runtime_status", length = 30)
private String runtimeStatus;

// getter/setter
public String getSerialNo() { return serialNo; }
public void setSerialNo(String serialNo) { this.serialNo = serialNo; }
public String getRuntimeStatus() { return runtimeStatus; }
public void setRuntimeStatus(String runtimeStatus) { this.runtimeStatus = runtimeStatus; }
```

### 5.4 DeviceMapper — 补全字段映射

```java
// toJpaEntity() 新增：
jpa.setSerialNo(device.getSerialNo());
jpa.setRuntimeStatus(device.getRuntimeStatus());

// toDomain() 新增：
device.setSerialNo(jpa.getSerialNo());
device.setRuntimeStatus(jpa.getRuntimeStatus());
```

### 5.5 DevicePageReq

```java
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class DevicePageReq {
    private Integer current = 1;
    private Integer size = 20;
    private String deviceTypeCode;
    private String deviceName;
    private String keyword;       // 新增：用于 blade pageDevices 模糊搜索（传 EUI 精确匹配）
}
```

### 5.6 RegisterDeviceCommand

```java
public record RegisterDeviceCommand(
    String deviceCode,
    DeviceType deviceType,
    Long tenantId,
    String devEui,
    String serialNo  // 新增
) {}
```

### 5.7 DeviceDto

新增 `serialNo` 字段到响应中。

### 5.8 TelemetryIngestionService

- `computeRuntimeStatus()` 标记 `@Deprecated`，保留但不再由 `ingest()` 调用。
- `updateDeviceRuntimeStatus()` 中仅删除 `device.setRuntimeStatus(computeRuntimeStatus(...))` 行；其余遥测指标更新（rssi/snr/battery/gateway/antiDisassembly 等）保留不动。
- `runtimeStatus` 改由遥测同步服务的 blade `onlineStatus` 轮询写入。
- `ingest()` 的 `status == ACTIVE` 守卫不变；`AgenticPlatformTelemetrySyncJob` 的 `platformDeviceId == null → return` 守卫保证无平台注册的设备不会被遥测处理。

---

## 六、数据库变更

所有 Flyway 迁移对 dev 和 test 两个环境**无条件执行**（同一套代码）。不存在环境特定的数据迁移。

### 6.1 新增 serial_no 列 + 统一 runtime_status 长度

```sql
-- V20260715120000__add_device_serial_no.sql

-- 新增 serial_no 列（dev/test 两个环境都缺此列）
ALTER TABLE devices ADD COLUMN IF NOT EXISTS serial_no VARCHAR(128);

-- 统一 runtime_status 列长度为 VARCHAR(30)
-- 历史问题：dev 环境部署较早（7月9日），当时迁移文件定义为 VARCHAR(20)；
-- test 环境部署较晚（7月13日），迁移文件已改为 VARCHAR(30)。
-- Flyway 已执行过不会重跑，导致 dev 仍为 VARCHAR(20)，不一致。
ALTER TABLE devices ALTER COLUMN runtime_status TYPE VARCHAR(30);
```

> **dev/test 表结构一致性说明**：两个环境除 `runtime_status` 列长度（VARCHAR(20) vs VARCHAR(30)）外，其余表结构完全一致。此迁移统一为 VARCHAR(30)，消除历史差异。后续所有 Flyway 迁移对两个环境无条件执行，不再产生此类不一致。

### 6.2 去掉 OFFLINE 状态：数据迁移 + 约束修改

```sql
-- V20260715121000__remove_offline_status.sql

-- 1. 将现有 OFFLINE 设备迁移为 ACTIVE（运行时离线状态由 runtimeStatus 表达）
UPDATE devices SET status = 'ACTIVE' WHERE status = 'OFFLINE';

-- 2. 删除所有 status 相关 CHECK 约束（名称可能因 PG 版本不同而异）
DO $$
DECLARE
    con_name text;
BEGIN
    FOR con_name IN
        SELECT conname FROM pg_constraint
        WHERE conrelid = 'devices'::regclass AND contype = 'c'
          AND pg_get_constraintdef(oid) ILIKE '%status%'
    LOOP
        EXECUTE 'ALTER TABLE devices DROP CONSTRAINT IF EXISTS ' || con_name;
    END LOOP;
END $$;

-- 3. 重新创建约束（不含 OFFLINE）
ALTER TABLE devices ADD CONSTRAINT chk_devices_status
    CHECK (status IN ('INVENTORY', 'ACTIVE', 'DECOMMISSIONED'));
```

> **COUNT 影响**：`countActiveByTenant()` 查 `status = 'ACTIVE'`，OFFLINE→ACTIVE 迁移后计数会增大（dev 环境 4 台 OFFLINE 设备变为 ACTIVE）。这是预期行为——之前 OFFLINE 设备本就是已注册的可用设备，只是暂时离线。

### 6.3 清理 runtime_status 中的 low_battery 历史值

去掉 low_battery 后，后端 `runtimeStatus` 只有 `online` / `offline` 两个值。数据库中已有的 `low_battery` 值需要迁移。

```sql
-- V20260715122000__cleanup_low_battery_runtime_status.sql
-- 历史数据中 runtime_status='low_battery' 是本地推算的，blade 平台不返回此值。
-- 迁移为 'offline'（保守策略），下次遥测同步时由 blade onlineStatus 覆盖为真实值。
UPDATE devices SET runtime_status = 'offline' WHERE runtime_status = 'low_battery';
```

> **数据分布**（截至 2026-07-15）：
> - dev 环境：33 台 `low_battery` → 迁移为 `offline`
> - test 环境：全部为 NULL，不受影响
>
> 后端表结构本身无需修改——`runtime_status VARCHAR(30)` 和 `battery_level INTEGER` 列已存在，容量足够。

### 6.4 不做 platform_device_id 数据迁移

**决定不新增 platform_device_id 补全迁移**，原因：

- **dev 环境**：HKT-11/16/20/21/22-01 系列设备已在运行时通过 Open API 注册到 blade 平台，platform_device_id 已有值。DEV-GPS-001/002 由 V20260709130000 种子迁移设置。无需补全。
- **test 环境**：按用户要求不做数据迁移。TST-17/21/22 可通过新的 activate 流程在运行时注册。
- **dev_eui 交叉风险**：test 的 TST-17 与 dev 的 HKT-11-01 共享 dev_eui `00956906000285d8`，无法通过 dev_eui 匹配做环境特定迁移。

---

## 七、多环境配置

### 7.1 application.yml

`agentic-platform` 配置块已支持环境变量覆盖，无需改动：

```yaml
agentic-platform:
  device:
    base-url: ${AGENTIC_PLATFORM_DEVICE_BASE_URL:http://172.22.4.17:8100}
  license:
    base-url: ${AGENTIC_PLATFORM_LICENSE_BASE_URL:http://172.22.4.17:8100}
  oauth2:
    enabled: ${AGENTIC_PLATFORM_OAUTH2_ENABLED:false}
```

> **OAuth2 说明**：当前 blade feign 接口（`/feign/v1/...`）在内网裸露，无需认证，`oauth2.enabled` 保持 `false`。若 blade 后续增加网关认证，需在 `.env` 中设置 `AGENTIC_PLATFORM_OAUTH2_ENABLED=true` 及相关 client-id/secret 变量。

### 7.2 docker-compose.dev.yml / docker-compose.test.yml

在 `app` 服务的 `environment` 块中添加 blade 地址传递：

```yaml
app:
  environment:
    AGENTIC_PLATFORM_DEVICE_BASE_URL: ${AGENTIC_PLATFORM_DEVICE_BASE_URL:-http://172.22.4.17:8100}
    AGENTIC_PLATFORM_LICENSE_BASE_URL: ${AGENTIC_PLATFORM_LICENSE_BASE_URL:-http://172.22.4.17:8100}
```

> 使用 `:-默认值` 语法，即使 `.env` 文件未定义也不会报错。

---

## 八、影响范围

| 文件 | 变更类型 |
|------|----------|
| `DeviceApplicationService.java` | `registerDevice()` 加 serialNo + 绑定状态；`activateDevice()` 重写（幂等+前置检查）；新增 `activateOnPlatform()`；`doPlatformRegistration()` 用 serialNo 查 license；**删除 `markOffline()`** |
| `Device.java` | 新增 `serialNo` 字段；**删除 `markOffline()`**；修改 `activate()`/`decommission()` 状态约束（去掉 OFFLINE） |
| `DeviceStatus.java` | **删除 `OFFLINE` 枚举值** |
| `DeviceJpaEntity.java` | 新增 `serial_no` + **新增 `runtime_status` 映射（修复既有 bug）** |
| `DeviceMapper.java` | 补全 `serialNo` + `runtimeStatus` 双向映射 |
| `RegisterDeviceCommand.java` | 新增 `serialNo` 参数 |
| `DeviceDto.java` | 新增 `serialNo` 字段 |
| `DevicePageReq.java` | 新增 `keyword` 字段 |
| `DeviceController.java` | `registerDevice()` 加 serialNo 参数 + i18n 校验；`activateDevice()` 端点适配新返回值（删除多余 `getDevice()` 调用，直接用 service 返回的 DTO） |
| `OpenDeviceRegisterController.java` | `registerDevice()` 加 i18n 校验，修复硬编码中文 |
| `TelemetryIngestionService.java` | `computeRuntimeStatus()` 标记 deprecated，`ingest()` 不再调它（其他遥测指标更新保留不动） |
| `docs/api-contracts/app-api.md` | 更新设备 status 枚举值描述：去掉 `offline`，新增 `runtimeStatus` 字段说明 |
| `docs/api-contracts/admin-api.md` | 同步更新（如有设备 status 描述） |
| `docs/api-contracts/open-api.md` | 同步更新（如有设备 status 描述） |
| **前端** `devices_page.dart` | 修复 DeviceHealthDialog `_statusBadge`/`_statusColor` 死代码 bug（`d.status == 'ACTIVE'` 枚举 vs 字符串永假），统一用 `d.status == DeviceStatus.online` 判断 |
| **前端** `device_health_card.dart` | 修复同上死代码 bug（`devices_page.dart` 的复制副本） |
| **前端** `highfi_device_tile.dart` | 修复硬编码中文；删除 `lowBattery` switch 分支 |
| **前端** `devices_api_repository.dart` | `_parseDeviceItem` 去掉 `LOW_BATTERY` 映射 |
| **前端** `core_models.dart` | `DeviceStatus` 枚举去掉 `lowBattery`；`batteryLowCount` 调整 |
| **前端** `enum_labels.dart` | 删除 `lowBattery` 标签 |
| **前端** `livestock_detail_page.dart` | 删除 `lowBattery` switch 分支 |
| **前端** `devices_page.dart` | 低电量统计卡片调整（改为电量信息或删除） |
| `V20260715120000__add_device_serial_no.sql` | 新增：devices 表添加 serial_no 列 |
| `V20260715121000__remove_offline_status.sql` | 新增：OFFLINE 设备迁移为 ACTIVE + 更新 CHECK 约束 |
| `V20260715122000__cleanup_low_battery_runtime_status.sql` | 新增：low_battery 迁移为 offline（dev 33 台） |
| `docker-compose.dev.yml` / `docker-compose.test.yml` | app 服务增加 blade 地址环境变量 |
| `messages_zh.properties` / `messages_en.properties` / `messages.properties` | 修改 `iot.deviceActivateWrongStatus`/`iot.deviceDecommissionWrongStatus`（去掉 OFFLINE）；新增 `error.deviceCodeRequired`、`error.deviceSnOrEuiRequired` |
| `DeviceTest.java` | 删除 `markOffline` 测试用例；更新 `activate` 约束测试（仅 INVENTORY→ACTIVE）；更新 `decommission` 约束测试（仅 ACTIVE→DECOMMISSIONED） |
| `DeviceApplicationServiceTest.java` | 删除 `markOffline` 相关测试；更新 mock 适配 `activateOnPlatform()` 平台调用 |

### 不涉及的文件

- `DeviceActivatedEvent.java` — 事件不变
- `InstallationApplicationService` — 已校验 `device.status == ACTIVE`，无需改动
- `DeviceLicense` / `DeviceLicenseApplicationService` — 独立聚合，不变

---

### 5.9 前端既有 bug 修复（P2-5）

以下 bug 与本次改动无关，但 `runtimeStatus` 从本地推算改为 blade 同步后行为会变化，同步修复避免回归。

**Bug 1：DeviceHealthDialog 死代码**（`devices_page.dart` + `device_health_card.dart`）

当前代码用原始字符串比较判断在线状态，存在枚举 vs 字符串类型不匹配的死分支：

```dart
// devices_page.dart:809 (BUG — d.status 是 DeviceStatus 枚举，永 != 字符串 'ACTIVE')
final online = d.runtimeStatus?.toLowerCase() == 'online' || d.status == 'ACTIVE';

// devices_page.dart:850 (BUG — d.status.name 返回 'online'/'offline'/'lowBattery'，永 != 'active')
(d.runtimeStatus?.toLowerCase() == 'online' || d.status.name.toLowerCase() == 'active')
```

修复为统一用已解析的 `DeviceStatus` 枚举判断：

```dart
final online = d.status == DeviceStatus.online;
```

`device_health_card.dart` 是 `devices_page.dart` 中 DeviceHealthDialog 的复制副本，同样修复。

**Bug 2：highfi_device_tile.dart 硬编码中文 + 去掉 lowBattery 状态**

blade 的 `onlineStatus` 只有在线/离线，电量是独立的数据字段。`DeviceStatus` 枚举的 `lowBattery` 是本地推算的，去掉它，统一只有 `online` 和 `offline`。

**前端 `DeviceStatus` 枚举简化**（`core_models.dart`）：
```dart
// 当前
enum DeviceStatus { online, offline, lowBattery }

// 修改后
enum DeviceStatus { online, offline }
```

**解析逻辑简化**（`devices_api_repository.dart` 的 `_parseDeviceItem`）：
```dart
// 当前：含 LOW_BATTERY 映射
final status = switch (statusStr.toUpperCase()) {
  'ONLINE' => DeviceStatus.online,
  'OFFLINE' => DeviceStatus.offline,
  'LOW_BATTERY' => DeviceStatus.lowBattery,
  'ACTIVE' => DeviceStatus.online,
  _ => DeviceStatus.offline,
};

// 修改后：去掉 LOW_BATTERY
final status = switch (statusStr.toUpperCase()) {
  'ONLINE' => DeviceStatus.online,
  'OFFLINE' => DeviceStatus.offline,
  'ACTIVE' => DeviceStatus.online,
  _ => DeviceStatus.offline,
};
// batteryPercent 直接从后端字段取原始值，不做状态派生
```

**清理所有 lowBattery 引用**：
- `highfi_device_tile.dart:137,146`：删除 `DeviceStatus.lowBattery` switch 分支，电量直接展示 `_BatteryBar`
- `livestock_detail_page.dart:239`：删除 `DeviceStatus.lowBattery` switch 分支
- `devices_page.dart:589`：低电量统计改为展示电量信息或删除该统计卡片
- `enum_labels.dart:20`：删除 `DeviceStatus.lowBattery` 标签
- `core_models.dart:244`：`batteryLowCount` 字段移除或改为展示平均电量
- `device_info_line.dart`：已正确展示原始电量值（`'$batteryLevel%'`），无需改动

**i18n 修复**（highfi_device_tile.dart）：
```dart
// 修改后
DeviceStatus.online => device.status.localizedLabel(l10n),
DeviceStatus.offline => device.status.localizedLabel(l10n),
```

---

## 九、前端适配要点

1. **添加设备表单**：deviceCode（必填）、serialNo、devEui 三个输入框，serialNo 和 devEui 至少填一个。后端返回 `status` 字段，前端据此判断是否显示"激活"按钮和"未激活"标签。
2. **设备列表**：展示设备状态（已激活/未激活），未激活设备显示"激活"操作。
3. **绑定牲畜**：仅已激活设备可选。未激活设备在列表/选择器中灰显或标记。
4. **激活操作**：调 `PUT /{deviceId}/activate`，成功后刷新状态。失败显示后端返回的错误信息。
5. **在线/离线**：显示 `runtimeStatus` 字段（来自 blade 遥测同步），非用户操作。

---

## 十、验证方式

1. **有 serialNo 有 devEui**：录入 → blade 注册成功 → ACTIVE → 可绑定牲畜
2. **只有 serialNo**：录入 → 用 serialNo 查 license 获取 EUI → 注册 → ACTIVE
3. **只有 devEui**：录入 → serialNo 为空跳过 license → 用 devEui 直接注册 → ACTIVE
4. **serialNo 在 blade 无效**：录入 → license 校验失败 → INVENTORY → 前端提示 → 手动激活 → 再次失败
5. **设备已在 blade 注册（EUI 反查命中）**：录入 → 注册可能创建重复 → 手动激活 → EUI 反查命中 → 直接绑定 → ACTIVE
6. **已注册设备重复激活（幂等）**：已有 platformDeviceId 且 status=ACTIVE 的设备 → activate → 直接返回（幂等）
7. **DECOMMISSIONED 设备不可激活**：DECOMMISSIONED → activate → 报错 STATE_CONFLICT
8. **OFFLINE 状态迁移**：部署后原 OFFLINE 设备 → status=ACTIVE，runtimeStatus 由遥测同步决定
9. **runtimeStatus 持久化**：服务重启后设备 runtimeStatus 不丢失（既有 bug 修复验证）
10. **dev/test 环境切换**：修改 `.env` 中 blade 地址，重启后自动指向对应 blade 环境
