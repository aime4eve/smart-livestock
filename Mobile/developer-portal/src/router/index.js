import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '../stores/auth.js';

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/LoginView.vue'),
  },
  {
    path: '/register',
    name: 'Register',
    component: () => import('../views/RegisterView.vue'),
  },
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: () => import('../views/DashboardView.vue'),
    meta: { requiresAuth: true },
  },
  {
    path: '/api-keys',
    name: 'ApiKeys',
    component: () => import('../views/ApiKeysView.vue'),
    meta: { requiresAuth: true },
  },
  {
    path: '/endpoints',
    name: 'Endpoints',
    component: () => import('../views/EndpointsView.vue'),
    meta: { requiresAuth: true },
  },
  {
    path: '/authorizations',
    name: 'Authorizations',
    component: () => import('../views/AuthorizationsView.vue'),
    meta: { requiresAuth: true },
  },
  {
    path: '/settings',
    name: 'Settings',
    component: () => import('../views/SettingsView.vue'),
    meta: { requiresAuth: true },
  },
  {
    path: '/',
    redirect: '/dashboard',
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

router.beforeEach((to, from, next) => {
  const authStore = useAuthStore();
  const publicPages = ['/login', '/register'];
  const authRequired = !publicPages.includes(to.path);

  if (authRequired && !authStore.isAuthenticated) {
    next('/login');
  } else {
    next();
  }
});

export default router;
