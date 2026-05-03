<script setup>
import { useEndpointsStore } from '../stores/endpoints.js';
import AppLayout from '../components/AppLayout.vue';

const endpointsStore = useEndpointsStore();
const tiers = endpointsStore.tiers;

function methodClass(method) {
  return `method-${method.toLowerCase()}`;
}
</script>

<template>
  <AppLayout>
    <div class="page-header">
      <h2>接口文档</h2>
    </div>

    <div v-for="tier in tiers" :key="tier.name" class="tier-group">
      <h3>{{ tier.name }}</h3>
      <div class="card" style="padding: 0;">
        <table class="data-table">
          <thead>
            <tr>
              <th style="width: 80px;">方法</th>
              <th>接口路径</th>
              <th>说明</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="ep in tier.endpoints" :key="ep.path">
              <td>
                <span class="method-badge" :class="methodClass(ep.method)">
                  {{ ep.method }}
                </span>
              </td>
              <td><code style="font-size: 13px;">{{ ep.path }}</code></td>
              <td class="text-muted">{{ ep.desc }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </AppLayout>
</template>
