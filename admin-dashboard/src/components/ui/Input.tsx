import type { InputHTMLAttributes } from 'react';
import { cn } from '@/lib/cn';

export function Input({ className, ...props }: InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      className={cn(
        'h-10 w-full rounded-xl border border-white/10 bg-black/30 px-3 text-sm text-neutral-100',
        'placeholder:text-neutral-500 outline-none transition',
        'focus:border-violet-400/45 focus:ring-2 focus:ring-[rgba(124,58,237,0.25)]',
        className,
      )}
      {...props}
    />
  );
}
