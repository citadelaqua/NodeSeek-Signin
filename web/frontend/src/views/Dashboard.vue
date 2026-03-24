<template>
  <div class="min-h-screen bg-gray-50 dark:bg-gray-950">
    <NavBar />
    <main class="max-w-5xl mx-auto px-4 py-6 flex flex-col gap-6">
      <!-- Stat cards -->
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <div
          v-for="card in statCards"
          :key="card.label"
          class="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 p-4 flex flex-col gap-1"
        >
          <span class="text-xs text-gray-500 dark:text-gray-400 uppercase tracking-wide">{{ card.label }}</span>
          <span class="text-2xl font-bold text-gray-800 dark:text-gray-100">{{ card.value }}</span>
        </div>
      </div>

      <!-- Chicken chart -->
      <ChickenChart :daily="allDaily" />

      <!-- Account cards -->
      <div>
        <h2 class="text-sm font-semibold text-gray-500 dark:text-gray-400 mb-3 uppercase tracking-wide">账号状态</h2>
        <div v-if="accounts.length" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <AccountCard v-for="a in accounts" :key="a.id" :account="a" />
        </div>
        <p v-else class="text-sm text-gray-400 dark:text-gray-500">暂无账号，请先在「账号」页面添加。</p>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import NavBar from '../components/NavBar.vue'
import AccountCard from '../components/AccountCard.vue'
import ChickenChart from '../components/ChickenChart.vue'
import { accountsApi, statsApi, type Account, type AccountStats, type GlobalStats } from '../api'
import { onAccountsRefreshed } from '../composables/useAccountEvents'

const accounts = ref<Account[]>([])
const globalStats = ref<GlobalStats | null>(null)
const allStats = ref<AccountStats[]>([])

const statCards = computed(() => [
  { label: '账号总数', value: globalStats.value?.total_accounts ?? '—' },
  {
    label: '今日已签',
    value: globalStats.value
      ? `${globalStats.value.signed_today}/${globalStats.value.total_accounts}`
      : '—',
  },
  { label: '今日鸡腿', value: globalStats.value ? `${globalStats.value.total_chickens_today} 🍗` : '—' },
  { label: '下次执行', value: globalStats.value?.next_run?.slice(11, 16) ?? '—' },
])

// Merge daily data from all accounts
const allDaily = computed(() => {
  const map = new Map<string, number>()
  for (const stat of allStats.value) {
    for (const d of stat.daily) {
      map.set(d.date, (map.get(d.date) ?? 0) + d.chickens)
    }
  }
  return [...map.entries()].sort(([a], [b]) => a.localeCompare(b)).map(([date, chickens]) => ({ date, chickens }))
})

async function refreshStats() {
  const statsRes = await statsApi.global()
  globalStats.value = statsRes.data
  allStats.value = await Promise.all(accounts.value.map((a) => statsApi.account(a.id).then((r) => r.data)))
}

onMounted(async () => {
  const [accsRes, statsRes] = await Promise.all([accountsApi.list(), statsApi.global()])
  accounts.value = accsRes.data
  globalStats.value = statsRes.data
  allStats.value = await Promise.all(accounts.value.map((a) => statsApi.account(a.id).then((r) => r.data)))
})

// Listen for account updates pushed by NavBar after a sign-in poll
const unsubscribe = onAccountsRefreshed((updated) => {
  accounts.value = updated
  refreshStats()
})

onUnmounted(unsubscribe)
</script>
