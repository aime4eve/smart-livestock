# 开放API接口文档-客户版-英文

# Open Platform API — Customer Integration Guide

**Audience:** Integration teams and technical stakeholders   **Scope:** This document describes only the public HTTP JSON APIs and how to integrate with them.

---

## 1. Platform overview

| Capability | Description |
| --- | --- |
| Spaces | Organize installation locations as a parent/child tree. Create with `name` and optional parent space id (omit for a top-level space); list, get detail, update, and delete. |
| Devices | Register devices by SN (serial number), list and filter, get detail, update display name, delete. |
| Devices by space | `GET /v1/devices` accepts optional `spaceId` to list devices in a given space. |
| Device commands | Send commands via `POST /v1/devices/{device_id}/commands`; query status via `GET /v1/commands/{command_id}/status`. A separate reference for function names per device type will be provided. |
| API keys | We issue `appId` and `appSecret` for creating and managing API keys only. Use the API key for all day-to-day API calls. |

---

## 2. Basics

*   **Base URL:** Provided per environment (e.g. `https://<host>/`).
    
*   **Content-Type:** `application/json`
    
*   **Character encoding:** UTF-8
    

---

## 3. Authentication and API keys

### 3.1 Application credentials (appId / appSecret)

We create an application for you and provide:

*   **appId** — application identifier
    
*   **appSecret** — application secret; store securely
    

Use these credentials **only** for `/v1/api-keys` endpoints, not for other business APIs.

### 3.2 API key endpoints (HTTP Basic)

```plaintext
Authorization: Basic <base64(appId + ":" + appSecret)>

```

**Example:** if appId is `my-app` and appSecret is `s3cr3t`:

```plaintext
Authorization: Basic bXktYXBwOnMzY3IzdA==

```

### 3.3 Create an API key

```plaintext
POST /v1/api-keys
Authorization: Basic ...
Content-Type: application/json

```

**Request body:**

| Field | Required | Description |
| --- | --- | --- |
| scope | Yes | `read`, `write`, `read_write`, or `admin` |
| description | No | Max 100 characters |
| expires\_in\_days | No | 1–3650; omit for non-expiring keys |

**Response (201 Created):**

| Field | Description |
| --- | --- |
| key\_id | Key identifier (for revoke/rotate) |
| api\_key | Plain key — **returned once only**; store immediately |
| description | Description |
| scope | Permission scope |
| expires\_at | Expiration time |
| created\_at | Creation time |

### 3.4 All other APIs (API key)

For every path except `/v1/api-keys`, send the key using either:

```plaintext
X-API-Key: <your api_key>

```

or:

```plaintext
Authorization: Bearer <your api_key>

```
---

## 4. Scopes and HTTP methods

| scope | Allowed methods |
| --- | --- |
| read | GET |
| write | POST, PUT |
| read\_write | GET, POST, PUT |
| admin | GET, POST, PUT, DELETE |

Deleting devices or spaces requires `admin`. Insufficient scope returns **403**.

---

## 5. General conventions

*   **ID format:** `device_id`, `space_id`, `parent_id`, `command_id`, and query parameter `spaceId` are **decimal digit strings, 1–21 characters**.
    
*   **Pagination:** List endpoints use `page` (default 1) and `pageSize` (default 20, max 200).
    
*   **Field naming:** Response fields mostly use snake\_case (e.g. `device_id`, `space_id`); `spaceId` in device register/list uses camelCase.
    

---

## 6. API reference

### 6.1 API key management

Authentication: **HTTP Basic** (appId + appSecret)

| Method | Path | Description |
| --- | --- | --- |
| POST | `/v1/api-keys` | Create key |
| GET | `/v1/api-keys?page=&pageSize=` | List keys (paginated) |
| DELETE | `/v1/api-keys/{key_id}` | Revoke key |
| PUT | `/v1/api-keys/{key_id}/rotate` | Rotate key; returns new `api_key` |

**List item fields:** `key_id`, `description`, `scope`, `status`, `expires_at`, `last_used_at`, `created_at`

---

### 6.2 Spaces

Authentication: **API key**

| Method | Path | Description |
| --- | --- | --- |
| GET | `/v1/spaces` | List spaces; optional `name`, `parent_id` |
| GET | `/v1/spaces/{space_id}` | Space detail |
| POST | `/v1/spaces` | Create space |
| PUT | `/v1/spaces/{space_id}` | Update space |
| DELETE | `/v1/spaces/{space_id}` | Delete space (requires admin) |

**Create / update request body:**

| Field | Required | Description |
| --- | --- | --- |
| name | Yes | Space name |
| parent\_id | No | Parent space id; omit or leave empty for a top-level space |

**Response fields:** `space_id`, `name`, `parent_id`, `root_id`, `created_at`

---

### 6.3 Devices

Authentication: **API key**

| Method | Path | Description |
| --- | --- | --- |
| GET | `/v1/devices` | List devices; optional `keyword`, `spaceId` |
| GET | `/v1/devices/{device_id}` | Device detail |
| POST | `/v1/devices` | Register device |
| PUT | `/v1/devices/{device_id}` | Update device |
| DELETE | `/v1/devices/{device_id}` | Delete device (requires admin) |

**Register request body:**

| Field | Required | Description |
| --- | --- | --- |
| sn | Yes | Serial number, max 100 characters |
| name | No | Display name |
| spaceId | No | Bind to a space at registration |

**List fields:** `device_id`, `name`, `type`, `type_name`, `status`, `status_code`, `created_at`, `last_active_at`

**Detail additional fields:** `identifier`, `rssi`, `snr`, etc.

**Query by space:**

```plaintext
GET /v1/devices?spaceId=<space_id>&page=1&pageSize=20

```
---

### 6.4 Device commands

Authentication: **API key**

#### Send command

```plaintext
POST /v1/devices/{device_id}/commands

```

| Parameter | Location | Description |
| --- | --- | --- |
| device\_id | Path | Target device id |
| func.method | Body | Device function / command name |
| func.params | Body | Optional command parameters (JSON object; depends on the function) |

**Request example:**

```json
{
  "func": {
    "method": "YOUR_FUNCTION_NAME"
  }
}

```

**Response fields:** `total_count`, `success_count`, `fail_count`, `success_list`, `fail_list`

Each item in `success_list` includes `record_id` for status queries.

#### Query command status

```plaintext
GET /v1/commands/{command_id}/status

```

| Parameter | Description |
| --- | --- |

| command\_id | Control record id; same as `success_list[ ].record_id` from the send response |

**Response fields:**

| Field | Type | Description |
| --- | --- | --- |
| record\_id | string | Record id |
| device\_id | string | Device id |
| func\_name | string | Command name |
| func\_params | string | Command parameters |
| cmd\_state | integer | Status code (see table below) |
| cmd\_state\_text | string | Status description |
| error\_msg | string | Failure reason |
| create\_time | string | Operation time |
| operator\_name | string | Operator name |

**cmd\_state values:**

| Value | Meaning |
| --- | --- |
| \-1 | Pending send |
| 0 | In progress |
| 1 | Success |
| 2 | Failed |
| 3 | Timeout |
| 4 | Pending retry |
| 5 | Expired |

---

## 7. Response formats

### 7.1 Paginated list

Used by `GET /v1/devices`, `GET /v1/spaces`, and `GET /v1/api-keys`.

```json
{
  "data": [ ... ],
  "total": 100,
  "page": 1,
  "pageSize": 20
}

```

### 7.2 Single resource

Most endpoints return the resource object directly. Creates return HTTP **201 Created**.

### 7.3 Error response

```json
{
  "error": "UNAUTHORIZED",
  "details": "Human-readable explanation",
  "request_id": "Request trace id"
}

```

We recommend sending `X-Trace-Id` in request headers and including it when reporting issues.

**Common error codes:**

| error | Typical HTTP status | Description |
| --- | --- | --- |
| INVALID\_REQUEST | 400 | Invalid request parameters |
| UNAUTHORIZED | 401 | Not authenticated or invalid key |
| KEY\_EXPIRED | 401 | API key expired |
| FORBIDDEN | 403 | Insufficient scope |
| NOT\_FOUND | 404 | Resource not found |
| INVALID\_SN | 400 | Invalid or inactive SN |
| INVALID\_SPACE | 400 | Invalid space id |

---

## 8. Recommended integration steps

1.  Receive `appId` and `appSecret` from us.
    
2.  Create API keys with the appropriate scope (use `admin` if you need deletes).
    
3.  Build your space tree with `POST /v1/spaces`: root spaces with `name` only, then child spaces with `name` + `parent_id`.
    
4.  Register devices with `POST /v1/devices` (`sn` required; optional `spaceId` to bind a space).
    
5.  Use `GET /v1/devices?spaceId=...` to list devices in a space.
    
6.  Send commands with `POST /v1/devices/{device_id}/commands`; poll `GET /v1/commands/{command_id}/status` when needed.
    

---

## 9. Security

*   Do not log full API keys or `appSecret`.
    
*   Store secrets in a secure secrets manager.
    
*   Rotate keys periodically (`PUT /v1/api-keys/{key_id}/rotate`); revoke immediately if compromised.
    

---

## 10. Support

For environment URLs, network access, and SLA, contact your project manager or integration contact. When reporting failures, include `request_id` or `X-Trace-Id`.