import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'presentation/mobile/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHiveForFlutter();
  await setupServiceLocator();
  runApp(const MobileApp());
}

class MobileApp extends StatelessWidget {
  const MobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: getIt<ValueNotifier<GraphQLClient>>(),
      child: MaterialApp.router(
        title: 'Mini Booking',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.mobile,
        routerConfig: mobileRouter,
      ),
    );
  }
}
