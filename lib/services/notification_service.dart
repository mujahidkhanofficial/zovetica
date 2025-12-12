import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class NotificationService {
  final SupabaseClient _client;

  NotificationService({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  /// Fetch Notifications Stream
  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((maps) => maps);
  }

  /// Get unread notification count stream
  Stream<int> getUnreadCountStream() {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return Stream.value(0);

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((notifications) => notifications.where((n) => n['is_read'] == false).length);
  }

  /// Create a notification for a target user
  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? relatedId,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'type': type,
        'title': title,
        'body': body,
        'related_id': relatedId,
        'is_read': false,
      });
    } catch (e) {
      // Silently fail - notifications are not critical
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;
    
    await _client.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }
  
  /// Mark all as read
  Future<void> markAllAsRead() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;
    
    await _client.from('notifications').update({'is_read': true}).eq('user_id', userId);
  }
}

