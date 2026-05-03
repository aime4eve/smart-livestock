<!-- developer-portal/src/views/AuthorizationsView.vue -->
<script setup>
import { ref, onMounted } from 'vue';
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
