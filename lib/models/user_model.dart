enum UserRole { petOwner, doctor }

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
  final String? username; // New field

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
  });
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? map['full_name'] ?? 'Unknown',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] == 'doctor' ? UserRole.doctor : UserRole.petOwner,
      specialty: map['specialty'],
      clinic: map['clinic'],
      bio: map['bio'],
      profileImage: map['profile_image'] ?? map['avatar_url'] ?? '',
      username: map['username'],
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role, // Fix parameter type
    String? specialty,
    String? clinic,
    String? bio,
    String? profileImage,
    String? username,
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
    );
  }
}
