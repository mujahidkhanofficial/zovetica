import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../local/database.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../models/app_models.dart';

/// Repository for offline-first appointment management
class AppointmentRepository {
  final AppDatabase _db = AppDatabase.instance;
  final AppointmentService _appointmentService = AppointmentService();
  final AuthService _authService = AuthService();

  // Singleton
  static final AppointmentRepository _instance = AppointmentRepository._();
  AppointmentRepository._();
  static AppointmentRepository get instance => _instance;

  /// Watch current user's appointments (local-first, reactive)
  Stream<List<LocalAppointment>> watchMyAppointments() {
    final userId = _authService.currentUser?.id;
    if (userId == null) return Stream.value([]);
    return _db.watchAppointments(userId);
  }

  /// Get current user's appointments from cache
  Future<List<LocalAppointment>> getMyAppointments({bool forceRefresh = false}) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return [];

    if (!forceRefresh) {
      final local = await _db.getAppointments(userId);
      if (local.isNotEmpty) return local;
    }

    await syncAppointments();
    return _db.getAppointments(userId);
  }

  /// Sync appointments from remote to local
  Future<void> syncAppointments() async {
    try {
      final appointments = await _appointmentService.getUserAppointments();
      final companions = appointments.map(_mapAppointmentToCompanion).toList();
      await _db.upsertAppointments(companions);
    } catch (e) {
      // Silently fail - use cached data
    }
  }

  /// Book a new appointment (optimistic write + sync)
  Future<String?> bookAppointment({
    required String doctorId,
    required String petId,
    required DateTime date,
    required String time,
    required String type,
    String? doctorName,
    String? doctorImage,
    String? doctorSpecialty,
    String? clinicName,
    String? petName,
    String? petEmoji,
  }) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return null;

    // Generate a temporary local ID
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    // Optimistic local insert
    await _db.insertPendingAppointment(LocalAppointmentsCompanion(
      id: Value(tempId),
      userId: Value(userId),
      doctorId: Value(doctorId),
      petId: Value(petId),
      date: Value(date),
      time: Value(time),
      type: Value(type),
      status: const Value('pending'),
      doctorName: Value(doctorName),
      doctorImage: Value(doctorImage),
      doctorSpecialty: Value(doctorSpecialty),
      clinicName: Value(clinicName),
      petName: Value(petName),
      petEmoji: Value(petEmoji),
      createdAt: Value(DateTime.now()),
      syncStatus: const Value('pending'),
      isSynced: const Value(false),
    ));

    // Sync to remote
    try {
      await _appointmentService.bookAppointment(
        doctorId: doctorId,
        petId: petId,
        date: date,
        time: time,
        type: type,
      );

      // Mark as synced
      await _db.upsertAppointment(LocalAppointmentsCompanion(
        id: Value(tempId),
        userId: Value(userId),
        doctorId: Value(doctorId),
        petId: Value(petId),
        date: Value(date),
        time: Value(time),
        type: Value(type),
        status: const Value('pending'),
        doctorName: Value(doctorName),
        doctorImage: Value(doctorImage),
        doctorSpecialty: Value(doctorSpecialty),
        clinicName: Value(clinicName),
        petName: Value(petName),
        petEmoji: Value(petEmoji),
        createdAt: Value(DateTime.now()),
        syncStatus: const Value('synced'),
        isSynced: const Value(true),
      ));
      
      // Trigger full sync to get real ID
      await syncAppointments();
      return tempId;
    } catch (e) {
      // Leave as pending for later sync
    }

    return tempId;
  }

  /// Cancel an appointment
  Future<bool> cancelAppointment(String appointmentId) async {
    // Optimistic local update
    await _db.updateAppointmentStatus(appointmentId, 'cancelled');

    // Sync to remote
    try {
      await _appointmentService.cancelAppointment(appointmentId);
      return true;
    } catch (e) {
      // Revert if needed, or leave for later sync
      return false;
    }
  }

  /// Sync pending appointments
  Future<void> syncPendingAppointments() async {
    final pending = await _db.getPendingAppointments();
    for (final appt in pending) {
      try {
        await _appointmentService.bookAppointment(
          doctorId: appt.doctorId,
          petId: appt.petId,
          date: appt.date,
          time: appt.time,
          type: appt.type,
        );

        // Mark as synced
        await _db.upsertAppointment(LocalAppointmentsCompanion(
          id: Value(appt.id),
          userId: Value(appt.userId),
          doctorId: Value(appt.doctorId),
          petId: Value(appt.petId),
          date: Value(appt.date),
          time: Value(appt.time),
          type: Value(appt.type),
          status: Value(appt.status),
          createdAt: Value(appt.createdAt),
          syncStatus: const Value('synced'),
          isSynced: const Value(true),
        ));
      } catch (e) {
        // Leave as pending
      }
    }
  }

  /// Map Appointment model to Drift companion
  LocalAppointmentsCompanion _mapAppointmentToCompanion(Appointment appt) {
    return LocalAppointmentsCompanion(
      id: Value(appt.uuid ?? appt.id.toString()),
      userId: Value(_authService.currentUser?.id ?? ''),
      doctorId: Value(appt.doctorId ?? ''),
      petId: Value(appt.petId ?? ''),
      date: Value(DateTime.tryParse(appt.date) ?? DateTime.now()),
      time: Value(appt.time),
      type: Value(appt.type),
      status: Value(appt.status),
      doctorName: Value(appt.doctor),
      doctorImage: Value(appt.doctorImage),
      // HACK: Store petImage in doctorSpecialty since we can't change schema without build_runner
      // This column is unused in Doctor View (we use doctor/patient name field)
      doctorSpecialty: Value(appt.petImage), 
      clinicName: Value(appt.clinic),
      petName: Value(appt.pet),
      createdAt: Value(DateTime.now()),
      isSynced: const Value(true),
      syncStatus: const Value('synced'),
    );
  }

  /// Convert LocalAppointment to Appointment model for UI
  Appointment localToAppointment(LocalAppointment local) {
    return Appointment(
      id: 0,
      uuid: local.id,
      doctor: local.doctorName ?? 'Doctor',
      doctorId: local.doctorId,
      // For doctor view, 'doctorImage' holds the patient/owner image
      // We map it to BOTH doctorImage and ownerImage to cover all UI cases
      doctorImage: local.doctorImage,
      ownerImage: local.doctorImage, 
      clinic: local.clinicName ?? '',
      type: local.type,
      date: '${local.date.year}-${local.date.month.toString().padLeft(2, '0')}-${local.date.day.toString().padLeft(2, '0')}',
      time: local.time,
      pet: local.petName ?? 'Pet',
      petId: local.petId,
      // Restore petImage from hijacked doctorSpecialty column
      petImage: local.doctorSpecialty,
      status: local.status,
    );
  }
  // ============================================
  // DOCTOR SPECIFIC METHODS
  // ============================================

  /// Watch appointments for a specific doctor
  Stream<List<LocalAppointment>> watchDoctorAppointments(String doctorId) {
    return (_db.select(_db.localAppointments)
          ..where((a) => a.doctorId.equals(doctorId))
          ..orderBy([(a) => OrderingTerm.desc(a.date)]))
        .watch();
  }
  
  /// Get appointments for a specific doctor
  Future<List<LocalAppointment>> getDoctorAppointments(String doctorId, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final local = await (_db.select(_db.localAppointments)
            ..where((a) => a.doctorId.equals(doctorId)))
          .get();
      if (local.isNotEmpty) return local;
    }
    
    await syncDoctorAppointments(doctorId);
    return (_db.select(_db.localAppointments)
          ..where((a) => a.doctorId.equals(doctorId)))
        .get();
  }

  /// Update appointment status
  Future<void> updateAppointmentStatus(String id, String status) async {
    // Optimistic local update
    await (_db.update(_db.localAppointments)..where((a) => a.id.equals(id))).write(
      LocalAppointmentsCompanion(status: Value(status)),
    );
    
    // Sync
    try {
      await _appointmentService.updateAppointmentStatus(
        appointmentId: id,
        status: status,
      );
    } catch (e) {
      // Retry later
    }
  }

  /// Reschedule an appointment (doctor emergency)
  Future<void> rescheduleAppointment({
    required String appointmentId,
    required DateTime newDate,
    required String newTime,
  }) async {
    // Optimistic local update - set to rescheduled_pending for pet owner approval
    await (_db.update(_db.localAppointments)..where((a) => a.id.equals(appointmentId))).write(
      LocalAppointmentsCompanion(
        date: Value(newDate),
        time: Value(newTime),
        status: const Value('rescheduled_pending'),
      ),
    );
    
    // Sync to Supabase
    try {
      final dateStr = '${newDate.year}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}';
      await _appointmentService.rescheduleAppointment(
        appointmentId: appointmentId,
        newDate: dateStr,
        newTime: newTime,
      );
    } catch (e) {
      debugPrint('❌ Error syncing rescheduled appointment: $e');
    }
  }

  /// Sync appointments for a doctor
  Future<void> syncDoctorAppointments(String doctorId) async {
    try {
      final appointments = await _appointmentService.getDoctorAppointments(doctorId);
      final companions = appointments.map(_mapAppointmentToCompanion).toList();
      await _db.upsertAppointments(companions);
      debugPrint('✅ Synced ${appointments.length} appointments to local DB.');
    } catch (e) {
      debugPrint('❌ Error syncing doctor appointments: $e');
    }
  }

  /// Get doctor by User ID (for dashboard caching)
  Future<LocalDoctor?> getDoctorByUserId(String userId) {
    return (_db.select(_db.localDoctors)..where((d) => d.userId.equals(userId))..limit(1)).getSingleOrNull();
  }

  /// Upsert doctor profile (local cache)
  Future<void> upsertDoctor(LocalDoctorsCompanion doctor) async {
    await _db.into(_db.localDoctors).insertOnConflictUpdate(doctor);
  }

  /// Delete doctor mapping (used for cleaning up bad cache)
  Future<void> deleteDoctor(String id) async {
    await (_db.delete(_db.localDoctors)..where((d) => d.id.equals(id))).go();
  }

  /// Watch availability slots
  Stream<List<LocalSlot>> watchAvailabilitySlots(String doctorId) {
    return _db.watchSlots(doctorId);
  }

  /// Get availability slots
  Future<List<LocalSlot>> getAvailabilitySlots(String doctorId, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final local = await _db.getSlots(doctorId);
      if (local.isNotEmpty) return local;
    }
    
    await syncAvailabilitySlots(doctorId);
    return _db.getSlots(doctorId);
  }

  /// Sync availability slots
  Future<void> syncAvailabilitySlots(String doctorId) async {
    try {
      final slots = await _appointmentService.getAvailabilitySlots(doctorId);
      final companions = slots.map((data) => LocalSlotsCompanion(
        id: Value(data['id']?.toString() ?? ''),
        doctorId: Value(doctorId),
        day: Value(data['day'] ?? ''),
        startTime: Value(data['start_time'] ?? ''),
        endTime: Value(data['end_time'] ?? ''),
        isSynced: const Value(true),
        syncStatus: const Value('synced'),
      )).toList();
      
      // CRITICAL FIX: Delete all temp/pending slots first to prevent duplicates
      // Temp slots have IDs starting with 'temp_slot_' and won't match synced ones
      await _db.deletePendingSlots(doctorId);
      
      await _db.upsertSlots(companions);
    } catch (e) {
      // Silently fail
    }
  }

  /// Add availability slot (optimistic)
  Future<void> addAvailabilitySlot({
    required String doctorId,
    required String day,
    required String startTime,
    required String endTime,
  }) async {
    // Temp ID
    final tempId = 'temp_slot_${DateTime.now().millisecondsSinceEpoch}';

    // Optimistic insert
    await _db.insertPendingSlot(LocalSlotsCompanion(
      id: Value(tempId),
      doctorId: Value(doctorId),
      day: Value(day),
      startTime: Value(startTime),
      endTime: Value(endTime),
      isSynced: const Value(false),
      syncStatus: const Value('pending'),
    ));

    // Sync
    try {
      await _appointmentService.addAvailabilitySlot(
        doctorId: doctorId,
        day: day,
        startTime: startTime,
        endTime: endTime,
      );
      
      // Update local with synced status (usually we'd get real ID back, but for MVP we trigger sync)
      await syncAvailabilitySlots(doctorId);
    } catch (e) {
      // Leave pending
    }
  }

  /// Remove availability slot
  Future<void> removeAvailabilitySlot(String slotId) async {
    // Optimistic soft delete
    await _db.deleteSlot(slotId);

    // Sync
    try {
      await _appointmentService.removeAvailabilitySlot(slotId);
    } catch (e) {
      // Retry later via sync job
    }
  }

  /// Convert LocalSlot to AvailabilitySlot model
  AvailabilitySlot localSlotToSlot(LocalSlot local) {
    return AvailabilitySlot(
      id: local.id,
      day: local.day,
      startTime: local.startTime,
      endTime: local.endTime,
    );
  }
}
