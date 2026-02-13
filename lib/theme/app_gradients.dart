import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Pets & Vets Design System - Industrial Level Gradients
class AppGradients {
  AppGradients._();

  // ============ PRIMARY GRADIENTS ============
  /// Ocean to Mint - Professional medical feel
  static const LinearGradient primaryCta = LinearGradient(
    colors: [AppColors.primary, AppColors.secondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Coral Action Gradient - For CTAs
  static const LinearGradient coralCta = LinearGradient(
    colors: [AppColors.accent, AppColors.accentDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Coral Horizontal - Button gradient
  static const LinearGradient coralButton = LinearGradient(
    colors: [Color(0xFFFF8A6C), Color(0xFFFF6B6B)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Vertical for headers
  static const LinearGradient primaryVertical = LinearGradient(
    colors: [AppColors.primary, AppColors.secondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Diagonal version
  static const LinearGradient primaryDiagonal = LinearGradient(
    colors: [AppColors.primary, AppColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============ WARM GRADIENTS ============
  /// Golden sunset - Warm community feel
  static const LinearGradient warmHeader = LinearGradient(
    colors: [AppColors.golden, AppColors.accent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Rose gradient - For social interactions
  static const LinearGradient roseGradient = LinearGradient(
    colors: [AppColors.rose, AppColors.roseDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============ SUBTLE GRADIENTS ============
  /// Light background gradient
  static const LinearGradient subtleBackground = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Card shimmer effect
  static const LinearGradient shimmer = LinearGradient(
    colors: [Color(0xFFE5E7EB), Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ============ DARK MODE GRADIENTS ============
  static const LinearGradient primaryCtaDark = LinearGradient(
    colors: [Color(0xFF5BA4E8), Color(0xFF6FD9C4)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient darkBackground = LinearGradient(
    colors: [Color(0xFF1A1D21), Color(0xFF252A30)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ============ GRADIENT DECORATIONS ============
  static BoxDecoration coralButtonDecoration({double radius = 12}) {
    return BoxDecoration(
      gradient: coralButton,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: AppColors.accent.withAlpha(89),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration primaryButtonDecoration({double radius = 12}) {
    return BoxDecoration(
      gradient: primaryCta,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withAlpha(77),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration headerDecoration() {
    return const BoxDecoration(
      gradient: primaryDiagonal,
    );
  }
}
