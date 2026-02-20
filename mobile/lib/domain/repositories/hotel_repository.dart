import '../../core/utils/result.dart';
import '../entities/hotel.dart';

abstract interface class HotelRepository {
  Future<Result<List<Hotel>>> getHotels();
  Future<Result<Hotel>> getHotelById(String id);
}
