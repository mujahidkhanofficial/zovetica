import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import 'supabase_service.dart';

/// Doctor service for listing and profile operations
class DoctorService {
  final _client = SupabaseService.client;
  static const String _tableName = 'users'; // Doctors are users with role 'doctor'

  /// Get all verified doctors
  Future<List<Doctor>> getDoctors() async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('role', 'doctor');

      return (response as List).map((data) => _mapUserToDoctor(data)).toList();
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
      return [];
    }
  }

  Doctor _mapUserToDoctor(Map<String, dynamic> data) {
    return Doctor(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Unknown Doctor',
      specialty: data['specialty'] ?? 'General Veterinarian',
      rating: (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0, // 0.0 = no rating
      reviews: data['reviews_count'] ?? 0,
       // Provide default if missing
      nextAvailable: 'Available', 
      clinic: data['clinic'] ?? 'Zovetica Clinic',
      image: data['profile_image'] ?? '',
      available: true,
    );
  }
}
