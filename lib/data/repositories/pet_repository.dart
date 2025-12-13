import 'package:drift/drift.dart';
import '../local/database.dart';
import '../../services/pet_service.dart';
import '../../services/auth_service.dart';
import '../../models/app_models.dart';

/// Repository for offline-first pet management
class PetRepository {
  final AppDatabase _db = AppDatabase.instance;
  final PetService _petService = PetService();
  final AuthService _authService = AuthService();

  // Singleton
  static final PetRepository _instance = PetRepository._();
  PetRepository._();
  static PetRepository get instance => _instance;

  /// Watch current user's pets (local-first, reactive)
  Stream<List<LocalPet>> watchMyPets() {
    final userId = _authService.currentUser?.id;
    if (userId == null) return Stream.value([]);
    return _db.watchPets(userId);
  }

  /// Watch pets for any user
  Stream<List<LocalPet>> watchPets(String ownerId) {
    return _db.watchPets(ownerId);
  }

  /// Get pets for any user from cache
  Future<List<LocalPet>> getPetsByUserId(String userId, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final local = await _db.getPets(userId);
      if (local.isNotEmpty) return local;
    }

    await syncPetsForUser(userId);
    return _db.getPets(userId);
  }

  /// Get current user's pets from cache
  Future<List<LocalPet>> getMyPets({bool forceRefresh = false}) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return [];
    return getPetsByUserId(userId, forceRefresh: forceRefresh);
  }

  /// Sync pets from remote to local (defaults to current user)
  Future<void> syncPets() async {
    final userId = _authService.currentUser?.id;
    if (userId != null) {
      await syncPetsForUser(userId);
    }
  }

  /// Sync pets for specific user
  Future<void> syncPetsForUser(String userId) async {
    try {
      final pets = await _petService.getPetsByUserId(userId);
      final companions = pets.map(_mapPetToCompanion).toList();
      await _db.upsertPets(companions);
    } catch (e) {
      // Silently fail - use cached data
    }
  }

  /// Add a new pet (optimistic write + sync)
  Future<String?> addPet({
    required String name,
    required String type,
    String? breed,
    String? age,
    String? gender,
    String? weight,
    String? height,
    String? health,
    String? emoji,
    String? imageUrl,
    DateTime? nextCheckup,
  }) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return null;

    // Generate a temporary local ID
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    // Optimistic local insert
    await _db.insertPendingPet(LocalPetsCompanion(
      id: Value(tempId),
      ownerId: Value(userId),
      name: Value(name),
      type: Value(type),
      breed: Value(breed),
      age: Value(age),
      gender: Value(gender),
      weight: Value(weight),
      height: Value(height),
      health: Value(health),
      emoji: Value(emoji ?? '🐾'),
      imageUrl: Value(imageUrl),
      nextCheckup: Value(nextCheckup),
      createdAt: Value(DateTime.now()),
      syncStatus: const Value('pending'),
      isSynced: const Value(false),
    ));

    // Sync to remote
    try {
      await _petService.addPet(
        name: name,
        type: type,
        breed: breed,
        age: age,
        gender: gender,
        weight: weight,
        height: height,
        health: health,
        emoji: emoji,
        imageUrl: imageUrl,
        nextCheckup: nextCheckup,
      );

      // Trigger full sync to get real ID and replace temp
      await syncPets();
      return tempId;
    } catch (e) {
      // Leave as pending for later sync
    }

    return tempId;
  }

  /// Update existing pet (optimistic + sync)
  Future<void> updatePet({
    required String petId,
    String? name,
    String? type,
    String? breed,
    String? age,
    String? gender,
    String? weight,
    String? height,
    String? health,
    String? emoji,
    String? imageUrl,
    DateTime? nextCheckup,
  }) async {
    // Optimistic Update
    await (_db.update(_db.localPets)..where((p) => p.id.equals(petId))).write(
      LocalPetsCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        type: type != null ? Value(type) : const Value.absent(),
        breed: breed != null ? Value(breed) : const Value.absent(),
        age: age != null ? Value(age) : const Value.absent(),
        gender: gender != null ? Value(gender) : const Value.absent(),
        weight: weight != null ? Value(weight) : const Value.absent(),
        height: height != null ? Value(height) : const Value.absent(),
        health: health != null ? Value(health) : const Value.absent(),
        emoji: emoji != null ? Value(emoji) : const Value.absent(),
        imageUrl: imageUrl != null ? Value(imageUrl) : const Value.absent(),
        nextCheckup: nextCheckup != null ? Value(nextCheckup) : const Value.absent(),
        isSynced: const Value(false),
        syncStatus: const Value('pending_update'),
      ),
    );

    // Sync
    try {
      await _petService.updatePet(
        petId: petId,
        name: name,
        type: type,
        breed: breed,
        age: age,
        gender: gender,
        weight: weight,
        height: height,
        health: health,
        emoji: emoji,
        imageUrl: imageUrl,
        nextCheckup: nextCheckup,
      );
      
      // Mark synced
      await (_db.update(_db.localPets)..where((p) => p.id.equals(petId))).write(
        const LocalPetsCompanion(
          isSynced: Value(true),
          syncStatus: Value('synced'),
        ),
      );
    } catch (e) {
      // Leave as pending
    }
  }

  /// Delete pet (optimistic + sync)
  Future<void> deletePet(String petId) async {
    // Optimistic local delete
    await _db.deletePet(petId);

    // Sync
    try {
      await _petService.deletePet(petId);
    } catch (e) {
      // If we could determine it failed, we might want to re-add it or queue a delete operation.
      // For now, simple optimistic delete is usually sufficient unless strict consistency is needed.
      // To be robust, we should have a 'deleted_pets' table to queue deletions.
      // For this MVP, we will assume eventually consistent via full sync or direct retry.
    }
  }

  /// Upload pending pets that failed to sync
  Future<void> syncPendingPets() async {
    final pending = await _db.getPendingPets();
    
    for (final pet in pending) {
      try {
        await _petService.addPet(
          name: pet.name,
          type: pet.type,
          breed: pet.breed,
          age: pet.age,
          gender: pet.gender,
          weight: pet.weight,
          height: pet.height,
          health: pet.health,
          emoji: pet.emoji,
          imageUrl: pet.imageUrl,
          nextCheckup: pet.nextCheckup,
        );
        
        // Mark as synced
        await _db.upsertPet(LocalPetsCompanion(
          id: Value(pet.id),
          ownerId: Value(pet.ownerId),
          name: Value(pet.name),
          type: Value(pet.type),
          createdAt: Value(pet.createdAt),
          syncStatus: const Value('synced'),
          isSynced: const Value(true),
        ));
      } catch (e) {
        // Leave as pending
      }
    }
  }

  /// Map Pet model to Drift companion
  LocalPetsCompanion _mapPetToCompanion(Pet pet) {
    return LocalPetsCompanion(
      id: Value(pet.id),
      ownerId: Value(pet.ownerId),
      name: Value(pet.name),
      type: Value(pet.type),
      breed: Value(pet.breed),
      age: Value(pet.age),
      gender: Value(pet.gender),
      weight: Value(pet.weight),
      height: Value(pet.height),
      health: Value(pet.health),
      emoji: Value(pet.emoji),
      imageUrl: Value(pet.imageUrl),
      nextCheckup: const Value(null),
      createdAt: Value(DateTime.now()),
      isSynced: const Value(true),
      syncStatus: const Value('synced'),
    );
  }

  /// Convert LocalPet to Pet model for UI
  Pet localPetToPet(LocalPet local) {
    return Pet(
      id: local.id,
      ownerId: local.ownerId,
      name: local.name,
      type: local.type,
      breed: local.breed ?? '',
      gender: local.gender ?? 'Unknown',
      age: local.age ?? '',
      weight: local.weight ?? '',
      height: local.height ?? '',
      health: local.health ?? 'Healthy',
      emoji: local.emoji ?? '🐾',
      imageUrl: local.imageUrl ?? '',
      nextCheckup: local.nextCheckup?.toIso8601String() ?? '',
    );
  }
}
