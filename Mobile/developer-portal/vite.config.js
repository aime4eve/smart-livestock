import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';

export default defineConfig({
  plugins: [vue()],
  test: { environment: 'jsdom' },
  build: { outDir: 'dist' },
  server: { port: 5173 },
});
