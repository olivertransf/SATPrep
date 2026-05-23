# Studium Supabase sync

Uses your existing Supabase project (same as other apps). Studium only touches the `studium_sync` table.

## 1. Run migration

In [Supabase Dashboard](https://supabase.com/dashboard) → SQL → New query, paste and run:

`migrations/001_studium_sync.sql`

## 2. Web env (`studium-web/.env.local`)

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=your_publishable_or_anon_key
```

Pick **one** auth style:

**A — Email + password (recommended)**  
Create a user in Authentication → Users (email + password). Then:

```env
VITE_SYNC_EMAIL=you@example.com
```

In the app Settings → Cloud sync, enter that password once. Session persists in the browser.

**B — Gate password only (solo)**  
No Supabase user. Data lives in row `id = 'default'`. Anyone with your anon key could touch that row if they guess it; keep the site private.

```env
VITE_SYNC_GATE_PASSWORD=your-long-secret
```

Restart `npm run dev` after changing env.

## 3. Native app (`Studium/StudiumSync.plist`)

Copy `Studium/StudiumSync.plist.example` → `Studium/StudiumSync.plist` (gitignored). Use the same URL/key and either `SYNC_EMAIL` or `SYNC_GATE_PASSWORD` as the web app.

In **Settings → Cloud sync**, enter your sync password once. The app **pulls on launch and when returning to the foreground**, and **pushes ~2.5s after** you answer questions, save quizzes, or move vocab cards.

## Sync behavior

| Action | Web | Native |
|--------|-----|--------|
| After local change | Debounced push (~2.5s) | Debounced push (~2.5s) |
| Tab focus / refresh | Pull on `visibilitychange` + `focus` | Pull when app becomes active |
| Leave tab | Flush push on `pagehide` | — |

Vocab on the wire uses `learn` / `review` / `known` (web UI shows **Mastered** for `known`).

## Note on Next.js snippets

Studium web is **Vite + React**, not Next.js. Use `@supabase/supabase-js` only (no `@supabase/ssr` unless you add a Next app).
