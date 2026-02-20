import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../../domain/entities/hotel.dart';
import '../../../../domain/entities/booking.dart';
import '../../../../domain/entities/room.dart';
import '../../../../domain/repositories/hotel_repository.dart';
import '../../../../domain/repositories/booking_repository.dart';

// Events
sealed class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class DashboardLoadRequested extends DashboardEvent {
  const DashboardLoadRequested();
}

class DashboardRefreshRequested extends DashboardEvent {
  const DashboardRefreshRequested();
}

// Data classes
class RoomStatus extends Equatable {
  final Room room;
  final bool isOccupiedToday;
  final Booking? nearestUpcomingBooking;

  const RoomStatus({
    required this.room,
    required this.isOccupiedToday,
    this.nearestUpcomingBooking,
  });

  @override
  List<Object?> get props => [room, isOccupiedToday, nearestUpcomingBooking];
}

class HotelStatus extends Equatable {
  final Hotel hotel;
  final List<RoomStatus> roomStatuses;

  const HotelStatus({required this.hotel, required this.roomStatuses});

  @override
  List<Object?> get props => [hotel, roomStatuses];
}

// States
sealed class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final List<HotelStatus> hotelStatuses;
  final DateTime lastRefreshed;

  const DashboardLoaded({required this.hotelStatuses, required this.lastRefreshed});

  @override
  List<Object?> get props => [hotelStatuses, lastRefreshed];
}

class DashboardError extends DashboardState {
  final Failure failure;
  const DashboardError(this.failure);
  @override
  List<Object?> get props => [failure];
}

// Bloc
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final HotelRepository _hotelRepository;
  final BookingRepository _bookingRepository;

  DashboardBloc({
    required HotelRepository hotelRepository,
    required BookingRepository bookingRepository,
  })  : _hotelRepository = hotelRepository,
        _bookingRepository = bookingRepository,
        super(const DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoadRequested);
    on<DashboardRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadRequested(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    await _loadDashboard(emit);
  }

  Future<void> _onRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    await _loadDashboard(emit);
  }

  Future<void> _loadDashboard(Emitter<DashboardState> emit) async {
    final hotelsResult = await _hotelRepository.getHotels();

    switch (hotelsResult) {
      case Fail(failure: final failure):
        emit(DashboardError(failure));
        return;
      case Success(data: final hotels):
        final hotelStatuses = <HotelStatus>[];

        for (final hotel in hotels) {
          final roomStatuses = <RoomStatus>[];

          for (final room in hotel.rooms) {
            final bookingsResult = await _bookingRepository.getBookingsForRoom(room.id);
            final bookings = switch (bookingsResult) {
              Success(data: final b) => b,
              Fail() => <Booking>[],
            };

            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final tomorrow = today.add(const Duration(days: 1));

            final isOccupied = bookings.any((b) =>
                b.status == BookingStatus.confirmed &&
                b.checkIn.isBefore(tomorrow) &&
                b.checkOut.isAfter(today));

            final futureBookings = bookings
                .where((b) => b.status == BookingStatus.confirmed && b.checkIn.isAfter(today))
                .toList()
              ..sort((a, b) => a.checkIn.compareTo(b.checkIn));

            roomStatuses.add(RoomStatus(
              room: room,
              isOccupiedToday: isOccupied,
              nearestUpcomingBooking: futureBookings.isNotEmpty ? futureBookings.first : null,
            ));
          }

          hotelStatuses.add(HotelStatus(hotel: hotel, roomStatuses: roomStatuses));
        }

        emit(DashboardLoaded(
          hotelStatuses: hotelStatuses,
          lastRefreshed: DateTime.now(),
        ));
    }
  }
}
