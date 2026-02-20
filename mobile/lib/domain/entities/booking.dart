import 'package:equatable/equatable.dart';

enum BookingStatus { confirmed, cancelled }

class Booking extends Equatable {
  final String id;
  final String roomId;
  final String guestName;
  final String? guestEmail;
  final DateTime checkIn;
  final DateTime checkOut;
  final BookingStatus status;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.roomId,
    required this.guestName,
    this.guestEmail,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, roomId, guestName, guestEmail, checkIn, checkOut, status, createdAt];
}
