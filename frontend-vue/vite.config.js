import { fileURLToPath, URL } from 'node:url'

// Minimal config without external plugins to avoid module resolution issues
export default {
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
