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
    String? age,
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
      'age': age,
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
    String? age,
    String? health,
    String? emoji,
    String? imageUrl,
    DateTime? nextCheckup,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (type != null) updates['type'] = type;
    if (breed != null) updates['breed'] = breed;
    if (age != null) updates['age'] = age;
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
}
