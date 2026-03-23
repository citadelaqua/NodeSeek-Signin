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
      <button
        class="text-sm px-3 py-1.5 rounded-lg bg-indigo-600 text-white hover:bg-indigo-700 transition disabled:opacity-50"
        :disabled="triggering"
        @click="triggerAll"
      >
        {{ triggering ? '签到中…' : '立即签到' }}
      </button>
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
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { signinApi } from '../api'

const router = useRouter()
const auth = useAuthStore()
const triggering = ref(false)

const links = [
  { to: '/', label: '总览' },
  { to: '/accounts', label: '账号' },
  { to: '/logs', label: '日志' },
  { to: '/config', label: '配置' },
]

async function triggerAll() {
  triggering.value = true
  try {
    await signinApi.triggerAll()
  } catch {
    // error handled globally
  } finally {
    setTimeout(() => (triggering.value = false), 2000)
  }
}

function handleLogout() {
  auth.logout()
  router.push('/login')
}
</script>
