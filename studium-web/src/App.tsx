import { useState, useEffect, useMemo, useCallback } from 'react'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import type {
  Question, VocabWord, QuestionProgress, FilterOptions,
  SavedQuiz, QuestionData, VocabData,
} from './types'
import { loadProgress, saveProgress } from './store/progress'
import { loadAllQuizzes, saveQuiz, generateQuizId, deleteQuiz } from './store/quiz'
import { getFilteredQuestions } from './utils/questions'
import HomeView from './components/HomeTab/HomeView'
import PracticeHome from './components/PracticeTab/PracticeHome'
import VocabFlashcards from './components/VocabTab/VocabFlashcards'
import DesmosCalculator from './components/DesmosTab/DesmosCalculator'
import StatsView from './components/StatsTab/StatsView'
import SettingsView from './components/SettingsTab/SettingsView'
import ReferenceView from './components/ReferenceTab/ReferenceView'
import MoreView from './components/MoreTab/MoreView'
import { fetchJSON } from './lib/offlineFetch'
import { AppDataProvider, useAppData } from './context/AppDataContext'
import { AppShell, StudyHubRedirect } from './layout/AppShell'
import QuizRoute from './routes/QuizRoute'
import { Button } from './components/ui/Button'

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

function AppRoutes() {
  const {
    questions, vocabWords, progress, savedQuizzes, cbVerifiedIds,
    practiceModulePreset, setPracticeModulePreset,
    handleProgressChange, handleStartQuiz, handleDeleteQuiz, setSavedQuizzes,
    dark, toggleTheme, htmlFontSize, handleFontSizeChange, answerChoiceFontSize, handleAnswerChoiceFontSizeChange,
  } = useAppData()

  return (
    <Routes>
      <Route path="/practice/quiz/:quizId" element={<QuizRoute />} />
      <Route element={<AppShell />}>
        <Route index element={
          <HomeView
            questions={questions}
            progress={progress}
            savedQuizzes={savedQuizzes}
            onDeleteQuiz={handleDeleteQuiz}
          />
        } />
        <Route path="practice" element={
          <PracticeHome
            questions={questions}
            progress={progress}
            cbVerifiedNotOnPracticeTestIds={cbVerifiedIds}
            initialModule={practiceModulePreset}
            onModulePresetConsumed={() => setPracticeModulePreset(undefined)}
            onStartQuiz={handleStartQuiz}
          />
        } />
        <Route path="study" element={<StudyHubRedirect />} />
        <Route path="vocab" element={<VocabFlashcards words={vocabWords} />} />
        <Route path="reference" element={<ReferenceView />} />
        <Route path="desmos" element={<DesmosCalculator />} />
        <Route path="stats" element={<StatsView questions={questions} progress={progress} />} />
        <Route path="more" element={<MoreView />} />
        <Route path="settings" element={
          <SettingsView
            onQuizzesChange={setSavedQuizzes}
            progress={progress}
            onProgressChange={handleProgressChange}
            onToggleTheme={toggleTheme}
            isDark={dark}
            fontSize={htmlFontSize}
            onFontSizeChange={handleFontSizeChange}
            answerChoiceFontSize={answerChoiceFontSize}
            onAnswerChoiceFontSizeChange={handleAnswerChoiceFontSizeChange}
          />
        } />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  )
}

export default function App() {
  const [practiceModulePreset, setPracticeModulePreset] = useState<'math' | 'english' | undefined>()
  const [questions, setQuestions] = useState<Question[]>([])
  const [vocabWords, setVocabWords] = useState<VocabWord[]>([])
  const [progress, setProgress] = useState<Record<string, QuestionProgress>>(loadProgress)
  const [savedQuizzes, setSavedQuizzes] = useState<SavedQuiz[]>(loadAllQuizzes)
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState<string | null>(null)
  const [cbVerifiedIds, setCbVerifiedIds] = useState<Set<string>>(() => new Set())
  const [htmlFontSize, setHtmlFontSize] = useState<number>(() => {
    const stored = localStorage.getItem('studium_html_font_size')
    const parsed = stored ? parseFloat(stored) : NaN
    return isNaN(parsed) ? 16 : parsed
  })
  const [answerChoiceFontSize, setAnswerChoiceFontSize] = useState<number>(() => {
    const stored = localStorage.getItem('studium_answer_choice_font_size')
    const parsed = stored ? parseFloat(stored) : NaN
    return isNaN(parsed) ? 15 : parsed
  })
  const { dark, toggle } = useDarkMode()

  const handleFontSizeChange = useCallback((size: number) => {
    setHtmlFontSize(size)
    localStorage.setItem('studium_html_font_size', String(size))
  }, [])

  const handleAnswerChoiceFontSizeChange = useCallback((size: number) => {
    setAnswerChoiceFontSize(size)
    localStorage.setItem('studium_answer_choice_font_size', String(size))
  }, [])

  useEffect(() => {
    function onSyncApplied() {
      setProgress(loadProgress())
      setSavedQuizzes(loadAllQuizzes())
    }
    window.addEventListener('studium-sync-applied', onSyncApplied)
    return () => window.removeEventListener('studium-sync-applied', onSyncApplied)
  }, [])

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

  const handleProgressChange = useCallback((p: Record<string, QuestionProgress>) => {
    setProgress(p)
    saveProgress(p)
  }, [])

  const handleStartQuiz = useCallback((filters: FilterOptions): string | null => {
    const qs = getFilteredQuestions(questions, filters, progress, cbVerifiedIds)
    if (qs.length === 0) return null
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
    return quiz.id
  }, [questions, progress, cbVerifiedIds])

  const handleDeleteQuiz = useCallback((id: string) => {
    deleteQuiz(id)
    setSavedQuizzes(loadAllQuizzes())
  }, [])

  const appData = useMemo(() => ({
    questions,
    vocabWords,
    progress,
    savedQuizzes,
    cbVerifiedIds,
    htmlFontSize,
    answerChoiceFontSize,
    dark,
    practiceModulePreset,
    setPracticeModulePreset,
    handleProgressChange,
    handleStartQuiz,
    handleDeleteQuiz,
    setSavedQuizzes,
    toggleTheme: toggle,
    handleFontSizeChange,
    handleAnswerChoiceFontSizeChange,
  }), [
    questions, vocabWords, progress, savedQuizzes, cbVerifiedIds, htmlFontSize, answerChoiceFontSize, dark,
    practiceModulePreset, handleProgressChange, handleStartQuiz, handleDeleteQuiz, toggle, handleFontSizeChange,
    handleAnswerChoiceFontSizeChange,
  ])

  if (loading) {
    return (
      <div className="h-screen flex items-center justify-center studium-screen" role="status" aria-live="polite" aria-label="Loading Studium">
        <div className="text-center space-y-4">
          <div className="w-10 h-10 border-2 rounded-full mx-auto animate-spin border-[var(--border)] border-t-[var(--accent)]" aria-hidden="true" />
          <div className="text-sm font-medium text-[var(--muted)]">Loading Studium…</div>
        </div>
      </div>
    )
  }

  if (loadError && questions.length === 0) {
    return (
      <div className="h-screen flex items-center justify-center studium-screen px-6">
        <div className="text-center space-y-4 max-w-md">
          <div className="text-base font-semibold text-[var(--text)]">Cannot load Studium</div>
          <p className="text-sm text-[var(--muted)]">{loadError}</p>
          <Button onClick={() => window.location.reload()}>Retry</Button>
        </div>
      </div>
    )
  }

  return (
    <AppDataProvider value={appData}>
      <BrowserRouter>
        <AppRoutes />
      </BrowserRouter>
    </AppDataProvider>
  )
}
