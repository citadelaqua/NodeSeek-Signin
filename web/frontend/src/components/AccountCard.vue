<template>
  <div
    class="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 p-4 flex flex-col gap-2"
    :class="{ 'opacity-50': !account.enabled }"
  >
    <div class="flex items-center justify-between">
      <span class="font-semibold text-gray-800 dark:text-gray-100 truncate max-w-[60%]">{{ account.label }}</span>
      <span :class="statusClass" class="text-xs font-medium px-2 py-0.5 rounded-full">
        {{ statusLabel }}
      </span>
    </div>
    <div v-if="account.last_message" class="text-xs text-gray-500 dark:text-gray-400 truncate">
      {{ account.last_message }}
    </div>
    <div class="flex items-center justify-between text-xs text-gray-400 dark:text-gray-500 mt-1">
      <span>{{ account.username || '仅 Cookie' }}</span>
      <span>{{ lastSignedLabel }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { Account } from '../api'

const props = defineProps<{ account: Account }>()

const statusLabel = computed(() => {
  switch (props.account.last_result) {
    case 'success': return '✅ 已签到'
    case 'already': return '✅ 已签到'
    case 'fail': return '❌ 失败'
    case 'error': return '⚠️ 错误'
    case 'forbidden': return '🚫 被拦截'
    default: return '⏳ 未签到'
  }
})

const statusClass = computed(() => {
  switch (props.account.last_result) {
    case 'success':
    case 'already':
      return 'bg-green-100 text-green-700 dark:bg-green-900/40 dark:text-green-400'
    case 'fail':
    case 'error':
    case 'forbidden':
      return 'bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-400'
    default:
      return 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400'
  }
})

const lastSignedLabel = computed(() => {
  if (!props.account.last_signin_at) return '从未'
  return new Date(props.account.last_signin_at).toLocaleString('zh-CN', {
    month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit',
  })
})
</script>
