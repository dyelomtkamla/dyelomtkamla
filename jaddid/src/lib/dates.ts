// أدوات التواريخ: حساب الأيام المتبقية، والعرض بالميلادي والهجري (أم القرى).

const DAY_MS = 24 * 60 * 60 * 1000;

/** يحوّل "YYYY-MM-DD" إلى تاريخ محلي في منتصف الليل */
export function parseISODate(iso: string): Date {
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(y, m - 1, d);
}

export function toISODate(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

export function isValidDate(y: number, m: number, d: number): boolean {
  if (!Number.isInteger(y) || !Number.isInteger(m) || !Number.isInteger(d)) return false;
  if (y < 1900 || y > 2200 || m < 1 || m > 12 || d < 1) return false;
  const date = new Date(y, m - 1, d);
  return date.getFullYear() === y && date.getMonth() === m - 1 && date.getDate() === d;
}

/** عدد الأيام المتبقية حتى تاريخ الانتهاء (سالب إذا انتهى) */
export function daysUntil(iso: string, now: Date = new Date()): number {
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  return Math.round((parseISODate(iso).getTime() - today.getTime()) / DAY_MS);
}

export function addDays(date: Date, days: number): Date {
  const d = new Date(date);
  d.setDate(d.getDate() + days);
  return d;
}

function safeFormat(date: Date, locale: string, options: Intl.DateTimeFormatOptions): string | null {
  try {
    return new Intl.DateTimeFormat(locale, options).format(date);
  } catch {
    return null;
  }
}

export function formatGregorian(iso: string): string {
  const date = parseISODate(iso);
  return (
    safeFormat(date, 'ar-u-ca-gregory-nu-latn', { day: 'numeric', month: 'long', year: 'numeric' }) ??
    iso
  );
}

/** التاريخ الهجري بتقويم أم القرى المعتمد في السعودية */
export function formatHijri(iso: string): string | null {
  return safeFormat(parseISODate(iso), 'ar-SA-u-ca-islamic-umalqura-nu-latn', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });
}

export type Status = 'expired' | 'urgent' | 'soon' | 'ok';

export function statusOf(days: number): Status {
  if (days < 0) return 'expired';
  if (days <= 7) return 'urgent';
  if (days <= 30) return 'soon';
  return 'ok';
}

export function remainingLabel(days: number): string {
  if (days < 0) {
    const n = -days;
    return n === 1 ? 'منتهي منذ يوم' : n === 2 ? 'منتهي منذ يومين' : `منتهي منذ ${n} يوم`;
  }
  if (days === 0) return 'ينتهي اليوم';
  if (days === 1) return 'ينتهي غداً';
  if (days === 2) return 'باقي يومان';
  if (days <= 10) return `باقي ${days} أيام`;
  return `باقي ${days} يوم`;
}

export function reminderLabel(days: number): string {
  if (days === 0) return 'يوم الانتهاء';
  if (days === 1) return 'قبل يوم';
  if (days === 2) return 'قبل يومين';
  if (days <= 10) return `قبل ${days} أيام`;
  return `قبل ${days} يوم`;
}
