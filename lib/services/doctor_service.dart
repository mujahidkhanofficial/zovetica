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
      // Fetch from 'doctors' table and join 'users' to get profile info
      final response = await _client
          .from('doctors')
          .select('*, users!inner(*)') // Inner join to ensure user exists
          .order('id');

      return (response as List).map((data) => _mapJoinedDataToDoctor(data)).toList();
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
      return [];
    }
  }

  Doctor _mapJoinedDataToDoctor(Map<String, dynamic> data) {
    final userData = data['users'] as Map<String, dynamic>? ?? {};
    
    return Doctor(
      id: data['id']?.toString() ?? '', // This is the Doctor Table ID
      name: userData['name'] ?? 'Unknown Doctor',
      specialty: userData['specialty'] ?? data['specialty_override'] ?? 'General Veterinarian',
      rating: (userData['rating'] is num) ? (userData['rating'] as num).toDouble() : 0.0,
      reviews: userData['reviews_count'] ?? 0,
      nextAvailable: 'Available',
      clinic: userData['clinic'] ?? 'Zovetica Clinic',
      image: userData['profile_image'] ?? '',
      available: true,
      userId: data['user_id']?.toString(),
    );
  }
}
