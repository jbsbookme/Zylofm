import type { ButtonHTMLAttributes } from 'react';
import { cn } from '@/lib/cn';

type Variant = 'primary' | 'secondary' | 'ghost' | 'danger';
type Size = 'sm' | 'md';

export function Button({
  className,
  variant = 'secondary',
  size = 'md',
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & { variant?: Variant; size?: Size }) {
  const base =
    'inline-flex items-center justify-center gap-2 rounded-xl font-semibold tracking-tight transition ' +
    'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[rgba(124,58,237,0.65)] focus-visible:ring-offset-2 focus-visible:ring-offset-[rgba(5,6,10,1)] ' +
    'disabled:opacity-50 disabled:cursor-not-allowed';

  const sizes =
    size === 'sm'
      ? 'h-9 px-3 text-xs'
      : 'h-10 px-4 text-sm';

  const variants: Record<Variant, string> = {
    primary:
      'text-neutral-950 bg-gradient-to-r from-violet-400 via-fuchsia-300 to-cyan-300 ' +
      'shadow-[0_10px_30px_-18px_rgba(34,211,238,0.45)] hover:brightness-105 active:brightness-95',
    secondary:
      'text-neutral-100 bg-white/5 border border-white/10 hover:bg-white/8 hover:border-white/15 ' +
      'shadow-[0_1px_0_0_rgba(255,255,255,0.06)_inset]',
    ghost: 'text-neutral-200 hover:bg-white/6',
    danger:
      'text-red-100 bg-red-500/10 border border-red-400/15 hover:bg-red-500/15 hover:border-red-400/25',
  };

  return <button className={cn(base, sizes, variants[variant], className)} {...props} />;
}
