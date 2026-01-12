import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../screens/simple_chat_screen.dart';
import '../screens/community_screen.dart';

/// Handles notification tap navigation and deep linking
class NotificationRouter {
  /// Navigate based on notification payload
  /// Payload format: "type:relatedId" (e.g., "message:123", "appointment_accepted:abc")
  static void handleNotificationTap(BuildContext context, String? payload) {
    if (payload == null || payload.isEmpty) {
      debugPrint('⚠️ Notification tap: empty payload');
      return;
    }

    debugPrint('🔔 Notification tap: $payload');
    
    final parts = payload.split(':');
    if (parts.length < 2) {
      debugPrint('⚠️ Invalid payload format: $payload');
      return;
    }

    final type = parts[0];
    final relatedId = parts[1];

    switch (type) {
      case NotificationService.typeMessage:
        _navigateToChat(context, relatedId);
        break;
        
      case NotificationService.typeAppointmentAccepted:
      case NotificationService.typeAppointmentRejected:
      case NotificationService.typeAppointmentRescheduled:
      case 'appointment_request':
      case 'appointment_cancelled':
        _navigateToAppointments(context);
        break;
        
      case NotificationService.typeCommunityLike:
      case NotificationService.typeCommunityComment:
        _navigateToCommunity(context);
        break;
        
      default:
        debugPrint('⚠️ Unknown notification type: $type');
    }
  }

  /// Navigate to chat screen with specific chat ID
  static void _navigateToChat(BuildContext context, String chatId) {
    try {
      final chatIdInt = int.parse(chatId);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SimpleChatScreen(
            chatId: chatIdInt,
            friendId: '', // Will be loaded from chat data
            friendName: 'Loading...',
            friendImage: null,
          ),
        ),
      );
      debugPrint('📱 Navigated to chat: $chatId');
    } catch (e) {
      debugPrint('❌ Error navigating to chat: $e');
    }
  }

  /// Navigate to appointments tab
  static void _navigateToAppointments(BuildContext context) {
    try {
      // Navigate to home screen with appointments tab selected (index 2)
      Navigator.of(context).popUntil((route) => route.isFirst);
      // Note: The actual tab selection would require a global key or state management
      // For now, just navigate back to root
      debugPrint('📱 Navigated to appointments');
    } catch (e) {
      debugPrint('❌ Error navigating to appointments: $e');
    }
  }

  /// Navigate to community screen
  static void _navigateToCommunity(BuildContext context) {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CommunityScreen(),
        ),
      );
      debugPrint('📱 Navigated to community');
    } catch (e) {
      debugPrint('❌ Error navigating to community: $e');
    }
  }
}
