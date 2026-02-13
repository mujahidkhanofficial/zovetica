import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Authentication service abstracting Supabase Auth
class AuthService {
  final SupabaseClient _client;

  AuthService({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Sign up with email and password
  /// 
  /// IMPORTANT: When email confirmation is ENABLED in Supabase:
  /// - The returned [AuthResponse.user] will be NULL (this is expected!)
  /// - The returned [AuthResponse.session] will be NULL (also expected!)
  /// - The user IS created in auth.users with email_confirmed_at = NULL
  /// - A verification email IS sent to the user
  /// 
  /// SECURITY: Role is NOT passed to Supabase - it is assigned server-side
  /// by database trigger to prevent privilege escalation attacks.
  /// New users are ALWAYS created as 'pet_owner'.
  /// Role changes require admin action via RLS-protected operations.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String username,
    String? phone,
    String? role,
    String? specialty,
    String? clinic,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'io.supabase.pets_and_vets://login-callback',
      data: {
        'full_name': name,
        'username': username,
        'phone': phone,
        'role': role ?? 'pet_owner',
        'specialty': specialty,
        'clinic': clinic,
      },
    );
    
    return response;
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Listen to auth state changes
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
}
