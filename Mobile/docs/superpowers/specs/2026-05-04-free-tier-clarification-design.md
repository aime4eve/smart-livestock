# Free Tier 定义澄清设计

**日期**: 2026-05-04
**关联 Issue**: #38
**状态**: Draft

## 背景

Phase 2b 规格 G1 章节 Open API 端点清单中，free tier 的定义模糊：

> free tier (捆绑 enterprise 订阅，或 api_consumer 最小起步为 growth)

这句话存在矛盾：
1. 如果 api_consumer 最小起步为 growth，free tier 谁在使用？
2. "捆绑 enterprise 订阅" 的触发条件未定义
3. seed 数据中 api_consumer（tenant_a001）直接是 growth，free tier 无种子数据支撑

## 设计决策

### 方案选择

**统一 free tier，触发条件仅文档约束**（方案 B）。

free tier 是一种 tier，不区分来源（无 tierSource 字段）。两条触发路径的差异由规格文档约束，代码层面 apiTierStore 统一处理。升级路径统一：free → growth → scale，不论来源。

选择理由：Demo + Mock 阶段，来源追踪等真实差异化定价场景出现时再引入字段。

## Free Tier 定义

```
free — API 试用层，零费用
  触发路径：
    1. api_consumer 注册后自动获得（开发者试用）
    2. enterprise 牧场主手动开启 API 访问后获得（订阅增值权益）
  端点：
    GET /api/open/v1/twin/fever/:id
    GET /api/open/v1/twin/estrus/:id
    GET /api/open/v1/twin/digestive/:id
    GET /api/open/v1/twin/health/:id
  配额：1,000 calls/月
  速率：10 calls/min
  升级：free → growth → scale（统一路径，不区分来源）
```

## 路径 1：API 开发者试用

- api_consumer 注册后自动获得 free tier
- 种子数据中 `tenant_a002`（type='api'）演示此路径
- 保留现有 `tenant_a001`（growth）演示已升级状态

## 路径 2：Enterprise 订阅增值权益

### 激活流程

1. enterprise 牧场主在开发者门户或设置页点击"开启 API 访问"
2. 系统在 farm tenant 上设置 `apiTier='free'`，生成 API Key
3. apiTierStore 创建对应记录（`apiTenantId = farmTenantId`）
4. 用户用 API Key 访问 Open API，走与 api_consumer 完全相同的认证链

### 数据模型

API Key 挂在 farm tenant 上（复用现有 tenant，不创建子 tenant）。apiTierStore 以 `apiTenantId` 为查询键，farm tenant 的 id 直接作为 `apiTenantId` 使用。

### 降级处理

- enterprise 订阅降为 pro/basic → 当前计费周期结束后 API 挂起（403 + 升级提示）
- Demo 简化：降级即挂起，不模拟计费周期
- API Key 不删除，升级后自动恢复

## 种子数据变更

### 新增 tenant_a002（API 开发者，free 试用）

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
  apiTier: 'free',
  apiCallQuota: 1000,
  accessibleFarmTenantIds: ['tenant_001'],
  // 预设 G3 授权（seed 数据跳过授权审批流程，Demo 直接可用）
}
```

### 新增 tenant_008（Enterprise 牧场，已开启 API）

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
  apiTier: 'free',
  apiCallQuota: 1000,
  accessibleFarmTenantIds: ['tenant_008'],
  // enterprise 访问自身牧场数据；其余 Phase 2 字段为 null
}
```

### apiTierStore 新增记录

```javascript
{ apiTenantId: 'tenant_a002', tier: 'free', monthlyQuota: 1000, usedThisMonth: 0, overageUnitPrice: 0, resetAt: null }
{ apiTenantId: 'tenant_008', tier: 'free', monthlyQuota: 1000, usedThisMonth: 0, overageUnitPrice: 0, resetAt: null }
```

### apiKeyStore 新增 seed Key（tenant_008）

为 tenant_008 预置一条 seed API Key，演示 enterprise 已激活 API 的状态。

```javascript
// seed 初始化时调用 apiKeyStore.generate('tenant_008')
// 生成完整记录：keyId, keyHash, keyPrefix, keySuffix, status='active', createdAt, rotatedAt=null
```

## 规格文档变更

修改 `docs/superpowers/specs/2026-05-02-unified-business-model-phase2b-design.md`：

| 位置 | 变更 |
|------|------|
| L616 端点清单注释 | 替换为本文档的 free tier 定义，删除模糊注释 |
| L468-477 种子数据段 | 新增 tenant_a002 和 tenant_008 的种子描述 |
| 新增小节 | "Free Tier 触发路径" — 描述两条路径的激活流程和降级规则 |

## 代码变更

| 文件 | 变更 |
|------|------|
| `backend/data/seed.js` | 新增 tenant_a002、tenant_008 |
| `backend/data/apiTierStore.js` | 新增两条 free tier 初始记录 |
| `backend/data/apiKeyStore.js` | 为 tenant_008 添加 seed API Key |

### 不需要变更的部分

- **apiTierStore 接口**：`getByTenantId` 已支持任意 tenantId，farm 和 api tenant 通用
- **shaping middleware**：已有 `req.apiTier` 分叉逻辑，free tier 走现有路径即可
- **apiKeyAuth middleware**：通过 `apiKeyStore.validate()` → `apiTierStore.getByTenantId()` 解析 tier，不关心 tenant 类型
- **端点可见性**：shaping 按 tier 值过滤，`'free'` 自然匹配 free 端点集

## 验收标准

- [ ] 规格文档明确 free tier 的两条触发路径和目标用户
- [ ] apiTierStore 包含 free tier 定义（`'free'` 在 tier 枚举中）
- [ ] 种子数据包含：一个 free trial api_consumer（tenant_a002）+ 一个已开启 API 的 enterprise farm（tenant_008）
- [ ] seed 数据与 tier 定义一致，无矛盾
