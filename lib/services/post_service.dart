import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import 'supabase_service.dart';
import 'storage_service.dart';

// Top-level function for isolate
List<Post> _parsePosts(List<dynamic> data) {
  return data.map((json) => Post.fromMap(json)).toList();
}

class PostService {
  final _client = SupabaseService.client;
  final _storageService = StorageService();

  /// Fetch all posts ordered by newest first
  Future<List<Post>> fetchPosts() async {
    try {
      final response = await _client
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      // Offload parsing to background isolate
      final posts = await compute(_parsePosts, response as List<dynamic>);
      
      final postsWithLikes = await _enrichPostsWithLikeStatus(posts);
      return postsWithLikes;
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      rethrow;
    }
  }

  /// Fetch posts by a specific user
  Future<List<Post>> fetchPostsByUserId(String userId) async {
    try {
      final response = await _client
          .from('posts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Offload parsing to background isolate
      final posts = await compute(_parsePosts, response as List<dynamic>);

      final postsWithLikes = await _enrichPostsWithLikeStatus(posts);
      return postsWithLikes;
    } catch (e) {
      debugPrint('Error fetching user posts: $e');
      return [];
    }
  }

  /// Create a new post
  Future<Post?> createPost({
    required String content,
    File? image,
    required String authorName,
    required String authorImage,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      String? imageUrl;
      if (image != null) {
        // Upload image to 'posts' bucket
        imageUrl = await _storageService.uploadImage(
          file: image, 
          bucket: 'posts', 
          folder: userId
        );
      }

      final response = await _client.from('posts').insert({
        'user_id': userId,
        'content': content,
        'image_url': imageUrl,
        'author_name': authorName,
        'author_image': authorImage,
        'likes_count': 0,
        'comments_count': 0,
        'tags': [], // Add logic for tag extraction if needed
      }).select().single();

      return Post.fromMap(response);
    } catch (e) {
      debugPrint('Error creating post: $e');
      return null;
    }
  }

  /// Update an existing post (only by owner)
  Future<bool> updatePost({
    required int postId,
    required String content,
    File? newImage,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    debugPrint('updatePost: Starting update for post $postId by user $userId');
    debugPrint('updatePost: New content length: ${content.length} chars');
    
    try {
      if (userId == null) {
        debugPrint('updatePost ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }

      // Verify ownership
      debugPrint('updatePost: Checking ownership...');
      final existing = await _client
          .from('posts')
          .select('user_id, image_url')
          .eq('id', postId)
          .single();

      debugPrint('updatePost: Post owner: ${existing['user_id']}, Current user: $userId');
      
      if (existing['user_id'] != userId) {
        debugPrint('updatePost ERROR: User does not own this post');
        throw Exception('You can only edit your own posts');
      }

      String? imageUrl = existing['image_url'];
      
      // Upload new image if provided
      if (newImage != null) {
        debugPrint('updatePost: Uploading new image...');
        imageUrl = await _storageService.uploadImage(
          file: newImage,
          bucket: 'posts',
          folder: userId,
        );
        debugPrint('updatePost: New image URL: $imageUrl');
      }

      debugPrint('updatePost: Executing update query...');
      final response = await _client.from('posts').update({
        'content': content,
        'image_url': imageUrl,
      }).eq('id', postId).select();

      debugPrint('updatePost: Update response: $response');
      debugPrint('updatePost SUCCESS: Post $postId updated');
      return true;
    } catch (e, stack) {
      debugPrint('updatePost ERROR: $e');
      debugPrint('updatePost STACK: $stack');
      return false;
    }
  }

  /// Delete a post (only by owner)
  Future<bool> deletePost(int postId) async {
    final userId = SupabaseService.currentUser?.id;
    debugPrint('deletePost: Starting delete for post $postId by user $userId');
    
    try {
      if (userId == null) {
        debugPrint('deletePost ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }

      // Verify ownership
      debugPrint('deletePost: Checking ownership...');
      final existing = await _client
          .from('posts')
          .select('user_id')
          .eq('id', postId)
          .single();

      debugPrint('deletePost: Post owner: ${existing['user_id']}, Current user: $userId');

      if (existing['user_id'] != userId) {
        debugPrint('deletePost ERROR: User does not own this post');
        throw Exception('You can only delete your own posts');
      }

      // Delete related data first (likes, comments)
      debugPrint('deletePost: Deleting related likes...');
      await _client.from('post_likes').delete().eq('post_id', postId);
      
      debugPrint('deletePost: Deleting related comments...');
      await _client.from('post_comments').delete().eq('post_id', postId);
      
      // Delete the post
      debugPrint('deletePost: Deleting post...');
      final deleteResponse = await _client.from('posts').delete().eq('id', postId).select();
      
      debugPrint('deletePost: Delete response: $deleteResponse');
      debugPrint('deletePost SUCCESS: Post $postId deleted');
      return true;
    } catch (e, stack) {
      debugPrint('deletePost ERROR: $e');
      debugPrint('deletePost STACK: $stack');
      return false;
    }
  }

  /// Toggle Like
  Future<bool> toggleLike(int postId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      debugPrint('toggleLike: No user logged in');
      return false;
    }

    debugPrint('toggleLike: userId=$userId, postId=$postId');

    try {
      // Check if already liked
      final existingLike = await _client
          .from('post_likes')
          .select()
          .match({'user_id': userId, 'post_id': postId})
          .maybeSingle();

      debugPrint('toggleLike: existingLike=$existingLike');

      if (existingLike != null) {
        // Unlike - delete from post_likes and decrement count
        debugPrint('toggleLike: Removing like...');
        await _client.from('post_likes').delete().match({'user_id': userId, 'post_id': postId});
        
        // Decrement likes_count in posts table
        await _client.rpc('decrement_likes', params: {'post_id_param': postId}).catchError((e) {
          debugPrint('toggleLike: RPC decrement failed (may not exist): $e');
          // Fallback: manual update
          return _client.from('posts').update({
            'likes_count': (existingLike['likes_count'] ?? 1) - 1,
          }).eq('id', postId);
        });
        
        debugPrint('toggleLike: Unlike successful');
        return false; // Not liked anymore
      } else {
        // Like - insert into post_likes and increment count
        debugPrint('toggleLike: Adding like...');
        await _client.from('post_likes').insert({'user_id': userId, 'post_id': postId});
        
        // Increment likes_count in posts table
        await _client.rpc('increment_likes', params: {'post_id_param': postId}).catchError((e) async {
          debugPrint('toggleLike: RPC increment failed (may not exist): $e');
          // Fallback: get current count and update
          final post = await _client.from('posts').select('likes_count').eq('id', postId).single();
          final currentCount = post['likes_count'] ?? 0;
          return _client.from('posts').update({
            'likes_count': currentCount + 1,
          }).eq('id', postId);
        });
        
        debugPrint('toggleLike: Like successful');
        return true; // Liked
      }
    } catch (e, stack) {
      debugPrint('toggleLike ERROR: $e');
      debugPrint('toggleLike STACK: $stack');
      return false;
    }
  }

  /// Add Comment
  Future<Comment?> addComment(int postId, String content) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return null;

    try {
      // Insert and return just the comment row (no user join needed)
      final response = await _client.from('post_comments').insert({
        'user_id': userId,
        'post_id': postId,
        'content': content,
      }).select().single();

      // Construct Comment with minimal author info (UI will use local profile)
      return Comment(
        id: response['id'],
        author: User(
          id: userId,
          name: 'You', // Placeholder, UI uses local profile data for display
          email: '',
          phone: '',
          role: UserRole.petOwner,
          profileImage: '',
        ),
        content: response['content'] ?? '',
        timestamp: DateTime.parse(response['created_at']),
      );
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return null;
    }
  }

  /// Fetch Comments for a post with real user profile data and interaction status
  Future<List<Comment>> fetchComments(int postId) async {
    try {
      final userId = SupabaseService.currentUser?.id;

      // Fetch comments for the post
      final commentsResponse = await _client
          .from('post_comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      final comments = commentsResponse as List;
      if (comments.isEmpty) return [];

      // Get unique IDs
      final userIds = comments
          .map((c) => c['user_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();
      
      final commentIds = comments.map((c) => c['id'] as int).toList();

      // Fetch user profiles
      Map<String, Map<String, dynamic>> userProfiles = {};
      if (userIds.isNotEmpty) {
        try {
          final usersResponse = await _client
              .from('users')
              .select('id, name, profile_image')
              .inFilter('id', userIds);
          
          for (final user in usersResponse as List) {
            userProfiles[user['id']] = user;
          }
        } catch (e) {
          debugPrint('Error fetching user profiles: $e');
        }
      }

      // Check which comments the user has liked
      Set<int> likedCommentIds = {};
      if (userId != null && commentIds.isNotEmpty) {
        try {
          final likesResponse = await _client
              .from('comment_likes')
              .select('comment_id')
              .eq('user_id', userId)
              .inFilter('comment_id', commentIds);
          
          for (final like in likesResponse as List) {
            likedCommentIds.add(like['comment_id'] as int);
          }
        } catch (e) {
          debugPrint('Error fetching comment likes: $e');
        }
      }

      // Build comments
      return comments.map((data) {
        final authorId = data['user_id']?.toString() ?? '';
        final userProfile = userProfiles[authorId];
        final commentId = data['id'] as int;
        
        return Comment(
          id: commentId,
          author: User(
            id: authorId,
            name: userProfile?['name'] ?? 'User',
            email: '',
            phone: '',
            role: UserRole.petOwner,
            profileImage: userProfile?['profile_image'] ?? '',
          ),
          content: data['content'] ?? '',
          timestamp: DateTime.parse(data['created_at']),
          likesCount: data['likes_count'] ?? 0,
          isLiked: likedCommentIds.contains(commentId),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      return [];
    }
  }

  /// Toggle Comment Like
  Future<bool> toggleCommentLike(int commentId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;

    try {
      // Check if already liked
      final existingLike = await _client
          .from('comment_likes')
          .select()
          .eq('user_id', userId)
          .eq('comment_id', commentId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _client
            .from('comment_likes')
            .delete()
            .eq('user_id', userId)
            .eq('comment_id', commentId);
        return false; // Not liked
      } else {
        // Like
        await _client.from('comment_likes').insert({
          'user_id': userId,
          'comment_id': commentId,
        });
        return true; // Liked
      }
    } catch (e) {
      debugPrint('Error toggling comment like: $e');
      rethrow;
    }
  }

  /// Edit Comment
  Future<bool> editComment(int commentId, String newContent) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;

    try {
      await _client
          .from('post_comments')
          .update({'content': newContent})
          .eq('id', commentId)
          .eq('user_id', userId); // Ensure ownership
      return true;
    } catch (e) {
      debugPrint('Error editing comment: $e');
      return false;
    }
  }

  /// Delete Comment
  Future<bool> deleteComment(int commentId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;

    try {
      await _client
          .from('post_comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', userId); // Ensure ownership
      return true;
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      return false;
    }
  }

  // --- Helpers for isLiked ---

  Future<List<Post>> _enrichPostsWithLikeStatus(List<Post> posts) async {
    final userId = SupabaseService.currentUser?.id;
    // posts are already parsed
    // final posts = rawPosts.map((data) => Post.fromMap(data)).toList(); 
    
    if (userId == null || posts.isEmpty) return posts;

    try {
      final postIds = posts.map((p) => p.id).toList();
      final myLikes = await _client
          .from('post_likes')
          .select('post_id')
          .eq('user_id', userId)
          .inFilter('post_id', postIds);
      
      final likedPostIds = (myLikes as List).map((l) => l['post_id'] as int).toSet();
      
      return posts.map((p) => p.copyWith(isLiked: likedPostIds.contains(p.id))).toList();
    } catch (e) {
      debugPrint('Error enriching posts with likes: $e');
      return posts;
    }
  }
}
