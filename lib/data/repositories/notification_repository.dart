import 'package:drift/drift.dart';
import '../local/database.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';

/// Repository for offline-first notifications
class NotificationRepository {
  final AppDatabase _db = AppDatabase.instance;
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  // Singleton
  static final NotificationRepository _instance = NotificationRepository._();
  NotificationRepository._();
  static NotificationRepository get instance => _instance;

  /// Watch notifications (local-first, reactive)
  Stream<List<LocalNotification>> watchNotifications() {
    final userId = _authService.currentUser?.id;
    if (userId == null) return Stream.value([]);
    return _db.watchNotifications(userId);
  }

  /// Get notifications from cache
  Future<List<LocalNotification>> getNotifications({bool forceRefresh = false}) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return [];

    if (!forceRefresh) {
      final local = await _db.getNotifications(userId);
      if (local.isNotEmpty) return local;
    }
    await syncNotifications();
    return _db.getNotifications(userId);
  }

  /// Sync notifications from remote to local
  Future<void> syncNotifications() async {
    try {
      // Fetch one batch of notifications
      final notifs = await _notificationService.getNotifications();
      final companions = notifs.map(_mapNotificationToCompanion).toList();
      await _db.upsertNotifications(companions);
    } catch (e) {
      // Silently fail - use cached data
    }
  }

  /// Mark notification as read (optimistic)
  Future<void> markAsRead(int notificationId) async {
    // Optimistic local update
    await _db.markNotificationRead(notificationId);
    
    // Sync to remote
    try {
      await _notificationService.markAsRead(notificationId);
    } catch (e) {
      // Leave local state
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    // Optimistic local update
    await (_db.update(_db.localNotifications)..where((n) => n.userId.equals(userId)))
        .write(const LocalNotificationsCompanion(isRead: Value(true)));

    // Sync to remote
    try {
      await _notificationService.markAllAsRead();
    } catch (e) {
      // Ignore failure, local state updated
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return 0;
    return _db.getUnreadNotificationCount(userId);
  }

  /// Map notification data to Drift companion
  LocalNotificationsCompanion _mapNotificationToCompanion(Map<String, dynamic> notif) {
    return LocalNotificationsCompanion(
      id: Value(notif['id'] as int),
      userId: Value(notif['user_id']?.toString() ?? ''),
      actorId: Value(notif['actor_id']?.toString()),
      type: Value(notif['type']?.toString() ?? 'message'),
      title: Value(notif['title']?.toString() ?? ''),
      body: Value(notif['body']?.toString() ?? ''),
      relatedId: Value(notif['related_id'] as int?),
      isRead: Value(notif['is_read'] as bool? ?? false),
      createdAt: Value(DateTime.tryParse(notif['created_at']?.toString() ?? '') ?? DateTime.now()),
      actorName: const Value(null),
      actorImage: const Value(null),
      isSynced: const Value(true),
    );
  }

  /// Convert LocalNotification to Map for UI
  Map<String, dynamic> localToMap(LocalNotification local) {
    return {
      'id': local.id,
      'user_id': local.userId,
      'actor_id': local.actorId,
      'type': local.type,
      'title': local.title,
      'body': local.body,
      'related_id': local.relatedId,
      'is_read': local.isRead,
      'created_at': local.createdAt.toIso8601String(),
    };
  }
}
