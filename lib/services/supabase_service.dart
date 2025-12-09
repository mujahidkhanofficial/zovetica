import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Supabase service for initialization and client access
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase - call this in main.dart before runApp()
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  /// Get the current authenticated user
  static User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Listen to auth state changes
  static Stream<AuthState> get onAuthStateChange =>
      client.auth.onAuthStateChange;
}
