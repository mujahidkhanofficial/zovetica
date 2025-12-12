import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review_model.dart';
import 'supabase_service.dart';

class ReviewService {
  final _supabase = Supabase.instance.client;

  // Add a review using the RPC function to update doctor stats atomically
  Future<void> addReview({
    required String doctorId,
    required String appointmentId,
    required int rating,
    String? comment,
  }) async {
    try {
      if (SupabaseService.currentUser == null) throw Exception('User not logged in');

      await _supabase.rpc('add_review', params: {
        'p_doctor_id': doctorId,
        'p_appointment_id': appointmentId,
        'p_rating': rating,
        'p_comment': comment,
      });
      
    } catch (e) {
      print('Error adding review: $e');
      rethrow;
    }
  }

  // Get reviews for a specific doctor
  Future<List<Review>> getDoctorReviews(String doctorId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('doctor_id', doctorId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching doctor reviews: $e');
      return [];
    }
  }

  // Check if a completed appointment has already been reviewed
  Future<bool> hasReviewed(String appointmentId) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('reviews')
          .select('id')
          .eq('user_id', userId)
          .eq('appointment_id', appointmentId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Get count of reviews written by a user
  Future<int> getUserReviewCount(String userId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .count(CountOption.exact)
          .eq('user_id', userId);
      
      return response;
    } catch (e) {
      print('Error fetching user review count: $e');
      return 0;
    }
  }
}
