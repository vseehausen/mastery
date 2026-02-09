import { defineConfig } from 'wxt';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  modules: ['@wxt-dev/module-svelte'],
  vite: () => ({
    plugins: [tailwindcss()],
  }),
  manifest: {
    name: 'Mastery — Vocabulary Capture',
    description: 'Double-click any word to translate, learn, and master it.',
    permissions: ['activeTab', 'contextMenus', 'storage'],
  },
  runner: {
    chromiumProfile: './.wxt/chrome-profile',
  },
});
