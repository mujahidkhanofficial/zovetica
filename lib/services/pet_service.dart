import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import '../models/app_models.dart';

/// Pet service for CRUD operations
class PetService {
  final _client = SupabaseService.client;
  static const String _tableName = 'pets';

  /// Add a new pet
  Future<void> addPet({
    required String name,
    required String type,
    String? breed,
    String? gender,
    String? age,
    String? weight, // New
    String? height, // New
    String? health,
    String? emoji,
    String? imageUrl,
    DateTime? nextCheckup,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client.from(_tableName).insert({
      'owner_id': userId,
      'name': name,
      'type': type,
      'breed': breed,
      'gender': gender ?? 'Unknown',
      'age': age,
      'weight': weight,
      'height': height,
      'health': health ?? 'Good',
      'emoji': emoji ?? '🐾',
      'image_url': imageUrl,
      'next_checkup': nextCheckup?.toIso8601String(),
    });
  }

  /// Get all pets for current user
  Future<List<Pet>> getPets() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from(_tableName)
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((data) => Pet.fromMap(data)).toList();
  }

  /// Get a single pet by ID
  Future<Pet?> getPetById(String petId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('id', petId)
          .single();
      
      return Pet.fromMap(response);
    } catch (e) {
      debugPrint('Error fetching pet by ID: $e');
      return null;
    }
  }

  /// Get all pets for a specific user
  Future<List<Pet>> getPetsByUserId(String userId) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((data) => Pet.fromMap(data)).toList();
  }

  /// Update a pet
  Future<void> updatePet({
    required String petId,
    String? name,
    String? type,
    String? breed,
    String? gender,
    String? age,
    String? weight, // New
    String? height, // New
    String? health,
    String? emoji,
    String? imageUrl,
    DateTime? nextCheckup,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (type != null) updates['type'] = type;
    if (breed != null) updates['breed'] = breed;
    if (gender != null) updates['gender'] = gender;
    if (age != null) updates['age'] = age;
    if (weight != null) updates['weight'] = weight;
    if (height != null) updates['height'] = height;
    if (health != null) updates['health'] = health;
    if (emoji != null) updates['emoji'] = emoji;
    if (imageUrl != null) updates['image_url'] = imageUrl;
    if (nextCheckup != null) {
      updates['next_checkup'] = nextCheckup.toIso8601String();
    }

    if (updates.isNotEmpty) {
      await _client.from(_tableName).update(updates).eq('id', petId);
    }
  }

  /// Delete a pet
  Future<void> deletePet(String petId) async {
    await _client.from(_tableName).delete().eq('id', petId);
  }

  // --- Health Events ---

  /// Get health events for a pet (petId is String UUID)
  Future<List<PetHealthEvent>> getHealthEvents(String petId) async {
    final response = await _client
        .from('pet_health_events')
        .select()
        .eq('pet_id', petId)
        .order('date', ascending: false);

    return (response as List).map((data) => PetHealthEvent.fromMap(data)).toList();
  }

  /// Add a health event
  Future<void> addHealthEvent(PetHealthEvent event) async {
    await _client.from('pet_health_events').insert({
      'pet_id': event.petId,
      'title': event.title,
      'date': event.date.toIso8601String(),
      'type': event.type,
      'notes': event.notes,
    });
  }

  /// Update a health event
  Future<void> updateHealthEvent(PetHealthEvent event) async {
    await _client.from('pet_health_events').update({
      'title': event.title,
      'date': event.date.toIso8601String(),
      'type': event.type,
      'notes': event.notes,
    }).eq('id', event.id);
  }

  /// Delete a health event
  Future<void> deleteHealthEvent(int eventId) async {
    await _client.from('pet_health_events').delete().eq('id', eventId);
  }
}
