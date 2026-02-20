import { PrismaClient, BookingStatus, Prisma } from '@prisma/client';
import { logger } from '../utils/logger';
import { BookingConflictError, ValidationError, NotFoundError } from '../utils/errors';
import { validateDateRange } from '../utils/date-validation';

export class BookingService {
  constructor(private prisma: PrismaClient) {}

  async createBooking(input: {
    roomId: string;
    guestName: string;
    guestEmail?: string;
    checkIn: Date;
    checkOut: Date;
  }) {
    validateDateRange(input.checkIn, input.checkOut);

    return this.prisma.$transaction(async (tx) => {
      const room = await tx.room.findUnique({
        where: { id: input.roomId },
        include: { hotel: true },
      });

      if (!room) {
        throw new NotFoundError('Room', input.roomId);
      }

      // Application-level overlap check
      const overlapping = await tx.booking.findMany({
        where: {
          roomId: input.roomId,
          status: BookingStatus.CONFIRMED,
          checkIn: { lt: input.checkOut },
          checkOut: { gt: input.checkIn },
        },
      });

    if (overlapping.length > 0) {
      throw new BookingConflictError(
        'Room is not available for the selected dates. Booking conflicts with existing reservation.',
        overlapping.map((b: any) => ({
          id: b.id,
          checkIn: b.checkIn.toISOString().split('T')[0],
          checkOut: b.checkOut.toISOString().split('T')[0],
          guestName: b.guestName,
        }))
      );
    }

      try {
        const booking = await tx.booking.create({
          data: {
            roomId: input.roomId,
            guestName: input.guestName,
            guestEmail: input.guestEmail,
            checkIn: input.checkIn,
            checkOut: input.checkOut,
            status: BookingStatus.CONFIRMED,
          },
          include: { room: { include: { hotel: true } } },
        });

        logger.info({
          event: 'booking_created',
          bookingId: booking.id,
          roomId: input.roomId,
          roomNumber: room.number,
          hotelName: room.hotel.name,
          checkIn: input.checkIn.toISOString().split('T')[0],
          checkOut: input.checkOut.toISOString().split('T')[0],
          guestName: input.guestName,
        });

        return booking;
      } catch (error: unknown) {
        if (error instanceof Prisma.PrismaClientKnownRequestError) {
          if (error.code === 'P2004' || error.message.includes('no_booking_overlap')) {
            throw new BookingConflictError(
              'Room is not available for the selected dates (concurrent booking detected)'
            );
          }
        }
        throw error;
      }
    });
  }

  async cancelBooking(bookingId: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { room: { include: { hotel: true } } },
    });

    if (!booking) {
      throw new NotFoundError('Booking', bookingId);
    }

    if (booking.status === BookingStatus.CANCELLED) {
      throw new ValidationError('Booking is already cancelled');
    }

    const updated = await this.prisma.booking.update({
      where: { id: bookingId },
      data: { status: BookingStatus.CANCELLED },
      include: { room: { include: { hotel: true } } },
    });

    logger.info({
      event: 'booking_cancelled',
      bookingId: updated.id,
      roomId: updated.roomId,
      roomNumber: updated.room.number,
      hotelName: updated.room.hotel.name,
      checkIn: updated.checkIn.toISOString().split('T')[0],
      checkOut: updated.checkOut.toISOString().split('T')[0],
      guestName: updated.guestName,
    });

    return updated;
  }

  async checkAvailability(roomId: string, checkIn: Date, checkOut: Date) {
    validateDateRange(checkIn, checkOut);

    const room = await this.prisma.room.findUnique({
      where: { id: roomId },
    });

    if (!room) {
      throw new NotFoundError('Room', roomId);
    }

    const conflicts = await this.prisma.booking.findMany({
      where: {
        roomId,
        status: BookingStatus.CONFIRMED,
        checkIn: { lt: checkOut },
        checkOut: { gt: checkIn },
      },
      orderBy: { checkIn: 'asc' },
    });

    return {
      available: conflicts.length === 0,
      conflictingBookings: conflicts,
    };
  }
}
