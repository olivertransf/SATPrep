import { useState, useMemo, useId, type CSSProperties } from 'react'
import katex from 'katex'
import 'katex/dist/katex.min.css'
import { Search, ChevronDown, ChevronUp, Calculator, BookOpen } from 'lucide-react'
import { MATH_SECTIONS, RW_SECTIONS, type ReferenceSection, type ReferenceEntry, type EntryTag } from './referenceData'

const TAG_STYLES: Record<EntryTag, { label: string; bg: string; color: string }> = {
  provided: { label: 'On test', bg: 'rgba(22, 163, 74, 0.12)', color: '#16a34a' },
  memorize: { label: 'Memorize', bg: 'var(--accent-chip-fill)', color: 'var(--accent)' },
  rule: { label: 'Rule', bg: 'rgba(234, 179, 8, 0.12)', color: '#ca8a04' },
  tip: { label: 'Strategy', bg: 'rgba(59, 130, 246, 0.12)', color: '#3b82f6' },
}

function TagBadge({ tag }: { tag: EntryTag }) {
  const s = TAG_STYLES[tag]
  return (
    <span
      className="inline-block px-2 py-0.5 rounded-full text-[11px] font-semibold shrink-0"
      style={{ background: s.bg, color: s.color }}
    >
      {s.label}
    </span>
  )
}

function KaTeXBlock({ src }: { src: string }) {
  let html = ''
  try {
    html = katex.renderToString(src, { displayMode: true, throwOnError: false, output: 'html' })
  } catch {
    return <code className="text-sm font-mono" style={{ color: 'var(--muted)' }}>{src}</code>
  }
  return (
    <div
      className="studium-formula-block overflow-x-auto text-base"
      dangerouslySetInnerHTML={{ __html: html }}
    />
  )
}

function EntryRow({ entry }: { entry: ReferenceEntry }) {
  return (
    <div className="studium-ref-entry">
      <div className="flex items-start justify-between gap-3 flex-wrap">
        <h4 className="text-sm font-semibold m-0 leading-snug" style={{ color: 'var(--text)' }}>
          {entry.title}
        </h4>
        {entry.tag && <TagBadge tag={entry.tag} />}
      </div>

      {(entry.latex || entry.formula) && (
        <div className="mt-2">
          {entry.latex ? (
            <KaTeXBlock src={entry.latex} />
          ) : (
            <p className="studium-formula-block text-sm font-mono whitespace-pre-line m-0" style={{ color: 'var(--text)' }}>
              {entry.formula}
            </p>
          )}
        </div>
      )}

      {entry.detail && (
        <p className="text-sm mt-2 mb-0 leading-relaxed" style={{ color: 'var(--muted)' }}>
          {entry.detail}
        </p>
      )}
    </div>
  )
}

function SectionAccordion({ section, defaultOpen }: { section: ReferenceSection; defaultOpen?: boolean }) {
  const [open, setOpen] = useState(defaultOpen ?? false)
  const headingId = useId()
  const panelId = useId()

  return (
    <div
      className={['studium-ref-section', open ? 'studium-ref-section--open' : ''].join(' ')}
      style={{ '--ref-accent': section.color } as CSSProperties}
    >
      <button
        id={headingId}
        type="button"
        aria-expanded={open}
        aria-controls={panelId}
        onClick={() => setOpen(o => !o)}
        className="studium-ref-section__header w-full"
      >
        <div className="flex items-center gap-3 flex-1 min-w-0">
          <span className="text-base font-semibold truncate" style={{ color: 'var(--text)' }}>
            {section.title}
          </span>
          <span className="text-xs font-medium px-2 py-0.5 rounded-full shrink-0" style={{ background: 'var(--fill-tertiary)', color: 'var(--muted)' }}>
            {section.entries.length}
          </span>
        </div>
        {open
          ? <ChevronUp size={18} aria-hidden="true" style={{ color: 'var(--muted)' }} />
          : <ChevronDown size={18} aria-hidden="true" style={{ color: 'var(--muted)' }} />
        }
      </button>

      {open && (
        <div id={panelId} role="region" aria-labelledby={headingId} className="studium-ref-section__body">
          {section.entries.map(entry => (
            <EntryRow key={entry.title} entry={entry} />
          ))}
        </div>
      )}
    </div>
  )
}

export default function ReferenceView() {
  const [subject, setSubject] = useState<'math' | 'rw'>('math')
  const [search, setSearch] = useState('')
  const searchId = useId()

  const allSections = subject === 'math' ? MATH_SECTIONS : RW_SECTIONS
  const totalEntries = allSections.reduce((n, s) => n + s.entries.length, 0)

  const filteredSections = useMemo<ReferenceSection[]>(() => {
    const q = search.trim().toLowerCase()
    if (!q) return allSections
    return allSections.flatMap(section => {
      const hits = section.entries.filter(e =>
        e.title.toLowerCase().includes(q) ||
        (e.formula?.toLowerCase().includes(q) ?? false) ||
        (e.latex?.toLowerCase().includes(q) ?? false) ||
        (e.detail?.toLowerCase().includes(q) ?? false),
      )
      return hits.length > 0 ? [{ ...section, entries: hits }] : []
    })
  }, [allSections, search])

  const hasSearch = search.trim().length > 0
  const mid = Math.ceil(filteredSections.length / 2)
  const col1 = filteredSections.slice(0, mid)
  const col2 = filteredSections.slice(mid)

  const renderSection = (section: ReferenceSection) => (
    <SectionAccordion
      key={section.id}
      section={section}
      defaultOpen={false}
    />
  )

  return (
    <div className="flex-1 overflow-y-auto studium-screen">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 py-8 space-y-6">

        <header>
          <p className="studium-eyebrow m-0">Study sheets</p>
          <h1 className="text-2xl sm:text-3xl font-bold tracking-tight m-0 mt-1" style={{ color: 'var(--text)' }}>
            Reference guide
          </h1>
          <p className="studium-page-subtitle mt-2 mb-0">
            Formulas, rules, and strategies for the Digital SAT
          </p>
        </header>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <button
            type="button"
            onClick={() => { setSubject('math'); setSearch('') }}
            className={['studium-subject-tab', subject === 'math' ? 'studium-subject-tab--active' : ''].join(' ')}
          >
            <Calculator size={22} style={{ color: subject === 'math' ? '#2563eb' : 'var(--muted)' }} aria-hidden="true" />
            <div className="text-left">
              <div className="font-semibold">Math</div>
              <div className="text-xs mt-0.5" style={{ color: 'var(--muted)' }}>
                {MATH_SECTIONS.length} topics
              </div>
            </div>
          </button>
          <button
            type="button"
            onClick={() => { setSubject('rw'); setSearch('') }}
            className={['studium-subject-tab', subject === 'rw' ? 'studium-subject-tab--active' : ''].join(' ')}
          >
            <BookOpen size={22} style={{ color: subject === 'rw' ? '#7c3aed' : 'var(--muted)' }} aria-hidden="true" />
            <div className="text-left">
              <div className="font-semibold">Reading & Writing</div>
              <div className="text-xs mt-0.5" style={{ color: 'var(--muted)' }}>
                {RW_SECTIONS.length} topics
              </div>
            </div>
          </button>
        </div>

        <div className="relative">
          <label htmlFor={searchId} className="sr-only">Search reference</label>
          <Search
            size={18}
            aria-hidden="true"
            className="absolute left-4 top-1/2 -translate-y-1/2 pointer-events-none"
            style={{ color: 'var(--muted)' }}
          />
          <input
            id={searchId}
            type="search"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder={`Search ${totalEntries} formulas and rules…`}
            className="studium-search-input w-full pl-11 pr-4 py-3 text-sm"
          />
        </div>

        {!hasSearch && (
          <div className="flex flex-wrap gap-2">
            {(['provided', 'memorize', 'rule', 'tip'] as EntryTag[]).map(tag => (
              <TagBadge key={tag} tag={tag} />
            ))}
          </div>
        )}

        {filteredSections.length === 0 ? (
          <div className="studium-card p-10 text-center">
            <p className="text-sm m-0" style={{ color: 'var(--muted)' }}>
              No results for &ldquo;{search}&rdquo;
            </p>
          </div>
        ) : (
          <>
            <div className="lg:hidden space-y-3">
              {filteredSections.map(section => renderSection(section))}
            </div>
            <div className="hidden lg:grid lg:grid-cols-2 gap-3 items-start">
              <div className="space-y-3 min-w-0">
                {col1.map(section => renderSection(section))}
              </div>
              <div className="space-y-3 min-w-0">
                {col2.map(section => renderSection(section))}
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  )
}
