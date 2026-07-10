// developer-portal/src/stores/apiKeys.js
import { defineStore } from 'pinia';
import { apiGet, apiPost } from '../api/client.js';

export const useApiKeysStore = defineStore('apiKeys', {
  state: () => ({
    keys: [],
    loading: false,
    error: null,
  }),

  actions: {
    async fetchKeys(token) {
      this.loading = true;
      this.error = null;
      try {
        const res = await apiGet('/api-keys', token);
        const data = res.data ?? res;
        this.keys = Array.isArray(data) ? data : [];
      } catch (e) {
        this.error = e.message || '加载失败';
        this.keys = [];
      } finally {
        this.loading = false;
      }
    },

    async createKey(token) {
      this.loading = true;
      this.error = null;
      try {
        const res = await apiPost('/api-keys', {}, token);
        const data = res.data ?? res;
        await this.fetchKeys(token);
        return data.rawKey || null;
      } catch (e) {
        this.error = e.message || '创建失败';
        throw e;
      } finally {
        this.loading = false;
      }
    },

    async rotateKey(keyId, token) {
      this.loading = true;
      this.error = null;
      try {
        const res = await apiPost(`/api-keys/${keyId}/rotate`, {}, token);
        const data = res.data ?? res;
        await this.fetchKeys(token);
        return data.rawKey || null;
      } catch (e) {
        this.error = e.message || '轮换失败';
        throw e;
      } finally {
        this.loading = false;
      }
    },
  },
});
