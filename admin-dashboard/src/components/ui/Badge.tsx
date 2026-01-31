import { cn } from '@/lib/cn';

export function Badge({
  children,
  tone = 'neutral',
  className,
}: {
  children: React.ReactNode;
  tone?: 'neutral' | 'success' | 'warning';
  className?: string;
}) {
  const tones: Record<string, string> = {
    neutral: 'border-white/10 bg-white/5 text-neutral-200',
    success: 'border-emerald-400/20 bg-emerald-400/10 text-emerald-200',
    warning: 'border-amber-400/20 bg-amber-400/10 text-amber-200',
  };

  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full border px-2.5 py-0.5 text-[11px] font-semibold tracking-tight',
        tones[tone],
        className,
      )}
    >
      {children}
    </span>
  );
}
