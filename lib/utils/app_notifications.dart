import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppNotifications {
  static void showSuccess(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    _showRaw(context, message, AppColors.success, Icons.check_circle_rounded, actionLabel: actionLabel, onAction: onAction);
  }

  static void showError(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    _showRaw(context, message, AppColors.error, Icons.error_rounded, actionLabel: actionLabel, onAction: onAction);
  }

  static void showInfo(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    _showRaw(context, message, AppColors.info, Icons.info_rounded, actionLabel: actionLabel, onAction: onAction);
  }

  static void showWarning(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    _showRaw(context, message, AppColors.warning, Icons.warning_rounded, actionLabel: actionLabel, onAction: onAction);
  }

  static void _showRaw(
      BuildContext context, String message, Color color, IconData icon, {String? actionLabel, VoidCallback? onAction}) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Clear queue
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        elevation: 0, 
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
        action: (actionLabel != null && onAction != null) 
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              ) 
            : null,
      ),
    );
  }
}
