import 'package:equatable/equatable.dart';
import 'booking.dart';

class Availability extends Equatable {
  final bool isAvailable;
  final List<Booking> conflictingBookings;

  const Availability({
    required this.isAvailable,
    this.conflictingBookings = const [],
  });

  @override
  List<Object?> get props => [isAvailable, conflictingBookings];
}
