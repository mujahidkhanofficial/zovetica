import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A consistent Pull-to-Refresh indicator for the entire app.
/// 
/// Usage:
/// ```dart
/// AppRefreshIndicator(
///   onRefresh: _refreshData,
///   child: ListView(...),
/// )
/// ```
class AppRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;
  final Color? backgroundColor;

  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? AppColors.primary,
      backgroundColor: backgroundColor ?? Colors.white,
      displacement: 40,
      strokeWidth: 3,
      child: child,
    );
  }
}
