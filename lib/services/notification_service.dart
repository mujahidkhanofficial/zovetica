import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'auth_service.dart';
import '../main.dart' show navigatorKey;
import '../utils/notification_router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService({SupabaseClient? client}) => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final SupabaseClient _client = Supabase.instance.client;
  final AuthService _authService = AuthService();
  
  bool _tzInitialized = false;

  Future<void> init() async {
    // Initialize timezone
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint('🔔 Notification tapped: ${details.payload}');
        final context = navigatorKey.currentContext;
        if (context != null && details.payload != null) {
          NotificationRouter.handleNotificationTap(context, details.payload);
        }
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Emergency and critical alerts',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // ============================================
  // SCHEDULED NOTIFICATION METHODS
  // ============================================

  /// Schedule a reminder notification 1 hour before the appointment
  Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required DateTime appointmentDateTime,
    required String doctorName,
    required String petName,
  }) async {
    // Calculate 1 hour before appointment
    final reminderTime = appointmentDateTime.subtract(const Duration(hours: 1));
    
    // Don't schedule if reminder time has already passed
    if (reminderTime.isBefore(DateTime.now())) {
      debugPrint('⏰ Reminder time has passed, skipping schedule');
      return;
    }

    // Convert to TZDateTime (using local timezone)
    final tzReminderTime = tz.TZDateTime.from(reminderTime, tz.local);
    
    // Generate unique notification ID from appointment ID
    final notificationId = appointmentId.hashCode.abs() % 2147483647;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'appointment_reminders',
      'Appointment Reminders',
      channelDescription: 'Reminders for upcoming appointments',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      'Appointment in 1 Hour! ⏰',
      'Your appointment with Dr. $doctorName for $petName is at ${_formatTime(appointmentDateTime)}',
      tzReminderTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'appointment_reminder:$appointmentId',
    );

    debugPrint('✅ Scheduled 1-hour reminder for ${appointmentDateTime.toIso8601String()}');
  }

  /// Cancel a scheduled reminder
  Future<void> cancelAppointmentReminder(String appointmentId) async {
    final notificationId = appointmentId.hashCode.abs() % 2147483647;
    await _notificationsPlugin.cancel(notificationId);
    debugPrint('🗑️ Cancelled reminder for appointment: $appointmentId');
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
  }

  // ============================================
  // REMOTE DATA METHODS (Restored)
  // ============================================

  /// Get notifications from Supabase
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  /// Mark as read
  Future<void> markAsRead(int notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }

  // ============================================
  // NOTIFICATION TYPE CONSTANTS
  // ============================================
  static const String typeMessage = 'message';
  static const String typeAppointmentAccepted = 'appointment_accepted';
  static const String typeAppointmentRejected = 'appointment_rejected';
  static const String typeAppointmentRescheduled = 'appointment_rescheduled';
  static const String typeAppointmentReminder = 'appointment_reminder';
  static const String typeCommunityLike = 'community_like';
  static const String typeCommunityComment = 'community_comment';

  /// Create notification (stores in DB AND shows local push notification)
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    dynamic relatedId,
    String? actorId,
    bool showLocalPush = true,
  }) async {
    try {
      // 1. Store in Supabase for persistence and history
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'related_id': relatedId?.toString(),
        'actor_id': actorId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('📝 Notification saved to DB: type=$type, user=$userId');
      
      // 2. Show local push notification if enabled (only for recipient, not sender)
      // The push will only show if the recipient's device is receiving this call
      // For cross-device push, FCM would be needed
      if (showLocalPush && userId == _authService.currentUser?.id) {
        // This will only work if this is the recipient's device running this code
        // Typically, this would be called via a Supabase Edge Function + FCM
        // For now, we rely on real-time listeners to show notifications
        await showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
          payload: '$type:$relatedId',
        );
        debugPrint('📱 Local push notification shown');
      }
    } catch (e) {
      debugPrint('❌ Error creating notification: $e');
    }
  }

  /// Get unread count stream
  Stream<int> getUnreadCountStream() {
    final userId = _authService.currentUser?.id;
    if (userId == null) return Stream.value(0);
    
    // Supabase stream count is tricky without count aggregation support in stream
    // Using a polling approach or 'all' stream and counting locally
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.where((n) => n['is_read'] == false).length);
  }

  RealtimeChannel? _notificationChannel;

  /// Start listening for real-time notifications and show push notifications
  /// Call this on app startup after user is authenticated
  void startNotificationListener() {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    // Cancel any existing subscription
    _notificationChannel?.unsubscribe();

    _notificationChannel = _client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) async {
            final newNotification = payload.newRecord;
            if (newNotification != null) {
              final title = newNotification['title'] ?? 'Pets & Vets';
              final body = newNotification['body'] ?? 'You have a new notification';
              final type = newNotification['type'] ?? '';
              final relatedId = newNotification['related_id'];
              
              debugPrint('🔔 Real-time notification received: $title - $body');
              
              // Show local push notification
              await showNotification(
                id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                title: title,
                body: body,
                payload: '$type:$relatedId',
              );
            }
          },
        )
        .subscribe();
    
    debugPrint('📡 Notification listener started for user: $userId');
  }

  /// Stop the notification listener (call on logout)
  void stopNotificationListener() {
    _notificationChannel?.unsubscribe();
    _notificationChannel = null;
    debugPrint('📡 Notification listener stopped');
  }

  /// Get unread message count specifically
  Future<int> getUnreadMessageCount() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return 0;
    
    try {
      final response = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('type', typeMessage)
          .eq('is_read', false);
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get unread count by type
  Future<int> getUnreadCountByType(String type) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return 0;
    
    try {
      final response = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('type', type)
          .eq('is_read', false);
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}

