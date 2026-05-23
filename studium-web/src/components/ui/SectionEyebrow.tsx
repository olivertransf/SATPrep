interface SectionEyebrowProps {
  children: string
  className?: string
}

export function SectionEyebrow({ children, className = '' }: SectionEyebrowProps) {
  return <div className={`studium-eyebrow ${className}`.trim()}>{children}</div>
}
