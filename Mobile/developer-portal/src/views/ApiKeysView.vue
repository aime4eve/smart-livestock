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
