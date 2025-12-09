import 'supabase_service.dart';
import '../models/app_models.dart';

/// Appointment service for booking and management
class AppointmentService {
  final _client = SupabaseService.client;
  static const String _tableName = 'appointments';
  static const String _slotsTable = 'availability_slots';

  /// Book a new appointment
  Future<void> bookAppointment({
    required String doctorId,
    required String petId,
    required DateTime date,
    required String time,
    required String type,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client.from(_tableName).insert({
      'user_id': userId,
      'doctor_id': doctorId,
      'pet_id': petId,
      'date': date.toIso8601String().split('T')[0],
      'time': time,
      'type': type,
      'status': 'pending',
    });
  }

  /// Get appointments for current user (pet owner)
  Future<List<Appointment>> getUserAppointments() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from(_tableName)
        .select('*, doctors(*, users(*)), pets(*)')
        .eq('user_id', userId)
        .order('date', ascending: true);

    return _parseAppointments(response);
  }

  /// Get appointments for doctor
  Future<List<Appointment>> getDoctorAppointments(String doctorId) async {
    final response = await _client
        .from(_tableName)
        .select('*, doctors(*, users(*)), pets(*)')
        .eq('doctor_id', doctorId)
        .order('date', ascending: true);

    return _parseAppointments(response);
  }

  /// Update appointment status
  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    await _client
        .from(_tableName)
        .update({'status': status})
        .eq('id', appointmentId);
  }

  /// Cancel appointment
  Future<void> cancelAppointment(String appointmentId) async {
    await updateAppointmentStatus(
      appointmentId: appointmentId,
      status: 'cancelled',
    );
  }

  /// Get available slots for a doctor
  Future<List<Map<String, dynamic>>> getAvailabilitySlots(
      String doctorId) async {
    final response = await _client
        .from(_slotsTable)
        .select()
        .eq('doctor_id', doctorId)
        .order('day');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Add availability slot (for doctors)
  Future<void> addAvailabilitySlot({
    required String doctorId,
    required String day,
    required String startTime,
    required String endTime,
  }) async {
    await _client.from(_slotsTable).insert({
      'doctor_id': doctorId,
      'day': day,
      'start_time': startTime,
      'end_time': endTime,
    });
  }

  /// Remove availability slot
  Future<void> removeAvailabilitySlot(String slotId) async {
    await _client.from(_slotsTable).delete().eq('id', slotId);
  }

  /// Parse appointments from response
  List<Appointment> _parseAppointments(List<dynamic> response) {
    return response.map((data) {
      final doctorData = data['doctors'] ?? {};
      final doctorUser = doctorData['users'] ?? {};
      final petData = data['pets'] ?? {};

      return Appointment(
        id: data['id'].hashCode,
        doctor: doctorUser['name'] ?? 'Unknown Doctor',
        clinic: doctorData['clinic'] ?? '',
        date: data['date'] ?? '',
        time: data['time'] ?? '',
        pet: petData['name'] ?? 'Unknown Pet',
        type: data['type'] ?? '',
        status: data['status'] ?? 'pending',
      );
    }).toList();
  }
}
