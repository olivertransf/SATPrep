import { useState, useEffect } from 'react'
import type { VocabWord } from '../../types'
import { ChevronLeft, ChevronRight, RotateCcw } from 'lucide-react'

interface VocabFlashcardsProps {
  words: VocabWord[]
}

type PosFilter = 'all' | 'noun' | 'verb' | 'adj' | 'adverb' | 'other'
type BucketFilter = 'learn' | 'review' | 'mastered'

const BUCKET_KEY = 'studium_vocab_buckets'
const POS_KEY = 'studium_vocab_pos_filter'
const BUCKET_FILTER_KEY = 'studium_vocab_bucket_filter'

function loadBuckets(): Record<string, BucketFilter> {
  try { return JSON.parse(localStorage.getItem(BUCKET_KEY) ?? '{}') } catch { return {} }
}
function saveBuckets(b: Record<string, BucketFilter>) {
  localStorage.setItem(BUCKET_KEY, JSON.stringify(b))
}

const POS_OPTIONS: { value: PosFilter; label: string }[] = [
  { value: 'all',    label: 'All' },
  { value: 'noun',   label: 'Nouns' },
  { value: 'verb',   label: 'Verbs' },
  { value: 'adj',    label: 'Adjectives' },
  { value: 'adverb', label: 'Adverbs' },
  { value: 'other',  label: 'Other' },
]

const BUCKET_OPTIONS: { value: BucketFilter; label: string; accent: string; bg: string }[] = [
  { value: 'learn',    label: 'Learning', accent: 'var(--accent)',  bg: 'var(--accent-chip-fill)' },
  { value: 'review',   label: 'Review',   accent: 'var(--warning)', bg: 'rgba(249,115,22,0.12)' },
  { value: 'mastered', label: 'Mastered', accent: 'var(--success)', bg: 'rgba(34,197,94,0.12)'  },
]

export default function VocabFlashcards({ words }: VocabFlashcardsProps) {
  const [buckets, setBuckets] = useState<Record<string, BucketFilter>>(loadBuckets)
  const [posFilter, setPosFilter] = useState<PosFilter>(() => {
    return (localStorage.getItem(POS_KEY) as PosFilter) ?? 'all'
  })
  const [bucketFilter, setBucketFilter] = useState<BucketFilter>(() => {
    return (localStorage.getItem(BUCKET_FILTER_KEY) as BucketFilter) ?? 'learn'
  })
  const [index, setIndex] = useState(0)
  const [flipped, setFlipped] = useState(false)

  const filtered = words.filter(w => {
    const posMatch    = posFilter === 'all' || w.partOfSpeech === posFilter
    const bucketMatch = (buckets[w.id] ?? 'learn') === bucketFilter
    return posMatch && bucketMatch
  })

  useEffect(() => {
    setIndex(0)
    setFlipped(false)
  }, [posFilter, bucketFilter])

  useEffect(() => { setFlipped(false) }, [index])

  const card = filtered[index]
  const currentBucket = BUCKET_OPTIONS.find(b => b.value === bucketFilter)!

  function moveBucket(b: BucketFilter) {
    if (!card) return
    const next = { ...buckets, [card.id]: b }
    setBuckets(next)
    saveBuckets(next)
    if (index < filtered.length - 1) setIndex(i => i + 1)
    else if (filtered.length > 1) setIndex(0)
  }

  function updateFilter(pos: PosFilter) {
    setPosFilter(pos)
    localStorage.setItem(POS_KEY, pos)
  }

  function updateBucketFilter(b: BucketFilter) {
    setBucketFilter(b)
    localStorage.setItem(BUCKET_FILTER_KEY, b)
  }

  function goNext() { setIndex(i => Math.min(filtered.length - 1, i + 1)) }
  function goPrev() { setIndex(i => Math.max(0, i - 1)) }

  return (
    <div className="flex-1 overflow-y-auto studium-screen">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 py-6 space-y-5">

        {/* Bucket tabs */}
        <div className="flex gap-1 p-1 studium-card">
          {BUCKET_OPTIONS.map(opt => {
            const count = words.filter(w =>
              (buckets[w.id] ?? 'learn') === opt.value &&
              (posFilter === 'all' || w.partOfSpeech === posFilter)
            ).length
            const active = bucketFilter === opt.value
            return (
              <button key={opt.value} onClick={() => updateBucketFilter(opt.value)}
                className={['studium-chip flex-1 py-1.5 text-xs', bucketFilter === opt.value ? 'studium-chip--selected' : ''].join(' ')}
                style={active
                  ? { background: opt.bg, color: opt.accent }
                  : { color: 'var(--muted)' }
                }>
                {opt.label} <span className="text-xs opacity-70">({count})</span>
              </button>
            )
          })}
        </div>

        {/* POS filter chips */}
        <div className="flex gap-2 overflow-x-auto pb-1 -mx-3 sm:-mx-4 lg:mx-0 px-3 sm:px-4 lg:px-0">
          {POS_OPTIONS.map(opt => (
            <button
              key={opt.value}
              type="button"
              onClick={() => updateFilter(opt.value)}
              className={['studium-chip shrink-0', posFilter === opt.value ? 'studium-chip--selected' : ''].join(' ')}
            >
              {opt.label}
            </button>
          ))}
        </div>

        {/* Card or empty state */}
        {filtered.length === 0 ? (
          <div className="studium-card p-8 text-center">
            <div className="text-4xl mb-3">📭</div>
            <div className="text-base font-semibold" style={{ color: 'var(--text)' }}>No cards here</div>
            <div className="text-sm mt-1" style={{ color: 'var(--muted)' }}>Try a different filter</div>
          </div>
        ) : (
          <>
            {/* Counter */}
            <div className="text-center text-sm" style={{ color: 'var(--muted)' }}>
              {index + 1} / {filtered.length}
            </div>

            {/* Card — crossfade approach, no 3D transforms */}
            <div
              className="relative studium-card overflow-hidden cursor-pointer select-none p-0"
              style={{ minHeight: '220px' }}
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
              {/* Front */}
              <div
                className={`flip-card-side absolute inset-0 flex flex-col items-center justify-center p-6 rounded-sm ${flipped ? 'hidden-side' : 'visible-side'}`}
                style={{ background: 'var(--card)', borderColor: 'var(--border)' }}
              >
                <div className="text-3xl font-bold text-center" style={{ color: 'var(--text)' }}>
                  {card.word}
                </div>
                <div className="mt-2 text-sm italic" style={{ color: 'var(--muted)' }}>
                  {card.partOfSpeech}
                </div>
                <div className="mt-6 text-xs flex items-center gap-1.5" style={{ color: 'var(--muted)' }}>
                  <RotateCcw size={12} aria-hidden="true" />
                  <span>tap to reveal</span>
                </div>
              </div>

              {/* Back */}
              <div
                className={`flip-card-side absolute inset-0 flex flex-col items-center justify-center p-6 rounded-sm ${flipped ? 'visible-side' : 'hidden-side'}`}
                style={{ background: currentBucket.bg, border: `1px solid ${currentBucket.accent}` }}
              >
                <div className="text-xl font-semibold text-center leading-snug" style={{ color: 'var(--text)' }}>
                  {card.definition}
                </div>
                <div className="mt-3 text-sm italic font-medium" style={{ color: currentBucket.accent }}>
                  {card.word}
                </div>
                <div className="mt-4 text-xs flex items-center gap-1.5" style={{ color: currentBucket.accent, opacity: 0.8 }}>
                  <RotateCcw size={12} aria-hidden="true" />
                  <span>tap to flip back</span>
                </div>
              </div>
            </div>

            {/* Prev / Next */}
            <div className="flex gap-2.5">
              <button
                onClick={goPrev}
                disabled={index === 0}
                className="flex items-center justify-center gap-2 flex-1 py-2.5 rounded-sm border text-sm font-medium transition-all disabled:opacity-30"
                style={{ background: 'var(--card)', borderColor: 'var(--border)', color: 'var(--text)' }}>
                <ChevronLeft size={16} /> Prev
              </button>
              <button
                onClick={goNext}
                disabled={index === filtered.length - 1}
                className="flex items-center justify-center gap-2 flex-1 py-2.5 rounded-sm border text-sm font-medium transition-all disabled:opacity-30"
                style={{ background: 'var(--card)', borderColor: 'var(--border)', color: 'var(--text)' }}>
                Next <ChevronRight size={16} />
              </button>
            </div>

            {/* Bucket move buttons */}
            <div className="flex gap-2">
              {BUCKET_OPTIONS.map(opt => (
                <button key={opt.value}
                  onClick={() => moveBucket(opt.value)}
                  className="flex-1 py-2.5 rounded-sm text-sm font-semibold transition-all"
                  style={bucketFilter === opt.value
                    ? { background: opt.bg, color: opt.accent, border: `1px solid ${opt.accent}` }
                    : { background: 'transparent', color: 'var(--muted)', border: '1px solid var(--border)' }
                  }>
                  {opt.label}
                </button>
              ))}
            </div>
          </>
        )}
      </div>
    </div>
  )
}
