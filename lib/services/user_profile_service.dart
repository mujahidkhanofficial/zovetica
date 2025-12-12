import 'package:zovetica/services/supabase_service.dart';

class UserProfileService {
  final _client = SupabaseService.client;

  Future<String?> getUserRole(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();
      
      return response['role'] as String?;
    } catch (e) {
      return null;
    }
  }
}
