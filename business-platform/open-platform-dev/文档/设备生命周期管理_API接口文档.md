# 设备生命周期管理 API 接口文档

## 概述

**服务名称**: hkt-blade-device  
**基础路径**: `/feign/v1/device/lifecycle`  
**接口类型**: Feign RPC 接口（内部调用）  
**认证方式**: 使用 `@Inner` 注解标识为内部接口

---

## 接口列表

### 1. 设备注册

注册单个设备到系统中。

#### 接口信息
- **接口路径**: `/feign/v1/device/lifecycle/registerDevice`
- **请求方法**: `POST`
- **接口说明**: 用于注册单个设备，需要提供设备标识符和设备类型编码

#### 请求参数

**请求体 (Request Body)**: `DeviceRegistrationReqDto`

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| user | LoginUser | 是 | 用户信息对象 |
| user.userId | String | 是 | 用户ID |
| user.userName | String | 是 | 用户名 |
| user.tenantId | String | 是 | 租户ID |
| deviceIdentifier | String | 是 | 设备唯一标识符 |
| deviceTypeCode | String | 是 | 设备类型标识 |

#### 请求示例

```json
{
  "user": {
    "userId": "1",
    "userName": "超级管理员",
    "tenantId": "1"
  },
  "deviceIdentifier": "001a0102ff00057b",
  "deviceTypeCode": "RUMEN_CAPSULE"
}
```

#### 响应结果

**响应类型**: `R<DeviceRegistrationRespDto>`

| 字段名 | 类型 | 说明 |
|--------|------|------|
| code | Integer | 响应码 |
| msg | String | 响应消息 |
| data | DeviceRegistrationRespDto | 设备注册响应数据 |
| data.deviceId | String | 注册成功的设备ID |
| data.deviceIdentifier | String | 设备唯一标识 |
| data.deviceTypeId | String | 设备类型ID |
| data.status | String | 设备状态 |
| data.createTime | LocalDateTime | 注册时间 |

#### 响应示例

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "deviceId": "2037377921942110208",
    "deviceIdentifier": "001a0102ff00057b",
    "deviceTypeId": "2000001",
    "status": "INACTIVE",
    "createTime": "2024-01-15T10:30:00"
  }
}
```

---

### 2. 批量设备注册

一次性注册多个设备到系统中。

#### 接口信息
- **接口路径**: `/feign/v1/device/lifecycle/batchRegisterDevices`
- **请求方法**: `POST`
- **接口说明**: 用于批量注册多个设备，提高注册效率

#### 请求参数

**请求体 (Request Body)**: `BatchDeviceRegistrationReqDto`

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| user | LoginUser | 是 | 用户信息对象 |
| user.userId | String | 是 | 用户ID |
| user.userName | String | 是 | 用户名 |
| user.tenantId | String | 是 | 租户ID |
| deviceRegistrationReqDtoList | List\<DeviceRegistrationReqDto\> | 是 | 设备注册请求列表 |
| deviceRegistrationReqDtoList[].deviceIdentifier | String | 是 | 设备唯一标识符 |
| deviceRegistrationReqDtoList[].deviceTypeCode | String | 是 | 设备类型标识 |

#### 请求示例

```json
{
  "user": {
    "userId": "1",
    "userName": "超级管理员",
    "tenantId": "1"
  },
  "deviceRegistrationReqDtoList": [
    {
      "deviceIdentifier": "009569000004097a",
      "deviceTypeCode": "TEMPERATURE_HUMIDITY"
    },
    {
      "deviceIdentifier": "24e124147b509419",
      "deviceTypeCode": "SWITCH_PANEL"
    }
  ]
}
```

#### 响应结果

**响应类型**: `R<BatchDeviceRegistrationRespDto>`

| 字段名 | 类型 | 说明 |
|--------|------|------|
| code | Integer | 响应码 |
| msg | String | 响应消息 |
| data | BatchDeviceRegistrationRespDto | 批量设备注册响应数据 |
| data.successCount | int | 成功注册的设备数量 |
| data.failCount | int | 注册失败的设备数量 |
| data.successList | List\<DeviceRegistrationRespDto\> | 注册成功的设备列表 |
| data.failList | List\<FailedDeviceInfo\> | 注册失败的设备信息列表 |
| data.failList[].deviceIdentifier | String | 失败设备的唯一标识 |
| data.failList[].reason | String | 失败原因 |

#### 响应示例

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "successCount": 2,
    "failCount": 0,
    "successList": [
      {
        "deviceId": "2037377921942110209",
        "deviceIdentifier": "009569000004097a",
        "deviceTypeId": "2000002",
        "status": "INACTIVE",
        "createTime": "2024-01-15T11:00:00"
      },
      {
        "deviceId": "2037377921942110210",
        "deviceIdentifier": "24e124147b509419",
        "deviceTypeId": "2000003",
        "status": "INACTIVE",
        "createTime": "2024-01-15T11:00:00"
      }
    ],
    "failList": []
  }
}
```

---

### 3. 修改设备基础信息

更新已注册设备的名称。

#### 接口信息
- **接口路径**: `/feign/v1/device/lifecycle/updateDeviceInfo`
- **请求方法**: `POST`
- **接口说明**: 用于修改设备的名称等基础信息

#### 请求参数

**请求体 (Request Body)**: `DeviceUpdateReqDto`

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| user | LoginUser | 是 | 用户信息对象 |
| user.userId | String | 是 | 用户ID |
| user.userName | String | 是 | 用户名 |
| user.tenantId | String | 是 | 租户ID |
| deviceId | String | 是 | 设备ID |
| deviceName | String | 是 | 设备名称 |

#### 请求示例

```json
{
  "user": {
    "userId": "1",
    "userName": "超级管理员",
    "tenantId": "1"
  },
  "deviceId": "2037377921942110208",
  "deviceName": "十楼小会议室"
}
```

#### 响应结果

**响应类型**: `R<Boolean>`

| 字段名 | 类型 | 说明 |
|--------|------|------|
| code | Integer | 响应码 |
| msg | String | 响应消息 |
| data | Boolean | 修改是否成功 |

#### 响应示例

```json
{
  "code": 200,
  "msg": "success",
  "data": true
}
```

---

### 4. 设备删除（逻辑删除）

从系统中逻辑删除设备（不物理删除），支持批量删除。

#### 接口信息
- **接口路径**: `/feign/v1/device/lifecycle/removeDevice`
- **请求方法**: `POST`
- **接口说明**: 逻辑删除设备，设备数据仍然保留在数据库中，只是标记为已删除。支持批量删除，传入多个设备ID

#### 请求参数

**请求体 (Request Body)**: `DeviceRemoveReqDto`

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| user | LoginUser | 是 | 用户信息对象 |
| user.userId | String | 是 | 用户ID |
| user.userName | String | 是 | 用户名 |
| user.tenantId | String | 是 | 租户ID |
| deviceIds | List\<String\> | 是 | 要删除的设备ID列表 |

#### 请求示例

```json
{
  "user": {
    "userId": "1",
    "userName": "超级管理员",
    "tenantId": "1"
  },
  "deviceIds": ["2037377921942110208", "2037377921942110209"]
}
```

#### 响应结果

**响应类型**: `R<Boolean>`

| 字段名 | 类型 | 说明 |
|--------|------|------|
| code | Integer | 响应码 |
| msg | String | 响应消息 |
| data | Boolean | 删除是否成功 |

#### 响应示例

```json
{
  "code": 200,
  "msg": "success",
  "data": true
}
```

---

### 5. 批量同步设备到物联网平台

将设备信息批量同步到物联网平台。

#### 接口信息
- **接口路径**: `/feign/v1/device/lifecycle/batchSyncDevicesToIot`
- **请求方法**: `POST`
- **接口说明**: 用于将本地设备信息同步到物联网平台，需要提供设备标识和设备类型ID

#### 请求参数

**请求体 (Request Body)**: `BatchSyncDeviceToIotReqDto`

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| devices | List\<DeviceInfo\> | 是 | 设备信息列表 |
| devices[].deviceIdentifier | String | 是 | 设备标识 |
| devices[].deviceTypeId | String | 是 | 设备类型ID |

#### 请求示例

```json
{
  "devices": [
    {
      "deviceIdentifier": "001a0102ff00057b",
      "deviceTypeId": "2000001"
    },
    {
      "deviceIdentifier": "009569000004097a",
      "deviceTypeId": "2000002"
    }
  ]
}
```

#### 响应结果

**响应类型**: `R<Boolean>`

| 字段名 | 类型 | 说明 |
|--------|------|------|
| code | Integer | 响应码 |
| msg | String | 响应消息 |
| data | Boolean | 同步是否成功 |

#### 响应示例

```json
{
  "code": 200,
  "msg": "success",
  "data": true
}
```

---

### 6. 分页查询设备列表

按条件分页查询设备列表，支持关键字搜索。

#### 接口信息
- **接口路径**: `/feign/v1/device/lifecycle/pageDevices`
- **请求方法**: `POST`
- **接口说明**: 支持按设备名称和设备标识进行关键字搜索，返回分页结果

#### 请求参数

**请求体 (Request Body)**: `DevicePageReqDto`（继承自 `Query`）

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| tenantId | String | 否 | 租户ID |
| userId | String | 否 | 用户ID |
| keyword | String | 否 | 搜索关键字（搜索deviceName和deviceIdentifier） |
| current | Integer | 否 | 当前页码（从1开始，继承自Query） |
| size | Integer | 否 | 每页大小（继承自Query） |

#### 请求示例

```json
{
  "tenantId": "1",
  "userId": "1",
  "keyword": "会议室",
  "current": 1,
  "size": 10
}
```

#### 响应结果

**响应类型**: `R<DevicePageRespDto>`

| 字段名 | 类型 | 说明 |
|--------|------|------|
| code | Integer | 响应码 |
| msg | String | 响应消息 |
| data | DevicePageRespDto | 设备分页响应数据 |
| data.total | Long | 总记录数 |
| data.current | Integer | 当前页码 |
| data.pageSize | Integer | 每页大小 |
| data.records | List\<DeviceDetailRespDto\> | 设备列表 |

#### 响应示例

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "total": 5,
    "current": 1,
    "pageSize": 10,
    "records": [
      {
        "deviceId": "2037377921942110208",
        "deviceName": "十楼小会议室",
        "deviceIdentifier": "001a0102ff00057b",
        "deviceTypeId": "2000003",
        "deviceTypeName": "开关面板",
        "deviceTypeCode": "SWITCH_PANEL",
        "tenantId": "1",
        "onlineStatus": 1,
        "onlineStatusName": "在线",
        "lastActiveTime": "2024-01-15T14:20:00+08:00",
        "isControlEnabled": 1,
        "isDataCollectionEnabled": 1,
        "offlineDuration": 300,
        "createTime": "2024-01-15T10:30:00+08:00",
        "rssi": -60,
        "snr": 8.5,
        "sf": 10,
        "lastGateway": "gateway-001"
      }
    ]
  }
}
```

---

### 7. 查询设备列表（不分页）

查询设备列表，不支持分页，返回所有匹配的设备详情。

#### 接口信息
- **接口路径**: `/feign/v1/device/lifecycle/listDevices`
- **请求方法**: `POST`
- **接口说明**: 查询设备列表（不分页），支持按设备名称和设备标识进行关键字搜索

#### 请求参数

**请求体 (Request Body)**: `DeviceListReqDto`

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| tenantId | String | 否 | 租户ID |
| userId | String | 否 | 用户ID |
| keyword | String | 否 | 搜索关键字（搜索deviceName和deviceIdentifier） |

#### 请求示例

```json
{
  "tenantId": "1",
  "userId": "1",
  "keyword": "会议室"
}
```

#### 响应结果

**响应类型**: `R<List<DeviceDetailRespDto>>`

| 字段名 | 类型 | 说明 |
|--------|------|------|
| code | Integer | 响应码 |
| msg | String | 响应消息 |
| data | List\<DeviceDetailRespDto\> | 设备详情列表 |

#### 响应示例

```json
{
  "code": 200,
  "msg": "success",
  "data": [
    {
      "deviceId": "2037377921942110208",
      "deviceName": "十楼小会议室",
      "deviceIdentifier": "001a0102ff00057b",
      "deviceTypeId": "2000003",
      "deviceTypeName": "开关面板",
      "deviceTypeCode": "SWITCH_PANEL",
      "tenantId": "1",
      "onlineStatus": 1,
      "onlineStatusName": "在线",
      "lastActiveTime": "2024-01-15T14:20:00+08:00",
      "isControlEnabled": 1,
      "isDataCollectionEnabled": 1,
      "offlineDuration": 300,
      "createTime": "2024-01-15T10:30:00+08:00",
      "rssi": -60,
      "snr": 8.5,
      "sf": 10,
      "lastGateway": "gateway-001"
    }
  ]
}
```

---

### 8. 获取设备详情

根据设备ID获取设备的详细信息。

#### 接口信息
- **接口路径**: `/feign/v1/device/lifecycle/getDeviceDetail`
- **请求方法**: `POST`
- **接口说明**: 获取单个设备的完整信息

#### 请求参数

**请求体 (Request Body)**: `DeviceDetailReqDto`

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| deviceId | String | 是 | 设备ID |

#### 请求示例

```json
{
  "deviceId": "2037377921942110208"
}
```

#### 响应结果

**响应类型**: `R<DeviceDetailRespDto>`

| 字段名 | 类型 | 说明 |
|--------|------|------|
| code | Integer | 响应码 |
| msg | String | 响应消息 |
| data | DeviceDetailRespDto | 设备详情响应数据 |
| data.deviceId | String | 设备ID |
| data.deviceName | String | 设备名称 |
| data.deviceIdentifier | String | 设备唯一标识 |
| data.deviceTypeId | String | 设备类型ID |
| data.deviceTypeName | String | 设备类型名称 |
| data.deviceTypeCode | String | 设备类型编码 |
| data.tenantId | String | 租户ID |
| data.onlineStatus | Integer | 在线状态值 |
| data.onlineStatusName | String | 在线状态名称 |
| data.lastActiveTime | OffsetDateTime | 最后活跃时间 |
| data.isControlEnabled | Integer | 是否可控制（0-否，1-是） |
| data.isDataCollectionEnabled | Integer | 是否可数采（0-否，1-是） |
| data.offlineDuration | Integer | 设备离线判定时长（秒） |
| data.createTime | OffsetDateTime | 创建时间 |
| data.rssi | Integer | 信号强度 |
| data.snr | BigDecimal | 信噪比 |
| data.sf | Integer | 扩频因子 |
| data.lastGateway | String | 最后网关 |

#### 响应示例

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "deviceId": "2037377921942110208",
    "deviceName": "十楼小会议室",
    "deviceIdentifier": "001a0102ff00057b",
    "deviceTypeId": "2000003",
    "deviceTypeName": "开关面板",
    "deviceTypeCode": "SWITCH_PANEL",
    "tenantId": "1",
    "onlineStatus": 1,
    "onlineStatusName": "在线",
    "lastActiveTime": "2024-01-15T14:20:00+08:00",
    "isControlEnabled": 1,
    "isDataCollectionEnabled": 1,
    "offlineDuration": 300,
    "createTime": "2024-01-15T10:30:00+08:00",
    "rssi": -60,
    "snr": 8.5,
    "sf": 10,
    "lastGateway": "gateway-001"
  }
}
```

---

### 9. 批量获取设备详情

根据多个设备ID批量获取设备详细信息。

#### 接口信息
- **接口路径**: `/feign/v1/device/lifecycle/batchGetDeviceDetails`
- **请求方法**: `POST`
- **接口说明**: 一次性获取多个设备的详细信息，提高查询效率

#### 请求参数

**请求体 (Request Body)**: `BatchDeviceDetailReqDto`

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| deviceIds | List\<String\> | 是 | 设备ID列表 |

#### 请求示例

```json
{
  "deviceIds": ["2037377921942110208", "2037377921942110209"]
}
```

#### 响应结果

**响应类型**: `R<List<DeviceDetailRespDto>>`

| 字段名 | 类型 | 说明 |
|--------|------|------|
| code | Integer | 响应码 |
| msg | String | 响应消息 |
| data | List\<DeviceDetailRespDto\> | 设备详情列表 |
| data[].deviceId | String | 设备ID |
| data[].deviceName | String | 设备名称 |
| data[].deviceIdentifier | String | 设备唯一标识 |
| data[].deviceTypeId | String | 设备类型ID |
| data[].deviceTypeName | String | 设备类型名称 |
| data[].deviceTypeCode | String | 设备类型编码 |
| data[].tenantId | String | 租户ID |
| data[].onlineStatus | Integer | 在线状态值 |
| data[].onlineStatusName | String | 在线状态名称 |
| data[].lastActiveTime | OffsetDateTime | 最后活跃时间 |
| data[].isControlEnabled | Integer | 是否可控制（0-否，1-是） |
| data[].isDataCollectionEnabled | Integer | 是否可数采（0-否，1-是） |
| data[].offlineDuration | Integer | 设备离线判定时长（秒） |
| data[].createTime | OffsetDateTime | 创建时间 |
| data[].rssi | Integer | 信号强度 |
| data[].snr | BigDecimal | 信噪比 |
| data[].sf | Integer | 扩频因子 |
| data[].lastGateway | String | 最后网关 |

#### 响应示例

```json
{
  "code": 200,
  "msg": "success",
  "data": [
    {
      "deviceId": "2037377921942110208",
      "deviceName": "十楼小会议室",
      "deviceIdentifier": "001a0102ff00057b",
      "deviceTypeId": "2000003",
      "deviceTypeName": "开关面板",
      "deviceTypeCode": "SWITCH_PANEL",
      "tenantId": "1",
      "onlineStatus": 1,
      "onlineStatusName": "在线",
      "lastActiveTime": "2024-01-15T14:20:00+08:00",
      "isControlEnabled": 1,
      "isDataCollectionEnabled": 1,
      "offlineDuration": 300,
      "createTime": "2024-01-15T10:30:00+08:00",
      "rssi": -60,
      "snr": 8.5,
      "sf": 10,
      "lastGateway": "gateway-001"
    },
    {
      "deviceId": "2037377921942110209",
      "deviceName": "温湿度传感器-009569000004097a",
      "deviceIdentifier": "009569000004097a",
      "deviceTypeId": "2000002",
      "deviceTypeName": "温湿度传感器",
      "deviceTypeCode": "TEMPERATURE_HUMIDITY",
      "tenantId": "1",
      "onlineStatus": 1,
      "onlineStatusName": "在线",
      "lastActiveTime": "2024-01-15T11:30:00+08:00",
      "isControlEnabled": 0,
      "isDataCollectionEnabled": 1,
      "offlineDuration": 300,
      "createTime": "2024-01-15T11:00:00+08:00",
      "rssi": -55,
      "snr": 9.2,
      "sf": 9,
      "lastGateway": "gateway-002"
    }
  ]
}
```

---

## 数据类型定义

### LoginUser（用户信息）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| userId | String | 用户ID |
| userName | String | 用户名 |
| tenantId | String | 租户ID |

### DeviceRegistrationReqDto（设备注册请求）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| user | LoginUser | 用户信息 |
| deviceIdentifier | String | 设备唯一标识 |
| deviceTypeCode | String | 设备类型标识 |

### DeviceRegistrationRespDto（设备注册响应）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| deviceId | String | 设备ID |
| deviceIdentifier | String | 设备唯一标识 |
| deviceTypeId | String | 设备类型ID |
| status | String | 设备状态 |
| createTime | LocalDateTime | 注册时间 |

### BatchDeviceRegistrationReqDto（批量设备注册请求）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| user | LoginUser | 用户信息 |
| deviceRegistrationReqDtoList | List\<DeviceRegistrationReqDto\> | 设备注册请求列表 |

### BatchDeviceRegistrationRespDto（批量设备注册响应）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| successCount | int | 成功注册数量 |
| failCount | int | 失败数量 |
| successList | List\<DeviceRegistrationRespDto\> | 注册成功的设备列表 |
| failList | List\<FailedDeviceInfo\> | 注册失败的设备信息列表 |

### FailedDeviceInfo（注册失败的设备信息）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| deviceIdentifier | String | 设备唯一标识 |
| reason | String | 失败原因 |

### DeviceUpdateReqDto（设备更新请求）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| user | LoginUser | 用户信息 |
| deviceId | String | 设备ID |
| deviceName | String | 设备名称 |

### DeviceRemoveReqDto（设备删除请求）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| user | LoginUser | 用户信息 |
| deviceIds | List\<String\> | 设备ID列表（支持批量删除） |

### BatchSyncDeviceToIotReqDto（批量同步设备请求）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| devices | List\<DeviceInfo\> | 设备信息列表 |

### DeviceInfo（同步设备信息）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| deviceIdentifier | String | 设备标识 |
| deviceTypeId | String | 设备类型ID |

### DevicePageReqDto（设备分页查询请求，继承自 Query）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| tenantId | String | 租户ID |
| userId | String | 用户ID |
| keyword | String | 搜索关键字（搜索deviceName和deviceIdentifier） |
| current | Integer | 当前页码（继承自Query） |
| size | Integer | 每页大小（继承自Query） |

### DeviceListReqDto（设备列表查询请求，不分页）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| tenantId | String | 租户ID |
| userId | String | 用户ID |
| keyword | String | 搜索关键字（搜索deviceName和deviceIdentifier） |

### DevicePageRespDto（设备分页查询响应）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| total | Long | 总记录数 |
| current | Integer | 当前页码 |
| pageSize | Integer | 每页大小 |
| records | List\<DeviceDetailRespDto\> | 设备列表 |

### DeviceDetailReqDto（设备详情请求）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| deviceId | String | 设备ID |

### BatchDeviceDetailReqDto（批量设备详情请求）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| deviceIds | List\<String\> | 设备ID列表 |

### DeviceDetailRespDto（设备详情响应）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| deviceId | String | 设备ID |
| deviceName | String | 设备名称 |
| deviceIdentifier | String | 设备唯一标识 |
| deviceTypeId | String | 设备类型ID |
| deviceTypeName | String | 设备类型名称 |
| deviceTypeCode | String | 设备类型编码 |
| tenantId | String | 租户ID |
| onlineStatus | Integer | 在线状态值 |
| onlineStatusName | String | 在线状态名称 |
| lastActiveTime | OffsetDateTime | 最后活跃时间 |
| isControlEnabled | Integer | 是否可控制（0-否，1-是） |
| isDataCollectionEnabled | Integer | 是否可数采（0-否，1-是） |
| offlineDuration | Integer | 设备离线判定时长（秒） |
| createTime | OffsetDateTime | 创建时间 |
| rssi | Integer | 信号强度 |
| snr | BigDecimal | 信噪比 |
| sf | Integer | 扩频因子 |
| lastGateway | String | 最后网关 |

---

## 错误码说明

| 错误码 | 说明 |
|--------|------|
| 200 | 请求成功 |
| 400 | 请求参数错误 |
| 401 | 未授权 |
| 403 | 禁止访问 |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |

---

## 注意事项

1. **内部接口**: 所有接口都使用 `@Inner` 注解，表示这些是内部服务间调用的接口，不对外暴露
2. **参数验证**: 所有请求参数都使用 `@Valid` 进行验证，确保数据完整性
3. **统一响应**: 所有接口都返回统一的 `R<T>` 响应格式
4. **租户隔离**: 涉及用户操作的接口都需要传递 `LoginUser` 对象，包含租户信息
5. **逻辑删除**: 设备删除采用逻辑删除方式，数据不会真正从数据库中移除
6. **批量删除**: 设备删除接口支持批量操作，通过 `deviceIds` 列表传入多个设备ID
7. **分页继承**: `DevicePageReqDto` 继承自 `Query` 类，`current` 和 `size` 字段由父类提供

---

## 附录：设备类型编码参考

| 设备类型编码 | 设备类型名称 |
|-------------|------------|
| RUMEN_CAPSULE | 瘤胃胶囊 |
| TEMPERATURE_HUMIDITY | 温湿度传感器 |
| SWITCH_PANEL | 开关面板 |
| AIR_SWITCH | 空气开关 |
| SMOKE_DETECTOR | 烟感传感器 |
| DOOR_SENSOR | 门磁传感器 |
| GEOMAGNETIC | 地磁传感器 |
| OVERFLOW_SENSOR | 垃圾溢满传感器 |
| CARBON_MONOXIDE | 一氧化碳传感器 |
| AIR_QUALITY | 空气质量传感器 |
| CATTLE_TRACKER | 牛羊追踪器 |

---

**文档版本**: v1.1  
**最后更新**: 2026-04-16  
**维护团队**: 设备中台团队
