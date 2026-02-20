import { BookingStatus } from '@prisma/client';
import { BookingService } from '../../services/booking.service';
import { Context } from '../../context';

const BOOKING_CHANGED = 'BOOKING_CHANGED';

export const bookingResolvers = {
  Query: {
    bookings: async (
      _parent: unknown,
      { roomId, status }: { roomId: string; status?: BookingStatus },
      { prisma }: Context
    ) => {
      return prisma.booking.findMany({
        where: {
          roomId,
          ...(status && { status }),
        },
        orderBy: { checkIn: 'asc' },
      });
    },

    checkAvailability: async (
      _parent: unknown,
      { input }: { input: { roomId: string; checkIn: Date; checkOut: Date } },
      { prisma }: Context
    ) => {
      const service = new BookingService(prisma);
      return service.checkAvailability(input.roomId, input.checkIn, input.checkOut);
    },
  },

  Mutation: {
    createBooking: async (
      _parent: unknown,
      {
        input,
      }: {
        input: {
          roomId: string;
          checkIn: Date;
          checkOut: Date;
          guestName: string;
          guestEmail?: string;
        };
      },
      { prisma, pubsub }: Context
    ) => {
      const service = new BookingService(prisma);
      const booking = await service.createBooking({
        roomId: input.roomId,
        guestName: input.guestName,
        guestEmail: input.guestEmail,
        checkIn: input.checkIn,
        checkOut: input.checkOut,
      });

      pubsub.publish(BOOKING_CHANGED, { bookingChanged: booking });

      return {
        success: true,
        booking,
        message: 'Booking created successfully',
      };
    },

    cancelBooking: async (
      _parent: unknown,
      { input }: { input: { bookingId: string } },
      { prisma, pubsub }: Context
    ) => {
      const service = new BookingService(prisma);
      const booking = await service.cancelBooking(input.bookingId);

      pubsub.publish(BOOKING_CHANGED, { bookingChanged: booking });

      return {
        success: true,
        booking,
        message: 'Booking cancelled successfully',
      };
    },
  },

  Subscription: {
    bookingChanged: {
      subscribe: (_parent: unknown, _args: { roomId?: string }, { pubsub }: Context) => {
        return pubsub.asyncIterableIterator(BOOKING_CHANGED);
      },
    },
  },

  Booking: {
    room: async (parent: { roomId: string; room?: unknown }, _args: unknown, { loaders }: Context) => {
      if (parent.room) {
        return parent.room;
      }
      return loaders.roomLoader.load(parent.roomId);
    },
    createdAt: (parent: { createdAt: Date }) => parent.createdAt.toISOString(),
  },
};
