enum UserRole { petOwner, doctor, admin, superAdmin }

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? specialty; // For doctors
  final String? clinic; // For doctors
  final String? bio;
  final String profileImage;
  final String? username;
  
  // Admin-related fields
  final DateTime? bannedAt;
  final String? bannedReason;
  final String? bannedBy;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.specialty,
    this.clinic,
    this.bio,
    required this.profileImage,
    this.username,
    this.bannedAt,
    this.bannedReason,
    this.bannedBy,
  });

  /// Returns true if this user has admin or super admin privileges
  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;

  /// Returns true if this user is a super admin
  bool get isSuperAdmin => role == UserRole.superAdmin;

  /// Returns true if this user is banned
  bool get isBanned => bannedAt != null;

  /// Helper to convert role string to enum
  static UserRole _parseRole(String? roleStr) {
    switch (roleStr) {
      case 'doctor':
        return UserRole.doctor;
      case 'admin':
        return UserRole.admin;
      case 'super_admin':
        return UserRole.superAdmin;
      default:
        return UserRole.petOwner;
    }
  }

  /// Helper to convert role enum to database string
  String get roleString {
    switch (role) {
      case UserRole.doctor:
        return 'doctor';
      case UserRole.admin:
        return 'admin';
      case UserRole.superAdmin:
        return 'super_admin';
      default:
        return 'pet_owner';
    }
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? map['full_name'] ?? 'Unknown',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: _parseRole(map['role']),
      specialty: map['specialty'],
      clinic: map['clinic'],
      bio: map['bio'],
      profileImage: map['profile_image'] ?? map['avatar_url'] ?? '',
      username: map['username'],
      bannedAt: map['banned_at'] != null 
          ? DateTime.tryParse(map['banned_at'].toString()) 
          : null,
      bannedReason: map['banned_reason'],
      bannedBy: map['banned_by'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': roleString,
      'specialty': specialty,
      'clinic': clinic,
      'bio': bio,
      'profile_image': profileImage,
      'username': username,
      'banned_at': bannedAt?.toIso8601String(),
      'banned_reason': bannedReason,
      'banned_by': bannedBy,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? specialty,
    String? clinic,
    String? bio,
    String? profileImage,
    String? username,
    DateTime? bannedAt,
    String? bannedReason,
    String? bannedBy,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      specialty: specialty ?? this.specialty,
      clinic: clinic ?? this.clinic,
      bio: bio ?? this.bio,
      profileImage: profileImage ?? this.profileImage,
      username: username ?? this.username,
      bannedAt: bannedAt ?? this.bannedAt,
      bannedReason: bannedReason ?? this.bannedReason,
      bannedBy: bannedBy ?? this.bannedBy,
    );
  }
}
