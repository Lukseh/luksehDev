import { fileURLToPath, URL } from 'node:url'
import vue from '@vitejs/plugin-vue'

// Simple config without importing from 'vite'
export default {
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    },
  },
  server: {
    port: 5174,
    host: true
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: false,
    minify: true
  }
}
