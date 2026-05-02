<script setup>
import { ref } from 'vue';
import AppLayout from '../components/AppLayout.vue';
import ApiKeyDisplay from '../components/ApiKeyDisplay.vue';

const keys = ref([
  {
    id: 'key_001',
    prefix: 'sl_apikey_',
    suffix: 'A1B2',
    status: 'active',
    createdAt: '2026-04-15',
    lastUsed: '2026-05-02 09:23:15',
  },
  {
    id: 'key_002',
    prefix: 'sl_apikey_',
    suffix: 'C3D4',
    status: 'active',
    createdAt: '2026-03-01',
    lastUsed: '2026-04-28 14:10:00',
  },
]);

const showDialog = ref(false);
const rotatingKeyId = ref(null);

function requestRotate(keyId) {
  rotatingKeyId.value = keyId;
  showDialog.value = true;
}

function confirmRotate() {
  const key = keys.value.find((k) => k.id === rotatingKeyId.value);
  if (key) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let newSuffix = '';
    for (let i = 0; i < 4; i++) {
      newSuffix += chars[Math.floor(Math.random() * chars.length)];
    }
    key.suffix = newSuffix;
    key.createdAt = new Date().toISOString().split('T')[0];
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
      <table class="data-table" v-if="keys.length > 0">
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
          <tr v-for="key in keys" :key="key.id">
            <td>
              <ApiKeyDisplay
                :key-prefix="key.prefix"
                :key-suffix="key.suffix"
              />
            </td>
            <td>
              <span class="badge" :class="key.status === 'active' ? 'badge-green' : 'badge-red'">
                {{ key.status === 'active' ? '活跃' : '已吊销' }}
              </span>
            </td>
            <td>{{ key.createdAt }}</td>
            <td class="text-muted">{{ key.lastUsed }}</td>
            <td>
              <button
                class="btn btn-secondary btn-sm"
                @click="requestRotate(key.id)"
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
