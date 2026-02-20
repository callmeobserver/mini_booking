import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'presentation/desktop/dashboard/dashboard_screen.dart';
import 'presentation/desktop/room_detail/desktop_room_detail_screen.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHiveForFlutter();
  await setupServiceLocator();
  runApp(const DesktopApp());
}

class DesktopApp extends StatelessWidget {
  const DesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: getIt<ValueNotifier<GraphQLClient>>(),
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Mini Booking Widget',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.desktop,
        home: DashboardScreen(
          onRoomTap: (roomId) {
            _navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => DesktopRoomDetailScreen(roomId: roomId),
              ),
            );
          },
        ),
      ),
    );
  }
}
