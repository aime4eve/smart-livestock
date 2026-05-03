// developer-portal/src/stores/endpoints.js
import { defineStore } from 'pinia';

export const useEndpointsStore = defineStore('endpoints', {
  state: () => ({
    tiers: [
      {
        name: 'Free 免费版',
        endpoints: [
          { method: 'GET', path: '/api/v1/cattle', desc: '查询牛只列表' },
          { method: 'GET', path: '/api/v1/cattle/:id', desc: '查询牛只详情' },
          { method: 'GET', path: '/api/v1/devices', desc: '查询设备列表' },
          { method: 'GET', path: '/api/v1/alerts', desc: '查询告警列表' },
          { method: 'GET', path: '/api/v1/fences', desc: '查询围栏列表' },
        ],
      },
      {
        name: 'Growth 成长版',
        endpoints: [
          { method: 'GET', path: '/api/v1/sensors/:id/temperature', desc: '查询瘤胃温度数据' },
          { method: 'GET', path: '/api/v1/sensors/:id/peristalsis', desc: '查询瘤胃蠕动数据' },
          { method: 'GET', path: '/api/v1/cattle/:id/history', desc: '查询牛只运动轨迹' },
          { method: 'POST', path: '/api/v1/fences', desc: '创建电子围栏' },
          { method: 'PUT', path: '/api/v1/fences/:id', desc: '更新电子围栏' },
        ],
      },
      {
        name: 'Scale 企业版',
        endpoints: [
          { method: 'POST', path: '/api/v1/cattle', desc: '录入新牛只' },
          { method: 'PUT', path: '/api/v1/cattle/:id', desc: '更新牛只信息' },
          { method: 'GET', path: '/api/v1/stats/health', desc: '牛群健康统计' },
          { method: 'GET', path: '/api/v1/stats/behavior', desc: '行为分析统计' },
          { method: 'POST', path: '/api/v1/alerts/:id/acknowledge', desc: '确认告警' },
          { method: 'DELETE', path: '/api/v1/fences/:id', desc: '删除电子围栏' },
        ],
      },
    ],
  }),

  actions: {
    loadEndpoints() {
      // Static data already in state — no API call needed
    },
  },
});
