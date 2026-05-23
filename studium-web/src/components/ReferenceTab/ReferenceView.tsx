import { useState, useMemo, useId } from 'react'
import katex from 'katex'
import 'katex/dist/katex.min.css'
import { Search, ChevronDown, ChevronUp } from 'lucide-react'
import { MATH_SECTIONS, RW_SECTIONS, type ReferenceSection, type ReferenceEntry, type EntryTag } from './referenceData'

// ─── Tag badge ──────────────────────────────────────────────────────────────

const TAG_STYLES: Record<EntryTag, { label: string; bg: string; color: string }> = {
  provided: { label: 'On Test',   bg: 'rgba(22,163,74,0.15)',  color: '#16a34a' },
  memorize: { label: 'Memorize',  bg: 'var(--accent-chip-fill)', color: 'var(--accent)' },
  rule:     { label: 'Rule',      bg: 'rgba(234,179,8,0.15)',  color: '#ca8a04' },
  tip:      { label: 'Strategy',  bg: 'rgba(59,130,246,0.15)', color: '#3b82f6' },
}

function TagBadge({ tag }: { tag: EntryTag }) {
  const s = TAG_STYLES[tag]
  return (
    <span
      className="inline-block px-1.5 py-0.5 rounded-sm text-[10px] font-semibold tracking-wide shrink-0"
      style={{ background: s.bg, color: s.color }}
    >
      {s.label}
    </span>
  )
}

// ─── KaTeX math renderer ─────────────────────────────────────────────────────

function KaTeXBlock({ src }: { src: string }) {
  let html = ''
  try {
    html = katex.renderToString(src, { displayMode: true, throwOnError: false, output: 'html' })
  } catch {
    return <code className="text-xs font-mono" style={{ color: 'var(--muted)' }}>{src}</code>
  }
  return (
    <div
      className="overflow-x-auto text-sm py-1"
      dangerouslySetInnerHTML={{ __html: html }}
      aria-hidden="true"
    />
  )
}

// ─── Entry row ───────────────────────────────────────────────────────────────

function EntryRow({ entry }: { entry: ReferenceEntry }) {
  return (
    <div className="studium-reading-panel space-y-1.5">
      <div className="flex items-start justify-between gap-2 flex-wrap">
        <span className="text-sm font-semibold leading-snug" style={{ color: 'var(--text)' }}>
          {entry.title}
        </span>
        {entry.tag && <TagBadge tag={entry.tag} />}
      </div>

      {entry.latex ? (
        <KaTeXBlock src={entry.latex} />
      ) : entry.formula ? (
        <p className="text-sm font-mono whitespace-pre-line leading-relaxed" style={{ color: 'var(--muted)' }}>
          {entry.formula}
        </p>
      ) : null}

      {entry.detail && (
        <p className="text-xs whitespace-pre-line leading-relaxed" style={{ color: 'var(--muted)' }}>
          {entry.detail}
        </p>
      )}
    </div>
  )
}

// ─── Section accordion ───────────────────────────────────────────────────────

function SectionAccordion({ section, defaultOpen }: { section: ReferenceSection; defaultOpen?: boolean }) {
  const [open, setOpen] = useState(defaultOpen ?? false)
  const headingId = useId()
  const panelId = useId()

  return (
    <div
      className="studium-card overflow-hidden p-0"
    >
      <button
        id={headingId}
        aria-expanded={open}
        aria-controls={panelId}
        onClick={() => setOpen(o => !o)}
      className="w-full flex items-center justify-between px-4 py-2.5 text-left transition-opacity hover:opacity-90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-1"
      >
        <div className="flex items-center gap-3">
          <div
            className="w-2.5 h-2.5 rounded-full shrink-0"
            style={{ background: section.color }}
            aria-hidden="true"
          />
          <span className="text-sm font-semibold" style={{ color: 'var(--text)' }}>
            {section.title}
          </span>
          <span
            className="text-xs font-medium px-1.5 py-0.5 rounded-sm border"
            style={{ background: 'transparent', color: 'var(--muted)', borderColor: 'var(--border)' }}
          >
            {section.entries.length}
          </span>
        </div>
        {open
          ? <ChevronUp size={15} aria-hidden="true" style={{ color: 'var(--muted)' }} />
          : <ChevronDown size={15} aria-hidden="true" style={{ color: 'var(--muted)' }} />
        }
      </button>

      {open && (
        <div
          id={panelId}
          role="region"
          aria-labelledby={headingId}
          className="px-4 pb-4 space-y-1.5"
        >
          {section.entries.map(entry => (
            <EntryRow key={entry.title} entry={entry} />
          ))}
        </div>
      )}
    </div>
  )
}

// ─── Main view ───────────────────────────────────────────────────────────────

export default function ReferenceView() {
  const [subject, setSubject] = useState<'math' | 'rw'>('math')
  const [search, setSearch] = useState('')
  const searchId = useId()

  const allSections = subject === 'math' ? MATH_SECTIONS : RW_SECTIONS

  const filteredSections = useMemo<ReferenceSection[]>(() => {
    const q = search.trim().toLowerCase()
    if (!q) return allSections
    return allSections.flatMap(section => {
      const hits = section.entries.filter(e =>
        e.title.toLowerCase().includes(q) ||
        (e.formula?.toLowerCase().includes(q) ?? false) ||
        (e.detail?.toLowerCase().includes(q) ?? false)
      )
      return hits.length > 0 ? [{ ...section, entries: hits }] : []
    })
  }, [allSections, search])

  const hasSearch = search.trim().length > 0

  // Split into two columns for large screens
  const mid = Math.ceil(filteredSections.length / 2)
  const col1 = filteredSections.slice(0, mid)
  const col2 = filteredSections.slice(mid)

  const renderSection = (section: ReferenceSection, i: number) => (
    <SectionAccordion
      key={section.id}
      section={section}
      defaultOpen={hasSearch || i === 0}
    />
  )

  return (
    <div className="flex-1 overflow-y-auto studium-screen">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 py-5 space-y-4">

        {/* Controls row */}
        <div className="flex flex-col sm:flex-row gap-2">
          {/* Subject toggle */}
          <div className="flex gap-2 shrink-0" role="tablist" aria-label="Subject">
            {(['math', 'rw'] as const).map(s => (
              <button
                key={s}
                type="button"
                role="tab"
                aria-selected={subject === s}
                onClick={() => { setSubject(s); setSearch('') }}
                className={['studium-chip', subject === s ? 'studium-chip--selected' : ''].join(' ')}
              >
                {s === 'math' ? 'Math' : 'Reading & Writing'}
              </button>
            ))}
          </div>

          {/* Search */}
          <div className="relative flex-1">
            <label htmlFor={searchId} className="sr-only">Search reference</label>
            <Search
              size={14}
              aria-hidden="true"
              className="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none"
              style={{ color: 'var(--muted)' }}
            />
            <input
              id={searchId}
              type="search"
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search formulas, rules…"
              className="w-full pl-8 pr-3 py-2.5 text-sm border outline-none"
              style={{
                background: 'var(--card)',
                borderColor: 'var(--border)',
                color: 'var(--text)',
                borderRadius: 'var(--radius-chip)',
              }}
            />
          </div>
        </div>

        {/* Sections */}
        {filteredSections.length === 0 ? (
          <p className="text-center py-12 text-sm" style={{ color: 'var(--muted)' }}>
            No results for "{search}"
          </p>
        ) : (
          <>
            {/* Single-column (mobile) */}
            <div className="lg:hidden space-y-2.5">
              {filteredSections.map((section, i) => renderSection(section, i))}
            </div>

            {/* Two-column (lg+) */}
            <div className="hidden lg:flex gap-3 items-start">
              <div className="flex-1 space-y-2.5 min-w-0">
                {col1.map((section, i) => renderSection(section, i))}
              </div>
              <div className="flex-1 space-y-2.5 min-w-0">
                {col2.map((section, i) => renderSection(section, i + mid))}
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  )
}
