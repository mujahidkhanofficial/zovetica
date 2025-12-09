import 'supabase_service.dart';

/// User profile service for CRUD operations
class UserService {
  final _client = SupabaseService.client;
  static const String _tableName = 'users';

  /// Create a new user profile
  Future<void> createUser({
    required String id,
    required String email,
    required String name,
    required String phone,
    required String role,
    String? specialty,
    String? clinic,
    String? bio,
    String? profileImage,
  }) async {
    await _client.from(_tableName).insert({
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'specialty': specialty,
      'clinic': clinic,
      'bio': bio,
      'profile_image': profileImage,
    });
  }

  /// Get user by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  /// Get current user profile
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return null;
    return getUserById(userId);
  }

  /// Update user profile
  Future<void> updateUser({
    required String userId,
    String? name,
    String? phone,
    String? specialty,
    String? clinic,
    String? bio,
    String? profileImage,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (specialty != null) updates['specialty'] = specialty;
    if (clinic != null) updates['clinic'] = clinic;
    if (bio != null) updates['bio'] = bio;
    if (profileImage != null) updates['profile_image'] = profileImage;

    if (updates.isNotEmpty) {
      await _client.from(_tableName).update(updates).eq('id', userId);
    }
  }

  /// Get user role
  Future<String?> getUserRole(String userId) async {
    final user = await getUserById(userId);
    return user?['role'] as String?;
  }
}
