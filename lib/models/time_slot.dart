import 'package:flutter/material.dart';

/// Time slot model for appointment booking
class TimeSlot {
  final String time;        // "09:00", "09:30", etc.
  final bool isAvailable;
  final String? label;      // "Morning", "Afternoon", "Evening"

  const TimeSlot({
    required this.time,
    required this.isAvailable,
    this.label,
  });

  /// Parse time string to TimeOfDay
  TimeOfDay get timeOfDay {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  /// Get formatted display time (e.g., "9:00 AM")
  String get displayTime {
    final hour = int.parse(time.split(':')[0]);
    final minute = time.split(':')[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

/// Appointment type with pricing in PKR
class AppointmentType {
  final String id;
  final String name;
  final String description;
  final int durationMinutes;
  final int priceInPKR;
  final IconData icon;

  const AppointmentType({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.priceInPKR,
    required this.icon,
  });

  /// Format price as PKR string
  String get formattedPrice => 'PKR ${priceInPKR.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  )}';

  /// Predefined appointment types with Material icons
  static const List<AppointmentType> predefinedTypes = [
    AppointmentType(
      id: 'checkup',
      name: 'General Checkup',
      description: 'Routine health examination',
      durationMinutes: 30,
      priceInPKR: 2000,
      icon: Icons.health_and_safety_rounded,
    ),
    AppointmentType(
      id: 'vaccination',
      name: 'Vaccination',
      description: 'Vaccine administration',
      durationMinutes: 30,
      priceInPKR: 3500,
      icon: Icons.vaccines_rounded,
    ),
    AppointmentType(
      id: 'dental',
      name: 'Dental Care',
      description: 'Teeth cleaning & checkup',
      durationMinutes: 60,
      priceInPKR: 5000,
      icon: Icons.sentiment_satisfied_alt_rounded,
    ),
    AppointmentType(
      id: 'surgery',
      name: 'Surgery',
      description: 'Pre-surgery assessment',
      durationMinutes: 60,
      priceInPKR: 8000,
      icon: Icons.local_hospital_rounded,
    ),
    AppointmentType(
      id: 'emergency',
      name: 'Emergency',
      description: 'Urgent care needed',
      durationMinutes: 30,
      priceInPKR: 10000,
      icon: Icons.emergency_rounded,
    ),
    AppointmentType(
      id: 'grooming',
      name: 'Grooming',
      description: 'Professional pet grooming',
      durationMinutes: 60,
      priceInPKR: 2500,
      icon: Icons.content_cut_rounded,
    ),
    AppointmentType(
      id: 'followup',
      name: 'Follow-up',
      description: 'Post-treatment checkup',
      durationMinutes: 30,
      priceInPKR: 1500,
      icon: Icons.assignment_turned_in_rounded,
    ),
  ];

  /// Get appointment type by ID
  static AppointmentType? getById(String id) {
    try {
      return predefinedTypes.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
}
