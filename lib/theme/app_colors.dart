import 'package:flutter/material.dart';

/// Pets & Vets Design System - Industrial Level Color Tokens
/// Ocean Blue (Trust) + Mint Green (Health) + Sunset Coral (Action)
class AppColors {
  AppColors._();

  // ============ PRIMARY COLORS ============
  /// Ocean Blue - Trust, medical, professional
  static const Color primary = Color(0xFF4A90D9);
  static const Color primaryLight = Color(0xFF7AB3F0);
  static const Color primaryDark = Color(0xFF3A75B5);

  /// Mint Green - Health, growth, positive
  static const Color secondary = Color(0xFF5ECFB1);
  static const Color secondaryLight = Color(0xFF8AECD5);
  static const Color secondaryDark = Color(0xFF45A890);

  /// Sunset Coral - CTAs, warmth, action
  static const Color accent = Color(0xFFFF8A6C);
  static const Color accentLight = Color(0xFFFFB4A0);
  static const Color accentDark = Color(0xFFFF6B6B);

  // ============ WARM ACCENTS ============
  /// Golden - Ratings, badges, stars
  static const Color golden = Color(0xFFFFD93D);
  static const Color goldenLight = Color(0xFFFFE680);
  static const Color goldenDark = Color(0xFFE5C235);

  /// Rose - Hearts, likes, love
  static const Color rose = Color(0xFFFDA4AF);
  static const Color roseLight = Color(0xFFFECDD3);
  static const Color roseDark = Color(0xFFFB7185);

  /// Lavender - Premium features
  static const Color lavender = Color(0xFFC4B5FD);

  // ============ NEUTRAL COLORS ============
  /// Charcoal - Headings
  static const Color charcoal = Color(0xFF2D3436);
  
  /// Slate - Body text
  static const Color slate = Color(0xFF636E72);
  
  /// Cloud - Backgrounds
  static const Color cloud = Color(0xFFF8F9FA);
  
  /// Pure White - Cards
  static const Color white = Color(0xFFFFFFFF);
  
  /// Border Light
  static const Color borderLight = Color(0xFFE9ECEF);
  
  /// Border Dark
  static const Color borderDark = Color(0xFF3D4852);

  // ============ DARK MODE COLORS ============
  static const Color backgroundDark = Color(0xFF1A1D21);
  static const Color surfaceDark = Color(0xFF252A30);
  static const Color textLight = Color(0xFFF5F5F5);
  static const Color textMuted = Color(0xFFA0A5AB);

  // ============ STATUS COLORS ============
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color info = Color(0xFF60A5FA);

  // ============ SEMANTIC GETTERS ============
  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? backgroundDark
        : cloud;
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceDark
        : white;
  }

  static Color text(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textLight
        : charcoal;
  }

  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textMuted
        : slate;
  }

  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? borderDark
        : borderLight;
  }

  // ============ LEGACY COMPATIBILITY ============
  // Keep old names for backward compatibility during migration
  static const Color textPrimary = charcoal;
  static const Color textSecondary = slate;
  static const Color accentYellow = golden;
  static const Color accentYellowLight = goldenLight;
  static const Color accentPeach = accent;
  static const Color accentPeachLight = accentLight;
  static const Color backgroundLight = cloud;
  static const Color surfaceLight = white;
}
