import { ValidationError } from './errors';

export function validateDateRange(checkIn: Date, checkOut: Date): void {
  if (isNaN(checkIn.getTime()) || isNaN(checkOut.getTime())) {
    throw new ValidationError('Invalid date format');
  }

  if (checkIn >= checkOut) {
    throw new ValidationError('Check-in date must be before check-out date');
  }

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  if (checkIn < today) {
    throw new ValidationError('Check-in date cannot be in the past');
  }

  const diffMs = checkOut.getTime() - checkIn.getTime();
  const diffDays = diffMs / (1000 * 60 * 60 * 24);
  if (diffDays > 30) {
    throw new ValidationError('Maximum booking duration is 30 days');
  }
}
