export default function DesmosCalculator() {
  return (
    <div className="flex-1 flex flex-col" style={{ background: 'var(--bg)' }}>
      <iframe
        src="https://www.desmos.com/testing/collegeboard/graphing"
        className="flex-1 w-full border-0"
        title="Desmos Graphing Calculator"
        allow="fullscreen"
      />
    </div>
  )
}
