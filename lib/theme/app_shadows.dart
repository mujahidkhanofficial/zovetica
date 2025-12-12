import 'package:flutter/material.dart';

/// Zovetica Design System - Shadows
class AppShadows {
  AppShadows._();

  /// Subtle card shadow
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withAlpha(10),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withAlpha(5),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// Elevated shadow for modals/dialogs
  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: Colors.black.withAlpha(20),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withAlpha(10),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  /// Bottom navigation shadow
  static List<BoxShadow> get bottomNav => [
        BoxShadow(
          color: Colors.black.withAlpha(15),
          blurRadius: 12,
          offset: const Offset(0, -4),
        ),
      ];

  /// Button press shadow
  static List<BoxShadow> buttonShadow(Color color) => [
        BoxShadow(
          color: color.withAlpha(77),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// Soft glow effect
  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withAlpha(51),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  /// No shadow (for dark mode cards)
  static List<BoxShadow> get none => [];
}
