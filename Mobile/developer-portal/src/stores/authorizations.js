// developer-portal/src/stores/authorizations.js
import { defineStore } from 'pinia';
import { apiGet, apiPost } from '../api/client.js';

export const useAuthorizationsStore = defineStore('authorizations', {
  state: () => ({
    authorizations: [],
    loading: false,
    error: null,
  }),

  actions: {
    async fetchAuthorizations(token) {
      this.loading = true;
      this.error = null;
      try {
        const res = await apiGet('/api-authorizations', token);
        const data = res.data ?? res;
        this.authorizations = data.items ?? (Array.isArray(data) ? data : []);
      } catch (e) {
        this.error = e.message || '加载失败';
        this.authorizations = [];
      } finally {
        this.loading = false;
      }
    },

    async submitAuthorization({ farmTenantId, requestedScopes }, token) {
      this.loading = true;
      this.error = null;
      try {
        await apiPost('/api-authorizations', { farmTenantId, requestedScopes }, token);
        await this.fetchAuthorizations(token);
      } catch (e) {
        this.error = e.message || '提交失败';
        throw e;
      } finally {
        this.loading = false;
      }
    },
  },
});
