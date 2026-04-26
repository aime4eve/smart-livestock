# API 兼容矩阵

## 策略

- `/api/v1` 是规范契约源。
- `/api` 是面向现有客户端与回滚场景的长期兼容入口。
- `/api` 必须与 `/api/v1` 共享后端实现；只允许适配层差异。

## 矩阵

| 模块 | `/api` 兼容承诺 | `/api/v1` 契约 | 负责人 | 测试状态 | 最后复核 |
|------|-----------------|----------------|--------|----------|----------|
| auth / me / profile | 保留登录、刷新、登出、`/me`、`/profile` | 规范源 | Backend | Planned | 2026-04-26 |
| tenant | 保留 Phase 1 CRUD、状态、许可 | 规范源 | Backend | Planned | 2026-04-26 |
| fence | 保留列表、详情、创建、更新、删除 | 规范源 | Backend | Planned | 2026-04-26 |
| alert | 保留列表、单条状态流转、批量处理 | 规范源 | Backend | Planned | 2026-04-26 |
| dashboard / map / devices / twin | 保留当前 live 预加载端点 | 规范源 | Backend | Planned | 2026-04-26 |
| stats / livestock extension | 默认不回迁 | 规范源 | TBD | Not started | 2026-04-26 |
