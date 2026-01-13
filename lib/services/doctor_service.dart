import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import 'supabase_service.dart';

/// Doctor service for listing and profile operations
class DoctorService {
  final _client = SupabaseService.client;

  /// Get all verified doctors directly from the users table
  Future<List<Doctor>> getDoctors() async {
    try {
      // Fetch from 'users' table where role is 'doctor'
      // We use the 'users' table for both pet owners and doctors now
      final response = await _client
          .from('users')
          .select()
          .eq('role', 'doctor')
          .order('rating', ascending: false);
      
      return (response as List).map((data) => _mapDoctorData(data)).toList();
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
      return [];
    }
  }

  Doctor _mapDoctorData(Map<String, dynamic> data) {
    return Doctor(
      id: data['id']?.toString() ?? '',       // User ID is also the Doctor ID now
      userId: data['id']?.toString(),
      name: data['name'] ?? 'Doctor',
      specialty: data['specialty'] ?? 'General Veterinarian',
      rating: (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0,
      reviews: data['reviews_count'] ?? 0,
      nextAvailable: 'Available', // Can be refined later
      clinic: data['clinic'] ?? 'Zovetica Clinic',
      image: data['profile_image'] ?? '',
      available: true, // Default to true if not specified
    );
  }
}
