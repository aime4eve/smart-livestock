<script setup>
import { computed } from 'vue';
import { useDashboardStore } from '../stores/dashboard.js';
import AppLayout from '../components/AppLayout.vue';
import MetricCard from '../components/MetricCard.vue';
import UsageChart from '../components/UsageChart.vue';

const dashboardStore = useDashboardStore();
const { quota, recentUsage, usagePercentage } = dashboardStore;

const chartLabels = computed(() => {
  const dates = [...new Set(recentUsage.map((r) => r.date))].sort();
  return dates;
});

const chartDatasets = computed(() => {
  const dailyTotals = chartLabels.value.map((date) => {
    return recentUsage
      .filter((r) => r.date === date)
      .reduce((sum, r) => sum + r.calls, 0);
  });
  return [
    {
      label: 'API 调用量',
      data: dailyTotals,
      borderColor: '#2e7d32',
      backgroundColor: 'rgba(46, 125, 50, 0.08)',
      fill: true,
    },
  ];
});
</script>

<template>
  <AppLayout>
    <div class="page-header">
      <h2>仪表盘</h2>
    </div>

    <div class="metrics-grid">
      <MetricCard
        title="本月 API 调用量"
        :value="quota.used.toLocaleString()"
        subtitle="过去 30 天"
        color="#1565c0"
      />
      <MetricCard
        title="剩余配额"
        :value="quota.remaining.toLocaleString()"
        :subtitle="`总计 ${quota.monthly.toLocaleString()} 次/月`"
        color="#2e7d32"
      />
      <MetricCard
        title="使用率"
        :value="`${usagePercentage}%`"
        :subtitle="`${quota.used} / ${quota.monthly}`"
        :color="usagePercentage > 80 ? '#c62828' : '#e65100'"
      />
      <MetricCard
        title="API Key 状态"
        value="正常"
        subtitle="最后轮换: 2026-04-15"
        color="#6a1b9a"
      />
    </div>

    <div class="card">
      <div class="card-title">API 调用量趋势（近 7 天）</div>
      <UsageChart :labels="chartLabels" :datasets="chartDatasets" />
    </div>

    <div class="card">
      <div class="card-title">最近 API 调用记录</div>
      <table class="data-table">
        <thead>
          <tr>
            <th>日期</th>
            <th>接口</th>
            <th>调用次数</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(row, i) in recentUsage" :key="i">
            <td>{{ row.date }}</td>
            <td><code style="font-size: 13px;">{{ row.endpoint }}</code></td>
            <td>{{ row.calls.toLocaleString() }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </AppLayout>
</template>
