import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/login', component: () => import('../views/Login.vue'), meta: { public: true } },
    { path: '/', component: () => import('../views/Dashboard.vue') },
    { path: '/accounts', component: () => import('../views/Accounts.vue') },
    { path: '/logs', component: () => import('../views/Logs.vue') },
    { path: '/config', component: () => import('../views/Config.vue') },
    { path: '/:pathMatch(.*)*', redirect: '/' },
  ],
})

router.beforeEach((to) => {
  const auth = useAuthStore()
  if (!to.meta.public && !auth.isLoggedIn()) {
    return '/login'
  }
  if (to.path === '/login' && auth.isLoggedIn()) {
    return '/'
  }
})

export default router
