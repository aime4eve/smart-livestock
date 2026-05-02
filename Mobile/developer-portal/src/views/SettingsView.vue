<script setup>
import { useAuthStore } from '../stores/auth.js';
import AppLayout from '../components/AppLayout.vue';

const authStore = useAuthStore();
const user = authStore.user || {};
</script>

<template>
  <AppLayout>
    <div class="page-header">
      <h2>账户设置</h2>
    </div>

    <div class="card">
      <div class="card-title">账户信息</div>
      <table class="data-table" style="max-width: 500px;">
        <tbody>
          <tr>
            <td style="font-weight: 500; color: #888; width: 120px;">角色</td>
            <td>{{ user.role || 'API 开发者' }}</td>
          </tr>
          <tr>
            <td style="font-weight: 500; color: #888;">用户名</td>
            <td>{{ user.name || user.tenantName || '-' }}</td>
          </tr>
          <tr>
            <td style="font-weight: 500; color: #888;">邮箱</td>
            <td>{{ user.email || '-' }}</td>
          </tr>
          <tr>
            <td style="font-weight: 500; color: #888;">订阅套餐</td>
            <td>
              <span class="badge badge-green">{{ user.tier || 'Free' }}</span>
            </td>
          </tr>
          <tr>
            <td style="font-weight: 500; color: #888;">Token</td>
            <td>
              <code style="font-size: 12px;">{{ authStore.token.substring(0, 20) }}...</code>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="card">
      <div class="card-title">API 使用限制</div>
      <p style="font-size: 14px; color: #666; line-height: 1.8;">
        每月调用配额: 10,000 次<br />
        速率限制: 100 次/分钟<br />
        数据保留: 30 天历史数据
      </p>
    </div>
  </AppLayout>
</template>
