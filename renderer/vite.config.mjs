import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'node:path';

export default defineConfig(() => {
  const rootDir = __dirname;

  return {
    root: rootDir,
    base: './',
    plugins: [react()],
    publicDir: false,
    build: {
      outDir: path.resolve(rootDir, 'dist'),
      emptyOutDir: true,
      minify: 'terser',
      terserOptions: {
        compress: {
          drop_console: true,
          drop_debugger: true
        }
      },
      rollupOptions: {
        output: {
          manualChunks: undefined
        }
      }
    },
    server: {
      proxy: {
        '/registry': {
          target: 'https://registry.modelcontextprotocol.io',
          changeOrigin: true,
          secure: true,
          rewrite: pathValue => pathValue.replace(/^\/registry/, '')
        }
      }
    },
    resolve: {
      alias: {
        '@': path.resolve(rootDir, 'src')
      }
    }
  };
});
