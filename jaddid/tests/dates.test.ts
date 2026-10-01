import assert from 'node:assert/strict';
import { test } from 'node:test';
import { daysUntil, formatHijri, isValidDate, remainingLabel, statusOf, toISODate } from '../src/lib/dates.ts';

const now = new Date(2026, 9, 1); // 1 أكتوبر 2026

test('daysUntil يحسب الأيام المتبقية والمنقضية', () => {
  assert.equal(daysUntil('2026-10-01', now), 0);
  assert.equal(daysUntil('2026-10-31', now), 30);
  assert.equal(daysUntil('2026-09-28', now), -3);
  assert.equal(daysUntil('2027-10-01', now), 365);
});

test('statusOf يصنف حسب القرب', () => {
  assert.equal(statusOf(-1), 'expired');
  assert.equal(statusOf(0), 'urgent');
  assert.equal(statusOf(7), 'urgent');
  assert.equal(statusOf(30), 'soon');
  assert.equal(statusOf(31), 'ok');
});

test('isValidDate يرفض التواريخ غير الموجودة', () => {
  assert.equal(isValidDate(2026, 2, 29), false);
  assert.equal(isValidDate(2028, 2, 29), true);
  assert.equal(isValidDate(2026, 13, 1), false);
  assert.equal(toISODate(new Date(2026, 0, 5)), '2026-01-05');
});

test('الصياغة العربية', () => {
  assert.equal(remainingLabel(0), 'ينتهي اليوم');
  assert.equal(remainingLabel(5), 'باقي 5 أيام');
  assert.equal(remainingLabel(-2), 'منتهي منذ يومين');
  assert.match(formatHijri('2026-10-01') ?? '', /1448/);
});
