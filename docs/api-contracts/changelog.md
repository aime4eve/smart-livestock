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
