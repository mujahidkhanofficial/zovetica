import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../services/admin_service.dart';
import '../../models/post_model.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Admin Content Moderation Screen
/// Allows viewing and moderating flagged posts.
class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;

  List<Post> _flaggedPosts = [];
  List<Post> _allPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);

    final flagged = await _adminService.getAllPosts(flaggedOnly: true);
    final all = await _adminService.getAllPosts();

    setState(() {
      _flaggedPosts = flagged;
      _allPosts = all;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Moderation'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flag, size: 18),
                  const SizedBox(width: 4),
                  const Text('Flagged'),
                  if (_flaggedPosts.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_flaggedPosts.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'All Posts'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPostList(_flaggedPosts, isFlagged: true),
                _buildPostList(_allPosts, isFlagged: false),
              ],
            ),
    );
  }

  Widget _buildPostList(List<Post> posts, {required bool isFlagged}) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFlagged ? Icons.check_circle : Icons.article,
              size: 64,
              color: AppColors.slate,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isFlagged ? 'No flagged content' : 'No posts yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (isFlagged)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Great! All content is clean.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: posts.length,
        itemBuilder: (context, index) => _buildPostCard(posts[index], isFlagged),
      ),
    );
  }

  Widget _buildPostCard(Post post, bool showFlaggedBadge) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: post.isFlagged
              ? AppColors.error.withOpacity(0.5)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flagged Banner
          if (post.isFlagged)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Flagged: ${post.flaggedReason ?? 'No reason provided'}',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: post.authorImage != null && post.authorImage!.isNotEmpty
                          ? NetworkImage(post.authorImage!)
                          : null,
                      child: post.authorImage == null || post.authorImage!.isEmpty
                          ? Text(
                              post.authorName?.isNotEmpty == true
                                  ? post.authorName![0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            timeago.format(post.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) => _handlePostAction(post, value),
                      itemBuilder: (context) => [
                        if (post.isFlagged)
                          const PopupMenuItem(
                            value: 'approve',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Approve Content'),
                              ],
                            ),
                          )
                        else
                          const PopupMenuItem(
                            value: 'flag',
                            child: Row(
                              children: [
                                Icon(Icons.flag, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Flag Content'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete Post'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Content
                Text(
                  post.content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),

                // Image Preview
                if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Image.network(
                      post.imageUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: AppColors.slate.withOpacity(0.1),
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 40),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

                // Stats
                Row(
                  children: [
                    _buildStatChip(Icons.favorite, '${post.likesCount} likes'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildStatChip(Icons.comment, '${post.commentsCount} comments'),
                    if (post.location != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      _buildStatChip(Icons.location_on, post.location!),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.slate.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.slate),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePostAction(Post post, String action) async {
    switch (action) {
      case 'approve':
        final success = await _adminService.unflagPost(post.id.toString());
        if (success) {
          _showSnackbar('Content approved', isSuccess: true);
          _loadPosts();
        }
        break;
      case 'flag':
        await _showFlagDialog(post);
        break;
      case 'delete':
        await _showDeleteConfirmation(post);
        break;
    }
  }

  Future<void> _showFlagDialog(Post post) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flag Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for flagging this content:'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'e.g., Inappropriate content...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Flag'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.isNotEmpty) {
      final success = await _adminService.flagPost(
        post.id.toString(),
        reasonController.text,
      );
      if (success) {
        _showSnackbar('Content flagged for review');
        _loadPosts();
      }
    }

    reasonController.dispose();
  }

  Future<void> _showDeleteConfirmation(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _adminService.deletePost(post.id.toString());
      if (success) {
        _showSnackbar('Post deleted', isSuccess: true);
        _loadPosts();
      }
    }
  }

  void _showSnackbar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.success : null,
      ),
    );
  }
}
