import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../services/supabase_service.dart';
import '../utils/image_picker_helper.dart';
import '../utils/app_notifications.dart';
import '../widgets/post_card.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/offline_banner.dart';
import '../widgets/widgets.dart';
import 'friends_screen.dart';
import '../data/repositories/post_repository.dart';
import '../data/repositories/user_repository.dart';
import '../services/auth_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with TickerProviderStateMixin {
  final TextEditingController _postController = TextEditingController();
  late AnimationController _heartAnimationController;
  final PostService _postService = PostService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final PostRepository _postRepo = PostRepository.instance;
  
  Map<String, dynamic>? _currentUserProfile; // Store user profile
  File? _selectedImage;
  bool _isLoading = true;
  final Map<int, bool> _showHeartOverlay = {};

  List<Post> _posts = [];

  @override
  void initState() {
    super.initState();
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fetchUserProfile(); // Fetch user data
    _initializePosts();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      // Local first
      final localUser = await UserRepository.instance.getUser(userId);
      if (localUser != null && mounted) {
        setState(() {
          _currentUserProfile = {
            'name': localUser.name,
            'profile_image': localUser.profileImage,
            'role': localUser.role,
          };
        });
      }
      
      // Then sync if needed
      final profile = await _userService.getCurrentUser();
      if (profile != null && mounted) {
        setState(() {
          _currentUserProfile = profile;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  Future<void> _initializePosts() async {
    setState(() => _isLoading = true);
    try {
      // Local first
      final localPosts = await _postRepo.getPosts();
      if (localPosts.isNotEmpty) {
        setState(() {
          _posts = localPosts.map(_postRepo.localPostToPost).toList();
          _isLoading = false;
        });
      }
      
      // Then sync
      await _postRepo.syncPosts();
      final updatedPosts = await _postRepo.getPosts();
      setState(() {
        _posts = updatedPosts.map(_postRepo.localPostToPost).toList();
      });
    } catch (e) {
      debugPrint('Error loading posts: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await ImagePickerHelper.pickAndCropImage(
      context,
      source: source,
      title: 'Post Photo',
    );
    if (file != null) {
      setState(() {
        _selectedImage = file;
      });
    }
  }

  @override
  void dispose() {
    _postController.dispose();
    _heartAnimationController.dispose();
    super.dispose();
  }

  void _toggleLike(int postId) async {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;
    
    final post = _posts[postIndex];
    
    // 1. Optimistic UI update
    setState(() {
      _posts[postIndex] = Post(
        id: post.id,
        author: post.author,
        content: post.content,
        imageUrl: post.imageUrl,
        timestamp: post.timestamp,
        likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
        commentsCount: post.commentsCount,
        isLiked: !post.isLiked,
        tags: post.tags,
      );
    });

    // 2. Play animation if liking
    if (!post.isLiked) {
      _heartAnimationController.forward().then((_) {
        _heartAnimationController.reverse();
      });
    }

    // 3. Delegate to repository
    // Note: The repository handles sync and reversion on failure internally
    // We pass the OLD state (layout before toggle) to allow revert if needed
    await _postRepo.toggleLike(postId, post.isLiked, post.likesCount);
  }

  // Double Tap Animation State
  final Map<int, AnimationController> _doubleTapControllers = {};
  
  void _handleDoubleTapLike(int postId) {
    _toggleLike(postId);
    
    // Trigger animation for specific post in a real app, 
    // but for now we'll simulate a general 'heart' overlay effect on the current post or manage state better.
    // Simplification: We'll just rely on the feed update for now, 
    // or we can add a local "showHeart" state per post if we want the overlay.
    // Let's implement a simple overlay in the build method using a state map.
    setState(() {
      _showHeartOverlay[postId] = true;
    });
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showHeartOverlay[postId] = false;
        });
      }
    });
  }
  


  void _showCreatePostDialog() {
    setState(() {
      _selectedImage = null; // Reset image on open
    });
    
    // Performance optimization: Use ValueNotifier to avoid rebuilding entire modal on typing
    final ValueNotifier<bool> canPostParams = ValueNotifier(false);

    void updatePostButtonState() {
      final hasText = _postController.text.trim().isNotEmpty;
      final hasImage = _selectedImage != null;
      canPostParams.value = hasText || hasImage;
    }

    // Initial check
    updatePostButtonState();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.95,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // 1. Header (Facebook Style)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.charcoal),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const Text(
                      'Create Post',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoal,
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: canPostParams,
                      builder: (context, canPost, child) {
                        return TextButton(
                          onPressed: canPost
                              ? () {
                                  _createPost(_postController.text);
                                  Navigator.pop(context);
                                }
                              : null,
                          style: TextButton.styleFrom(
                            backgroundColor: canPost
                                ? AppColors.primary
                                : AppColors.cloud,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Post',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: canPost
                                  ? Colors.white
                                  : AppColors.slate.withAlpha(128),
                            ),
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ),

              // 2. User Context & Content

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        CachedAvatar(
                          imageUrl: _currentUserProfile?['profile_image'],
                          name: _currentUserProfile?['name'] ?? 'Pet Parent',
                          radius: 22,
                          backgroundColor: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentUserProfile?['name'] ?? 'Pet Parent',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.charcoal,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.cloud,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.public, size: 12, color: AppColors.slate),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Public',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.slate,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_drop_down, size: 12, color: AppColors.slate),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Text Field
                    TextField(
                      controller: _postController,
                      maxLines: null,
                      // Optimization: Update notifier only, don't rebuild modal
                      onChanged: (_) => updatePostButtonState(),
                      decoration: const InputDecoration(
                        hintText: "What's on your mind?",
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        filled: true,
                        fillColor: Colors.white,
                        hintStyle: TextStyle(
                          fontSize: 20,
                          color: AppColors.slate, 
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        color: AppColors.charcoal,
                      ),
                    ),
                    
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 20),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  _selectedImage = null;
                                });
                                updatePostButtonState();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(153),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // 3. Bottom Toolbar
              Container(
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.borderLight)),
                ),
                child: Row(
                  children: [
                     Expanded( // Use Expanded to push icons to the right or fill
                       child: Text(
                          "Add to your post",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                        ),
                     ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () => ImagePickerHelper.showPickerModal(
                        context,
                        onCamera: () => _pickImage(ImageSource.camera).then((_) { 
                          setModalState((){});
                          updatePostButtonState(); 
                        }),
                        onGallery: () => _pickImage(ImageSource.gallery).then((_) { 
                          setModalState((){});
                          updatePostButtonState();
                        }),
                        title: 'Add Photo',
                      ),
                      icon: const Icon(Icons.photo_library, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createPost(String content) async {
    // Data Integrity: Use the real profile if available
    final String authorName = _currentUserProfile?['name'] ?? 'Pet Parent';
    final String authorImage = _currentUserProfile?['profile_image'] ?? '';

    setState(() => _isLoading = true);
    
    try {
      final newPost = await _postService.createPost(
        content: content,
        image: _selectedImage,
        authorName: authorName, 
        authorImage: authorImage, 
      );

      if (!mounted) return; // Added mounted check
      if (newPost != null) {
        setState(() {
          _posts.insert(0, newPost);
          _postController.clear();
          _selectedImage = null;
        });
      }
    } catch (e) {
      debugPrint('Error creating post: $e');
    } finally {
      if (!mounted) return; // Added mounted check
      setState(() => _isLoading = false);
    }
  }

  void _showCommentsSheet(Post post) {
    CommentsSheet.show(
      context: context,
      post: post,
      postService: _postService,
      currentUserProfile: _currentUserProfile,
      onCommentAdded: _initializePosts,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Community',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Connect with other pet parents',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withAlpha(230),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.primaryDiagonal,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.people_alt_rounded, color: Colors.white),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen()));
              },
            ),
          ),
        ],
      ),
      body: OfflineAwareBody(
        child: Column(
        children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                ]
              ),
              child: Row(
                children: [
                  CachedAvatar(
                    imageUrl: _currentUserProfile?['profile_image'],
                    name: _currentUserProfile?['name'] ?? 'U',
                    radius: 20,
                    backgroundColor: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _showCreatePostDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cloud,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          "What's on your mind?",
                          style: TextStyle(
                            color: AppColors.slate,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: AppGradients.coralButtonDecoration(radius: 50),
                    child: ElevatedButton(
                      onPressed: _showCreatePostDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: _initializePosts,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: 80),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    return _buildPostCard(_posts[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareOptions(Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Share to',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoal,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context), // Close sheet
                        icon: const Icon(Icons.close, color: AppColors.slate),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildShareOption(Icons.copy_rounded, 'Copy Link', Colors.blue),
                      _buildShareOption(Icons.message_rounded, 'Chat', Colors.green),
                      _buildShareOption(Icons.share_rounded, 'More', AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(Post post) {
    return PostCard(
      post: post,
      onLike: () => _toggleLike(post.id),
      onComment: () => _showCommentsSheet(post),
      onDoubleTap: () => _handleDoubleTapLike(post.id),
      showHeartOverlay: _showHeartOverlay[post.id] == true,
      onMoreOptions: null, // Hidden on community page - only visible on profile
    );
  }

  void _showPostOptionsMenu(Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.edit_rounded, color: AppColors.primary),
                ),
                title: const Text('Edit Post', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Modify your post content'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditPostDialog(post);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_rounded, color: AppColors.error),
                ),
                title: Text('Delete Post', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.error)),
                subtitle: const Text('Remove this post permanently'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeletePost(post);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPostDialog(Post post) {
    final editController = TextEditingController(text: post.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            const Text('Edit Post'),
          ],
        ),
        content: TextField(
          controller: editController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'What\'s on your mind?',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: AppColors.cloud,
          ),
          style: const TextStyle(color: AppColors.charcoal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.slate)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _postService.updatePost(
                postId: post.id,
                content: editController.text.trim(),
              );
              if (success) {
                _initializePosts(); // Refresh posts
                if (mounted) {
                  AppNotifications.showSuccess(context, 'Post updated successfully!');
                }
              } else {
                if (mounted) {
                  AppNotifications.showError(context, 'Failed to update post');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePost(Post post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 10),
            const Text('Delete Post?'),
          ],
        ),
        content: const Text(
          'This will permanently delete your post and all its comments. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.slate)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _postService.deletePost(post.id);
              if (success) {
                setState(() {
                  _posts.removeWhere((p) => p.id == post.id);
                });
                if (mounted) {
                  AppNotifications.showSuccess(context, 'Post deleted');
                }
              } else {
                if (mounted) {
                  AppNotifications.showError(context, 'Failed to delete post');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

