import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/appointment_model.dart';

/// Service class for admin-specific operations.
/// Handles user management, doctor verification, content moderation,
/// and analytics for the admin dashboard.
class AdminService {
  final SupabaseClient _client = Supabase.instance.client;

  // ============= ANALYTICS =============

  /// Fetches aggregated statistics for the admin dashboard.
  /// Returns a map with various counts and metrics.
  Future<Map<String, dynamic>> getDashboardStats() async {
    return getAdminStats();
  }

  /// Fetches aggregated statistics for the admin dashboard.
  /// Returns a map with various counts and metrics.
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await _client.rpc('get_admin_stats');
      if (response != null) {
        return Map<String, dynamic>.from(response);
      }
      
      // Fallback: Manual count if function doesn't exist
      return await _getManualStats();
    } catch (e) {
      print('Error fetching admin stats: $e');
      return await _getManualStats();
    }
  }

  /// Manual stats collection as fallback
  Future<Map<String, dynamic>> _getManualStats() async {
    try {
      final usersCount = await _client.from('users').select('id').count();
      final doctorsCount = await _client.from('doctors').select('id').count();
      final petsCount = await _client.from('pets').select('id').count();
      final appointmentsCount = await _client.from('appointments').select('id').count();
      final postsCount = await _client.from('posts').select('id').count();

      return {
        'total_users': usersCount.count,
        'total_doctors': doctorsCount.count,
        'total_pets': petsCount.count,
        'total_appointments': appointmentsCount.count,
        'total_posts': postsCount.count,
      };
    } catch (e) {
      print('Error in manual stats: $e');
      return {};
    }
  }

  // ============= USER MANAGEMENT =============

  /// Fetches all users with optional pagination and filtering.
  Future<List<User>> getAllUsers({
    int page = 0,
    int limit = 20,
    String? searchQuery,
    String? roleFilter,
    bool? bannedOnly,
  }) async {
    try {
      var query = _client.from('users').select();

      // Apply search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$searchQuery%,email.ilike.%$searchQuery%,username.ilike.%$searchQuery%');
      }

      // Apply role filter
      if (roleFilter != null && roleFilter.isNotEmpty) {
        query = query.eq('role', roleFilter);
      }

      // Apply banned filter
      if (bannedOnly == true) {
        query = query.not('banned_at', 'is', null);
      }

      // Apply pagination
      final response = await query
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      return (response as List).map((json) => User.fromMap(json)).toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  /// Bans a user with a reason.
  Future<bool> banUser(String userId, String reason) async {
    try {
      final adminId = _client.auth.currentUser?.id;
      if (adminId == null) return false;

      await _client.from('users').update({
        'banned_at': DateTime.now().toIso8601String(),
        'banned_reason': reason,
        'banned_by': adminId,
      }).eq('id', userId);

      return true;
    } catch (e) {
      print('Error banning user: $e');
      return false;
    }
  }

  /// Unbans a previously banned user.
  Future<bool> unbanUser(String userId) async {
    try {
      await _client.from('users').update({
        'banned_at': null,
        'banned_reason': null,
        'banned_by': null,
      }).eq('id', userId);

      return true;
    } catch (e) {
      print('Error unbanning user: $e');
      return false;
    }
  }

  /// Updates a user's role (super admin only).
  /// Updates a user's role (super admin only).
  /// If promoting to doctor, ensures a doctor profile exists.
  Future<bool> updateUserRole(String userId, UserRole newRole) async {
    try {
      final roleString = _roleToString(newRole);
      
      // Update the user's role in the users table
      await _client.from('users').update({
        'role': roleString,
      }).eq('id', userId);

      // If promoting to doctor, ensure a record exists in the doctors table
      if (newRole == UserRole.doctor) {
        final existingDoctor = await _client
            .from('doctors')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (existingDoctor == null) {
          await _client.from('doctors').insert({
            'user_id': userId,
            'specialty': 'General', // Default, can be updated later
            'clinic': 'Not specified',
            'verified': true, // Admin manually promoted, so auto-verify
            'verified_at': DateTime.now().toIso8601String(),
            'verified_by': _client.auth.currentUser?.id,
          });
        }
      }

      return true;
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }

  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.doctor:
        return 'doctor';
      case UserRole.admin:
        return 'admin';
      case UserRole.superAdmin:
        return 'super_admin';
      default:
        return 'pet_owner';
    }
  }

  // ============= DOCTOR MANAGEMENT =============

  /// Fetches all doctors with optional filters.
  Future<List<Map<String, dynamic>>> getAllDoctors({
    int page = 0,
    int limit = 20,
    bool? verifiedOnly,
    bool? pendingOnly,
  }) async {
    try {
      var query = _client.from('doctors').select('*, users(*)');

      if (verifiedOnly == true) {
        query = query.eq('verified', true);
      } else if (pendingOnly == true) {
        query = query.eq('verified', false);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching doctors: $e');
      return [];
    }
  }

  /// Approves a doctor's application.
  Future<bool> verifyDoctor(String doctorId) async {
    try {
      final adminId = _client.auth.currentUser?.id;

      await _client.from('doctors').update({
        'verified': true,
        'verified_at': DateTime.now().toIso8601String(),
        'verified_by': adminId,
        'rejection_reason': null,
      }).eq('id', doctorId);

      return true;
    } catch (e) {
      print('Error verifying doctor: $e');
      return false;
    }
  }

  /// Rejects a doctor's application with a reason.
  Future<bool> rejectDoctor(String doctorId, String reason) async {
    try {
      final adminId = _client.auth.currentUser?.id;

      await _client.from('doctors').update({
        'verified': false,
        'rejection_reason': reason,
        'verified_by': adminId,
      }).eq('id', doctorId);

      return true;
    } catch (e) {
      print('Error rejecting doctor: $e');
      return false;
    }
  }

  // ============= CONTENT MODERATION =============

  /// Fetches all posts with optional filters for moderation.
  Future<List<Post>> getAllPosts({
    int page = 0,
    int limit = 20,
    bool? flaggedOnly,
  }) async {
    try {
      var query = _client.from('posts').select();

      if (flaggedOnly == true) {
        query = query.eq('is_flagged', true);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      return (response as List).map((json) => Post.fromMap(json)).toList();
    } catch (e) {
      print('Error fetching posts: $e');
      return [];
    }
  }

  /// Flags a post for review.
  Future<bool> flagPost(String postId, String reason) async {
    try {
      await _client.from('posts').update({
        'is_flagged': true,
        'flagged_at': DateTime.now().toIso8601String(),
        'flagged_reason': reason,
      }).eq('id', postId);

      return true;
    } catch (e) {
      print('Error flagging post: $e');
      return false;
    }
  }

  /// Removes the flag from a post (approves content).
  Future<bool> unflagPost(String postId) async {
    try {
      final adminId = _client.auth.currentUser?.id;

      await _client.from('posts').update({
        'is_flagged': false,
        'flagged_at': null,
        'flagged_reason': null,
        'moderated_by': adminId,
      }).eq('id', postId);

      return true;
    } catch (e) {
      print('Error unflagging post: $e');
      return false;
    }
  }

  /// Deletes a post (content moderation action).
  Future<bool> deletePost(String postId) async {
    try {
      // First delete related comments and likes
      await _client.from('post_comments').delete().eq('post_id', postId);
      await _client.from('post_likes').delete().eq('post_id', postId);
      
      // Then delete the post
      await _client.from('posts').delete().eq('id', postId);

      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  // ============= APPOINTMENT MANAGEMENT =============

  /// Fetches all appointments with optional filters.
  Future<List<Appointment>> getAllAppointments({
    int page = 0,
    int limit = 20,
    String? statusFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      var query = _client.from('appointments').select('*, users(*), doctors(*), pets(*)');

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }

      if (dateFrom != null) {
        query = query.gte('date', dateFrom.toIso8601String().split('T')[0]);
      }

      if (dateTo != null) {
        query = query.lte('date', dateTo.toIso8601String().split('T')[0]);
      }

      final response = await query
          .order('date', ascending: false)
          .order('time', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      return (response as List).map((json) => Appointment.fromMap(json)).toList();
    } catch (e) {
      print('Error fetching appointments: $e');
      return [];
    }
  }

  /// Cancels an appointment (admin override).
  Future<bool> cancelAppointment(String appointmentId, String reason) async {
    try {
      await _client.from('appointments').update({
        'status': 'cancelled',
      }).eq('id', appointmentId);

      // TODO: Send notification to user and doctor about cancellation with reason

      return true;
    } catch (e) {
      print('Error cancelling appointment: $e');
      return false;
    }
  }

  // ============= NOTIFICATIONS =============

  /// Sends a broadcast notification to all users or a specific segment.
  Future<bool> broadcastNotification({
    required String title,
    required String body,
    String? segment, // 'all', 'doctors', 'pet_owners'
  }) async {
    try {
      // Get target users based on segment
      List<Map<String, dynamic>> users;
      
      if (segment == 'doctors') {
        users = await _client.from('users').select('id').eq('role', 'doctor');
      } else if (segment == 'pet_owners') {
        users = await _client.from('users').select('id').eq('role', 'pet_owner');
      } else {
        users = await _client.from('users').select('id');
      }

      final adminId = _client.auth.currentUser?.id;

      // Create notifications for each user
      final notifications = users.map((user) => {
        'user_id': user['id'],
        'actor_id': adminId,
        'type': 'message',
        'title': title,
        'body': body,
        'is_read': false,
      }).toList();

      if (notifications.isNotEmpty) {
        await _client.from('notifications').insert(notifications);
      }

      return true;
    } catch (e) {
      print('Error broadcasting notification: $e');
      return false;
    }
  }

  // ============= REVIEWS MANAGEMENT =============

  /// Fetches all reviews for moderation.
  Future<List<Map<String, dynamic>>> getAllReviews({
    int page = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _client
          .from('reviews')
          .select('*, users(*)')
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching reviews: $e');
      return [];
    }
  }

  /// Deletes an inappropriate review.
  Future<bool> deleteReview(String reviewId) async {
    try {
      await _client.from('reviews').delete().eq('id', reviewId);
      return true;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }
}
