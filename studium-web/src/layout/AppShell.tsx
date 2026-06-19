import { useMemo } from 'react'
import { Navigate, Outlet, useLocation, useNavigate } from 'react-router-dom'
import {
  Home, BookOpen, GraduationCap, TrendingUp, MoreHorizontal,
  Calculator, BookMarked, Layers, Sun, Moon, Settings,
} from 'lucide-react'
import AccountMenu from '../components/Auth/AccountMenu'
import { useAppData } from '../context/AppDataContext'
import { SegmentedControl } from '../components/ui/SegmentedControl'

const DESKTOP_NAV = [
  { path: '/', label: 'Home', Icon: Home },
  { path: '/practice', label: 'Practice', Icon: BookOpen },
  { path: '/vocab', label: 'Vocab', Icon: Layers },
  { path: '/reference', label: 'Reference', Icon: BookMarked },
  { path: '/desmos', label: 'Desmos', Icon: Calculator },
  { path: '/stats', label: 'Progress', Icon: TrendingUp },
] as const

const MOBILE_NAV = [
  { path: '/', label: 'Home', Icon: Home },
  { path: '/practice', label: 'Practice', Icon: BookOpen },
  { path: '/study', label: 'Study', Icon: GraduationCap, matchPrefix: '/study' },
  { path: '/stats', label: 'Progress', Icon: TrendingUp },
  { path: '/more', label: 'More', Icon: MoreHorizontal },
] as const

const STUDY_TABS = [
  { value: '/vocab' as const, label: 'Vocab' },
  { value: '/reference' as const, label: 'Reference' },
  { value: '/desmos' as const, label: 'Desmos' },
] as const

function isActivePath(pathname: string, path: string, matchPrefix?: string) {
  if (matchPrefix) {
    return pathname === matchPrefix || pathname.startsWith('/vocab') || pathname.startsWith('/reference') || pathname.startsWith('/desmos')
  }
  if (path === '/') return pathname === '/'
  return pathname === path || pathname.startsWith(`${path}/`)
}

export function AppShell() {
  const location = useLocation()
  const navigate = useNavigate()
  const { dark, toggleTheme } = useAppData()

  const isQuiz = location.pathname.startsWith('/practice/quiz/')
  const showStudySubNav = ['/vocab', '/reference', '/desmos'].includes(location.pathname)

  const studyTabValue = useMemo(() => {
    if (location.pathname.startsWith('/reference')) return '/reference'
    if (location.pathname.startsWith('/desmos')) return '/desmos'
    return '/vocab'
  }, [location.pathname])

  if (isQuiz) {
    return (
      <div className="studium-quiz-root">
        <Outlet />
      </div>
    )
  }

  return (
    <div className="h-screen flex flex-col overflow-hidden studium-screen">
      <header className="shrink-0 border-b z-30 bg-[var(--card)] border-[var(--border)]">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 h-14 sm:h-16 flex items-center gap-4">
          <button
            type="button"
            onClick={() => navigate('/')}
            className="flex items-center gap-2.5 shrink-0 border-0 bg-transparent cursor-pointer p-0"
          >
            <div
              className="flex items-center justify-center rounded-lg font-bold text-sm w-8 h-8 bg-[var(--accent)] text-[var(--on-accent)]"
              aria-hidden="true"
            >
              S
            </div>
            <div className="text-left hidden sm:block">
              <div className="text-base font-bold leading-tight text-[var(--text)]">Studium</div>
              <div className="text-xs leading-tight text-[var(--muted)]">SAT Prep</div>
            </div>
          </button>

          <nav className="hidden lg:flex items-center gap-1 flex-1" aria-label="Main navigation">
            {DESKTOP_NAV.map(({ path, label, Icon }) => (
              <button
                key={path}
                type="button"
                onClick={() => navigate(path)}
                aria-current={isActivePath(location.pathname, path) ? 'page' : undefined}
                className={[
                  'studium-topnav-item',
                  isActivePath(location.pathname, path) ? 'studium-topnav-item--active' : '',
                ].join(' ')}
              >
                <Icon size={16} aria-hidden="true" />
                <span>{label}</span>
              </button>
            ))}
          </nav>

          <div className="flex items-center gap-2 ml-auto">
            <AccountMenu compact />
            <button
              type="button"
              onClick={toggleTheme}
              aria-label={dark ? 'Switch to light mode' : 'Switch to dark mode'}
              className="studium-btn-ghost hidden lg:inline-flex"
            >
              {dark ? <Sun size={18} aria-hidden="true" /> : <Moon size={18} aria-hidden="true" />}
            </button>
            <button
              type="button"
              onClick={() => navigate('/settings')}
              aria-label="Settings"
              aria-current={location.pathname === '/settings' ? 'page' : undefined}
              className={[
                'studium-btn-ghost hidden lg:inline-flex',
                location.pathname === '/settings' ? 'studium-btn-ghost--active' : '',
              ].join(' ')}
            >
              <Settings size={18} aria-hidden="true" />
            </button>
          </div>
        </div>

        {showStudySubNav && (
          <div className="lg:hidden border-t border-[var(--border)] px-4 py-2">
            <SegmentedControl
              ariaLabel="Study tools"
              options={[...STUDY_TABS]}
              value={studyTabValue}
              onChange={path => navigate(path)}
            />
          </div>
        )}
      </header>

      <main className="flex-1 overflow-hidden flex flex-col min-h-0">
        <div className="tab-content flex-1 overflow-hidden flex flex-col min-h-0">
          <Outlet />
        </div>
      </main>

      <nav
        className="lg:hidden flex shrink-0 border-t studium-bottom-nav bg-[var(--card)] border-[var(--border)]"
        aria-label="Tabs"
      >
        {MOBILE_NAV.map(({ path, label, Icon, ...rest }) => {
          const matchPrefix = 'matchPrefix' in rest ? rest.matchPrefix : undefined
          const active = isActivePath(location.pathname, path, matchPrefix)
          return (
            <button
              key={path}
              type="button"
              onClick={() => navigate(path === '/study' ? '/vocab' : path)}
              aria-current={active ? 'page' : undefined}
              className={[
                'flex-1 flex flex-col items-center gap-0.5 py-2 min-h-[52px] transition-colors',
                'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-[var(--accent)]',
                active ? 'text-[var(--accent)]' : 'text-[var(--muted)]',
              ].join(' ')}
            >
              <Icon size={22} aria-hidden="true" />
              <span className="text-[11px] font-medium mobile-tab-label">{label}</span>
            </button>
          )
        })}
      </nav>
    </div>
  )
}

export function StudyHubRedirect() {
  return <Navigate to="/vocab" replace />
}
