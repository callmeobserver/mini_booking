import 'package:equatable/equatable.dart';
import 'room.dart';

class Hotel extends Equatable {
  final String id;
  final String name;
  final String address;
  final int starRating;
  final String? imageUrl;
  final List<Room> rooms;

  const Hotel({
    required this.id,
    required this.name,
    required this.address,
    required this.starRating,
    this.imageUrl,
    this.rooms = const [],
  });

  @override
  List<Object?> get props => [id, name, address, starRating, imageUrl, rooms];
}
