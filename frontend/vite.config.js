import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    host: '0.0.0.0', // 监听所有接口，WSL2 兼容
    port: 34115, // 使用高位端口避免权限问题
    strictPort: false, // 如果端口被占用，自动尝试下一个
    hmr: {
      host: 'localhost' // HMR 使用 localhost
    }
  },
  build: {
    outDir: 'dist',
    emptyOutDir: true
  }
})
