import 'package:equatable/equatable.dart';

class Room extends Equatable {
  final String id;
  final String hotelId;
  final String number;
  final String type;
  final double pricePerNight;
  final int capacity;
  final String? description;

  const Room({
    required this.id,
    required this.hotelId,
    required this.number,
    required this.type,
    required this.pricePerNight,
    required this.capacity,
    this.description,
  });

  @override
  List<Object?> get props => [id, hotelId, number, type, pricePerNight, capacity, description];
}
