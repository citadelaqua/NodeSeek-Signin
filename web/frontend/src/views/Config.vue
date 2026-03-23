<template>
  <div class="min-h-screen bg-gray-50 dark:bg-gray-950">
    <NavBar />
    <main class="max-w-2xl mx-auto px-4 py-6">
      <h1 class="text-lg font-bold text-gray-800 dark:text-gray-100 mb-4">配置</h1>

      <div v-if="cfg" class="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 p-6 flex flex-col gap-5">
        <label class="flex flex-col gap-1 text-sm text-gray-600 dark:text-gray-400">
          签到时间 (RUN_AT)
          <input v-model="cfg.run_at" class="input" placeholder="08:00-10:59" />
          <span class="text-xs text-gray-400">支持固定时间 <code>10:30</code> 或时间范围 <code>08:00-10:59</code></span>
        </label>

        <label class="flex flex-col gap-1 text-sm text-gray-600 dark:text-gray-400">
          验证码方案 (SOLVER_TYPE)
          <select v-model="cfg.solver_type" class="input">
            <option value="turnstile">turnstile（自建 CloudFreed）</option>
            <option value="yescaptcha">yescaptcha（商业服务）</option>
          </select>
        </label>

        <label class="flex flex-col gap-1 text-sm text-gray-600 dark:text-gray-400">
          验证码服务地址 (API_BASE_URL)
          <input v-model="cfg.api_base_url" class="input" placeholder="http://127.0.0.1:3000" />
        </label>

        <label class="flex flex-col gap-1 text-sm text-gray-600 dark:text-gray-400">
          随机签到 (NS_RANDOM)
          <select v-model="cfg.ns_random" class="input">
            <option value="true">true（随机）</option>
            <option value="false">false（不随机）</option>
          </select>
        </label>

        <div v-if="saved" class="text-sm text-green-600 dark:text-green-400">✅ 已保存</div>
        <div v-if="error" class="text-sm text-red-500">{{ error }}</div>

        <div class="flex justify-end">
          <button
            class="text-sm px-5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white transition"
            :disabled="saving"
            @click="save"
          >
            {{ saving ? '保存中…' : '保存配置' }}
          </button>
        </div>
      </div>

      <!-- Scheduler status -->
      <div v-if="schedulerStatus" class="mt-4 bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 p-5">
        <h2 class="text-sm font-semibold text-gray-500 dark:text-gray-400 mb-3 uppercase tracking-wide">调度器状态</h2>
        <div class="grid grid-cols-3 gap-4 text-center">
          <div>
            <div class="text-xs text-gray-400">模式</div>
            <div class="font-semibold text-gray-800 dark:text-gray-100">{{ schedulerStatus.mode }}</div>
          </div>
          <div>
            <div class="text-xs text-gray-400">运行中</div>
            <div class="font-semibold" :class="schedulerStatus.running ? 'text-yellow-500' : 'text-green-500'">
              {{ schedulerStatus.running ? '是' : '空闲' }}
            </div>
          </div>
          <div>
            <div class="text-xs text-gray-400">下次执行</div>
            <div class="font-semibold text-gray-800 dark:text-gray-100 text-sm">
              {{ schedulerStatus.next_run?.slice(11, 16) ?? '—' }}
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import NavBar from '../components/NavBar.vue'
import { configApi, type AppConfig, type SchedulerStatus } from '../api'

const cfg = ref<AppConfig | null>(null)
const schedulerStatus = ref<SchedulerStatus | null>(null)
const saving = ref(false)
const saved = ref(false)
const error = ref('')

onMounted(async () => {
  const [cfgRes, schedRes] = await Promise.all([configApi.get(), configApi.schedulerStatus()])
  cfg.value = cfgRes.data
  schedulerStatus.value = schedRes.data
})

async function save() {
  if (!cfg.value) return
  saving.value = true
  error.value = ''
  saved.value = false
  try {
    await configApi.update(cfg.value)
    saved.value = true
    schedulerStatus.value = (await configApi.schedulerStatus()).data
    setTimeout(() => (saved.value = false), 3000)
  } catch (e: unknown) {
    error.value = '保存失败'
  } finally {
    saving.value = false
  }
}
</script>

<style scoped>
.input {
  @apply w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-800 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-indigo-500 transition text-sm;
}
</style>
