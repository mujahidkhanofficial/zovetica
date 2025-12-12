import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zovetica/screens/auth_screen.dart';
import 'package:zovetica/screens/main_screen.dart';
import 'package:zovetica/services/auth_service.dart';
import 'package:zovetica/services/supabase_service.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await SupabaseService.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const ZoveticaApp());
}

class ZoveticaApp extends StatelessWidget {
  final AuthService? authService;

  const ZoveticaApp({super.key, this.authService});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      title: 'Zovetica',
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
