import '../../core/utils/result.dart';
import '../entities/availability.dart';
import '../entities/booking.dart';

abstract interface class BookingRepository {
  Future<Result<List<Booking>>> getBookingsForRoom(String roomId);
  Future<Result<Availability>> checkAvailability({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  });
  Future<Result<Booking>> createBooking({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    required String guestName,
  });
  Future<Result<Booking>> cancelBooking(String bookingId);
}
