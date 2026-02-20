import { Context } from '../../context';

export const hotelResolvers = {
  Query: {
    hotels: async (_parent: unknown, _args: unknown, { prisma }: Context) => {
      return prisma.hotel.findMany({
        include: { rooms: true },
        orderBy: { name: 'asc' },
      });
    },

    hotel: async (_parent: unknown, { id }: { id: string }, { prisma }: Context) => {
      return prisma.hotel.findUnique({
        where: { id },
        include: { rooms: true },
      });
    },
  },

  Hotel: {
    rooms: async (parent: { id: string; rooms?: unknown[] }, _args: unknown, { loaders }: Context) => {
      if (parent.rooms && parent.rooms.length > 0) {
        return parent.rooms;
      }
      return loaders.hotelRoomsLoader.load(parent.id);
    },
    createdAt: (parent: { createdAt: Date }) => parent.createdAt.toISOString(),
  },
};
