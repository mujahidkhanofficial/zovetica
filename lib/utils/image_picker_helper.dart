import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/crop_photo_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from the specified source and crop it to a square
  static Future<File?> pickAndCropImage(
    BuildContext context, {
    required ImageSource source,
    String title = 'Crop Photo',
  }) async {
    try {
      // 1. Pick Image
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile == null) return null;

      // 2. Crop Image (Custom Screen)
      if (context.mounted) {
        final croppedFile = await Navigator.push<File>(
          context,
          MaterialPageRoute(
            builder: (context) => CropPhotoScreen(
              imageFile: File(pickedFile.path),
            ),
          ),
        );
        return croppedFile;
      }
    } catch (e) {
      debugPrint('ImagePickerHelper Error: $e');
    }
    return null;
  }

  /// Show a standardized modal bottom sheet for photo selection
  static void showPickerModal(
    BuildContext context, {
    required VoidCallback onCamera,
    required VoidCallback onGallery,
    VoidCallback? onRemove,
    String title = 'Upload Photo',
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allows full control over height
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias, // Ensure header also clips
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Custom Gradient App Bar Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: AppGradients.primaryDiagonal,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            SafeArea(
              top: false, // Header handles top
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildOption(
                      context, 
                      Icons.camera_alt_rounded, 
                      'Take Photo', 
                      'Use your camera',
                      onCamera
                    ),
                    const SizedBox(height: 16),
                    _buildOption(
                      context, 
                      Icons.photo_library_rounded, 
                      'Choose from Gallery', 
                      'Select from your photos',
                      onGallery
                    ),
                    if (onRemove != null) ...[
                      const SizedBox(height: 16),
                      _buildOption(
                        context, 
                        Icons.delete_outline_rounded, 
                        'Remove Photo', 
                        'Delete current photo',
                        onRemove,
                        isDestructive: true
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildOption(
    BuildContext context, 
    IconData icon, 
    String label, 
    String sublabel,
    VoidCallback onTap, 
    {bool isDestructive = false}
  ) {
    final color = isDestructive ? AppColors.error : AppColors.primary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Close modal first
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDestructive ? AppColors.error.withAlpha(51) : AppColors.borderLight,
            ),
            borderRadius: BorderRadius.circular(16),
            color: isDestructive ? AppColors.error.withAlpha(13) : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDestructive ? Colors.white : color.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDestructive ? AppColors.error : AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sublabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDestructive ? AppColors.error.withAlpha(179) : AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDestructive ? AppColors.error.withAlpha(128) : AppColors.slate.withAlpha(128),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
