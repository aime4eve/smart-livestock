# API 契约变更日志

> 跟踪 `docs/api-contracts/` 下所有文档的变更。

---

## 2026-05-07 — 契约重设计（v1.0）

**来源**: 旧契约文档 `docs/superpowers/specs/2026-05-07-multi-client-api-contract-design.md` 废弃，从头重写。

**变更范围**: 全部文档。

**修正的 P0/P1 问题**（来自三份评审报告）:

| 问题编号 | 修正内容 |
|---------|---------|
| B1 | code 字段统一为全字符串枚举（`"OK"`、`"AUTH_TOKEN_EXPIRED"` 等） |
| B2 | ID 统一为 BIGSERIAL，JSON 序列化为字符串 |
| H1 | 设备 API 路径统一为 `/farms/{farmId}/devices` |
| H2 | GPS 写入通道明确为主路径 MQTT→RocketMQ，Phase 1 保留 `@Deprecated` REST 端点 |
| H4 | device-licenses 移至租户级路径 `/device-licenses`（JWT tid 隔离），解决 INVENTORY 设备无 farm 可挂和多牧场许可证汇总问题 |
| H6 | Device 模型增加 `runtimeStatus` 字段（online/offline/low_battery） |
| C1 | 补充牧场切换从 header 到 path 的完整过渡路径和 Flutter 变更清单 |
| C2 | 补充初始种子数据方案（platform_admin + 租户 + owner + demo API Key） |
| C3 | 错误码扩展至 17 个（新增 QUOTA_EXCEEDED、LICENSE_EXPIRED、DEVICE_NOT_ACTIVE、RESOURCE_DELETED） |
| C5 | 补充 Idempotency-Key 实现规范（Redis 存储、TTL 24h、key 冲突返回 409） |
| C6 | 全部 81 个端点补充 JSON 请求/响应示例 |
| C7 | 补充读操作 header 兼容模式的精确行为规范（等效性、403、不返回 farmId） |
| C10 | 在总览 §2.3 增加 HTTP 方法语义统一约定 |
| C12 | 在总览 §2.4 增加客户端枚举值容错要求 |

**架构决策**:
- 三端隔离架构保留（`/api/v1/`、`/api/v1/admin/`、`/api/v1/open/`）
- Farm Scope 硬约束保留（写操作仅路径、读操作二选一、双来源 422）
- API Key 首次发放仅返回一次明文，之后仅显示 keyId + prefix

**新增文档**:
- `api-overview.md` — 总览
- `app-api.md` — App API 49 端点
- `admin-api.md` — Admin API 21 端点
- `open-api.md` — Open API 11 端点 + 专属约定
- `migration-guide.md` — Mock Server → Spring Boot 迁移指南
- `changelog.md` — 本文件

---

## 2026-09-03 — NIX-184 部署授权与试点授权（licensing 端点）

**来源**: NIX-184 市场测试版发布准备（部署授权设计 §7/§8/§9/§11）；实现为 `DeploymentLicenseAdminController` / `CloudPilotLicenseController`（licensing 上下文）。

**变更范围**: `admin-api.md` 新增 §14「部署授权与试点授权」5 端点。

**新增端点**:

| 端点 | 模式 | 说明 |
|------|------|------|
| POST /admin/tenants/{tenantId}/pilot-license | HOSTED（需 pilot 开关） | 365 天云端试点开通/延长（TRIAL，now+365d 或 max 不缩短） |
| GET /admin/deployment-license/mode | 通用 | 报告 `{mode, pilotLicenseEnabled}`，前端功能探测 |
| GET /admin/deployment-license/enrollment | ONPREM | 安装登记：installationId / 实时指纹 / 公钥 ID |
| POST /admin/deployment-license | ONPREM | multipart 导入 .sllicense（file + confirm=true），驱动订阅映射 |
| GET /admin/deployment-license/current | ONPREM | 授权 / 运行时状态 / 订阅映射 / 防篡改锚点全景 |

**新增错误码与 HTTP 映射**（`ErrorCode` + `GlobalExceptionHandler`）:

| 错误码 | HTTP | 触发场景 |
|--------|------|---------|
| LICENSE_REQUIRED | 403 | ONPREM 未激活/挂起阻断业务 API；ONPREM 下自助订阅端点禁用 |
| LICENSE_INVALID | 403 | envelope 结构/摘要/验签/keyId 失败 |
| LICENSE_BINDING_MISMATCH | 403 | tenant/installation/指纹绑定三元组不匹配 |
| LICENSE_TIME_ROLLBACK | 409 | 系统时间回拨超容差（保护性 SUSPENDED） |
| LICENSE_QUOTA_EXCEEDED | 403 | 导入预检：用量超 payload 配额 |

**行为约束**: HOSTED/ONPREM 模式互斥（`SMARTLIVESTOCK_LICENSE_MODE`）；试点授权仅 HOSTED + `SMARTLIVESTOCK_PILOT_LICENSE_ENABLED=true`；runtime 状态机 PENDING_ACTIVATION / VALID / EXPIRED / SUSPENDED（调度器默认每 5 分钟重验）；ONPREM 下 commerce 自助订阅端点被 `requireSelfServiceAllowed()` 拒绝（LICENSE_REQUIRED）。详见 `admin-api.md` §14。

---

## 2026-09-04 — 集成测试修正：牲畜规范值与 API Key 契约对齐

**来源**: NIX-184 双机集成测试发现（86/223 实测 + 契约与实现比对）。

**修正内容**:

| 位置 | 修正 |
|------|------|
| `app-api.md` / `open-api.md` 牲畜示例 | breed/gender 统一为 DB CHECK 约束的规范码（`ANGUS/WAGYU/SIMMENTAL/LIMOUSIN/OTHER`、`MALE/FEMALE`）；后端服务层同步做别名规范化（中文别名 → 规范码）与校验（未知值 400 `VALIDATION_ERROR`，不再 500） |
| `admin-api.md` §6 API Key 管理 | 按实现修正字段：创建响应为 `id/keyName/prefix/role/rawKey/scopes`（原 `keyId/apiKey` 为笔误）；`scopes` 接受数组或逗号串并逐个校验；限流默认 60 rpm / 20000 日；DELETE 前须先置 `disabled` |
| 门户 `POST /portal/keys` | 创建响应补回一次性 `rawKey`（此前响应丢失密钥明文，key 创建后不可获得） |
