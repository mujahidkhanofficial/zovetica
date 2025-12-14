import 'user_model.dart';

class Post {
  final int id;
  final User author;
  final String content;
  final String? imageUrl;
  final String? localImagePath; // For locally picked images
  final DateTime timestamp;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final List<String> tags;
  
  // Moderation fields
  final bool isFlagged;
  final DateTime? flaggedAt;
  final String? flaggedReason;
  final String? moderatedBy;
  final String? postLocation;

  Post({
    required this.id,
    required this.author,
    required this.content,
    this.imageUrl,
    this.localImagePath,
    required this.timestamp,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.tags,
    this.isFlagged = false,
    this.flaggedAt,
    this.flaggedReason,
    this.moderatedBy,
    this.postLocation,
  });

  // Getters for admin content screen compatibility
  String? get authorName => author.name;
  String? get authorImage => author.profileImage;
  DateTime get createdAt => timestamp;
  String? get location => postLocation;

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'],
      author: User(
        id: map['user_id']?.toString() ?? '', 
        name: (map['users'] != null ? map['users']['name'] : null) ?? map['author_name'] ?? 'Unknown User',
        email: '',
        phone: '',
        role: UserRole.petOwner,
        profileImage: (map['users'] != null ? map['users']['profile_image'] : null) ?? map['author_image'] ?? '',
      ),
      content: map['content'] ?? '',
      imageUrl: map['image_url'],
      timestamp: DateTime.parse(map['created_at']),
      likesCount: map['likes_count'] ?? 0,
      commentsCount: map['comments_count'] ?? 0,
      isLiked: map['is_liked'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
      isFlagged: map['is_flagged'] ?? false,
      flaggedAt: map['flagged_at'] != null 
          ? DateTime.tryParse(map['flagged_at'].toString()) 
          : null,
      flaggedReason: map['flagged_reason'],
      moderatedBy: map['moderated_by'],
      postLocation: map['location'],
    );
  }

  Post copyWith({
    User? author,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    bool? isFlagged,
    String? flaggedReason,
  }) {
    return Post(
      id: id,
      author: author ?? this.author,
      content: content,
      imageUrl: imageUrl,
      localImagePath: localImagePath,
      timestamp: timestamp,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      tags: tags,
      isFlagged: isFlagged ?? this.isFlagged,
      flaggedAt: flaggedAt,
      flaggedReason: flaggedReason ?? this.flaggedReason,
      moderatedBy: moderatedBy,
      postLocation: postLocation,
    );
  }
}
