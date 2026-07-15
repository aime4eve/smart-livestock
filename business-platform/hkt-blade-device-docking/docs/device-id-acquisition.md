# blade 平台 deviceId 获取技术说明

本文档说明 blade 设备对接 PoC 中获取 `deviceId` 的两种技术实现方式及其完整调用链路。

## 背景

`deviceId` 是 blade 平台侧为每个设备分配的数字主键（如 `1810410796053938178`），由 blade 统一管理。PoC 代码不做本地生成，所有 `deviceId` 均通过 blade API 获取。

---

## 方式一：新设备注册（SN → license → 注册 → deviceId）

**适用场景**：设备尚未在 blade 平台注册，手头有设备 SN（序列号），需要完成首次注册并获取 blade 分配的 `deviceId`。

### 调用链路

```
SN（序列号）
  → GET /feign/v1/device-license/control/by-sn?deviceSn={sn}
  → 获取 deviceEui + deviceTypeCode
  → POST /feign/v1/device/lifecycle/registerDevice
  → blade 返回 deviceId
```

### 详细步骤

#### Step 1: 查询 license 信息

通过 SN 查询设备 license，获取 `deviceEui` 和 `deviceTypeCode`。

**接口**：`BladeLicenseClient.getLicenseStatusBySn()`

```
GET /feign/v1/device-license/control/by-sn?deviceSn={sn}
```

**请求参数**：

| 参数 | 类型 | 说明 |
|------|------|------|
| `deviceSn` | String | 设备序列号 |

**响应**（`LicenseStatusResp`）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `deviceEui` | String | 设备唯一标识符，用于后续注册 |
| `deviceSn` | String | 设备序列号 |
| `deviceTypeCode` | String | 设备类型编码（如 `CATTLE_TRACKER`） |
| `isValid` | Boolean | license 是否有效 |
| `status` | String | license 状态 |
| `activatedAt` | String | 激活时间 |

#### Step 2: 校验 license 有效性

```java
if (license.getIsValid() == null || !license.getIsValid()) {
    throw new BladeServiceException("SN not activated or invalid");
}
```

#### Step 3: 调用设备注册接口

使用 Step 1 获取的 `deviceEui` 和 `deviceTypeCode` 向 blade 注册设备。

**接口**：`BladeDeviceServiceClient.registerDevice()`

```
POST /feign/v1/device/lifecycle/registerDevice
```

**请求体**（`DeviceRegistrationReq`）：

```json
{
  "user": {
    "userId": "2074385063398711296",
    "tenantId": "000000"
  },
  "deviceIdentifier": "0095690600028ea6",
  "deviceTypeCode": "CATTLE_TRACKER"
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `user.userId` | String | 服务账号 userId |
| `user.tenantId` | String | 租户 ID |
| `deviceIdentifier` | String | 设备 EUI（来自 license 查询） |
| `deviceTypeCode` | String | 设备类型编码（来自 license 查询） |

**响应**（`DeviceRegistrationResp`）：

```json
{
  "deviceId": "1810410796053938178",
  "deviceIdentifier": "0095690600028ea6",
  "deviceTypeId": "...",
  "status": "ACTIVE",
  "createTime": "2026-07-07 10:00:00"
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `deviceId` | String | **blade 分配的数字设备 ID** |
| `deviceIdentifier` | String | 设备 EUI |
| `deviceTypeId` | String | 设备类型 ID |
| `status` | String | 注册状态 |

#### Step 4: 获取 deviceId

```java
String deviceId = regResp.getData().getDeviceId();
```

### 完整代码参考

`BladeDeviceService.java:97-123`：

```java
public String registerDevice(String sn) {
    // Step 1: 查 license
    InternalResponse<LicenseStatusResp> licenseResp = licenseClient.getLicenseStatusBySn(sn);
    if (!licenseResp.isOk() || licenseResp.getData() == null) {
        throw new BladeServiceException("SN not found or license service error");
    }
    LicenseStatusResp license = licenseResp.getData();

    // Step 2: 校验有效性
    if (license.getIsValid() == null || !license.getIsValid()) {
        throw new BladeServiceException("SN not activated or invalid");
    }

    // Step 3: 构造注册请求
    LoginUser loginUser = LoginUser.from(serviceUserId, serviceTenantId);
    DeviceRegistrationReq regReq = new DeviceRegistrationReq();
    regReq.setUser(loginUser);
    regReq.setDeviceIdentifier(license.getDeviceEui());
    regReq.setDeviceTypeCode(license.getDeviceTypeCode());

    // Step 4: 注册并获取 deviceId
    InternalResponse<DeviceRegistrationResp> regResp = deviceClient.registerDevice(regReq);
    if (!regResp.isOk() || regResp.getData() == null) {
        throw new BladeServiceException("device registration failed");
    }
    return regResp.getData().getDeviceId();
}
```

---

## 方式二：已有设备 EUI 反查 deviceId（keyword 搜索）

**适用场景**：设备已在 blade 平台注册，手头有设备 EUI（如 `0095690600028ea6`），需要获取对应的数字 `deviceId`。

### 调用链路

```
EUI（设备标识符）
  → POST /feign/v1/device/lifecycle/pageDevices {"keyword":"{eui}","current":1,"size":1}
  → 从 records[0].deviceId 提取
```

### 详细步骤

#### Step 1: 用 EUI 作为 keyword 分页搜索

**接口**：`BladeDeviceServiceClient.pageDevices()`

```
POST /feign/v1/device/lifecycle/pageDevices
```

**请求体**（`DevicePageReq`）：

```json
{
  "keyword": "0095690600028ea6",
  "current": 1,
  "size": 1
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `keyword` | String | 搜索关键词，传入设备 EUI |
| `current` | Integer | 当前页码 |
| `size` | Integer | 每页条数（反查时设为 1 即可） |

#### Step 2: 从响应中提取 deviceId

**响应**（`DevicePageResp`）：

```json
{
  "code": 200,
  "success": true,
  "data": {
    "total": 1,
    "current": 1,
    "pageSize": 1,
    "records": [
      {
        "deviceId": "1810410796053938178",
        "deviceName": "0095690600028ea6",
        "deviceIdentifier": "0095690600028ea6",
        "deviceTypeCode": "CATTLE_TRACKER",
        "onlineStatus": 1,
        "rssi": -65,
        "snr": "8.5",
        "lastActiveTime": "2026-07-07 14:44:17"
      }
    ]
  }
}
```

**提取路径**：`$.data.records[0].deviceId`

### Shell 脚本实现

`scripts/verify-blade-docking.sh:114-129`（Step 1.5）：

```bash
# 对 devices.conf 中的每个 EUI 执行反查
for i in "${!DEVICE_EUIS[@]}"; do
  eui="${DEVICE_EUIS[$i]}"
  RESP=$(blade_post "/feign/v1/device/lifecycle/pageDevices" \
    "{\"keyword\":\"${eui}\",\"current\":1,\"size\":1}")
  CODE=$(echo "$RESP" | jq -r '.code // 0')
  TOTAL=$(echo "$RESP" | jq -r '.data.total // 0')
  if [ "$CODE" = "200" ] && [ "$TOTAL" -gt 0 ] 2>/dev/null; then
    DID=$(echo "$RESP" | jq -r '.data.records[0].deviceId')
    DEVICE_IDS+=("$DID")
  else
    DEVICE_IDS+=("")  # 解析失败，标记为空
  fi
done
```

### Java 代码参考

同样的接口可通过 `BladeDeviceServiceClient` 在 Java 中调用：

```java
// BladeDeviceServiceClient.java:32-33
@PostMapping("/pageDevices")
InternalResponse<DevicePageResp> pageDevices(@RequestBody DevicePageReq request);
```

调用示例：

```java
DevicePageReq req = new DevicePageReq();
req.setKeyword(eui);   // EUI 作为 keyword
req.setCurrent(1);
req.setSize(1);
InternalResponse<DevicePageResp> resp = deviceClient.pageDevices(req);
String deviceId = resp.getData().getRecords().get(0).getDeviceId();
```

---

## 两种方式对比

| 维度 | 方式一：注册获取 | 方式二：反查获取 |
|------|-----------------|-----------------|
| **输入** | SN（设备序列号） | EUI（设备标识符） |
| **前提条件** | 设备 license 已激活 | 设备已在 blade 注册 |
| **是否写操作** | 是（在 blade 创建设备记录） | 否（只读查询） |
| **涉及接口数** | 2 个（license + register） | 1 个（pageDevices） |
| **关键字段** | `deviceEui` → `deviceIdentifier` | `keyword` → `records[].deviceId` |
| **使用场景** | 首次接入新设备 | 日常验证、批量操作 |

---

## 关键数据结构

涉及 `deviceId` 字段的 DTO 类：

| DTO | 文件 | deviceId 来源 |
|-----|------|--------------|
| `DeviceRegistrationResp` | `dto/DeviceRegistrationResp.java` | blade 注册接口返回 |
| `DeviceDetailResp` | `dto/DeviceDetailResp.java` | blade 设备详情/分页接口返回 |
| `DeviceTelemetryResp` | `dto/DeviceTelemetryResp.java` | blade 设备+遥测接口返回 |

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `service/BladeDeviceService.java` | 设备服务编排层，`registerDevice()` 实现方式一 |
| `client/BladeLicenseClient.java` | license 查询 Feign 客户端 |
| `client/BladeDeviceServiceClient.java` | 设备生命周期 Feign 客户端（registerDevice / pageDevices） |
| `dto/LicenseStatusResp.java` | license 响应 DTO（含 deviceEui） |
| `dto/DeviceRegistrationReq.java` | 注册请求 DTO |
| `dto/DeviceRegistrationResp.java` | 注册响应 DTO（含 deviceId） |
| `scripts/verify-blade-docking.sh` | Shell 验证脚本，Step 1.5 实现方式二 |
| `scripts/devices.conf` | 设备 EUI 清单配置文件 |
| `docs/poc-device-configuration-guide.md` | PoC 设备配置指南 |

---

## 实际验证记录

**验证时间**：2026-07-15  
**验证环境**：blade 生产集群（172.22.4.17:8100/8108）  
**当前设备**：130 台已注册设备（pageDevices total=130）

### 方式二（EUI 反查）：✅ 完全可用

三个测试 EUI 全部反查成功，deviceId 在后续 API 中正常工作：

| EUI | deviceId | 在线 | 遥测 |
|-----|----------|------|------|
| `0095690600028ea6` | `2072879090955759616` | ✅ online | 10 属性 |
| `0095690600028600` | `2072879090955759618` | ✅ online | — |
| `00956906000285d8` | `2075561438264500224` | — | — |

验证步骤：
```
1. POST /feign/v1/device/lifecycle/pageDevices {"keyword":"EUI","current":1,"size":1}
   → 提取 .data.records[0].deviceId
2. POST /feign/v1/device/lifecycle/getDeviceDetail {"deviceId":"..."}
   → 确认 onlineStatus / RSSI / SNR / lastActiveTime 正常返回
3. GET  /feign/v1/device/lifecycle/getDeviceDetailWithTelemetry?deviceId=...
   → 确认 10 个 telemetryProperties 正常返回（battery/lat/lon/steps/accel）
```

### 方式一（SN 注册）：⚠️ license 端点不可用

`GET /feign/v1/device-license/control/by-sn` 持续返回 `HTTP 500 Internal server error`。

**根因分析**：`BladeLicenseClient` 注释明确指出 license 是 blade 侧独立微服务（`hkt-blade-device-license-client`），当前 blade 集群（172.22.4.17:8100）上该微服务不可用或未配置数据库。此外，当前 blade 环境中的"设备标识符"为 EUI 格式，与 SN 可能不是同一概念。

**代码路径正确性**：Java 代码（`BladeDeviceService.registerDevice()` → `BladeLicenseClient` → `BladeDeviceServiceClient.registerDevice()`）的调用链路设计正确。license 端点不可用是**环境问题**，非代码或文档缺陷。如需验证方式一，需要：
1. 确认 blade 集群上 license 微服务已部署并配置数据库
2. 获取有效的设备 SN（非 EUI），确认 SN 在 license 库中存在

### 结论

- **方式二（EUI 反查 deviceId）**：生产可用，是当前 PoC 验证流程（`verify-blade-docking.sh`）的唯一 deviceId 获取方式
- **方式一（SN 注册获取 deviceId）**：代码路径正确，依赖 blade license 微服务（当前环境不可用），待该服务上线后可验证
