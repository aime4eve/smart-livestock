# 开放平台 API — 客户集成指南（中文版）

**读者：** 集成开发与技术人员（可与英文版一并提供给海外客户）。  
**对应英文版：** [Open-Platform-Customer-Guide.md](./Open-Platform-Customer-Guide.md)  
**服务：** `open-api-service` — 基于 HTTP JSON 的 API，提供 **空间（安装位置）**、**设备**、**API Key 生命周期**、**设备命令** 等能力。

---

## 1. 平台能做什么

| 能力 | 说明 |
|------|------|
| **空间（Spaces）** | 将 **安装位置** 建成 **父子树**；**对外不提供单独的「层级类型」能力**。创建空间时只需 **名称** 与可选 **上级空间 ID**（不传则为 **顶级根节点**）；支持列举、详情、更新、删除。 |
| **设备（Devices）** | 按 **SN（序列号）/ License** 注册设备，分页列举与筛选，查看详情，修改显示名称，删除。 |
| **按安装位置查设备** | `GET /v1/devices` 支持可选查询参数 **`spaceId`**，返回属于该空间的设备列表 —— 按你们此前需求增加，便于「在某个安装站点下有哪些设备」。 |
| **设备命令** | 仅需 **设备 ID** + **设备功能名称** 即可下发（`POST /v1/devices/{device_id}/commands`）；各 **设备类型** 下可用功能名称将 **另附文档说明**（后续提供）。按 **`record_id`** 查询状态 **`GET /v1/commands/{command_id}/status`**（已对接）。 |
| **API Key** | 我们为你们下发 **`appId`** + **`appSecret`**；二者 **仅用于** 创建和管理 **API Key**。日常调业务接口一律使用 **API Key**，不要把 app 密钥当作每笔请求的凭证。 |

设备与空间的底层数据由内网中台等服务提供；本服务是对外 **稳定的集成门面**。

---

## 2. 基础地址与文档

- **Base URL：** 按环境由我方提供（例如 `https://<host>/`）。若直连开发实例，配置里默认端口为 **8777**；生产环境通常挂在网关之后。
- **OpenAPI / Swagger UI：** `/swagger-ui.html`（机器可读定义：`/v3/api-docs`）。联调时可对照 Schema 或试用「Try it out」。

**请求体 Content-Type：** `application/json`。**编码：** UTF-8。

---

## 3. 上手流程：从应用凭证到 API Key

### 步骤 A — 我们下发的凭证

我们会创建 **应用（Application）** 并向你方提供：

- **`appId`** — 应用标识（字符串，可视为公开 ID）。
- **`appSecret`** — 密钥，**务必安全保管**，视同密码。

这两者 **不要** 挂在每一笔业务请求上；**只能** 用于路径前缀为 **`/v1/api-keys`** 的接口来签发、轮换、吊销 Key。

### 步骤 B — 使用 HTTP Basic（appId + appSecret）

**仅** 调用 **`/v1/api-keys`** 时：

```http
Authorization: Basic <base64(appId + ":" + appSecret)>
```

示例（示意）：若 `appId` 为 `my-app`，`appSecret` 为 `s3cr3t`，则将字符串 `my-app:s3cr3t` 做 Base64 后放入：

```http
Authorization: Basic bXktYXBwOnMzY3IzdA==
```

失败时返回 JSON，字段见第七节（如 `error`、`details`、`request_id`）。

### 步骤 C — 创建 API Key

```http
POST /v1/api-keys
Authorization: Basic ...
Content-Type: application/json
```

**请求体：**

| 字段 | 必填 | 说明 |
|------|------|------|
| `scope` | 是 | 取值：`read`、`write`、`read_write`、`admin` |
| `description` | 否 | 描述，最长 100 字符 |
| `expires_in_days` | 否 | 过期天数 1～3650；不传表示不按天过期 |

**响应：** `201 Created`，正文示例字段：

| 字段 | 说明 |
|------|------|
| `key_id` | Key 的稳定 ID（吊销、轮换时用） |
| `api_key` | **明文 Key，仅返回这一次。** 请立即保存；服务端只存哈希 |
| `description`、`scope`、`expires_at`、`created_at` | 元数据 |

生成的 Key 通常带配置前缀（如 `ak_live_`）再加随机部分。

### 步骤 D — 其它接口一律带 API Key

除 **`/v1/api-keys`** 外的所有路径，任选一种方式传 Key：

```http
X-API-Key: <你的 api_key>
```

或：

```http
Authorization: Bearer <你的 api_key>
```

说明：若以 `ey` 开头、看起来像 JWT 的 Bearer 串，**不会** 被当作 API Key 解析。

---

## 4. scope 与 HTTP 方法

| scope | 允许的 HTTP 方法 |
|-------|------------------|
| `read` | `GET` |
| `write` | `POST`、`PUT` |
| `read_write` | `GET`、`POST`、`PUT` |
| `admin` | `GET`、`POST`、`PUT`、`DELETE` |

**注意：** 删除设备、删除空间需要 **`admin`**（会用到 `DELETE`）。scope 不足时返回 **403**，`details` 中会说明不允许当前方法。

---

## 5. ID 与通用参数约定

- **数字 ID：** 对外 ID（路径里的 `device_id`、`space_id`，请求体/查询里的 **`parent_id`（上级空间）**、设备列表查询里的 `spaceId` 等）均为 **纯数字字符串**，长度 **1～21**（不能含字母）。
- **分页：** 列表接口使用 `page`（默认 `1`）、`pageSize`（默认 `20`，最大 `200`）。
- **可选筛选：** 不需要的查询参数可直接不传。

---

## 6. 主要接口一览

### 6.1 API Key（Basic：appId + appSecret）

| 方法 | 路径 | 说明 |
|------|------|------|
| `POST` | `/v1/api-keys` | 创建 Key |
| `GET` | `/v1/api-keys?page=&pageSize=` | 分页列举 Key（仅元数据，不含密钥明文） |
| `DELETE` | `/v1/api-keys/{key_id}` | 吊销 Key |
| `PUT` | `/v1/api-keys/{key_id}/rotate` | 轮换 Key，响应里返回新的 `api_key` |

**列表单项（`KeyInfoVO`）：** `key_id`、`description`、`scope`、`status`、`expires_at`、`last_used_at`、`created_at`。

---

### 6.2 空间 — 安装位置（API Key）

空间表示设备 **安装位置**，用 **父子关系** 组成树；**集成侧不再提供「层级定义」类接口**，仅用 **上级空间 ID** 表达父子。

| 方法 | 路径 | 说明 |
|------|------|------|
| `GET` | `/v1/spaces` | 分页列举；可选 `name`、`parent_id`（筛选某父节点下的子空间） |
| `GET` | `/v1/spaces/{space_id}` | 空间详情 |
| `POST` | `/v1/spaces` | 创建空间（见下表） |
| `PUT` | `/v1/spaces/{space_id}` | 更新空间 |
| `DELETE` | `/v1/spaces/{space_id}` | 删除空间（需 **`admin`**） |

**创建空间 — 请求体（集成方只需关心这两项）：**

| 字段 | 必填 | 说明 |
|------|------|------|
| `name` | 是 | 空间名称 |
| `parent_id` | 否 | **上级空间 ID**（数字字符串）。**不传或留空表示顶级（根）空间。** |

**更新空间 — 请求体：** 同样以 **`name`** 为主；若需调整挂载关系可传 **`parent_id`**（具体约束随平台实现）。

**响应 `SpaceVO`：** 固定为 `space_id`、`name`、`parent_id`、`root_id`、`created_at`；层级、面积等由空间中台自用，开放平台不在 JSON 中暴露。

---

### 6.3 设备（API Key）

| 方法 | 路径 | 说明 |
|------|------|------|
| `GET` | `/v1/devices` | 分页列举；可选 `keyword`、**`spaceId`（按安装空间筛选）** |
| `GET` | `/v1/devices/{device_id}` | 设备详情 |
| `POST` | `/v1/devices` | 注册设备（需合法 **SN / License**） |
| `PUT` | `/v1/devices/{device_id}` | 更新设备（如 `name`） |
| `DELETE` | `/v1/devices/{device_id}` | 删除设备（需 **`admin`**） |

**注册请求体：**

| 字段 | 必填 | 说明 |
|------|------|------|
| `sn` | 是 | 序列号 / License 标识，最长 100 字符 |
| `name` | 否 | 显示名称 |
| `spaceId` | 否 | 注册时绑定到某空间 |

**列表 / 详情常用字段：** `device_id`、`name`、`type`、`type_name`、`status`、`status_code`、`created_at`、`last_active_at`；详情还会包含 `identifier`、`rssi`、`snr` 等扩展字段。

**按安装位置查设备：**  
`GET /v1/devices?spaceId=<space_id>&page=1&pageSize=20`  
返回与该空间关联的设备分页列表。

---

### 6.4 设备命令（API Key）

```http
POST /v1/devices/{device_id}/commands
```

**集成所需（最小约定）：**

| 输入 | 位置 | 说明 |
|------|------|------|
| **设备 ID** | 路径 **`device_id`** | 目标网关设备（数字 ID 字符串）。 |
| **设备功能名称** | 请求体 **`func.method`** | 要下发的设备能力/指令名称。**允许取值与设备类型有关**，我方将 **另行提供「设备类型 → 功能名称」说明文档**（后续发布）。 |

**最简请求体示例：**

```json
{
  "func": {
    "method": "YOUR_FUNCTION_NAME"
  }
}
```

对外约定为 **路径 `device_id` + 请求体 `func.method`**，下发接口 **不接受** 其它字段（多余 JSON 键将被忽略）。其它接口完整 Schema 见 **`/v3/api-docs`**。

下发成功后，可将 **`success_list[].record_id`** 作为 **控制记录 ID**，用于后续查询命令执行状态（见下）。

#### 查询命令状态

异步命令下发后，可按 **控制记录 ID** 轮询状态（与下发响应里的 **`record_id`** 为同一含义）。

```http
GET /v1/commands/{command_id}/status
```

| 路径参数 | 说明 |
|----------|------|
| `command_id` | **控制记录 ID**（1～21 位数字字符串），与 **`POST /v1/devices/{device_id}/commands`** 返回的 **`success_list[].record_id`** 一致。 |

**认证：** API Key（需允许 **GET**，即 `read` / `read_write` / `admin`）。

**响应体**（**HTTP 200**，字段 **snake_case**，与中台 **`DeviceControlRecordRespDto`** 对齐）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `record_id` | string | 记录 ID（与路径 `command_id` 一致） |
| `device_id` | string | 设备 ID |
| `trigger_source` | string | 控制类型编码：`0` 手动，`1` 规则，`2` 定时，`3` API |
| `trigger_source_text` | string | 控制类型文案 |
| `func_name` | string | 指令名称 |
| `func_params` | string | 指令参数（含单位） |
| `cmd_state` | integer | 下发结果状态码（见下表） |
| `cmd_state_text` | string | 状态文案 |
| `error_msg` | string | 失败原因 |
| `create_time` | string | 操作时间（date-time） |
| `operator_name` | string | 操作人名称 |

**`cmd_state` 取值**（设备中台约定）：

| 值 | 含义 |
|----|------|
| `-1` | 待发送 |
| `0` | 下发中 |
| `1` | 成功 |
| `2` | 失败 |
| `3` | 超时 |
| `4` | 待重试 |
| `5` | 过期 |

**设备中台接口说明**：

- **地址：** `POST /api/device/feign/v1/device/control/record/queryControlRecordByIds`
- **请求体：** JSON **字符串数组**，元素为控制记录 ID，例如 `["记录id1","记录id2"]`。
- **响应包：** `code`、`success`、`data`（`DeviceControlRecordRespDto` 数组）、`msg`，与其它内部 `R` 包装一致。

开放平台已实现 **`GET /v1/commands/{command_id}/status`**：对内以 **`queryControlRecordByIds`** 传入仅含该记录 ID 的数组查询。若记录不存在，返回 **`404`**（`NOT_FOUND`）。

**仍未开放**（调用返回 **404**）：设备设置更新、取消命令 —— 后续排期。

---

## 7. 返回结构说明

### 7.1 分页列表（`OpenApiResponse`）

```json
{
  "data": [ ... ],
  "total": 100,
  "page": 1,
  "pageSize": 20
}
```

用于 **`GET /v1/devices`**、**`GET /v1/spaces`**。

### 7.2 单个资源

多数接口直接返回资源对象（如 `SpaceVO`、`DeviceDetailVO`）；创建成功时常为 **HTTP 201 Created**。

### 7.3 错误（`ErrorResponse`）

典型结构：

```json
{
  "error": "UNAUTHORIZED",
  "details": "可读的中文或英文说明",
  "request_id": "链路或生成的追踪 ID"
}
```

可在请求头携带 **`X-Trace-Id`**，便于与内部日志、`request_id` 对齐排查。

常见 **`error`：** `INVALID_REQUEST`、`UNAUTHORIZED`、`KEY_EXPIRED`、`FORBIDDEN`、`NOT_FOUND`、`INVALID_SN`、`INVALID_SPACE`、`INTERNAL_ERROR`、`UPSTREAM_ERROR` 等；HTTP 状态码与语义对应（400 / 401 / 403 / 404 / 409 / 429 / 500 / 502 等）。

---

## 8. 推荐集成顺序（示例）

1. 通过安全渠道接收我方下发的 **`appId`** / **`appSecret`**。
2. 按业务需要创建一至多个 **API Key**，选对 **`scope`**（若需删除资源，一般用 `admin`）。
3. 用 **`POST /v1/spaces`** 搭建空间树：先建 **顶级** 空间（只传 **`name`**），再建 **子级**（传 **`name`** + **`parent_id`** 指向上级空间）。
4. 用 `sn` 及可选 **`spaceId`** **注册设备**；后续若有 CMDB 也可按需调整绑定关系。
5. 大屏或报表用 **`GET /v1/devices?spaceId=...`** 展示「某安装站点下全部设备」。
6. 运维自动化：路径传 **设备 ID**，请求体 **`func.method`** 传 **设备功能名称**（各类型可用名称见后续专门文档）；若关心异步结果，用 **`record_id`** 轮询 **`GET /v1/commands/{command_id}/status`**。

---

## 9. 安全提示

- 日志中不要打印完整的 **API Key** 或 **appSecret**。
- `appSecret` 与签发得到的 `api_key` 建议放入 **密钥管理系统**（Vault、CI Secret 等）。
- 定期 **轮换** Key（`PUT /v1/api-keys/{key_id}/rotate`），泄露则立即 **吊销**。

---

## 10. 支持与对接

环境地址、防火墙、SLA 等事项请联系我方项目经理或集成接口人。报障时请附带 **`request_id`** 或 **`X-Trace-Id`**。

---

*与客户约定的对外模型一致：**不提供层级类型接口**；**创建空间** 仅为 **`name`** + 可选 **`parent_id`**（不传则为顶级）。JSON 字段名多为 **snake_case**（如 `device_id`、`space_id`、`parent_id`、`expires_in_days`）。*
