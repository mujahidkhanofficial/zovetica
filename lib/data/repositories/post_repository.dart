import 'package:drift/drift.dart';
import '../local/database.dart';
import '../../services/post_service.dart';
import '../../services/auth_service.dart';
import '../../models/app_models.dart';

/// Repository for offline-first post/community management
class PostRepository {
  final AppDatabase _db = AppDatabase.instance;
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();

  // Singleton
  static final PostRepository _instance = PostRepository._();
  PostRepository._();
  static PostRepository get instance => _instance;

  /// Watch all posts (local-first, reactive)
  Stream<List<LocalPost>> watchPosts() {
    return _db.watchPosts();
  }

  /// Get posts from cache
  Future<List<LocalPost>> getPosts({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final local = await _db.getPosts();
      if (local.isNotEmpty) return local;
    }
    await syncPosts();
    return _db.getPosts();
  }

  /// Get posts by user from cache
  Future<List<LocalPost>> getPostsByUserId(String userId, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final query = _db.select(_db.localPosts)
        ..where((p) => p.userId.equals(userId))
        ..orderBy([(p) => OrderingTerm(expression: p.createdAt, mode: OrderingMode.desc)]);
      
      final local = await query.get();
      if (local.isNotEmpty) return local;
    }
    
    await syncPostsByUserId(userId);
    
    final query = _db.select(_db.localPosts)
      ..where((p) => p.userId.equals(userId))
      ..orderBy([(p) => OrderingTerm(expression: p.createdAt, mode: OrderingMode.desc)]);
    return query.get();
  }

  /// Sync posts from remote to local
  Future<void> syncPosts() async {
    try {
      final posts = await _postService.fetchPosts();
      final companions = posts.map(_mapPostToCompanion).toList();
      await _db.upsertPosts(companions);
    } catch (e) {
      // Silently fail - use cached data
    }
  }

  /// Sync user specific posts
  Future<void> syncPostsByUserId(String userId) async {
    try {
      final posts = await _postService.fetchPostsByUserId(userId);
      final companions = posts.map(_mapPostToCompanion).toList();
      await _db.upsertPosts(companions);
    } catch (e) {
      // Silently fail
    }
  }

  /// Like/unlike a post (optimistic) - returns true on success, false on failure
  Future<bool> toggleLike(int postId, bool currentlyLiked, int currentLikes) async {
    final newLiked = !currentlyLiked;
    final newCount = newLiked ? currentLikes + 1 : currentLikes - 1;
    
    // Optimistic local update
    await _db.updatePostLike(postId, newLiked, newCount);
    
    // Sync to remote
    try {
      await _postService.toggleLike(postId);
      return true; // Success
    } catch (e) {
      // Revert on failure
      await _db.updatePostLike(postId, currentlyLiked, currentLikes);
      return false; // Signal failure to caller
    }
  }

  /// Map Post model to Drift companion
  LocalPostsCompanion _mapPostToCompanion(Post post) {
    return LocalPostsCompanion(
      id: Value(post.id),
      userId: Value(post.author.id),
      content: Value(post.content),
      imageUrl: Value(post.imageUrl),
      authorName: Value(post.author.name),
      authorImage: Value(post.author.profileImage),
      location: const Value(null),
      likesCount: Value(post.likesCount),
      commentsCount: Value(post.commentsCount),
      isLikedByMe: Value(post.isLiked),
      createdAt: Value(post.timestamp),
      isSynced: const Value(true),
      syncStatus: const Value('synced'),
      isDeleted: const Value(false),
    );
  }

  /// Convert LocalPost to Post model for UI
  Post localPostToPost(LocalPost local) {
    return Post(
      id: local.id,
      author: User(
        id: local.userId,
        name: local.authorName,
        email: '',
        phone: '',
        role: UserRole.petOwner,
        profileImage: local.authorImage ?? '',
      ),
      content: local.content,
      imageUrl: local.imageUrl,
      timestamp: local.createdAt,
      likesCount: local.likesCount,
      commentsCount: local.commentsCount,
      isLiked: local.isLikedByMe,
      tags: [],
    );
  }
}
