# Phase C：hkt-blade-device 对接设计（整合版）

**Date**: 2026-07-07
**Status**: PoC 已验证（单元测试 18/18 + 真实联通性 13/13 全绿）
**整合自**:
- `2026-07-03-phase-c-blade-device-integration-design.md`（方案 A：纯 HttpClient 主设计）
- `2026-07-04-phase-c-feign-url-approach.md`（方案 B：Feign + url 直连）
- `2026-07-04-phase-c-option-c-nacos-work-items.md`（方案 C：Feign + Nacos）

---

## 0. 关键约束（必读）

**hkt-blade-device 是第三方系统，不可修改其代码。**

smart-livestock 侧只作为 blade Feign 端点的**消费方**，不要求 blade 新增任何代码。方案 B（Feign + url 直连）已被 PoC 验证可行。

---

## 1. 背景与目标

### 1.1 blade 真实环境与服务拓扑

2026-07-07 实测验证。blade 服务通过 Nacos 注册中心管理，开发机通过端口映射访问。

**Nacos 注册中心：**

| 属性 | 值 |
|------|-----|
| 地址 | `172.22.3.16:8848` |
| namespace | `c47123d9-9d2b-4fdf-a61a-8d5daa9c89ac` |
| 用户名 | `nacos` |
| 密码 | `16c47768b93458d3!QA` |

**blade 服务实例（开发机可达地址 vs Nacos 内网注册地址）：**

| 服务 | 开发机可达地址 | Nacos 注册地址 | 端口 | 用途 |
|------|---------------|---------------|------|------|
| hkt-blade-auth | `172.22.4.17:8108` | `172.21.2.41:8108` | 8108 | OAuth2 认证换票 |
| hkt-blade-device | `172.22.4.17:8100` | `172.21.2.41:8100` | 8100 | 设备 + 遥测 + 历史数据 |
| hkt-blade-system | `172.22.4.17:8106` | `172.21.2.41:8106` | 8106 | 用户管理（feign 端点无需 token） |
| hkt-blade-gateway | `172.22.4.16:80` | `172.21.2.41:*` | 80 | nginx 网关入口 |
| hkt-blade-device-license-client | **未注册** | — | — | License 服务（当前无实例） |

> Nacos 还注册了 12 个 blade 微服务：hkt-blade-file, hkt-blade-system, hkt-building-management-service, automation-strategy, open-api-service, hkt-blade-auth, hkt-blade-gateway, hkt-blade-device-license-client, message-center, hkt-blade-device, hkt-blade-space-resource, hkt-blade-gdpr。

### 1.2 目标

| 目标 | 状态 | 说明 |
|------|------|------|
| OAuth2 换票 | ✅ 已验证 | `hkt_openapi` + `openapi` grant，12h token |
| 服务账号创建 | ✅ 已验证 | 通过 blade-system feign 端点自建用户 |
| 设备列表 | ✅ 已验证 | 120 台 CATTLE_TRACKER 设备 |
| 设备详情 + 遥测 | ✅ 已验证 | 10 个 telemetry properties（含三轴加速度） |
| 最新遥测 | ✅ 已验证 | battery/latitude/longitude/stepNumber |
| 上行历史记录 | ✅ 已验证 | report-record/page，324+ 条（持续增长） |
| 设备物模型 | ✅ 已验证 | 19 个属性定义（含三轴加速度） |
| License 查询 | ⏳ 待验证 | License 服务未注册 |
| 设备注册 | ✅ 已验证 | registerDevice + batchRegisterDevices + removeDevice + updateDeviceInfo |

---

## 2. 接口总览

| # | 方向 | 接口 | 状态 |
|---|------|------|------|
| ② | smart-livestock → blade | `GET /feign/v1/device-license/control/by-sn` | ⏳ License 服务未注册 |
| ③a | smart-livestock → blade | `POST /feign/v1/device/lifecycle/registerDevice` | ✅ 已验证（含批量/删除/更新） |
| ③b | smart-livestock → blade | `POST /feign/v1/device/lifecycle/pageDevices` | ✅ 120 台 |
| ③c | smart-livestock → blade | `GET /feign/v1/device/lifecycle/getDeviceDetailWithTelemetry` | ✅ 含遥测 |
| ④a | smart-livestock → blade | `GET /device/report-record/page` | ✅ **推荐时序数据源** |
| ④b | smart-livestock → blade | `POST /feign/v1/device/telemetry/history/latest` | ✅ 最新快照 |
| ④c | smart-livestock → blade | `POST /feign/v1/device/telemetry/history/query` | ✅ 端点正常（数据为空） |

> Webhook 推送（接口①）因 blade 不可改代码而作废。替代方案为 smart-livestock 主动轮询 `report-record/page`（详见 §6）。

---

## 3. blade 端点契约（实测验证）

### 3.1 通用约定

- **认证头**: `token: {access_token}`（blade 约定，无 Bearer 前缀）
- **租户头**: `Tenant-Id: 000000`（所有请求必须携带）
- **响应包络** `InternalResponse<T>`:

```json
{ "code": 200, "success": true, "data": {...}, "msg": "Operation successful" }
```

> blade 用 HTTP 200 包装业务状态码（如 401 业务错误也返回 HTTP 200）。`isOk()` = `success && (code == 200 || code == 0)`。

### 3.2 设备生命周期端点（全部已验证）

服务地址: `http://172.22.4.17:8100`，路径前缀 `/feign/v1/device/lifecycle`

| 端点 | 方法 | 用途 | 验证结果 |
|------|------|------|---------|
| `/pageDevices` | POST | 分页设备列表 | ✅ 返回 120 台 |
| `/getDeviceDetail` | POST | 设备详情 | ✅ 含 rssi/snr/gateway |
| `/getDeviceDetailWithTelemetry` | GET | **设备 + 遥测快照（推荐）** | ✅ 10 个 telemetry properties（含加速度） |
| `/registerDevice` | POST | 设备注册（单个） | ✅ 已验证 |
| `/batchRegisterDevices` | POST | 设备注册（批量） | ✅ 已验证 |
| `/updateDeviceInfo` | POST | 更新设备信息 | ✅ 已验证 |
| `/removeDevice` | POST | 删除设备（软删除） | ✅ 已验证 |
| `/listDevices` | POST | 批量查询 | ✅ |


**pageDevices 请求/响应样例（真实数据）：**

```
POST /feign/v1/device/lifecycle/pageDevices
Headers: token: {token}, Tenant-Id: 000000
Body: {"current":1,"size":5}

Response.data.records[]:
{
  "deviceId": "2072879090955759618",
  "deviceName": "0095690600028600",
  "deviceIdentifier": "0095690600028600",
  "deviceTypeId": "2049031246054559744",
  "onlineStatus": 1,
  "lastActiveTime": "07/07/2026 14:44:17",
  "rssi": -35,
  "snr": "11.2",
  "lastGateway": "24e124fffef4714e"
}
```

**getDeviceDetailWithTelemetry 响应样例（真实数据）：**

```json
{
  "deviceId": "2072879090955759616",
  "deviceTypeCode": "CATTLE_TRACKER",
  "onlineStatus": 1,
  "rssi": -32, "snr": "12.8",
  "lastGateway": "24e124fffef4714e",
  "telemetryProperties": [
    {"identifier":"battery","name":"Battery Level","dataType":"int","value":100,"specs":{"unit":"%"}},
    {"identifier":"latitude","name":"Latitude","dataType":"float","value":0,"specs":{"scale":1e-06}},
    {"identifier":"longitude","name":"Longitude","dataType":"float","value":0,"specs":{"scale":1e-06}},
    {"identifier":"stepNumber","name":"Step Number","dataType":"int","value":3},
    {"identifier":"workMode","name":"Work Mode","dataType":"select","value":"Fixed Period Mode"},
    {"identifier":"software","name":"Software Version","dataType":"text","value":"4"},
    {"identifier":"hardware","name":"Hardware Version","dataType":"text","value":"4"}
  ]
}
```

### 3.2a 设备注册/批量注册/删除/更新（实测验证）

#### 单个注册

```
POST /feign/v1/device/lifecycle/registerDevice
Headers: token: {token}, Tenant-Id: 000000, Content-Type: application/json
```

**请求 DTO**: `DeviceRegistrationReqDto`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `user.userId` | String | ✅ | 服务账号 userId |
| `user.tenantId` | String | ✅ | 租户 ID（`000000`） |
| `deviceIdentifier` | String | ✅ | **DevEUI**（LoRaWAN 设备硬件标识，16 位十六进制，如 `0095690600028ea6`） |
| `deviceTypeCode` | String | ✅ | 设备类型（如 `CATTLE_TRACKER`） |
| `spaceId` | String | ❌ | 空间/位置分配 |

**请求样例：**
```json
{
  "user": {"userId": "2074385063398711296", "tenantId": "000000"},
  "deviceIdentifier": "0095690600028ea6",
  "deviceTypeCode": "CATTLE_TRACKER"
}
```

**成功响应：**
```json
{
  "code": 200,
  "data": {
    "deviceId": "2074666288126443520",
    "deviceIdentifier": "0095690600028ea6",
    "deviceTypeId": "2049031246054559744",
    "status": "device.online.status.offline",
    "createTime": "07/08/2026 09:26:03"
  }
}
```

> **字段映射说明**：`deviceIdentifier` 就是设备的 **DevEUI**（LoRaWAN 设备全球唯一硬件标识），不是自定义名称。blade 注册成功后返回的 `deviceId` 是 blade 内部数据库主键（如 `2074666288126443520`），两者关系：
>
> | smart-livestock 字段 | blade 字段 | 示例值 | 说明 |
> |---|---|---|---|
> | `devices.dev_eui` | `deviceIdentifier` | `0095690600028ea6` | DevEUI，注册时传入，LoRaWAN 网关识别设备的依据 |
> | `devices.blade_device_id` | `deviceId` | `2074666288126443520` | blade 数据库 ID，注册成功后返回，后续所有 blade API 查询用 |
>
> **类型兼容说明**：blade 当前将 `deviceId` 实现为 VARCHAR（已知 bug，对方承诺后续改为 BIGINT）。smart-livestock 侧 DB 使用 **BIGINT** 存储（遵循本地设计规范），Feign DTO 层使用 String（匹配 blade 当前 API），在 Application Service 边界做 `Long.parseLong()` / `String.valueOf()` 转换。blade 修复后只需改 Feign DTO 类型，DB 和领域模型零迁移。

**错误场景：**
| 场景 | 错误码 | 消息 |
|------|--------|------|
| 缺 `user` | 400 | `must not be null` |
| 缺 `deviceIdentifier` | 400 | `must not be blank` |
| 缺 `deviceTypeCode` | 400 | `must not be null` |
| 重复标识 | 1000000004 | `Device registration failed` |
| 无效类型 | 1000000004 | `Device registration failed` |

#### 批量注册

```
POST /feign/v1/device/lifecycle/batchRegisterDevices
Headers: token: {token}, Tenant-Id: 000000
```

**请求 DTO**: `BatchDeviceRegistrationReqDto`

> **注意**：列表字段名是 `deviceRegistrationReqDtoList`（非 `devices`/`deviceList` 等直觉命名）。

**请求样例：**
```json
{
  "user": {"userId": "2074385063398711296", "tenantId": "000000"},
  "deviceRegistrationReqDtoList": [
    {"deviceIdentifier": "0095690600028ea6", "deviceTypeCode": "CATTLE_TRACKER"},
    {"deviceIdentifier": "0095690600028600", "deviceTypeCode": "CATTLE_TRACKER"}
  ]
}
```

**响应——三种结果分类返回：**
```json
{
  "code": 200,
  "data": {
    "successCount": 1,
    "failCount": 1,
    "successList": [{"deviceId": "2074673347207184384"}],
    "failList": [{"deviceIdentifier": "0095690600028ea6", "reason": "设备已存在"}],
    "existedDevices": [{"deviceId": "...", "deviceName": "...", "deviceIdentifier": "..."}]
  }
}
```

批量注册优雅处理重复：重复设备不会导致整批失败，而是在 `failList` 中标记原因，并在 `existedDevices` 中返回已有设备完整信息。

#### 删除设备（软删除）

```
POST /feign/v1/device/lifecycle/removeDevice
Headers: token: {token}, Tenant-Id: 000000
```

**请求 DTO**: `DeviceRemoveReqDto`

```json
{
  "user": {"userId": "2074385063398711296", "tenantId": "000000"},
  "deviceIds": ["2074666288126443520", "2074666405088804864"]
}
```

**行为**：软删除——设备标记删除，但 `getDeviceDetail` 仍可查到。重复删除已删除设备返回 `1000000006 Device not found`。

#### 更新设备信息

```
POST /feign/v1/device/lifecycle/updateDeviceInfo
Headers: token: {token}, Tenant-Id: 000000
```

**请求 DTO**: `DeviceUpdateReqDto`（需 `user` + `deviceId` + 可更新字段）

```json
{
  "user": {"userId": "2074385063398711296", "tenantId": "000000"},
  "deviceId": "2074673167011495936",
  "deviceName": "Renamed-Cattle-Tracker"
}
```

实测成功将设备名从 `SL-BATCH-001` 改为 `Renamed-Cattle-Tracker`。

### 3.3 遥测数据端点

| 端点 | 方法 | 用途 | 参数 | 验证结果 |
|------|------|------|------|---------|
| `/feign/v1/device/telemetry/history/latest` | POST | 最新遥测 | `deviceIds[]` + `deviceTypeCode` | ✅ 有数据 |
| `/feign/v1/device/telemetry/history/query` | POST | 遥测历史 | `deviceIds[]` + `deviceTypeCode` + `startTime` + `endTime` | ✅ 端点正常（数据空） |

**latest 响应样例：**

```json
{
  "data": [
    {
      "deviceId": null,
      "telemetryJson": {
        "lastRow(battery)": "1E+2",
        "lastRow(latitude)": "0",
        "lastRow(longitude)": "0",
        "lastRow(stepNumber)": "1",
        "lastRow(ts)": "2026-07-07 14:44:17"
      }
    }
  ]
}
```

### 3.4 上行历史记录端点（核心时序数据源，含加速度/GPS/步数）

```
GET /device/report-record/page?deviceId={deviceId}&current={page}&size={pageSize}
```

> 此端点在 blade 8100 上可直接访问（也通过网关 `172.22.4.16/api/building/v1/devices/report/record/page` 访问）。

**响应样例（真实数据，每条含完整解码后的属性）：**

```json
{
  "total": 278,
  "records": [
    {
      "id": "2074406664928313344",
      "deviceId": "2072879090955759616",
      "deviceIdentifier": "0095690600028ea6",
      "hexData": "686b7400fa0104040364100000000011...",
      "reportTime": "07/07/2026 16:14:23",
      "decodeStatus": true,
      "decodeData": "{\"properties\":{\"properties\":{\"battery\":100,\"latitude\":0,\"longitude\":0,\"stepNumber\":3,\"xAxisDirectionAccelerationValue\":65383,\"yAxisDirectionAccelerationValue\":65383,\"zAxisDirectionAccelerationValue\":64922}}}",
      "rssi": -32,
      "snr": "12.0",
      "reportGateway": "24e124fffef4714e"
    }
  ]
}
```

> `decodeData` 是嵌套 JSON 字符串，需二次解析。其中 `properties.properties` 包含全部上报属性（含三轴加速度，2026-07-08 起物模型已注册）。加速度原始值为 uint16 存储的 signed int16 补码，需用 §3.5.1 的换算公式转为 g 值。

### 3.5 设备物模型端点

```
GET /feign/v1/device/type/findById?id={typeId}
```

CATTLE_TRACKER（typeId=`2049031246054559744`）物模型 19 个属性（2026-07-08 blade 团队更新，新增三轴加速度）：

| identifier | name | dataType |
|------------|------|----------|
| software | Software Version | text |
| hardware | Hardware Version | text |
| battery | Battery Level | int |
| workMode | Work Mode | select |
| fixedReportInterval | Fixed Report Interval | int |
| segment1ReportInterval | Segment 1 Report Interval | int |
| segment1StartTime | Segment 1 Start Time | string |
| segment1EndTime | Segment 1 End Time | string |
| segment2ReportInterval | Segment 2 Report Interval | int |
| segment2StartTime | Segment 2 Start Time | string |
| segment2EndTime | Segment 2 End Time | string |
| idleReportInterval | Idle Report Interval | int |
| latitude | Latitude | float |
| longitude | Longitude | float |
| stepNumber | Step Number | int |
| antiDisassemblyStatus | Anti-disassembly Status | int |
| **xAxisDirectionAccelerationValue** | **device.prop.xAxisDirectionAccelerationValue** | **int** |
| **yAxisDirectionAccelerationValue** | **device.prop.yAxisDirectionAccelerationValue** | **int** |
| **zAxisDirectionAccelerationValue** | **device.prop.zAxisDirectionAccelerationValue** | **int** |

> 2026-07-08：blade 团队更新物模型，新增三个加速度属性（#17-19）。此前加速度值仅存在于 report-record 的 decodeData 中（物模型未注册），更新后所有遥测端点（getDeviceDetailWithTelemetry、telemetry/history/latest）均返回加速度值。

### 3.5.1 加速度计换算（LIS3DH，固件源码 + 规格书 + 实测数据三方确认）

**传感器**: ST LIS3DH 三轴 MEMS 加速度计（见 `docs/reference/C15134_姿态传感器-陀螺仪_LIS3DHTR_规格书_WJ51889.PDF`）

**固件配置**（源码分析确认）:

| 配置项 | 值 | 来源 |
|--------|-----|------|
| 量程 | ±2g | LIS3DH_SCALES[0] = 0.001 |
| 分辨率模式 | Low Power（8-bit，~16mg） | acc.c:411 `lis3dh_low_power` |
| 数据上报 | 原始整数（非 g 值） | acc.c:289 `lis3dh_get_raw_data` |
| 动作阈值 | 512 raw ≈ 32mg | acc.h:18 `DYNAMIC_PRECISION = 512` |
| 高通滤波 | 未启用（数据含重力分量） | 静止合矢量 ≈ 1g 实测确认 |

**数据编码**: LIS3DH 输出为二进制补码 signed int16（左对齐 16-bit 寄存器），blade 存为 unsigned uint16。负值（如 -153）在 uint16 中表现为 65383。

**换算公式**:

```python
def blade_accel_to_g(raw: int) -> float:
    signed = raw - 65536 if raw > 32767 else raw
    return signed * 0.004  # ~3.57mg/digit (实测), 4mg/digit (规格书 Normal)
```

> **为什么是 0.004 而不是 1/16384**：固件源码中 LIS3DH 的 16-bit 左对齐寄存器值用 `g = raw / 16384` 换算（±2g 下 1g = 16384）。但 blade 上报的值不是芯片寄存器原始值——经过解码器处理后降为 ~10-bit 有效精度。实测 92 个静止样本合矢量均值 = 280.5 digits → 反推灵敏度为 3.57mg/digit，接近规格书 Normal 模式的 4mg/digit。

**验证依据**: 92 个静止样本合矢量均值 = 280.5 digits × 4mg = 1122mg ≈ 1.12g（接近理论重力 1g，偏差来自传感器零点偏移 ±40mg + 微振动噪声）。

**坐标系**（LIS3DH datasheet 定义）:

- X 轴：平行于芯片长边（引脚 1→16 方向）
- Y 轴：平行于芯片短边（引脚 1→2 方向）
- Z 轴：垂直芯片表面，朝上为正
- 静止正面朝上：AccZ ≈ +1g，AccX ≈ AccY ≈ 0g

**物理含义**: 传感器输出的是视在加速度（比力），包含重力分量。静止时合矢量 ≈ 1g；自由落体时三轴趋近 0g（失重）。

**倾角计算**（需重力分量，数据满足条件）:

```python
import math
roll  = math.degrees(math.atan2(ay, az))                           # 绕 X 轴旋转
pitch = math.degrees(math.atan2(-ax, math.sqrt(ay**2 + az**2)))    # 绕 Y 轴旋转
```

**活动分类（基于合矢量，数据含重力）**:

| 合矢量 | 分类 | 业务含义 |
|--------|------|---------|
| < 1.15g | rest | 静止/休息 |
| 1.15-1.5g | light | 轻微活动（吃草） |
| 1.5-2.5g | active | 活跃行走 |
| > 2.5g | intense | 剧烈运动/冲击/跌倒 |

**精度限制**: 当前固件用 Low Power 8-bit 模式（~16mg 分辨率），动作阈值 32mg 以下被忽略。反刍咀嚼、头部微摆等细微动作（< 16mg）可能检测不到。固件中有注释掉的 `lis3dh_high_res` 备选（~1mg 分辨率），建议长期切换以支持健康监测场景。

**代码**: `AccelerometerConverter.java`（`toG()` / `toMs2()` / `magnitudeG()` / `motionIntensity()` / `rollDegrees()` / `pitchDegrees()` / `classifyActivity()` / `isAboveFirmwareThreshold()`）+ 12 个单元测试。

### 3.6 License 查询（接口②）

```
GET /feign/v1/device-license/control/by-sn?deviceSn={sn}
```

> License 服务 `hkt-blade-device-license-client` 当前在 Nacos 未注册（无实例），调用返回 500。待 blade 部署 License 服务后验证。

---

## 4. 认证链路：OAuth2 换票

### 4.1 换票端点

```
POST http://172.22.4.17:8108/oauth2/token
Headers:
  Authorization: Basic {base64(client_id:client_secret)}
  Content-Type: application/x-www-form-urlencoded
  Tenant-Id: 000000
Body:
  grant_type=openapi&userId={serviceUserId}
```

| 参数 | 实际值 |
|------|--------|
| client_id | `hkt_openapi` |
| client_secret | `RLuXd5H8RkZZRPA6TKbf72XmjKYNq` |
| grant_type | `openapi` |
| userId | `2074385063398711296`（自建服务账号，见 §4.5） |
| Tenant-Id | `000000` |

> 注意端点路径是 `/oauth2/token`（带 "2"），不是标准 OAuth2 的 `/oauth/token`。

### 4.2 换票响应

```json
{
  "code": 200,
  "success": true,
  "data": {
    "accessToken": "RGnm98lSGH_JQMjTpMkHzJmtdpVgF9COFgoRP9iY2vQa4XxN7HCGui6QPR2kbMj6e6krwLbba_AhrIQIDARObbR0X6jo1eCzlG0aa4AvwoB5gEFH0066rOjdBeGp3wn1",
    "tokenType": "Bearer",
    "expiresIn": 43200,
    "scope": "",
    "additionalParameters": {
      "sub": "SmartLivestock Service",
      "aud": ["hkt_openapi"],
      "user_id": "2074385063398711296",
      "iss": "https://hkt.com",
      "jti": "7d412546-5b8e-46ef-b438-b5b69c4fc9b1",
      "username": "SmartLivestock Service"
    }
  },
  "msg": "Operation successful"
}
```

Token 有效期 12 小时（43200 秒），代码中提前 120 秒失效刷新。

### 4.3 blade 请求约定（与标准 OAuth2 的差异）

| 标准 OAuth2 | blade 约定 |
|-------------|-----------|
| `Authorization: Bearer {token}` | `token: {token}`（裸值，无 Bearer 前缀） |
| 无租户概念 | 所有请求必须带 `Tenant-Id: 000000` 头 |
| `/oauth/token` | `/oauth2/token`（blade 自定义路径） |
| `grant_type=client_credentials` | `grant_type=openapi`（blade 自定义 grant type） |

### 4.4 两个 OAuth 客户端

| 客户端 | client_id | 支持的 grant_type | 用途 |
|--------|-----------|-------------------|------|
| openapi | `hkt_openapi` | `openapi`（按 userId 换票，不需要密码） | **服务间调用（推荐）** |
| web | `hkt_web` | `password`（需要用户名密码） | 前端登录 |

我们使用 `hkt_openapi` + `openapi` grant，只需 userId，不需要知道用户密码。

> hkt_web 的 Basic Auth 凭据：`aGt0X3dlYjpCQUoxd1VvdFp0NkRXZWYzd25iYUMwSUx1Ng==`（`hkt_web:BAJ1wUotZt6DWef3wnbaC0ILu6`）

### 4.5 服务账号创建实操（PoC 实际操作记录）

blade 平台没有现成的 API 用户，我们通过 hkt-blade-system 的 feign 端点（无需 token 认证）自建了服务账号。

**实际创建的用户/账户信息：**

| 属性 | 值 |
|------|-----|
| 账户名 (account) | `sl_service` |
| 密码明文 | `Sl@SmartLivestock2026!` |
| 密码 RSA 加密 | 用 blade `/code/public-key` 返回的 RSA 公钥，`PKCS1Padding` 加密 |
| 用户 ID (userId) | `2074385063398711296` |
| 用户名 (name) | `SmartLivestock Service` |
| 用户类型 | `client` |
| 租户 | `000000` |
| 创建时间 | `2026-07-07 14:48:33` |

**创建流程（4 步）：**

**步骤 1：获取 RSA 公钥**

```
GET http://172.22.4.17:8108/code/public-key
Response.data: "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCdcFKLWbeg1nn98J22gtCC7uvi7t8FrJIy2E0dlSRLuXd5H8RkZZRPA6TKbf72XmjKYNqwz1y46SOpaS9ZyIOXqdoldxNCZZKUYzjAyu/H63wL0cE+nAtuRdtOwMYk+9o5ZrB6Ld398mDc01SU3gMpiqGoaJQPLEvwja5qbTcXawIDAQAB"
```

**步骤 2：RSA 加密密码**

```python
# RSA/ECB/PKCS1Padding
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives.serialization import load_der_public_key
import base64

pub_key = load_der_public_key(base64.b64decode(pubkey_b64))
encrypted = pub_key.encrypt(b'Sl@SmartLivestock2026!', padding.PKCS1v15())
encrypted_b64 = base64.b64encode(encrypted).decode()
```

**步骤 3：创建用户（feign 端点，不需要 token）**

```
POST http://172.22.4.17:8106/feign/v1/system/sdk/user/create
Headers: Tenant-Id: 000000, Content-Type: application/json
Body: {"account":"sl_service","password":"{RSA加密后Base64}","name":"SmartLivestock Service"}

Response:
{
  "code": 200, "success": true,
  "data": {
    "id": "2074385063398711296",
    "userType": "client",
    "name": "SmartLivestock Service",
    "authStatus": "pending",
    "status": "active"
  }
}
```

**步骤 4：启用用户**

```
PUT http://172.22.4.17:8106/feign/v1/system/sdk/user/2074385063398711296/enable
Headers: Tenant-Id: 000000
Response: {"code":200,"success":true,"msg":"操作成功"}
```

启用后即可用 `userId=2074385063398711296` 走 `openapi` grant 换票。

> 用户创建后 `authStatus` 是 `pending`，不启用直接换票会返回"用户已失效"。

**创建过程中踩过的坑：**
- `account/create`（`/feign/v1/system/sdk/account/create`）对同样加密的密码返回 `20010017 Password does not meet security rules`，而 `user/create` 返回 `20010018 Password decryption failed`（密码未加密时）。最终走 `user/create` + RSA 加密密码成功。
- 密码必须先用 RSA 公钥加密，明文密码会报 `Password decryption failed`。
- 密码需满足安全规则（大小写 + 数字 + 特殊字符 + 足够长度）。

**blade-system 其他可用的 feign 端点（不需要 token）：**
- `POST /feign/v1/system/sdk/user/create` — 创建用户
- `PUT /feign/v1/system/sdk/user/{id}/enable` — 启用
- `PUT /feign/v1/system/sdk/user/{id}/disable` — 禁用
- `GET /feign/v1/system/sdk/user/{id}` — 查询
- `GET /feign/v1/system/sdk/user/list` — 列表
- `POST /feign/v1/system/sdk/account/create` — 创建账户
- `POST /feign/v1/system/sdk/tenant/create` — 创建租户

### 4.6 token 缓存策略（代码已固化）

- 进程内 `ConcurrentHashMap` 按 userId 缓存
- 提前 `expiry-skew-seconds`（120s）失效，避免边界 401
- 双重检查锁（per-userId `synchronized`），防止并发重复换票

---

## 5. HTTP 客户端技术选型：方案 B（Feign + url 直连）

### 5.1 方案选型结论

| 维度 | 方案 B：Feign + url 直连 | 方案 C：Feign + Nacos |
|------|------|------|
| **新增依赖** | 1（spring-cloud-starter-openfeign） | 4+（Cloud + Alibaba + Nacos） |
| **启动依赖** | 零外部依赖 | 依赖 Nacos 集群连通 |
| **运维复杂度** | 低 | 高 |
| **架构侵入** | 极小 | 大（变成微服务节点） |
| **未来迁移到 Nacos** | 删 `url` 属性即可 | 已是 |

### 5.2 关键写法

```java
@FeignClient(
    name = "blade-device-lifecycle",        // 内部标识，随便起
    url  = "${blade.device.base-url}",       // 直连地址，不查 Nacos
    path = "/feign/v1/device/lifecycle",
    configuration = BladeFeignConfig.class,
    fallbackFactory = BladeDeviceServiceFallback.class
)
```

### 5.3 依赖（已验证）

```groovy
plugins {
    id 'org.springframework.boot' version '3.3.0'
    id 'io.spring.dependency-management' version '1.1.5'
}

ext {
    // Cloud 2023.0.x 匹配 Boot 3.2/3.3；Cloud 2024.0.x 需要 Boot 3.4.x。
    // smart-livestock-server 是 Boot 3.3.0，必须用 2023.0.x。
    set('springCloudVersion', '2023.0.4')
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.cloud:spring-cloud-starter-openfeign'
    compileOnly 'org.projectlombok:lombok'
    annotationProcessor 'org.projectlombok:lombok'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'com.squareup.okhttp3:mockwebserver:4.12.0'
}
```

> **重要修正**：原文档写 Cloud 2024.0.0 匹配 Boot 3.3 是**错误的**。Cloud 2024.0.x 需要 Boot 3.4.x。Boot 3.3.0 必须用 Cloud **2023.0.4**。PoC 已验证此组合编译和测试通过。

### 5.4 Feign 请求拦截器（BladeFeignConfig）

```java
// 每次请求注入 token + Tenant-Id 头
@Bean
RequestInterceptor bladeAuthInterceptor(BladeTokenProvider tokenProvider, ...) {
    return template -> {
        template.header("token", tokenProvider.getToken());  // blade 约定，无 Bearer
        template.header("Tenant-Id", tenantId);              // blade 必须头
    };
}

// HTTP 5xx → BladeServiceException（不需要 circuit breaker 依赖）
@Bean
ErrorDecoder bladeErrorDecoder() {
    return (methodKey, response) -> {
        if (response.status() >= 500) {
            return new BladeServiceException("blade service unavailable for " + methodKey);
        }
        return new ErrorDecoder.Default().decode(methodKey, response);
    };
}
```

---

## 6. 遥测数据获取方案：主动轮询（替代 Webhook）

blade 不可改代码，Webhook 推送方案作废。改为 smart-livestock 主动轮询。

### 6.1 推荐数据源：report-record/page

`GET /device/report-record/page` 是验证后最佳的时序数据源：
- 每条记录包含 `hexData`（原始十六进制）+ `decodeData`（解码后的完整属性 JSON）
- 支持分页（`current` + `size`），实测 324+ 条记录（持续增长）
- 返回 `rssi`/`snr`/`reportGateway`（运维数据）+ 所有上报属性（特征数据）
- 数据上报频率约 30 分钟一次

### 6.2 轮询方案

```
定时任务（每 5-30 min）:
  1. 查 devices WHERE blade_device_id IS NOT NULL
  2. 对每个设备:
     a. 取 last_report_synced_at（游标）
     b. GET /device/report-record/page?deviceId={id}&current=1&size=100
     c. 翻页拉完所有新数据
     d. 解析 decodeData，提取 battery/latitude/longitude/stepNumber 等
     e. 逐条 ingest 进 TelemetryIngestionService
     f. 更新游标
```

### 6.3 备选数据源对比

| 端点 | 数据丰富度 | 时序支持 | 实测状态 |
|------|-----------|---------|---------|
| `/device/report-record/page` | **最高**（hexData + decodeData + rssi/snr） | ✅ 按 reportTime 排序 | 278+264 条 |
| `/telemetry/history/query` | 中（仅 telemetryJson） | ✅ 时间范围 | 0 条（空） |
| `/telemetry/history/latest` | 低（仅快照） | ❌ 无 | 2 条快照 |
| `/telemetry/history/aggregation` | 聚合 | ✅ | 参数名未完全确认 |

### 6.4 decodeData 解析

`decodeData` 是嵌套 JSON 字符串，结构为：
```
decodeData → JSON → properties → properties → {battery, latitude, longitude, stepNumber, ...}
```

解析需二次 JSON 反序列化。三轴加速度已纳入物模型（2026-07-08 更新）。

---

## 7. smart-livestock 改造需求（方案 B）

### 7.1 新增：Blade Feign Client 基础设施

PoC 已验证的文件结构（迁移到 `smart-livestock-server/.../iot/infrastructure/client/feign/`）：

```
client/feign/
├── BladeDeviceServiceClient.java     ← 设备生命周期（pageDevices/getDeviceDetail/...）
├── BladeHistoryDataClient.java       ← 遥测+历史（latest/query/report-record）
├── BladeLicenseClient.java           ← License 查询（待 License 服务部署）
├── BladeFeignConfig.java             ← token+Tenant-Id 拦截器 + ErrorDecoder
├── InternalResponse.java             ← blade 包络
├── fallback/
│   ├── BladeDeviceServiceFallback.java
│   ├── BladeHistoryDataFallback.java
│   └── BladeLicenseFallback.java
└── dto/
    ├── DeviceDetailResp, DevicePageReq/Resp
    ├── DeviceTelemetryResp, TelemetryQueryReq/Resp
    ├── ReportRecordPageResp（新增）
    ├── DeviceRegistrationReq/Resp, LicenseStatusResp
    └── LoginUser

util/
└── AccelerometerConverter.java       ← LIS3DH 加速度计换算（toG/magnitudeG/classifyActivity）

oauth/
├── BladeOAuth2Properties.java        ← 含 tenantId 字段
├── BladeGatewayTokenService.java     ← 换票 + Tenant-Id 头 + 缓存
├── BladeTokenProvider.java           ← 固定 service account
├── BladeOAuth2RestConfig.java
└── OAuthTokenEnvelope.java
```

### 7.2 配置项（application.yml）

```yaml
blade:
  device:
    base-url: ${BLADE_DEVICE_URL:http://172.22.4.17:8100}
  license:
    base-url: ${BLADE_LICENSE_URL:http://172.22.4.17:8100}
  oauth2:
    enabled: ${BLADE_OAUTH2_ENABLED:false}
    token-uri: ${BLADE_OAUTH2_TOKEN_URL:http://172.22.4.17:8108/oauth2/token}
    client-id: ${BLADE_OAUTH2_CLIENT_ID:hkt_openapi}
    client-secret: ${BLADE_OAUTH2_CLIENT_SECRET:RLuXd5H8RkZZRPA6TKbf72XmjKYNq}
    expiry-skew-seconds: 120
    service-user-id: ${BLADE_SERVICE_USER_ID:2074385063398711296}
    tenant-id: ${BLADE_TENANT_ID:000000}
  feign-auth:
    header-name: token
    token-prefix: ""
  service-account:
    user-id: ${BLADE_SERVICE_USER_ID:2074385063398711296}
    tenant-id: ${BLADE_TENANT_ID:000000}
```

### 7.3 修改：Device 领域模型

新增字段：`bladeDeviceId`, `rssi`, `snr`, `lastGateway`, `lastTelemetrySyncedAt`

### 7.4 新增：Flyway 迁移

```sql
ALTER TABLE devices
    ADD COLUMN IF NOT EXISTS blade_device_id BIGINT,
    ADD COLUMN IF NOT EXISTS rssi INTEGER,
    ADD COLUMN IF NOT EXISTS snr NUMERIC(4,1),
    ADD COLUMN IF NOT EXISTS last_gateway VARCHAR(128),
    ADD COLUMN IF NOT EXISTS last_telemetry_synced_at TIMESTAMP;

CREATE UNIQUE INDEX IF NOT EXISTS idx_devices_blade_device_id
    ON devices (blade_device_id) WHERE blade_device_id IS NOT NULL;
```

---

## 8. 数据模型对齐

### 8.1 Device ID 映射

blade `deviceId`（当前 String，实际为 19 位纯数字 snowflake ID，如 `2072879090955759616`）↔ smart-livestock `blade_device_id`（**BIGINT**，遵循本地设计规范）。

### 8.2 DeviceType 映射（已确认）

| blade `deviceTypeCode` | blade `typeId` | smart-livestock `DeviceType` |
|------|------|------|
| `CATTLE_TRACKER` | `2049031246054559744` | `TRACKER` |

> 原文档推测的 `tracker`/`rumenCapsule` 等 typeCode 是错的，实际是 `CATTLE_TRACKER`（大写下划线）。blade 还有其他设备类型（GEOMAGNETIC, AIR_QUALITY, GARBAGE_OVERFLOW, GATE_MAGNETIC 等），与畜牧无关。

### 8.3 状态机各自独立

blade `onlineStatus`（0=离线/1=在线，运行时心跳）与 smart-livestock `status`（生命周期状态机）独立维护。

---

## 9. PoC 验证结果

### 9.1 单元测试（16/16 全绿）

**对接测试（MockWebServer，6/6）：**

| # | 用例 | 覆盖点 |
|---|------|--------|
| 1 | `oauthTokenExchangeWorks` | `/oauth2/token` + `grant_type=openapi` + Basic Auth + `Tenant-Id` |
| 2 | `tokenHeaderInjected` | `token` 头 + `Tenant-Id` 头注入 |
| 3 | `envelopeParsing` | `InternalResponse` 包络 + `DevicePageResp` 解析 |
| 4 | `deviceDetailWithTelemetry` | 设备详情 + 遥测属性 |
| 5 | `telemetryLatestQuery` | 最新遥测查询 |
| 6 | `errorDecoderOn500` | HTTP 500 → `BladeServiceException` |

**加速度计换算测试（AccelerometerConverterTest，12/12）：**

| # | 用例 | 覆盖点 |
|---|------|--------|
| 7 | `positiveValue` | 正值 uint16 → g（+0.612g） |
| 8 | `negativeValue` | 负值补码 uint16 → g（-0.612g） |
| 9 | `zeroValue` | 零值 = 0g |
| 10 | `maxPositive` | 量程边界（512 → +2.048g） |
| 11 | `maxNegative` | 负边界（65485 → -0.204g） |
| 12 | `magnitudeStationary` | 静止合矢量 ≈ 1g |
| 13 | `magnitudeFlatHorizontal` | 水平放置 Z=1g |
| 14 | `motionIntensityZero` | 纯重力时运动强度=0 |
| 15 | `activityClassification` | rest/light/active/intense 阈值 |
| 16 | `realBladeComparison` | 真实 blade 样本：活动 > 静止 |
| 17 | `toMs2Conversion` | g → m/s² 换算（1g = 9.80665） |
| 18 | `firmwareThreshold` | 固件动作阈值 512 raw ≈ 32mg |

### 9.2 真实联通性验证（13/13 全绿）

脚本：`business-platform/hkt-blade-device-docking/scripts/verify-blade-docking.sh`

| Step | 验证项 | 结果 |
|------|--------|------|
| 0 | auth + device 服务健康 | UP |
| 1 | OAuth2 换票 | token 12h 有效 |
| 2 | 设备详情（2 台） | online + RSSI/SNR/gateway |
| 3 | 设备 + 遥测快照（2 台） | 10 个 telemetry properties（含加速度） |
| 4 | 最新遥测 | battery/lat/lon/steps/accel(x/y/z g 值) |
| 5 | 上行历史记录摘要（latest 10） | 278+264 条 |
| 6 | GPS+步数+加速度历史表（全量，含 raw + g 值 + 活动分类） | 324+ 条完整表 |
| 7 | 物模型定义 | 19 个属性（含三轴加速度） |

### 9.3 PoC 工程位置

`business-platform/hkt-blade-device-docking/`

```bash
# 单元测试
cd business-platform/hkt-blade-device-docking
smart-livestock-server/gradlew test

# 真实联通性验证
./scripts/verify-blade-docking.sh
```

---

## 10. 实施顺序

```
已完成（PoC）:
  [服务账号创建] ── [OAuth2 换票] ── [Feign Client + DTO] ── [加速度计换算] ── [单元测试 16/16]
  [真实联通性 13/13] ── [report-record 历史数据验证]

待迁移到 smart-livestock-server:
  [Feign Client 迁移] ── [Device 模型扩展 + Flyway] ── [注册流程改造]
  [轮询 Job] ── [ErrorCode + i18n] ── [部署 + 集成测试]
```

---

## 11. 风险与待确认（更新版）

| # | 项 | 状态 | 说明 |
|---|------|------|------|
| 1 | token header 名 | ✅ 已验证 | `token`（无 Bearer） |
| 2 | `grant_type=openapi` | ✅ 已验证 | hkt_openapi 客户端 |
| 3 | Tenant-Id 头 | ✅ 已验证 | 所有请求必须带 `000000` |
| 4 | OAuth 端点路径 | ✅ 已验证 | `/oauth2/token`（不是 `/oauth/token`） |
| 5 | Cloud 版本 | ✅ 已验证 | 2023.0.4 匹配 Boot 3.3.0（非 2024.0.0） |
| 6 | `deviceTypeCode` | ✅ 已确认 | `CATTLE_TRACKER` |
| 7 | `deviceId` 格式 | ✅ 已确认 | 19 位数字 String，VARCHAR(64) 够 |
| 8 | 上行历史数据 | ✅ 已验证 | report-record/page，324+ 条（持续增长），含 decodeData |
| 9 | 服务账号创建 | ✅ 已验证 | userId=2074385063398711296 |
| 10 | ErrorDecoder 降级 | ✅ 已验证 | HTTP 5xx → BladeServiceException |
| 11 | License 服务 | ⏳ 待部署 | hkt-blade-device-license-client 未注册 |
| 12 | 设备注册 | ✅ 已验证 | registerDevice/batchRegister/removeDevice/updateDeviceInfo 全部验证 |
| 13 | aggregation 参数 | ⏳ 待确认 | 聚合端点参数名未完全确认 |
| 14 | GPS 定位 | ⓞ 数据为空 | 设备 GPS 坐标为 0（未移动到 GPS 信号区） |
| 15 | 加速度计换算 | ✅ 已确认 | LIS3DH ±2g LP 8-bit，~4mg/digit，signed int16 补码，含重力，固件源码+规格书+实测三方确认 |
| 16 | 活动分类 | ✅ 已验证 | rest/light/active/intense 四级，静止 1.13g、活动 1.53x |

---

## 12. open-platform-dev 参考实现索引

| 参考源 | 路径 | 用途 |
|--------|------|------|
| OAuth2 换票 | `common/feign/oauth/OpenApiGatewayTokenService.java` | 参考（需加 Tenant-Id） |
| Token 响应 | `common/feign/oauth/OAuthTokenEnvelope.java` | 复制 |
| 请求头注入 | `common/feign/FeignAuthInterceptor.java` | 参考（blade 约定 `token` 头） |
| 响应包络 | `common/feign/InternalResponse.java` | 复制 |
| 设备服务客户端 | `device/client/DeviceServiceClient.java` | 参考（加 `url`） |
| License 客户端 | `device/client/DeviceLicenseClient.java` | 参考 |
| 历史数据客户端 | `device/client/DeviceHistoryDataClient.java` | 参考 |
| 内部 DTO | `device/dto/internal/*` | 参考 |

> open-platform-dev 是 Boot 3.5.3 + Cloud 2025.0.0，与 smart-livestock Boot 3.3.0 不兼容。Feign 接口签名和 DTO 与版本无关，直接参考源码即可。

---

## 附录 A：PoC 创建的实际凭据清单

| 类型 | 属性 | 值 |
|------|------|-----|
| **Nacos** | 地址 | `172.22.3.16:8848` |
| | namespace | `c47123d9-9d2b-4fdf-a61a-8d5daa9c89ac` |
| | 用户/密码 | `nacos` / `16c47768b93458d3!QA` |
| **OAuth client** | client_id | `hkt_openapi` |
| | client_secret | `RLuXd5H8RkZZRPA6TKbf72XmjKYNq` |
| | grant_type | `openapi` |
| **服务账号** | userId | `2074385063398711296` |
| | account | `sl_service` |
| | 密码明文 | `Sl@SmartLivestock2026!` |
| | name | `SmartLivestock Service` |
| | tenant | `000000` |
| **Web client**（备用） | client_id | `hkt_web` |
| | client_secret | `BAJ1wUotZt6DWef3wnbaC0ILu6` |
| | grant_type | `password` |
| **目标设备** | Device 1 | `2072879090955759616` / `0095690600028ea6` |
| | Device 2 | `2072879090955759618` / `0095690600028600` |
| | 设备类型 | `CATTLE_TRACKER` |
| | typeId | `2049031246054559744` |

---

## 附录 B：完整端点映射（实测）

| 端点 | 方法 | 服务 | 验证状态 |
|------|------|------|---------|
| `/oauth2/token` | POST | auth:8108 | ✅ |
| `/code/public-key` | GET | auth:8108 | ✅ |
| `/code/image` | GET | auth:8108 | ✅ 验证码 |
| `/feign/v1/system/sdk/user/create` | POST | system:8106 | ✅ 无需 token |
| `/feign/v1/system/sdk/user/{id}/enable` | PUT | system:8106 | ✅ 无需 token |
| `/feign/v1/system/sdk/user/{id}` | GET | system:8106 | ✅ 无需 token |
| `/feign/v1/device/lifecycle/pageDevices` | POST | device:8100 | ✅ |
| `/feign/v1/device/lifecycle/getDeviceDetail` | POST | device:8100 | ✅ |
| `/feign/v1/device/lifecycle/getDeviceDetailWithTelemetry` | GET | device:8100 | ✅ |
| `/feign/v1/device/lifecycle/registerDevice` | POST | device:8100 | ✅ 已验证 |
| `/feign/v1/device/lifecycle/batchRegisterDevices` | POST | device:8100 | ✅ 已验证 |
| `/feign/v1/device/lifecycle/removeDevice` | POST | device:8100 | ✅ 已验证 |
| `/feign/v1/device/lifecycle/updateDeviceInfo` | POST | device:8100 | ✅ 已验证 |
| `/feign/v1/device/telemetry/history/latest` | POST | device:8100 | ✅ |
| `/feign/v1/device/telemetry/history/query` | POST | device:8100 | ✅ 数据空 |
| `/feign/v1/device/telemetry/history/aggregation` | POST | device:8100 | ⏳ 参数待确认 |
| `/device/report-record/page` | GET | device:8100 | ✅ **推荐** |
| `/feign/v1/device/type/findById` | GET | device:8100 | ✅ |
| `/feign/v1/device/type/findAll` | GET | device:8100 | ✅ |
| `/feign/v1/device/history/data/legends/{deviceType}` | GET | device:8100 | ✅ |
| `/feign/v1/device-license/control/by-sn` | GET | device:8100 | ⏳ License 服务未注册 |

