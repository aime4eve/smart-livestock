<script setup>
import { ref, onMounted, onBeforeUnmount, watch } from 'vue';
import {
  Chart,
  LineController,
  LineElement,
  PointElement,
  LinearScale,
  CategoryScale,
  Filler,
  Tooltip,
} from 'chart.js';

Chart.register(LineController, LineElement, PointElement, LinearScale, CategoryScale, Filler, Tooltip);

const props = defineProps({
  labels: { type: Array, required: true },
  datasets: { type: Array, required: true },
});

const chartRef = ref(null);
let chartInstance = null;

function createChart() {
  if (!chartRef.value) return;
  if (chartInstance) chartInstance.destroy();

  chartInstance = new Chart(chartRef.value, {
    type: 'line',
    data: {
      labels: props.labels,
      datasets: props.datasets,
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: { mode: 'index', intersect: false },
      },
      scales: {
        x: { grid: { display: false } },
        y: { beginAtZero: true, grid: { color: '#f0f0f0' } },
      },
      elements: {
        line: { tension: 0.4, borderWidth: 2.5 },
        point: { radius: 4, hoverRadius: 6, backgroundColor: '#fff', borderWidth: 2 },
      },
    },
  });
}

onMounted(createChart);

watch(
  () => [props.labels, props.datasets],
  () => createChart(),
  { deep: true },
);

onBeforeUnmount(() => {
  if (chartInstance) chartInstance.destroy();
});
</script>

<template>
  <div style="position: relative; height: 220px;">
    <canvas ref="chartRef"></canvas>
  </div>
</template>
