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
const showCreateDialog = ref(false);
const showKeyResult = ref(false);
const revealedKey = ref('');
const copyFeedback = ref('');

onMounted(() => {
  apiKeysStore.fetchKeys(authStore.token);
});

function requestRotate(keyId) {
  rotatingKeyId.value = keyId;
  showDialog.value = true;
}

async function confirmRotate() {
  try {
    const rawKey = await apiKeysStore.rotateKey(rotatingKeyId.value, authStore.token);
    showDialog.value = false;
    rotatingKeyId.value = null;
    if (rawKey) {
      revealedKey.value = rawKey;
      showKeyResult.value = true;
    }
  } catch {
    // error handled in store
  }
}

function cancelRotate() {
  showDialog.value = false;
  rotatingKeyId.value = null;
}

async function confirmCreate() {
  try {
    const rawKey = await apiKeysStore.createKey(authStore.token);
    showCreateDialog.value = false;
    if (rawKey) {
      revealedKey.value = rawKey;
      showKeyResult.value = true;
    }
  } catch {
    // error handled in store
  }
}

async function copyKey() {
  try {
    await navigator.clipboard.writeText(revealedKey.value);
    copyFeedback.value = '已复制！';
    setTimeout(() => { copyFeedback.value = ''; }, 2000);
  } catch {
    const textarea = document.createElement('textarea');
    textarea.value = revealedKey.value;
    document.body.appendChild(textarea);
    textarea.select();
    document.execCommand('copy');
    document.body.removeChild(textarea);
    copyFeedback.value = '已复制！';
    setTimeout(() => { copyFeedback.value = ''; }, 2000);
  }
}

function closeKeyResult() {
  showKeyResult.value = false;
  revealedKey.value = '';
  copyFeedback.value = '';
}
</script>

<template>
  <AppLayout>
    <div class="page-header">
      <h2>API Key 管理</h2>
      <button class="btn btn-primary" @click="showCreateDialog = true">+ 创建新 Key</button>
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

    <!-- Rotate Dialog -->
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

    <!-- Create Dialog -->
    <div v-if="showCreateDialog" class="dialog-overlay" @click.self="showCreateDialog = false">
      <div class="dialog-box">
        <h3>创建新 API Key</h3>
        <p>新创建的 Key 将立即生效。请妥善保管 Key 值，关闭后将无法再次查看完整 Key。</p>
        <div class="dialog-actions">
          <button class="btn btn-secondary" @click="showCreateDialog = false">取消</button>
          <button class="btn btn-primary" @click="confirmCreate">确认创建</button>
        </div>
      </div>
    </div>

    <!-- Key Result Dialog -->
    <div v-if="showKeyResult" class="dialog-overlay">
      <div class="dialog-box" style="max-width: 560px;">
        <h3>{{ copyFeedback || '请复制并妥善保管您的 API Key' }}</h3>
        <p style="color: #c62828; font-size: 13px; margin-bottom: 12px;">
          关闭此窗口后将无法再次查看完整 Key，请立即复制保存。
        </p>
        <div style="background: #f5f5f5; border: 1px solid #e0e0e0; border-radius: 6px; padding: 12px; display: flex; align-items: center; gap: 8px;">
          <code style="flex: 1; word-break: break-all; font-size: 13px; user-select: all;">{{ revealedKey }}</code>
          <button class="btn btn-primary btn-sm" @click="copyKey" style="white-space: nowrap;">
            {{ copyFeedback ? '✓ 已复制' : '复制' }}
          </button>
        </div>
        <div class="dialog-actions" style="margin-top: 16px;">
          <button class="btn btn-secondary" @click="closeKeyResult">我已保存，关闭</button>
        </div>
      </div>
    </div>
  </AppLayout>
</template>
