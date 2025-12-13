import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'auth_service.dart';

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

  /// Schedule a reminder notification 24 hours before the appointment
  Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required DateTime appointmentDateTime,
    required String doctorName,
    required String petName,
  }) async {
    // Calculate 24 hours before appointment
    final reminderTime = appointmentDateTime.subtract(const Duration(hours: 24));
    
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
      'Appointment Tomorrow! 🏥',
      'Your appointment with Dr. $doctorName for $petName is tomorrow at ${_formatTime(appointmentDateTime)}',
      tzReminderTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'appointment:$appointmentId',
    );

    debugPrint('✅ Scheduled reminder for ${appointmentDateTime.toIso8601String()} (24h before)');
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

  /// Create notification (Server side usually, but client might trigger it)
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    dynamic relatedId,
    String? actorId,
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'related_id': relatedId,
      'actor_id': actorId,
      'is_read': false,
    });
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
}

