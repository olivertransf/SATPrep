import { useParams, useNavigate } from 'react-router-dom'
import { loadAllQuizzes } from '../store/quiz'
import QuizView from '../components/PracticeTab/QuizView'
import { Button } from '../components/ui/Button'
import { useAppData } from '../context/AppDataContext'
import type { Question } from '../types'

export default function QuizRoute() {
  const { quizId } = useParams<{ quizId: string }>()
  const navigate = useNavigate()
  const { questions, progress, handleProgressChange, dark, htmlFontSize, handleFontSizeChange, answerChoiceFontSize, handleAnswerChoiceFontSizeChange } = useAppData()

  const quiz = loadAllQuizzes().find(q => q.id === quizId)

  if (!quiz) {
    return (
      <div className="flex flex-col items-center justify-center flex-1 p-8 text-center studium-screen">
        <div className="text-xl font-semibold mb-2 text-[var(--text)]">Quiz not found</div>
        <p className="text-sm text-[var(--muted)] mb-4">This quiz may have been deleted or the link is invalid.</p>
        <Button onClick={() => navigate('/practice')}>
          Back to Practice
        </Button>
      </div>
    )
  }

  const map = Object.fromEntries(questions.map(q => [q.questionId, q]))
  const quizQuestions = quiz.questionIds.map(id => map[id]).filter(Boolean) as Question[]

  return (
    <QuizView
      quiz={quiz}
      questions={quizQuestions}
      progress={progress}
      onProgressChange={handleProgressChange}
      onExit={() => navigate('/practice')}
      isDark={dark}
      fontSize={htmlFontSize}
      onFontSizeChange={handleFontSizeChange}
      answerChoiceFontSize={answerChoiceFontSize}
      onAnswerChoiceFontSizeChange={handleAnswerChoiceFontSizeChange}
    />
  )
}
