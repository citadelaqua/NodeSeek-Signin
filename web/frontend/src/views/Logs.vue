<template>
  <div class="min-h-screen bg-gray-50 dark:bg-gray-950">
    <NavBar />
    <main class="max-w-5xl mx-auto px-4 py-6">
      <h1 class="text-lg font-bold text-gray-800 dark:text-gray-100 mb-4">签到日志</h1>
      <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 p-4">
        <LogTable :logs="logs" :accounts="accounts" />
        <div class="flex justify-center mt-4 gap-3">
          <button
            v-if="hasMore"
            class="text-sm px-4 py-2 rounded-xl border border-gray-300 dark:border-gray-600 text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 transition"
            :disabled="loading"
            @click="loadMore"
          >
            {{ loading ? '加载中…' : '加载更多' }}
          </button>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import NavBar from '../components/NavBar.vue'
import LogTable from '../components/LogTable.vue'
import { accountsApi, signinApi, type Account, type SigninLog } from '../api'

const logs = ref<SigninLog[]>([])
const accounts = ref<Account[]>([])
const loading = ref(false)
const offset = ref(0)
const limit = 50
const hasMore = ref(true)

onMounted(async () => {
  accounts.value = (await accountsApi.list()).data
  await loadMore()
})

async function loadMore() {
  loading.value = true
  const res = await signinApi.logs(limit, offset.value)
  const newLogs = res.data
  logs.value.push(...newLogs)
  offset.value += newLogs.length
  hasMore.value = newLogs.length === limit
  loading.value = false
}
</script>
