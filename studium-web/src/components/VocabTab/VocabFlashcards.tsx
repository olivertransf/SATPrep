import { useState, useEffect, useMemo } from 'react'
import type { VocabWord } from '../../types'
import {
  ChevronLeft, ChevronRight, RotateCcw, BookOpen, CheckCircle2, Clock, GraduationCap, Shuffle,
} from 'lucide-react'
import { PageHeader } from '../ui/PageHeader'
import { Button } from '../ui/Button'
import { loadWordBucketsForUI, saveWordBucketsFromUI, type WebVocabBucket } from '../../store/vocabBuckets'

interface VocabFlashcardsProps {
  words: VocabWord[]
}

type PosFilter = 'all' | 'noun' | 'verb' | 'adj' | 'adverb' | 'other'
type BucketFilter = WebVocabBucket

const POS_KEY = 'studium_vocab_pos_filter'
const BUCKET_FILTER_KEY = 'studium_vocab_bucket_filter'
const SHUFFLE_MODE_KEY = 'studium_vocab_shuffle_mode'

const POS_OPTIONS: { value: PosFilter; label: string }[] = [
  { value: 'all', label: 'All words' },
  { value: 'noun', label: 'Nouns' },
  { value: 'verb', label: 'Verbs' },
  { value: 'adj', label: 'Adjectives' },
  { value: 'adverb', label: 'Adverbs' },
  { value: 'other', label: 'Other' },
]

const BUCKET_OPTIONS: {
  value: BucketFilter
  label: string
  description: string
  accent: string
  bg: string
  Icon: React.ElementType
}[] = [
  {
    value: 'learn',
    label: 'Learning',
    description: 'Words you are studying',
    accent: 'var(--accent)',
    bg: 'var(--accent-chip-fill)',
    Icon: BookOpen,
  },
  {
    value: 'review',
    label: 'Review',
    description: 'Words to revisit',
    accent: 'var(--warning)',
    bg: 'rgba(234, 88, 12, 0.1)',
    Icon: Clock,
  },
  {
    value: 'mastered',
    label: 'Mastered',
    description: 'Words you know well',
    accent: 'var(--success)',
    bg: 'rgba(22, 163, 74, 0.1)',
    Icon: GraduationCap,
  },
]

function shuffleIds(ids: string[]): string[] {
  const next = [...ids]
  for (let i = next.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[next[i], next[j]] = [next[j], next[i]]
  }
  return next
}

function orderDeckIds(ids: string[], shuffleMode: boolean): string[] {
  return shuffleMode ? shuffleIds(ids) : ids
}

export default function VocabFlashcards({ words }: VocabFlashcardsProps) {
  const [buckets, setBuckets] = useState<Record<string, BucketFilter>>(loadWordBucketsForUI)
  const [posFilter, setPosFilter] = useState<PosFilter>(() => {
    return (localStorage.getItem(POS_KEY) as PosFilter) ?? 'all'
  })
  const [bucketFilter, setBucketFilter] = useState<BucketFilter>(() => {
    return (localStorage.getItem(BUCKET_FILTER_KEY) as BucketFilter) ?? 'learn'
  })
  const [shuffleMode, setShuffleMode] = useState<boolean>(() => {
    return localStorage.getItem(SHUFFLE_MODE_KEY) === 'true'
  })
  const [index, setIndex] = useState(0)
  const [flipped, setFlipped] = useState(false)
  const [deckOrder, setDeckOrder] = useState<string[]>([])

  const bucketCounts = useMemo(() => {
    const counts: Record<BucketFilter, number> = { learn: 0, review: 0, mastered: 0 }
    for (const w of words) {
      if (posFilter !== 'all' && w.partOfSpeech !== posFilter) continue
      const b = buckets[w.id] ?? 'learn'
      counts[b] += 1
    }
    return counts
  }, [words, buckets, posFilter])

  const filtered = useMemo(() => words.filter(w => {
    const posMatch = posFilter === 'all' || w.partOfSpeech === posFilter
    const bucketMatch = (buckets[w.id] ?? 'learn') === bucketFilter
    return posMatch && bucketMatch
  }), [words, posFilter, bucketFilter, buckets])

  const filteredIdsKey = useMemo(
    () => filtered.map(w => w.id).sort().join('|'),
    [filtered],
  )

  const deck = useMemo(() => {
    const byId = Object.fromEntries(filtered.map(w => [w.id, w]))
    const baseIds = filtered.map(w => w.id)
    const order = deckOrder.length === baseIds.length && deckOrder.every(id => byId[id])
      ? deckOrder
      : orderDeckIds(baseIds, shuffleMode)
    return order.map(id => byId[id]).filter(Boolean)
  }, [filtered, deckOrder, shuffleMode])

  useEffect(() => {
    setDeckOrder(orderDeckIds(filtered.map(w => w.id), shuffleMode))
    setIndex(0)
    setFlipped(false)
  }, [filteredIdsKey, shuffleMode])

  useEffect(() => { setFlipped(false) }, [index])

  useEffect(() => {
    const refresh = () => setBuckets(loadWordBucketsForUI())
    window.addEventListener('studium-local-data-change', refresh)
    return () => window.removeEventListener('studium-local-data-change', refresh)
  }, [])

  const card = deck[index]
  const currentBucket = BUCKET_OPTIONS.find(b => b.value === bucketFilter)!
  const progressPct = deck.length > 0 ? Math.round(((index + 1) / deck.length) * 100) : 0

  function setShuffleModeEnabled(enabled: boolean) {
    setShuffleMode(enabled)
    localStorage.setItem(SHUFFLE_MODE_KEY, String(enabled))
  }

  function moveBucket(b: BucketFilter) {
    if (!card) return
    const next = { ...buckets, [card.id]: b }
    setBuckets(next)
    saveWordBucketsFromUI(next)
    const cardLeavesDeck = b !== bucketFilter
    if (cardLeavesDeck) {
      setFlipped(false)
      return
    }
    if (index < deck.length - 1) {
      setIndex(i => i + 1)
    } else if (deck.length > 1) {
      if (shuffleMode) {
        setDeckOrder(shuffleIds(deck.map(w => w.id)))
      }
      setIndex(0)
    }
    setFlipped(false)
  }

  function updateFilter(pos: PosFilter) {
    setPosFilter(pos)
    localStorage.setItem(POS_KEY, pos)
  }

  function updateBucketFilter(b: BucketFilter) {
    setBucketFilter(b)
    localStorage.setItem(BUCKET_FILTER_KEY, b)
  }

  function goNext() { setIndex(i => Math.min(deck.length - 1, i + 1)) }
  function goPrev() { setIndex(i => Math.max(0, i - 1)) }

  return (
    <div className="flex-1 overflow-y-auto studium-screen">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 py-8">

        <PageHeader
          eyebrow="SAT vocabulary"
          title="Flashcards"
          subtitle={`${words.length.toLocaleString()} words · flip to reveal definitions, then sort into piles`}
        />

        <div className="grid grid-cols-1 lg:grid-cols-[240px_1fr] gap-6 items-start">

          {/* Sidebar: deck + filters */}
          <aside className="space-y-4">
            <div className="space-y-2">
              {BUCKET_OPTIONS.map(opt => {
                const active = bucketFilter === opt.value
                const count = bucketCounts[opt.value]
                return (
                  <button
                    key={opt.value}
                    type="button"
                    onClick={() => updateBucketFilter(opt.value)}
                    className={['studium-deck-btn w-full text-left', active ? 'studium-deck-btn--active' : ''].join(' ')}
                    style={active ? { borderColor: opt.accent, background: opt.bg } : undefined}
                  >
                    <opt.Icon size={18} style={{ color: active ? opt.accent : 'var(--muted)' }} aria-hidden="true" />
                    <div className="flex-1 min-w-0">
                      <div className="font-semibold text-sm text-[var(--text)]">{opt.label} ({count})</div>
                      <div className="text-xs mt-0.5 text-[var(--muted)]">{opt.description}</div>
                    </div>
                  </button>
                )
              })}
            </div>

            <div className="studium-card p-4 space-y-3">
              <div className="text-xs font-semibold uppercase tracking-wide text-[var(--muted)]">
                Card order
              </div>
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => setShuffleModeEnabled(false)}
                  className={['studium-chip w-full min-h-[44px]', !shuffleMode ? 'studium-chip--selected' : ''].join(' ')}
                >
                  In order
                </button>
                <button
                  type="button"
                  onClick={() => setShuffleModeEnabled(true)}
                  disabled={filtered.length < 2}
                  className={['studium-chip w-full min-h-[44px]', shuffleMode ? 'studium-chip--selected' : ''].join(' ')}
                >
                  <span className="inline-flex items-center gap-1.5">
                    <Shuffle size={14} aria-hidden="true" />
                    Shuffle
                  </span>
                </button>
              </div>
            </div>

            <div className="studium-card p-4 space-y-3">
              <div className="text-xs font-semibold uppercase tracking-wide text-[var(--muted)]">
                Part of speech
              </div>
              <div className="flex flex-wrap gap-2">
                {POS_OPTIONS.map(opt => (
                  <button
                    key={opt.value}
                    type="button"
                    onClick={() => updateFilter(opt.value)}
                    className={['studium-chip text-xs px-3', posFilter === opt.value ? 'studium-chip--selected' : ''].join(' ')}
                  >
                    {opt.label}
                  </button>
                ))}
              </div>
            </div>
          </aside>

          {/* Main flashcard area */}
          <div className="space-y-4 min-w-0">
            {deck.length === 0 ? (
              <div className="studium-card p-10 text-center space-y-4">
                <div
                  className="mx-auto flex items-center justify-center rounded-full"
                  style={{ width: 56, height: 56, background: 'var(--fill-tertiary)' }}
                >
                  <CheckCircle2 size={28} style={{ color: 'var(--success)' }} aria-hidden="true" />
                </div>
                <div>
                  <div className="text-lg font-semibold" style={{ color: 'var(--text)' }}>
                    {bucketFilter === 'mastered' ? 'All caught up!' : 'No cards in this pile'}
                  </div>
                  <p className="text-sm mt-2 mb-0 max-w-sm mx-auto" style={{ color: 'var(--muted)' }}>
                    {bucketFilter === 'learn'
                      ? 'Try a different part of speech, or move words here from Review or Mastered.'
                      : 'Switch to Learning to study new words, or change the part-of-speech filter.'}
                  </p>
                </div>
                {BUCKET_OPTIONS.filter(o => o.value !== bucketFilter).map(opt => (
                  <button
                    key={opt.value}
                    type="button"
                    onClick={() => updateBucketFilter(opt.value)}
                    className="studium-btn-secondary"
                  >
                    Go to {opt.label}
                  </button>
                ))}
              </div>
            ) : (
              <>
                <div className="flex items-center justify-between gap-3">
                  <div className="text-sm font-medium text-[var(--muted)]">
                    Card {index + 1} of {deck.length}
                    {shuffleMode && deck.length > 1 && (
                      <span className="ml-2 text-xs font-semibold text-[var(--accent)]">· Shuffled</span>
                    )}
                  </div>
                  <div
                    className="text-xs font-semibold px-2.5 py-1 rounded-full"
                    style={{ background: currentBucket.bg, color: currentBucket.accent }}
                  >
                    {currentBucket.label}
                  </div>
                </div>

                <div className="h-1.5 rounded-full overflow-hidden" style={{ background: 'var(--border)' }}>
                  <div
                    className="h-full rounded-full transition-all duration-300"
                    style={{ width: `${progressPct}%`, background: 'var(--accent)' }}
                  />
                </div>

                <div
                  className="studium-flashcard relative cursor-pointer select-none"
                  style={{ minHeight: '280px' }}
                  onClick={() => setFlipped(f => !f)}
                  onKeyDown={e => {
                    if (e.key === 'Enter' || e.key === ' ') {
                      e.preventDefault()
                      setFlipped(f => !f)
                    }
                  }}
                  tabIndex={0}
                  role="button"
                  aria-label={flipped ? 'Tap to see word' : 'Tap to reveal definition'}
                >
                  <div
                    className={`flip-card-side absolute inset-0 flex flex-col items-center justify-center p-8 ${flipped ? 'hidden-side' : 'visible-side'}`}
                  >
                    <div className="text-xs font-semibold uppercase tracking-widest mb-4" style={{ color: 'var(--muted)' }}>
                      Word
                    </div>
                    <div className="text-4xl sm:text-5xl font-bold text-center leading-tight" style={{ color: 'var(--text)' }}>
                      {card.word}
                    </div>
                    <div className="mt-4 text-sm capitalize px-3 py-1 rounded-full" style={{ background: 'var(--fill-tertiary)', color: 'var(--muted)' }}>
                      {card.partOfSpeech}
                    </div>
                    <div className="mt-8 text-xs flex items-center gap-1.5" style={{ color: 'var(--muted)' }}>
                      <RotateCcw size={12} aria-hidden="true" />
                      <span>Click or tap to reveal</span>
                    </div>
                  </div>

                  <div
                    className={`flip-card-side absolute inset-0 flex flex-col items-center justify-center p-8 ${flipped ? 'visible-side' : 'hidden-side'}`}
                    style={{ background: currentBucket.bg }}
                  >
                    <div className="text-xs font-semibold uppercase tracking-widest mb-4" style={{ color: currentBucket.accent }}>
                      Definition
                    </div>
                    <div className="text-xl sm:text-2xl font-medium text-center leading-relaxed max-w-md" style={{ color: 'var(--text)' }}>
                      {card.definition}
                    </div>
                    <div className="mt-6 text-base font-semibold italic" style={{ color: currentBucket.accent }}>
                      {card.word}
                    </div>
                  </div>
                </div>

                <div className="flex gap-2">
                  <button
                    type="button"
                    onClick={goPrev}
                    disabled={index === 0}
                    className="studium-btn-secondary flex-1"
                  >
                    <ChevronLeft size={16} aria-hidden="true" />
                    Previous
                  </button>
                  <button
                    type="button"
                    onClick={goNext}
                    disabled={index === deck.length - 1}
                    className="studium-btn-secondary flex-1"
                  >
                    Next
                    <ChevronRight size={16} aria-hidden="true" />
                  </button>
                </div>

                <div className="studium-card p-4">
                  <div className="text-xs font-semibold uppercase tracking-wide mb-3 text-[var(--muted)]">
                    How well do you know this word?
                  </div>
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
                    <Button variant="secondary" fullWidth onClick={() => moveBucket('learn')}>
                      Still learning
                    </Button>
                    <Button variant="secondary" fullWidth onClick={() => moveBucket('review')}>
                      Review later
                    </Button>
                    <Button fullWidth onClick={() => moveBucket('mastered')}>
                      Know it
                    </Button>
                  </div>
                </div>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
