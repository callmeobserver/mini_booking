import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../graphql/graphql_client.dart';
import '../../data/repositories/hotel_repository_impl.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../domain/repositories/hotel_repository.dart';
import '../../domain/repositories/booking_repository.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // GraphQL Client
  final graphqlClient = createGraphQLClient();
  getIt.registerSingleton<ValueNotifier<GraphQLClient>>(graphqlClient);
  getIt.registerSingleton<GraphQLClient>(graphqlClient.value);

  // Repositories
  getIt.registerLazySingleton<HotelRepository>(
    () => HotelRepositoryImpl(getIt<GraphQLClient>()),
  );
  getIt.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(getIt<GraphQLClient>()),
  );
}
