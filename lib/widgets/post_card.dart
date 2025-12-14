import 'dart:io';
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_gradients.dart';
import '../screens/profile_screen.dart';
import '../widgets/widgets.dart';

/// Reusable Facebook-style Post Card Widget - Enterprise Level
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onMoreOptions;
  final bool showHeartOverlay;
  final String? flaggedReason;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onDoubleTap,
    this.onMoreOptions,
    this.showHeartOverlay = false,
    this.flaggedReason,
  });

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: AppShadows.card,
          border: flaggedReason != null ? Border.all(color: AppColors.error, width: 1.5) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flagged Banner
            if (flaggedReason != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusMd)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Flagged: $flaggedReason',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Header
            _buildHeader(context),
            
            // Content
            if (post.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Text(
                  post.content,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.charcoal,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            
            // Image
            if (post.localImagePath != null || post.imageUrl != null)
              _buildImage(),
            
            // Tags
            if (post.tags.isNotEmpty) _buildTags(),
            
            // Stats Row
            _buildStatsRow(),
            
            // Divider
            Divider(height: 1, color: AppColors.borderLight),
            
            // Action Buttons
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar with gradient ring
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen(userId: post.author.id)),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primaryDiagonal,
              ),
              child: CachedAvatar(
                name: post.author.name,
                imageUrl: post.author.profileImage,
                radius: 20,
                backgroundColor: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Name & Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                      Flexible(
                      child: Text(
                        post.author.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // VET Badge
                    if (post.author.role == UserRole.doctor) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppGradients.primaryCta,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'VET',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.public, size: 12, color: AppColors.slate),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(post.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // More Options
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onMoreOptions,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.more_horiz, color: AppColors.slate, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onDoubleTap: onDoubleTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            post.localImagePath != null
                ? Image.file(
                    File(post.localImagePath!),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : CachedImage(
                    imageUrl: post.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      height: 250,
                      color: AppColors.cloud,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    errorWidget: Container(
                      height: 200,
                      color: AppColors.cloud,
                      child: Center(
                        child: Icon(Icons.broken_image_outlined, 
                          color: AppColors.textMuted, size: 48),
                      ),
                    ),
                  ),
            // Heart overlay for double-tap like - simplified animation
            if (showHeartOverlay)
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 80,
                  shadows: [
                    Shadow(
                      color: Colors.black.withAlpha(100),
                      blurRadius: 20,
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTags() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: post.tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(20),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              '#$tag',
              style: TextStyle(
                color: AppColors.secondaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsRow() {
    if (post.likesCount == 0 && post.commentsCount == 0) {
      return const SizedBox(height: 12);
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          if (post.likesCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.roseDark,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.favorite, color: AppColors.white, size: 10),
            ),
            const SizedBox(width: 6),
            Text(
              '${post.likesCount}',
              style: TextStyle(
                color: AppColors.slate,
                fontSize: 13,
              ),
            ),
          ],
          const Spacer(),
          if (post.commentsCount > 0)
            Text(
              '${post.commentsCount} comment${post.commentsCount > 1 ? 's' : ''}',
              style: TextStyle(
                color: AppColors.slate,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Like Button
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onLike,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(scale: animation, child: child);
                        },
                        child: Icon(
                          post.isLiked ? Icons.favorite : Icons.favorite_outline,
                          key: ValueKey(post.isLiked),
                          color: post.isLiked ? AppColors.roseDark : AppColors.slate,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Like',
                        style: TextStyle(
                          color: post.isLiked ? AppColors.roseDark : AppColors.charcoal,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Comment Button
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onComment,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.slate,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Comment',
                        style: TextStyle(
                          color: AppColors.charcoal,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
  
// ============================================================================
// REUSABLE POST OPTIONS SHEET
// ============================================================================

class PostOptionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  PostOptionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

void showPostOptionsModal({
  required BuildContext context,
  required String title,
  required List<PostOptionItem> options,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoal,
                ),
              ),
            ),
            // Options
            ...options.map((option) => _buildOptionTile(
              icon: option.icon,
              title: option.title,
              subtitle: option.subtitle,
              color: option.color,
              onTap: option.onTap,
            )),
            
            const SizedBox(height: 12),
            
            // Cancel Action
            ListTile(
              title: const Center(
                child: Text(
                  'Cancel', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: AppColors.slate,
                    fontSize: 16,
                  ),
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}

Widget _buildOptionTile({
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color == AppColors.error ? color : AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    ),
  );
}


