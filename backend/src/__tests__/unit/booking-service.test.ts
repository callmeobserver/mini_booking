import { describe, it, expect, vi, beforeEach } from 'vitest';
import { BookingService } from '../../services/booking.service.js';
import { BookingConflictError, NotFoundError, ValidationError } from '../../utils/errors.js';

// Mock Prisma
function createMockPrisma() {
  const mock = {
    room: {
      findUnique: vi.fn(),
    },
    booking: {
      findMany: vi.fn(),
      findUnique: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
    $transaction: vi.fn(async (callback) => {
      return callback(mock);
    }),
  } as any;
  return mock;
}

describe('BookingService', () => {
  let service: BookingService;
  let mockPrisma: ReturnType<typeof createMockPrisma>;

  const futureDate = (days: number) => {
    const d = new Date();
    d.setDate(d.getDate() + days);
    d.setHours(0, 0, 0, 0);
    return d;
  };

  beforeEach(() => {
    mockPrisma = createMockPrisma();
    service = new BookingService(mockPrisma);
  });

  describe('createBooking', () => {
    it('should create booking when room is available', async () => {
      const room = { id: 'room-1', number: '101', hotel: { name: 'Hotel' } };
      mockPrisma.room.findUnique.mockResolvedValue(room);
      mockPrisma.booking.findMany.mockResolvedValue([]);
      mockPrisma.booking.create.mockResolvedValue({
        id: 'booking-1',
        roomId: 'room-1',
        guestName: 'Alice',
        checkIn: futureDate(1),
        checkOut: futureDate(3),
        status: 'CONFIRMED',
        room: { number: '101', hotel: { name: 'Hotel' } },
      });

      const result = await service.createBooking({
        roomId: 'room-1',
        guestName: 'Alice',
        checkIn: futureDate(1),
        checkOut: futureDate(3),
      });

      expect(result.id).toBe('booking-1');
      expect(result.guestName).toBe('Alice');
    });

    it('should throw NotFoundError for non-existent room', async () => {
      mockPrisma.room.findUnique.mockResolvedValue(null);

      await expect(
        service.createBooking({
          roomId: 'nonexistent',
          guestName: 'Alice',
          checkIn: futureDate(1),
          checkOut: futureDate(3),
        })
      ).rejects.toThrow(NotFoundError);
    });

    it('should throw BookingConflictError when dates overlap', async () => {
      const room = { id: 'room-1', number: '101', hotel: { name: 'Hotel' } };
      mockPrisma.room.findUnique.mockResolvedValue(room);
      mockPrisma.booking.findMany.mockResolvedValue([
        {
          id: 'existing',
          checkIn: futureDate(2),
          checkOut: futureDate(5),
          guestName: 'Bob',
        },
      ]);

      await expect(
        service.createBooking({
          roomId: 'room-1',
          guestName: 'Alice',
          checkIn: futureDate(1),
          checkOut: futureDate(4),
        })
      ).rejects.toThrow(BookingConflictError);
    });
  });

  describe('cancelBooking', () => {
    it('should cancel existing CONFIRMED booking', async () => {
      const booking = {
        id: 'booking-1',
        roomId: 'room-1',
        status: 'CONFIRMED',
        guestName: 'Alice',
        checkIn: futureDate(1),
        checkOut: futureDate(3),
        room: { number: '101', hotel: { name: 'Hotel' } },
      };
      mockPrisma.booking.findUnique.mockResolvedValue(booking);
      mockPrisma.booking.update.mockResolvedValue({
        ...booking,
        status: 'CANCELLED',
      });

      const result = await service.cancelBooking('booking-1');
      expect(result.status).toBe('CANCELLED');
    });

    it('should throw NotFoundError for non-existent booking', async () => {
      mockPrisma.booking.findUnique.mockResolvedValue(null);
      await expect(service.cancelBooking('nonexistent')).rejects.toThrow(NotFoundError);
    });

    it('should throw ValidationError for already cancelled booking', async () => {
      mockPrisma.booking.findUnique.mockResolvedValue({
        id: 'booking-1',
        status: 'CANCELLED',
      });
      await expect(service.cancelBooking('booking-1')).rejects.toThrow(ValidationError);
    });
  });

  describe('checkAvailability', () => {
    it('should return available=true when no conflicts', async () => {
      mockPrisma.room.findUnique.mockResolvedValue({ id: 'room-1' });
      mockPrisma.booking.findMany.mockResolvedValue([]);

      const result = await service.checkAvailability('room-1', futureDate(1), futureDate(3));
      expect(result.available).toBe(true);
      expect(result.conflictingBookings).toHaveLength(0);
    });

    it('should return available=false with conflicts', async () => {
      mockPrisma.room.findUnique.mockResolvedValue({ id: 'room-1' });
      mockPrisma.booking.findMany.mockResolvedValue([
        { id: 'b1', checkIn: futureDate(2), checkOut: futureDate(5) },
      ]);

      const result = await service.checkAvailability('room-1', futureDate(1), futureDate(4));
      expect(result.available).toBe(false);
      expect(result.conflictingBookings).toHaveLength(1);
    });
  });
});
