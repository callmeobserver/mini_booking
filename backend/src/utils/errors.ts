import { GraphQLError } from 'graphql';

export class ValidationError extends GraphQLError {
  constructor(message: string) {
    super(message, {
      extensions: { code: 'BAD_USER_INPUT' },
    });
  }
}

export class BookingConflictError extends GraphQLError {
  constructor(message: string, conflictingBookings?: unknown[]) {
    super(message, {
      extensions: {
        code: 'BOOKING_CONFLICT',
        ...(conflictingBookings && { conflictingBookings }),
      },
    });
  }
}

export class NotFoundError extends GraphQLError {
  constructor(resource: string, id: string) {
    super(`${resource} with id "${id}" not found`, {
      extensions: { code: 'NOT_FOUND' },
    });
  }
}
