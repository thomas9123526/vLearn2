'use client';

import * as React from 'react';
import { createPortal } from 'react-dom';
import { X } from 'lucide-react';
import { cn } from '@/lib/utils';

/**
 * Minimal modal dialog. No external dep — uses a portal into <body> so the
 * overlay isn't trapped inside a scroll container. Closes on backdrop click
 * and on Escape; the consumer controls open state via `open` + `onClose`.
 *
 * Intentionally thin: anything more elaborate (focus trap, scroll lock,
 * Headless UI primitives) can land later. This is enough to host CRUD-style
 * edit forms without dragging in a heavy dependency.
 */
export interface DialogProps {
  open: boolean;
  onClose: () => void;
  title?: React.ReactNode;
  description?: React.ReactNode;
  /** Size hint for the inner panel. Default `md` (640px). */
  size?: 'sm' | 'md' | 'lg' | 'xl';
  children: React.ReactNode;
  /** Footer area (typically Save / Cancel buttons). */
  footer?: React.ReactNode;
}

const SIZE_CLASS: Record<NonNullable<DialogProps['size']>, string> = {
  sm: 'max-w-sm',
  md: 'max-w-xl',
  lg: 'max-w-3xl',
  xl: 'max-w-5xl',
};

export function Dialog({
  open,
  onClose,
  title,
  description,
  size = 'md',
  children,
  footer,
}: DialogProps) {
  // Portal target only exists in the browser, so guard SSR.
  const [mounted, setMounted] = React.useState(false);
  React.useEffect(() => setMounted(true), []);

  // Close on Escape. Listener is attached only while the dialog is open so
  // multiple stacked dialogs each get their own Escape handler.
  React.useEffect(() => {
    if (!open) return;
    function onKey(e: KeyboardEvent) {
      if (e.key === 'Escape') onClose();
    }
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open, onClose]);

  if (!mounted || !open) return null;

  const overlay = (
    <div
      // Backdrop. Clicking it closes; clicks on the inner panel stop here.
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
      onMouseDown={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-label={typeof title === 'string' ? title : undefined}
        className={cn(
          'flex max-h-[90vh] w-full flex-col overflow-hidden rounded-lg border border-border bg-card text-card-foreground shadow-xl',
          SIZE_CLASS[size],
        )}
        onMouseDown={(e) => e.stopPropagation()}
      >
        {(title || description) && (
          <div className="flex items-start justify-between gap-2 border-b border-border px-5 py-4">
            <div>
              {title && <h2 className="text-base font-semibold">{title}</h2>}
              {description && (
                <p className="mt-0.5 text-xs text-muted-foreground">{description}</p>
              )}
            </div>
            <button
              type="button"
              onClick={onClose}
              aria-label="Close"
              className="rounded-md p-1 text-muted-foreground hover:bg-muted hover:text-foreground"
            >
              <X className="h-4 w-4" />
            </button>
          </div>
        )}
        <div className="flex-1 overflow-y-auto px-5 py-4">{children}</div>
        {footer && (
          <div className="flex items-center justify-end gap-2 border-t border-border bg-muted/30 px-5 py-3">
            {footer}
          </div>
        )}
      </div>
    </div>
  );

  return createPortal(overlay, document.body);
}
