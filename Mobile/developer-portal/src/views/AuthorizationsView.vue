<!-- developer-portal/src/views/AuthorizationsView.vue -->
<script setup>
import { ref, onMounted } from 'vue';
import { useAuthorizationsStore } from '../stores/authorizations.js';
import { useAuthStore } from '../stores/auth.js';
import AppLayout from '../components/AppLayout.vue';

const authStore = useAuthStore();
const authorizationsStore = useAuthorizationsStore();

const availableFarms = [
  { id: 'tenant_001', name: '华东示范牧场' },
  { id: 'tenant_002', name: '西部高原牧场' },
  { id: 'tenant_003', name: '东北黑土地牧场' },
  { id: 'tenant_005', name: '西南高山牧场' },
  { id: 'tenant_006', name: '华北草原牧场' },
  { id: 'tenant_007', name: '张三的第二牧场' },
];
const availableScopes = [
  'cattle:read', 'cattle:write', 'devices:read', 'devices:write',
  'alerts:read', 'alerts:write', 'fences:read', 'fences:write',
  'stats:read', 'sensors:read',
];

const showForm = ref(false);
const newFarm = ref('');
const newScopes = ref([]);
const expandedId = ref(null);

onMounted(() => {
  authorizationsStore.fetchAuthorizations(authStore.token);
});

function farmName(farmTenantId) {
  const farm = availableFarms.find((f) => f.id === farmTenantId);
  return farm ? farm.name : farmTenantId;
}

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
  if (status === 'revoked') return 'badge-gray';
  return 'badge-yellow';
}

function statusLabel(status) {
  const map = { approved: '已批准', rejected: '已拒绝', revoked: '已撤销', pending: '待审核' };
  return map[status] || status;
}

function toggleExpand(id) {
  expandedId.value = expandedId.value === id ? null : id;
}

function canReapply(status) {
  return status === 'rejected' || status === 'revoked';
}

function reapply(auth) {
  newFarm.value = auth.farmTenantId;
  newScopes.value = auth.requestedScopes ? [...auth.requestedScopes] : [];
  showForm.value = true;
}

function formatExpiry(expiresAt) {
  if (!expiresAt) return null;
  const expiry = new Date(expiresAt.replace('+08:00', ''));
  const now = new Date();
  const daysLeft = Math.ceil((expiry - now) / (1000 * 60 * 60 * 24));
  if (daysLeft < 0) return { text: '已过期', warn: true };
  if (daysLeft <= 30) return { text: `剩余 ${daysLeft} 天`, warn: true };
  return { text: expiry.toLocaleDateString('zh-CN'), warn: false };
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
          <option v-for="farm in availableFarms" :key="farm.id" :value="farm.id">
            {{ farm.name }}
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
    <div class="card" style="padding: 0;" v-if="authorizationsStore.authorizations.length > 0">
      <table class="data-table">
        <thead>
          <tr>
            <th style="width: 30px;"></th>
            <th>牧场</th>
            <th>权限范围</th>
            <th>状态</th>
            <th>申请日期</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <template v-for="auth in authorizationsStore.authorizations" :key="auth.id">
            <tr style="cursor: pointer;" @click="toggleExpand(auth.id)">
              <td style="text-align: center; color: #999; font-size: 11px;">
                {{ expandedId === auth.id ? '▼' : '▶' }}
              </td>
              <td>{{ farmName(auth.farmTenantId) }}</td>
              <td>
                <span
                  v-for="scope in (auth.requestedScopes || []).slice(0, 3)"
                  :key="scope"
                  class="badge badge-gray"
                  style="margin-right: 4px; margin-bottom: 2px;"
                >
                  {{ scope }}
                </span>
                <span v-if="(auth.requestedScopes || []).length > 3" class="badge badge-gray">
                  +{{ auth.requestedScopes.length - 3 }}
                </span>
              </td>
              <td>
                <span class="badge" :class="statusBadge(auth.status)">
                  {{ statusLabel(auth.status) }}
                </span>
              </td>
              <td class="text-muted">{{ (auth.createdAt || '').split('T')[0] }}</td>
              <td>
                <button
                  v-if="canReapply(auth.status)"
                  class="btn btn-secondary btn-sm"
                  @click.stop="reapply(auth)"
                >
                  重新申请
                </button>
              </td>
            </tr>
            <!-- Expanded Detail Row -->
            <tr v-if="expandedId === auth.id">
              <td colspan="6" style="background: #fafafa; padding: 16px 20px;">
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px; font-size: 13px;">
                  <div>
                    <span style="color: #888;">授权 ID：</span>{{ auth.id }}
                  </div>
                  <div>
                    <span style="color: #888;">目标牧场：</span>{{ farmName(auth.farmTenantId) }}
                  </div>
                  <div>
                    <span style="color: #888;">申请时间：</span>{{ auth.createdAt }}
                  </div>
                  <div v-if="auth.reviewedAt">
                    <span style="color: #888;">审批时间：</span>{{ auth.reviewedAt }}
                  </div>
                  <div v-if="auth.expiresAt">
                    <span style="color: #888;">到期时间：</span>
                    <span :style="{ color: formatExpiry(auth.expiresAt)?.warn ? '#c62828' : 'inherit', fontWeight: formatExpiry(auth.expiresAt)?.warn ? '600' : 'normal' }">
                      {{ formatExpiry(auth.expiresAt)?.text }}
                    </span>
                  </div>
                  <div v-if="auth.reason">
                    <span style="color: #888;">备注：</span>{{ auth.reason }}
                  </div>
                  <div style="grid-column: 1 / -1;">
                    <span style="color: #888;">权限范围：</span>
                    <span
                      v-for="scope in (auth.requestedScopes || [])"
                      :key="scope"
                      class="badge badge-gray"
                      style="margin-right: 4px;"
                    >
                      {{ scope }}
                    </span>
                  </div>
                </div>
              </td>
            </tr>
          </template>
        </tbody>
      </table>
    </div>
    <div class="card" v-else style="text-align: center; padding: 32px; color: #999;">
      暂无数据授权记录
    </div>
  </AppLayout>
</template>
