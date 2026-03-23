<template>
  <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 p-4">
    <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-3">近 {{ days }} 天鸡腿收益</h3>
    <Line v-if="chartData.datasets[0].data.length" :data="chartData" :options="chartOptions" class="max-h-56" />
    <div v-else class="text-center text-gray-400 dark:text-gray-500 text-sm py-8">暂无数据</div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { Line } from 'vue-chartjs'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler,
} from 'chart.js'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend, Filler)

const props = defineProps<{
  daily: { date: string; chickens: number }[]
  days?: number
}>()

const days = computed(() => props.days ?? 30)

const chartData = computed(() => ({
  labels: props.daily.map((d) => d.date.slice(5)), // MM-DD
  datasets: [
    {
      label: '鸡腿',
      data: props.daily.map((d) => d.chickens),
      borderColor: '#4f46e5',
      backgroundColor: 'rgba(79,70,229,0.1)',
      tension: 0.4,
      fill: true,
      pointRadius: 3,
    },
  ],
}))

const chartOptions = {
  responsive: true,
  plugins: {
    legend: { display: false },
    tooltip: { mode: 'index' as const, intersect: false },
  },
  scales: {
    y: { beginAtZero: true, ticks: { precision: 0 } },
  },
}
</script>
