import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A badge indicator widget that displays an unread count
/// Used on navigation tabs and app bar icons
class BadgeWidget extends StatelessWidget {
  final int count;
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;
  final double? top;
  final double? right;
  final bool showZero;

  const BadgeWidget({
    super.key,
    required this.count,
    required this.child,
    this.badgeColor,
    this.textColor,
    this.top = -4,
    this.right = -4,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show badge if count is 0 and showZero is false
    if (count <= 0 && !showZero) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: top,
          right: right,
          child: _buildBadge(),
        ),
      ],
    );
  }

  Widget _buildBadge() {
    final displayText = count > 99 ? '99+' : count.toString();
    final isSmall = count < 10;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 5,
        vertical: 2,
      ),
      constraints: BoxConstraints(
        minWidth: isSmall ? 18 : 22,
        minHeight: 18,
      ),
      decoration: BoxDecoration(
        color: badgeColor ?? AppColors.error,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: (badgeColor ?? AppColors.error).withAlpha(100),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// A stream-based badge that automatically updates from a stream
class StreamBadgeWidget extends StatelessWidget {
  final Stream<int> countStream;
  final Widget child;
  final Color? badgeColor;
  final bool showZero;

  const StreamBadgeWidget({
    super.key,
    required this.countStream,
    required this.child,
    this.badgeColor,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: countStream,
      initialData: 0,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return BadgeWidget(
          count: count,
          badgeColor: badgeColor,
          showZero: showZero,
          child: child,
        );
      },
    );
  }
}
