import 'package:drift/drift.dart';
import '../local/database.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';

/// Repository for offline-first user profile management
class UserRepository {
  final AppDatabase _db = AppDatabase.instance;
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  // Singleton
  static final UserRepository _instance = UserRepository._();
  UserRepository._();
  static UserRepository get instance => _instance;

  /// Watch current user profile (local-first, reactive)
  Stream<LocalUser?> watchCurrentUser() {
    final userId = _authService.currentUser?.id;
    if (userId == null) return Stream.value(null);
    return _db.watchUser(userId);
  }

  /// Watch any user by ID
  Stream<LocalUser?> watchUser(String userId) {
    return _db.watchUser(userId);
  }

  /// Get current user from local cache or remote
  Future<LocalUser?> getCurrentUser({bool forceRefresh = false}) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return null;

    // Try local first
    if (!forceRefresh) {
      final local = await _db.getUser(userId);
      if (local != null) return local;
    }

    // Fetch from remote and cache
    await syncUser(userId);
    return _db.getUser(userId);
  }

  /// Get any user by ID
  Future<LocalUser?> getUser(String userId, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final local = await _db.getUser(userId);
      if (local != null) return local;
    }
    await syncUser(userId);
    return _db.getUser(userId);
  }

  /// Sync a specific user from remote to local
  Future<void> syncUser(String userId) async {
    try {
      final userData = await _userService.getUserById(userId);
      if (userData != null) {
        await _db.upsertUser(_mapUserToCompanion(userData));
      }
    } catch (e) {
      // Silently fail on network errors - use cached data
    }
  }

  /// Update current user profile (optimistic + sync)
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? profileImage,
    String? bio,
    String? username,
  }) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return false;

    // Optimistic local update
    final current = await _db.getUser(userId);
    if (current != null) {
      await _db.upsertUser(LocalUsersCompanion(
        id: Value(userId),
        email: Value(current.email),
        name: Value(name ?? current.name),
        phone: Value(phone ?? current.phone),
        profileImage: Value(profileImage ?? current.profileImage),
        bio: Value(bio ?? current.bio),
        username: Value(username ?? current.username),
        role: Value(current.role),
        createdAt: Value(current.createdAt),
        isSynced: const Value(false),
        localUpdatedAt: Value(DateTime.now()),
      ));
    }

    // Sync to remote
    try {
      await _userService.updateUser(
        userId: userId,
        name: name,
        phone: phone,
        profileImage: profileImage,
      );
      
      // Mark as synced
      if (current != null) {
        await _db.upsertUser(LocalUsersCompanion(
          id: Value(userId),
          email: Value(current.email),
          isSynced: const Value(true),
        ));
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Map Supabase user data to Drift companion
  LocalUsersCompanion _mapUserToCompanion(Map<String, dynamic> data) {
    return LocalUsersCompanion(
      id: Value(data['id'] as String),
      email: Value(data['email'] as String? ?? ''),
      name: Value(data['name'] as String?),
      phone: Value(data['phone'] as String?),
      role: Value(data['role'] as String? ?? 'pet_owner'),
      profileImage: Value(data['profile_image'] as String?),
      specialty: Value(data['specialty'] as String?),
      clinic: Value(data['clinic'] as String?),
      bio: Value(data['bio'] as String?),
      username: Value(data['username'] as String?),
      rating: Value((data['rating'] as num?)?.toDouble()),
      reviewsCount: Value(data['reviews_count'] as int? ?? 0),
      createdAt: Value(DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now()),
      isSynced: const Value(true),
    );
  }
}
