// developer-portal/src/stores/endpoints.js
import { defineStore } from 'pinia';

export const useEndpointsStore = defineStore('endpoints', {
  state: () => ({
    tiers: [
      {
        name: 'Free',
        desc: '基础只读查询，单个牛只维度',
        endpoints: [
          {
            method: 'GET', path: '/api/open/v1/twin/fever/:id', desc: '查询单只牛发热状态',
            params: [{ name: 'id', in: 'path', type: 'string', required: true, desc: '牛只 ID (livestockId)' }],
            query: [], body: null,
            response: '{ code, data: { livestockId, earTag, status, temperature, ... } }',
            errors: ['404 NOT_FOUND — 牛只不存在或无权访问'],
          },
          {
            method: 'GET', path: '/api/open/v1/twin/estrus/:id', desc: '查询单只牛发情评分',
            params: [{ name: 'id', in: 'path', type: 'string', required: true, desc: '牛只 ID (livestockId)' }],
            query: [], body: null,
            response: '{ code, data: { livestockId, earTag, score, status, ... } }',
            errors: ['404 NOT_FOUND — 牛只不存在或无权访问'],
          },
          {
            method: 'GET', path: '/api/open/v1/twin/digestive/:id', desc: '查询单只牛消化状态',
            params: [{ name: 'id', in: 'path', type: 'string', required: true, desc: '牛只 ID (livestockId)' }],
            query: [], body: null,
            response: '{ code, data: { livestockId, earTag, status, ... } }',
            errors: ['404 NOT_FOUND — 牛只不存在或无权访问'],
          },
          {
            method: 'GET', path: '/api/open/v1/twin/health/:id', desc: '查询单只牛健康综合评分',
            params: [{ name: 'id', in: 'path', type: 'string', required: true, desc: '牛只 ID (livestockId)' }],
            query: [], body: null,
            response: '{ code, data: { livestockId, healthScore, feverStatus, digestiveStatus, ... } }',
            errors: ['404 NOT_FOUND — 牛只不存在或无权访问'],
          },
        ],
      },
      {
        name: 'Growth',
        desc: '批量查询与聚合数据，列表维度',
        endpoints: [
          {
            method: 'GET', path: '/api/open/v1/twin/fever/list', desc: '发热状态列表（分页）',
            params: [],
            query: [{ name: 'page', type: 'integer', default: '1', desc: '页码' }, { name: 'pageSize', type: 'integer', default: '20', desc: '每页条数' }],
            body: null,
            response: '{ code, data: { items: [...], page, pageSize, total } }',
            errors: ['403 TIER_REQUIRED — 需要 Growth 及以上套餐'],
          },
          {
            method: 'GET', path: '/api/open/v1/twin/estrus/list', desc: '发情评分列表（分页）',
            params: [],
            query: [{ name: 'page', type: 'integer', default: '1', desc: '页码' }, { name: 'pageSize', type: 'integer', default: '20', desc: '每页条数' }],
            body: null,
            response: '{ code, data: { items: [...], page, pageSize, total } }',
            errors: ['403 TIER_REQUIRED — 需要 Growth 及以上套餐'],
          },
          {
            method: 'GET', path: '/api/open/v1/twin/epidemic/summary', desc: '疫病摘要统计',
            params: [], query: [], body: null,
            response: '{ code, data: { total, healthy, warning, critical, ... } }',
            errors: ['403 TIER_REQUIRED — 需要 Growth 及以上套餐', '403 FORBIDDEN — 无权访问任何牧场数据'],
          },
          {
            method: 'POST', path: '/api/open/v1/twin/health/batch', desc: '批量健康评分查询',
            params: [], query: [],
            body: '{ "livestockIds": ["ls_001", "ls_002"] }',
            response: '{ code, data: { items: [{ livestockId, healthScore, ... }], total } }',
            errors: ['400 BAD_REQUEST — 请提供 livestockIds 数组', '403 TIER_REQUIRED — 需要 Growth 及以上套餐'],
          },
        ],
      },
      {
        name: 'Scale',
        desc: '完整数据访问，牲畜/围栏/告警列表',
        endpoints: [
          {
            method: 'GET', path: '/api/open/v1/cattle/list', desc: '牛只列表',
            params: [],
            query: [{ name: 'page', type: 'integer', default: '1', desc: '页码' }, { name: 'pageSize', type: 'integer', default: '50', desc: '每页条数' }],
            body: null,
            response: '{ code, data: { items: [{ livestockId, earTag, breed, ... }], total } }',
            errors: ['403 TIER_REQUIRED — 需要 Scale 及以上套餐'],
          },
          {
            method: 'GET', path: '/api/open/v1/fence/list', desc: '电子围栏列表',
            params: [],
            query: [{ name: 'page', type: 'integer', default: '1', desc: '页码' }, { name: 'pageSize', type: 'integer', default: '20', desc: '每页条数' }],
            body: null,
            response: '{ code, data: { items: [{ id, name, status, ... }], total } }',
            errors: ['403 TIER_REQUIRED — 需要 Scale 及以上套餐'],
          },
          {
            method: 'GET', path: '/api/open/v1/alert/list', desc: '告警列表',
            params: [],
            query: [{ name: 'page', type: 'integer', default: '1', desc: '页码' }, { name: 'pageSize', type: 'integer', default: '20', desc: '每页条数' }],
            body: null,
            response: '{ code, data: { items: [{ id, type, severity, ... }], total } }',
            errors: ['403 TIER_REQUIRED — 需要 Scale 及以上套餐'],
          },
          {
            method: 'POST', path: '/api/open/v1/twin/fever/batch', desc: '批量发热数据查询',
            params: [], query: [],
            body: '{ "livestockIds": ["ls_001", "ls_002"] }',
            response: '{ code, data: { items: [{ livestockId, temperature, status, ... }], total } }',
            errors: ['400 BAD_REQUEST — 请提供 livestockIds 数组', '403 TIER_REQUIRED — 需要 Scale 及以上套餐'],
          },
        ],
      },
    ],
    authInfo: {
      type: 'API Key',
      header: 'X-API-Key: <your_api_key>',
      desc: '所有 Open API 请求需在 Header 中携带 API Key。在「API Key 管理」页面创建。',
    },
    rateLimit: {
      limit: '100 次/分钟（按 Key 维度）',
      headers: 'X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset',
    },
    commonErrors: [
      { code: 400, desc: '请求参数错误' },
      { code: 401, desc: '未提供有效的 API Key' },
      { code: 403, desc: '权限不足（tier 不够或无牧场访问权）' },
      { code: 404, desc: '资源不存在' },
      { code: 429, desc: '请求频率超限' },
      { code: 500, desc: '服务器内部错误' },
    ],
  }),

  actions: {
    loadEndpoints() {
      // Static data already in state
    },
  },
});
