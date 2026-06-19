import { createContext, useContext, type ReactNode } from 'react'
import type {
  Question, VocabWord, QuestionProgress, FilterOptions, SavedQuiz,
} from '../types'

export interface AppDataContextValue {
  questions: Question[]
  vocabWords: VocabWord[]
  progress: Record<string, QuestionProgress>
  savedQuizzes: SavedQuiz[]
  cbVerifiedIds: Set<string>
  htmlFontSize: number
  passageFontSize: number
  answerChoiceFontSize: number
  dark: boolean
  practiceModulePreset: 'math' | 'english' | undefined
  setPracticeModulePreset: (m: 'math' | 'english' | undefined) => void
  handleProgressChange: (p: Record<string, QuestionProgress>) => void
  handleStartQuiz: (filters: FilterOptions) => string | null
  handleDeleteQuiz: (id: string) => void
  setSavedQuizzes: (quizzes: SavedQuiz[]) => void
  toggleTheme: () => void
  handleFontSizeChange: (size: number) => void
  handlePassageFontSizeChange: (size: number) => void
  handleAnswerChoiceFontSizeChange: (size: number) => void
}

const AppDataContext = createContext<AppDataContextValue | null>(null)

export function AppDataProvider({ value, children }: { value: AppDataContextValue; children: ReactNode }) {
  return <AppDataContext.Provider value={value}>{children}</AppDataContext.Provider>
}

export function useAppData() {
  const ctx = useContext(AppDataContext)
  if (!ctx) throw new Error('useAppData must be used within AppDataProvider')
  return ctx
}
