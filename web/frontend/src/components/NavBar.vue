<template>
  <nav class="bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-700 px-6 py-3 flex items-center justify-between shadow-sm">
    <div class="flex items-center gap-6">
      <RouterLink to="/" class="text-lg font-bold text-indigo-600 dark:text-indigo-400 hover:opacity-80 transition">
        🐔 NodeSeek 签到
      </RouterLink>
      <div class="hidden sm:flex gap-4 text-sm font-medium">
        <RouterLink
          v-for="link in links"
          :key="link.to"
          :to="link.to"
          class="text-gray-600 dark:text-gray-300 hover:text-indigo-600 dark:hover:text-indigo-400 transition"
          active-class="text-indigo-600 dark:text-indigo-400"
        >
          {{ link.label }}
        </RouterLink>
      </div>
    </div>
    <div class="flex items-center gap-3">
      <div class="relative group">
        <button
          class="text-sm px-3 py-1.5 rounded-lg bg-indigo-600 text-white hover:bg-indigo-700 transition disabled:opacity-40 disabled:cursor-not-allowed"
          :disabled="triggering || !hasEnabledAccounts"
          @click="triggerAll"
        >
          {{ triggering ? '签到中…' : '立即签到' }}
        </button>
        <!-- Tooltip when no enabled accounts -->
        <div
          v-if="!hasEnabledAccounts && !triggering"
          class="pointer-events-none absolute right-0 top-full mt-1.5 w-max max-w-[180px] rounded-lg bg-gray-800 text-white text-xs px-2.5 py-1.5 opacity-0 group-hover:opacity-100 transition-opacity z-50"
        >
          请先在「账号」页添加并启用账号
        </div>
      </div>
      <button
        class="text-sm px-3 py-1.5 rounded-lg border border-gray-300 dark:border-gray-600 text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 transition"
        @click="handleLogout"
      >
        退出
      </button>
    </div>
  </nav>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { accountsApi, signinApi, type Account } from '../api'
import { useToast } from '../composables/useToast'
import { emitAccountsRefreshed, onAccountsRefreshed } from '../composables/useAccountEvents'

const router = useRouter()
const auth = useAuthStore()
const triggering = ref(false)
const allAccounts = ref<Account[]>([])
const { success, warning, error: toastError, info } = useToast()

const hasEnabledAccounts = computed(() => allAccounts.value.some((a) => a.enabled))

const links = [
  { to: '/', label: '总览' },
  { to: '/accounts', label: '账号' },
  { to: '/logs', label: '日志' },
  { to: '/config', label: '配置' },
]

const RESULT_LABEL: Record<string, string> = {
  success: '签到成功',
  already: '已签到',
  fail: '签到失败',
  error: '签到出错',
  forbidden: '被拦截',
  invalid: 'Cookie 无效',
}

// Keep allAccounts in sync when Dashboard/Accounts pages mutate accounts
const unsubscribe = onAccountsRefreshed((accounts) => {
  allAccounts.value = accounts
})
onUnmounted(unsubscribe)

onMounted(async () => {
  allAccounts.value = (await accountsApi.list()).data
})

async function triggerAll() {
  if (triggering.value || !hasEnabledAccounts.value) return
  triggering.value = true
  try {
    // Snapshot current last_signin_at before trigger
    const before = await accountsApi.list()
    allAccounts.value = before.data
    const beforeMap = new Map<number, string | null>(
      before.data.map((a: Account) => [a.id, a.last_signin_at]),
    )

    await signinApi.triggerAll()
    info('签到任务已触发', `共 ${before.data.filter((a: Account) => a.enabled).length} 个账号`)

    // Poll until all enabled accounts have a newer last_signin_at (max 30s)
    const deadline = Date.now() + 30_000
    let settled = false

    while (Date.now() < deadline) {
      await sleep(2000)
      const after = await accountsApi.list()
      const updated = after.data.filter(
        (a: Account) => a.enabled && a.last_signin_at !== beforeMap.get(a.id),
      )

      if (updated.length > 0) {
        // Emit refresh for Dashboard / other subscribers
        allAccounts.value = after.data
        emitAccountsRefreshed(after.data)

        // Show one toast per updated account
        for (const a of updated) {
          const label = RESULT_LABEL[a.last_result ?? ''] ?? `结果: ${a.last_result}`
          const body = a.last_message ?? undefined
          if (a.last_result === 'success' || a.last_result === 'already') {
            success(`${a.label}：${label}`, body)
          } else if (a.last_result === 'fail' || a.last_result === 'forbidden' || a.last_result === 'invalid') {
            warning(`${a.label}：${label}`, body)
          } else {
            toastError(`${a.label}：${label}`, body)
          }
        }

        // If all enabled accounts settled, stop early
        const enabledTotal = after.data.filter((a: Account) => a.enabled).length
        if (updated.length >= enabledTotal) {
          settled = true
          break
        }
        // Update baseline so next poll only catches remaining accounts
        for (const a of updated) beforeMap.set(a.id, a.last_signin_at)
      }
    }

    if (!settled) {
      // Do a final refresh anyway
      const final = await accountsApi.list()
      allAccounts.value = final.data
      emitAccountsRefreshed(final.data)
    }
  } catch (err: unknown) {
    const msg = (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail
    toastError('触发签到失败', msg ?? '请检查网络或重新登录')
  } finally {
    triggering.value = false
  }
}

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

function handleLogout() {
  auth.logout()
  router.push('/login')
}
</script>
