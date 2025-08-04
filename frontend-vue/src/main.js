import './assets/main.css'
import '@mdi/font/css/materialdesignicons.css'

import { createApp } from 'vue'
import App from './App.vue'
import router from './router'

// Vuetify
import 'vuetify/styles'
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'

const vuetify = createVuetify({
  components,
  directives,
  theme: {
    defaultTheme: 'dark',
    themes: {
      dark: {
        colors: {
          primary: '#667eea',
          secondary: '#764ba2',
          accent: '#4CAF50',
          error: '#ff6b6b',
          warning: '#ffd93d',
          info: '#0077B5',
          success: '#4CAF50'
        }
      }
    }
  }
})

createApp(App).use(vuetify).use(router).mount('#app')
