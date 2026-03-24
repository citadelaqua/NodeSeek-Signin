<template>
  <Teleport to="body">
    <div class="fixed top-4 right-4 z-[9999] flex flex-col gap-2 pointer-events-none" style="max-width: 320px">
      <Transition
        v-for="t in toasts"
        :key="t.id"
        name="toast"
        appear
      >
        <div
          :class="[
            'pointer-events-auto flex items-start gap-2 px-4 py-3 rounded-xl shadow-lg text-sm font-medium',
            colorClass(t.type),
          ]"
        >
          <span>{{ icon(t.type) }}</span>
          <div class="flex flex-col gap-0.5 min-w-0">
            <span class="font-semibold truncate">{{ t.title }}</span>
            <span v-if="t.body" class="font-normal opacity-90 break-words">{{ t.body }}</span>
          </div>
        </div>
      </Transition>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { useToast } from '../composables/useToast'

const { toasts } = useToast()

function colorClass(type: string) {
  switch (type) {
    case 'success': return 'bg-green-600 text-white'
    case 'warning': return 'bg-yellow-500 text-white'
    case 'error': return 'bg-red-600 text-white'
    default: return 'bg-gray-800 text-white'
  }
}

function icon(type: string) {
  switch (type) {
    case 'success': return '✅'
    case 'warning': return '⚠️'
    case 'error': return '❌'
    default: return 'ℹ️'
  }
}
</script>

<style scoped>
.toast-enter-active { transition: all 0.25s ease; }
.toast-leave-active { transition: all 0.2s ease; }
.toast-enter-from { opacity: 0; transform: translateX(40px); }
.toast-leave-to   { opacity: 0; transform: translateX(40px); }
</style>
