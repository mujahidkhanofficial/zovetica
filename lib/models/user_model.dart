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
}
