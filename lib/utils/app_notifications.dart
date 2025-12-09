import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

class AppNotifications {
  static void showSuccess(BuildContext context, String message) {
    _showRaw(context, message, AppColors.success, Icons.check_circle_rounded);
  }

  static void showError(BuildContext context, String message) {
    _showRaw(context, message, AppColors.error, Icons.error_rounded);
  }

  static void showInfo(BuildContext context, String message) {
    _showRaw(context, message, AppColors.info, Icons.info_rounded);
  }

  static void showWarning(BuildContext context, String message) {
    _showRaw(context, message, AppColors.warning, Icons.warning_rounded);
  }

  static void _showRaw(
      BuildContext context, String message, Color color, IconData icon) {
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
        elevation: 0, // Using manual shadow or just default flat look with color
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
