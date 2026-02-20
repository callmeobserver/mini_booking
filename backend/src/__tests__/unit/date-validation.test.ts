import { describe, it, expect } from 'vitest';
import { validateDateRange } from '../../utils/date-validation.js';

describe('validateDateRange', () => {
  const futureDate = (days: number) => {
    const d = new Date();
    d.setDate(d.getDate() + days);
    d.setHours(0, 0, 0, 0);
    return d;
  };

  it('should accept valid date range', () => {
    expect(() => validateDateRange(futureDate(1), futureDate(5))).not.toThrow();
  });

  it('should reject check-in equal to check-out', () => {
    const date = futureDate(3);
    expect(() => validateDateRange(date, date)).toThrow('Check-in date must be before check-out date');
  });

  it('should reject check-in after check-out', () => {
    expect(() => validateDateRange(futureDate(5), futureDate(1))).toThrow('Check-in date must be before check-out date');
  });

  it('should reject check-in in the past', () => {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);
    expect(() => validateDateRange(yesterday, futureDate(5))).toThrow('Check-in date cannot be in the past');
  });

  it('should reject stays longer than 30 days', () => {
    expect(() => validateDateRange(futureDate(1), futureDate(35))).toThrow('Maximum booking duration is 30 days');
  });
});
