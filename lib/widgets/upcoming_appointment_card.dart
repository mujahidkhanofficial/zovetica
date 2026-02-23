import 'package:flutter/material.dart';
import 'package:pets_and_vets/theme/app_colors.dart';
import 'package:pets_and_vets/theme/app_gradients.dart';
import 'package:pets_and_vets/theme/app_shadows.dart';
import 'package:pets_and_vets/screens/payment_screen.dart';
import 'package:pets_and_vets/utils/pricing.dart';

class UpcomingAppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onRefresh;

  const UpcomingAppointmentCard({
    super.key,
    required this.appointment,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final status = appointment['status']?.toString().toLowerCase() ?? 'pending';
    final paymentConfirmed = appointment['paymentConfirmed'] == true;
    final paymentStatus = appointment['paymentStatus']?.toString().toLowerCase() ?? '';
    final String id = appointment['id'];
    final double price = (appointment['price'] is int) 
        ? (appointment['price'] as int).toDouble() 
        : (appointment['price'] as double? ?? 0.0);

    final paymentAlreadySubmitted =
      paymentConfirmed ||
      paymentStatus == 'pending_admin' ||
      paymentStatus == 'paid_to_platform' ||
      paymentStatus == 'completed';

    // Determine display state
    String title = 'Upcoming Appointment';
    Color statusColor = AppColors.primary;
    String statusText = 'Unknown';
    bool showPayButton = false;

    if (status == 'confirmed') {
      statusText = 'Confirmed';
      statusColor = Colors.green;
    } else if (status == 'accepted') {
      statusText = 'Accepted';
      statusColor = Colors.green;
    } else if (status == 'cancelled') {
        return const SizedBox.shrink(); // Don't show cancelled in upcoming
    } else {
      // Pending statuses
      if (!paymentAlreadySubmitted) {
        statusText = 'Payment Required';
        statusColor = Colors.orange;
        showPayButton = true;
      } else {
        statusText = 'Awaiting Confirmation';
        statusColor = Colors.blue;
        title = 'Request Sent';
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Date Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatDay(appointment['date']),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.charcoal,
                        ),
                      ),
                      Text(
                        _formatMonth(appointment['date']),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment['doctorName'] ?? 'Veterinarian',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                       Row(
                        children: [
                           const Icon(Icons.access_time_rounded, size: 14, color: AppColors.slate),
                           const SizedBox(width: 4),
                           Text(
                             appointment['time'] ?? '',
                             style: const TextStyle(fontSize: 13, color: AppColors.slate),
                           ),
                           const SizedBox(width: 12),
                           const Icon(Icons.pets_rounded, size: 14, color: AppColors.slate),
                           const SizedBox(width: 4),
                           Text(
                             appointment['petName'] ?? '',
                             style: const TextStyle(fontSize: 13, color: AppColors.slate),
                           ),
                        ],
                       ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Action Button
          if (showPayButton)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentScreen(
                          appointmentIds: [id],
                          totalAmount: price > 0 ? price : fixedAppointmentFeePkr.toDouble(),
                          onPaymentConfirmed: () {
                            Navigator.pop(context);
                            onRefresh(); // Refresh home screen
                          },
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Complete Payment'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDay(dynamic dateStr) {
    if (dateStr == null) return '--';
    final date = DateTime.tryParse(dateStr.toString());
    if (date == null) return '--';
    return date.day.toString();
  }

  String _formatMonth(dynamic dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr.toString());
    if (date == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }
}
