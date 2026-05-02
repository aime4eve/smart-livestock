import { defineStore } from 'pinia';

export const useDashboardStore = defineStore('dashboard', {
  state: () => ({
    quota: {
      monthly: 10000,
      used: 3421,
      remaining: 6579,
    },
    recentUsage: [
      { date: '2026-05-01', calls: 156, endpoint: 'GET /cattle' },
      { date: '2026-05-01', calls: 89, endpoint: 'GET /devices' },
      { date: '2026-04-30', calls: 203, endpoint: 'GET /fences' },
      { date: '2026-04-30', calls: 67, endpoint: 'GET /alerts' },
      { date: '2026-04-29', calls: 178, endpoint: 'GET /cattle' },
      { date: '2026-04-29', calls: 112, endpoint: 'GET /sensors' },
      { date: '2026-04-28', calls: 45, endpoint: 'GET /farm' },
      { date: '2026-04-28', calls: 234, endpoint: 'GET /devices' },
    ],
  }),

  getters: {
    usagePercentage: (state) => {
      return Math.round((state.quota.used / state.quota.monthly) * 100);
    },
  },

  actions: {
    fetchUsage() {
      // Mock implementation — would call apiGet('/usage', token) in production
    },
  },
});
