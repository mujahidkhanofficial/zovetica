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
      // Fetch directly from 'users' table where role is 'doctor'
      debugPrint("Fetching doctors from Users table...");
      final response = await _client
          .from('users')
          .select()
          .eq('role', 'doctor')
          .order('id');
      
      debugPrint("Doctors fetch raw response: $response");

      final doctors = (response as List).map((data) => _mapUserDataToDoctor(data)).toList();
      debugPrint("Parsed ${doctors.length} doctors");
      return doctors;
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
      return [];
    }
  }

  Doctor _mapUserDataToDoctor(Map<String, dynamic> data) {
    return Doctor(
      id: data['id']?.toString() ?? '', 
      name: data['name'] ?? 'Unknown Doctor',
      specialty: data['specialty'] ?? 'General Veterinarian',
      rating: (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0,
      reviews: data['reviews_count'] ?? 0,
      nextAvailable: 'Available',
      clinic: data['clinic'] ?? 'Zovetica Clinic',
      image: data['profile_image'] ?? '',
      available: true,
      userId: data['id']?.toString(), // For users table, id IS the user_id
    );
  }
}
