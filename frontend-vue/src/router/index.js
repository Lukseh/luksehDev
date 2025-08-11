import { createRouter, createWebHistory } from 'vue-router'
import Home from '../views/Home.vue'
import GitHub from '../views/GitHub.vue'
import CV from '../views/CV.vue'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home,
    meta: {
      title: 'lukseh.dev - Developer Portfolio'
    }
  },
  {
    path: '/github',
    name: 'GitHub',
    component: GitHub,
    meta: {
      title: 'GitHub Repositories - lukseh.dev'
    }
  },
  {
    path: '/cv',
    name: 'CV',
    component: CV,
    meta: {
      title: 'Curriculum Vitae - lukseh.dev'
    }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) {
      return savedPosition
    } else {
      return { top: 0 }
    }
  }
})

// Update page title based on route
router.beforeEach((to, from, next) => {
  document.title = to.meta.title || 'lukseh.dev'
  next()
})

export default router
