import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart'; // Needed for debugPrint
import '../local/database.dart';
import '../../services/doctor_service.dart';
import '../../models/app_models.dart';

/// Repository for offline-first doctor listing
class DoctorRepository {
  final AppDatabase _db = AppDatabase.instance;
  final DoctorService _doctorService = DoctorService();

  // Singleton
  static final DoctorRepository _instance = DoctorRepository._();
  DoctorRepository._();
  static DoctorRepository get instance => _instance;

  /// Watch all doctors (local-first, reactive)
  Stream<List<LocalDoctor>> watchDoctors() {
    return _db.watchDoctors();
  }

  /// Get doctors from cache
  Future<List<LocalDoctor>> getDoctors({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final local = await _db.getDoctors();
      if (local.isNotEmpty) return local;
    }
    await syncDoctors();
    return _db.getDoctors();
  }

  /// Sync doctors from remote to local
  Future<void> syncDoctors() async {
    try {
      debugPrint("Syncing doctors...");
      final doctors = await _doctorService.getDoctors();
      debugPrint("Got ${doctors.length} doctors from service");
      final companions = doctors.map(_mapDoctorToCompanion).toList();
      await _db.upsertDoctors(companions);
      debugPrint("Upserted doctors to local DB");
    } catch (e) {
      debugPrint("Error syncing doctors: $e");
      // Silently fail - use cached data
    }
  }

  /// Map Doctor model to Drift companion
  LocalDoctorsCompanion _mapDoctorToCompanion(Doctor doctor) {
    return LocalDoctorsCompanion(
      id: Value(doctor.id),
      userId: Value(doctor.userId ?? ''), // Correctly map User ID
      name: Value(doctor.name),
      specialty: Value(doctor.specialty),
      clinic: Value(doctor.clinic),
      rating: Value(doctor.rating),
      reviewsCount: Value(doctor.reviews),
      profileImage: Value(doctor.image),
      nextAvailable: Value(doctor.nextAvailable),
      available: Value(doctor.available),
      verified: const Value(false),
      createdAt: Value(DateTime.now()),
      isSynced: const Value(true),
    );
  }

  /// Convert LocalDoctor to Doctor model for UI
  Doctor localDoctorToDoctor(LocalDoctor local) {
    return Doctor(
      id: local.id,
      name: local.name,
      specialty: local.specialty ?? '',
      clinic: local.clinic ?? '',
      rating: local.rating,
      reviews: local.reviewsCount,
      nextAvailable: local.nextAvailable ?? '',
      image: local.profileImage ?? '',
      available: local.available,
      userId: local.userId,
    );
  }
}
