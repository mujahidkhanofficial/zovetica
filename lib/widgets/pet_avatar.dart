import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Circular avatar with optional border and pet decoration
class PetAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double size;
  final Color? backgroundColor;
  final bool showBorder;
  final bool showPawBadge;
  final VoidCallback? onTap;

  const PetAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = AppSpacing.avatarLg,
    this.backgroundColor,
    this.showBorder = false,
    this.showPawBadge = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppColors.primaryLight.withOpacity(0.2),
        border: showBorder
            ? Border.all(
                color: AppColors.primary,
                width: 3,
              )
            : null,
        image: imageUrl != null && imageUrl!.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl == null || imageUrl!.isEmpty
          ? Center(
              child: initials != null
                  ? Text(
                      initials!,
                      style: TextStyle(
                        fontSize: size * 0.35,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: size * 0.5,
                      color: AppColors.primary,
                    ),
            )
          : null,
    );

    if (showPawBadge) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: AppColors.accentYellow,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '🐾',
                  style: TextStyle(fontSize: size * 0.15),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}

/// Pet emoji avatar (for pets list)
class PetEmojiAvatar extends StatelessWidget {
  final String emoji;
  final String? imageUrl;
  final double size;
  final Color? backgroundColor;

  const PetEmojiAvatar({
    super.key,
    this.emoji = '🐾',
    this.imageUrl,
    this.size = AppSpacing.avatarMd,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(imageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.accentYellowLight,
            AppColors.accentPeachLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }
}
