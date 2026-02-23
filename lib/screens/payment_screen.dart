import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pets_and_vets/services/storage_service.dart';
import 'package:pets_and_vets/services/appointment_service.dart';
import 'package:pets_and_vets/theme/app_colors.dart';
import 'package:pets_and_vets/theme/app_gradients.dart';
import 'package:pets_and_vets/theme/app_shadows.dart';
import 'package:pets_and_vets/utils/app_notifications.dart';
import 'package:pets_and_vets/utils/pricing.dart';

class PaymentScreen extends StatefulWidget {
  final List<String> appointmentIds;
  final double totalAmount;
  final VoidCallback onPaymentConfirmed;

  const PaymentScreen({
    super.key,
    required this.appointmentIds,
    required this.totalAmount,
    required this.onPaymentConfirmed,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final StorageService _storageService = StorageService();
  File? _screenshot;
  bool _isUploading = false;
  final String _easypaisaNumber = '03448962643';
  final String _accountName = 'Taimoor';

  Future<void> _pickScreenshot() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _screenshot = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) AppNotifications.showError(context, 'Failed to pick image');
    }
  }

  Future<void> _submitPayment() async {
    if (_screenshot == null) {
      AppNotifications.showWarning(context, 'Please attach a payment screenshot');
      return;
    }

    setState(() => _isUploading = true);
    try {
      // 1. Upload screenshot
      final url = await _storageService.uploadPaymentScreenshot(_screenshot!);

      if (url == null && mounted) {
        AppNotifications.showWarning(
          context,
          'Screenshot upload is restricted by server policy. Payment confirmation will be submitted without image proof.',
        );
      }

      // 2. Update all appointments with screenshot
      // Since booking wizard creates multiple appointments for multiple pets
      for (final appId in widget.appointmentIds) {
        await _appointmentService.confirmPaymentByUser(appId, screenshotUrl: url);
      }

      if (mounted) {
        // Success
        widget.onPaymentConfirmed();
      }
    } catch (e) {
      if (mounted) AppNotifications.showError(context, 'Payment submission failed: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalAmount = widget.totalAmount.round();
    final int commission = calculatePlatformCommission(totalAmount);
    final int vetReceives = calculateVetEarnings(totalAmount);

    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        title: const Text('Complete Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppGradients.primaryDiagonal)),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Amount Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  const Text('Total Amount', style: TextStyle(fontSize: 14, color: AppColors.slate)),
                  const SizedBox(height: 8),
                  Text(
                    'PKR $totalAmount',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cloud,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        _buildAmountSplitRow('Appointment Fee', totalAmount),
                        const SizedBox(height: 6),
                        _buildAmountSplitRow('Platform Commission (15%)', commission),
                        const SizedBox(height: 6),
                        _buildAmountSplitRow('Vet Receives (85%)', vetReceives, highlight: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment Details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.payment_rounded, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cloud,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        // Easypaisa Logo Placeholder or Icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_wallet, color: Colors.green),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Easypaisa', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(_accountName, style: const TextStyle(fontSize: 12, color: AppColors.slate)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Number and Copy
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Account Number', style: TextStyle(fontSize: 11, color: AppColors.slate)),
                            Text(_easypaisaNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _easypaisaNumber));
                            AppNotifications.showSuccess(context, 'Number copied to clipboard');
                          },
                          icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                          tooltip: 'Copy Number',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Step 1: Send payment to the above Easypaisa account.\nStep 2: Take a screenshot of the transaction receipt.\nStep 3: Upload the screenshot below.',
                    style: TextStyle(fontSize: 13, color: AppColors.slate, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Screenshot Upload
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Attach Screenshot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickScreenshot,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _screenshot == null ? AppColors.cloud : null,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border(context), style: BorderStyle.solid),
                        image: _screenshot != null
                            ? DecorationImage(image: FileImage(_screenshot!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _screenshot == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_rounded, size: 40, color: AppColors.slate.withOpacity(0.5)),
                                const SizedBox(height: 8),
                                Text('Tap to upload', style: TextStyle(color: AppColors.slate.withOpacity(0.5))),
                              ],
                            )
                          : null,
                    ),
                  ),
                  if (_screenshot != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: _pickScreenshot,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Change Screenshot'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: _screenshot != null && !_isUploading
                    ? AppGradients.primaryButtonDecoration()
                    : BoxDecoration(color: AppColors.slate.withOpacity(0.3), borderRadius: BorderRadius.circular(30)),
                child: ElevatedButton(
                  onPressed: (_screenshot != null && !_isUploading) ? _submitPayment : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isUploading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
             const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSplitRow(String label, int value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: highlight ? AppColors.secondary : AppColors.slate,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          'PKR $value',
          style: TextStyle(
            fontSize: 12,
            color: highlight ? AppColors.secondary : AppColors.charcoal,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
