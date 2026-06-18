import type { ButtonHTMLAttributes, ReactNode } from 'react'

type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'destructive'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant
  fullWidth?: boolean
  children: ReactNode
}

const VARIANT_CLASS: Record<ButtonVariant, string> = {
  primary: 'studium-btn-primary',
  secondary: 'studium-btn-secondary',
  ghost: 'studium-btn-ghost',
  destructive: 'studium-btn-destructive',
}

export function Button({
  variant = 'primary',
  fullWidth = false,
  className = '',
  type = 'button',
  children,
  ...props
}: ButtonProps) {
  return (
    <button
      type={type}
      className={[VARIANT_CLASS[variant], fullWidth ? 'w-full' : '', className].filter(Boolean).join(' ')}
      {...props}
    >
      {children}
    </button>
  )
}
