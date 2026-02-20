import { BookingStatus } from '@prisma/client';
import { Context } from '../../context';

export const roomResolvers = {
  Query: {
    rooms: async (_parent: unknown, { hotelId }: { hotelId: string }, { prisma }: Context) => {
      return prisma.room.findMany({
        where: { hotelId },
        orderBy: { number: 'asc' },
      });
    },

    room: async (_parent: unknown, { id }: { id: string }, { prisma }: Context) => {
      return prisma.room.findUnique({
        where: { id },
        include: { hotel: true },
      });
    },
  },

  Room: {
    hotel: async (parent: { id: string; hotelId: string; hotel?: unknown }, _args: unknown, { loaders }: Context) => {
      if (parent.hotel) {
        return parent.hotel;
      }
      return loaders.hotelLoader.load(parent.hotelId);
    },

    bookings: async (
      parent: { id: string },
      args: { status?: BookingStatus },
      { prisma }: Context
    ) => {
      return prisma.booking.findMany({
        where: {
          roomId: parent.id,
          ...(args.status && { status: args.status }),
        },
        orderBy: { checkIn: 'asc' },
      });
    },
  },
};
