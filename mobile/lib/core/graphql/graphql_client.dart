import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../constants/api_constants.dart';
import 'dart:io' show Platform;

ValueNotifier<GraphQLClient> createGraphQLClient() {
  final String endpoint;

  if (Platform.isAndroid) {
    endpoint = ApiConstants.graphqlEndpoint;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    endpoint = ApiConstants.graphqlEndpointDesktop;
  } else {
    endpoint = ApiConstants.graphqlEndpointWeb;
  }

  final HttpLink httpLink = HttpLink(endpoint);

  return ValueNotifier(
    GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(store: InMemoryStore()),
    ),
  );
}
