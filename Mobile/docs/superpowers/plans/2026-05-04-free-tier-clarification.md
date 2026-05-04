# Free Tier 澄清实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 消除 Phase 2b 规格中 free tier 定义模糊，添加双路径种子数据，更新规格文档。

**Architecture:** 统一 free tier 模型，不区分来源。新增 2 个种子 tenant（api 试用 + enterprise farm）和对应的 apiTierStore/apiKeyStore 记录。代码层面仅修改数据种子文件，无需改动 Store 接口或中间件。

**Tech Stack:** Node.js (Mock Server 数据层)、Markdown (规格文档)

**Spec:** `docs/superpowers/specs/2026-05-04-free-tier-clarification-design.md`

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `backend/data/seed.js` | 新增 tenant_a002 + tenant_008 种子记录 |
| Modify | `backend/data/apiTierStore.js` | 新增两条 free tier 初始记录 |
| Modify | `backend/test/apiTierStore.test.js` | 新增 free tier 查询测试 + 更新 resetMonthlyUsage 计数 |
| Modify | `backend/test/tenantStore.test.js` | 更新 total 计数（12→14） |
| Modify | `docs/superpowers/specs/2026-05-02-unified-business-model-phase2b-design.md` | 替换 L616 模糊注释、新增种子描述、新增触发路径小节 |

---

### Task 1: apiTierStore — 新增 free tier 初始记录

**Files:**
- Modify: `backend/data/apiTierStore.js:4-13` (`_initialTiers` 数组)
- Test: `backend/test/apiTierStore.test.js`

- [ ] **Step 1: 写失败测试 — 验证 free tier 种子数据存在**

在 `backend/test/apiTierStore.test.js` 的 `describe('apiTierStore', ...)` 块内（`resetMonthlyUsage` 测试之前）新增：

```javascript
test('getByTenantId returns free tier for tenant_a002 (free trial)', () => {
  const tier = store.getByTenantId('tenant_a002');
  assert.ok(tier);
  assert.equal(tier.apiTenantId, 'tenant_a002');
  assert.equal(tier.tier, 'free');
  assert.equal(tier.monthlyQuota, 1000);
  assert.equal(tier.usedThisMonth, 0);
  assert.equal(tier.overageUnitPrice, 0);
  assert.equal(tier.resetAt, null);
});

test('getByTenantId returns free tier for tenant_008 (enterprise farm)', () => {
  const tier = store.getByTenantId('tenant_008');
  assert.ok(tier);
  assert.equal(tier.apiTenantId, 'tenant_008');
  assert.equal(tier.tier, 'free');
  assert.equal(tier.monthlyQuota, 1000);
  assert.equal(tier.usedThisMonth, 0);
  assert.equal(tier.overageUnitPrice, 0);
  assert.equal(tier.resetAt, null);
});
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd Mobile && node --test backend/test/apiTierStore.test.js`
Expected: FAIL — `getByTenantId('tenant_a002')` 返回 null

- [ ] **Step 3: 实现最小变更 — 在 `_initialTiers` 数组中新增两条记录**

在 `backend/data/apiTierStore.js` 的 `_initialTiers` 数组中，在现有的 `tenant_a001` 记录后面追加：

```javascript
  {
    apiTenantId: 'tenant_a002',
    tier: 'free',
    monthlyQuota: 1000,
    usedThisMonth: 0,
    overageUnitPrice: 0,
    resetAt: null,
  },
  {
    apiTenantId: 'tenant_008',
    tier: 'free',
    monthlyQuota: 1000,
    usedThisMonth: 0,
    overageUnitPrice: 0,
    resetAt: null,
  },
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd Mobile && node --test backend/test/apiTierStore.test.js`
Expected: 全部 PASS

- [ ] **Step 5: 修复 resetMonthlyUsage 测试中的计数断言**

现有测试 `resetMonthlyUsage resets at month boundary` 断言 `count === 1`（只有 tenant_a001）。现在有 3 条记录，需改为：

```javascript
assert.equal(count, 3); // tenant_a001 + tenant_a002 + tenant_008
```

- [ ] **Step 6: 再次运行全部 apiTierStore 测试**

Run: `cd Mobile && node --test backend/test/apiTierStore.test.js`
Expected: 全部 PASS

- [ ] **Step 7: 提交**

```bash
cd Mobile
git add backend/data/apiTierStore.js backend/test/apiTierStore.test.js
git commit -m "feat(data): add free tier seed records for tenant_a002 and tenant_008 — #38"
```

---

### Task 2: seed.js — 新增 tenant_a002 和 tenant_008

**Files:**
- Modify: `backend/data/seed.js` (在 `tenant_a001` 之后插入 `tenant_a002`，在最后插入 `tenant_008`)
- Test: `backend/test/tenantStore.test.js`

- [ ] **Step 1: 写失败测试 — 验证新 tenant 可被查询到**

在 `backend/test/tenantStore.test.js` 中新增：

```javascript
test('tenantStore: seed includes tenant_a002 (api free trial)', () => {
  store.reset();
  const t = store.findById('tenant_a002');
  assert.ok(t, 'tenant_a002 should exist in seed');
  assert.equal(t.type, 'api');
  assert.equal(t.apiTier, 'free');
  assert.equal(t.apiCallQuota, 1000);
  assert.deepEqual(t.accessibleFarmTenantIds, ['tenant_001']);
});

test('tenantStore: seed includes tenant_008 (enterprise farm with API)', () => {
  store.reset();
  const t = store.findById('tenant_008');
  assert.ok(t, 'tenant_008 should exist in seed');
  assert.equal(t.type, 'farm');
  assert.equal(t.entitlementTier, 'enterprise');
  assert.equal(t.apiTier, 'free');
  assert.equal(t.apiCallQuota, 1000);
  assert.deepEqual(t.accessibleFarmTenantIds, ['tenant_008']);
});
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd Mobile && node --test backend/test/tenantStore.test.js`
Expected: FAIL — `findById('tenant_a002')` 返回 undefined

- [ ] **Step 3: 在 seed.js 中新增 tenant_a002**

在 `backend/data/seed.js` 中 `tenant_a001` 的闭合 `}` 之后、`tenant_p002` 之前，插入：

```javascript
  {
    id: 'tenant_a002',
    name: '试点集成商',
    type: 'api',
    parentTenantId: null,
    billingModel: 'api_usage',
    entitlementTier: null,
    ownerId: null,
    status: 'active',
    contactName: '李集成',
    contactPhone: '13900080008',
    contactEmail: 'lijicheng@trialint.cn',
    region: null,
    remarks: '新注册 API 开发者，free tier 试用中。',
    licenseUsed: 0,
    licenseTotal: 0,
    createdAt: '2026-05-04T00:00:00+08:00',
    updatedAt: '2026-05-04T00:00:00+08:00',
    lastUpdatedBy: '系统初始化',
    contractId: null,
    revenueShareRatio: null,
    deploymentType: null,
    serviceKey: null,
    heartbeatAt: null,
    apiTier: 'free',
    apiKey: null,
    apiCallQuota: 1000,
    accessibleFarmTenantIds: ['tenant_001'],
    deviceConfigRatio: null,
    livestockCount: null,
  },
```

- [ ] **Step 4: 在 seed.js 末尾新增 tenant_008**

在 seed 数组的最后一个 tenant 之后（数组闭合 `]` 之前）插入：

```javascript
  {
    id: 'tenant_008',
    name: '中原旗舰牧场',
    type: 'farm',
    parentTenantId: null,
    billingModel: 'direct',
    entitlementTier: 'enterprise',
    ownerId: null,
    status: 'active',
    contactName: '陈旗舰',
    contactPhone: '13900080009',
    contactEmail: 'chenqj@centralflagship.cn',
    region: '华中',
    remarks: 'Enterprise 订阅牧场，已手动开启 API 访问。',
    licenseUsed: 200,
    licenseTotal: 500,
    createdAt: '2026-05-04T00:00:00+08:00',
    updatedAt: '2026-05-04T00:00:00+08:00',
    lastUpdatedBy: '系统初始化',
    contractId: null,
    revenueShareRatio: null,
    deploymentType: null,
    serviceKey: null,
    heartbeatAt: null,
    apiTier: 'free',
    apiKey: null,
    apiCallQuota: 1000,
    accessibleFarmTenantIds: ['tenant_008'],
    deviceConfigRatio: null,
    livestockCount: null,
  },
```

- [ ] **Step 5: 更新 tenantStore 测试中的 total 计数**

现有测试 `sliceForPage 默认分页返回全部` 断言 `total === 12` 和 `items.length === 12`。新增 2 个 tenant 后改为 14：

```javascript
assert.equal(res.total, 14);
assert.equal(res.items.length, 14);
```

- [ ] **Step 6: 运行全部 tenantStore 测试**

Run: `cd Mobile && node --test backend/test/tenantStore.test.js`
Expected: 全部 PASS

- [ ] **Step 7: 运行全量后端测试确认无回归**

Run: `cd Mobile && node --test backend/test/*.test.js`
Expected: 全部 PASS

- [ ] **Step 8: 提交**

```bash
cd Mobile
git add backend/data/seed.js backend/test/tenantStore.test.js
git commit -m "feat(data): add tenant_a002 (free trial) and tenant_008 (enterprise farm) — #38"
```

---

### Task 3: apiKeyStore — 为 tenant_008 生成 seed API Key

**Files:**
- Modify: `backend/data/apiKeyStore.js` (或在 `server.js` 初始化阶段调用 generate)
- Test: `backend/test/apiKeyStore.test.js`

注意：apiKeyStore 的 `generate()` 需要依赖 tenantStore（更新 tenant 的 apiKey 字段）。最简洁的做法是在 server.js 初始化时调用 `apiKeyStore.generate('tenant_008')`，但这会引入启动副作用。更好的做法是在 seed 数据中直接预置一条 key 记录。

- [ ] **Step 1: 写失败测试 — 验证 tenant_008 有 seed API Key**

在 `backend/test/apiKeyStore.test.js` 中新增：

```javascript
test('apiKeyStore: seed key exists for tenant_008 (enterprise farm)', () => {
  // apiKeyStore.reset() restores initial state including seed key
  const keys = store.listByTenantId('tenant_008');
  assert.equal(keys.length, 1, 'tenant_008 should have exactly one seed key');
  assert.equal(keys[0].status, 'active');
});

test('apiKeyStore: validate seed key for tenant_008 end-to-end', () => {
  const result = store.validate('sl_apikey_seed_tenant_008_0000000000000001');
  assert.ok(result, 'seed key should validate');
  assert.equal(result.apiTenantId, 'tenant_008');
  assert.equal(result.apiTier, 'free');
});
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd Mobile && node --test backend/test/apiKeyStore.test.js`
Expected: FAIL — `keys.length === 0`

- [ ] **Step 3: 在 apiKeyStore 的 reset() 中添加 seed key**

在 `backend/data/apiKeyStore.js` 中，修改 `reset()` 函数，在 `_keys = []; _nextId = 1;` 之后添加 seed key 的初始化。为了避免硬编码 hash，使用一个固定的 raw key 并计算 hash：

```javascript
function reset() {
  _keys = [];
  _nextId = 1;

  // Seed key for tenant_008 (enterprise farm, free tier)
  const seedRawKey = 'sl_apikey_seed_tenant_008_0000000000000001';
  const seedKeyHash = _hashKey(seedRawKey);
  _keys.push({
    keyId: 'apikey_seed_008',
    apiTenantId: 'tenant_008',
    keyHash: seedKeyHash,
    keyPrefix: seedRawKey.substring(0, 10),
    keySuffix: seedRawKey.substring(seedRawKey.length - 4),
    status: 'active',
    createdAt: '2026-05-04T00:00:00+08:00',
    rotatedAt: null,
  });
  _nextId = 2;
}
```

同时需要将 seed key 的 hash 同步到 tenantStore 中 tenant_008 的 `apiKey` 字段。在 `seed.js` 中 tenant_008 的 `apiKey` 字段设置为此 hash 值。计算方式：

```bash
node -e "const crypto = require('crypto'); console.log(crypto.createHash('sha256').update('sl_apikey_seed_tenant_008_0000000000000001').digest('hex'))"
```

将输出的 hash 填入 `seed.js` 中 tenant_008 的 `apiKey` 字段。

- [ ] **Step 4: 运行测试确认通过**

Run: `cd Mobile && node --test backend/test/apiKeyStore.test.js`
Expected: 全部 PASS

- [ ] **Step 5: 运行全量后端测试确认无回归**

Run: `cd Mobile && node --test backend/test/*.test.js`
Expected: 全部 PASS

- [ ] **Step 6: 提交**

```bash
cd Mobile
git add backend/data/apiKeyStore.js backend/data/seed.js backend/test/apiKeyStore.test.js
git commit -m "feat(data): add seed API key for tenant_008 (enterprise farm) — #38"
```

---

### Task 4: 规格文档更新 — 修正 phase2b-design.md

**Files:**
- Modify: `docs/superpowers/specs/2026-05-02-unified-business-model-phase2b-design.md`

- [ ] **Step 1: 替换 L616 模糊注释**

将：
```
free tier (捆绑 enterprise 订阅，或 api_consumer 最小起步为 growth):
```

替换为：
```
free tier — API 试用层（零费用。触发路径：① api_consumer 注册后自动获得；② enterprise 牧场主手动开启 API 访问后获得。详见"Free Tier 触发路径"小节）:
```

- [ ] **Step 2: 更新种子数据段（9.4 节）**

在 `### 9.4 种子数据扩展` 的代码块末尾（`tenant_f_p002_001` 之后），追加：

```javascript
// 新增 API 开发者（free tier 试用）
// tenant_a002: type='api', billingModel='api_usage', apiTier='free', apiCallQuota=1000,
//   accessibleFarmTenantIds=['tenant_001']

// 新增 Enterprise 牧场（已开启 API 访问）
// tenant_008: type='farm', entitlementTier='enterprise', apiTier='free', apiCallQuota=1000,
//   accessibleFarmTenantIds=['tenant_008']
```

- [ ] **Step 3: 新增"Free Tier 触发路径"小节**

在 G1 端点清单之前（即 `## G1: Open API 端点` 之前），插入：

```markdown
### Free Tier 触发路径

free tier 有两条独立的触发路径，代码层面统一处理（apiTierStore 不区分来源）：

**路径 1 — API 开发者试用**：api_consumer 注册后自动获得 free tier。种子数据 `tenant_a002` 演示此路径。现有 `tenant_a001`（growth）演示已升级状态。

**路径 2 — Enterprise 订阅增值权益**：enterprise 牧场主手动开启 API 访问后获得 free tier。系统在 farm tenant 上设置 `apiTier='free'`，生成 API Key，apiTierStore 创建对应记录。种子数据 `tenant_008` 演示此路径。

**降级处理**：enterprise 订阅降为 pro/basic 时，API 访问挂起（403 + 升级提示），API Key 不删除，升级后自动恢复。Demo 阶段简化为降级即挂起。
```

- [ ] **Step 4: 提交**

```bash
cd Mobile
git add docs/superpowers/specs/2026-05-02-unified-business-model-phase2b-design.md
git commit -m "docs(spec): clarify free tier trigger paths and update seed data — #38"
```

---

### Task 5: 全量验证 + 认领 Issue

- [ ] **Step 1: 运行全量后端测试**

Run: `cd Mobile && node --test backend/test/*.test.js`
Expected: 全部 PASS

- [ ] **Step 2: 启动 Mock Server 验证端点**

```bash
cd Mobile/backend && node server.js &
curl -s http://localhost:3001/api/open/v1/twin/health/1 -H "X-API-Key: sl_apikey_seed_tenant_008_0000000000000001" | head -5
kill %1
```

Expected: 返回 JSON 响应（认证通过，但因 tenant_008 的 accessibleFarms 仅含自身而种子动物属于 tenant_001，会返回 404 NOT_FOUND。此响应证明 API Key 认证链路正常工作，非 401/403 即为通过）

- [ ] **Step 3: 认领 Issue**

```bash
cd /Users/hkt/wzy/产品开发/smart-livestock
gh issue edit 38 --add-assignee aime4eve
```

- [ ] **Step 4: 最终提交（如有未提交的改动）**

```bash
git status  # 确认无遗留改动
```
