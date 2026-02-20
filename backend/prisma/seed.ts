import { PrismaClient, RoomType, BookingStatus } from '@prisma/client';
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';

const connectionString = `${process.env.DATABASE_URL}`;
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

function daysFromNow(days: number): Date {
  const d = new Date();
  d.setDate(d.getDate() + days);
  d.setHours(0, 0, 0, 0);
  return d;
}

async function main() {
  const hotel1 = await prisma.hotel.upsert({
    where: { id: 'a1b2c3d4-0001-4000-8000-000000000001' },
    update: {},
    create: {
      id: 'hotel-1',
      name: 'Grand Palace Hotel',
      address: '123 Main Street, New York, NY 10001',
      starRating: 5,
      imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800',
    },
  });

  const hotel2 = await prisma.hotel.upsert({
    where: { id: 'a1b2c3d4-0002-4000-8000-000000000002' },
    update: {},
    create: {
      id: 'hotel-2',
      name: 'Cozy Inn',
      address: '456 Beach Road, Miami, FL 33101',
      starRating: 3,
      imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800',
    },
  });

  const rooms = [
    {
      id: 'room-101',
      hotelId: hotel1.id,
      number: '101',
      type: RoomType.STANDARD,
      pricePerNight: 150.0,
      capacity: 2,
      description: 'Comfortable standard room with city view',
    },
    {
      id: 'room-201',
      hotelId: hotel1.id,
      number: '201',
      type: RoomType.DELUXE,
      pricePerNight: 280.0,
      capacity: 2,
      description: 'Spacious deluxe room with panoramic windows',
    },
    {
      id: 'room-301',
      hotelId: hotel1.id,
      number: '301',
      type: RoomType.SUITE,
      pricePerNight: 500.0,
      capacity: 4,
      description: 'Luxury suite with separate living area',
    },
    {
      id: 'room-1a',
      hotelId: hotel2.id,
      number: '1A',
      type: RoomType.STANDARD,
      pricePerNight: 89.0,
      capacity: 2,
      description: 'Beachside standard room with ocean sounds',
    },
    {
      id: 'room-2a',
      hotelId: hotel2.id,
      number: '2A',
      type: RoomType.STANDARD,
      pricePerNight: 95.0,
      capacity: 2,
      description: 'Standard room with garden view',
    },
    {
      id: 'room-3a',
      hotelId: hotel2.id,
      number: '3A',
      type: RoomType.DELUXE,
      pricePerNight: 175.0,
      capacity: 3,
      description: 'Deluxe ocean-view room with balcony',
    },
  ];

  for (const room of rooms) {
    await prisma.room.upsert({
      where: { id: room.id },
      update: {},
      create: room,
    });
  }

  const bookings = [
    {
      id: 'booking-1',
      roomId: rooms[0].id,
      guestName: 'Alice Johnson',
      guestEmail: 'alice@example.com',
      checkIn: daysFromNow(1),
      checkOut: daysFromNow(5),
      status: BookingStatus.CONFIRMED,
    },
    {
      id: 'booking-2',
      roomId: rooms[0].id,
      guestName: 'Bob Smith',
      guestEmail: 'bob@example.com',
      checkIn: daysFromNow(7),
      checkOut: daysFromNow(10),
      status: BookingStatus.CONFIRMED,
    },
    {
      id: 'booking-3',
      roomId: rooms[1].id,
      guestName: 'Carol Davis',
      guestEmail: 'carol@example.com',
      checkIn: daysFromNow(2),
      checkOut: daysFromNow(6),
      status: BookingStatus.CONFIRMED,
    },
    {
      id: 'booking-4',
      roomId: rooms[3].id,
      guestName: 'David Wilson',
      guestEmail: 'david@example.com',
      checkIn: daysFromNow(3),
      checkOut: daysFromNow(8),
      status: BookingStatus.CONFIRMED,
    },
    {
      id: 'booking-5',
      roomId: rooms[3].id,
      guestName: 'Eve Martinez',
      guestEmail: 'eve@example.com',
      checkIn: daysFromNow(1),
      checkOut: daysFromNow(3),
      status: BookingStatus.CANCELLED,
    },
  ];

  for (const booking of bookings) {
    await prisma.booking.upsert({
      where: { id: booking.id },
      update: {},
      create: booking,
    });
  }

  console.log('Seed data inserted successfully:');
  console.log(`  Hotels: 2`);
  console.log(`  Rooms: ${rooms.length}`);
  console.log(`  Bookings: ${bookings.length} (${bookings.filter((b) => b.status === 'CONFIRMED').length} confirmed, ${bookings.filter((b) => b.status === 'CANCELLED').length} cancelled)`);
}

main()
  .catch((e) => {
    console.error('Seed failed:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
