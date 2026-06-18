import { useNavigate } from 'react-router-dom'
import { Sun, Moon, Settings, TrendingUp, ChevronRight } from 'lucide-react'
import { PageHeader } from '../ui/PageHeader'
import { Button } from '../ui/Button'
import AccountMenu from '../Auth/AccountMenu'
import { useAppData } from '../../context/AppDataContext'
import { useAuth } from '../../context/AuthContext'
import { useSync } from '../../context/SyncContext'

export default function MoreView() {
  const navigate = useNavigate()
  const { dark, toggleTheme } = useAppData()
  const { user, configured } = useAuth()
  const { status, lastSyncedAt } = useSync()

  function syncStatusLabel() {
    if (status === 'syncing') return 'Syncing…'
    if (status === 'offline') return 'Offline — changes save locally'
    if (status === 'error') return 'Sync error'
    if (lastSyncedAt) return `Synced ${new Date(lastSyncedAt).toLocaleTimeString()}`
    return user ? 'Synced' : 'Sign in to sync'
  }

  return (
    <div className="flex-1 overflow-y-auto studium-screen">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 py-8 space-y-4">
        <PageHeader title="More" subtitle="Account, settings, and shortcuts" />

        {configured && (
          <section className="studium-card overflow-hidden p-0">
            <div className="px-4 py-3 border-b border-[var(--border)]">
              <div className="font-semibold text-[var(--text)]">Account</div>
              <div className="text-xs mt-0.5 text-[var(--muted)]">{syncStatusLabel()}</div>
            </div>
            <div className="px-4 py-3">
              <AccountMenu />
            </div>
          </section>
        )}

        <section className="studium-card overflow-hidden p-0 divide-y divide-[var(--border)]">
          <button
            type="button"
            onClick={() => navigate('/stats')}
            className="w-full flex items-center gap-3 px-4 py-3 min-h-[52px] text-left border-0 bg-transparent cursor-pointer hover:bg-[var(--fill-tertiary)]"
          >
            <TrendingUp size={20} className="text-[var(--accent)] shrink-0" aria-hidden="true" />
            <div className="flex-1 min-w-0">
              <div className="text-sm font-semibold text-[var(--text)]">Progress</div>
              <div className="text-xs text-[var(--muted)]">Accuracy and breakdowns</div>
            </div>
            <ChevronRight size={16} className="text-[var(--muted)] shrink-0" aria-hidden="true" />
          </button>

          <button
            type="button"
            onClick={() => navigate('/settings')}
            className="w-full flex items-center gap-3 px-4 py-3 min-h-[52px] text-left border-0 bg-transparent cursor-pointer hover:bg-[var(--fill-tertiary)]"
          >
            <Settings size={20} className="text-[var(--accent)] shrink-0" aria-hidden="true" />
            <div className="flex-1 min-w-0">
              <div className="text-sm font-semibold text-[var(--text)]">Settings</div>
              <div className="text-xs text-[var(--muted)]">Appearance, font size, data</div>
            </div>
            <ChevronRight size={16} className="text-[var(--muted)] shrink-0" aria-hidden="true" />
          </button>

          <div className="flex items-center justify-between px-4 py-3 min-h-[52px]">
            <div className="flex items-center gap-3">
              {dark ? <Moon size={20} className="text-[var(--accent)]" aria-hidden="true" /> : <Sun size={20} className="text-[var(--accent)]" aria-hidden="true" />}
              <div>
                <div className="text-sm font-semibold text-[var(--text)]">Theme</div>
                <div className="text-xs text-[var(--muted)]">{dark ? 'Dark mode' : 'Light mode'}</div>
              </div>
            </div>
            <Button variant="secondary" onClick={toggleTheme}>
              {dark ? 'Light' : 'Dark'}
            </Button>
          </div>
        </section>
      </div>
    </div>
  )
}
