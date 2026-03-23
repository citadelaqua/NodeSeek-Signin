import axios from 'axios'
import { useAuthStore } from './stores/auth'
import router from './router'

const api = axios.create({
  baseURL: '/api',
  timeout: 30_000,
})

api.interceptors.request.use((config) => {
  const auth = useAuthStore()
  if (auth.token) {
    config.headers.Authorization = `Bearer ${auth.token}`
  }
  return config
})

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      const auth = useAuthStore()
      auth.logout()
      router.push('/login')
    }
    return Promise.reject(err)
  },
)

export default api

// ── API helpers ───────────────────────────────────────────────────────────────

export interface Account {
  id: number
  label: string
  username: string | null
  cookie: string | null
  last_signin_at: string | null
  last_result: string | null
  last_message: string | null
  enabled: boolean
  created_at: string
}

export interface SigninLog {
  id: number
  account_id: number
  result: string
  message: string | null
  chickens: number | null
  triggered_by: string
  created_at: string
}

export interface GlobalStats {
  total_accounts: number
  signed_today: number
  total_chickens_today: number
  next_run: string | null
}

export interface AccountStats {
  account_id: number
  total_chickens: number
  signin_count: number
  daily: { date: string; chickens: number }[]
}

export interface AppConfig {
  run_at: string
  solver_type: string
  api_base_url: string
  ns_random: string
}

export interface SchedulerStatus {
  next_run: string | null
  mode: string
  running: boolean
}

export const authApi = {
  login: (password: string) =>
    api.post<{ access_token: string; token_type: string }>('/auth/token', { password }),
}

export const accountsApi = {
  list: () => api.get<Account[]>('/accounts'),
  create: (data: Partial<Account> & { password?: string }) => api.post<Account>('/accounts', data),
  update: (id: number, data: Partial<Account> & { password?: string }) => api.patch<Account>(`/accounts/${id}`, data),
  remove: (id: number) => api.delete(`/accounts/${id}`),
}

export const signinApi = {
  triggerAll: () => api.post('/signin/trigger'),
  triggerOne: (id: number) => api.post(`/signin/trigger/${id}`),
  logs: (limit = 50, offset = 0) => api.get<SigninLog[]>(`/signin/logs?limit=${limit}&offset=${offset}`),
  accountLogs: (id: number, limit = 50) => api.get<SigninLog[]>(`/signin/logs/${id}?limit=${limit}`),
}

export const statsApi = {
  global: () => api.get<GlobalStats>('/stats'),
  account: (id: number, days = 30) => api.get<AccountStats>(`/stats/${id}?days=${days}`),
}

export const configApi = {
  get: () => api.get<AppConfig>('/config'),
  update: (data: Partial<AppConfig>) => api.put<AppConfig>('/config', data),
  schedulerStatus: () => api.get<SchedulerStatus>('/scheduler/status'),
}
