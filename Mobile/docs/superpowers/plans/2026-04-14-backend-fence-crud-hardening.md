# Mock Server 围栏 CRUD 补强实施计划

**Goal:** 在不改动现有前端交互的前提下，补齐后端围栏 CRUD 的参数校验、详情查询接口与单元测试，提升联调稳定性。

**Scope:** `Mobile/backend`（Express mock server）

---

## Issue 索引

| 优先级 | Issue | 标题 |
|--------|-------|------|
| P1 | [#17](https://github.com/aime4eve/smart-livestock/issues/17) | Mock Server 围栏 CRUD 补强：参数校验、详情接口与单测 |

### 完成记录

| 完成日期 | Issue | PR | 备注 |
|----------|-------|----|------|
| 2026-04-14 | [#17](https://github.com/aime4eve/smart-livestock/issues/17) | [#18](https://github.com/aime4eve/smart-livestock/pull/18) | 已合并至 master；含 GET /api/fences/:id、fenceStore 校验与 npm test |

---

## #17 — Mock Server 围栏 CRUD 补强

### 目标

- 新增 `GET /api/fences/:id`，支持按 ID 查询围栏
- 强化 `POST /api/fences` 与 `PUT /api/fences/:id` 参数校验
- 为 `fenceStore` 新增独立测试文件并纳入 `npm test`

### 涉及文件

- `Mobile/backend/routes/fences.js`
- `Mobile/backend/data/fenceStore.js`
- `Mobile/backend/server.js`
- `Mobile/backend/package.json`
- `Mobile/backend/test/fenceStore.test.js`

### 验收标准

- `cd Mobile/backend && npm test` 通过
- 创建/更新围栏错误请求返回 `422 VALIDATION_ERROR`
- 详情接口不存在资源返回 `404 RESOURCE_NOT_FOUND`
