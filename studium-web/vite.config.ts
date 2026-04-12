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
        theme_color: '#6366f1',
        background_color: '#0f0f11',
        display: 'standalone',
        orientation: 'any',
        scope: '/',
        start_url: '/',
        icons: [
          { src: '/favicon.svg', sizes: 'any', type: 'image/svg+xml', purpose: 'any maskable' },
        ],
      },
      workbox: {
        // Pre-cache everything: JS/CSS bundles + all public JSON data
        globPatterns: ['**/*.{js,css,html,svg,png,ico,woff,woff2}'],
        additionalManifestEntries: [
          { url: '/questions.json', revision: null },
          { url: '/vocab.json', revision: null },
          { url: '/cb-verified-not-on-practice-tests.json', revision: null },
        ],
        runtimeCaching: [
          {
            // Cache the JSON data files at runtime too (first-visit + updates)
            urlPattern: /\/(questions|vocab|cb-verified-not-on-practice-tests)\.json$/,
            handler: 'CacheFirst',
            options: {
              cacheName: 'studium-data',
              expiration: { maxEntries: 10, maxAgeSeconds: 60 * 60 * 24 * 30 },
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
