<script setup>
import { ref } from 'vue';
import { useEndpointsStore } from '../stores/endpoints.js';
import AppLayout from '../components/AppLayout.vue';

const endpointsStore = useEndpointsStore();
const expandedPath = ref(null);

function methodClass(method) {
  return `method-${method.toLowerCase()}`;
}

function toggleExpand(path) {
  expandedPath.value = expandedPath.value === path ? null : path;
}

function hasDetails(ep) {
  return (ep.params && ep.params.length > 0) || (ep.query && ep.query.length > 0) || ep.body || ep.errors;
}
</script>

<template>
  <AppLayout>
    <div class="page-header">
      <h2>接口文档</h2>
    </div>

    <!-- Auth & Rate Limit -->
    <div class="card">
      <div class="card-title">认证方式</div>
      <table class="data-table" style="max-width: 600px;">
        <tbody>
          <tr>
            <td style="font-weight: 500; color: #888; width: 120px;">类型</td>
            <td>{{ endpointsStore.authInfo.type }}</td>
          </tr>
          <tr>
            <td style="font-weight: 500; color: #888;">请求头</td>
            <td><code style="font-size: 13px;">{{ endpointsStore.authInfo.header }}</code></td>
          </tr>
          <tr>
            <td style="font-weight: 500; color: #888;">说明</td>
            <td>{{ endpointsStore.authInfo.desc }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="card">
      <div class="card-title">频率限制</div>
      <p style="font-size: 14px; color: #555; line-height: 1.8;">
        {{ endpointsStore.rateLimit.limit }}<br />
        响应头：<code style="font-size: 13px;">{{ endpointsStore.rateLimit.headers }}</code>
      </p>
    </div>

    <!-- Common Errors -->
    <div class="card">
      <div class="card-title">通用错误码</div>
      <table class="data-table">
        <thead>
          <tr>
            <th style="width: 80px;">状态码</th>
            <th>说明</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="err in endpointsStore.commonErrors" :key="err.code">
            <td><code style="font-size: 13px;">{{ err.code }}</code></td>
            <td class="text-muted">{{ err.desc }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Endpoints by Tier -->
    <div v-for="tier in endpointsStore.tiers" :key="tier.name" class="tier-group">
      <h3>{{ tier.name }}</h3>
      <p class="text-muted" style="font-size: 13px; margin: -8px 0 12px;">{{ tier.desc }}</p>
      <div v-for="ep in tier.endpoints" :key="ep.path" class="card" style="margin-bottom: 8px;">
        <div
          style="display: flex; align-items: center; gap: 12px; cursor: pointer;"
          @click="hasDetails(ep) && toggleExpand(tier.name + ep.path)"
        >
          <span class="method-badge" :class="methodClass(ep.method)" style="min-width: 50px; text-align: center;">
            {{ ep.method }}
          </span>
          <code style="font-size: 13px; flex: 1;">{{ ep.path }}</code>
          <span class="text-muted" style="font-size: 13px;">{{ ep.desc }}</span>
          <span v-if="hasDetails(ep)" style="color: #999; font-size: 11px; margin-left: 4px;">
            {{ expandedPath === tier.name + ep.path ? '▼' : '▶ 详情' }}
          </span>
        </div>

        <!-- Expanded Detail -->
        <div v-if="expandedPath === tier.name + ep.path" style="margin-top: 12px; padding-top: 12px; border-top: 1px solid #eee;">
          <!-- Path Params -->
          <div v-if="ep.params && ep.params.length > 0" style="margin-bottom: 12px;">
            <div style="font-weight: 600; font-size: 13px; margin-bottom: 6px; color: #555;">路径参数</div>
            <table class="data-table" style="font-size: 13px;">
              <thead>
                <tr>
                  <th>参数名</th>
                  <th>类型</th>
                  <th>必填</th>
                  <th>说明</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="p in ep.params" :key="p.name">
                  <td><code>{{ p.name }}</code></td>
                  <td>{{ p.type }}</td>
                  <td>{{ p.required ? '是' : '否' }}</td>
                  <td class="text-muted">{{ p.desc }}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Query Params -->
          <div v-if="ep.query && ep.query.length > 0" style="margin-bottom: 12px;">
            <div style="font-weight: 600; font-size: 13px; margin-bottom: 6px; color: #555;">查询参数</div>
            <table class="data-table" style="font-size: 13px;">
              <thead>
                <tr>
                  <th>参数名</th>
                  <th>类型</th>
                  <th>默认值</th>
                  <th>说明</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="q in ep.query" :key="q.name">
                  <td><code>{{ q.name }}</code></td>
                  <td>{{ q.type }}</td>
                  <td>{{ q.default || '-' }}</td>
                  <td class="text-muted">{{ q.desc }}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Request Body -->
          <div v-if="ep.body" style="margin-bottom: 12px;">
            <div style="font-weight: 600; font-size: 13px; margin-bottom: 6px; color: #555;">请求体 (JSON)</div>
            <pre style="background: #f5f5f5; padding: 12px; border-radius: 6px; font-size: 13px; overflow-x: auto; margin: 0;">{{ ep.body }}</pre>
          </div>

          <!-- Response -->
          <div style="margin-bottom: 12px;">
            <div style="font-weight: 600; font-size: 13px; margin-bottom: 6px; color: #555;">响应格式</div>
            <pre style="background: #f5f5f5; padding: 12px; border-radius: 6px; font-size: 13px; overflow-x: auto; margin: 0;">{{ ep.response }}</pre>
          </div>

          <!-- Errors -->
          <div v-if="ep.errors && ep.errors.length > 0">
            <div style="font-weight: 600; font-size: 13px; margin-bottom: 6px; color: #555;">可能错误</div>
            <ul style="font-size: 13px; color: #666; padding-left: 20px; margin: 0;">
              <li v-for="e in ep.errors" :key="e" style="margin-bottom: 2px;">{{ e }}</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </AppLayout>
</template>
