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
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': name,
        'username': username,
      },
    );
    
    // Also explicitly insert into public.users if a trigger doesn't do it.
    // Assuming backend trigger handles sync from auth.users to public.users?
    // If not, we should do it here. 
    // Standard Zovetica pattern: triggers do it. 
    // BUT we need to ensure 'username' gets to public.users.
    // If the trigger copies ALL specific metadata fields, we are good.
    // If not, we might need a manual update.
    // Let's assume trigger copies 'username' if present in metadata, OR we update manually.
    
    // Safer approach: manual upsert to public.users after signup (if trigger isn't perfect)
    /*
    if (response.user != null) {
       await _client.from('users').upsert({
         'id': response.user!.id,
         'email': email,
         'name': name,
         'username': username,
         'role': 'pet_owner',
       });
    }
    */
    
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
