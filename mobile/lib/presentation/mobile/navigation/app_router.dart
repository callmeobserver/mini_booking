import 'package:go_router/go_router.dart';
import '../hotels/hotels_screen.dart';
import '../rooms/rooms_screen.dart';
import '../room_detail/room_detail_screen.dart';

final mobileRouter = GoRouter(
  initialLocation: '/hotels',
  routes: [
    GoRoute(
      path: '/hotels',
      builder: (context, state) => const HotelsScreen(),
      routes: [
        GoRoute(
          path: ':hotelId/rooms',
          builder: (context, state) {
            final hotelId = state.pathParameters['hotelId']!;
            final hotelName = state.extra as String? ?? '';
            return RoomsScreen(hotelId: hotelId, hotelName: hotelName);
          },
          routes: [
            GoRoute(
              path: ':roomId',
              builder: (context, state) {
                final roomId = state.pathParameters['roomId']!;
                final extra = state.extra as Map<String, String>?;
                return RoomDetailScreen(
                  roomId: roomId,
                  roomNumber: extra?['roomNumber'],
                  roomType: extra?['roomType'],
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
