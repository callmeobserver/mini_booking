import 'package:graphql_flutter/graphql_flutter.dart';
import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/hotel_repository.dart';
import '../graphql/queries.dart';

class HotelRepositoryImpl implements HotelRepository {
  final GraphQLClient _client;

  HotelRepositoryImpl(this._client);

  @override
  Future<Result<List<Hotel>>> getHotels() async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(getHotelsQuery),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        return Fail(ServerFailure(
          result.exception?.graphqlErrors.firstOrNull?.message ?? 'Failed to load hotels',
        ));
      }

      final hotels = (result.data?['hotels'] as List<dynamic>?)
              ?.map((json) => _parseHotel(json as Map<String, dynamic>))
              .toList() ??
          [];

      return Success(hotels);
    } catch (e) {
      return Fail(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Result<Hotel>> getHotelById(String id) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(getHotelQuery),
          variables: {'id': id},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        return Fail(ServerFailure(
          result.exception?.graphqlErrors.firstOrNull?.message ?? 'Failed to load hotel',
        ));
      }

      final hotelData = result.data?['hotel'] as Map<String, dynamic>?;
      if (hotelData == null) {
        return const Fail(ServerFailure('Hotel not found'));
      }

      return Success(_parseHotel(hotelData));
    } catch (e) {
      return Fail(NetworkFailure(e.toString()));
    }
  }

  Hotel _parseHotel(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      starRating: json['starRating'] as int,
      imageUrl: json['imageUrl'] as String?,
      rooms: (json['rooms'] as List<dynamic>?)
              ?.map((r) => _parseRoom(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Room _parseRoom(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      hotelId: json['hotelId']?.toString() ?? '',
      number: json['number'] as String,
      type: json['type'] as String,
      pricePerNight: (json['pricePerNight'] as num).toDouble(),
      capacity: json['capacity'] as int,
      description: json['description'] as String?,
    );
  }
}
