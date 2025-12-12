import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

    try {
      // Join with doctors table, then get user info from doctors.user_id
      final response = await _client
          .from(_tableName)
          .select('*, pets(*), doctors!appointments_doctor_id_fkey(*, users(*))')
          .eq('user_id', userId)
          .order('date', ascending: true);

      return _parseAppointmentsWithDoctors(response);
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
      return [];
    }
  }

  /// Get appointments for current logged-in doctor
  Future<List<Appointment>> getMyDoctorAppointments() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    try {
      // 1. Get doctor_id from users table (or doctors table via user_id)
      final doctorId = await _getDoctorIdFromUserId(userId);
      if (doctorId == null) return [];

      // 2. Fetch appointments for this doctor
      return await getDoctorAppointments(doctorId);
    } catch (e) {
      debugPrint('Error fetching my doctor appointments: $e');
      return [];
    }
  }

  /// Get appointment count for user
  Future<int> getAppointmentCount(String userId) async {
    final response = await _client
        .from(_tableName)
        .select('id')
        .eq('user_id', userId)
        .count(CountOption.exact);
        
    return response.count;
  }

  /// Get appointments for doctor
  Future<List<Appointment>> getDoctorAppointments(String doctorId) async {
    try {
      debugPrint('Fetching appointments for doctor_id: $doctorId');
      
      // Simple query without complex joins to avoid foreign key issues
      final response = await _client
          .from(_tableName)
          .select()
          .eq('doctor_id', doctorId)
          .order('date', ascending: true);

      debugPrint('Raw response: ${response.length} items');
      
      if (response.isEmpty) {
        return [];
      }

      // Now get pet and user data for each appointment
      List<Appointment> appointments = [];
      for (var data in response) {
        // Fetch pet info
        Map<String, dynamic> petData = {};
        if (data['pet_id'] != null) {
          try {
            final petResponse = await _client
                .from('pets')
                .select()
                .eq('id', data['pet_id'])
                .maybeSingle();
            petData = petResponse ?? {};
          } catch (e) {
            debugPrint('Error fetching pet: $e');
          }
        }

        // Fetch patient (user) info
        Map<String, dynamic> patientData = {};
        if (data['user_id'] != null) {
          try {
            final userResponse = await _client
                .from('users')
                .select()
                .eq('id', data['user_id'])
                .maybeSingle();
            patientData = userResponse ?? {};
          } catch (e) {
            debugPrint('Error fetching user: $e');
          }
        }

        appointments.add(Appointment(
          id: data['id'] is int ? data['id'] : data['id'].hashCode,
          uuid: data['id']?.toString(), // Store actual UUID for updates
          doctor: patientData['name'] ?? 'Unknown Patient',
          doctorImage: patientData['profile_image'], // Map patient image to avatar slot
          clinic: 'Pet Owner', // Show role instead of fake clinic
          date: data['date'] ?? '',
          time: data['time'] ?? '',
          pet: petData['name'] ?? 'Pet',
          type: data['type'] ?? '',
          status: data['status'] ?? 'pending',
          petId: petData['id']?.toString(),
          petImage: petData['image_url'],
          ownerId: patientData['id']?.toString(),
          ownerImage: patientData['profile_image'],
        ));
      }

      debugPrint('Found ${appointments.length} appointments for doctor');
      return appointments;
    } catch (e) {
      debugPrint('Error fetching doctor appointments: $e');
      return [];
    }
  }

  /// Parse appointments for doctor view
  List<Appointment> _parseDoctorAppointments(List<dynamic> response) {
    return response.map((data) {
      // 'patient' alias from the query for user data (pet owner)
      final patientData = data['patient'] ?? {};
      final petData = data['pets'] ?? {};

      return Appointment(
        id: data['id'] is int ? data['id'] : data['id'].hashCode,
        doctor: patientData['name'] ?? 'Unknown Patient',
        doctorImage: patientData['profile_image'], // Map for avatar
        clinic: 'Pet Owner',
        date: data['date'] ?? '',
        time: data['time'] ?? '',
        pet: petData['name'] ?? 'Pet',
        type: data['type'] ?? '',
        status: data['status'] ?? 'pending',
        petId: petData['id']?.toString(),
        petImage: petData['image_url'],
        ownerId: patientData['id']?.toString(),
        ownerImage: patientData['profile_image'],
      );
    }).toList();
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

  /// Reschedule appointment (update date and time)
  Future<void> rescheduleAppointment({
    required String appointmentId,
    required String newDate,
    required String newTime,
  }) async {
    await _client
        .from(_tableName)
        .update({
          'date': newDate,
          'time': newTime,
          'status': 'pending', // Reset to pending for doctor approval
        })
        .eq('id', appointmentId);
  }

  /// Helper: Get the doctor table ID from the user ID
  /// Since doctors are stored in both 'users' (user_id) and 'doctors' (doctor_id) tables
  Future<String?> _getDoctorIdFromUserId(String userId) async {
    try {
      final response = await _client
          .from('doctors')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      
      return response?['id']?.toString();
    } catch (e) {
      debugPrint('Error getting doctor ID: $e');
      return null;
    }
  }

  /// Get available slots for a doctor (accepts user_id, resolves to doctor_id if needed)
  Future<List<Map<String, dynamic>>> getAvailabilitySlots(String doctorUserId) async {
    // First try with the given ID (might be doctor_id directly)
    var response = await _client
        .from(_slotsTable)
        .select()
        .eq('doctor_id', doctorUserId)
        .order('day');

    // If no results, try looking up the doctor_id from user_id
    if ((response as List).isEmpty) {
      final actualDoctorId = await _getDoctorIdFromUserId(doctorUserId);
      if (actualDoctorId != null) {
        response = await _client
            .from(_slotsTable)
            .select()
            .eq('doctor_id', actualDoctorId)
            .order('day');
      }
    }

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
  List<Appointment> _parseAppointments(List<dynamic> response, {bool isDoctorView = false}) {
    return response.map((data) {
      // If doctor view, 'patient' alias contains user info. If user view, 'users' (doctor) contains info.
      final userData = isDoctorView ? (data['patient'] ?? {}) : (data['users'] ?? {});
      final petData = data['pets'] ?? {};

      return Appointment(
        id: data['id'] is int ? data['id'] : data['id'].hashCode,
        uuid: data['id']?.toString(), // Store actual UUID for database operations
        doctorId: data['doctor_id']?.toString(), // Doctor's ID for fetching available slots
        doctorImage: userData['profile_image'], // Doctor's profile image
        // For doctor view, this field effectively becomes "Patient Name"
        doctor: userData['name'] ?? (isDoctorView ? 'Unknown Patient' : 'Doctor'),
        clinic: userData['clinic'] ?? (isDoctorView ? 'Virtual Clinic' : 'Zovetica Clinic'), 
        date: data['date'] ?? '',
        time: data['time'] ?? '',
        pet: petData['name'] ?? 'Pet',
        type: data['type'] ?? '',
        status: data['status'] ?? 'pending',
        petId: petData['id']?.toString(),
        petImage: petData['image_url'],
        ownerId: userData['id']?.toString(),
        ownerImage: userData['profile_image'],
      );
    }).toList();
  }

  /// Parse appointments with doctors table join (for pet owner view)
  List<Appointment> _parseAppointmentsWithDoctors(List<dynamic> response) {
    return response.map((data) {
      final doctorData = data['doctors'] ?? {};
      final userData = doctorData['users'] ?? {};
      final petData = data['pets'] ?? {};

      return Appointment(
        id: data['id'] is int ? data['id'] : data['id'].hashCode,
        uuid: data['id']?.toString(), // Store actual UUID for database operations
        doctorId: data['doctor_id']?.toString(), // Doctor's ID for fetching available slots
        doctorImage: userData['profile_image'], // Doctor's profile image
        doctor: userData['name'] ?? doctorData['specialty'] ?? 'Doctor',
        clinic: userData['clinic'] ?? doctorData['clinic'] ?? 'Zovetica Clinic', 
        date: data['date'] ?? '',
        time: data['time'] ?? '',
        pet: petData['name'] ?? 'Pet',
        type: data['type'] ?? '',
        status: data['status'] ?? 'pending',
        petId: petData['id']?.toString(),
        petImage: petData['image_url'],
        ownerId: userData['id']?.toString(),
        ownerImage: userData['profile_image'],
      );
    }).toList();
  }

  // ============ REAL-TIME AVAILABILITY METHODS ============

  /// Get available time slots for a doctor on a specific date
  /// Generates 30-minute slots based on doctor's working hours
  /// and excludes already booked slots
  Future<List<Map<String, dynamic>>> getAvailableSlotsForDate(
    String doctorUserId,
    DateTime date,
  ) async {
    try {
      // Resolve the actual doctor_id from the doctors table
      String? actualDoctorId = doctorUserId;
      final doctorIdFromTable = await _getDoctorIdFromUserId(doctorUserId);
      if (doctorIdFromTable != null) {
        actualDoctorId = doctorIdFromTable;
      }

      // Get day of week (1=Monday, 7=Sunday)
      final dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final dayName = dayNames[date.weekday];
      
      // Get doctor's availability for this day
      final availability = await _client
          .from(_slotsTable)
          .select()
          .eq('doctor_id', actualDoctorId)
          .eq('day', dayName)
          .maybeSingle();

      if (availability == null) {
        // Doctor not available on this day
        return [];
      }

      final startTime = availability['start_time'] as String; // "09:00"
      final endTime = availability['end_time'] as String;     // "17:00"

      // Get existing appointments for this doctor on this date
      final dateStr = date.toIso8601String().split('T')[0];
      final existingAppointments = await _client
          .from(_tableName)
          .select('time')
          .eq('doctor_id', actualDoctorId)
          .eq('date', dateStr)
          .neq('status', 'cancelled');

      final bookedTimes = (existingAppointments as List)
          .map((a) => a['time'] as String)
          .toSet();

      // Generate 30-minute slots
      final slots = <Map<String, dynamic>>[];
      var currentTime = _parseTime(startTime);
      final end = _parseTime(endTime);

      while (_timeToMinutes(currentTime) < _timeToMinutes(end)) {
        final timeStr = _formatTime(currentTime);
        final isBooked = bookedTimes.contains(timeStr);
        
        // Determine label based on hour
        String label;
        if (currentTime.hour < 12) {
          label = 'Morning';
        } else if (currentTime.hour < 17) {
          label = 'Afternoon';
        } else {
          label = 'Evening';
        }

        slots.add({
          'time': timeStr,
          'displayTime': _formatDisplayTime(currentTime),
          'isAvailable': !isBooked,
          'label': label,
        });

        // Add 30 minutes
        currentTime = TimeOfDay(
          hour: currentTime.hour + (currentTime.minute + 30) ~/ 60,
          minute: (currentTime.minute + 30) % 60,
        );
      }

      return slots;
    } catch (e) {
      debugPrint('Error getting available slots: $e');
      return [];
    }
  }

  /// Check if a specific slot is still available (real-time check)
  Future<bool> isSlotAvailable(String doctorId, DateTime date, String time) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final existing = await _client
          .from(_tableName)
          .select('id')
          .eq('doctor_id', doctorId)
          .eq('date', dateStr)
          .eq('time', time)
          .neq('status', 'cancelled')
          .maybeSingle();
      
      return existing == null;
    } catch (e) {
      debugPrint('Error checking slot availability: $e');
      return false;
    }
  }

  /// Book appointment with real-time slot verification
  Future<void> bookWithSlotCheck({
    required String doctorUserId,
    required String petId,
    required DateTime date,
    required String time,
    required String type,
    int? priceInPKR,
  }) async {
    // Resolve the actual doctor_id from the doctors table
    String actualDoctorId = doctorUserId;
    final doctorIdFromTable = await _getDoctorIdFromUserId(doctorUserId);
    if (doctorIdFromTable != null) {
      actualDoctorId = doctorIdFromTable;
    }

    // First check if slot is still available
    final isAvailable = await isSlotAvailable(doctorUserId, date, time);
    if (!isAvailable) {
      throw Exception('This time slot is no longer available. Please select another slot.');
    }

    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Check for existing pending request for this doctor
    final hasPending = await checkPendingRequest(userId, actualDoctorId);
    if (hasPending) {
      throw Exception('You already have a pending request with this doctor. Please wait for them to respond.');
    }

    await _client.from(_tableName).insert({
      'user_id': userId,
      'doctor_id': actualDoctorId,
      'pet_id': petId,
      'date': date.toIso8601String().split('T')[0],
      'time': time,
      'type': type,
      'status': 'pending',
      'price': priceInPKR,
    });
  }

  /// Check if user already has a pending request with this doctor
  Future<bool> checkPendingRequest(String userId, String doctorId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('id')
          .eq('user_id', userId)
          .eq('doctor_id', doctorId)
          .eq('status', 'pending')
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      debugPrint('Error checking pending requests: $e');
      return false; // Fail safe, allow request if check errors (or handle differently)
    }
  }

  /// Get dates with availability for a doctor (next 30 days)
  Future<List<DateTime>> getAvailableDates(String doctorId) async {
    try {
      // Get doctor's weekly availability
      final availability = await getAvailabilitySlots(doctorId);
      if (availability.isEmpty) return [];

      final availableDays = availability.map((a) => a['day'] as String).toSet();
      final dayNameToWeekday = {
        'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4,
        'Friday': 5, 'Saturday': 6, 'Sunday': 7,
      };

      final availableWeekdays = availableDays
          .map((day) => dayNameToWeekday[day])
          .whereType<int>()
          .toSet();

      // Generate next 30 days that match availability
      final dates = <DateTime>[];
      final today = DateTime.now();
      
      for (var i = 1; i <= 30; i++) {
        final date = today.add(Duration(days: i));
        if (availableWeekdays.contains(date.weekday)) {
          dates.add(date);
        }
      }

      return dates;
    } catch (e) {
      debugPrint('Error getting available dates: $e');
      return [];
    }
  }

  // Helper methods
  TimeOfDay _parseTime(String time) {
    // Handle both "09:00" and "09:00 AM" formats
    time = time.trim();
    
    // Check for AM/PM format
    final isPM = time.toUpperCase().contains('PM');
    final isAM = time.toUpperCase().contains('AM');
    
    // Remove AM/PM suffix
    time = time.replaceAll(RegExp(r'[APap][Mm]', caseSensitive: false), '').trim();
    
    final parts = time.split(':');
    var hour = int.parse(parts[0].trim());
    final minute = int.parse(parts[1].trim().split(' ')[0]); // Handle extra spaces
    
    // Convert 12-hour to 24-hour format
    if (isPM && hour < 12) {
      hour += 12;
    } else if (isAM && hour == 12) {
      hour = 0;
    }
    
    return TimeOfDay(hour: hour, minute: minute);
  }

  int _timeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String _formatDisplayTime(TimeOfDay time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
