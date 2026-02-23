import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final AppointmentService _appointmentService = AppointmentService();

  List<Appointment> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final appointments = await _appointmentService.getUserAppointments();

      final paymentRows = appointments.where((a) {
        final paymentStatus = (a.paymentStatus ?? '').toLowerCase();
        return a.paymentConfirmedByUser == true ||
            ['pending_admin', 'paid_to_platform', 'completed', 'refunded'].contains(paymentStatus);
      }).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

      if (mounted) {
        setState(() {
          _transactions = paymentRows;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _transactions.fold<double>(
      0,
      (sum, tx) => sum + tx.price.toDouble(),
    );

    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        title: const Text('Payment History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppGradients.primaryDiagonal),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                    children: [
                      _buildSummaryCard(totalAmount),
                      const SizedBox(height: 14),
                      ..._transactions.map(_buildTransactionCard),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Sent to Vets', style: TextStyle(fontSize: 12, color: AppColors.slate)),
                const SizedBox(height: 2),
                Text(
                  'PKR ${totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_transactions.length} tx',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.slate,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Appointment tx) {
    final paymentStatus = (tx.paymentStatus ?? '').toLowerCase();
    final status = _statusLabel(paymentStatus);
    final statusColor = _statusColor(paymentStatus);

    final appointmentDateTime = DateFormat.yMMMd().format(tx.dateTime);
    final appointmentTime = tx.time;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tx.doctor.isNotEmpty ? tx.doctor : 'Veterinarian',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.slate),
              const SizedBox(width: 6),
              Text(
                '$appointmentDateTime • $appointmentTime',
                style: const TextStyle(fontSize: 12, color: AppColors.slate),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.pets_rounded, size: 14, color: AppColors.slate),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tx.pet.isNotEmpty ? tx.pet : 'Pet',
                  style: const TextStyle(fontSize: 12, color: AppColors.slate),
                ),
              ),
              Text(
                'PKR ${tx.price}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded, size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            const Text(
              'No Payment Transactions Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Once you submit payment for appointments, your history will appear here with status and date/time.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.slate, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String paymentStatus) {
    switch (paymentStatus) {
      case 'pending_admin':
        return 'Awaiting Verification';
      case 'paid_to_platform':
        return 'Submitted';
      case 'completed':
        return 'Completed';
      case 'refunded':
        return 'Refunded';
      default:
        return 'Pending';
    }
  }

  Color _statusColor(String paymentStatus) {
    switch (paymentStatus) {
      case 'pending_admin':
        return Colors.orange;
      case 'paid_to_platform':
        return AppColors.primary;
      case 'completed':
        return AppColors.secondary;
      case 'refunded':
        return AppColors.error;
      default:
        return AppColors.slate;
    }
  }
}
