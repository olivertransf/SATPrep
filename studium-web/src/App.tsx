import { useState, useEffect } from 'react'
import type {
  Question, VocabWord, QuestionProgress, FilterOptions,
  SavedQuiz, QuestionData, VocabData,
} from './types'
import { loadProgress, saveProgress } from './store/progress'
import { loadAllQuizzes, saveQuiz, generateQuizId, deleteQuiz } from './store/quiz'
import { getFilteredQuestions } from './utils/questions'
import HomeView from './components/HomeTab/HomeView'
import PracticeHome from './components/PracticeTab/PracticeHome'
import QuizView from './components/PracticeTab/QuizView'
import VocabFlashcards from './components/VocabTab/VocabFlashcards'
import DesmosCalculator from './components/DesmosTab/DesmosCalculator'
import StatsView from './components/StatsTab/StatsView'
import SettingsView from './components/SettingsTab/SettingsView'
import ReferenceView from './components/ReferenceTab/ReferenceView'
import { fetchJSON } from './lib/offlineFetch'
import {
  Home, BookOpen, Layers, Calculator, BarChart2, Settings, Sun, Moon, BookMarked, Menu, X,
} from 'lucide-react'

type Tab = 'home' | 'practice' | 'vocab' | 'reference' | 'desmos' | 'stats' | 'settings'

const NAV_ITEMS: { id: Tab; label: string; Icon: React.ElementType }[] = [
  { id: 'home', label: 'Home', Icon: Home },
  { id: 'practice', label: 'Practice', Icon: BookOpen },
  { id: 'vocab', label: 'Vocab', Icon: Layers },
  { id: 'reference', label: 'Reference', Icon: BookMarked },
  { id: 'desmos', label: 'Desmos', Icon: Calculator },
  { id: 'stats', label: 'Stats', Icon: BarChart2 },
]

function useDarkMode() {
  const [dark, setDark] = useState<boolean>(() => {
    const stored = localStorage.getItem('studium_theme')
    if (stored) return stored === 'dark'
    return false
  })

  useEffect(() => {
    document.documentElement.classList.toggle('light', !dark)
    localStorage.setItem('studium_theme', dark ? 'dark' : 'light')
  }, [dark])

  return { dark, toggle: () => setDark(d => !d) }
}

export default function App() {
  const [tab, setTab] = useState<Tab>('home')
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
  const [practiceModulePreset, setPracticeModulePreset] = useState<'math' | 'english' | undefined>()
  const [questions, setQuestions] = useState<Question[]>([])
  const [vocabWords, setVocabWords] = useState<VocabWord[]>([])
  const [progress, setProgress] = useState<Record<string, QuestionProgress>>(loadProgress)
  const [savedQuizzes, setSavedQuizzes] = useState<SavedQuiz[]>(loadAllQuizzes)
  const [activeQuiz, setActiveQuiz] = useState<SavedQuiz | null>(null)
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState<string | null>(null)
  const [cbVerifiedIds, setCbVerifiedIds] = useState<Set<string>>(() => new Set())
  const [htmlFontSize, setHtmlFontSize] = useState<number>(() => {
    const stored = localStorage.getItem('studium_html_font_size')
    const parsed = stored ? parseFloat(stored) : NaN
    return isNaN(parsed) ? 16 : parsed
  })
  const { dark, toggle } = useDarkMode()

  function handleFontSizeChange(size: number) {
    setHtmlFontSize(size)
    localStorage.setItem('studium_html_font_size', String(size))
  }

  function navigateTo(tabId: Tab) {
    setTab(tabId)
    setMobileMenuOpen(false)
  }

  function handleStartSection(module: 'math' | 'english') {
    setPracticeModulePreset(module)
    navigateTo('practice')
  }

  useEffect(() => {
    let cancelled = false
    void (async () => {
      setLoadError(null)
      try {
        const [qData, vData, verifiedManifest] = await Promise.all([
          fetchJSON<QuestionData>('/questions.json'),
          fetchJSON<VocabData>('/vocab.json'),
          fetchJSON<{ questionIds?: string[] }>('/cb-verified-not-on-practice-tests.json').catch(
            () => ({ questionIds: [] as string[] }),
          ),
        ])
        if (cancelled) return
        setQuestions(qData.questions)
        setVocabWords(vData.words)
        const ids = verifiedManifest.questionIds ?? []
        setCbVerifiedIds(new Set(ids.map(x => x.toLowerCase())))
      } catch {
        if (cancelled) return
        setLoadError(
          navigator.onLine
            ? 'Could not load question bank. Try refreshing.'
            : 'You are offline and the question bank is not cached yet. Open Studium once while online, then try again.',
        )
      } finally {
        if (!cancelled) setLoading(false)
      }
    })()
    return () => {
      cancelled = true
    }
  }, [])

  function handleProgressChange(p: Record<string, QuestionProgress>) {
    setProgress(p)
    saveProgress(p)
  }

  function handleStartQuiz(filters: FilterOptions) {
    const qs = getFilteredQuestions(questions, filters, progress, cbVerifiedIds)
    if (qs.length === 0) return
    const quiz: SavedQuiz = {
      id: generateQuizId(),
      questionIds: qs.map(q => q.questionId),
      currentIndex: 0,
      filters,
      answerStates: {},
      lastSaved: Date.now(),
    }
    saveQuiz(quiz)
    setSavedQuizzes(loadAllQuizzes())
    setActiveQuiz(quiz)
  }

  function handleResumeQuiz(quiz: SavedQuiz) {
    setActiveQuiz(quiz)
  }

  function handleExitQuiz() {
    setSavedQuizzes(loadAllQuizzes())
    setActiveQuiz(null)
  }

  function handleDeleteQuiz(id: string) {
    deleteQuiz(id)
    setSavedQuizzes(loadAllQuizzes())
  }

  const quizQuestions = activeQuiz
    ? (() => {
        const map = Object.fromEntries(questions.map(q => [q.questionId, q]))
        return activeQuiz.questionIds.map(id => map[id]).filter(Boolean) as Question[]
      })()
    : []

  if (loading) {
    return (
      <div
        className="h-screen flex items-center justify-center studium-screen"
        role="status"
        aria-live="polite"
        aria-label="Loading Studium"
      >
        <div className="text-center space-y-4">
          <div
            className="w-10 h-10 border-2 rounded-full mx-auto animate-spin"
            style={{ borderColor: 'var(--border)', borderTopColor: 'var(--accent)' }}
            aria-hidden="true"
          />
          <div className="text-sm font-medium" style={{ color: 'var(--muted)' }}>Loading Studium…</div>
        </div>
      </div>
    )
  }

  if (loadError && questions.length === 0) {
    return (
      <div className="h-screen flex items-center justify-center studium-screen px-6">
        <div className="text-center space-y-4 max-w-md">
          <div className="text-base font-semibold" style={{ color: 'var(--text)' }}>Cannot load Studium</div>
          <p className="text-sm" style={{ color: 'var(--muted)' }}>{loadError}</p>
          <button
            type="button"
            className="studium-btn-primary px-6"
            onClick={() => window.location.reload()}
          >
            Retry
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="h-screen flex flex-col overflow-hidden studium-screen">

      {!activeQuiz && (
        <header
          className="shrink-0 border-b z-30"
          style={{ background: 'var(--card)', borderColor: 'var(--border)' }}
        >
          <div className="max-w-6xl mx-auto px-4 sm:px-6 h-14 sm:h-16 flex items-center gap-4">
            <button
              type="button"
              onClick={() => navigateTo('home')}
              className="flex items-center gap-2.5 shrink-0 border-0 bg-transparent cursor-pointer p-0"
            >
              <div
                className="flex items-center justify-center rounded-lg font-bold text-sm"
                style={{ width: 32, height: 32, background: 'var(--accent)', color: '#fff' }}
                aria-hidden="true"
              >
                S
              </div>
              <div className="text-left hidden sm:block">
                <div className="text-base font-bold leading-tight" style={{ color: 'var(--text)' }}>Studium</div>
                <div className="text-xs leading-tight" style={{ color: 'var(--muted)' }}>SAT Prep</div>
              </div>
            </button>

            <nav className="hidden lg:flex items-center gap-1 flex-1" aria-label="Main navigation">
              {NAV_ITEMS.map(({ id, label, Icon }) => (
                <button
                  key={id}
                  type="button"
                  onClick={() => navigateTo(id)}
                  aria-current={tab === id ? 'page' : undefined}
                  className={['studium-topnav-item', tab === id ? 'studium-topnav-item--active' : ''].join(' ')}
                >
                  <Icon size={16} aria-hidden="true" />
                  <span>{label}</span>
                </button>
              ))}
            </nav>

            <div className="flex items-center gap-2 ml-auto">
              <button
                type="button"
                onClick={toggle}
                aria-label={dark ? 'Switch to light mode' : 'Switch to dark mode'}
                className="studium-btn-ghost"
              >
                {dark ? <Sun size={18} aria-hidden="true" /> : <Moon size={18} aria-hidden="true" />}
              </button>
              <button
                type="button"
                onClick={() => navigateTo('settings')}
                aria-label="Settings"
                aria-current={tab === 'settings' ? 'page' : undefined}
                className={['studium-btn-ghost', tab === 'settings' ? 'studium-btn-ghost--active' : ''].join(' ')}
              >
                <Settings size={18} aria-hidden="true" />
              </button>
              <button
                type="button"
                className="studium-btn-ghost lg:hidden"
                aria-label={mobileMenuOpen ? 'Close menu' : 'Open menu'}
                aria-expanded={mobileMenuOpen}
                onClick={() => setMobileMenuOpen(o => !o)}
              >
                {mobileMenuOpen ? <X size={20} /> : <Menu size={20} />}
              </button>
            </div>
          </div>

          {mobileMenuOpen && (
            <nav
              className="lg:hidden border-t px-4 py-3 flex flex-col gap-1"
              style={{ borderColor: 'var(--border)', background: 'var(--card)' }}
              aria-label="Mobile navigation"
            >
              {NAV_ITEMS.map(({ id, label, Icon }) => (
                <button
                  key={id}
                  type="button"
                  onClick={() => navigateTo(id)}
                  aria-current={tab === id ? 'page' : undefined}
                  className={['studium-nav-item', tab === id ? 'studium-nav-item--active' : ''].join(' ')}
                >
                  <Icon size={18} aria-hidden="true" />
                  <span>{label}</span>
                </button>
              ))}
            </nav>
          )}
        </header>
      )}

      <main className="flex-1 overflow-hidden flex flex-col min-h-0">
        <div className="tab-content flex-1 overflow-hidden flex flex-col min-h-0">
          {activeQuiz ? (
            <QuizView
              quiz={activeQuiz}
              questions={quizQuestions}
              progress={progress}
              onProgressChange={handleProgressChange}
              onExit={handleExitQuiz}
              isDark={dark}
              fontSize={htmlFontSize}
            />
          ) : tab === 'home' ? (
            <HomeView
              questions={questions}
              progress={progress}
              savedQuizzes={savedQuizzes}
              onStartSection={handleStartSection}
              onGoToPractice={() => navigateTo('practice')}
              onGoToVocab={() => navigateTo('vocab')}
              onGoToReference={() => navigateTo('reference')}
              onGoToStats={() => navigateTo('stats')}
              onResumeQuiz={handleResumeQuiz}
              onDeleteQuiz={handleDeleteQuiz}
            />
          ) : tab === 'practice' ? (
            <PracticeHome
              questions={questions}
              progress={progress}
              savedQuizzes={savedQuizzes}
              cbVerifiedNotOnPracticeTestIds={cbVerifiedIds}
              initialModule={practiceModulePreset}
              onModulePresetConsumed={() => setPracticeModulePreset(undefined)}
              onStartQuiz={handleStartQuiz}
              onResumeQuiz={handleResumeQuiz}
              onQuizzesChange={setSavedQuizzes}
            />
          ) : tab === 'vocab' ? (
            <VocabFlashcards words={vocabWords} />
          ) : tab === 'reference' ? (
            <ReferenceView />
          ) : tab === 'desmos' ? (
            <DesmosCalculator />
          ) : tab === 'stats' ? (
            <StatsView questions={questions} progress={progress} />
          ) : (
            <SettingsView
              onQuizzesChange={setSavedQuizzes}
              progress={progress}
              onProgressChange={handleProgressChange}
              onToggleTheme={toggle}
              isDark={dark}
              fontSize={htmlFontSize}
              onFontSizeChange={handleFontSizeChange}
            />
          )}
        </div>
      </main>

      {!activeQuiz && (
        <nav
          className="lg:hidden flex shrink-0 border-t"
          style={{ background: 'var(--card)', borderColor: 'var(--border)' }}
          aria-label="Tabs"
        >
          {NAV_ITEMS.slice(0, 5).map(({ id, label, Icon }) => (
            <button
              key={id}
              type="button"
              onClick={() => navigateTo(id)}
              aria-current={tab === id ? 'page' : undefined}
              aria-label={label}
              className="flex-1 flex flex-col items-center gap-0.5 py-2 min-h-[52px] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-[var(--accent)]"
              style={tab === id ? { color: 'var(--accent)' } : { color: 'var(--muted)' }}
            >
              <Icon size={22} aria-hidden="true" />
              <span className="text-[11px] font-medium mobile-tab-label">{label}</span>
            </button>
          ))}
        </nav>
      )}
    </div>
  )
}
