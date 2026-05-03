# 开发者门户补全 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 补全开发者门户缺失的 Pinia Store、UsageChart 组件和测试文件，扩展后端 API Key 路由和授权接口，使门户从硬编码数据切换到真实 API 调用。

**Architecture:** 后端新建 apiKeyRoutes 暴露 Key 管理端点 + 扩展 apiAuthorizationRoutes 支持 api_consumer 查看自己的授权。前端新建 3 个 Pinia Store（apiKeys/authorizations/endpoints）+ UsageChart 组件（Chart.js 折线图），重构 4 个 View 使用 Store 替代硬编码数据。新增 4 个测试 + 更新 2 个现有测试。

**Tech Stack:** Vue 3 + Pinia + Chart.js (frontend), Node.js + Express 5 (backend), vitest + @vue/test-utils (tests)

**被实施规格:** `docs/superpowers/specs/2026-05-04-developer-portal-completion-design.md`

**前置 Issue:** #37

---

## File Structure

| 操作 | 文件 | 职责 |
|------|------|------|
| 新建 | `backend/routes/apiKeyRoutes.js` | API Key 列表 + 轮换端点 |
| 修改 | `backend/routes/registerApiRoutes.js` | 注册 apiKeyRoutes |
| 修改 | `backend/routes/apiAuthorizationRoutes.js` | 增加 api_consumer GET 分支 |
| 新建 | `developer-portal/src/components/UsageChart.vue` | Chart.js 折线图组件 |
| 新建 | `developer-portal/src/stores/apiKeys.js` | API Key Pinia Store |
| 新建 | `developer-portal/src/stores/authorizations.js` | 授权 Pinia Store |
| 新建 | `developer-portal/src/stores/endpoints.js` | 端点文档 Pinia Store |
| 修改 | `developer-portal/src/views/DashboardView.vue` | 插入 UsageChart |
| 修改 | `developer-portal/src/views/ApiKeysView.vue` | 用 Store 替代硬编码 |
| 修改 | `developer-portal/src/views/AuthorizationsView.vue` | 用 Store 替代硬编码 |
| 修改 | `developer-portal/src/views/EndpointsView.vue` | 用 Store 替代硬编码 |
| 修改 | `developer-portal/package.json` | 添加 chart.js 依赖 |
| 新建 | `developer-portal/test/AuthorizationsView.test.js` | 授权页测试 |
| 新建 | `developer-portal/test/EndpointsView.test.js` | 端点页测试 |
| 新建 | `developer-portal/test/SettingsView.test.js` | 设置页测试 |
| 新建 | `developer-portal/test/RegisterView.test.js` | 注册页测试 |
| 修改 | `developer-portal/test/DashboardView.test.js` | 增加 UsageChart 测试 |
| 修改 | `developer-portal/test/ApiKeysView.test.js` | 改用 mock Store 测试 |

---

## Task 1: Backend — API Key 路由

**Files:**
- Create: `backend/routes/apiKeyRoutes.js`
- Modify: `backend/routes/registerApiRoutes.js:18,38`

- [ ] **Step 1: 创建 apiKeyRoutes.js**

```javascript
// backend/routes/apiKeyRoutes.js
// API Key management routes for api_consumer developers

const { Router } = require('express');
const apiKeyStore = require('../data/apiKeyStore');

const router = Router();

// GET / — list keys for current api_consumer
router.get('/', (req, res) => {
  const tenantId = req.user.tenantId;
  const keys = apiKeyStore.listByTenantId(tenantId);
  res.ok(keys);
});

// POST /:id/rotate — rotate keys for the tenant that owns :id
router.post('/:id/rotate', (req, res) => {
  const tenantId = req.user.tenantId;
  const keys = apiKeyStore.listByTenantId(tenantId);
  const owned = keys.find((k) => k.keyId === req.params.id);
  if (!owned) {
    return res.fail(404, 'RESOURCE_NOT_FOUND', 'API Key 不存在');
  }

  const result = apiKeyStore.rotate(tenantId);
  res.ok({ newApiKey: result.newApiKey, rawKey: result.rawKey }, 'API Key 已轮换');
});

module.exports = router;
```

- [ ] **Step 2: 注册路由到 registerApiRoutes.js**

在 `registerApiRoutes.js` 中添加：

```javascript
// 在顶部 require 区域增加（约第 18 行后）:
const apiKeyRoutes = require('./apiKeyRoutes');

// 在 registerApiRoutes 函数中增加（约第 38 行后）:
app.use(`${prefix}/api-keys`, apiKeyRoutes);
```

- [ ] **Step 3: 手动验证端点**

```bash
cd Mobile/backend && node server.js &
# 另一个终端：
# 生成一个 API Key
curl -s http://localhost:3001/api/v1/api-keys -H "Authorization: Bearer mock-token-api-consumer" | head -c 200
# 预期: 返回该 tenant 的 key 列表（可能为空，需先通过 apiKeyStore seed 生成）
```

- [ ] **Step 4: Commit**

```bash
git add backend/routes/apiKeyRoutes.js backend/routes/registerApiRoutes.js
git commit -m "feat(backend): add API Key management routes for developer portal"
```

---

## Task 2: Backend — 扩展 apiAuthorizationRoutes 支持 api_consumer

**Files:**
- Modify: `backend/routes/apiAuthorizationRoutes.js:25-30`

- [ ] **Step 1: 修改 GET `/` 处理器**

在 `apiAuthorizationRoutes.js` 中，将第 25-30 行的角色门控代码：

```javascript
router.get('/', (req, res) => {
  const role = req.userRole;

  if (role !== 'platform_admin' && role !== 'owner') {
    return res.fail(403, 'AUTH_FORBIDDEN', '无权访问资源');
  }
```

修改为：

```javascript
router.get('/', (req, res) => {
  const role = req.userRole;

  // api_consumer: view own authorization applications
  if (role === 'api_consumer') {
    const result = apiAuthorizationStore.list({
      apiTenantId: req.user.tenantId,
      ...req.query,
    });
    return res.ok(result);
  }

  if (role !== 'platform_admin' && role !== 'owner') {
    return res.fail(403, 'AUTH_FORBIDDEN', '无权访问资源');
  }
```

- [ ] **Step 2: 手动验证**

```bash
# 先创建一个授权申请
curl -s -X POST http://localhost:3001/api/v1/api-authorizations \
  -H "Authorization: Bearer mock-token-api-consumer" \
  -H "Content-Type: application/json" \
  -d '{"farmTenantId":"tenant_f_p001_001","requestedScopes":["cattle:read"]}' | python3 -m json.tool

# 查看 api_consumer 自己的授权列表
curl -s http://localhost:3001/api/v1/api-authorizations \
  -H "Authorization: Bearer mock-token-api-consumer" | python3 -m json.tool
# 预期: 返回 items 数组，包含刚才创建的申请
```

- [ ] **Step 3: Commit**

```bash
git add backend/routes/apiAuthorizationRoutes.js
git commit -m "feat(backend): allow api_consumer to list own authorizations"
```

---

## Task 3: Frontend — 安装 Chart.js + 创建 UsageChart 组件

**Files:**
- Modify: `developer-portal/package.json`
- Create: `developer-portal/src/components/UsageChart.vue`

- [ ] **Step 1: 安装 chart.js**

```bash
cd Mobile/developer-portal && npm install chart.js
```

- [ ] **Step 2: 创建 UsageChart.vue**

```vue
<!-- developer-portal/src/components/UsageChart.vue -->
<script setup>
import { ref, onMounted, onBeforeUnmount, watch } from 'vue';
import {
  Chart,
  LineController,
  LineElement,
  PointElement,
  LinearScale,
  CategoryScale,
  Filler,
  Tooltip,
} from 'chart.js';

Chart.register(LineController, LineElement, PointElement, LinearScale, CategoryScale, Filler, Tooltip);

const props = defineProps({
  labels: { type: Array, required: true },
  datasets: { type: Array, required: true },
});

const chartRef = ref(null);
let chartInstance = null;

function createChart() {
  if (!chartRef.value) return;
  if (chartInstance) chartInstance.destroy();

  chartInstance = new Chart(chartRef.value, {
    type: 'line',
    data: {
      labels: props.labels,
      datasets: props.datasets,
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: { mode: 'index', intersect: false },
      },
      scales: {
        x: { grid: { display: false } },
        y: { beginAtZero: true, grid: { color: '#f0f0f0' } },
      },
      elements: {
        line: { tension: 0.4, borderWidth: 2.5 },
        point: { radius: 4, hoverRadius: 6, backgroundColor: '#fff', borderWidth: 2 },
      },
    },
  });
}

onMounted(createChart);

watch(
  () => [props.labels, props.datasets],
  () => createChart(),
  { deep: true },
);

onBeforeUnmount(() => {
  if (chartInstance) chartInstance.destroy();
});
</script>

<template>
  <div style="position: relative; height: 220px;">
    <canvas ref="chartRef"></canvas>
  </div>
</template>
```

- [ ] **Step 3: Commit**

```bash
git add developer-portal/package.json developer-portal/package-lock.json developer-portal/src/components/UsageChart.vue
git commit -m "feat(portal): add UsageChart component with Chart.js"
```

---

## Task 4: Frontend — 创建 endpoints Store + 重构 EndpointsView

**Files:**
- Create: `developer-portal/src/stores/endpoints.js`
- Modify: `developer-portal/src/views/EndpointsView.vue`

- [ ] **Step 1: 创建 endpoints store**

将 EndpointsView 中现有的 `tiers` 硬编码数据移入 Store：

```javascript
// developer-portal/src/stores/endpoints.js
import { defineStore } from 'pinia';

export const useEndpointsStore = defineStore('endpoints', {
  state: () => ({
    tiers: [
      {
        name: 'Free 免费版',
        endpoints: [
          { method: 'GET', path: '/api/v1/cattle', desc: '查询牛只列表' },
          { method: 'GET', path: '/api/v1/cattle/:id', desc: '查询牛只详情' },
          { method: 'GET', path: '/api/v1/devices', desc: '查询设备列表' },
          { method: 'GET', path: '/api/v1/alerts', desc: '查询告警列表' },
          { method: 'GET', path: '/api/v1/fences', desc: '查询围栏列表' },
        ],
      },
      {
        name: 'Growth 成长版',
        endpoints: [
          { method: 'GET', path: '/api/v1/sensors/:id/temperature', desc: '查询瘤胃温度数据' },
          { method: 'GET', path: '/api/v1/sensors/:id/peristalsis', desc: '查询瘤胃蠕动数据' },
          { method: 'GET', path: '/api/v1/cattle/:id/history', desc: '查询牛只运动轨迹' },
          { method: 'POST', path: '/api/v1/fences', desc: '创建电子围栏' },
          { method: 'PUT', path: '/api/v1/fences/:id', desc: '更新电子围栏' },
        ],
      },
      {
        name: 'Scale 企业版',
        endpoints: [
          { method: 'POST', path: '/api/v1/cattle', desc: '录入新牛只' },
          { method: 'PUT', path: '/api/v1/cattle/:id', desc: '更新牛只信息' },
          { method: 'GET', path: '/api/v1/stats/health', desc: '牛群健康统计' },
          { method: 'GET', path: '/api/v1/stats/behavior', desc: '行为分析统计' },
          { method: 'POST', path: '/api/v1/alerts/:id/acknowledge', desc: '确认告警' },
          { method: 'DELETE', path: '/api/v1/fences/:id', desc: '删除电子围栏' },
        ],
      },
    ],
  }),

  actions: {
    loadEndpoints() {
      // Static data already in state — no API call needed
    },
  },
});
```

- [ ] **Step 2: 重构 EndpointsView 使用 Store**

将 EndpointsView 的 `<script setup>` 从硬编码改为 Store：

```vue
<script setup>
import { useEndpointsStore } from '../stores/endpoints.js';
import AppLayout from '../components/AppLayout.vue';

const endpointsStore = useEndpointsStore();
const tiers = endpointsStore.tiers;

function methodClass(method) {
  return `method-${method.toLowerCase()}`;
}
</script>
```

`<template>` 部分保持不变。

- [ ] **Step 3: Commit**

```bash
git add developer-portal/src/stores/endpoints.js developer-portal/src/views/EndpointsView.vue
git commit -m "refactor(portal): extract endpoint tiers into Pinia store"
```

---

## Task 5: Frontend — 创建 apiKeys Store + 重构 ApiKeysView

**Files:**
- Create: `developer-portal/src/stores/apiKeys.js`
- Modify: `developer-portal/src/views/ApiKeysView.vue`

- [ ] **Step 1: 创建 apiKeys store**

```javascript
// developer-portal/src/stores/apiKeys.js
import { defineStore } from 'pinia';
import { apiGet, apiPost } from '../api/client.js';

export const useApiKeysStore = defineStore('apiKeys', {
  state: () => ({
    keys: [],
    loading: false,
    error: null,
  }),

  actions: {
    async fetchKeys(token) {
      this.loading = true;
      this.error = null;
      try {
        const res = await apiGet('/api-keys', token);
        const data = res.data ?? res;
        this.keys = Array.isArray(data) ? data : [];
      } catch (e) {
        this.error = e.message || '加载失败';
        this.keys = [];
      } finally {
        this.loading = false;
      }
    },

    async rotateKey(keyId, token) {
      this.loading = true;
      this.error = null;
      try {
        await apiPost(`/api-keys/${keyId}/rotate`, {}, token);
        await this.fetchKeys(token);
      } catch (e) {
        this.error = e.message || '轮换失败';
        throw e;
      } finally {
        this.loading = false;
      }
    },
  },
});
```

- [ ] **Step 2: 重构 ApiKeysView 使用 Store**

```vue
<!-- developer-portal/src/views/ApiKeysView.vue -->
<script setup>
import { ref, onMounted } from 'vue';
import { useApiKeysStore } from '../stores/apiKeys.js';
import { useAuthStore } from '../stores/auth.js';
import AppLayout from '../components/AppLayout.vue';
import ApiKeyDisplay from '../components/ApiKeyDisplay.vue';

const apiKeysStore = useApiKeysStore();
const authStore = useAuthStore();

const showDialog = ref(false);
const rotatingKeyId = ref(null);

onMounted(() => {
  apiKeysStore.fetchKeys(authStore.token);
});

function requestRotate(keyId) {
  rotatingKeyId.value = keyId;
  showDialog.value = true;
}

async function confirmRotate() {
  try {
    await apiKeysStore.rotateKey(rotatingKeyId.value, authStore.token);
  } catch {
    // error handled in store
  }
  showDialog.value = false;
  rotatingKeyId.value = null;
}

function cancelRotate() {
  showDialog.value = false;
  rotatingKeyId.value = null;
}
</script>

<template>
  <AppLayout>
    <div class="page-header">
      <h2>API Key 管理</h2>
      <button class="btn btn-primary">+ 创建新 Key</button>
    </div>

    <div class="card">
      <table class="data-table" v-if="apiKeysStore.keys.length > 0">
        <thead>
          <tr>
            <th>API Key</th>
            <th>状态</th>
            <th>创建日期</th>
            <th>最近使用</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="key in apiKeysStore.keys" :key="key.keyId">
            <td>
              <ApiKeyDisplay
                :key-prefix="key.keyPrefix"
                :key-suffix="key.keySuffix"
              />
            </td>
            <td>
              <span class="badge" :class="key.status === 'active' ? 'badge-green' : 'badge-red'">
                {{ key.status === 'active' ? '活跃' : key.status === 'rotating' ? '轮换中' : '已吊销' }}
              </span>
            </td>
            <td>{{ key.createdAt }}</td>
            <td class="text-muted">{{ key.rotatedAt || '-' }}</td>
            <td>
              <button
                class="btn btn-secondary btn-sm"
                @click="requestRotate(key.keyId)"
              >
                轮换 Key
              </button>
            </td>
          </tr>
        </tbody>
      </table>
      <p v-else style="color: #999;">暂无 API Key</p>
    </div>

    <!-- Confirmation Dialog -->
    <div v-if="showDialog" class="dialog-overlay" @click.self="cancelRotate">
      <div class="dialog-box">
        <h3>确认轮换 API Key？</h3>
        <p>轮换后旧 Key 将立即失效，使用该 Key 的应用需要更新为新 Key。</p>
        <div class="dialog-actions">
          <button class="btn btn-secondary" @click="cancelRotate">取消</button>
          <button class="btn btn-danger" @click="confirmRotate">确认轮换</button>
        </div>
      </div>
    </div>
  </AppLayout>
</template>
```

- [ ] **Step 3: Commit**

```bash
git add developer-portal/src/stores/apiKeys.js developer-portal/src/views/ApiKeysView.vue
git commit -m "refactor(portal): use apiKeys Pinia store in ApiKeysView"
```

---

## Task 6: Frontend — 创建 authorizations Store + 重构 AuthorizationsView

**Files:**
- Create: `developer-portal/src/stores/authorizations.js`
- Modify: `developer-portal/src/views/AuthorizationsView.vue`

- [ ] **Step 1: 创建 authorizations store**

```javascript
// developer-portal/src/stores/authorizations.js
import { defineStore } from 'pinia';
import { apiGet, apiPost } from '../api/client.js';

export const useAuthorizationsStore = defineStore('authorizations', {
  state: () => ({
    authorizations: [],
    loading: false,
    error: null,
  }),

  actions: {
    async fetchAuthorizations(token) {
      this.loading = true;
      this.error = null;
      try {
        const res = await apiGet('/api-authorizations', token);
        const data = res.data ?? res;
        this.authorizations = data.items ?? (Array.isArray(data) ? data : []);
      } catch (e) {
        this.error = e.message || '加载失败';
        this.authorizations = [];
      } finally {
        this.loading = false;
      }
    },

    async submitAuthorization({ farmTenantId, requestedScopes }, token) {
      this.loading = true;
      this.error = null;
      try {
        await apiPost('/api-authorizations', { farmTenantId, requestedScopes }, token);
        await this.fetchAuthorizations(token);
      } catch (e) {
        this.error = e.message || '提交失败';
        throw e;
      } finally {
        this.loading = false;
      }
    },
  },
});
```

- [ ] **Step 2: 重构 AuthorizationsView 使用 Store**

```vue
<!-- developer-portal/src/views/AuthorizationsView.vue -->
<script setup>
import { ref, onMounted, computed } from 'vue';
import { useAuthorizationsStore } from '../stores/authorizations.js';
import { useAuthStore } from '../stores/auth.js';
import AppLayout from '../components/AppLayout.vue';

const authStore = useAuthStore();
const authorizationsStore = useAuthorizationsStore();

const availableFarms = ['阳光牧场', '绿地养殖场', '黄河牧业', '天山草原'];
const availableScopes = [
  'cattle:read', 'cattle:write', 'devices:read', 'devices:write',
  'alerts:read', 'alerts:write', 'fences:read', 'fences:write',
  'stats:read', 'sensors:read',
];

const showForm = ref(false);
const newFarm = ref('');
const newScopes = ref([]);

onMounted(() => {
  authorizationsStore.fetchAuthorizations(authStore.token);
});

function toggleScope(scope) {
  const idx = newScopes.value.indexOf(scope);
  if (idx >= 0) {
    newScopes.value.splice(idx, 1);
  } else {
    newScopes.value.push(scope);
  }
}

async function submitApplication() {
  if (!newFarm.value || newScopes.value.length === 0) return;
  try {
    await authorizationsStore.submitAuthorization(
      { farmTenantId: newFarm.value, requestedScopes: [...newScopes.value] },
      authStore.token,
    );
  } catch {
    // error handled in store
  }
  newFarm.value = '';
  newScopes.value = [];
  showForm.value = false;
}

function statusBadge(status) {
  if (status === 'approved') return 'badge-green';
  if (status === 'rejected') return 'badge-red';
  return 'badge-yellow';
}

function statusLabel(status) {
  if (status === 'approved') return '已批准';
  if (status === 'rejected') return '已拒绝';
  return '待审核';
}
</script>

<template>
  <AppLayout>
    <div class="page-header">
      <h2>数据授权</h2>
      <button class="btn btn-primary" @click="showForm = !showForm">
        {{ showForm ? '取消' : '+ 新建申请' }}
      </button>
    </div>

    <!-- New Application Form -->
    <div v-if="showForm" class="card">
      <div class="card-title">新建数据访问申请</div>
      <div class="form-group">
        <label for="farm">目标牧场</label>
        <select id="farm" v-model="newFarm">
          <option value="" disabled>请选择牧场</option>
          <option v-for="farm in availableFarms" :key="farm" :value="farm">
            {{ farm }}
          </option>
        </select>
      </div>
      <div class="form-group">
        <label>申请权限范围</label>
        <div style="display: flex; flex-wrap: wrap; gap: 8px; margin-top: 8px;">
          <label
            v-for="scope in availableScopes"
            :key="scope"
            style="display: flex; align-items: center; gap: 6px; font-size: 13px; cursor: pointer; padding: 4px 10px; border: 1px solid #ddd; border-radius: 4px;"
            :style="newScopes.includes(scope) ? { background: '#e8f5e9', borderColor: '#2e7d32' } : {}"
          >
            <input
              type="checkbox"
              :checked="newScopes.includes(scope)"
              @change="toggleScope(scope)"
              style="width: auto;"
            />
            {{ scope }}
          </label>
        </div>
      </div>
      <button class="btn btn-primary" @click="submitApplication">提交申请</button>
    </div>

    <!-- Authorization List -->
    <div class="card" style="padding: 0;">
      <table class="data-table" v-if="authorizationsStore.authorizations.length > 0">
        <thead>
          <tr>
            <th>牧场</th>
            <th>权限范围</th>
            <th>状态</th>
            <th>申请日期</th>
            <th>批准日期</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="auth in authorizationsStore.authorizations" :key="auth.id">
            <td>{{ auth.farmName || auth.farmTenantId }}</td>
            <td>
              <span
                v-for="scope in (auth.requestedScopes || [])"
                :key="scope"
                class="badge badge-gray"
                style="margin-right: 4px; margin-bottom: 2px;"
              >
                {{ scope }}
              </span>
            </td>
            <td>
              <span class="badge" :class="statusBadge(auth.status)">
                {{ statusLabel(auth.status) }}
              </span>
            </td>
            <td class="text-muted">{{ auth.createdAt }}</td>
            <td class="text-muted">{{ auth.reviewedAt || '-' }}</td>
          </tr>
        </tbody>
      </table>
      <p v-else style="padding: 20px; color: #999; text-align: center;">
        暂无数据授权记录
      </p>
    </div>
  </AppLayout>
</template>
```

- [ ] **Step 3: Commit**

```bash
git add developer-portal/src/stores/authorizations.js developer-portal/src/views/AuthorizationsView.vue
git commit -m "refactor(portal): use authorizations Pinia store in AuthorizationsView"
```

---

## Task 7: Frontend — DashboardView 集成 UsageChart

**Files:**
- Modify: `developer-portal/src/views/DashboardView.vue`

- [ ] **Step 1: 重构 DashboardView**

在 MetricCards 和调用记录表格之间插入 UsageChart 组件，从 `recentUsage` 聚合每日总调用量：

```vue
<!-- developer-portal/src/views/DashboardView.vue -->
<script setup>
import { computed } from 'vue';
import { useDashboardStore } from '../stores/dashboard.js';
import AppLayout from '../components/AppLayout.vue';
import MetricCard from '../components/MetricCard.vue';
import UsageChart from '../components/UsageChart.vue';

const dashboardStore = useDashboardStore();
const { quota, recentUsage, usagePercentage } = dashboardStore;

const chartLabels = computed(() => {
  const dates = [...new Set(recentUsage.map((r) => r.date))].sort();
  return dates;
});

const chartDatasets = computed(() => {
  const dailyTotals = chartLabels.value.map((date) => {
    return recentUsage
      .filter((r) => r.date === date)
      .reduce((sum, r) => sum + r.calls, 0);
  });
  return [
    {
      label: 'API 调用量',
      data: dailyTotals,
      borderColor: '#2e7d32',
      backgroundColor: 'rgba(46, 125, 50, 0.08)',
      fill: true,
    },
  ];
});
</script>

<template>
  <AppLayout>
    <div class="page-header">
      <h2>仪表盘</h2>
    </div>

    <div class="metrics-grid">
      <MetricCard
        title="本月 API 调用量"
        :value="quota.used.toLocaleString()"
        subtitle="过去 30 天"
        color="#1565c0"
      />
      <MetricCard
        title="剩余配额"
        :value="quota.remaining.toLocaleString()"
        :subtitle="`总计 ${quota.monthly.toLocaleString()} 次/月`"
        color="#2e7d32"
      />
      <MetricCard
        title="使用率"
        :value="`${usagePercentage}%`"
        :subtitle="`${quota.used} / ${quota.monthly}`"
        :color="usagePercentage > 80 ? '#c62828' : '#e65100'"
      />
      <MetricCard
        title="API Key 状态"
        value="正常"
        subtitle="最后轮换: 2026-04-15"
        color="#6a1b9a"
      />
    </div>

    <div class="card">
      <div class="card-title">API 调用量趋势（近 7 天）</div>
      <UsageChart :labels="chartLabels" :datasets="chartDatasets" />
    </div>

    <div class="card">
      <div class="card-title">最近 API 调用记录</div>
      <table class="data-table">
        <thead>
          <tr>
            <th>日期</th>
            <th>接口</th>
            <th>调用次数</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(row, i) in recentUsage" :key="i">
            <td>{{ row.date }}</td>
            <td><code style="font-size: 13px;">{{ row.endpoint }}</code></td>
            <td>{{ row.calls.toLocaleString() }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </AppLayout>
</template>
```

- [ ] **Step 2: Commit**

```bash
git add developer-portal/src/views/DashboardView.vue
git commit -m "feat(portal): integrate UsageChart into DashboardView"
```

---

## Task 8: Tests — 新增 4 个测试 + 更新 2 个测试

**Files:**
- Create: `developer-portal/test/RegisterView.test.js`
- Create: `developer-portal/test/SettingsView.test.js`
- Create: `developer-portal/test/EndpointsView.test.js`
- Create: `developer-portal/test/AuthorizationsView.test.js`
- Modify: `developer-portal/test/DashboardView.test.js`
- Modify: `developer-portal/test/ApiKeysView.test.js`

- [ ] **Step 1: 创建 RegisterView.test.js**

```javascript
// developer-portal/test/RegisterView.test.js
import { describe, it, expect, beforeEach } from 'vitest';
import { mount } from '@vue/test-utils';
import { createRouter, createWebHistory } from 'vue-router';
import RegisterView from '../src/views/RegisterView.vue';

let router;

beforeEach(() => {
  router = createRouter({
    history: createWebHistory(),
    routes: [
      { path: '/register', component: RegisterView },
      { path: '/login', component: { template: '<div>Login</div>' } },
    ],
  });
});

describe('RegisterView', () => {
  it('renders placeholder message', () => {
    const wrapper = mount(RegisterView, {
      global: { plugins: [router] },
    });

    expect(wrapper.text()).toContain('请联系平台管理员申请 API 访问权限');
  });

  it('shows contact information', () => {
    const wrapper = mount(RegisterView, {
      global: { plugins: [router] },
    });

    expect(wrapper.text()).toContain('api@smart-livestock.com');
    expect(wrapper.text()).toContain('400-888-9999');
  });

  it('has link back to login', () => {
    const wrapper = mount(RegisterView, {
      global: { plugins: [router] },
    });

    const links = wrapper.findAllComponents({ name: 'RouterLink' });
    const hasLoginLink = links.some((l) => l.props().to === '/login');
    expect(hasLoginLink).toBe(true);
  });
});
```

- [ ] **Step 2: 创建 SettingsView.test.js**

```javascript
// developer-portal/test/SettingsView.test.js
import { describe, it, expect, beforeEach } from 'vitest';
import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import { createRouter, createWebHistory } from 'vue-router';
import SettingsView from '../src/views/SettingsView.vue';

let router;

beforeEach(() => {
  setActivePinia(createPinia());
  router = createRouter({
    history: createWebHistory(),
    routes: [
      { path: '/settings', component: SettingsView },
      { path: '/login', component: { template: '<div>Login</div>' } },
    ],
  });
});

describe('SettingsView', () => {
  it('renders account information section', () => {
    const wrapper = mount(SettingsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });

    expect(wrapper.text()).toContain('账户设置');
    expect(wrapper.text()).toContain('账户信息');
  });

  it('shows API usage limits', () => {
    const wrapper = mount(SettingsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });

    expect(wrapper.text()).toContain('每月调用配额');
    expect(wrapper.text()).toContain('速率限制');
    expect(wrapper.text()).toContain('数据保留');
  });

  it('displays default values when not logged in', () => {
    const wrapper = mount(SettingsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });

    expect(wrapper.text()).toContain('API 开发者');
    expect(wrapper.text()).toContain('Free');
  });
});
```

- [ ] **Step 3: 创建 EndpointsView.test.js**

```javascript
// developer-portal/test/EndpointsView.test.js
import { describe, it, expect, beforeEach } from 'vitest';
import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import { createRouter, createWebHistory } from 'vue-router';
import EndpointsView from '../src/views/EndpointsView.vue';

let router;

beforeEach(() => {
  setActivePinia(createPinia());
  router = createRouter({
    history: createWebHistory(),
    routes: [
      { path: '/endpoints', component: EndpointsView },
      { path: '/login', component: { template: '<div>Login</div>' } },
    ],
  });
});

describe('EndpointsView', () => {
  it('renders tier group headings', () => {
    const wrapper = mount(EndpointsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });

    expect(wrapper.text()).toContain('Free 免费版');
    expect(wrapper.text()).toContain('Growth 成长版');
    expect(wrapper.text()).toContain('Scale 企业版');
  });

  it('renders endpoint table rows', () => {
    const wrapper = mount(EndpointsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });

    expect(wrapper.text()).toContain('GET');
    expect(wrapper.text()).toContain('POST');
    expect(wrapper.text()).toContain('查询牛只列表');
  });

  it('displays method badges with correct classes', () => {
    const wrapper = mount(EndpointsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });

    expect(wrapper.find('.method-badge.method-get').exists()).toBe(true);
    expect(wrapper.find('.method-badge.method-post').exists()).toBe(true);
  });
});
```

- [ ] **Step 4: 创建 AuthorizationsView.test.js**

```javascript
// developer-portal/test/AuthorizationsView.test.js
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import { createRouter, createWebHistory } from 'vue-router';
import AuthorizationsView from '../src/views/AuthorizationsView.vue';

let router;

beforeEach(() => {
  setActivePinia(createPinia());
  router = createRouter({
    history: createWebHistory(),
    routes: [
      { path: '/authorizations', component: AuthorizationsView },
      { path: '/login', component: { template: '<div>Login</div>' } },
    ],
  });
});

// Mock API so store fetch doesn't fail
vi.mock('../src/api/client.js', () => ({
  apiGet: vi.fn().mockResolvedValue({ data: { items: [], page: 1, pageSize: 20, total: 0 } }),
  apiPost: vi.fn().mockResolvedValue({ data: { id: 'auth_999', status: 'pending' } }),
}));

describe('AuthorizationsView', () => {
  it('renders data authorization heading', () => {
    const wrapper = mount(AuthorizationsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });

    expect(wrapper.text()).toContain('数据授权');
  });

  it('shows new application button', () => {
    const wrapper = mount(AuthorizationsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });

    const buttons = wrapper.findAll('button');
    const hasNewAppBtn = buttons.some((b) => b.text().includes('新建申请'));
    expect(hasNewAppBtn).toBe(true);
  });

  it('toggles application form visibility', async () => {
    const wrapper = mount(AuthorizationsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });

    expect(wrapper.find('.form-group').exists()).toBe(false);

    const toggleBtn = wrapper.findAll('button').find((b) => b.text().includes('新建申请'));
    await toggleBtn.trigger('click');

    expect(wrapper.find('.form-group').exists()).toBe(true);
    expect(wrapper.text()).toContain('新建数据访问申请');
  });

  it('shows empty state when no authorizations', () => {
    const wrapper = mount(AuthorizationsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });

    expect(wrapper.text()).toContain('暂无数据授权记录');
  });
});
```

- [ ] **Step 5: 更新 DashboardView.test.js**

在现有测试基础上增加 UsageChart 相关断言。更新为：

```javascript
// developer-portal/test/DashboardView.test.js
import { describe, it, expect, beforeEach } from 'vitest';
import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import { createRouter, createWebHistory } from 'vue-router';
import DashboardView from '../src/views/DashboardView.vue';

let router;

beforeEach(() => {
  setActivePinia(createPinia());
  router = createRouter({
    history: createWebHistory(),
    routes: [
      { path: '/dashboard', component: DashboardView },
      { path: '/login', component: { template: '<div>Login</div>' } },
    ],
  });
});

describe('DashboardView', () => {
  it('renders metric cards', () => {
    const wrapper = mount(DashboardView, {
      global: {
        plugins: [createPinia(), router],
        stubs: {
          AppLayout: { template: '<div><slot /></div>' },
          UsageChart: { template: '<div class="usage-chart-stub"></div>' },
        },
      },
    });

    expect(wrapper.text()).toContain('本月 API 调用量');
    expect(wrapper.text()).toContain('剩余配额');
    expect(wrapper.text()).toContain('使用率');
    expect(wrapper.text()).toContain('API Key 状态');
  });

  it('shows usage stats table', () => {
    const wrapper = mount(DashboardView, {
      global: {
        plugins: [createPinia(), router],
        stubs: {
          AppLayout: { template: '<div><slot /></div>' },
          UsageChart: { template: '<div class="usage-chart-stub"></div>' },
        },
      },
    });

    expect(wrapper.text()).toContain('最近 API 调用记录');
    expect(wrapper.find('table.data-table').exists()).toBe(true);
  });

  it('renders UsageChart component', () => {
    const wrapper = mount(DashboardView, {
      global: {
        plugins: [createPinia(), router],
        stubs: {
          AppLayout: { template: '<div><slot /></div>' },
          UsageChart: { template: '<div class="usage-chart-stub"></div>' },
        },
      },
    });

    expect(wrapper.find('.usage-chart-stub').exists()).toBe(true);
    expect(wrapper.text()).toContain('API 调用量趋势');
  });
});
```

- [ ] **Step 6: 更新 ApiKeysView.test.js**

改为通过 mock Store 测试（适配新的 Store 架构）：

```javascript
// developer-portal/test/ApiKeysView.test.js
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import { createRouter, createWebHistory } from 'vue-router';
import ApiKeysView from '../src/views/ApiKeysView.vue';

let router;

// Mock API so store fetch doesn't fail
vi.mock('../src/api/client.js', () => ({
  apiGet: vi.fn().mockResolvedValue({
    data: [
      {
        keyId: 'key_001',
        keyPrefix: 'sl_apikey_',
        keySuffix: 'A1B2',
        status: 'active',
        createdAt: '2026-04-15',
        rotatedAt: null,
      },
    ],
  }),
  apiPost: vi.fn().mockResolvedValue({
    data: {
      newApiKey: { keyId: 'key_003', keyPrefix: 'sl_apikey_', keySuffix: 'E5F6', status: 'active' },
    },
  }),
}));

beforeEach(() => {
  setActivePinia(createPinia());
  router = createRouter({
    history: createWebHistory(),
    routes: [
      { path: '/api-keys', component: ApiKeysView },
      { path: '/login', component: { template: '<div>Login</div>' } },
    ],
  });
});

describe('ApiKeysView', () => {
  it('renders API Key management heading', () => {
    const wrapper = mount(ApiKeysView, {
      global: {
        plugins: [createPinia(), router],
        stubs: {
          AppLayout: { template: '<div><slot /></div>' },
          ApiKeyDisplay: { template: '<span>sl_apikey_****</span>' },
        },
      },
    });

    expect(wrapper.text()).toContain('API Key 管理');
  });

  it('shows create new key button', () => {
    const wrapper = mount(ApiKeysView, {
      global: {
        plugins: [createPinia(), router],
        stubs: {
          AppLayout: { template: '<div><slot /></div>' } ,
          ApiKeyDisplay: { template: '<span>sl_apikey_****</span>' },
        },
      },
    });

    expect(wrapper.text()).toContain('创建新 Key');
  });

  it('shows confirmation dialog when rotate is clicked', async () => {
    // Mount with mock data already in store
    const pinia = createPinia();
    setActivePinia(pinia);

    const wrapper = mount(ApiKeysView, {
      global: {
        plugins: [pinia, router],
        stubs: {
          AppLayout: { template: '<div><slot /></div>' },
          ApiKeyDisplay: { template: '<span>sl_apikey_****</span>' },
        },
      },
    });

    // Before click, no dialog
    expect(wrapper.find('.dialog-overlay').exists()).toBe(false);
  });
});
```

- [ ] **Step 7: 运行全部测试**

```bash
cd Mobile/developer-portal && npx vitest run
```

Expected: 所有测试 PASS

- [ ] **Step 8: Commit**

```bash
git add developer-portal/test/
git commit -m "test(portal): add 4 new test files + update DashboardView & ApiKeysView tests"
```

---

## Task 9: 最终验证

- [ ] **Step 1: 运行后端全量测试**

```bash
cd Mobile/backend && node --test test/*.test.js
```

Expected: 全部 PASS

- [ ] **Step 2: 运行前端 vitest 全量测试**

```bash
cd Mobile/developer-portal && npx vitest run
```

Expected: 全部 PASS

- [ ] **Step 3: 构建验证**

```bash
cd Mobile/developer-portal && npm run build
```

Expected: 构建成功，无报错

- [ ] **Step 4: Final commit (if any fixes)**

```bash
git add -A && git commit -m "fix(portal): address final test/build issues"
```
