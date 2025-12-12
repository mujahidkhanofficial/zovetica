import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/post_service.dart';
import '../screens/profile_screen.dart';

/// Reusable Facebook-style Comments Sheet Widget
/// Enterprise-level design with responsive layout and clear text visibility
class CommentsSheet extends StatefulWidget {
  final Post post;
  final PostService postService;
  final Map<String, dynamic>? currentUserProfile;
  final VoidCallback onCommentAdded;

  const CommentsSheet({
    super.key,
    required this.post,
    required this.postService,
    required this.currentUserProfile,
    required this.onCommentAdded,
  });

  /// Show the comments sheet as a modal bottom sheet
  static Future<void> show({
    required BuildContext context,
    required Post post,
    required PostService postService,
    required Map<String, dynamic>? currentUserProfile,
    required VoidCallback onCommentAdded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(
        post: post,
        postService: postService,
        currentUserProfile: currentUserProfile,
        onCommentAdded: onCommentAdded,
      ),
    );
  }

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
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
    _focusNode.dispose();
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
    _focusNode.unfocus();

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
      _comments.insert(0, tempComment); // Add to top
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
      if (mounted) {
        setState(() {
          _comments.removeWhere((c) => c.id == tempComment.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to post comment'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = widget.currentUserProfile;
    final userImage = userProfile?['profile_image']?.toString() ?? '';
    final userName = userProfile?['name']?.toString() ?? 'User';
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 8),
                if (_comments.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_comments.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                const Spacer(),
                Material(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.close, color: Colors.grey[600], size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: Colors.grey[200]),
          
          // Comments List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.teal[400],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Loading comments...',
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No comments yet',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 6),
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
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return _buildCommentItem(comment);
                        },
                      ),
          ),
          
          // ═══════════════════════════════════════════════════════════════
          // FOOTER INPUT SECTION - Enterprise Facebook-style Design
          // ═══════════════════════════════════════════════════════════════
          Container(
            padding: EdgeInsets.fromLTRB(12, 10, 12, bottomPadding + 12),
            decoration: const BoxDecoration(
              color: Colors.white, // PURE WHITE BACKGROUND
              border: Border(
                top: BorderSide(color: Color(0xFFE4E6EB), width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // User Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE4E6EB),
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.teal.shade50,
                      backgroundImage: userImage.isNotEmpty 
                          ? NetworkImage(userImage) 
                          : null,
                      child: userImage.isEmpty
                          ? Text(
                              _getInitials(userName),
                              style: TextStyle(
                                color: Colors.teal.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Input Field - Clean White Design
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 100),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5), // Light Facebook grey
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        cursorColor: Colors.teal,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF1C1E21), // Facebook dark text
                          height: 1.35,
                        ),
                        decoration: const InputDecoration(
                          filled: true, // Explicitly enable fill
                          fillColor: Colors.transparent, // Transparent to show Container color
                          hintText: 'Write a comment...',
                          hintStyle: TextStyle(
                            color: Color(0xFF65676B), // Facebook grey hint
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Send Button - Modern Design
                  AnimatedScale(
                    scale: _commentController.text.trim().isNotEmpty ? 1.0 : 0.9,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: _commentController.text.trim().isNotEmpty
                            ? const LinearGradient(
                                colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: _commentController.text.trim().isEmpty
                            ? const Color(0xFFE4E6EB)
                            : null,
                        shape: BoxShape.circle,
                        boxShadow: _commentController.text.trim().isNotEmpty
                            ? [
                                BoxShadow(
                                  color: Colors.teal.withAlpha(60),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _commentController.text.trim().isNotEmpty && !_isSending
                              ? _addComment
                              : null,
                          child: Center(
                            child: _isSending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    Icons.send_rounded,
                                    color: _commentController.text.trim().isNotEmpty
                                        ? Colors.white
                                        : const Color(0xFFBCC0C4),
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
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

  Future<void> _toggleCommentLike(Comment comment) async {
    // Optimistic Update
    final isLiked = comment.isLiked;
    final likesCount = comment.likesCount;
    
    setState(() {
      final index = _comments.indexWhere((c) => c.id == comment.id);
      if (index != -1) {
        _comments[index] = comment.copyWith(
          isLiked: !isLiked,
          likesCount: isLiked ? likesCount - 1 : likesCount + 1,
        );
      }
    });

    try {
      await widget.postService.toggleCommentLike(comment.id);
    } catch (e) {
      // Revert if failed
      if (mounted) {
        setState(() {
          final index = _comments.indexWhere((c) => c.id == comment.id);
          if (index != -1) {
            _comments[index] = comment.copyWith(
              isLiked: isLiked,
              likesCount: likesCount,
            );
          }
        });
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Optimistic Delete
    final deletedCommentIndex = _comments.indexWhere((c) => c.id == commentId);
    final deletedComment = deletedCommentIndex != -1 ? _comments[deletedCommentIndex] : null;
    
    setState(() {
      _comments.removeWhere((c) => c.id == commentId);
    });

    try {
      final success = await widget.postService.deleteComment(commentId);
      if (!success && deletedComment != null && mounted) {
        setState(() {
          _comments.insert(deletedCommentIndex, deletedComment);
        });
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete comment')),
        );
      }
    } catch (e) {
      if (deletedComment != null && mounted) {
        setState(() {
          _comments.insert(deletedCommentIndex, deletedComment);
        });
      }
    }
  }

  Future<void> _showEditDialog(Comment comment) async {
    final controller = TextEditingController(text: comment.content);
    final save = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Edit your comment...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (save != null && save.isNotEmpty && save != comment.content) {
      setState(() {
        final index = _comments.indexWhere((c) => c.id == comment.id);
        if (index != -1) {
          _comments[index] = comment.copyWith(content: save);
        }
      });

      try {
        await widget.postService.editComment(comment.id, save);
      } catch (e) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to edit comment')),
          );
           // Optionally revert
         }
      }
    }
  }

  Widget _buildCommentItem(Comment comment) {
    final currentUserId = widget.currentUserProfile?['id']?.toString();
    final isAuthor = currentUserId == comment.author.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar - CLEARLY VISIBLE
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen(userId: comment.author.id)),
              );
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.teal.shade100, // Visible teal background
              backgroundImage: comment.author.profileImage.isNotEmpty
                  ? NetworkImage(comment.author.profileImage)
                  : null,
              child: comment.author.profileImage.isEmpty
                  ? Text(
                      _getInitials(comment.author.name),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800, // Dark teal for visibility
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          
          // Comment Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bubble with visible styling
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2F5), // Facebook-style light grey
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author Name - CLEARLY VISIBLE BLACK
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfileScreen(userId: comment.author.id),
                                  ),
                                );
                              },
                              child: Text(
                                comment.author.name.isNotEmpty ? comment.author.name : 'User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.black87, // EXPLICIT BLACK
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Comment Text - CLEARLY VISIBLE
                            Text(
                              comment.content,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: Colors.black87, // EXPLICIT BLACK TEXT
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Options Menu (Edit/Delete)
                    if (isAuthor) 
                      SizedBox(
                        width: 30,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.more_horiz, size: 20, color: Colors.grey[500]),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditDialog(comment);
                            } else if (value == 'delete') {
                              _deleteComment(comment.id);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                // Actions Row (Time, Like, Reply)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Row(
                    children: [
                      Text(
                        _formatTime(comment.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _toggleCommentLike(comment),
                        child: Text(
                          comment.likesCount > 0 
                              ? 'Like (${comment.likesCount})' 
                              : 'Like',
                          style: TextStyle(
                            fontSize: 12,
                            color: comment.isLiked ? Colors.teal : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          // Focus input to reply
                          _focusNode.requestFocus();
                        },
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
