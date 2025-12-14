import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/post_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/confirmation_dialog.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../widgets/post_card.dart';

class AdminPostsScreen extends StatefulWidget {
  const AdminPostsScreen({super.key});

  @override
  State<AdminPostsScreen> createState() => _AdminPostsScreenState();
}

class _AdminPostsScreenState extends State<AdminPostsScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<Post> _posts = [];
  bool _showFlaggedOnly = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    final posts = await _adminService.getAllPosts(flaggedOnly: _showFlaggedOnly);
    setState(() {
      _posts = posts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        title: const Text(
          'Content Moderation',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.primaryDiagonal,
          ),
        ),
        actions: [
          // Filter Action instead of chip bar
          PopupMenuButton<bool>(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            onSelected: (val) {
              if (_showFlaggedOnly != val) {
                setState(() => _showFlaggedOnly = val);
                _loadPosts();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: true,
                child: Text('Flagged Only'),
              ),
              const PopupMenuItem(
                value: false,
                child: Text('All Posts'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return _buildPostCard(post);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _showFlaggedOnly ? 'All Caught Up!' : 'No Posts Found',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _showFlaggedOnly 
                  ? 'There are no flagged posts requiring your attention right now. Great job!'
                  : 'There are no posts in the system matching your criteria.',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.slate,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: OutlinedButton.icon(
                onPressed: _loadPosts,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh Feed'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return PostCard(
      post: post,
      flaggedReason: post.isFlagged ? (post.flaggedReason ?? "Reported by users") : null,
      onMoreOptions: () => _showAdminActions(post),
      // Disable standard interactions for admin view to focus on moderation, 
      // or keep them but they won't do much without auth context if generic
    );
  }

  void _showAdminActions(Post post) {
    showPostOptionsModal(
      context: context,
      title: 'Moderation Actions',
      options: [
        if (post.isFlagged)
          PostOptionItem(
            icon: Icons.check_circle_outline,
            title: 'Dismiss Flag',
            subtitle: 'Mark post as safe',
            color: AppColors.success,
            onTap: () {
              Navigator.pop(context);
              _dismissFlag(post);
            },
          ),
        PostOptionItem(
          icon: Icons.delete_outline,
          title: 'Delete Post',
          subtitle: 'Permanently remove content',
          color: AppColors.error,
          onTap: () {
            Navigator.pop(context);
            _deletePost(post);
          },
        ),
      ],
    );
  }

  Future<void> _deletePost(Post post) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Post?',
      message: 'Are you sure you want to delete this post? This action cannot be undone.',
      confirmText: 'Delete',
      icon: Icons.delete_forever_rounded,
      isDestructive: true,
    );

    if (confirmed) {
      await _adminService.deletePost(post.id.toString());
      _loadPosts();
    }
  }

  Future<void> _dismissFlag(Post post) async {
    await _adminService.unflagPost(post.id.toString());
    _loadPosts();
  }
}
