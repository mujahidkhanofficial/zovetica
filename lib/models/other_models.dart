import 'package:flutter/material.dart';

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

class PetHealthEvent {
  final int id;
  final String petId; // Changed to String (UUID)
  final String title;
  final DateTime date;
  final String type; // 'Vaccine', 'Surgery', 'Checkup', 'Dental', 'Other'
  final String? notes;

  PetHealthEvent({
    required this.id,
    required this.petId,
    required this.title,
    required this.date,
    required this.type,
    this.notes,
  });

  factory PetHealthEvent.fromMap(Map<String, dynamic> map) {
    return PetHealthEvent(
      id: map['id'],
      petId: map['pet_id'].toString(), // Ensure String
      title: map['title'] ?? '',
      date: DateTime.parse(map['date']),
      type: map['type'] ?? 'Other',
      notes: map['notes'],
    );
  }
}

class AvailabilitySlot {
  final String id;
  final String day;
  final String startTime;
  final String endTime;

  AvailabilitySlot({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
  });
}
