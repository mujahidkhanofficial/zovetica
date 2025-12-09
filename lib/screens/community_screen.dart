import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import '../theme/app_shadows.dart';
import '../widgets/enterprise_header.dart';
import '../services/post_service.dart';
import '../services/supabase_service.dart';
import '../services/user_service.dart';
import '../utils/image_picker_helper.dart';
import 'friends_screen.dart';
import 'profile_screen.dart';

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
  final UserService _userService = UserService(); // Add UserService
  
  Map<String, dynamic>? _currentUserProfile; // Store user profile
  File? _selectedImage;
  bool _isLoading = true;

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
      final profile = await _userService.getCurrentUser();
      if (mounted) {
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
      final posts = await _postService.fetchPosts();
      setState(() {
        _posts = posts;
      });
    } catch (e) {
      debugPrint('Error loading posts: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await ImagePickerHelper.pickAndCropImage(
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

  void _toggleLike(int postId) {
    setState(() {
      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        final post = _posts[index];
        _posts[index] = Post(
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
      }
    });

    if (_posts.firstWhere((post) => post.id == postId).isLiked) {
      _heartAnimationController.forward().then((_) {
        _heartAnimationController.reverse();
      });
    }
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
  
  final Map<int, bool> _showHeartOverlay = {};

  void _showCreatePostDialog() {
    setState(() {
      _selectedImage = null; // Reset image on open
    });
    
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
                    TextButton(
                      onPressed: (_postController.text.trim().isNotEmpty || _selectedImage != null)
                          ? () {
                              _createPost(_postController.text);
                              Navigator.pop(context);
                            }
                          : null,
                      style: TextButton.styleFrom(
                        backgroundColor: (_postController.text.trim().isNotEmpty || _selectedImage != null)
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
                          color: (_postController.text.trim().isNotEmpty || _selectedImage != null)
                              ? Colors.white
                              : AppColors.slate.withOpacity(0.5),
                        ),
                      ),
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
                        CircleAvatar(
                          radius: 22,
                          backgroundImage: (_currentUserProfile != null && _currentUserProfile!['profile_image'] != null && _currentUserProfile!['profile_image'].toString().isNotEmpty)
                              ? NetworkImage(_currentUserProfile!['profile_image'])
                              : null,
                          backgroundColor: AppColors.primary,
                          child: (_currentUserProfile == null || _currentUserProfile!['profile_image'] == null || _currentUserProfile!['profile_image'].toString().isEmpty)
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
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
                      onChanged: (_) => setModalState(() {}), // Update UI for button state
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
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
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
                        onCamera: () => _pickImage(ImageSource.camera).then((_) => setModalState((){})),
                        onGallery: () => _pickImage(ImageSource.gallery).then((_) => setModalState((){})),
                        title: 'Add Photo',
                      ),
                      icon: const Icon(Icons.photo_library, color: Colors.green),
                    ),
                    IconButton(
                      onPressed: (){}, 
                      icon: const Icon(Icons.person_add, color: Colors.blue),
                    ),
                    IconButton(
                       onPressed: (){},
                       icon: const Icon(Icons.emoji_emotions, color: Colors.amber),
                    ),
                     IconButton(
                       onPressed: (){},
                       icon: const Icon(Icons.location_on, color: Colors.red),
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
      setState(() => _isLoading = false);
    }
  }

  void _showCommentsSheet(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommunityCommentsSheet(
        post: post, 
        postService: _postService, 
        currentUserProfile: _currentUserProfile,
        onCommentAdded: () {
          // Refresh posts to update comment count
          _initializePosts();
        },
      ),
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
                color: Colors.white.withOpacity(0.9),
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
              color: Colors.white.withOpacity(0.2),
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
      body: Column(
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
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary,
                    backgroundImage: (_currentUserProfile?['profile_image'] ?? '').toString().isNotEmpty
                        ? NetworkImage(_currentUserProfile!['profile_image'])
                        : null,
                    child: (_currentUserProfile?['profile_image'] ?? '').toString().isEmpty
                        ? Text(
                            (_currentUserProfile?['name'] ?? 'U').toString().isNotEmpty 
                                ? (_currentUserProfile!['name'] as String)[0].toUpperCase() 
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
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
              child: ListView.builder(
                padding: const EdgeInsets.only(top: AppSpacing.md, bottom: 80),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  return _buildPostCard(_posts[index]);
                },
              ),
            ),
          ],
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
            color: color.withOpacity(0.1),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileScreen(userId: post.author.id)),
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.primaryDiagonal,
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: post.author.profileImage.isNotEmpty
                            ? NetworkImage(post.author.profileImage)
                            : null,
                        child: post.author.profileImage.isEmpty
                            ? Text(
                                post.author.name.split(' ').map((n) => n[0]).join(),
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.author.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.charcoal,
                                fontSize: 15,
                              ),
                            ),
                            if (post.author.role == UserRole.doctor) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppGradients.primaryCta,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'VET',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _formatTime(post.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.slate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.more_horiz, color: AppColors.slate),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              post.content,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.charcoal,
              ),
            ),
            if (post.localImagePath != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onDoubleTap: () => _handleDoubleTapLike(post.id),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(post.localImagePath!),
                        height: 300, // Taller image for better immersive feel
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (_showHeartOverlay[post.id] == true)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 80,
                              shadows: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ] else if (post.imageUrl != null) ...[
              const SizedBox(height: 12),
               GestureDetector(
                onDoubleTap: () => _handleDoubleTapLike(post.id),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        post.imageUrl!,
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 300,
                          color: AppColors.cloud,
                          child: const Center(child: Icon(Icons.broken_image, color: AppColors.slate)),
                        ),
                      ),
                    ),
                     if (_showHeartOverlay[post.id] == true)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 80,
                               shadows: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: post.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _toggleLike(post.id),
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _heartAnimationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: post.isLiked
                                ? 1.0 + (_heartAnimationController.value * 0.3)
                                : 1.0,
                            child: Icon(
                              post.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border_rounded,
                              color: post.isLiked
                                  ? AppColors.error
                                  : AppColors.slate,
                              size: 24,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.likesCount}',
                        style: TextStyle(
                          color: post.isLiked ? AppColors.error : AppColors.slate,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showCommentsSheet(post),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.slate,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.commentsCount}',
                        style: TextStyle(
                          color: AppColors.slate,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showShareOptions(post),
                  child: Icon(
                    Icons.share_rounded,
                    color: AppColors.slate,
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComment(Comment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen(userId: comment.author.id)),
              );
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.secondary,
              child: Text(
                comment.author.name.split(' ').map((n) => n[0]).join(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cloud,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            comment.author.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.charcoal,
                            ),
                          ),
                          if (comment.author.role == UserRole.doctor) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'VET',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.content,
                        style: TextStyle(fontSize: 14, color: AppColors.charcoal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _formatTime(comment.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.slate,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Like',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.slate,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Reply',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.slate,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

// Separate Stateful Widget for Comments Sheet with real data
class _CommunityCommentsSheet extends StatefulWidget {
  final Post post;
  final PostService postService;
  final Map<String, dynamic>? currentUserProfile;
  final VoidCallback onCommentAdded;

  const _CommunityCommentsSheet({
    required this.post,
    required this.postService,
    required this.currentUserProfile,
    required this.onCommentAdded,
  });

  @override
  State<_CommunityCommentsSheet> createState() => _CommunityCommentsSheetState();
}

class _CommunityCommentsSheetState extends State<_CommunityCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    try {
      final comments = await widget.postService.fetchComments(widget.post.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    // Optimistic UI: Add comment immediately
    final tempComment = Comment(
      id: DateTime.now().millisecondsSinceEpoch,
      author: User(
        id: widget.currentUserProfile?['id']?.toString() ?? '',
        name: widget.currentUserProfile?['name'] ?? 'You',
        email: '',
        phone: '',
        role: UserRole.petOwner,
        profileImage: widget.currentUserProfile?['profile_image'] ?? '',
      ),
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _comments.add(tempComment);
      _commentController.clear();
    });

    try {
      final newComment = await widget.postService.addComment(widget.post.id, text);
      if (newComment != null && mounted) {
        setState(() {
          final index = _comments.indexWhere((c) => c.id == tempComment.id);
          if (index != -1) {
            _comments[index] = newComment;
          }
        });
        widget.onCommentAdded();
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      setState(() {
        _comments.removeWhere((c) => c.id == tempComment.id);
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = widget.currentUserProfile;
    final userImage = userProfile?['profile_image']?.toString() ?? '';
    final userName = userProfile?['name']?.toString() ?? 'U';

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.grey[50], // Light grey background
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900], // Explicit dark color
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: Colors.grey[700]),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          // Comments List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.teal))
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No comments yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700], // Explicit dark
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Be the first to share your thoughts!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.teal.withOpacity(0.15),
                                backgroundImage: comment.author.profileImage.isNotEmpty
                                    ? NetworkImage(comment.author.profileImage)
                                    : null,
                                child: comment.author.profileImage.isEmpty
                                    ? Text(
                                        comment.author.name.isNotEmpty 
                                            ? comment.author.name[0].toUpperCase() 
                                            : 'U',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal[700], // Explicit color
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              // Comment Bubble
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            comment.author.name.isNotEmpty ? comment.author.name : 'User',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: Colors.grey[900], // EXPLICIT DARK
                                            ),
                                          ),
                                          Text(
                                            _formatTime(comment.timestamp),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        comment.content,
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.4,
                                          color: Colors.grey[800], // EXPLICIT DARK
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
          // Input Area
          Container(
            padding: EdgeInsets.fromLTRB(
              16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // User Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.teal,
                    backgroundImage: userImage.isNotEmpty ? NetworkImage(userImage) : null,
                    child: userImage.isEmpty
                        ? Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Text Field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _commentController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _addComment(),
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[900], // EXPLICIT DARK TEXT
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isSending ? null : _addComment,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
