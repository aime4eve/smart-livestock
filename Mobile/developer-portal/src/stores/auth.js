import { defineStore } from 'pinia';
import { apiGet } from '../api/client.js';

export const useAuthStore = defineStore('auth', {
  state: () => ({
    token: '',
    user: null,
  }),

  getters: {
    isAuthenticated: (state) => !!state.token && !!state.user,
  },

  actions: {
    async login(token) {
      this.token = token;
      try {
        const data = await apiGet('/me', token);
        this.user = data.data ?? data;
      } catch {
        this.token = '';
        this.user = null;
        throw new Error('登录失败：无效的 API Token');
      }
    },

    logout() {
      this.token = '';
      this.user = null;
    },

    async fetchProfile() {
      if (!this.token) return;
      try {
        const data = await apiGet('/me', this.token);
        this.user = data.data ?? data;
      } catch {
        // token may have expired
      }
    },
  },
});
