import 'package:flutter/material.dart';
import '../services/review_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/app_notifications.dart';
import '../widgets/pet_button.dart';

class ReviewModal extends StatefulWidget {
  final Map<String, dynamic> doctor; // Passing raw map or Doctor model
  final String appointmentId;
  final VoidCallback onReviewSubmitted;

  const ReviewModal({
    super.key,
    required this.doctor,
    required this.appointmentId,
    required this.onReviewSubmitted,
  });

  @override
  State<ReviewModal> createState() => _ReviewModalState();
}

class _ReviewModalState extends State<ReviewModal> {
  final _reviewService = ReviewService();
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  void _submitReview() async {
    if (_rating == 0) {
      AppNotifications.showWarning(context, 'Please select a rating');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final doctorId = widget.doctor['id'] ?? '';
      
      await _reviewService.addReview(
        doctorId: doctorId,
        appointmentId: widget.appointmentId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onReviewSubmitted();
        AppNotifications.showSuccess(context, 'Review submitted! Thank you.');
      }
    } catch (e) {
      if (mounted) {
        AppNotifications.showError(context, 'Error submitting review: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorName = "${widget.doctor['firstName'] ?? ''} ${widget.doctor['lastName'] ?? ''}".trim();
    final displayName = widget.doctor['name'] ?? doctorName;
    final doctorImage = widget.doctor['profile_image'];

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // Doctor Info
          Row(
            children: [
               Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cloud,
                  image: doctorImage != null && doctorImage.isNotEmpty
                      ? DecorationImage(image: NetworkImage(doctorImage), fit: BoxFit.cover)
                      : null,
                ),
                child: doctorImage == null || doctorImage.isEmpty
                    ? Center(
                        child: Text(
                          displayName.isNotEmpty ? displayName[0] : 'D',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate your visit with',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.slate,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dr. $displayName',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Star Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _rating = index + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: index < _rating ? AppColors.golden : AppColors.borderLight,
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 24),
          
          // Comment Input
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Share your experience (optional)',
              hintStyle: TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.cloud,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Submit Button - Using PetButton
          PetButton(
            text: 'Submit Review',
            onPressed: _isSubmitting ? null : _submitReview,
            isLoading: _isSubmitting,
            width: double.infinity,
            height: 52,
          ),
        ],
      ),
    );
  }
}
