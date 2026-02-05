import { createRouter, createWebHashHistory } from 'vue-router'
import SetPassword from '../views/SetPassword.vue'
import Login from '../views/Login.vue'
import Dashboard from '../views/Dashboard.vue'
import Settings from '../views/Settings.vue'

const routes = [
  {
    path: '/',
    redirect: '/login'
  },
  {
    path: '/set-password',
    name: 'SetPassword',
    component: SetPassword
  },
  {
    path: '/login',
    name: 'Login',
    component: Login
  },
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: Dashboard
  },
  {
    path: '/settings',
    name: 'Settings',
    component: Settings
  }
]

const router = createRouter({
  history: createWebHashHistory(),
  routes
})

export default router
