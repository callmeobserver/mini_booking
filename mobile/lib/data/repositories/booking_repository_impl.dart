import 'package:graphql_flutter/graphql_flutter.dart';
import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/availability.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../graphql/queries.dart';

class BookingRepositoryImpl implements BookingRepository {
  final GraphQLClient _client;

  BookingRepositoryImpl(this._client);

  @override
  Future<Result<List<Booking>>> getBookingsForRoom(String roomId) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(getBookingsQuery),
          variables: {'roomId': roomId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        return Fail(ServerFailure(
          result.exception?.graphqlErrors.firstOrNull?.message ?? 'Failed to load bookings',
        ));
      }

      final bookings = (result.data?['bookings'] as List<dynamic>?)
              ?.map((json) => _parseBooking(json as Map<String, dynamic>, roomId))
              .toList() ??
          [];

      return Success(bookings);
    } catch (e) {
      return Fail(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Result<Availability>> checkAvailability({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(checkAvailabilityQuery),
          variables: {
            'input': {
              'roomId': roomId,
              'checkIn': _formatDate(checkIn),
              'checkOut': _formatDate(checkOut),
            },
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        final message = result.exception?.graphqlErrors.firstOrNull?.message ??
            'Failed to check availability';
        return Fail(ServerFailure(message));
      }

      final data = result.data?['checkAvailability'] as Map<String, dynamic>;
      final available = data['available'] as bool;
      final conflicts = (data['conflictingBookings'] as List<dynamic>?)
              ?.map((json) => _parseBooking(json as Map<String, dynamic>, roomId))
              .toList() ??
          [];

      return Success(Availability(
        isAvailable: available,
        conflictingBookings: conflicts,
      ));
    } catch (e) {
      return Fail(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Result<Booking>> createBooking({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    required String guestName,
  }) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(createBookingMutation),
          variables: {
            'input': {
              'roomId': roomId,
              'checkIn': _formatDate(checkIn),
              'checkOut': _formatDate(checkOut),
              'guestName': guestName,
            },
          },
        ),
      );

      if (result.hasException) {
        final message = result.exception?.graphqlErrors.firstOrNull?.message ??
            'Failed to create booking';
        final code = result.exception?.graphqlErrors.firstOrNull?.extensions?['code'];
        if (code == 'BOOKING_CONFLICT') {
          return Fail(BookingConflictFailure(message));
        }
        return Fail(ServerFailure(message));
      }

      final data = result.data?['createBooking'] as Map<String, dynamic>;
      final success = data['success'] as bool;

      if (!success) {
        return Fail(ServerFailure(data['message'] as String));
      }

      final bookingData = data['booking'] as Map<String, dynamic>;
      return Success(_parseBooking(bookingData, roomId));
    } catch (e) {
      return Fail(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Result<Booking>> cancelBooking(String bookingId) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(cancelBookingMutation),
          variables: {
            'input': {
              'bookingId': bookingId,
            },
          },
        ),
      );

      if (result.hasException) {
        return Fail(ServerFailure(
          result.exception?.graphqlErrors.firstOrNull?.message ?? 'Failed to cancel booking',
        ));
      }

      final data = result.data?['cancelBooking'] as Map<String, dynamic>;
      final bookingData = data['booking'] as Map<String, dynamic>;
      return Success(_parseBooking(bookingData, ''));
    } catch (e) {
      return Fail(NetworkFailure(e.toString()));
    }
  }

  Booking _parseBooking(Map<String, dynamic> json, String roomId) {
    return Booking(
      id: json['id'] as String,
      roomId: json['roomId']?.toString() ?? roomId,
      guestName: json['guestName'] as String,
      guestEmail: json['guestEmail'] as String?,
      checkIn: DateTime.parse(json['checkIn'] as String),
      checkOut: DateTime.parse(json['checkOut'] as String),
      status: (json['status'] as String).toUpperCase() == 'CONFIRMED'
          ? BookingStatus.confirmed
          : BookingStatus.cancelled,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
