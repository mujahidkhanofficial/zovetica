import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class WalletService {
  final _client = SupabaseService.client;

  /// Get the current wallet balance for a doctor
  Future<double> getWalletBalance(String doctorId) async {
    try {
      final response = await _client
          .from('users')
          .select('wallet_balance')
          .eq('id', doctorId)
          .maybeSingle();
      
      if (response != null && response['wallet_balance'] != null) {
        return (response['wallet_balance'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      debugPrint('Error fetching wallet balance: $e');
      return 0.0;
    }
  }

  /// Request a payout to Easypaisa
  Future<void> requestPayout(String doctorId, double amount) async {
    try {
      // 1. Check balance
      final currentBalance = await getWalletBalance(doctorId);
      if (currentBalance < amount) {
        throw Exception('Insufficient wallet balance');
      }

      // 2. Create payout request
      final payoutResponse = await _client.from('payouts').insert({
        'doctor_id': doctorId,
        'amount': amount,
        'status': 'pending',
      }).select('id').single();

      final payoutId = payoutResponse['id'];

      // 3. Deduct from wallet balance
      await _client.from('users').update({
        'wallet_balance': currentBalance - amount
      }).eq('id', doctorId);

      // 4. Log transaction
      await _client.from('wallet_transactions').insert({
        'doctor_id': doctorId,
        'payout_id': payoutId,
        'type': 'debit',
        'amount': amount,
        'description': 'Payout request to Easypaisa',
      });

    } catch (e) {
      debugPrint('Error requesting payout: $e');
      rethrow;
    }
  }

  /// Get payout history
  Future<List<Map<String, dynamic>>> getPayoutHistory(String doctorId) async {
    try {
      final response = await _client
          .from('payouts')
          .select()
          .eq('doctor_id', doctorId)
          .order('requested_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching payout history: $e');
      return [];
    }
  }

  /// Get wallet transaction history for a doctor or user
  /// If both doctorId and userId are provided, filters by either.
  Future<List<Map<String, dynamic>>> getTransactionHistory({String? doctorId, String? userId}) async {
    try {
      // build filter before ordering
      var query = _client.from('wallet_transactions').select();
      if (doctorId != null && userId != null) {
        query = query.or('doctor_id.eq.$doctorId,user_id.eq.$userId');
      } else if (doctorId != null) {
        query = query.eq('doctor_id', doctorId);
      } else if (userId != null) {
        query = query.eq('user_id', userId);
      }
      // apply ordering when performing the request to avoid type mismatch
      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching transaction history: $e');
      return [];
    }
  }

  /// Update Easypaisa account number
  Future<void> updateEasypaisaAccount(String doctorId, String accountNumber) async {
    try {
      await _client.from('users').update({
        'easypaisa_account_number': accountNumber
      }).eq('id', doctorId);
    } catch (e) {
      debugPrint('Error updating Easypaisa account: $e');
      rethrow;
    }
  }
}
