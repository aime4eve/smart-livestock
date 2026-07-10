# API 兼容矩阵

## 策略

- `/api/v1` 是规范契约源。
- `/api` 是面向现有客户端与回滚场景的长期兼容入口。
- `/api` 必须与 `/api/v1` 共享后端实现；只允许适配层差异。

## 矩阵

| 模块 | `/api` 兼容承诺 | `/api/v1` 契约 | 负责人 | 测试状态 | 最后复核 |
|------|-----------------|----------------|--------|----------|----------|
| auth / me / profile | 保留登录、刷新、登出、`/me`、`/profile` | 规范源 | Backend | Covered by `apiVersionRoutes.test.js` / `authChain.test.js` | 2026-04-26 |
| tenant | 保留 Phase 1 CRUD、状态、许可 | 规范源 | Backend | Covered by route equivalence tests | 2026-04-26 |
| fence | 保留列表、详情、创建、更新、删除 | 规范源 | Backend | Covered by route equivalence tests | 2026-04-26 |
| alert | 保留列表、单条状态流转、批量处理 | 规范源 | Backend | Covered by route equivalence tests | 2026-04-26 |
| dashboard / map / devices / twin | 保留当前 live 预加载端点 | 规范源 | Backend | Covered by Flutter live v1 contract test | 2026-04-26 |
| stats / livestock extension | 默认不回迁 | 规范源 | TBD | Not started | 2026-04-26 |

---

## 兼容债台账

每个兼容映射必须登记以下信息。新功能默认只写 `/api/v1`，如需 `/api` 兼容必须在此登记。

| 序号 | 兼容项 | 影响端点 | 引入原因 | 负责人 | 引入日期 | 风险等级 | 移除条件 |
|------|--------|----------|----------|--------|----------|----------|----------|
| CD-001 | alert ID 命名：`alert-XXX`（连字符）为规范格式 | `/api/alerts`、`/api/v1/alerts` | seed 数据自 Demo 起使用 `alert-001` 格式，未发现 `alert_001` 下划线变体 | Backend | 2026-04-27 | low | 无差异，无需移除 |
| CD-002 | `/me` 与 `/profile` 字段投影已对齐 | `/api/me`、`/api/profile`、`/api/v1/me`、`/api/v1/profile` | 早期 `/me` 仅返回基础字段，后通过 `buildUserProjection` 补齐 `tenantName`、`notificationEnabled` | Backend | 2026-04-26 | low | 已验证一致，无需移除 |
| CD-003 | 围栏 `version` 字段 | `/api/fences`、`/api/v1/fences` | 乐观并发控制需求，防止编辑冲突 | Backend | 2026-04-27 | medium | callers 升级到发送 version 后自然移除 adapter |

**登记说明**：
- CD-001 和 CD-002 为"已验证无差异"条目，保留用于审计追踪。
- 新兼容项按递增序号 CD-NNN 登记。
- 风险等级：`low`（仅格式差异）、`medium`（字段语义差异）、`high`（安全或数据完整性风险）。

---

## 月度审查机制

1. **审查频率**：每月第一个工作日检查兼容债台账。
2. **审查内容**：
   - 检查 `/api` 调用占比（后端日志 `apiVersion=legacy` 占比）。
   - 审查 pending 状态的兼容项是否有移除条件已满足的。
   - 评估是否因新功能产生了未登记的 `/api` 兼容需求。
3. **量化门槛**：当 `/api` 调用占比连续 2 个月低于 5% 时，可启动 `/api` 下线评估。
4. **责任人**：Backend owner。
5. **记录方式**：每次审查在本文件末尾追加一行审查记录。

### 审查记录

| 日期 | 审查人 | `/api` 占比 | 新债务 | 移除债务 | 结论 |
|------|--------|-------------|--------|----------|------|
| 2026-04-27 | Backend | N/A（Mock 环境） | CD-001, CD-002, CD-003 | 无 | 基线建立 |
