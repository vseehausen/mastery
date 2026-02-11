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
    permissions: ['activeTab', 'contextMenus', 'storage', 'identity'],
    key: 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApeUtpXcQEkkaHlwj1xEdFHenKyvjJexIE+JZ6t/RDnJSsz4Y5xNBVXKTuM3KMzZjW07hxU9BnA4IHrhAwzN3b24POHmHZ5d7QyDRCOuML1SRGnObmhIAfQ7GOhcoqFNrAkO7FNCV6/TVC588ZWlSljpDHbs3ae5xHlXogkoT+eRf8QUaAHsg96iQ1aYEbvRgF36Mh7B+YpVjPgYTTWxnDf9AquH9vAhMZRRqQiGox4cdW+C9tYZU450639kZCKEiL/Hfjg8V179i/W32JIZ+B1SJDMkTVrYQfghKFUTtsR/kdI+PzP1crPaiP0HuIRmsLAjaHiumbFbIfwlkDuDbEwIDAQAB',
  },
  webExt: {
    chromiumProfile: './.wxt/chrome-profile',
  },
});
