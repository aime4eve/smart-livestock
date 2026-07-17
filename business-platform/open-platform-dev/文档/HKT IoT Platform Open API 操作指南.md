# HKT IoT Platform Open API 操作指南

**文档版本：** V5.7
**发布日期：** 2026-05-29

---

## 目录

- [HKT IoT Platform Open API 操作指南](#hkt-iot-platform-open-api-操作指南)
  - [目录](#目录)
  - [1. 快速入门](#1-快速入门)
    - [1.1 文档说明](#11-文档说明)
    - [1.2 环境准备](#12-环境准备)
      - [1.2.1 获取配置信息](#121-获取配置信息)
      - [1.2.2 网络配置检查](#122-网络配置检查)
      - [1.2.3 文档准备](#123-文档准备)
    - [1.3 快速开始](#13-快速开始)
      - [步骤1：创建API-KEY](#步骤1创建api-key)
      - [步骤2：调用业务API](#步骤2调用业务api)
      - [步骤3：查看响应](#步骤3查看响应)
  - [2. API基础](#2-api基础)
    - [2.1 整体调用流程](#21-整体调用流程)
    - [2.2 API请求格式](#22-api请求格式)
      - [2.2.1 请求基础信息](#221-请求基础信息)
      - [2.2.2 公共请求头](#222-公共请求头)
      - [2.2.3 请求方法](#223-请求方法)
      - [2.2.4 ID和参数规范](#224-id和参数规范)
    - [2.3 权限与 HTTP 方法](#23-权限与-http-方法)
    - [2.4 API响应格式](#24-api响应格式)
      - [2.4.1 成功响应](#241-成功响应)
      - [2.4.2 错误响应](#242-错误响应)
  - [3. API-KEY 管理](#3-api-key-管理)
    - [3.1 创建API-KEY](#31-创建api-key)
    - [3.2 使用API-KEY](#32-使用api-key)
    - [3.3 查看API-KEY列表](#33-查看api-key列表)
    - [3.4 轮换API-KEY](#34-轮换api-key)
    - [3.5 撤销API-KEY](#35-撤销api-key)
  - [4. 空间管理](#4-空间管理)
    - [4.1 创建根空间](#41-创建根空间)
    - [4.2 创建子空间](#42-创建子空间)
    - [4.3 查询空间列表](#43-查询空间列表)
    - [4.4 查询单个空间详情](#44-查询单个空间详情)
    - [4.5 更新空间](#45-更新空间)
    - [4.6 删除空间](#46-删除空间)
  - [5. 设备管理](#5-设备管理)
    - [5.1 注册设备](#51-注册设备)
    - [5.2 查询设备列表](#52-查询设备列表)
    - [5.3 查询设备详情](#53-查询设备详情)
    - [5.4 更新设备](#54-更新设备)
    - [5.5 删除设备](#55-删除设备)
  - [6. 设备命令](#6-设备命令)
    - [6.1 发送设备命令](#61-发送设备命令)
    - [6.2 查询命令状态](#62-查询命令状态)
    - [6.3 设备命令参考](#63-设备命令参考)
      - [6.3.1 门锁命令清单](#631-门锁命令清单)
        - [1. RemoteOpenClose — 远程开关锁 (0x2F)](#1-remoteopenclose--远程开关锁-0x2f)
        - [2. ManageTmpPwd — 临时密码 (0x32)](#2-managetmppwd--临时密码-0x32)
        - [3. ManagePwd — 管理密码（带时效）(0x4E)](#3-managepwd--管理密码带时效0x4e)
        - [4. ManageCard — 管理 MF 卡（带时效）(0x4F)](#4-managecard--管理-mf-卡带时效0x4f)
        - [5. NormallyOpenModeSetting — 常开模式设置 (0x52)](#5-normallyopenmodesetting--常开模式设置-0x52)
        - [6. LockBackTimeSetting — 门锁自动回锁时间 (0x53)](#6-lockbacktimesetting--门锁自动回锁时间-0x53)
        - [7. SyncTimestamp — 同步时间戳 (0x54)](#7-synctimestamp--同步时间戳-0x54)
        - [8. UserBindingStatusSetting — 用户绑定状态 (0x56)](#8-userbindingstatussetting--用户绑定状态-0x56)
        - [9. VolumeSetting — 音量设置 (0x57)](#9-volumesetting--音量设置-0x57)
        - [10. RestoreDefaultFactorySettings — 恢复出厂设置 (0x85)](#10-restoredefaultfactorysettings--恢复出厂设置-0x85)
        - [11. DataSyncPeriodSetting — 数据同步周期 (0x86)](#11-datasyncperiodsetting--数据同步周期-0x86)
        - [12. TimezoneSetting — 时区设置 (0x8A)](#12-timezonesetting--时区设置-0x8a)
      - [6.3.2 其他设备命令清单](#632-其他设备命令清单)
        - [燃气表](#燃气表)
          - [1. 设置燃气单价 (gasUnitPrice)](#1-设置燃气单价-gasunitprice)
          - [2. 燃气充值 (gasCharge)](#2-燃气充值-gascharge)
          - [3. 设置燃气用量 (gasUsage)](#3-设置燃气用量-gasusage)
          - [4. 设置燃气余量 (gasSurplus)](#4-设置燃气余量-gassurplus)
          - [5. 设置燃气余额 (gasBalance)](#5-设置燃气余额-gasbalance)
          - [6. 阀门控制 (valveControl)](#6-阀门控制-valvecontrol)
        - [暖气控制阀](#暖气控制阀)
          - [1. 设置目标温度 (SetTargetTemperature)](#1-设置目标温度-settargettemperature)
          - [2. 设置阀门开度 (SetValveOpening)](#2-设置阀门开度-setvalveopening)
        - [车位锁](#车位锁)
          - [1. 锁控制 (LockControl)](#1-锁控制-lockcontrol)
        - [开关面板](#开关面板)
          - [1. 开关控制 (SwitchControl)](#1-开关控制-switchcontrol)
        - [声光报警器](#声光报警器)
          - [1. 报警控制 (AlarmControl)](#1-报警控制-alarmcontrol)
        - [空开物模型](#空开物模型)
          - [1. 空开开关控制 (CtrlAirSwitchOnOff)](#1-空开开关控制-ctrlairswitchonoff)
        - [电表](#电表)
          - [1. 阀门控制 (ValveControl)](#1-阀门控制-valvecontrol)
          - [2. 远程充值 (RemoteRecharge)](#2-远程充值-remoterecharge)
        - [水表](#水表)
          - [1. 阀门控制 (ValveControl)](#1-阀门控制-valvecontrol-1)
        - [超声波水表](#超声波水表)
          - [1. 阀门控制 (ValveControl)](#1-阀门控制-valvecontrol-2)
          - [2. 设置计量模式 (SetMeteringMode)](#2-设置计量模式-setmeteringmode)
          - [3. 设置脉冲常数 (SetPulseConstant)](#3-设置脉冲常数-setpulseconstant)
  - [7. 安全建议与常见问题](#7-安全建议与常见问题)
    - [7.1 安全建议](#71-安全建议)
    - [7.2 常见问题](#72-常见问题)
  - [8. 附录：完整集成流程示例](#8-附录完整集成流程示例)
  - [9. 文档说明与规范](#9-文档说明与规范)
  - [10. 技术支持](#10-技术支持)

---

## 1. 快速入门

### 1.1 文档说明

本文档旨在帮助开发者快速上手使用 HKT IoT Platform Open API，完成设备接入、空间管理和设备控制等功能。

**适用对象：**
- 集成开发工程师
- 技术负责人
- 合作伙伴技术团队

---

### 1.2 环境准备

在开始使用API之前，请完成以下准备工作：

#### 1.2.1 获取配置信息

请联系您的销售代表或项目负责人获取以下配置信息：

1. **HKT LoRaWAN Network-Service 配置**
   - 服务器IP地址和端口号

2. **HKT IoT Platform Open API 配置**
   - Base-URL（例如 `https://<host>/`）


3. **应用凭证**
   - 应用ID（`appId`）
   - 应用密钥（`appSecret`）

#### 1.2.2 网络配置检查

请确保完成以下网络配置：

- **LoRaWAN 网络配置**：确保您的LoRaWAN网关可以访问HKT LoRaWAN Network-Service服务器，必要时配置防火墙规则。
- **Open API 网络配置**：确保您的网络可以访问HKT IoT Platform Open API Base-URL，必要时配置防火墙规则。

#### 1.2.3 文档准备

请确保已阅读并了解《HKT IoT Platform Open API — Customer Integration Guide》文档。

---

**⚠️ 安全提醒：**
- `appId` 和 `appSecret` 仅用于创建和管理API-KEY
- 不要在日常业务API调用中使用这两个凭证
- 请勿将 `appSecret` 记录在日志中或提交到代码仓库
- 请妥善保管所有配置信息

---

### 1.3 快速开始

本章节将引导您在5分钟内完成第一个API调用。

#### 步骤1：创建API-KEY

首先，使用您的 `appId` 和 `appSecret` 创建一个API-KEY：

```http
POST /v1/api-keys
Authorization: Basic <base64(appId + ":" + appSecret)>
Content-Type: application/json

{
  "scope": "read_write",
  "description": "快速开始测试",
  "expires_in_days": 30
}
```

**响应示例（201 Created）：**
```json
{
  "key_id": "12345",
  "api_key": "ak_live_abc123xyz456...",
  "description": "快速开始测试",
  "scope": "read_write",
  "expires_at": "2026-06-28T12:00:00Z",
  "created_at": "2026-05-29T12:00:00Z"
}
```

**⚠️ 重要：** `api_key` 只会在创建时显示一次，请立即安全保存！

#### 步骤2：调用业务API

使用刚才创建的API-KEY，查询空间列表：

```http
GET /v1/spaces?page=1&pageSize=10
X-API-Key: ak_live_abc123xyz456...
```

#### 步骤3：查看响应

您将收到类似以下的响应：

```json
{
  "data": [],
  "total": 0,
  "page": 1,
  "pageSize": 10
}
```

恭喜！您已成功完成第一个API调用。接下来请阅读后续章节了解更多功能。

---

## 2. API基础

### 2.1 整体调用流程

Open API调用的完整流程如下：

```
1. 获取应用凭证（appId + appSecret）
   ↓
2. 使用 appId + appSecret 创建 API-KEY
   ↓
3. 使用 API-KEY 调用业务 API（空间/设备/命令等）
   ↓
4. 处理 API 响应
```

**详细步骤说明：**

1. **准备阶段**：完成环境准备，获取 `appId` 和 `appSecret`
2. **认证阶段**：使用 `appId` 和 `appSecret` 通过 HTTP Basic Auth 调用 `/v1/api-keys` 接口创建 API-KEY
3. **业务调用阶段**：使用 API -KEY（通过 `X-API-Key` 或 `Authorization: Bearer` 请求头）调用各个业务 API
4. **结果处理阶段**：解析 API 响应，处理业务数据或错误信息

---

### 2.2 API请求格式

#### 2.2.1 请求基础信息

- **Base URL**：`{HKT_IoT_Platform_Open_API_Base_URL}`
- **协议**：HTTPS
- **字符编码**：UTF-8
- **Content-Type**：`application/json`（请求体）

#### 2.2.2 公共请求头

| 请求头 | 说明 | 示例 |
|--------|------|------|
| `Content-Type` | 请求体类型，固定为 `application/json` | `application/json` |
| `X-API-Key` | API-KEY（业务 API 调用使用） | `ak_live_abc123xyz456...` |
| `Authorization` | 认证方式（二选一）：<br>- Basic Auth（用于 API-KEY 管理）<br>- Bearer Token（业务 API 调用使用） | `Basic YXBwSWQ6YXBwU2VjcmV0`<br>`Bearer ak_live_abc123xyz456...` |
| `X-Trace-Id` | 追踪 ID，用于问题排查（可选） | `trace-123456` |

#### 2.2.3 请求方法

| 方法 | 说明 |
|------|------|
| `GET` | 查询资源 |
| `POST` | 创建资源或发送命令 |
| `PUT` | 更新资源 |
| `DELETE` | 删除资源（需要 `admin` 权限） |

#### 2.2.4 ID和参数规范

**Numeric IDs**：外部 ID（`device_id`、`space_id`、`parent_id`、设备列表查询中的 `spaceId` 等）均为**十进制数字符串**，**1-21个字符**（不含字母）。

**通用查询参数**：

| 参数 | 类型 | 必填 | 说明 | 示例 |
|------|------|------|------|------|
| `page` | Integer | 否 | 页码，默认 1 | `page=1` |
| `pageSize` | Integer | 否 | 每页数量，默认 20，最大 200 | `pageSize=20` |

**可选过滤器**：不需要的查询参数可以省略。

---

### 2.3 权限与 HTTP 方法

| scope | 允许的 HTTP 方法 |
| --- | --- |
| read | GET |
| write | POST、PUT |
| read_write | GET、POST、PUT |
| admin | GET、POST、PUT、DELETE |

**重要提示：** 删除设备、删除空间需要 `admin` 权限。权限不足时返回 **403 Forbidden**。

---

### 2.4 API响应格式

#### 2.4.1 成功响应

**列表查询响应（分页，以下以空间列表为例）：**
```json
{
  "data": [
    {
      "space_id": "1",
      "name": "示例空间",
      "parent_id": null,
      "root_id": "1",
      "created_at": "2026-05-29T12:00:00Z"
    }
  ],
  "total": 100,
  "page": 1,
  "pageSize": 20
}
```

**单个资源响应（以下以空间详情为例）：**
```json
{
  "space_id": "1",
  "name": "示例空间",
  "parent_id": null,
  "root_id": "1",
  "created_at": "2026-05-29T12:00:00Z"
}
```

**创建成功响应（以下以空间创建为例）：**
```json
{
  "space_id": "2",
  "name": "新创建的空间",
  "parent_id": "1",
  "root_id": "1",
  "created_at": "2026-05-29T12:00:00Z"
}
```

#### 2.4.2 错误响应

```json
{
  "error": "ERROR_CODE",
  "details": "错误详细描述",
  "request_id": "trace-123456"
}
```

**常见错误码：**

| HTTP状态码 | 错误码 | 说明 |
|------------|--------|------|
| 400 | `INVALID_REQUEST` | 请求参数错误 |
| 400 | `INVALID_SN` | 无效的设备序列号 |
| 400 | `INVALID_SPACE` | 无效的空间 |
| 401 | `UNAUTHORIZED` | 未授权或认证失败 |
| 401 | `KEY_EXPIRED` | API-KEY 已过期 |
| 403 | `FORBIDDEN` | 权限不足 |
| 404 | `NOT_FOUND` | 资源不存在 |

---

## 3. API-KEY 管理

### 3.1 创建API-KEY

使用 `appId` 和 `appSecret` 创建API-KEY：

```http
POST /v1/api-keys
Authorization: Basic <base64(appId + ":" + appSecret)>
Content-Type: application/json

{
  "scope": "read_write",
  "description": "智慧建筑应用API-KEY",
  "expires_in_days": 365
}
```

**请求参数说明：**

| 参数 | 必需 | 说明 |
|------|------|------|
| `scope` | 是 | 权限范围：`read`、`write`、`read_write`、`admin` |
| `description` | 否 | 描述，最多100字符 |
| `expires_in_days` | 否 | 有效期（1-3650天），不填则永久有效 |

**响应示例：**

```json
{
  "key_id": "12345",
  "api_key": "ak_live_abc123xyz456...",
  "description": "智慧建筑应用API-KEY",
  "scope": "read_write",
  "expires_at": "2027-05-29T12:00:00Z",
  "created_at": "2026-05-29T12:00:00Z"
}
```

**⚠️ 重要：** `api_key` 只会在创建时显示一次，请立即安全保存！

### 3.2 使用API-KEY

除了 `/v1/api-keys` 路径外，所有其他API调用都使用API-KEY进行认证，有两种方式：

**方式一：使用 X-API-Key 请求头**
```http
GET /v1/spaces
X-API-Key: ak_live_abc123xyz456...
```

**方式二：使用 Authorization Bearer 请求头**
```http
GET /v1/spaces
Authorization: Bearer ak_live_abc123xyz456...
```

### 3.3 查看API-KEY列表

```http
GET /v1/api-keys?page=1&pageSize=20
Authorization: Basic <base64(appId + ":" + appSecret)>
```

**响应示例：**
```json
{
  "data": [
    {
      "key_id": "12345",
      "description": "智慧建筑应用API-KEY",
      "scope": "read_write",
      "status": "active",
      "expires_at": "2027-05-29T12:00:00Z",
      "last_used_at": "2026-05-29T12:30:00Z",
      "created_at": "2026-05-29T12:00:00Z"
    }
  ],
  "total": 1,
  "page": 1,
  "pageSize": 20
}
```

### 3.4 轮换API-KEY

定期轮换API-KEY是良好的安全实践：

```http
PUT /v1/api-keys/{key_id}/rotate
Authorization: Basic <base64(appId + ":" + appSecret)>
```

响应会返回新的 `api_key`。

### 3.5 撤销API-KEY

如果API-KEY泄露或不再需要，请立即撤销：

```http
DELETE /v1/api-keys/{key_id}
Authorization: Basic <base64(appId + ":" + appSecret)>
```

---

## 4. 空间管理

空间（Spaces）代表设备的安装位置，以树形结构组织。

### 4.1 创建根空间

```http
POST /v1/spaces
X-API-Key: <your_api_key>
Content-Type: application/json

{
  "name": "华沙总部大楼"
}
```

### 4.2 创建子空间

```http
POST /v1/spaces
X-API-Key: <your_api_key>
Content-Type: application/json

{
  "name": "3楼数据中心",
  "parent_id": "1"
}
```

**说明：** `parent_id` 是父空间的ID，不传则创建根空间。

### 4.3 查询空间列表

```http
GET /v1/spaces?page=1&pageSize=20
X-API-Key: <your_api_key>
```

支持的查询参数：
- `name`：按名称过滤
- `parent_id`：按父空间ID过滤（查询某空间的子空间）

### 4.4 查询单个空间详情

```http
GET /v1/spaces/{space_id}
X-API-Key: <your_api_key>
```

**响应示例：**
```json
{
  "space_id": "1",
  "name": "华沙总部大楼",
  "parent_id": null,
  "root_id": "1",
  "created_at": "2026-05-29T12:00:00Z"
}
```

### 4.5 更新空间

```http
PUT /v1/spaces/{space_id}
X-API-Key: <your_api_key>
Content-Type: application/json

{
  "name": "华沙总部大楼（新名称）",
  "parent_id": "2"
}
```

### 4.6 删除空间

⚠️ 需要 `admin` 权限：

```http
DELETE /v1/spaces/{space_id}
X-API-Key: <your_api_key>
```

---

## 5. 设备管理

### 5.1 注册设备

```http
POST /v1/devices
X-API-Key: <your_api_key>
Content-Type: application/json

{
  "sn": "SN123456789",
  "name": "温湿度传感器-001",
  "spaceId": "2"
}
```

**请求参数说明：**

| 参数 | 必需 | 说明 |
|------|------|------|
| `sn` | 是 | 设备序列号/许可证，最多100字符 |
| `name` | 否 | 设备显示名称 |
| `spaceId` | 否 | 绑定的空间ID |

### 5.2 查询设备列表

```http
GET /v1/devices?page=1&pageSize=20
X-API-Key: <your_api_key>
```

支持的查询参数：
- `keyword`：按关键词搜索设备
- `spaceId`：按空间ID过滤（查询某空间下的设备）

**示例：查询某空间下的设备**
```http
GET /v1/devices?spaceId=2&page=1&pageSize=20
X-API-Key: <your_api_key>
```

### 5.3 查询设备详情

```http
GET /v1/devices/{device_id}
X-API-Key: <your_api_key>
```

**响应示例：**
```json
{
  "device_id": "1001",
  "name": "温湿度传感器-001",
  "type": "temperature_humidity",
  "type_name": "温湿度传感器",
  "status": "online",
  "status_code": 1,
  "created_at": "2026-05-29T12:00:00Z",
  "last_active_at": "2026-05-29T14:30:00Z",
  "identifier": "device-001",
  "rssi": -65,
  "snr": 25
}
```

### 5.4 更新设备

```http
PUT /v1/devices/{device_id}
X-API-Key: <your_api_key>
Content-Type: application/json

{
  "name": "温湿度传感器-001（新名称）"
}
```

### 5.5 删除设备

⚠️ 需要 `admin` 权限：

```http
DELETE /v1/devices/{device_id}
X-API-Key: <your_api_key>
```

---

## 6. 设备命令

### 6.1 发送设备命令

```http
POST /v1/devices/{device_id}/commands
X-API-Key: <your_api_key>
Content-Type: application/json

{
  "func": {
    "method": "YOUR_FUNCTION_NAME"
  }
}
```

**说明：**
- `device_id`：目标设备ID（十进制数字符串，1-21字符）
- `func.method`：设备功能 / 指令名称（具体参数设置参考“6.3 设备命令参考“章节）
- `func.params`：可选，指令参数（JSON 对象，依功能而定）

**带参数的命令示例（以门锁 `RemoteOpenClose` 为例）：**
```http
POST /v1/devices/{device_id}/commands
X-API-Key: <your_api_key>
Content-Type: application/json

{
  "func": {
    "method": "RemoteOpenClose",
    "params": {
      "lockControl": 1
    }
  }
}
```

**响应示例：**
```json
{
  "total_count": 1,
  "success_count": 1,
  "fail_count": 0,
  "success_list": [
    {
      "record_id": "54321",
      "device_id": "1001"
    }
  ],
  "fail_list": []
}
```

**重要：** 请保存 `success_list[].record_id`，用于后续查询命令状态。

---

### 6.2 查询命令状态

使用发送命令时返回的 `record_id` 查询执行状态：

```http
GET /v1/commands/{command_id}/status
X-API-Key: <your_api_key>
```

**路径参数：**
- `command_id`：即之前返回的 `record_id`（十进制数字符串，1-21字符）

**响应示例（使用 snake_case）：**
```json
{
  "record_id": "54321",
  "device_id": "1001",
  "func_name": "RemoteOpenClose",
  "func_params": "{\"lockControl\":1}",
  "cmd_state": 1,
  "cmd_state_text": "成功",
  "error_msg": null,
  "create_time": "2026-05-29T14:00:00Z",
  "operator_name": "API调用"
}
```

**响应字段详细说明：**

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| record_id | string | 记录 ID |
| device_id | string | 设备 ID |
| func_name | string | 命令名称 |
| func_params | string | 命令参数 |
| cmd_state | integer | 状态码（见下表） |
| cmd_state_text | string | 状态描述 |
| error_msg | string | 失败原因 |
| create_time | string | 操作时间（日期时间） |
| operator_name | string | 操作人显示名称 |

**命令状态码说明：**

| 状态码 | 说明 |
|--------|------|
| -1 | 待发送 |
| 0 | 下发中 |
| 1 | 成功 |
| 2 | 失败 |
| 3 | 超时 |
| 4 | 待重试 |
| 5 | 过期 |

---

### 6.3 设备命令参考

#### 6.3.1 门锁命令清单

##### 1. RemoteOpenClose — 远程开关锁 (0x2F)

**功能**：远程控制门锁的开启或关闭。

**JSON 示例**：

```json
{
  "func": {
    "method": "RemoteOpenClose",
    "params": {
      "lockControl": 1
    }
  }
}
```

**参数说明**：

| 参数 | 类型 | 说明 | 约束 |
|------|------|------|------|
| lockControl | int | 0=远程开锁，1=远程关锁 | 必填，仅允许 0 或 1 |

---

##### 2. ManageTmpPwd — 临时密码 (0x32)

**功能**：下发临时开锁密码，可设置有效期。

**JSON 示例**：

```json
{
  "func": {
    "method": "ManageTmpPwd",
    "params": {
      "validDuration": 30,
      "pwd": "123456"
    }
  }
}
```

**参数说明**：

| 参数 | 类型 | 说明 | 约束 |
|------|------|------|------|
| validDuration | int | 有效期（单位：分钟，最大 24 小时） | 必填，范围 1~1440 |
| pwd | string | 临时密码 | 必填，长度 6~8 位数字 |

---

##### 3. ManagePwd — 管理密码（带时效）(0x4E)

**功能**：管理用户密码（新增/修改、删除、读取），支持时效和有效次数限制。

**JSON 示例**：

**新增/修改（operation = 0）**

```json
{
  "func": {
    "method": "ManagePwd",
    "params": {
      "operation": 0,
      "userNo": 1,
      "pwdStatus": 1,
      "pwd": "12345678",
      "validStartTime": 1704038400,
      "validEndTime": 1706716800,
      "validUnlockCount": 0
    }
  }
}
```

**删除（operation = 1）**

```json
{
  "func": {
    "method": "ManagePwd",
    "params": {
      "operation": 1,
      "userNo": 1
    }
  }
}
```

**读取（operation = 2）**

```json
{
  "func": {
    "method": "ManagePwd",
    "params": {
      "operation": 2,
      "userNo": 1
    }
  }
}
```

**参数说明**：

| 参数 | 类型 | 说明 | 约束 |
|------|------|------|------|
| operation | int | 0=新增/修改，1=删除，2=读取 | 必填，0/1/2 |
| userNo | int | 用户编号 | 必填，0=超级管理员，1~100=普通用户，101~200=蓝牙用户 |
| pwdStatus | int | 密码状态（新增时必填） | 0=冻结，1=生效 |
| pwd | string | 密码（新增时必填） | 长度 6~8 位 |
| validStartTime | int | 有效起始时间（Unix 秒，格林时间） | 必填 |
| validEndTime | int | 有效结束时间（Unix 秒，格林时间） | 必填 |
| validUnlockCount | int | 密码开锁有效次数 | 0=无次数限制，>0=限定次数 |

---

##### 4. ManageCard — 管理 MF 卡（带时效）(0x4F)

**功能**：管理 IC 卡/门禁卡，支持时效和有效次数限制。

**JSON 示例**：

**新增/修改（operation = 0）**

```json
{
  "func": {
    "method": "ManageCard",
    "params": {
      "operation": 0,
      "userNo": 1,
      "cardStatus": 1,
      "cardNo": "01020304",
      "cardKey": "01020304050607080102030405060708",
      "validStartTime": 1704038400,
      "validEndTime": 1706716800,
      "validUnlockCount": 0
    }
  }
}
```

**删除（operation = 1）**

```json
{
  "func": {
    "method": "ManageCard",
    "params": {
      "operation": 1,
      "userNo": 1
    }
  }
}
```

**读取（operation = 2）**

```json
{
  "func": {
    "method": "ManageCard",
    "params": {
      "operation": 2,
      "userNo": 1
    }
  }
}
```

**参数说明**：

| 参数 | 类型 | 说明 | 约束 |
|------|------|------|------|
| operation | int | 0=新增/修改，1=删除，2=读取 | 必填 |
| userNo | int | 用户编号 | 1~100 |
| cardStatus | int | 卡状态（新增时必填） | 0=冻结，1=生效 |
| cardNo | string | 卡号（十六进制字符串，不加 0x） | 8 个十六进制字符（4 字节） |
| cardKey | string | 卡密钥（十六进制字符串） | 32 个十六进制字符（16 字节） |
| validStartTime | int | 有效起始时间戳 | 必填 |
| validEndTime | int | 有效结束时间戳 | 必填 |
| validUnlockCount | int | 开锁有效次数 | 0=无限制 |

---

##### 5. NormallyOpenModeSetting — 常开模式设置 (0x52)

**功能**：设置门锁常开模式，支持手动上锁、延时上锁、定时常开三种子模式。

**JSON 示例**：

**模式 0：关闭常开模式**

```json
{
  "func": {
    "method": "NormallyOpenModeSetting",
    "params": {
      "mode": 0
    }
  }
}
```

**模式 1：常开模式1（手动上锁，按 35# 上锁）**

```json
{
  "func": {
    "method": "NormallyOpenModeSetting",
    "params": {
      "mode": 1
    }
  }
}
```

**模式 2：常开模式2（延时自动上锁）**

```json
{
  "func": {
    "method": "NormallyOpenModeSetting",
    "params": {
      "mode": 2,
      "delayLockTime": 1800
    }
  }
}
```

**参数说明**：

| 参数 | 类型 | 说明 | 约束 |
|------|------|------|------|
| mode | int | 0=关闭，1=模式1，2=模式2 | 必填 |
| delayLockTime | int | 延时上锁时间（秒，模式2时必填） | 范围 1~65535 |

---

##### 6. LockBackTimeSetting — 门锁自动回锁时间 (0x53)

**功能**：设置开锁后自动回锁的延迟时间。

**JSON 示例**：

```json
{
  "func": {
    "method": "LockBackTimeSetting",
    "params": {
      "lockBackTime": 5
    }
  }
}
```

**参数说明**：

| 参数 | 类型 | 说明 | 约束 |
|------|------|------|------|
| lockBackTime | int | 自动回锁时间（秒） | 范围 3~30 |

---

##### 7. SyncTimestamp — 同步时间戳 (0x54)

**功能**：同步设备本地时间为服务器时间，或读取设备当前时间。

**JSON 示例**：

```json
{
  "func": {
    "method": "SyncTimestamp",
    "params": {
      "timestamp": 1704038400
    }
  }
}
```

**参数说明**：

| 参数 | 类型 | 说明 | 约束 |
|------|------|------|------|
| timestamp | int | Unix 时间戳（秒，格林时间） | 时间戳 |

---

##### 8. UserBindingStatusSetting — 用户绑定状态 (0x56)

**功能**：设置设备与平台的绑定状态。

**JSON 示例**：

```json
{
  "func": {
    "method": "UserBindingStatusSetting",
    "params": {
      "userBindingStatus": 1
    }
  }
}
```

**参数说明**：

| 参数 | 类型 | 说明 | 约束 |
|------|------|------|------|
| userBindingStatus | int | 0=未绑定，1=已绑定 | 必填，仅允许 0 或 1 |

---

##### 9. VolumeSetting — 音量设置 (0x57)

**功能**：设置设备音量百分比。

**JSON 示例**：

```json
{
  "func": {
    "method": "VolumeSetting",
    "params": {
      "volume": 80
    }
  }
}
```

**参数说明**：

| 参数 | 类型 | 说明 | 约束 |
|------|------|------|------|
| volume | int | 音量百分比 | 范围 0~100 |

---

##### 10. RestoreDefaultFactorySettings — 恢复出厂设置 (0x85)

**功能**：将设备恢复至出厂默认状态（仅未绑定状态下可用）。

**JSON 示例**：

```json
{
  "func": {
    "method": "RestoreDefaultFactorySettings",
    "params": {}
  }
}
```

**参数说明**：无参数。

---

##### 11. DataSyncPeriodSetting — 数据同步周期 (0x86)

**功能**：设置设备主动向服务器同步状态的间隔时间。

**JSON 示例**：

```json
{
  "func": {
    "method": "DataSyncPeriodSetting",
    "params": {
      "dataSyncPeriod": 1440
    }
  }
}
```

**参数说明**：

| 参数 | 类型 | 说明 | 约束 |
|------|------|------|------|
| dataSyncPeriod | int | 数据同步周期（分钟） | 范围 10~1440，0=不主动同步 |

---

##### 12. TimezoneSetting — 时区设置 (0x8A)

**功能**：设置设备所在时区。

**JSON 示例**：

```json
{
  "func": {
    "method": "TimezoneSetting",
    "params": {
      "timeZone": 8
    }
  }
}
```

**参数说明**：

| 参数 | 类型 | 说明 | 约束 |
|------|------|------|------|
| timeZone | int | 0~12=东0~东12区，13~24=西1~西12区，25=UTC+3.5，26=UTC+5.5 | 范围 0~26 |

**时区对照表**：

| 值 | 含义 | 值 | 含义 |
|----|------|----|------|
| 0 | UTC+0 | 13 | UTC-1 |
| 8 | UTC+8（东八区） | 17 | UTC-11 |
| 25 | UTC+3.5 | 26 | UTC+5.5 |

---

#### 6.3.2 其他设备命令清单

##### 燃气表

###### 1. 设置燃气单价 (gasUnitPrice)

```json
{
  "func": {
    "method": "gasUnitPrice",
    "params": {
      "gasUnitPrice": 3.5
    }
  }
}
```

###### 2. 燃气充值 (gasCharge)

```json
{
  "func": {
    "method": "gasCharge",
    "params": {
      "gasBalance": 200
    }
  }
}
```

###### 3. 设置燃气用量 (gasUsage)

```json
{
  "func": {
    "method": "gasUsage",
    "params": {
      "gasUsage": 50.5
    }
  }
}
```

###### 4. 设置燃气余量 (gasSurplus)

```json
{
  "func": {
    "method": "gasSurplus",
    "params": {
      "gasSurplus": 150.5
    }
  }
}
```

###### 5. 设置燃气余额 (gasBalance)

```json
{
  "func": {
    "method": "gasBalance",
    "params": {
      "gasBalance": 200
    }
  }
}
```

###### 6. 阀门控制 (valveControl)

```json
{
  "func": {
    "method": "valveControl",
    "params": {
      "valveStatus": 0
    }
  }
}
```

| valveStatus | 说明 |
|---------|------|
| 0 | 关阀 |
| 1 | 开阀 |

---

##### 暖气控制阀

###### 1. 设置目标温度 (SetTargetTemperature)

```json
{
  "func": {
    "method": "SetTargetTemperature",
    "params": {
      "targetTemperature": 25.5,
      "temperatureTolerance": 0.5
    }
  }
}
```

###### 2. 设置阀门开度 (SetValveOpening)

```json
{
  "func": {
    "method": "SetValveOpening",
    "params": {
      "valveOpening": 50
    }
  }
}
```

| valveOpening | 说明 |
|--------------|------|
| 0-100 | 阀门开度百分比 |

---

##### 车位锁

###### 1. 锁控制 (LockControl)

```json
{
  "func": {
    "method": "LockControl",
    "params": {
      "lockStatus": 1,
      "bluetoothId": "BT0012345678"
    }
  }
}
```

| lockStatus | 说明 |
|------------|------|
| 1 | 降锁 |
| 2 | 升锁 |
| 3 | APP降锁 |
| 4 | APP升锁 |

---

##### 开关面板

###### 1. 开关控制 (SwitchControl)

```json
{
  "func": {
    "method": "SwitchControl",
    "params": {
      "state": 1
    }
  }
}
```

| state | 说明 |
|-------|------|
| 0 | 关 |
| 1 | 开 |

---

##### 声光报警器

###### 1. 报警控制 (AlarmControl)

```json
{
  "func": {
    "method": "AlarmControl",
    "params": {
      "alarm": 1,
      "alarmTime": 10
    }
  }
}
```

| alarm | 说明 |
|-------|------|
| 0 | 关 |
| 1 | 开 |

| alarmTime | 说明 |
|-----------|------|
| 数值 | 报警时长（秒） |

---

##### 空开物模型

###### 1. 空开开关控制 (CtrlAirSwitchOnOff)

```json
{
  "func": {
    "method": "CtrlAirSwitchOnOff",
    "params": {
      "onOff": 1
    }
  }
}
```

| onOff | 说明 |
|-------|------|
| 0 | 关（合闸） |
| 1 | 开（分闸） |

---

##### 电表

###### 1. 阀门控制 (ValveControl)

```json
{
  "func": {
    "method": "ValveControl",
    "params": {
      "valveStatus": 0
    }
  }
}
```

| valveStatus | 说明 |
|-------------|------|
| 0 | 开阀 |
| 1 | 关阀 |

###### 2. 远程充值 (RemoteRecharge)

```json
{
  "func": {
    "method": "RemoteRecharge",
    "params": {
      "amount": 100.00
    }
  }
}
```

---

##### 水表

###### 1. 阀门控制 (ValveControl)

```json
{
  "func": {
    "method": "ValveControl",
    "params": {
      "valveStatus": 0,
      "meterAddress": "ADDR1234"
    }
  }
}
```

| valveStatus | 说明 |
|-------------|------|
| 0 | 开阀 |
| 1 | 关阀 |

---

##### 超声波水表

###### 1. 阀门控制 (ValveControl)

```json
{
  "func": {
    "method": "ValveControl",
    "params": {
      "valveStatus": 0
    }
  }
}
```

| valveStatus | 说明 |
|-------------|------|
| 0 | 开阀 |
| 1 | 关阀 |
| 2 | 疏通 |

###### 2. 设置计量模式 (SetMeteringMode)

```json
{
  "func": {
    "method": "SetMeteringMode",
    "params": {
      "meteringMode": 0
    }
  }
}
```

| meteringMode | 说明 |
|--------------|------|
| 0 | 双脉冲 |
| 1 | 单脉冲 |
| 2 | 霍尔 |
| 3 | ADC采集 |
| 4 | 光电直读 |

###### 3. 设置脉冲常数 (SetPulseConstant)

```json
{
  "func": {
    "method": "SetPulseConstant",
    "params": {
      "pulseConstant": 1
    }
  }
}
```

| pulseConstant | 说明           |
|---------------|--------------|
| 1 | 1计量脉冲表示1升    |
| 2 | 1计量脉冲表示10升   |
| 3 | 1计量脉冲表示100升  |
| 4 | 1计量脉冲表示1000升 |

---

## 7. 安全建议与常见问题

### 7.1 安全建议

- 不要在日志中记录完整的 API Key 或 `appSecret`。
- 将API Key 或 `appSecret`存入安全的密钥管理系统（如 Vault）。
- 定期轮换 Key（`PUT /v1/api-keys/{key_id}/rotate`），发现泄露立即吊销。

### 7.2 常见问题

**Q：如何获取设备类型对应的功能名称列表？**
A：请参考本文档 [6.3 设备命令参考](#63-设备命令参考) 章节，其中包含了门锁、燃气表、暖气控制阀、车位锁、开关面板、声光报警器、空开物模型、电表、水表、超声波水表等设备的完整命令清单。更多设备类型的功能请联系HKT项目团队获取。

**Q：命令发送后多久可以查询状态？**
A：建议在发送命令后等待2-5秒再查询状态，具体时间取决于设备类型和网络状况。使用返回的 `record_id` 调用 `GET /v1/commands/{record_id}/status` 查询执行状态。

**Q：如何发送设备命令？**
A：使用 `POST /v1/devices/{device_id}/commands` 接口，在请求体的 `func.method` 中指定功能名称，在 `func.params` 中提供参数。具体请参考 [6.3 设备命令参考](#63-设备命令参考) 中的详细示例。

**Q：API调用返回403 Forbidden怎么办？**
A：请检查您的API-KEY权限范围是否足够，删除操作需要 `admin` 权限。发送设备命令通常需要 `write` 或 `read_write` 权限。

**Q：空间可以无限嵌套吗？**
A：API支持父子关系嵌套，但请遵循合理的层级结构设计。

**Q：设备可以同时属于多个空间吗？**
A：不可以，一个设备同一时间只能绑定到一个空间。

---

## 8. 附录：完整集成流程示例

以下是智慧建筑应用场景的完整集成步骤：

1. **接收凭证**：通过安全渠道获取 `appId` 和 `appSecret`
2. **创建API-KEY**：
   
   ```http
   POST /v1/api-keys
   {
     "scope": "read_write",
     "description": "智慧建筑应用项目集成",
     "expires_in_days": 365
   }
   ```
3. **创建空间树**：
   - 创建根空间：`POST /v1/spaces` → `{"name": "波兰区域"}`
   - 创建城市空间：`POST /v1/spaces` → `{"name": "华沙", "parent_id": "1"}`
   - 创建建筑空间：`POST /v1/spaces` → `{"name": "总部大楼", "parent_id": "2"}`
4. **注册设备**：
   ```http
   POST /v1/devices
   {
     "sn": "SN-PL-001",
     "name": "华沙-总部-001",
     "spaceId": "3"
   }
   ```
5. **查询空间下的设备**：
   ```http
   GET /v1/devices?spaceId=3
   ```
6. **发送设备命令**：
   - 发送命令获取 `record_id`
   - 需要时轮询 `GET /v1/commands/{record_id}/status` 查询状态

---

## 9. 文档说明与规范

本文档与约定的客户侧空间模型保持一致：
- **不暴露层级 API**
- **创建空间**使用 `name` + 可选的 `parent_id`（如省略则为顶级空间）
- JSON 中的字段名在定义的地方使用 **snake_case**（`device_id`、`space_id`、`parent_id`、`expires_in_days` 等）；设备注册/列表查询中的 `spaceId` 使用 camelCase

---

## 10. 技术支持

如遇到问题，请联系您的销售代表或项目负责人，并提供以下信息：
- 环境URL
- 请求的API路径和方法
- `request_id` 或 `X-Trace-Id`（如果有）
- 错误信息和请求时间

---

**Copyright © 2026 Hunan HKT Technology Co., Ltd. All Rights Reserved.**
