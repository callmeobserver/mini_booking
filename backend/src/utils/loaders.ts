import DataLoader from 'dataloader';
import { PrismaClient, Room, Hotel } from '@prisma/client';

export interface DataLoaders {
  hotelRoomsLoader: DataLoader<string, Room[]>;
  roomLoader: DataLoader<string, Room>;
  hotelLoader: DataLoader<string, Hotel>;
}

export function createLoaders(prisma: PrismaClient): DataLoaders {
  return {
    hotelRoomsLoader: new DataLoader<string, Room[]>(async (hotelIds) => {
      const rooms = await prisma.room.findMany({
        where: { hotelId: { in: hotelIds as string[] } },
        orderBy: { number: 'asc' },
      });

      const roomsByHotel = rooms.reduce((acc, room) => {
        if (!acc[room.hotelId]) acc[room.hotelId] = [];
        acc[room.hotelId].push(room);
        return acc;
      }, {} as Record<string, Room[]>);

      return hotelIds.map((id) => roomsByHotel[id] || []);
    }),

    roomLoader: new DataLoader<string, Room>(async (roomIds) => {
      const rooms = await prisma.room.findMany({
        where: { id: { in: roomIds as string[] } },
      });

      const roomById = rooms.reduce((acc, room) => {
        acc[room.id] = room;
        return acc;
      }, {} as Record<string, Room>);

      return roomIds.map(
        (id) => roomById[id] || new Error(`Room not found: ${id}`)
      );
    }),

    hotelLoader: new DataLoader<string, Hotel>(async (hotelIds) => {
      const hotels = await prisma.hotel.findMany({
        where: { id: { in: hotelIds as string[] } },
      });

      const hotelById = hotels.reduce((acc, hotel) => {
        acc[hotel.id] = hotel;
        return acc;
      }, {} as Record<string, Hotel>);

      return hotelIds.map(
        (id) => hotelById[id] || new Error(`Hotel not found: ${id}`)
      );
    }),
  };
}
