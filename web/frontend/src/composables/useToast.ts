import { ref } from 'vue'

export interface Toast {
  id: number
  type: 'success' | 'warning' | 'error' | 'info'
  title: string
  body?: string
}

const toasts = ref<Toast[]>([])
let nextId = 0

export function useToast() {
  function show(type: Toast['type'], title: string, body?: string, duration = 4000) {
    const id = ++nextId
    toasts.value.push({ id, type, title, body })
    setTimeout(() => {
      toasts.value = toasts.value.filter((t) => t.id !== id)
    }, duration)
  }

  return {
    toasts,
    success: (title: string, body?: string) => show('success', title, body),
    warning: (title: string, body?: string) => show('warning', title, body),
    error:   (title: string, body?: string) => show('error', title, body),
    info:    (title: string, body?: string) => show('info', title, body),
  }
}
