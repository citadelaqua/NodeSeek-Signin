<template>
  <div class="min-h-screen bg-gray-50 dark:bg-gray-950">
    <NavBar />
    <main class="max-w-4xl mx-auto px-4 py-6">
      <div class="flex items-center justify-between mb-4">
        <h1 class="text-lg font-bold text-gray-800 dark:text-gray-100">账号管理</h1>
        <button
          class="text-sm px-4 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white transition"
          @click="openAdd"
        >
          + 添加账号
        </button>
      </div>

      <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden">
        <table class="min-w-full text-sm">
          <thead class="bg-gray-50 dark:bg-gray-700/50">
            <tr class="text-left text-xs text-gray-500 dark:text-gray-400 uppercase tracking-wide">
              <th class="px-4 py-3">名称</th>
              <th class="px-4 py-3">用户名</th>
              <th class="px-4 py-3">状态</th>
              <th class="px-4 py-3">启用</th>
              <th class="px-4 py-3">操作</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100 dark:divide-gray-700">
            <tr
              v-for="a in accounts"
              :key="a.id"
              class="hover:bg-gray-50 dark:hover:bg-gray-700/40 transition"
            >
              <td class="px-4 py-3 font-medium text-gray-800 dark:text-gray-100">{{ a.label }}</td>
              <td class="px-4 py-3 text-gray-500 dark:text-gray-400">{{ a.username || '—' }}</td>
              <td class="px-4 py-3">
                <span :class="resultClass(a.last_result)" class="text-xs px-2 py-0.5 rounded-full font-medium">
                  {{ a.last_result ?? '未签' }}
                </span>
              </td>
              <td class="px-4 py-3">
                <input type="checkbox" :checked="a.enabled" @change="toggleEnabled(a)" class="accent-indigo-600" />
              </td>
              <td class="px-4 py-3 flex gap-2">
                <button class="text-xs text-indigo-600 hover:underline" @click="openEdit(a)">编辑</button>
                <button class="text-xs text-red-500 hover:underline" @click="removeAccount(a.id)">删除</button>
              </td>
            </tr>
            <tr v-if="!accounts.length">
              <td colspan="5" class="py-10 text-center text-gray-400 dark:text-gray-500">暂无账号</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Modal -->
      <div
        v-if="showModal"
        class="fixed inset-0 bg-black/40 flex items-center justify-center z-50 px-4"
        @click.self="showModal = false"
      >
        <div class="bg-white dark:bg-gray-900 rounded-2xl shadow-xl w-full max-w-md p-6 flex flex-col gap-4">
          <h2 class="text-base font-bold text-gray-800 dark:text-gray-100">{{ editing ? '编辑账号' : '添加账号' }}</h2>
          <label class="flex flex-col gap-1 text-sm text-gray-600 dark:text-gray-400">
            显示名称 *
            <input v-model="form.label" class="input" placeholder="账号1" />
          </label>
          <label class="flex flex-col gap-1 text-sm text-gray-600 dark:text-gray-400">
            Cookie
            <textarea v-model="form.cookie" class="input min-h-[60px] resize-none" placeholder="ns_uid=...; ns_token=..." />
          </label>
          <label class="flex flex-col gap-1 text-sm text-gray-600 dark:text-gray-400">
            用户名（账号密码模式）
            <input v-model="form.username" class="input" placeholder="可选" />
          </label>
          <label class="flex flex-col gap-1 text-sm text-gray-600 dark:text-gray-400">
            密码
            <input v-model="form.password" type="password" class="input" placeholder="可选" />
          </label>
          <div class="flex gap-3 justify-end mt-2">
            <button class="text-sm px-4 py-2 rounded-xl border border-gray-300 dark:border-gray-600 text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 transition" @click="showModal = false">取消</button>
            <button class="text-sm px-4 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white transition" @click="saveAccount">保存</button>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import NavBar from '../components/NavBar.vue'
import { accountsApi, type Account } from '../api'

const accounts = ref<Account[]>([])
const showModal = ref(false)
const editing = ref<Account | null>(null)
const form = ref({ label: '', cookie: '', username: '', password: '' })

async function load() {
  accounts.value = (await accountsApi.list()).data
}

onMounted(load)

function openAdd() {
  editing.value = null
  form.value = { label: '', cookie: '', username: '', password: '' }
  showModal.value = true
}

function openEdit(a: Account) {
  editing.value = a
  form.value = { label: a.label, cookie: a.cookie ?? '', username: a.username ?? '', password: '' }
  showModal.value = true
}

async function saveAccount() {
  if (!form.value.label) return
  if (editing.value) {
    await accountsApi.update(editing.value.id, form.value)
  } else {
    await accountsApi.create(form.value)
  }
  showModal.value = false
  await load()
}

async function removeAccount(id: number) {
  if (!confirm('确认删除该账号？')) return
  await accountsApi.remove(id)
  await load()
}

async function toggleEnabled(a: Account) {
  await accountsApi.update(a.id, { enabled: !a.enabled })
  await load()
}

function resultClass(result: string | null): string {
  if (result === 'success' || result === 'already') return 'bg-green-100 text-green-700 dark:bg-green-900/40 dark:text-green-400'
  if (result === 'fail' || result === 'error' || result === 'forbidden') return 'bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-400'
  return 'bg-gray-100 text-gray-500 dark:bg-gray-700 dark:text-gray-400'
}
</script>

<style scoped>
.input {
  @apply w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-800 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-indigo-500 transition text-sm;
}
</style>
