import { ref } from 'vue'
import type { Account } from '../api'

// Tiny event bus: components emit/listen for 'accounts-refreshed'
type Listener = (accounts: Account[]) => void
const listeners = new Set<Listener>()

export function onAccountsRefreshed(fn: Listener) {
  listeners.add(fn)
  return () => listeners.delete(fn)
}

export function emitAccountsRefreshed(accounts: Account[]) {
  for (const fn of listeners) fn(accounts)
}

// Shared in-flight poll ref so NavBar + others can cancel
export const signinPolling = ref(false)
