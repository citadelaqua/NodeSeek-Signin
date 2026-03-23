<template>
  <div class="overflow-x-auto">
    <table class="min-w-full text-sm">
      <thead>
        <tr class="text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide border-b border-gray-200 dark:border-gray-700">
          <th class="pb-2 pr-4">时间</th>
          <th class="pb-2 pr-4">账号</th>
          <th class="pb-2 pr-4">结果</th>
          <th class="pb-2 pr-4">鸡腿</th>
          <th class="pb-2">消息</th>
        </tr>
      </thead>
      <tbody class="divide-y divide-gray-100 dark:divide-gray-700">
        <tr v-for="log in logs" :key="log.id" class="hover:bg-gray-50 dark:hover:bg-gray-700/40 transition">
          <td class="py-2 pr-4 text-gray-500 dark:text-gray-400 whitespace-nowrap">
            {{ fmtDate(log.created_at) }}
          </td>
          <td class="py-2 pr-4 text-gray-700 dark:text-gray-300">
            {{ accountLabel(log.account_id) }}
          </td>
          <td class="py-2 pr-4">
            <span :class="resultClass(log.result)" class="text-xs font-medium px-2 py-0.5 rounded-full">
              {{ log.result }}
            </span>
          </td>
          <td class="py-2 pr-4 text-yellow-600 dark:text-yellow-400">
            {{ log.chickens != null ? `+${log.chickens} 🍗` : '—' }}
          </td>
          <td class="py-2 text-gray-500 dark:text-gray-400 max-w-xs truncate">{{ log.message }}</td>
        </tr>
        <tr v-if="!logs.length">
          <td colspan="5" class="py-8 text-center text-gray-400 dark:text-gray-500">暂无日志</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup lang="ts">
import type { Account, SigninLog } from '../api'

const props = defineProps<{
  logs: SigninLog[]
  accounts?: Account[]
}>()

function accountLabel(id: number): string {
  return props.accounts?.find((a) => a.id === id)?.label ?? `#${id}`
}

function fmtDate(dt: string): string {
  return new Date(dt).toLocaleString('zh-CN', {
    month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit',
  })
}

function resultClass(result: string): string {
  if (result === 'success' || result === 'already')
    return 'bg-green-100 text-green-700 dark:bg-green-900/40 dark:text-green-400'
  if (result === 'fail' || result === 'error' || result === 'forbidden')
    return 'bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-400'
  return 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400'
}
</script>
