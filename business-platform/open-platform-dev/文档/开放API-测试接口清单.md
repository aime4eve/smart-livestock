# 开放 API — 测试接口清单（入参 / 出参）

**用途：** 联调 / 测试人员按接口核对请求与响应。  
**Base URL：** `{BASE}` 由环境提供（例：`https://<网关或直连>/`，直连开发常见端口 `8777`）。下文路径均省略前缀，实际为 `{BASE}` + 路径。  
**Content-Type：** 有请求体时为 `application/json`；编码 UTF-8。

---

## 0. 认证说明

| 路径前缀 | 认证方式 |
|----------|----------|
| `/v1/api-keys` | **`Authorization: Basic`**，`Base64(appId + ":" + appSecret)` |
| 其余开放业务接口 | **`X-API-Key: <api_key>`** 或 **`Authorization: Bearer <api_key>`**（勿用 JWT 形态 `ey` 开头冒充 Key） |

**scope 与 HTTP 方法（API Key）：**

| scope | GET | POST | PUT | DELETE |
|-------|-----|------|-----|--------|
| `read` | ✓ | ✗ | ✗ | ✗ |
| `write` | ✗ | ✓ | ✓ | ✗ |
| `read_write` | ✓ | ✓ | ✓ | ✗ |
| `admin` | ✓ | ✓ | ✓ | ✓ |

删除设备、删除空间需要 **`admin`**。

**统一错误体（`ErrorResponse`）：** `error`（错误码字符串）、`details`（说明）、`request_id`（可选，可传请求头 `X-Trace-Id` 便于对齐日志）。

**ID 约定：** 路径/查询中的数字 ID 一般为 **1～21 位纯数字字符串**（`device_id`、`space_id`、`command_id`、`spaceId`、`parent_id` 等）。

---

## 1. API Key 管理（Basic：appId + appSecret）

### 1.1 创建 API Key

| 项 | 内容 |
|----|------|
| **地址** | `POST /v1/api-keys` |
| **认证** | `Authorization: Basic <Base64(appId:appSecret)>` |

**请求体（JSON）**

| 字段 | 必填 | 类型 / 约束 |
|------|------|-------------|
| `scope` | 是 | `read` \| `write` \| `read_write` \| `admin` |
| `description` | 否 | string，最长 100 |
| `expires_in_days` | 否 | int，1～3650；不传表示不按天过期 |

**响应** `201 Created`，JSON：

| 字段 | 类型 | 说明 |
|------|------|------|
| `key_id` | string | Key 业务 ID |
| `api_key` | string | **明文，仅返回一次** |
| `description` | string | |
| `scope` | string | |
| `expires_at` | string (ISO-8601) | 可空 |
| `created_at` | string (ISO-8601) | |

---

### 1.2 列举 API Key

| 项 | 内容 |
|----|------|
| **地址** | `GET /v1/api-keys` |
| **认证** | Basic |

**Query**

| 参数 | 必填 | 默认 | 约束 |
|------|------|------|------|
| `page` | 否 | 1 | 1～1_000_000 |
| `pageSize` | 否 | 20 | 1～200 |

**响应** `200`，分页包装：

| 字段 | 类型 |
|------|------|
| `data` | `KeyInfoVO[]` |
| `total` | number |
| `page` | number |
| `pageSize` | number |

**`data[]` 单项 `KeyInfoVO`**

| 字段 | 类型 |
|------|------|
| `key_id` | string |
| `description` | string |
| `scope` | string |
| `status` | string |
| `expires_at` | string，可空 |
| `last_used_at` | string，可空 |
| `created_at` | string |

---

### 1.3 吊销 API Key

| 项 | 内容 |
|----|------|
| **地址** | `DELETE /v1/api-keys/{key_id}` |
| **认证** | Basic |

**路径参数：** `key_id` — Key 业务 ID（字符串）。

**响应** `200`：

| 字段 | 类型 |
|------|------|
| `key_id` | string |
| `status` | string |

---

### 1.4 轮换 API Key

| 项 | 内容 |
|----|------|
| **地址** | `PUT /v1/api-keys/{key_id}/rotate` |
| **认证** | Basic |

**路径参数：** `key_id`

**响应** `200`：

| 字段 | 类型 |
|------|------|
| `key_id` | string |
| `new_api_key` | string |
| `rotated_at` | string (ISO-8601) |

---

## 2. 空间（API Key）

### 2.1 分页列举空间

| 项 | 内容 |
|----|------|
| **地址** | `GET /v1/spaces` |
| **认证** | API Key（需 GET 权限） |

**Query**

| 参数 | 必填 | 说明 |
|------|------|------|
| `name` | 否 | 筛选名称，最长 100 |
| `parent_id` | 否 | 父空间 ID；空或未传表示不按父级筛 |
| `page` | 否 | 默认 1，1～1_000_000 |
| `pageSize` | 否 | 默认 20，1～200 |

**响应** `200`：`data`（`SpaceVO[]`）、`total`、`page`、`pageSize`。

**`SpaceVO`**

| 字段 | 类型 |
|------|------|
| `space_id` | string |
| `name` | string |
| `parent_id` | string，可空 |
| `root_id` | string，可空 |
| `created_at` | string，可空 |

---

### 2.2 空间详情

| 项 | 内容 |
|----|------|
| **地址** | `GET /v1/spaces/{space_id}` |
| **认证** | API Key（GET） |

**路径：** `space_id` — 1～21 位数字。

**响应** `200`：单个 `SpaceVO`。

---

### 2.3 创建空间

| 项 | 内容 |
|----|------|
| **地址** | `POST /v1/spaces` |
| **认证** | API Key（POST，需 `write`/`read_write`/`admin`） |

**请求体**

| 字段 | 必填 | 说明 |
|------|------|------|
| `name` | 是 | 空间名称，最长 100 |
| `parent_id` | 否 | 上级空间 ID；不传或空串为 **顶级** |

**响应** `201`：`SpaceVO`（创建后一般会再拉详情，字段以实际返回为准）。

---

### 2.4 更新空间

| 项 | 内容 |
|----|------|
| **地址** | `PUT /v1/spaces/{space_id}` |
| **认证** | API Key（PUT） |

**路径：** `space_id`

**请求体**

| 字段 | 必填 | 说明 |
|------|------|------|
| `name` | 是 | 名称，最长 100 |
| `parent_id` | 否 | 上级；空串语义以中台为准 |

**响应** `200`：`SpaceVO`。

---

### 2.5 删除空间

| 项 | 内容 |
|----|------|
| **地址** | `DELETE /v1/spaces/{space_id}` |
| **认证** | API Key（**`admin`**） |

**路径：** `space_id`

**响应** `200`：

| 字段 | 类型 |
|------|------|
| `space_id` | string |
| `deleted` | boolean |

---

## 3. 设备（API Key）

### 3.1 分页列举设备

| 项 | 内容 |
|----|------|
| **地址** | `GET /v1/devices` |
| **认证** | API Key（GET） |

**Query**

| 参数 | 必填 | 说明 |
|------|------|------|
| `keyword` | 否 | 最长 100 |
| `spaceId` | 否 | 按安装空间筛选；数字 ID 或空 |
| `page` | 否 | 默认 1 |
| `pageSize` | 否 | 默认 20，最大 200 |

**响应** `200`：`data`（`DeviceVO[]`）、`total`、`page`、`pageSize`。

**`DeviceVO`**

| 字段 | 类型 |
|------|------|
| `device_id` | string |
| `name` | string |
| `type` | string |
| `type_name` | string |
| `status` | string |
| `status_code` | number |
| `created_at` | string |
| `last_active_at` | string |

---

### 3.2 设备详情

| 项 | 内容 |
|----|------|
| **地址** | `GET /v1/devices/{device_id}` |
| **认证** | API Key（GET） |

**路径：** `device_id`

**响应** `200`：`DeviceDetailVO`（继承 `DeviceVO`，额外字段）：

| 字段 | 类型 |
|------|------|
| `identifier` | string |
| `type_id` | string |
| `control_enabled` | boolean |
| `data_collection_enabled` | boolean |
| `rssi` | number |
| `snr` | number |
| `spreading_factor` | number |
| `last_gateway` | string |

（另含父类 `DeviceVO` 全部字段。）

---

### 3.3 注册设备

| 项 | 内容 |
|----|------|
| **地址** | `POST /v1/devices` |
| **认证** | API Key（POST） |

**请求体**

| 字段 | 必填 | 说明 |
|------|------|------|
| `sn` | 是 | 序列号 / License，最长 100 |
| `name` | 否 | 显示名，最长 100 |
| `spaceId` | 否 | 绑定空间；数字 ID 或空 |

**响应** `201`：

| 字段 | 类型 |
|------|------|
| `device_id` | string |
| `type` | string |
| `type_name` | string |
| `name` | string |
| `status` | string |
| `created_at` | string |

---

### 3.4 更新设备

| 项 | 内容 |
|----|------|
| **地址** | `PUT /v1/devices/{device_id}` |
| **认证** | API Key（PUT） |

**路径：** `device_id`

**请求体**

| 字段 | 必填 | 说明 |
|------|------|------|
| `name` | 否 | 最长 100（若业务要求必填以产品为准） |

**响应** `200`：`DeviceVO`。

---

### 3.5 删除设备

| 项 | 内容 |
|----|------|
| **地址** | `DELETE /v1/devices/{device_id}` |
| **认证** | API Key（**`admin`**） |

**路径：** `device_id`

**响应** `200`：

| 字段 | 类型 |
|------|------|
| `device_id` | string |
| `deleted` | boolean |

---

## 4. 设备命令与控制（API Key）

### 4.1 下发命令

| 项 | 内容 |
|----|------|
| **地址** | `POST /v1/devices/{device_id}/commands` |
| **认证** | API Key（POST） |

**路径：** `device_id` — 目标设备（网关），1～21 位数字。

**请求体（仅接受以下字段；其余 JSON 字段将被忽略）**

| 字段 | 必填 | 说明 |
|------|------|------|
| `func` | 是 | 对象，仅含 `method` |
| `func.method` | 是 | 设备功能名称，最长 100 |

**最简示例：**

```json
{
  "func": {
    "method": "YOUR_FUNCTION_NAME"
  }
}
```

**服务端内部固定（调用方不传、文档不展开）：** `trigger_source` 固定为 `open-api`；`request_id`、`sub_device_ids` 不传；下行配置固定为 `response_timeout=30`、`retry_times=3`、`retry_interval=5`、`try_again_immediately=true`（与中台约定一致，后续如需可调仅改服务端）。

**响应** `200`：

| 字段 | 类型 |
|------|------|
| `total_count` | number |
| `success_count` | number |
| `fail_count` | number |
| `success_list` | 数组，元素见下 |
| `fail_list` | 数组，元素见下 |

**`success_list[]`**

| 字段 | 类型 |
|------|------|
| `record_id` | string | 控制记录 ID，用于 **4.2 查询状态** |
| `command_status` | string |
| `error_message` | string |

**`fail_list[]`**

| 字段 | 类型 |
|------|------|
| `device_id` | string |
| `enqueue` | boolean |
| `wait_for_response` | boolean |
| `func` | string |
| `error_message` | string |

---

### 4.2 查询命令状态

| 项 | 内容 |
|----|------|
| **地址** | `GET /v1/commands/{command_id}/status` |
| **认证** | API Key（GET） |

**路径：** `command_id` — 与下发成功项中的 **`record_id`** 相同（1～21 位数字）。

**响应** `200` — `DeviceCommandStatusVO`：

| 字段 | 类型 | 说明 |
|------|------|------|
| `record_id` | string | |
| `device_id` | string | |
| `trigger_source` | string | 中台：0 手动 / 1 规则 / 2 定时 / 3 API |
| `trigger_source_text` | string | |
| `func_name` | string | |
| `func_params` | string | |
| `cmd_state` | number | 见下表 |
| `cmd_state_text` | string | |
| `error_msg` | string | |
| `create_time` | string | |
| `operator_name` | string | |

**`cmd_state`（中台约定）**

| 值 | 含义 |
|----|------|
| -1 | 待发送 |
| 0 | 下发中 |
| 1 | 成功 |
| 2 | 失败 |
| 3 | 超时 |
| 4 | 待重试 |
| 5 | 过期 |

**记录不存在：** `404`，`error` 一般为 `NOT_FOUND`。

---

### 4.3 未开放接口（预期 404）

以下路由已实现占位，当前固定返回 **404** + 业务说明，**不必作为通过用例**：

| 方法 | 地址 | 说明 |
|------|------|------|
| `PUT` | `/v1/devices/{device_id}/settings` | 设备设置 |
| `DELETE` | `/v1/devices/{device_id}/commands/{command_id}` | 取消命令 |

---

## 5. 参考

- 机器可读契约：`GET {BASE}/v3/api-docs`，Swagger UI：`{BASE}/swagger-ui.html`（若环境已开放）。
- 客户集成说明：`文档/Open-Platform-Customer-Guide.zh-CN.md` / `Open-Platform-Customer-Guide.md`。

---

*文档根据当前 `open-api-service` 代码整理；若与中台/网关实际部署路径不一致，以环境配置为准。*
