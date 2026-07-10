<script setup>
import { useRoute, useRouter } from 'vue-router';
import { useAuthStore } from '../stores/auth.js';

const route = useRoute();
const router = useRouter();
const authStore = useAuthStore();

const navItems = [
  { path: '/dashboard', label: '仪表盘' },
  { path: '/api-keys', label: 'API Key 管理' },
  { path: '/endpoints', label: '接口文档' },
  { path: '/authorizations', label: '数据授权' },
  { path: '/settings', label: '账户设置' },
];

function isActive(path) {
  return route.path === path;
}

function handleLogout() {
  authStore.logout();
  router.push('/login');
}
</script>

<template>
  <div class="app-layout">
    <aside class="sidebar">
      <div class="sidebar-header">智慧畜牧 API 平台</div>
      <ul class="sidebar-nav">
        <li v-for="item in navItems" :key="item.path">
          <router-link :to="item.path" :class="{ active: isActive(item.path) }">
            {{ item.label }}
          </router-link>
        </li>
      </ul>
    </aside>

    <div class="main-area">
      <header class="topbar">
        <span class="topbar-title">智慧畜牧 API 平台</span>
        <div class="topbar-user">
          <span>{{ authStore.user?.name || authStore.user?.tenantName || '开发者' }}</span>
          <button class="logout-btn" @click="handleLogout">退出登录</button>
        </div>
      </header>
      <main class="page-content">
        <slot />
      </main>
    </div>
  </div>
</template>
