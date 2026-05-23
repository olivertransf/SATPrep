import { useState, useEffect, useCallback } from 'react'
import type {
  Question, VocabWord, QuestionProgress, FilterOptions,
  SavedQuiz, QuestionData, VocabData,
} from './types'
import { loadProgress, saveProgress } from './store/progress'
import { loadAllQuizzes, saveQuiz, generateQuizId } from './store/quiz'
import { getFilteredQuestions } from './utils/questions'
import PracticeHome from './components/PracticeTab/PracticeHome'
import QuizView from './components/PracticeTab/QuizView'
import VocabFlashcards from './components/VocabTab/VocabFlashcards'
import DesmosCalculator from './components/DesmosTab/DesmosCalculator'
import StatsView from './components/StatsTab/StatsView'
import SettingsView from './components/SettingsTab/SettingsView'
import ReferenceView from './components/ReferenceTab/ReferenceView'
import { useCloudSync } from './hooks/useCloudSync'
import { fetchJSON } from './lib/offlineFetch'
import {
  BookOpen, Layers, Calculator, BarChart2, Settings, Sun, Moon, BookMarked,
} from 'lucide-react'

type Tab = 'practice' | 'vocab' | 'reference' | 'desmos' | 'stats' | 'settings'

const TABS: { id: Tab; label: string; Icon: React.ElementType }[] = [
  { id: 'practice', label: 'Practice', Icon: BookOpen },
  { id: 'vocab', label: 'Vocab', Icon: Layers },
  { id: 'reference', label: 'Reference', Icon: BookMarked },
  { id: 'desmos', label: 'Desmos', Icon: Calculator },
  { id: 'stats', label: 'Stats', Icon: BarChart2 },
  { id: 'settings', label: 'Settings', Icon: Settings },
]

function useDarkMode() {
  const [dark, setDark] = useState<boolean>(() => {
    const stored = localStorage.getItem('studium_theme')
    if (stored) return stored === 'dark'
    return true
  })

  useEffect(() => {
    document.documentElement.classList.toggle('light', !dark)
    localStorage.setItem('studium_theme', dark ? 'dark' : 'light')
  }, [dark])

  return { dark, toggle: () => setDark(d => !d) }
}

export default function App() {
  const [tab, setTab] = useState<Tab>('practice')
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

  const onCloudMerged = useCallback((data: { progress: Record<string, QuestionProgress>; savedQuizzes: SavedQuiz[] }) => {
    setProgress(data.progress)
    setSavedQuizzes(data.savedQuizzes)
  }, [])

  const cloudSync = useCloudSync({
    enabled: !loading,
    onMerged: onCloudMerged,
  })

  function handleFontSizeChange(size: number) {
    setHtmlFontSize(size)
    localStorage.setItem('studium_html_font_size', String(size))
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
    cloudSync.notifyLocalChange()
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
    cloudSync.notifyLocalChange()
    setActiveQuiz(quiz)
  }

  function handleResumeQuiz(quiz: SavedQuiz) {
    setActiveQuiz(quiz)
  }

  function handleExitQuiz() {
    setSavedQuizzes(loadAllQuizzes())
    cloudSync.notifyLocalChange()
    setActiveQuiz(null)
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
            className="studium-chip studium-chip--selected px-4 py-2 text-sm font-semibold"
            onClick={() => window.location.reload()}
          >
            Retry
          </button>
        </div>
      </div>
    )
  }

  const currentTabLabel = TABS.find(t => t.id === tab)?.label ?? ''

  return (
    <div className="h-screen flex overflow-hidden studium-screen">

      {!activeQuiz && (
        <aside
          className="hidden md:flex flex-col w-[240px] shrink-0 border-r h-full"
          style={{ background: 'var(--card)', borderColor: 'var(--border)' }}
          aria-label="Main navigation"
        >
          <div className="px-5 py-5 border-b" style={{ borderColor: 'var(--border)' }}>
            <div className="text-lg font-bold tracking-tight" style={{ color: 'var(--text)' }}>Studium</div>
            <div className="text-sm mt-0.5" style={{ color: 'var(--muted)' }}>SAT Prep</div>
          </div>

          <nav className="flex-1 py-3 px-3 space-y-1" aria-label="Tabs">
            {TABS.map(({ id, label, Icon }) => (
              <button
                key={id}
                type="button"
                onClick={() => setTab(id)}
                aria-current={tab === id ? 'page' : undefined}
                className={['studium-nav-item', tab === id ? 'studium-nav-item--active' : ''].join(' ')}
              >
                <Icon size={18} aria-hidden="true" />
                <span>{label}</span>
              </button>
            ))}
          </nav>

          <div className="px-3 py-4 border-t" style={{ borderColor: 'var(--border)' }}>
            <button
              type="button"
              onClick={toggle}
              aria-label={dark ? 'Switch to light mode' : 'Switch to dark mode'}
              className="studium-btn-secondary w-full"
            >
              {dark ? <Sun size={16} aria-hidden="true" /> : <Moon size={16} aria-hidden="true" />}
              <span>{dark ? 'Light mode' : 'Dark mode'}</span>
            </button>
          </div>
        </aside>
      )}

      <div className="flex-1 flex flex-col min-w-0 h-full overflow-hidden studium-screen">

        {!activeQuiz && (
          <header
            className="md:hidden flex items-center justify-between px-4 py-3 border-b shrink-0"
            style={{ background: 'var(--card)', borderColor: 'var(--border)' }}
          >
            <h1 className="text-lg font-semibold m-0" style={{ color: 'var(--text)' }}>{currentTabLabel}</h1>
            <button
              type="button"
              onClick={toggle}
              aria-label={dark ? 'Switch to light mode' : 'Switch to dark mode'}
              className="studium-btn-secondary px-3 min-h-[36px]"
            >
              {dark ? <Sun size={18} aria-hidden="true" /> : <Moon size={18} aria-hidden="true" />}
            </button>
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
            ) : tab === 'practice' ? (
              <PracticeHome
                questions={questions}
                progress={progress}
                savedQuizzes={savedQuizzes}
                cbVerifiedNotOnPracticeTestIds={cbVerifiedIds}
                onStartQuiz={handleStartQuiz}
                onResumeQuiz={handleResumeQuiz}
                onQuizzesChange={quizzes => {
                  setSavedQuizzes(quizzes)
                  cloudSync.notifyLocalChange()
                }}
              />
            ) : tab === 'vocab' ? (
              <VocabFlashcards words={vocabWords} onLocalChange={cloudSync.notifyLocalChange} />
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
                cloudSync={cloudSync}
              />
            )}
          </div>
        </main>

        {!activeQuiz && (
          <nav
            className="md:hidden flex shrink-0 border-t"
            style={{ background: 'var(--card)', borderColor: 'var(--border)' }}
            aria-label="Tabs"
          >
            {TABS.map(({ id, label, Icon }) => (
              <button
                key={id}
                type="button"
                onClick={() => setTab(id)}
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
    </div>
  )
}
