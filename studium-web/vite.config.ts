import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import { VitePWA } from 'vite-plugin-pwa'

export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.svg', 'icons.svg', '*.png', '*.ico'],
      manifest: {
        name: 'Studium – SAT Prep',
        short_name: 'Studium',
        description: 'SAT practice questions, vocab flashcards, and math reference',
        theme_color: '#007aff',
        background_color: '#f8fafc',
        display: 'standalone',
        orientation: 'any',
        scope: '/',
        start_url: '/',
        icons: [
          { src: '/favicon.svg', sizes: 'any', type: 'image/svg+xml', purpose: 'any maskable' },
        ],
      },
      workbox: {
        // App shell + fonts; JSON is runtime-cached on first visit (questions.json is ~20MB).
        globPatterns: ['**/*.{js,css,html,svg,png,ico,woff,woff2,json}'],
        globIgnores: ['**/questions.json'],
        additionalManifestEntries: [
          { url: '/vocab.json', revision: null },
          { url: '/cb-verified-not-on-practice-tests.json', revision: null },
        ],
        navigateFallback: 'index.html',
        runtimeCaching: [
          {
            urlPattern: /\/questions\.json$/,
            handler: 'CacheFirst',
            options: {
              cacheName: 'studium-questions',
              expiration: { maxEntries: 2, maxAgeSeconds: 60 * 60 * 24 * 90 },
              cacheableResponse: { statuses: [0, 200] },
            },
          },
          {
            urlPattern: /\/(vocab|cb-verified-not-on-practice-tests)\.json$/,
            handler: 'CacheFirst',
            options: {
              cacheName: 'studium-data',
              expiration: { maxEntries: 10, maxAgeSeconds: 60 * 60 * 24 * 30 },
              cacheableResponse: { statuses: [0, 200] },
            },
          },
          {
            // Cache Desmos from CDN so it works offline
            urlPattern: /^https:\/\/www\.desmos\.com\/.*/i,
            handler: 'CacheFirst',
            options: {
              cacheName: 'desmos-cdn',
              expiration: { maxEntries: 20, maxAgeSeconds: 60 * 60 * 24 * 7 },
            },
          },
          {
            // Cache MathJax 3 from jsdelivr CDN for offline math rendering
            urlPattern: /^https:\/\/cdn\.jsdelivr\.net\/npm\/mathjax@3\/.*/i,
            handler: 'CacheFirst',
            options: {
              cacheName: 'mathjax-cdn',
              expiration: { maxEntries: 30, maxAgeSeconds: 60 * 60 * 24 * 30 },
            },
          },
        ],
      },
    }),
  ],
})
