# 租户管理模块实施计划（Phase 1 MVP）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在现有 `/ops/admin` 占位页之上，落地租户管理 MVP：支持租户列表（搜索/状态筛选/排序/分页）、租户创建、租户详情（状态切换 + License 调整 + 软删除）与改名编辑，前后端对齐统一包络，严格遵循现有同步 Controller + ViewData 模式。

**Architecture:**
1. 新增 `features/tenant/` 模块（domain/data/presentation），取代 `features/admin/` 作为 Ops 角色主入口。
2. Controller 全部使用**同步方法** + `state = repository.load(...)` 写法，与 `AdminController`/`DevicesController` 等现有模块一致。State 按场景拆分（列表 / 详情），避免大一统 Provider。
3. 后端在 `backend/data/` 新增 `tenantStore.js`（仿 `fenceStore.js`），路由扩展 `GET /:id`、`PUT /:id`、`DELETE /:id`，列表端点支持 `status/search/sort` 参数。
4. Live 模式通过 `ApiCache.instance.tenants` 读取，写操作后调用 `ApiCache.refreshTenants()` 刷新缓存。详情页的补充信息（若缓存未命中）回退 Mock 数据。

**Tech Stack:** Flutter 3.x, flutter_riverpod, go_router, Node.js + Express 5, `http` 包。

**真相来源**：Issue 的 open/closed 以 GitHub 为准；本文件记录范围说明、依赖与完成后的归档信息。

**被实施规格**：`docs/superpowers/specs/2026-04-20-tenant-management-design.md` v1.1。

---

## Issue 索引

| 优先级 | Issue | 标题 |
|--------|-------|------|
| P0 | #27 | 租户管理 Phase 1 MVP：列表/创建/详情/编辑/删除 |

### 完成记录

| 完成日期 | Issue | PR | 备注 |
|----------|-------|-----|------|
| 2026-04-21 | #27 | 待合并 | Phase 1 MVP：17 个 Task 全部完成，178 flutter tests + 15 backend tests 通过，手工 E2E 验证通过 |

---

## 范围界定（Scope）

**本计划覆盖（Phase 1 MVP）**：
- 后端：租户 CRUD 6 端点 + 列表过滤/排序参数。
- 前端：租户列表 / 创建 / 详情（基本信息卡片）/ 编辑（改名）四个页面。
- 详情页仅含「基本信息卡片」。**设备列表 / 操作日志 / 统计概览卡片** 均属 Phase 2，不在本计划内。
- 权限：沿用现有 `tenant:view / tenant:create / tenant:toggle / license:manage` 四个后端权限；新增 `tenant:edit / tenant:delete` 两个权限。

**本计划不覆盖**：
- 图表降采样（Phase 3）。
- 操作日志存储机制（Phase 2）。
- seed 扩展到联系人/地区/备注（Phase 2）。
- Web E2E 验证（保留 flutter test 覆盖）。

---

## 文件结构

### 后端 — 新建

| 文件 | 职责 |
|------|------|
| `backend/data/tenantStore.js` | 租户内存存储 + 过滤/排序/分页 + CRUD |
| `backend/test/tenantStore.test.js` | 存储单元测试 |

### 后端 — 修改

| 文件 | 变更 |
|------|------|
| `backend/routes/tenants.js` | 替换内存实现为 `tenantStore`，新增 GET `/:id` / PUT `/:id` / DELETE `/:id`，列表端点支持 `status/search/sort/order` 参数 |
| `backend/data/seed.js` | `tenants` 数据保持 5 字段（id/name/status/licenseUsed/licenseTotal），但扩充到 6 条以覆盖分页测试 |
| `backend/data/seed.js` | `users.ops.permissions` 增加 `tenant:edit` / `tenant:delete` |
| `backend/data/seed.js` | `users.owner.permissions` 同步增加 `tenant:edit` / `tenant:delete` |
| `backend/server.js` | `ROUTE_TABLE` 更新为新的端点清单 |

### 前端 — 新建

| 文件 | 职责 |
|------|------|
| `lib/features/tenant/domain/tenant.dart` | `Tenant` 值对象 + `TenantStatus` 枚举 |
| `lib/features/tenant/domain/tenant_query.dart` | `TenantListQuery`（status / search / sort / page / pageSize） |
| `lib/features/tenant/domain/tenant_view_data.dart` | `TenantListViewData` / `TenantDetailViewData` |
| `lib/features/tenant/domain/tenant_repository.dart` | 仓储接口 |
| `lib/features/tenant/data/mock_tenant_repository.dart` | Mock 实现（内存列表 + 过滤/排序） |
| `lib/features/tenant/data/live_tenant_repository.dart` | Live 实现（读取 `ApiCache.tenants` + 回退 Mock） |
| `lib/features/tenant/data/tenant_dto.dart` | JSON ↔ Tenant 映射 |
| `lib/features/tenant/presentation/tenant_list_controller.dart` | 列表 Notifier + Provider |
| `lib/features/tenant/presentation/tenant_detail_controller.dart` | 详情 `NotifierProvider.family` |
| `lib/features/tenant/presentation/pages/tenant_list_page.dart` | 列表页 |
| `lib/features/tenant/presentation/pages/tenant_create_page.dart` | 创建页 |
| `lib/features/tenant/presentation/pages/tenant_detail_page.dart` | 详情页（卡片堆叠） |
| `lib/features/tenant/presentation/pages/tenant_edit_page.dart` | 编辑页（改名） |
| `lib/features/tenant/presentation/widgets/tenant_card.dart` | 列表项卡片 |
| `lib/features/tenant/presentation/widgets/license_adjust_dialog.dart` | License 调整对话框 |
| `lib/features/tenant/presentation/widgets/tenant_delete_dialog.dart` | 删除对话框（单次确认 + 原因） |
| `lib/widgets/pagination_bar.dart` | 通用分页组件 |

### 前端 — 修改

| 文件 | 变更 |
|------|------|
| `lib/core/api/api_cache.dart` | 新增 `refreshTenants(role)` / `fetchTenantDetail(role, id)`；创建/更新/删除 API 封装（`createTenantRemote` / `updateTenantRemote` / `deleteTenantRemote` / `toggleTenantStatusRemote` / `adjustTenantLicenseRemote`） |
| `lib/core/permissions/role_permission.dart` | 新增 `canManageTenants` / `canEditTenant` / `canDeleteTenant` / `canAdjustLicense` 四个静态方法 |
| `lib/app/app_router.dart` | `/ops/admin` 路由替换为 `TenantListPage`；增加子路由 `/ops/admin/create`、`/ops/admin/:id`、`/ops/admin/:id/edit` |
| `lib/features/pages/admin_page.dart` | owner 访问 `/admin` 仍复用旧占位页，但导航到 `/ops/admin` 时不再展示此页面（由路由直接指向 `TenantListPage`） |

### 前端 — 删除/废弃

| 文件 | 动作 |
|------|------|
| `lib/features/admin/` 目录 | **不删除**。`admin_page.dart` 仍被 owner 的 `/admin` 沿用作为历史占位页。仅 `/ops/admin` 切换到新模块；本计划结束后由后续迭代移除。 |

### 前端 — 测试

| 文件 | 动作 |
|------|------|
| `test/features/tenant/tenant_dto_test.dart` | 新建 |
| `test/features/tenant/mock_tenant_repository_test.dart` | 新建 |
| `test/features/tenant/live_tenant_repository_test.dart` | 新建 |
| `test/features/tenant/tenant_list_controller_test.dart` | 新建 |
| `test/features/tenant/tenant_list_page_test.dart` | 新建（widget） |
| `test/features/tenant/tenant_detail_page_test.dart` | 新建（widget） |
| `test/features/tenant/tenant_create_flow_test.dart` | 新建（widget） |
| `test/features/tenant/pagination_bar_test.dart` | 新建（widget） |
| `test/flow_smoke_test.dart` | 修改：ops 流程从 `tenant-license-adjust` 切换为 `tenant-list-page` 首屏验证 |
| `test/mock_repository_override_test.dart` | 修改：增加 `tenantListRepositoryProvider` override 案例（可选，若时间紧可延后） |

### 后端 — 测试

| 文件 | 动作 |
|------|------|
| `backend/test/tenantStore.test.js` | 新建 |

---

## 前置条件与约定

1. **包络规范**：所有成功响应 `{ code: 'OK', message, requestId, data }`；列表 `data` 为 `{ items, page, pageSize, total }`。
2. **参数命名**：`licenseTotal`（不得使用 `newQuota`）；状态值枚举 `active | disabled`。
3. **错误码**：422 `VALIDATION_ERROR`；404 `RESOURCE_NOT_FOUND`；409 `CONFLICT`；403 `AUTH_FORBIDDEN`；401 `AUTH_UNAUTHORIZED`。
4. **删除语义**：Phase 1 采用**硬删除**（Mock Server 从内存移除）。真实数据库的软删除留待 MVP 后端阶段。
5. **License 调整校验**：`licenseTotal < licenseUsed` 返回 422（错误文案：`新配额不能小于当前已使用量（$licenseUsed）`）。
6. **改名唯一性**：租户名称全局唯一；重复名称返回 409 `CONFLICT`，文案 `租户名称已存在`。
7. **分页默认**：`page=1`，`pageSize=20`。
8. **搜索规则**：`search` 参数按名称做大小写不敏感 `includes` 匹配。
9. **排序**：`sort=licenseUsage`（`licenseUsed/licenseTotal` 计算）或 `sort=name`；`order=asc|desc`，默认 `sort=name&order=asc`。
10. **提交频次**：每个 Task 结束必须 `git commit`，遵循现有 conventional commits 风格。

---

## Task 1：扩展 tenants 种子数据 + 权限

**Files:**
- Modify: `backend/data/seed.js`

- [ ] **Step 1：扩充 `tenants` 数组为 6 条，用于分页验证**

替换 `backend/data/seed.js` 中 `const tenants = [...]` 块为：

```javascript
const tenants = [
  { id: 'tenant_001', name: '华东示范牧场', status: 'active', licenseUsed: 50, licenseTotal: 200 },
  { id: 'tenant_002', name: '西部高原牧场', status: 'active', licenseUsed: 120, licenseTotal: 200 },
  { id: 'tenant_003', name: '东北黑土地牧场', status: 'active', licenseUsed: 180, licenseTotal: 250 },
  { id: 'tenant_004', name: '华南热带牧场', status: 'disabled', licenseUsed: 30, licenseTotal: 100 },
  { id: 'tenant_005', name: '西南高山牧场', status: 'active', licenseUsed: 95, licenseTotal: 150 },
  { id: 'tenant_006', name: '华北草原牧场', status: 'active', licenseUsed: 75, licenseTotal: 180 },
];
```

- [ ] **Step 2：`users.owner.permissions` 与 `users.ops.permissions` 增加新权限**

在 owner 与 ops 的 permissions 数组末尾追加：

```javascript
'tenant:edit',
'tenant:delete',
```

- [ ] **Step 3：运行后端已有测试确认不破坏**

Run: `cd Mobile/backend && npm test`
Expected: 全部已有测试 PASS。

- [ ] **Step 4：Commit**

```bash
cd Mobile
git add backend/data/seed.js
git commit -m "feat(backend): extend tenant seed and add tenant:edit/delete permissions"
```

---

## Task 2：抽取 `tenantStore.js`（TDD）

**Files:**
- Create: `backend/data/tenantStore.js`
- Create: `backend/test/tenantStore.test.js`

- [ ] **Step 1：写失败测试 `tenantStore.test.js`**

```javascript
const assert = require('node:assert/strict');
const { test } = require('node:test');
const store = require('../data/tenantStore');

test('tenantStore: sliceForPage 默认分页返回全部', () => {
  store.reset();
  const res = store.sliceForPage({});
  assert.equal(res.page, 1);
  assert.equal(res.pageSize, 20);
  assert.equal(res.total, 6);
  assert.equal(res.items.length, 6);
});

test('tenantStore: sliceForPage 支持 status 过滤', () => {
  store.reset();
  const res = store.sliceForPage({ status: 'disabled' });
  assert.equal(res.items.length, 1);
  assert.equal(res.items[0].status, 'disabled');
});

test('tenantStore: sliceForPage 支持 search 名称模糊', () => {
  store.reset();
  const res = store.sliceForPage({ search: '草原' });
  assert.equal(res.items.length, 1);
  assert.equal(res.items[0].name, '华北草原牧场');
});

test('tenantStore: sliceForPage 支持 licenseUsage 排序', () => {
  store.reset();
  const res = store.sliceForPage({ sort: 'licenseUsage', order: 'desc' });
  assert.equal(res.items[0].name, '东北黑土地牧场');
});

test('tenantStore: findById 命中', () => {
  store.reset();
  const t = store.findById('tenant_001');
  assert.equal(t.name, '华东示范牧场');
});

test('tenantStore: createTenant 校验 name 必填', () => {
  store.reset();
  const { error } = store.createTenant({ licenseTotal: 100 });
  assert.equal(error, 'name_required');
});

test('tenantStore: createTenant 校验名称唯一', () => {
  store.reset();
  const { error } = store.createTenant({ name: '华东示范牧场', licenseTotal: 100 });
  assert.equal(error, 'name_conflict');
});

test('tenantStore: createTenant 成功', () => {
  store.reset();
  const { tenant } = store.createTenant({ name: '测试新租户', licenseTotal: 80 });
  assert.equal(tenant.name, '测试新租户');
  assert.equal(tenant.status, 'active');
  assert.equal(tenant.licenseUsed, 0);
  assert.equal(tenant.licenseTotal, 80);
});

test('tenantStore: updateTenant 改名冲突返回 name_conflict', () => {
  store.reset();
  const { error } = store.updateTenant('tenant_001', { name: '西部高原牧场' });
  assert.equal(error, 'name_conflict');
});

test('tenantStore: updateTenant 改名成功', () => {
  store.reset();
  const { tenant } = store.updateTenant('tenant_001', { name: '华东示范牧场（改）' });
  assert.equal(tenant.name, '华东示范牧场（改）');
});

test('tenantStore: adjustLicense 小于已用量返回 license_below_used', () => {
  store.reset();
  const { error } = store.adjustLicense('tenant_003', 100);
  assert.equal(error, 'license_below_used');
});

test('tenantStore: adjustLicense 正确更新', () => {
  store.reset();
  const { tenant } = store.adjustLicense('tenant_003', 300);
  assert.equal(tenant.licenseTotal, 300);
});

test('tenantStore: toggleStatus 非法值返回 status_invalid', () => {
  store.reset();
  const { error } = store.toggleStatus('tenant_001', 'paused');
  assert.equal(error, 'status_invalid');
});

test('tenantStore: removeTenant 不存在返回 not_found', () => {
  store.reset();
  const { error } = store.removeTenant('tenant_999');
  assert.equal(error, 'not_found');
});

test('tenantStore: removeTenant 成功', () => {
  store.reset();
  const { removed } = store.removeTenant('tenant_001');
  assert.equal(removed.id, 'tenant_001');
  assert.equal(store.findById('tenant_001'), undefined);
});
```

- [ ] **Step 2：运行测试确认失败**

Run: `cd Mobile/backend && node --test test/tenantStore.test.js`
Expected: FAIL（模块不存在）。

- [ ] **Step 3：实现 `tenantStore.js`**

```javascript
const { tenants: seedTenants } = require('./seed');

const ALLOWED_STATUS = ['active', 'disabled'];
let tenants = seedTenants.map((t) => ({ ...t }));
let nextId = tenants.length + 1;

function reset() {
  tenants = seedTenants.map((t) => ({ ...t }));
  nextId = tenants.length + 1;
}

function getAll() {
  return tenants;
}

function findById(id) {
  return tenants.find((t) => t.id === id);
}

function nameExists(name, excludeId) {
  return tenants.some((t) => t.name === name && t.id !== excludeId);
}

function sliceForPage(query) {
  const {
    page = '1',
    pageSize = '20',
    status,
    search,
    sort = 'name',
    order = 'asc',
  } = query || {};
  let filtered = tenants.slice();

  if (status && ALLOWED_STATUS.includes(status)) {
    filtered = filtered.filter((t) => t.status === status);
  }
  if (search && typeof search === 'string' && search.trim() !== '') {
    const kw = search.toLowerCase();
    filtered = filtered.filter((t) => t.name.toLowerCase().includes(kw));
  }

  const sortKey = sort === 'licenseUsage' ? 'licenseUsage' : 'name';
  const dir = order === 'desc' ? -1 : 1;
  filtered.sort((a, b) => {
    const va = sortKey === 'licenseUsage'
      ? (a.licenseTotal === 0 ? 0 : a.licenseUsed / a.licenseTotal)
      : a.name;
    const vb = sortKey === 'licenseUsage'
      ? (b.licenseTotal === 0 ? 0 : b.licenseUsed / b.licenseTotal)
      : b.name;
    if (va < vb) return -1 * dir;
    if (va > vb) return 1 * dir;
    return 0;
  });

  const p = Math.max(1, parseInt(page, 10) || 1);
  const ps = Math.max(1, parseInt(pageSize, 10) || 20);
  const total = filtered.length;
  const start = (p - 1) * ps;
  const items = filtered.slice(start, start + ps);
  return { items, page: p, pageSize: ps, total };
}

function createTenant(body) {
  const { name: rawName, licenseTotal = 100 } = body || {};
  const name = typeof rawName === 'string' ? rawName.trim() : rawName;
  if (!name) return { error: 'name_required' };
  if (typeof licenseTotal !== 'number' || licenseTotal < 0) {
    return { error: 'license_invalid' };
  }
  if (nameExists(name)) return { error: 'name_conflict' };
  const tenant = {
    id: `tenant_${String(nextId++).padStart(3, '0')}`,
    name,
    status: 'active',
    licenseUsed: 0,
    licenseTotal,
  };
  tenants.push(tenant);
  return { tenant };
}

function updateTenant(id, body) {
  const tenant = findById(id);
  if (!tenant) return { error: 'not_found' };
  const { name: rawName } = body || {};
  if (rawName !== undefined) {
    const name = typeof rawName === 'string' ? rawName.trim() : rawName;
    if (!name) return { error: 'name_required' };
    if (nameExists(name, id)) return { error: 'name_conflict' };
    tenant.name = name;
  }
  return { tenant };
}

function toggleStatus(id, status) {
  if (!ALLOWED_STATUS.includes(status)) return { error: 'status_invalid' };
  const tenant = findById(id);
  if (!tenant) return { error: 'not_found' };
  tenant.status = status;
  return { tenant };
}

function adjustLicense(id, licenseTotal) {
  if (typeof licenseTotal !== 'number' || licenseTotal < 0) {
    return { error: 'license_invalid' };
  }
  const tenant = findById(id);
  if (!tenant) return { error: 'not_found' };
  if (licenseTotal < tenant.licenseUsed) {
    return { error: 'license_below_used' };
  }
  tenant.licenseTotal = licenseTotal;
  return { tenant };
}

function removeTenant(id) {
  const idx = tenants.findIndex((t) => t.id === id);
  if (idx === -1) return { error: 'not_found' };
  const [removed] = tenants.splice(idx, 1);
  return { removed };
}

module.exports = {
  getAll,
  findById,
  sliceForPage,
  createTenant,
  updateTenant,
  toggleStatus,
  adjustLicense,
  removeTenant,
  reset,
};
```

- [ ] **Step 4：运行测试确认通过**

Run: `cd Mobile/backend && node --test test/tenantStore.test.js`
Expected: 全部 15 个 case PASS。

- [ ] **Step 5：Commit**

```bash
cd Mobile
git add backend/data/tenantStore.js backend/test/tenantStore.test.js
git commit -m "feat(backend): extract tenantStore with filter/sort/paging and CRUD"
```

---

## Task 3：租户路由对齐 + 新增端点

**Files:**
- Modify: `backend/routes/tenants.js`
- Modify: `backend/server.js`

- [ ] **Step 1：替换 `backend/routes/tenants.js` 全部内容**

```javascript
const { Router } = require('express');
const { authMiddleware, requirePermission } = require('../middleware/auth');
const store = require('../data/tenantStore');

const router = Router();

const ERROR_MAP = {
  name_required: { status: 422, code: 'VALIDATION_ERROR', message: 'name 为必填项' },
  name_conflict: { status: 409, code: 'CONFLICT', message: '租户名称已存在' },
  license_invalid: { status: 422, code: 'VALIDATION_ERROR', message: 'licenseTotal 必须为非负整数' },
  license_below_used: { status: 422, code: 'VALIDATION_ERROR', message: '新配额不能小于当前已使用量' },
  status_invalid: { status: 422, code: 'VALIDATION_ERROR', message: 'status 必须为 active / disabled' },
  not_found: { status: 404, code: 'RESOURCE_NOT_FOUND', message: '租户不存在' },
};

function sendErr(res, tenantError, tenantContext) {
  const spec = ERROR_MAP[tenantError];
  if (!spec) return res.fail(500, 'INTERNAL_ERROR', '未知错误');
  const msg = tenantError === 'license_below_used' && tenantContext
    ? `${spec.message}（${tenantContext.licenseUsed}）`
    : spec.message;
  return res.fail(spec.status, spec.code, msg);
}

router.get(
  '/',
  authMiddleware,
  requirePermission('tenant:view'),
  (req, res) => {
    const { page, pageSize, status, search, sort, order } = req.query;
    res.ok(store.sliceForPage({ page, pageSize, status, search, sort, order }));
  }
);

router.get(
  '/:id',
  authMiddleware,
  requirePermission('tenant:view'),
  (req, res) => {
    const tenant = store.findById(req.params.id);
    if (!tenant) return sendErr(res, 'not_found');
    res.ok(tenant);
  }
);

router.post(
  '/',
  authMiddleware,
  requirePermission('tenant:create'),
  (req, res) => {
    const { name, licenseTotal = 100 } = req.body || {};
    const result = store.createTenant({ name, licenseTotal });
    if (result.error) return sendErr(res, result.error);
    res.ok(result.tenant);
  }
);

router.put(
  '/:id',
  authMiddleware,
  requirePermission('tenant:edit'),
  (req, res) => {
    const { name } = req.body || {};
    const result = store.updateTenant(req.params.id, { name });
    if (result.error) return sendErr(res, result.error);
    res.ok(result.tenant);
  }
);

router.delete(
  '/:id',
  authMiddleware,
  requirePermission('tenant:delete'),
  (req, res) => {
    const result = store.removeTenant(req.params.id);
    if (result.error) return sendErr(res, result.error);
    res.ok({ id: result.removed.id });
  }
);

router.post(
  '/:id/status',
  authMiddleware,
  requirePermission('tenant:toggle'),
  (req, res) => {
    const { status } = req.body || {};
    const result = store.toggleStatus(req.params.id, status);
    if (result.error) return sendErr(res, result.error);
    res.ok(result.tenant);
  }
);

router.post(
  '/:id/license',
  authMiddleware,
  requirePermission('license:manage'),
  (req, res) => {
    const { licenseTotal } = req.body || {};
    const existing = store.findById(req.params.id);
    const result = store.adjustLicense(req.params.id, licenseTotal);
    if (result.error) return sendErr(res, result.error, existing);
    res.ok(result.tenant);
  }
);

module.exports = router;
```

- [ ] **Step 2：更新 `backend/server.js` 的 `ROUTE_TABLE`**

在 `tenants` 相关三行 `['GET',    '/api/tenants']`、`['POST',   '/api/tenants']` 等区域替换为：

```javascript
  ['GET',    '/api/tenants'],
  ['GET',    '/api/tenants/:id'],
  ['POST',   '/api/tenants'],
  ['PUT',    '/api/tenants/:id'],
  ['DELETE', '/api/tenants/:id'],
  ['POST',   '/api/tenants/:id/status'],
  ['POST',   '/api/tenants/:id/license'],
```

- [ ] **Step 3：curl 烟雾测试**

```bash
cd Mobile/backend && node server.js &
SERVER_PID=$!
sleep 1

curl -sS 'http://localhost:3001/api/tenants?pageSize=3&status=active&sort=name&order=asc' \
  -H 'Authorization: Bearer mock-token-ops' | jq .
# Expected: code=OK, items.length<=3

curl -sS -X POST 'http://localhost:3001/api/tenants' \
  -H 'Authorization: Bearer mock-token-ops' \
  -H 'Content-Type: application/json' \
  -d '{"name":"冒烟新建","licenseTotal":50}' | jq .
# Expected: code=OK, data.id 类似 tenant_00N

curl -sS 'http://localhost:3001/api/tenants/tenant_001' \
  -H 'Authorization: Bearer mock-token-ops' | jq .
# Expected: code=OK, data.name=华东示范牧场

curl -sS -X PUT 'http://localhost:3001/api/tenants/tenant_001' \
  -H 'Authorization: Bearer mock-token-ops' \
  -H 'Content-Type: application/json' \
  -d '{"name":"西部高原牧场"}' | jq .
# Expected: code=CONFLICT

curl -sS -X DELETE 'http://localhost:3001/api/tenants/tenant_006' \
  -H 'Authorization: Bearer mock-token-ops' | jq .
# Expected: code=OK

kill $SERVER_PID
```

- [ ] **Step 4：Commit**

```bash
cd Mobile
git add backend/routes/tenants.js backend/server.js
git commit -m "feat(backend): add GET/PUT/DELETE /api/tenants/:id and filter params"
```

---

## Task 4：前端领域层（Tenant / Query / ViewData）

**Files:**
- Create: `lib/features/tenant/domain/tenant.dart`
- Create: `lib/features/tenant/domain/tenant_query.dart`
- Create: `lib/features/tenant/domain/tenant_view_data.dart`
- Create: `lib/features/tenant/domain/tenant_repository.dart`
- Create: `lib/features/tenant/data/tenant_dto.dart`
- Create: `test/features/tenant/tenant_dto_test.dart`

- [ ] **Step 1：创建 `tenant.dart`**

```dart
enum TenantStatus {
  active('active'),
  disabled('disabled');

  const TenantStatus(this.wireValue);
  final String wireValue;

  static TenantStatus? tryParse(String? value) {
    for (final s in TenantStatus.values) {
      if (s.wireValue == value) return s;
    }
    return null;
  }
}

class Tenant {
  const Tenant({
    required this.id,
    required this.name,
    required this.status,
    required this.licenseUsed,
    required this.licenseTotal,
  });

  final String id;
  final String name;
  final TenantStatus status;
  final int licenseUsed;
  final int licenseTotal;

  double get licenseUsage =>
      licenseTotal == 0 ? 0 : licenseUsed / licenseTotal;

  Tenant copyWith({
    String? name,
    TenantStatus? status,
    int? licenseUsed,
    int? licenseTotal,
  }) {
    return Tenant(
      id: id,
      name: name ?? this.name,
      status: status ?? this.status,
      licenseUsed: licenseUsed ?? this.licenseUsed,
      licenseTotal: licenseTotal ?? this.licenseTotal,
    );
  }
}
```

- [ ] **Step 2：创建 `tenant_query.dart`**

```dart
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';

enum TenantSort { name, licenseUsage }

enum SortOrder { asc, desc }

class TenantListQuery {
  const TenantListQuery({
    this.search,
    this.status,
    this.sort = TenantSort.name,
    this.order = SortOrder.asc,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? search;
  final TenantStatus? status;
  final TenantSort sort;
  final SortOrder order;
  final int page;
  final int pageSize;

  TenantListQuery copyWith({
    String? search,
    TenantStatus? status,
    TenantSort? sort,
    SortOrder? order,
    int? page,
    int? pageSize,
    bool clearSearch = false,
    bool clearStatus = false,
  }) {
    return TenantListQuery(
      search: clearSearch ? null : (search ?? this.search),
      status: clearStatus ? null : (status ?? this.status),
      sort: sort ?? this.sort,
      order: order ?? this.order,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}
```

- [ ] **Step 3：创建 `tenant_view_data.dart`**

```dart
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_query.dart';

class TenantListViewData {
  const TenantListViewData({
    required this.viewState,
    required this.query,
    required this.tenants,
    required this.total,
    this.message,
  });

  final ViewState viewState;
  final TenantListQuery query;
  final List<Tenant> tenants;
  final int total;
  final String? message;

  int get pageCount =>
      total == 0 ? 1 : ((total + query.pageSize - 1) ~/ query.pageSize);
}

class TenantDetailViewData {
  const TenantDetailViewData({
    required this.viewState,
    this.tenant,
    this.message,
  });

  final ViewState viewState;
  final Tenant? tenant;
  final String? message;
}
```

- [ ] **Step 4：创建 `tenant_repository.dart`**

```dart
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_query.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';

abstract class TenantRepository {
  TenantListViewData loadList(TenantListQuery query);
  TenantDetailViewData loadDetail(String id);
}
```

- [ ] **Step 5：创建 `tenant_dto.dart`**

```dart
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';

class TenantDto {
  const TenantDto._();

  static Tenant? fromJson(Map<String, dynamic> json) {
    try {
      final status = TenantStatus.tryParse(json['status'] as String?);
      if (status == null) return null;
      return Tenant(
        id: json['id'] as String,
        name: json['name'] as String,
        status: status,
        licenseUsed: (json['licenseUsed'] as num).toInt(),
        licenseTotal: (json['licenseTotal'] as num).toInt(),
      );
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 6：写 `tenant_dto_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/features/tenant/data/tenant_dto.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';

void main() {
  test('TenantDto 完整 JSON 解析为 Tenant', () {
    final t = TenantDto.fromJson({
      'id': 'tenant_001',
      'name': '测试牧场',
      'status': 'active',
      'licenseUsed': 10,
      'licenseTotal': 100,
    });
    expect(t, isNotNull);
    expect(t!.name, '测试牧场');
    expect(t.status, TenantStatus.active);
    expect(t.licenseUsage, closeTo(0.1, 1e-9));
  });

  test('TenantDto 非法 status 返回 null', () {
    final t = TenantDto.fromJson({
      'id': 'x',
      'name': 'x',
      'status': 'xxx',
      'licenseUsed': 0,
      'licenseTotal': 0,
    });
    expect(t, isNull);
  });
}
```

- [ ] **Step 7：运行测试**

Run: `cd Mobile/mobile_app && flutter test test/features/tenant/tenant_dto_test.dart`
Expected: 2 个 case PASS。

- [ ] **Step 8：Commit**

```bash
cd Mobile
git add mobile_app/lib/features/tenant mobile_app/test/features/tenant/tenant_dto_test.dart
git commit -m "feat(tenant): add domain models and DTO for tenant module"
```

---

## Task 5：MockTenantRepository（TDD）

**Files:**
- Create: `lib/features/tenant/data/mock_tenant_repository.dart`
- Create: `test/features/tenant/mock_tenant_repository_test.dart`

- [ ] **Step 1：写 `mock_tenant_repository_test.dart` 失败用例**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/tenant/data/mock_tenant_repository.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_query.dart';

void main() {
  test('Mock 默认列表返回全部且 viewState=normal', () {
    final repo = MockTenantRepository();
    final data = repo.loadList(const TenantListQuery());
    expect(data.viewState, ViewState.normal);
    expect(data.tenants.length, greaterThan(0));
    expect(data.total, data.tenants.length);
  });

  test('Mock status 过滤只返回匹配项', () {
    final repo = MockTenantRepository();
    final data = repo.loadList(const TenantListQuery(status: TenantStatus.disabled));
    expect(data.tenants.every((t) => t.status == TenantStatus.disabled), isTrue);
  });

  test('Mock search 支持名称包含', () {
    final repo = MockTenantRepository();
    final data = repo.loadList(const TenantListQuery(search: '草原'));
    expect(data.tenants.every((t) => t.name.contains('草原')), isTrue);
  });

  test('Mock loadDetail 未命中返回 empty viewState', () {
    final repo = MockTenantRepository();
    final data = repo.loadDetail('tenant_unknown');
    expect(data.viewState, ViewState.empty);
    expect(data.tenant, isNull);
  });
}
```

- [ ] **Step 2：运行测试确认失败**

Run: `cd Mobile/mobile_app && flutter test test/features/tenant/mock_tenant_repository_test.dart`
Expected: FAIL（模块不存在）。

- [ ] **Step 3：实现 `mock_tenant_repository.dart`**

```dart
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_query.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_repository.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';

class MockTenantRepository implements TenantRepository {
  MockTenantRepository();

  static const List<Tenant> _seed = [
    Tenant(id: 'tenant_001', name: '华东示范牧场', status: TenantStatus.active, licenseUsed: 50, licenseTotal: 200),
    Tenant(id: 'tenant_002', name: '西部高原牧场', status: TenantStatus.active, licenseUsed: 120, licenseTotal: 200),
    Tenant(id: 'tenant_003', name: '东北黑土地牧场', status: TenantStatus.active, licenseUsed: 180, licenseTotal: 250),
    Tenant(id: 'tenant_004', name: '华南热带牧场', status: TenantStatus.disabled, licenseUsed: 30, licenseTotal: 100),
    Tenant(id: 'tenant_005', name: '西南高山牧场', status: TenantStatus.active, licenseUsed: 95, licenseTotal: 150),
    Tenant(id: 'tenant_006', name: '华北草原牧场', status: TenantStatus.active, licenseUsed: 75, licenseTotal: 180),
  ];

  @override
  TenantListViewData loadList(TenantListQuery query) {
    var filtered = List<Tenant>.from(_seed);
    if (query.status != null) {
      filtered = filtered.where((t) => t.status == query.status).toList();
    }
    final search = query.search?.trim();
    if (search != null && search.isNotEmpty) {
      final kw = search.toLowerCase();
      filtered = filtered.where((t) => t.name.toLowerCase().contains(kw)).toList();
    }
    final dir = query.order == SortOrder.desc ? -1 : 1;
    filtered.sort((a, b) {
      switch (query.sort) {
        case TenantSort.licenseUsage:
          return a.licenseUsage.compareTo(b.licenseUsage) * dir;
        case TenantSort.name:
          return a.name.compareTo(b.name) * dir;
      }
    });
    final total = filtered.length;
    final start = (query.page - 1) * query.pageSize;
    final items = start >= total
        ? <Tenant>[]
        : filtered.sublist(start, (start + query.pageSize).clamp(0, total));
    return TenantListViewData(
      viewState: items.isEmpty ? ViewState.empty : ViewState.normal,
      query: query,
      tenants: items,
      total: total,
      message: items.isEmpty ? '暂无租户' : null,
    );
  }

  @override
  TenantDetailViewData loadDetail(String id) {
    for (final t in _seed) {
      if (t.id == id) {
        return TenantDetailViewData(
          viewState: ViewState.normal,
          tenant: t,
        );
      }
    }
    return const TenantDetailViewData(
      viewState: ViewState.empty,
      message: '租户不存在',
    );
  }
}
```

- [ ] **Step 4：运行测试确认通过**

Run: `cd Mobile/mobile_app && flutter test test/features/tenant/mock_tenant_repository_test.dart`
Expected: 4 个 case PASS。

- [ ] **Step 5：Commit**

```bash
cd Mobile
git add mobile_app/lib/features/tenant/data/mock_tenant_repository.dart mobile_app/test/features/tenant/mock_tenant_repository_test.dart
git commit -m "feat(tenant): implement MockTenantRepository with filter/sort/paging"
```

---

## Task 6：ApiCache 扩展（租户相关远程调用）

**Files:**
- Modify: `lib/core/api/api_cache.dart`

- [ ] **Step 1：在 `ApiCache` 类中新增 tenants 相关方法**

在 `refreshFencesAndMap` 附近（`Future<bool> deleteFenceRemote(...)` 之前）插入以下方法：

```dart
Future<void> refreshTenants(String role) async {
  final headers = _headers(role);
  final data = await _get('/tenants?pageSize=100', headers);
  if (data != null) {
    _tenants = List<Map<String, dynamic>>.from(data['items'] ?? []);
  }
}

Future<Map<String, dynamic>?> fetchTenantDetail(String role, String id) async {
  final response = await http
      .get(Uri.parse('${resolveApiBaseUrl()}/tenants/$id'),
          headers: _headers(role))
      .timeout(const Duration(seconds: 20));
  if (response.statusCode == 200) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['code'] == 'OK') {
      return body['data'] as Map<String, dynamic>?;
    }
  }
  return null;
}

class TenantWriteResult {
  const TenantWriteResult({required this.ok, this.tenant, this.errorCode, this.statusCode, this.message});
  final bool ok;
  final Map<String, dynamic>? tenant;
  final String? errorCode;
  final int? statusCode;
  final String? message;
}
```

**注意**：`TenantWriteResult` 应定义在文件顶层（类外），保持与 `FenceSaveResult` 同级。把这段类声明挪到 `FenceSaveResult` 后面。

- [ ] **Step 2：添加写操作封装**

继续在 `ApiCache` 类内添加（可以放在 `updateFenceRemote` 之后）：

```dart
Future<TenantWriteResult> createTenantRemote(
  String role,
  Map<String, dynamic> body,
) async {
  final response = await http
      .post(
        Uri.parse('${resolveApiBaseUrl()}/tenants'),
        headers: _headers(role),
        body: jsonEncode(body),
      )
      .timeout(const Duration(seconds: 20));
  return _parseTenantWrite(response);
}

Future<TenantWriteResult> updateTenantRemote(
  String role,
  String id,
  Map<String, dynamic> body,
) async {
  final response = await http
      .put(
        Uri.parse('${resolveApiBaseUrl()}/tenants/$id'),
        headers: _headers(role),
        body: jsonEncode(body),
      )
      .timeout(const Duration(seconds: 20));
  return _parseTenantWrite(response);
}

Future<TenantWriteResult> toggleTenantStatusRemote(
  String role,
  String id,
  String status,
) async {
  final response = await http
      .post(
        Uri.parse('${resolveApiBaseUrl()}/tenants/$id/status'),
        headers: _headers(role),
        body: jsonEncode({'status': status}),
      )
      .timeout(const Duration(seconds: 20));
  return _parseTenantWrite(response);
}

Future<TenantWriteResult> adjustTenantLicenseRemote(
  String role,
  String id,
  int licenseTotal,
) async {
  final response = await http
      .post(
        Uri.parse('${resolveApiBaseUrl()}/tenants/$id/license'),
        headers: _headers(role),
        body: jsonEncode({'licenseTotal': licenseTotal}),
      )
      .timeout(const Duration(seconds: 20));
  return _parseTenantWrite(response);
}

Future<TenantWriteResult> deleteTenantRemote(String role, String id) async {
  final response = await http
      .delete(
        Uri.parse('${resolveApiBaseUrl()}/tenants/$id'),
        headers: _headers(role),
      )
      .timeout(const Duration(seconds: 20));
  return _parseTenantWrite(response);
}

TenantWriteResult _parseTenantWrite(http.Response response) {
  try {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['code'] == 'OK') {
      final data = body['data'];
      return TenantWriteResult(
        ok: true,
        tenant: data is Map<String, dynamic> ? data : null,
      );
    }
    return TenantWriteResult(
      ok: false,
      errorCode: body['code'] as String?,
      statusCode: response.statusCode,
      message: body['message'] as String?,
    );
  } catch (_) {
    return TenantWriteResult(ok: false, statusCode: response.statusCode);
  }
}
```

- [ ] **Step 3：添加测试辅助方法**

在 `ApiCache` 类末尾添加（供 Task 7 的 Live 仓库测试使用）：

```dart
@visibleForTesting
void debugReset() {
  _initialized = false;
  _tenants = [];
}

@visibleForTesting
void debugSetInitialized(bool value) {
  _initialized = value;
}

@visibleForTesting
void debugSetTenants(List<Map<String, dynamic>> value) {
  _tenants = value;
}
```

- [ ] **Step 4：静态分析**

Run: `cd Mobile/mobile_app && flutter analyze lib/core/api/api_cache.dart`
Expected: No issues found.

- [ ] **Step 5：Commit**

```bash
cd Mobile
git add mobile_app/lib/core/api/api_cache.dart
git commit -m "feat(api-cache): add tenant CRUD and license/status remote helpers"
```

---

## Task 7：LiveTenantRepository + Provider

**Files:**
- Create: `lib/features/tenant/data/live_tenant_repository.dart`
- Create: `test/features/tenant/live_tenant_repository_test.dart`

- [ ] **Step 1：写 `live_tenant_repository_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/tenant/data/live_tenant_repository.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_query.dart';

void main() {
  tearDown(() {
    ApiCache.instance.debugReset();
  });

  test('LiveRepository 未初始化时回退 Mock', () {
    final repo = LiveTenantRepository();
    final data = repo.loadList(const TenantListQuery());
    expect(data.viewState, anyOf(ViewState.normal, ViewState.empty));
  });

  test('LiveRepository 解析缓存返回正确状态', () {
    ApiCache.instance.debugSetInitialized(true);
    ApiCache.instance.debugSetTenants([
      {'id': 't1', 'name': '缓存A', 'status': 'active', 'licenseUsed': 10, 'licenseTotal': 100},
      {'id': 't2', 'name': '缓存B', 'status': 'disabled', 'licenseUsed': 5, 'licenseTotal': 50},
    ]);
    final repo = LiveTenantRepository();
    final data = repo.loadList(const TenantListQuery(status: TenantStatus.disabled));
    expect(data.tenants.length, 1);
    expect(data.tenants.first.name, '缓存B');
  });
}
```

- [ ] **Step 2：实现 `live_tenant_repository.dart`**

说明：`debugReset` / `debugSetInitialized` / `debugSetTenants` 三个测试辅助已在 Task 6 中写入 `ApiCache`，此处直接使用。

```dart
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/tenant/data/mock_tenant_repository.dart';
import 'package:smart_livestock_demo/features/tenant/data/tenant_dto.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_query.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_repository.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';

class LiveTenantRepository implements TenantRepository {
  LiveTenantRepository();

  final MockTenantRepository _fallback = MockTenantRepository();

  @override
  TenantListViewData loadList(TenantListQuery query) {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.tenants.isEmpty) {
      return _fallback.loadList(query);
    }
    var all = cache.tenants
        .map(TenantDto.fromJson)
        .whereType<Tenant>()
        .toList();
    if (query.status != null) {
      all = all.where((t) => t.status == query.status).toList();
    }
    final search = query.search?.trim();
    if (search != null && search.isNotEmpty) {
      final kw = search.toLowerCase();
      all = all.where((t) => t.name.toLowerCase().contains(kw)).toList();
    }
    final dir = query.order == SortOrder.desc ? -1 : 1;
    all.sort((a, b) {
      switch (query.sort) {
        case TenantSort.licenseUsage:
          return a.licenseUsage.compareTo(b.licenseUsage) * dir;
        case TenantSort.name:
          return a.name.compareTo(b.name) * dir;
      }
    });
    final total = all.length;
    final start = (query.page - 1) * query.pageSize;
    final items = start >= total
        ? <Tenant>[]
        : all.sublist(start, (start + query.pageSize).clamp(0, total));
    return TenantListViewData(
      viewState: items.isEmpty ? ViewState.empty : ViewState.normal,
      query: query,
      tenants: items,
      total: total,
      message: items.isEmpty ? '暂无租户' : null,
    );
  }

  @override
  TenantDetailViewData loadDetail(String id) {
    final cache = ApiCache.instance;
    if (!cache.initialized) return _fallback.loadDetail(id);
    Map<String, dynamic>? map;
    for (final t in cache.tenants) {
      if (t['id'] == id) {
        map = t;
        break;
      }
    }
    if (map == null) {
      return _fallback.loadDetail(id);
    }
    final tenant = TenantDto.fromJson(map);
    if (tenant == null) {
      return const TenantDetailViewData(
        viewState: ViewState.error,
        message: '租户数据解析失败',
      );
    }
    return TenantDetailViewData(
      viewState: ViewState.normal,
      tenant: tenant,
    );
  }
}
```

- [ ] **Step 3：运行测试确认通过**

Run: `cd Mobile/mobile_app && flutter test test/features/tenant/live_tenant_repository_test.dart`
Expected: 2 个 case PASS。

- [ ] **Step 4：Commit**

```bash
cd Mobile
git add mobile_app/lib/features/tenant/data/live_tenant_repository.dart mobile_app/test/features/tenant/live_tenant_repository_test.dart
git commit -m "feat(tenant): implement LiveTenantRepository with ApiCache fallback"
```

---

## Task 8：Controller（列表 + 详情）

**Files:**
- Create: `lib/features/tenant/presentation/tenant_list_controller.dart`
- Create: `lib/features/tenant/presentation/tenant_detail_controller.dart`
- Create: `test/features/tenant/tenant_list_controller_test.dart`

- [ ] **Step 1：写 `tenant_list_controller_test.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_query.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_list_controller.dart';

void main() {
  test('Controller 初始化使用默认 Query', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = container.read(tenantListControllerProvider);
    expect(data.query.page, 1);
    expect(data.query.status, isNull);
  });

  test('setStatus 更新 query.status 并重置 page=1', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(tenantListControllerProvider.notifier)
        .setStatus(TenantStatus.disabled);
    final data = container.read(tenantListControllerProvider);
    expect(data.query.status, TenantStatus.disabled);
    expect(data.query.page, 1);
  });

  test('setPage 翻到下一页', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(tenantListControllerProvider.notifier).setPage(2);
    final data = container.read(tenantListControllerProvider);
    expect(data.query.page, 2);
  });

  test('setSort 切换排序字段', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(tenantListControllerProvider.notifier)
        .setSort(TenantSort.licenseUsage, SortOrder.desc);
    final data = container.read(tenantListControllerProvider);
    expect(data.query.sort, TenantSort.licenseUsage);
    expect(data.query.order, SortOrder.desc);
  });
}
```

- [ ] **Step 2：运行测试确认失败**

Run: `cd Mobile/mobile_app && flutter test test/features/tenant/tenant_list_controller_test.dart`
Expected: FAIL。

- [ ] **Step 3：实现 `tenant_list_controller.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/features/tenant/data/live_tenant_repository.dart';
import 'package:smart_livestock_demo/features/tenant/data/mock_tenant_repository.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_query.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_repository.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return MockTenantRepository();
    case AppMode.live:
      return LiveTenantRepository();
  }
});

class TenantListController extends Notifier<TenantListViewData> {
  @override
  TenantListViewData build() {
    return ref.watch(tenantRepositoryProvider).loadList(const TenantListQuery());
  }

  void _reload(TenantListQuery query) {
    state = ref.read(tenantRepositoryProvider).loadList(query);
  }

  void setSearch(String? value) {
    _reload(state.query.copyWith(
      search: value,
      page: 1,
      clearSearch: value == null || value.isEmpty,
    ));
  }

  void setStatus(TenantStatus? status) {
    _reload(state.query.copyWith(
      status: status,
      page: 1,
      clearStatus: status == null,
    ));
  }

  void setSort(TenantSort sort, SortOrder order) {
    _reload(state.query.copyWith(sort: sort, order: order, page: 1));
  }

  void setPage(int page) {
    _reload(state.query.copyWith(page: page));
  }

  void refresh() {
    _reload(state.query);
  }
}

final tenantListControllerProvider =
    NotifierProvider<TenantListController, TenantListViewData>(
  TenantListController.new,
);
```

- [ ] **Step 4：实现 `tenant_detail_controller.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_list_controller.dart';

class TenantDetailController
    extends FamilyNotifier<TenantDetailViewData, String> {
  @override
  TenantDetailViewData build(String id) {
    return ref.watch(tenantRepositoryProvider).loadDetail(id);
  }

  void refresh() {
    state = ref.read(tenantRepositoryProvider).loadDetail(arg);
  }
}

final tenantDetailControllerProvider = NotifierProvider.family<
    TenantDetailController, TenantDetailViewData, String>(
  TenantDetailController.new,
);
```

- [ ] **Step 5：运行测试确认通过**

Run: `cd Mobile/mobile_app && flutter test test/features/tenant/tenant_list_controller_test.dart`
Expected: 4 个 case PASS。

- [ ] **Step 6：Commit**

```bash
cd Mobile
git add mobile_app/lib/features/tenant/presentation mobile_app/test/features/tenant/tenant_list_controller_test.dart
git commit -m "feat(tenant): add list/detail controllers with NotifierProvider(.family)"
```

---

## Task 9：权限扩展

**Files:**
- Modify: `lib/core/permissions/role_permission.dart`

- [ ] **Step 1：新增 tenant 相关静态方法**

在 `RolePermission` 类末尾追加：

```dart
static bool canManageTenants(DemoRole role) =>
    role == DemoRole.owner || role == DemoRole.ops;

static bool canCreateTenant(DemoRole role) => canManageTenants(role);

static bool canEditTenant(DemoRole role) => canManageTenants(role);

static bool canDeleteTenant(DemoRole role) => canManageTenants(role);

static bool canToggleTenantStatus(DemoRole role) => canManageTenants(role);

static bool canAdjustLicense(DemoRole role) => canManageTenants(role);
```

- [ ] **Step 2：静态分析**

Run: `cd Mobile/mobile_app && flutter analyze lib/core/permissions/role_permission.dart`

- [ ] **Step 3：Commit**

```bash
cd Mobile
git add mobile_app/lib/core/permissions/role_permission.dart
git commit -m "feat(permissions): add tenant management permission helpers"
```

---

## Task 10：通用分页组件 `PaginationBar`

**Files:**
- Create: `lib/widgets/pagination_bar.dart`
- Create: `test/features/tenant/pagination_bar_test.dart`

- [ ] **Step 1：写 widget 测试**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/widgets/pagination_bar.dart';

void main() {
  testWidgets('PaginationBar 显示当前页/总页数', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PaginationBar(
          page: 2,
          pageCount: 5,
          onPageChanged: (_) {},
        ),
      ),
    ));
    expect(find.text('2 / 5'), findsOneWidget);
  });

  testWidgets('点击下一页触发 onPageChanged(page+1)', (tester) async {
    int? received;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PaginationBar(
          page: 2,
          pageCount: 5,
          onPageChanged: (p) => received = p,
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('pagination-next')));
    expect(received, 3);
  });

  testWidgets('首页时上一页按钮禁用', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PaginationBar(
          page: 1,
          pageCount: 5,
          onPageChanged: (_) {},
        ),
      ),
    ));
    final prev = tester.widget<IconButton>(find.byKey(const Key('pagination-prev')));
    expect(prev.onPressed, isNull);
  });
}
```

- [ ] **Step 2：实现 `pagination_bar.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onPageChanged,
  });

  final int page;
  final int pageCount;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final canPrev = page > 1;
    final canNext = page < pageCount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            key: const Key('pagination-prev'),
            icon: const Icon(Icons.chevron_left),
            onPressed: canPrev ? () => onPageChanged(page - 1) : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('$page / $pageCount'),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            key: const Key('pagination-next'),
            icon: const Icon(Icons.chevron_right),
            onPressed: canNext ? () => onPageChanged(page + 1) : null,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3：运行测试**

Run: `cd Mobile/mobile_app && flutter test test/features/tenant/pagination_bar_test.dart`
Expected: 3 个 case PASS。

- [ ] **Step 4：Commit**

```bash
cd Mobile
git add mobile_app/lib/widgets/pagination_bar.dart mobile_app/test/features/tenant/pagination_bar_test.dart
git commit -m "feat(widgets): add generic PaginationBar"
```

---

## Task 11：租户列表页 `TenantListPage`

**Files:**
- Create: `lib/features/tenant/presentation/widgets/tenant_card.dart`
- Create: `lib/features/tenant/presentation/pages/tenant_list_page.dart`
- Create: `test/features/tenant/tenant_list_page_test.dart`

- [ ] **Step 1：实现 `tenant_card.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';

class TenantCard extends StatelessWidget {
  const TenantCard({
    super.key,
    required this.tenant,
    required this.onTap,
  });

  final Tenant tenant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final usageRatio = tenant.licenseUsage.clamp(0.0, 1.0);
    return HighfiCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        key: Key('tenant-card-${tenant.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tenant.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  HighfiStatusChip(
                    label: tenant.status == TenantStatus.active ? '启用中' : '已禁用',
                    color: tenant.status == TenantStatus.active
                        ? AppColors.success
                        : AppColors.danger,
                    icon: tenant.status == TenantStatus.active
                        ? Icons.check_circle_outline
                        : Icons.block_outlined,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'License ${tenant.licenseUsed} / ${tenant.licenseTotal}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: usageRatio,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2：实现 `tenant_list_page.dart`**

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_query.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_list_controller.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/widgets/tenant_card.dart';
import 'package:smart_livestock_demo/widgets/pagination_bar.dart';

class TenantListPage extends ConsumerStatefulWidget {
  const TenantListPage({super.key});

  @override
  ConsumerState<TenantListPage> createState() => _TenantListPageState();
}

class _TenantListPageState extends ConsumerState<TenantListPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(tenantListControllerProvider.notifier).setSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(tenantListControllerProvider);
    final ctrl = ref.read(tenantListControllerProvider.notifier);
    return Scaffold(
      key: const Key('page-tenant-list'),
      appBar: AppBar(
        title: const Text('租户管理'),
        actions: [
          IconButton(
            key: const Key('tenant-create-btn'),
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/ops/admin/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('tenant-search-input'),
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: '搜索租户名称',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                DropdownButton<TenantStatus?>(
                  key: const Key('tenant-status-filter'),
                  value: data.query.status,
                  hint: const Text('全部'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('全部')),
                    DropdownMenuItem(
                        value: TenantStatus.active, child: Text('启用')),
                    DropdownMenuItem(
                        value: TenantStatus.disabled, child: Text('禁用')),
                  ],
                  onChanged: ctrl.setStatus,
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(data, ctrl)),
        ],
      ),
    );
  }

  Widget _buildBody(data, TenantListController ctrl) {
    switch (data.viewState) {
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.error:
        return HighfiEmptyErrorState(
          title: '加载失败',
          description: data.message ?? '请稍后再试',
          icon: Icons.error_outline,
        );
      case ViewState.empty:
        return const HighfiEmptyErrorState(
          title: '暂无租户',
          description: '可点击右上角 + 创建新租户',
          icon: Icons.inbox_outlined,
        );
      case ViewState.forbidden:
        return const HighfiEmptyErrorState(
          title: '无权访问',
          description: '当前角色无法访问租户管理',
          icon: Icons.lock_outline_rounded,
        );
      case ViewState.offline:
        return const HighfiEmptyErrorState(
          title: '离线',
          description: '网络未连接，请稍后重试',
          icon: Icons.cloud_off_rounded,
        );
      case ViewState.normal:
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                key: const Key('tenant-list'),
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: data.tenants.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, idx) {
                  final t = data.tenants[idx];
                  return TenantCard(
                    tenant: t,
                    onTap: () => context.go('/ops/admin/${t.id}'),
                  );
                },
              ),
            ),
            PaginationBar(
              page: data.query.page,
              pageCount: data.pageCount,
              onPageChanged: ctrl.setPage,
            ),
          ],
        );
    }
  }
}
```

- [ ] **Step 3：写 `tenant_list_page_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/pages/tenant_list_page.dart';

void main() {
  testWidgets('TenantListPage 列表项渲染 mock 数据', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: const TenantListPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-tenant-list')), findsOneWidget);
    expect(find.text('华东示范牧场'), findsOneWidget);
    expect(find.text('西部高原牧场'), findsOneWidget);
  });
}
```

说明：由于此 widget 内含 `context.go(...)`，会要求 GoRouter。此处使用 `MaterialApp` 保持最小化，依赖 `DemoApp` 集成测试覆盖导航行为（在 Task 16 中完成）。因此本测试用 try/catch 包裹 onTap 场景或直接不触发 onTap 即可。若测试抛 Router 异常，改用 `overrides: [tenantListControllerProvider.overrideWith((ref) { ... })]` 的 Container 模式替代 `DemoApp`。

- [ ] **Step 4：运行测试**

Run: `cd Mobile/mobile_app && flutter test test/features/tenant/tenant_list_page_test.dart`

- [ ] **Step 5：Commit**

```bash
cd Mobile
git add mobile_app/lib/features/tenant/presentation mobile_app/test/features/tenant/tenant_list_page_test.dart
git commit -m "feat(tenant): add tenant list page with search/filter/pagination"
```

---

## Task 12：租户创建页 `TenantCreatePage`

**Files:**
- Create: `lib/features/tenant/presentation/pages/tenant_create_page.dart`

- [ ] **Step 1：实现创建页**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_list_controller.dart';

class TenantCreatePage extends ConsumerStatefulWidget {
  const TenantCreatePage({super.key});

  @override
  ConsumerState<TenantCreatePage> createState() => _TenantCreatePageState();
}

class _TenantCreatePageState extends ConsumerState<TenantCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController(text: '100');
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final mode = ref.read(appModeProvider);
    if (mode.isLive) {
      final role = ref.read(sessionControllerProvider).role?.name ?? 'ops';
      final result = await ApiCache.instance.createTenantRemote(role, {
        'name': _nameCtrl.text.trim(),
        'licenseTotal': int.parse(_licenseCtrl.text),
      });
      if (!mounted) return;
      if (!result.ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message ?? '创建失败'),
        ));
        setState(() => _submitting = false);
        return;
      }
      await ApiCache.instance.refreshTenants(role);
    }
    ref.read(tenantListControllerProvider.notifier).refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('租户创建成功')),
    );
    context.go('/ops/admin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('page-tenant-create'),
      appBar: AppBar(title: const Text('创建租户')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('tenant-create-name'),
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: '租户名称',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入租户名称' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('tenant-create-license'),
                controller: _licenseCtrl,
                decoration: const InputDecoration(
                  labelText: '初始 License',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 0) return '请输入非负整数';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                key: const Key('tenant-create-submit'),
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? '提交中…' : '创建'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2：静态分析**

Run: `cd Mobile/mobile_app && flutter analyze lib/features/tenant/presentation/pages/tenant_create_page.dart`

- [ ] **Step 3：Commit**

```bash
cd Mobile
git add mobile_app/lib/features/tenant/presentation/pages/tenant_create_page.dart
git commit -m "feat(tenant): add tenant create page"
```

---

## Task 13：租户详情页（基本信息卡片 + 操作）

**Files:**
- Create: `lib/features/tenant/presentation/widgets/license_adjust_dialog.dart`
- Create: `lib/features/tenant/presentation/widgets/tenant_delete_dialog.dart`
- Create: `lib/features/tenant/presentation/pages/tenant_detail_page.dart`

- [ ] **Step 1：实现 `license_adjust_dialog.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';

class LicenseAdjustDialog extends StatefulWidget {
  const LicenseAdjustDialog({super.key, required this.tenant});

  final Tenant tenant;

  @override
  State<LicenseAdjustDialog> createState() => _LicenseAdjustDialogState();
}

class _LicenseAdjustDialogState extends State<LicenseAdjustDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.tenant.licenseTotal.toString());
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final n = int.tryParse(_ctrl.text);
    if (n == null || n < 0) {
      setState(() => _error = '请输入非负整数');
      return;
    }
    if (n < widget.tenant.licenseUsed) {
      setState(() => _error = '新配额不能小于当前已使用量（${widget.tenant.licenseUsed}）');
      return;
    }
    Navigator.of(context).pop(n);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('调整 License 配额'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('当前已使用：${widget.tenant.licenseUsed}'),
          const SizedBox(height: 12),
          TextField(
            key: const Key('tenant-license-input'),
            controller: _ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: '新 License 配额',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          key: const Key('tenant-license-submit'),
          onPressed: _submit,
          child: const Text('确认调整'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2：实现 `tenant_delete_dialog.dart`**

```dart
import 'package:flutter/material.dart';

class TenantDeleteDialog extends StatefulWidget {
  const TenantDeleteDialog({super.key, required this.tenantName});

  final String tenantName;

  @override
  State<TenantDeleteDialog> createState() => _TenantDeleteDialogState();
}

class _TenantDeleteDialogState extends State<TenantDeleteDialog> {
  final _reasonCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_reasonCtrl.text.trim().isEmpty) {
      setState(() => _error = '请输入删除原因');
      return;
    }
    Navigator.of(context).pop(_reasonCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('删除租户'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('即将删除租户「${widget.tenantName}」。该操作不可撤销。'),
          const SizedBox(height: 12),
          TextField(
            key: const Key('tenant-delete-reason'),
            controller: _reasonCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: '删除原因',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          key: const Key('tenant-delete-confirm'),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _confirm,
          child: const Text('确认删除'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3：实现 `tenant_detail_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_detail_controller.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_list_controller.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/widgets/license_adjust_dialog.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/widgets/tenant_delete_dialog.dart';

class TenantDetailPage extends ConsumerWidget {
  const TenantDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(tenantDetailControllerProvider(id));
    return Scaffold(
      key: Key('page-tenant-detail-$id'),
      appBar: AppBar(title: const Text('租户详情')),
      body: _buildBody(context, ref, data),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, data) {
    if (data.viewState != ViewState.normal || data.tenant == null) {
      return HighfiEmptyErrorState(
        title: '无法加载',
        description: data.message ?? '租户不存在',
        icon: Icons.error_outline,
      );
    }
    final Tenant t = data.tenant!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HighfiCard(
            key: Key('tenant-detail-card-basic'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(t.name,
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    HighfiStatusChip(
                      label: t.status == TenantStatus.active ? '启用中' : '已禁用',
                      color: t.status == TenantStatus.active
                          ? AppColors.success
                          : AppColors.danger,
                      icon: t.status == TenantStatus.active
                          ? Icons.check_circle_outline
                          : Icons.block_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('License ${t.licenseUsed} / ${t.licenseTotal}'),
                const SizedBox(height: AppSpacing.xs),
                LinearProgressIndicator(
                  value: t.licenseUsage.clamp(0.0, 1.0),
                  minHeight: 6,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          HighfiCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('tenant-detail-edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('编辑'),
                  onPressed: () => context.go('/ops/admin/${t.id}/edit'),
                ),
                OutlinedButton.icon(
                  key: const Key('tenant-detail-toggle'),
                  icon: Icon(t.status == TenantStatus.active
                      ? Icons.block_outlined
                      : Icons.play_circle_outline),
                  label: Text(t.status == TenantStatus.active ? '禁用' : '启用'),
                  onPressed: () => _toggleStatus(context, ref, t),
                ),
                OutlinedButton.icon(
                  key: const Key('tenant-detail-license'),
                  icon: const Icon(Icons.tune),
                  label: const Text('调整 License'),
                  onPressed: () => _adjustLicense(context, ref, t),
                ),
                OutlinedButton.icon(
                  key: const Key('tenant-detail-delete'),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _deleteTenant(context, ref, t),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(BuildContext context, WidgetRef ref, Tenant t) async {
    final next = t.status == TenantStatus.active
        ? TenantStatus.disabled
        : TenantStatus.active;
    if (ref.read(appModeProvider).isLive) {
      final role = ref.read(sessionControllerProvider).role?.name ?? 'ops';
      final r = await ApiCache.instance
          .toggleTenantStatusRemote(role, t.id, next.wireValue);
      if (!context.mounted) return;
      if (!r.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(r.message ?? '状态切换失败')));
        return;
      }
      await ApiCache.instance.refreshTenants(role);
    }
    ref.read(tenantListControllerProvider.notifier).refresh();
    ref.read(tenantDetailControllerProvider(t.id).notifier).refresh();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('已更新租户状态')));
  }

  Future<void> _adjustLicense(BuildContext context, WidgetRef ref, Tenant t) async {
    final next = await showDialog<int>(
      context: context,
      builder: (_) => LicenseAdjustDialog(tenant: t),
    );
    if (next == null) return;
    if (ref.read(appModeProvider).isLive) {
      final role = ref.read(sessionControllerProvider).role?.name ?? 'ops';
      final r = await ApiCache.instance.adjustTenantLicenseRemote(role, t.id, next);
      if (!context.mounted) return;
      if (!r.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(r.message ?? 'License 调整失败')));
        return;
      }
      await ApiCache.instance.refreshTenants(role);
    }
    ref.read(tenantListControllerProvider.notifier).refresh();
    ref.read(tenantDetailControllerProvider(t.id).notifier).refresh();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('License 已调整')));
  }

  Future<void> _deleteTenant(BuildContext context, WidgetRef ref, Tenant t) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => TenantDeleteDialog(tenantName: t.name),
    );
    if (reason == null) return;
    if (ref.read(appModeProvider).isLive) {
      final role = ref.read(sessionControllerProvider).role?.name ?? 'ops';
      final r = await ApiCache.instance.deleteTenantRemote(role, t.id);
      if (!context.mounted) return;
      if (!r.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(r.message ?? '删除失败')));
        return;
      }
      await ApiCache.instance.refreshTenants(role);
    }
    ref.read(tenantListControllerProvider.notifier).refresh();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('租户已删除')));
    context.go('/ops/admin');
  }
}
```

**备注**：删除原因在 Demo 阶段仅用于 UI 反馈，后端接口当前不接受 `reason` 字段。Phase 2 引入操作日志后需扩展。

- [ ] **Step 4：写详情页 widget 测试**

`test/features/tenant/tenant_detail_page_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/pages/tenant_detail_page.dart';

void main() {
  testWidgets('TenantDetailPage 渲染已 seed 的租户', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: TenantDetailPage(id: 'tenant_001')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('华东示范牧场'), findsOneWidget);
    expect(find.byKey(const Key('tenant-detail-card-basic')), findsOneWidget);
    expect(find.byKey(const Key('tenant-detail-delete')), findsOneWidget);
  });

  testWidgets('TenantDetailPage 未命中时显示错误态', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: TenantDetailPage(id: 'tenant_unknown')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('无法加载'), findsOneWidget);
  });
}
```

- [ ] **Step 5：运行测试**

Run: `cd Mobile/mobile_app && flutter test test/features/tenant/tenant_detail_page_test.dart`

- [ ] **Step 6：Commit**

```bash
cd Mobile
git add mobile_app/lib/features/tenant/presentation mobile_app/test/features/tenant/tenant_detail_page_test.dart
git commit -m "feat(tenant): add detail page with status toggle / license adjust / delete"
```

---

## Task 14：租户编辑页 `TenantEditPage`（改名）

**Files:**
- Create: `lib/features/tenant/presentation/pages/tenant_edit_page.dart`

- [ ] **Step 1：实现**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_detail_controller.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_list_controller.dart';

class TenantEditPage extends ConsumerStatefulWidget {
  const TenantEditPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<TenantEditPage> createState() => _TenantEditPageState();
}

class _TenantEditPageState extends ConsumerState<TenantEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  bool _submitting = false;
  bool _inited = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    if (ref.read(appModeProvider).isLive) {
      final role = ref.read(sessionControllerProvider).role?.name ?? 'ops';
      final r = await ApiCache.instance.updateTenantRemote(role, widget.id, {
        'name': _nameCtrl.text.trim(),
      });
      if (!mounted) return;
      if (!r.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(r.message ?? '更新失败')));
        setState(() => _submitting = false);
        return;
      }
      await ApiCache.instance.refreshTenants(role);
    }
    ref.read(tenantListControllerProvider.notifier).refresh();
    ref.read(tenantDetailControllerProvider(widget.id).notifier).refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('租户信息已更新')));
    context.go('/ops/admin/${widget.id}');
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(tenantDetailControllerProvider(widget.id));
    if (!_inited && detail.tenant != null) {
      _nameCtrl.text = detail.tenant!.name;
      _inited = true;
    }
    return Scaffold(
      key: Key('page-tenant-edit-${widget.id}'),
      appBar: AppBar(title: const Text('编辑租户')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('tenant-edit-name'),
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: '租户名称',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入租户名称' : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                key: const Key('tenant-edit-submit'),
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? '保存中…' : '保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2：静态分析**

Run: `cd Mobile/mobile_app && flutter analyze lib/features/tenant/presentation/pages/tenant_edit_page.dart`

- [ ] **Step 3：Commit**

```bash
cd Mobile
git add mobile_app/lib/features/tenant/presentation/pages/tenant_edit_page.dart
git commit -m "feat(tenant): add tenant edit page (rename only in phase 1)"
```

---

## Task 15：路由接入 `/ops/admin`

**Files:**
- Modify: `lib/app/app_router.dart`

- [ ] **Step 1：替换 `/ops/admin` 路由**

找到 `app_router.dart` 中：

```dart
GoRoute(
  path: AppRoute.opsAdmin.path,
  name: AppRoute.opsAdmin.routeName,
  builder: (context, state) => const AdminPage(),
),
```

替换为：

```dart
GoRoute(
  path: AppRoute.opsAdmin.path,
  name: AppRoute.opsAdmin.routeName,
  builder: (context, state) => const TenantListPage(),
  routes: [
    GoRoute(
      path: 'create',
      name: 'ops-tenant-create',
      builder: (context, state) => const TenantCreatePage(),
    ),
    GoRoute(
      path: ':id',
      name: 'ops-tenant-detail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TenantDetailPage(id: id);
      },
      routes: [
        GoRoute(
          path: 'edit',
          name: 'ops-tenant-edit',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return TenantEditPage(id: id);
          },
        ),
      ],
    ),
  ],
),
```

- [ ] **Step 2：在文件顶部追加 import**

```dart
import 'package:smart_livestock_demo/features/tenant/presentation/pages/tenant_create_page.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/pages/tenant_detail_page.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/pages/tenant_edit_page.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/pages/tenant_list_page.dart';
```

- [ ] **Step 3：更新 redirect 兼容**

`app_router.dart` 当前 redirect 里 `location == AppRoute.opsAdmin.path` 会把 non-ops 角色踢走；子路由 `/ops/admin/create` 也要被拦截。将：

```dart
if (location == AppRoute.login.path ||
    location == AppRoute.opsAdmin.path) {
  return AppRoute.twin.path;
}
```

替换为：

```dart
if (location == AppRoute.login.path ||
    location.startsWith(AppRoute.opsAdmin.path)) {
  return AppRoute.twin.path;
}
```

并且 `if (role == DemoRole.ops) { return location == AppRoute.opsAdmin.path ? null : AppRoute.opsAdmin.path; }` 替换为：

```dart
if (role == DemoRole.ops) {
  return location.startsWith(AppRoute.opsAdmin.path)
      ? null
      : AppRoute.opsAdmin.path;
}
```

- [ ] **Step 4：静态分析 + 现有测试全部跑一遍**

Run:
```bash
cd Mobile/mobile_app && flutter analyze && flutter test
```

Expected: `flutter analyze` 无错误；已有测试全部通过（可能 `flow_smoke_test.dart` 中 ops 场景需要在下一 Task 调整）。

- [ ] **Step 5：Commit**

```bash
cd Mobile
git add mobile_app/lib/app/app_router.dart
git commit -m "feat(router): mount tenant module at /ops/admin with child routes"
```

---

## Task 16：回归测试与流程对齐

**Files:**
- Modify: `test/flow_smoke_test.dart`
- Modify: `test/role_visibility_test.dart`（若断言包含 `tenant-license-demo-applied`）
- Modify: `test/mock_repository_override_test.dart`（可选）

- [ ] **Step 1：更新 `flow_smoke_test.dart` 中 ops 流程**

找到 `testWidgets('流程1：ops 直达租户后台'...` 测试。原断言期望 `tenant-license-demo-applied` 这类 key。替换为校验 `page-tenant-list` 与 `华东示范牧场` 文本。示例：

```dart
testWidgets('流程1：ops 直达租户列表', (tester) async {
  await tester.pumpWidget(const DemoApp());
  await tester.tap(find.byKey(const Key('role-ops')));
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('page-tenant-list')), findsOneWidget);
  expect(find.text('华东示范牧场'), findsOneWidget);
});
```

- [ ] **Step 2：更新 owner 流程中 `tenant-license-adjust` 断言（若存在）**

owner 流程里如果还期望 `/admin` 老占位页的 `tenant-license-adjust` 按钮，保留断言（owner 的 `/admin` 路由仍指向旧 `AdminPage`）。如果断言是在 `/ops/admin` 下进行，请改为导航到新 tenant list page 并校验列表即可。

- [ ] **Step 3：全量测试**

Run:
```bash
cd Mobile/mobile_app && flutter analyze && flutter test
```

Expected: analyze 无错误；所有测试（已有 + 新增）全部通过。

- [ ] **Step 4：Commit**

```bash
cd Mobile
git add mobile_app/test
git commit -m "test(tenant): update ops smoke test to target new tenant list page"
```

---

## Task 17：端到端手工验证（Live 模式）

**Files:**（无代码改动）

- [ ] **Step 1：启动 Mock Server**

```bash
cd Mobile/backend && node server.js
```

- [ ] **Step 2：启动 Flutter（Live 模式）**

```bash
cd Mobile/mobile_app && flutter run -d chrome --dart-define=APP_MODE=live --dart-define=API_BASE_URL=http://127.0.0.1:3001/api
```

- [ ] **Step 3：手工走查清单**

1. 以 `ops` 登录，验证直达 `/ops/admin` 展示 6 条租户。
2. 搜索「草原」仅剩 1 条。
3. 状态筛选 `disabled` 仅剩 1 条。
4. 点击「+」创建租户「冒烟测试牧场」/ License 50 → 成功提示，列表新增。
5. 进入租户详情，点击「调整 License」输入 30 → 报错「不能小于已使用量」；输入 200 → 成功。
6. 切换状态为「禁用」→ 列表回显 `已禁用`。
7. 点击「编辑」改名为已存在名称「华东示范牧场」→ 报错 `CONFLICT`。
8. 改名为「华东示范牧场（改）」→ 成功。
9. 删除租户 → 弹窗输入「演示清理」→ 成功提示；列表移除。
10. 以 `worker` 登录 → 被路由重定向到 `/twin`，无法访问 `/ops/admin`。

- [ ] **Step 4：在 plan 末尾「完成记录」表格登记**

```markdown
| 2026-04-XX | #N | #PR | Phase 1 MVP 合并 |
```

- [ ] **Step 5：Commit（仅文档）**

```bash
cd Mobile
git add docs/superpowers/plans/2026-04-20-tenant-management-implementation.md
git commit -m "docs(plan): record tenant management phase 1 completion"
```

---

## 验收清单（Definition of Done）

**架构**
- [ ] `features/tenant/` 模块遵循 domain / data / presentation 三层。
- [ ] Controller 全部为同步方法 + `state = repository.load(...)`。
- [ ] 列表、详情分别由独立 Provider 管理。

**API**
- [ ] 所有成功响应使用 `{ code, message, requestId, data }` 包络。
- [ ] 列表分页字段为 `{ items, page, pageSize, total }`。
- [ ] 参数与字段命名对齐（`licenseTotal` / `status`）。
- [ ] 名称冲突返回 409，License 低于已用返回 422。

**UI**
- [ ] 详情页使用卡片堆叠；无 Tab 依赖。
- [ ] 删除交互为单次 AlertDialog + 原因输入。
- [ ] 通用 `PaginationBar` 上线。
- [ ] 列表搜索具备 300ms 防抖。

**行为**
- [ ] `ops` 登录直达 `/ops/admin` 并看到租户列表。
- [ ] Mock / Live 双模式 CRUD 均可运行。
- [ ] `flutter analyze` 无错误。
- [ ] `flutter test` 全部通过。
- [ ] `node --test backend/test` 全部通过。

---

**计划版本**：v1.0
**创建日期**：2026-04-20
**状态**：待评审
