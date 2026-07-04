# Open Platform API — Customer Integration Guide

**Chinese version:** [Open-Platform-Customer-Guide.zh-CN.md](./Open-Platform-Customer-Guide.zh-CN.md)

**Audience:** Integration teams and technical stakeholders (e.g. Polish partner).  
**Service:** `open-api-service` — HTTP JSON API for **spaces (installation locations)**, **devices**, **API key lifecycle**, and **device commands**.

---

## 1. What this platform provides

| Capability | Description |
|------------|-------------|
| **Spaces** | Model **installation locations** as a **parent/child tree** only. **Space levels are not exposed** to integrators. Create a space with **name** and optional **parent space id** (omit for a top-level root); then list, update, or delete spaces as needed. |
| **Devices** | Register devices (by **SN** / license), list and filter devices, get detail, update display name, delete. |
| **Filter devices by location** | `GET /v1/devices` supports an optional **`spaceId`** query parameter to return devices belonging to a given installation space — added per your requirement to query devices by installation location. |
| **Device commands** | Send commands with **device id** + **function name** only (`POST /v1/devices/{device_id}/commands`). Valid function names per **device type** will be listed in a separate reference *(to be published)*. **Query status** via `GET /v1/commands/{command_id}/status` using **`record_id`** from the send response. |
| **API keys** | Your application receives **`appId`** + **`appSecret`** from us; you use them **only** to create and manage **API keys**. Day-to-day integration uses the **API key**, not the app secret. |

Underlying device and space data are served via internal platform services; this API is the **stable public façade** for your integrations.

---

## 2. Base URL and documentation

- **Base URL:** Provided per environment (e.g. `https://<host>/`). Default developer port in config is **8777** if you hit the service directly — production typically sits behind your gateway.
- **OpenAPI / Swagger UI:** `/swagger-ui.html` (API definition: `/v3/api-docs`). Use this for live schema and “Try it out” during onboarding.

**Content type:** `application/json` for bodies. **Character encoding:** UTF-8.

---

## 3. Onboarding: from app credentials to API key

### Step A — Credentials we issue to you

We provision an **application** record and share:

- **`appId`** — public application identifier (string).
- **`appSecret`** — secret; **store securely**; treat like a password.

These are **not** sent on every API call. They are used **only** on routes under **`/v1/api-keys`** to mint and manage keys.

### Step B — Authenticate with HTTP Basic (appId + appSecret)

For **`/v1/api-keys`** only:

```http
Authorization: Basic <base64(appId + ":" + appSecret)>
```

Example (conceptual): if `appId` is `my-app` and `appSecret` is `s3cr3t`, encode `my-app:s3cr3t` in Base64 and send:

```http
Authorization: Basic bXktYXBwOnMzY3IzdA==
```

Errors return JSON with fields such as `error`, `details`, `request_id` (see §7).

### Step C — Create an API key

```http
POST /v1/api-keys
Authorization: Basic ...
Content-Type: application/json
```

**Request body:**

| Field | Required | Description |
|-------|----------|-------------|
| `scope` | Yes | One of: `read`, `write`, `read_write`, `admin` |
| `description` | No | Max 100 characters |
| `expires_in_days` | No | 1–3650; omit for non-expiring keys |

**Response:** `201 Created` — body includes:

| Field | Description |
|-------|-------------|
| `key_id` | Stable key identifier (for revoke/rotate) |
| `api_key` | **Plain key — shown once.** Store immediately; we only persist a hash server-side |
| `description`, `scope`, `expires_at`, `created_at` | Metadata |

Generated keys use the configured prefix (e.g. `ak_live_`) plus random material.

### Step D — Call all other APIs with the API key

For **every path except** `/v1/api-keys`, send the key using **either**:

```http
X-API-Key: <your api_key>
```

or:

```http
Authorization: Bearer <your api_key>
```

(Note: Bearer values that look like JWTs starting with `ey` are **not** treated as API keys.)

---

## 4. Scopes and HTTP methods

| scope | Allowed methods |
|-------|-----------------|
| `read` | `GET` |
| `write` | `POST`, `PUT` |
| `read_write` | `GET`, `POST`, `PUT` |
| `admin` | `GET`, `POST`, `PUT`, `DELETE` |

**Important:** Deleting devices or spaces requires **`admin`** scope (`DELETE`). If scope is too narrow, you receive **403** with a clear message.

---

## 5. IDs and parameters

- **Numeric IDs:** External IDs (`device_id`, `space_id`, `parent_id` for parent space, `spaceId` on device list query, etc.) are **decimal digit strings**, **1–21 characters** (no letters).
- **Pagination:** List endpoints use `page` (default `1`) and `pageSize` (default `20`, max `200`).
- **Optional filters:** Omit query parameters you don’t need.

---

## 6. Main endpoints (summary)

### 6.1 API keys (Basic auth: appId + appSecret)

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/v1/api-keys` | Create key |
| `GET` | `/v1/api-keys?page=&pageSize=` | List keys (metadata only; no secret) |
| `DELETE` | `/v1/api-keys/{key_id}` | Revoke key |
| `PUT` | `/v1/api-keys/{key_id}/rotate` | Rotate key — new `api_key` returned |

**List item (`KeyInfoVO`):** `key_id`, `description`, `scope`, `status`, `expires_at`, `last_used_at`, `created_at`.

---

### 6.2 Spaces — installation locations (API key)

Spaces represent **where** equipment is installed, organized as a **tree**: each space may have a **parent space**. **There is no separate “level type” API** for integrators—only parent links.

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/v1/spaces` | List spaces — optional `name`, `parent_id` (filter children of a parent), pagination |
| `GET` | `/v1/spaces/{space_id}` | Space detail |
| `POST` | `/v1/spaces` | Create space (see body below) |
| `PUT` | `/v1/spaces/{space_id}` | Update space |
| `DELETE` | `/v1/spaces/{space_id}` | Delete space (**admin**) |

**Create space — request body (what you send):**

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Space display name |
| `parent_id` | No | **Parent space id** (numeric string). **Omit or leave empty for a top-level (root) space.** |

**Update space — request body:** same idea: **`name`** is required; **`parent_id`** optional if you need to change the parent (behavior follows platform rules).

**`SpaceVO` (response):** `space_id`, `name`, `parent_id`, `root_id`, `created_at` only. Level types and area are handled inside the space platform and are **not** exposed in this API’s JSON.

---

### 6.3 Devices (API key)

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/v1/devices` | List devices — optional `keyword`, **`spaceId`** (filter by installation space), pagination |
| `GET` | `/v1/devices/{device_id}` | Device detail |
| `POST` | `/v1/devices` | Register device (requires valid **SN** / license) |
| `PUT` | `/v1/devices/{device_id}` | Update device (e.g. `name`) |
| `DELETE` | `/v1/devices/{device_id}` | Delete device (**admin**) |

**Register body:**

| Field | Required | Description |
|-------|----------|-------------|
| `sn` | Yes | Serial / license identifier (max 100 chars) |
| `name` | No | Display name |
| `spaceId` | No | Bind device to a space at registration |

**List/detail fields (summary):** `device_id`, `name`, `type`, `type_name`, `status`, `status_code`, `created_at`, `last_active_at`; detail adds telemetry/control hints such as `identifier`, `rssi`, `snr`, etc.

**Query devices by installation location:**  
`GET /v1/devices?spaceId=<space_id>&page=1&pageSize=20`  
Returns paginated devices linked to that space.

---

### 6.4 Device commands (API key)

```http
POST /v1/devices/{device_id}/commands
```

**What you need to integrate (minimal contract):**

| Input | Where | Description |
|-------|--------|-------------|
| **Device id** | Path **`device_id`** | Target gateway device (numeric id string). |
| **Device function name** | Body **`func.method`** | The command / capability name for that device. **Which names are allowed depends on device type** — we will provide a dedicated document listing function names per type *(coming soon)*. |

**Minimal JSON body example:**

```json
{
  "func": {
    "method": "YOUR_FUNCTION_NAME"
  }
}
```

The public contract is **path `device_id` + JSON body `func.method` only** — no other fields are accepted on the send endpoint (extras are ignored). See **`/v3/api-docs`** for full schemas of other endpoints.

Use **`success_list[].record_id`** (when present) as the **control record id** for later status queries (see below).

#### Query command status

After sending a command, poll execution status by **control record id** (the same value returned as `record_id` in the send response).

```http
GET /v1/commands/{command_id}/status
```

| Path parameter | Description |
|----------------|-------------|
| `command_id` | **Control record id** (string of digits, 1–21 chars), same meaning as **`record_id`** in `POST /v1/devices/{device_id}/commands` → `success_list[]`. |

**Authentication:** API key (`read` / `read_write` / `admin` — **GET**).

**Response body** (`200 OK`, **snake_case**; aligned with device platform **`DeviceControlRecordRespDto`**):

| Field | Type | Description |
|-------|------|-------------|
| `record_id` | string | Record id (same as path `command_id`). |
| `device_id` | string | Device id. |
| `trigger_source` | string | Source code: `0` manual, `1` rule, `2` schedule, `3` API. |
| `trigger_source_text` | string | Human-readable source. |
| `func_name` | string | Command / function name. |
| `func_params` | string | Parameters (including units). |
| `cmd_state` | integer | Status code (see table below). |
| `cmd_state_text` | string | Human-readable status. |
| `error_msg` | string | Failure reason when applicable. |
| `create_time` | string | Operation time (date-time). |
| `operator_name` | string | Operator display name. |

**`cmd_state` values** (device platform contract):

| Value | Meaning |
|------|---------|
| `-1` | Pending send |
| `0` | Issuing / in progress |
| `1` | Success |
| `2` | Failed |
| `3` | Timeout |
| `4` | Pending retry |
| `5` | Expired |

**Device platform reference** :

- **URL:** `POST /api/device/feign/v1/device/control/record/queryControlRecordByIds`
- **Body:** JSON **array of strings** — control record ids (e.g. `["id1","id2"]`).
- **Response envelope:** `code`, `success`, `data` (array of `DeviceControlRecordRespDto`), `msg` — same semantics as other internal `R` wrappers.

Open Platform implements **`GET /v1/commands/{command_id}/status`** by calling **`POST .../record/queryControlRecordByIds`** with a single-element id array. If the record does not exist, the API returns **`404`** with **`NOT_FOUND`**.

**Not yet available** (still **404**): device settings update and command cancel — roadmap items.

---

## 7. Response shapes

### 7.1 Paginated list (`OpenApiResponse`)

```json
{
  "data": [ ... ],
  "total": 100,
  "page": 1,
  "pageSize": 20
}
```

Used by **`GET /v1/devices`** and **`GET /v1/spaces`**.

### 7.2 Single resource

Many operations return the resource object directly (e.g. `SpaceVO`, `DeviceDetailVO`) with **HTTP 200** or **201 Created** for creates.

### 7.3 Errors (`ErrorResponse`)

Typical shape:

```json
{
  "error": "UNAUTHORIZED",
  "details": "Human-readable explanation",
  "request_id": "trace-or-generated-id"
}
```

You may send **`X-Trace-Id`**; when present it can be echoed as `request_id` for support correlation.

Common **`error` codes:** `INVALID_REQUEST`, `UNAUTHORIZED`, `KEY_EXPIRED`, `FORBIDDEN`, `NOT_FOUND`, `INVALID_SN`, `INVALID_SPACE`, `INTERNAL_ERROR`, `UPSTREAM_ERROR`, etc. HTTP status matches the situation (400 / 401 / 403 / 404 / 409 / 429 / 500 / 502).

---

## 8. Recommended integration flow (Polish rollout)

1. Receive **`appId`** / **`appSecret`** from us (secure channel).
2. Create one or more **API keys** with appropriate **`scope`** (often `read_write` or `admin` if you need deletes).
3. Build your **space tree** with **`POST /v1/spaces`**: create **root** spaces with **`name` only**, then **child** spaces with **`name`** + **`parent_id`** pointing at the parent space.
4. **Register devices** with `sn` and optional `spaceId`; or update bindings as your CMDB allows.
5. Use **`GET /v1/devices?spaceId=...`** for dashboards “all devices in this installation site”.
6. Send **commands** with path **`device_id`** and body **`func.method`** (function name); use the **per-device-type function list** when published. Poll **`GET /v1/commands/{command_id}/status`** with **`record_id`** when asynchronous status matters.

---

## 9. Security reminders

- Never log **full API keys** or **appSecret**.
- Prefer **secrets management** (vault, CI secrets) for `appSecret` and issued `api_key`.
- Rotate keys periodically (`PUT /v1/api-keys/{key_id}/rotate`) and revoke compromised keys immediately.

---

## 10. Support

For environment URLs, firewall rules, and SLA: contact your project manager or integration contact on our side. Include **`request_id`** or **`X-Trace-Id`** when reporting API failures.

---

*Document aligned with the agreed customer-facing space model: **no exposed level API**; **create space** uses **`name`** + optional **`parent_id`** (top-level if omitted). Field names in JSON use **snake_case** where defined (`device_id`, `space_id`, `parent_id`, `expires_in_days`, etc.).*
