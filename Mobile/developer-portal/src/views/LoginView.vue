<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../stores/auth.js';

const router = useRouter();
const authStore = useAuthStore();

const token = ref('mock-token-api-consumer');
const error = ref('');
const loading = ref(false);

async function handleLogin() {
  error.value = '';
  loading.value = true;
  try {
    await authStore.login(token.value.trim());
    router.push('/dashboard');
  } catch (e) {
    error.value = e.message || '登录失败';
  } finally {
    loading.value = false;
  }
}
</script>

<template>
  <div class="login-page">
    <div class="login-card">
      <h1>智慧畜牧 API 平台</h1>
      <p class="login-subtitle">开发者门户 - 请输入 API Token 登录</p>

      <div v-if="error" class="error-msg">{{ error }}</div>

      <div class="form-group">
        <label for="token">API Token</label>
        <input
          id="token"
          v-model="token"
          type="text"
          placeholder="请输入 API Token"
          @keyup.enter="handleLogin"
        />
      </div>

      <button
        class="btn btn-primary"
        style="width: 100%"
        :disabled="loading"
        @click="handleLogin"
      >
        {{ loading ? '登录中...' : '登录' }}
      </button>

      <p style="text-align: center; margin-top: 16px; font-size: 13px; color: #aaa;">
        还没有账号？
        <router-link to="/register">申请访问权限</router-link>
      </p>
    </div>
  </div>
</template>
