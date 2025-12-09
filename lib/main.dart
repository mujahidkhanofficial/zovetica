import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zovetica/screens/auth_screen.dart';
import 'package:zovetica/screens/main_screen.dart';
import 'package:zovetica/services/supabase_service.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  // TODO: Replace with your actual Supabase credentials
  await SupabaseService.initialize(
    url: 'https://stwqqpnocgonkavteufx.supabase.co', // e.g., 'https://xxxx.supabase.co'
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN0d3FxcG5vY2dvbmthdnRldWZ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyMTE3ODYsImV4cCI6MjA4MDc4Nzc4Nn0.dUJrQnbCh8ie4YRKYYqhOuOL3ZSkF_KggyWbnVqxn5M',
  );

  runApp(const ZoveticaApp());
}

class ZoveticaApp extends StatelessWidget {
  const ZoveticaApp({super.key});

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
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/auth': (context) => const AuthScreen(), // To be created
        '/main': (context) =>
            const MainScreen(), // Firebase integrated main screen
      },
    );
  }
}
