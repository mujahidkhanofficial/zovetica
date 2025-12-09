import 'package:flutter/material.dart';

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
  });
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? map['full_name'] ?? 'Unknown', // Fallback for various schemas
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] == 'doctor' ? UserRole.doctor : UserRole.petOwner,
      specialty: map['specialty'],
      clinic: map['clinic'],
      bio: map['bio'],
      profileImage: map['profile_image'] ?? map['avatar_url'] ?? '', // Fallback for various schemas
    );
  }
}

class Pet {
  final String name;
  final String type;
  final String age;
  final String nextCheckup;
  final String health;
  final String emoji;
  final String imageUrl;

  Pet({
    required this.name,
    required this.type,
    required this.age,
    required this.nextCheckup,
    required this.health,
    required this.emoji,
    required this.imageUrl,
  });

  // Factory constructor to create Pet from database (supports both camelCase and snake_case)
  factory Pet.fromMap(Map<String, dynamic> data) {
    return Pet(
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      age: data['age'] ?? '',
      nextCheckup: data['next_checkup'] ?? data['nextCheckup'] ?? '',
      health: data['health'] ?? '',
      emoji: data['emoji'] ?? '🐾',
      imageUrl: data['image_url'] ?? data['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'age': age,
      'nextCheckup': nextCheckup,
      'health': health,
      'emoji': emoji,
      'imageUrl': imageUrl,
    };
  }
}

class Doctor {
  final int id;
  final String name;
  final String specialty;
  final double rating;
  final int reviews;
  // final String distance;
  final String nextAvailable;
  final String clinic;
  final String image;
  final bool available;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.reviews,
    // required this.distance,
    required this.nextAvailable,
    required this.clinic,
    required this.image,
    required this.available,
  });
}

class Appointment {
  final int id;
  final String doctor;
  final String clinic;
  final String date;
  final String time;
  final String pet;
  final String type;
  final String status;

  Appointment({
    required this.id,
    required this.doctor,
    required this.clinic,
    required this.date,
    required this.time,
    required this.pet,
    required this.type,
    required this.status,
  });
}

class Medication {
  final int id;
  final String name;
  final String pet;
  final String dosage;
  final String frequency;
  final String nextDose;
  final String timeLeft;
  final bool completed;
  final bool reminderEnabled;
  final int daysLeft;
  final String instructions;

  Medication({
    required this.id,
    required this.name,
    required this.pet,
    required this.dosage,
    required this.frequency,
    required this.nextDose,
    required this.timeLeft,
    required this.completed,
    required this.reminderEnabled,
    required this.daysLeft,
    required this.instructions,
  });
}

class EmergencyCategory {
  final String title;
  final String urgency;
  final List<String> items;
  final Color color;

  EmergencyCategory({
    required this.title,
    required this.urgency,
    required this.items,
    required this.color,
  });
}

class ChatMessage {
  final int id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

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
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'],
      author: User(
        id: map['user_id']?.toString() ?? '', 
        name: map['author_name'] ?? 'Unknown User',
        email: '',
        phone: '',
        role: UserRole.petOwner,
        profileImage: map['author_image'] ?? '',
      ),
      content: map['content'] ?? '',
      imageUrl: map['image_url'],
      timestamp: DateTime.parse(map['created_at']),
      likesCount: map['likes_count'] ?? 0,
      commentsCount: map['comments_count'] ?? 0,
      isLiked: map['is_liked'] ?? false, // Support mapped is_liked if query provides it
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Post copyWith({
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
  }) {
    return Post(
      id: id,
      author: author,
      content: content,
      imageUrl: imageUrl,
      localImagePath: localImagePath,
      timestamp: timestamp,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      tags: tags,
    );
  }
}

class Comment {
  final int id;
  final User author;
  final String content;
  final DateTime timestamp;
  final int likesCount;
  final bool isLiked;

  Comment({
    required this.id,
    required this.author,
    required this.content,
    required this.timestamp,
    this.likesCount = 0,
    this.isLiked = false,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      // We often need to join user table to get author details. 
      // Assuming Supabase query returns 'user:users(...)'
      author: map['user'] != null ? User.fromMap(map['user']) : User(
          id: map['user_id'] ?? '',
          name: 'User',
          role: UserRole.petOwner,
          email: '', phone: '', profileImage: ''
      ),
      content: map['content'] ?? '',
      timestamp: DateTime.parse(map['created_at']),
    );
  }
}

enum AppScreen {
  splash,
  onboarding,
  auth,
  home,
  doctors,
  appointments,
  medication,
  emergency,
  chat,
  community,
  profile,
}
