import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/app_models.dart';
import 'supabase_service.dart';
import 'storage_service.dart';

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

      final postsWithLikes = await _enrichPostsWithLikeStatus(response as List);
      return postsWithLikes;
    } catch (e) {
      print('Error fetching posts: $e');
      throw e;
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

      final postsWithLikes = await _enrichPostsWithLikeStatus(response as List);
      return postsWithLikes;
    } catch (e) {
      print('Error fetching user posts: $e');
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
        // We'll trust StorageService has a generic upload or we use generic one
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
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
      print('Error creating post: $e');
      return null;
    }
  }

  /// Toggle Like
  Future<bool> toggleLike(int postId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;

    try {
      // Check if already liked
      final existingLike = await _client
          .from('post_likes')
          .select()
          .match({'user_id': userId, 'post_id': postId})
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _client.from('post_likes').delete().match({'user_id': userId, 'post_id': postId});
        return false; // Not liked anymore
      } else {
        // Like
        await _client.from('post_likes').insert({'user_id': userId, 'post_id': postId});
        return true; // Liked
      }
    } catch (e) {
      print('Error toggling like: $e');
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
      print('Error adding comment: $e');
      return null;
    }
  }

  /// Fetch Comments for a post
  Future<List<Comment>> fetchComments(int postId) async {
    try {
      final response = await _client
          .from('post_comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return (response as List).map((data) {
        return Comment(
          id: data['id'],
          author: User(
            id: data['user_id']?.toString() ?? '',
            name: 'User', // Generic fallback; ideally fetch from a users table
            email: '',
            phone: '',
            role: UserRole.petOwner,
            profileImage: '',
          ),
          content: data['content'] ?? '',
          timestamp: DateTime.parse(data['created_at']),
        );
      }).toList();
    } catch (e) {
      print('Error fetching comments: $e');
      return [];
    }
  }

  // --- Helpers for isLiked ---

  Future<List<Post>> _enrichPostsWithLikeStatus(List<dynamic> rawPosts) async {
    final userId = SupabaseService.currentUser?.id;
    final posts = rawPosts.map((data) => Post.fromMap(data)).toList();

    if (userId == null || posts.isEmpty) return posts;

    try {
      final postIds = posts.map((p) => p.id).toList();
      final myLikes = await _client
          .from('post_likes')
          .select('post_id')
          .eq('user_id', userId)
          .filter('post_id', 'in', postIds);
      
      final likedPostIds = (myLikes as List).map((l) => l['post_id'] as int).toSet();
      
      return posts.map((p) => p.copyWith(isLiked: likedPostIds.contains(p.id))).toList();
    } catch (e) {
      print('Error enriching posts with likes: $e');
      return posts;
    }
  }
}
