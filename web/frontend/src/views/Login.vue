<template>
  <div class="min-h-screen bg-gray-50 dark:bg-gray-950 flex items-center justify-center px-4">
    <div class="bg-white dark:bg-gray-900 rounded-2xl shadow-md w-full max-w-sm p-8">
      <div class="text-center mb-6">
        <div class="text-4xl mb-2">🐔</div>
        <h1 class="text-xl font-bold text-gray-800 dark:text-gray-100">NodeSeek 签到面板</h1>
        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">请输入访问密码</p>
      </div>
      <form @submit.prevent="handleLogin" class="flex flex-col gap-4">
        <input
          v-model="password"
          type="password"
          placeholder="密码"
          autocomplete="current-password"
          class="w-full px-4 py-2.5 rounded-xl border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-800 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-indigo-500 transition"
        />
        <div v-if="error" class="text-sm text-red-500 text-center">{{ error }}</div>
        <button
          type="submit"
          :disabled="loading"
          class="w-full py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-medium transition disabled:opacity-50"
        >
          {{ loading ? '登录中…' : '登录' }}
        </button>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { authApi } from '../api'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const auth = useAuthStore()
const password = ref('')
const loading = ref(false)
const error = ref('')

async function handleLogin() {
  if (!password.value) return
  loading.value = true
  error.value = ''
  try {
    const res = await authApi.login(password.value)
    auth.setToken(res.data.access_token)
    router.push('/')
  } catch {
    error.value = '密码错误，请重试'
  } finally {
    loading.value = false
  }
}
</script>
