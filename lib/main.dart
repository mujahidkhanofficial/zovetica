import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pets_and_vets/screens/auth_screen.dart';
import 'package:pets_and_vets/screens/main_screen.dart';
import 'package:pets_and_vets/services/auth_service.dart';
import 'package:pets_and_vets/services/supabase_service.dart';
import 'package:pets_and_vets/core/network/connectivity_service.dart';
import 'package:pets_and_vets/core/sync/sync_engine.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

// Global navigator key for navigation from anywhere (e.g., notifications)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await SupabaseService.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Initialize offline-first infrastructure
  await ConnectivityService.instance.initialize();
  await SyncEngine.instance.initialize();

  runApp(const PetsAndVetsApp());
}


class PetsAndVetsApp extends StatelessWidget {
  final AuthService? authService;

  const PetsAndVetsApp({super.key, this.authService});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Pets & Vets',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: SplashScreen(authService: authService),
      debugShowCheckedModeBanner: false,
      routes: {
        '/auth': (context) => const AuthScreen(), // To be created
        '/main': (context) =>
            const MainScreen(),
      },
    );
  }
}
