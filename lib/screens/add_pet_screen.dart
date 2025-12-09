import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:zovetica/services/pet_service.dart';
import 'package:zovetica/services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import '../theme/app_shadows.dart';
import '../widgets/enterprise_header.dart';
import '../utils/app_notifications.dart';
import '../utils/image_picker_helper.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final PetService _petService = PetService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  
  // Focus nodes for keyboard navigation
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _breedFocus = FocusNode();
  final FocusNode _ageFocus = FocusNode();
  final FocusNode _weightFocus = FocusNode();
  
  String _selectedType = 'Dog';
  final List<String> _petTypes = ['Dog', 'Cat', 'Bird', 'Hamster', 'Rabbit', 'Other'];
  
  File? _imageFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _nameFocus.dispose();
    _breedFocus.dispose();
    _ageFocus.dispose();
    _weightFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await ImagePickerHelper.pickAndCropImage(
      source: source,
      title: 'Crop Pet Photo',
    );
    if (file != null) {
      setState(() => _imageFile = file);
    }
  }

  void _showPhotoOptions() {
    ImagePickerHelper.showPickerModal(
      context,
      title: 'Pet Photo',
      onCamera: () => _pickImage(ImageSource.camera),
      onGallery: () => _pickImage(ImageSource.gallery),
    );
  }



  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
        // Optional: Require photo or use default? Let's allow no photo but confirm
    }

    setState(() => _isLoading = true);
    try {
      // 1. Upload Image if exists
      String? imageUrl;
      if (_imageFile != null) {
        // Generate a random ID for the pet temporarily or use timestamp
        final petId = DateTime.now().millisecondsSinceEpoch.toString(); 
        imageUrl = await _storageService.uploadPetImage(_imageFile!, petId);
      }

      // 2. Add Pet to DB
      await _petService.addPet(
        name: _nameController.text.trim(),
        type: _selectedType,
        breed: _breedController.text.trim(),
        age: _ageController.text.trim(),
        imageUrl: imageUrl,
        health: 'Good', // Default
        emoji: _getEmojiForType(_selectedType),
      );

      if (!mounted) return;
      AppNotifications.showSuccess(context, 'Pet added successfully!');
      Navigator.pop(context, true); // Return true to trigger refresh
    } catch (e) {
      debugPrint('Error adding pet: $e');
      if (mounted) AppNotifications.showError(context, 'Failed to add pet: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getEmojiForType(String type) {
    switch (type) {
      case 'Dog': return '🐶';
      case 'Cat': return '🐱';
      case 'Bird': return '🐦';
      case 'Hamster': return '🐹';
      case 'Rabbit': return '🐰';
      default: return '🐾';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Pet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Tell us about your furry friend',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.primaryDiagonal,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildPhotoSelector(),
                const SizedBox(height: AppSpacing.xl),
                _buildFormCard(),
                const SizedBox(height: AppSpacing.xl),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSelector() {
    return Center(
      child: GestureDetector(
        onTap: _showPhotoOptions,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight, width: 4),
                boxShadow: AppShadows.card,
                image: _imageFile != null
                    ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                    : null,
              ),
              child: _imageFile == null
                  ? Icon(Icons.pets_rounded, size: 48, color: AppColors.slate.withOpacity(0.3))
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildSectionTitle('Pet Details'),
           const SizedBox(height: AppSpacing.lg),
           
           _buildTextField(
             label: 'Pet Name',
             controller: _nameController,
             icon: Icons.edit_outlined,
             validator: (v) => v!.isEmpty ? 'Please enter a name' : null,
             focusNode: _nameFocus,
             nextFocusNode: _breedFocus,
           ),
           const SizedBox(height: AppSpacing.lg),
           
           _buildDropdown(),
           const SizedBox(height: AppSpacing.lg),

           Row(
             children: [
               Expanded(
                 child: _buildTextField(
                   label: 'Breed',
                   controller: _breedController,
                   icon: Icons.category_outlined,
                   focusNode: _breedFocus,
                   nextFocusNode: _ageFocus,
                 ),
               ),
               const SizedBox(width: AppSpacing.md),
               Expanded(
                 child: _buildTextField(
                   label: 'Age',
                   controller: _ageController,
                   icon: Icons.cake_outlined,
                   focusNode: _ageFocus,
                   nextFocusNode: _weightFocus,
                 ),
               ),
             ],
           ),
           const SizedBox(height: AppSpacing.lg),
           
           _buildTextField(
             label: 'Weight (optional)',
             controller: _weightController,
             icon: Icons.monitor_weight_outlined,
             focusNode: _weightFocus,
             keyboardType: TextInputType.number,
             onSubmit: _submit,
           ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.charcoal,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    VoidCallback? onSubmit,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocusNode != null) {
          nextFocusNode.requestFocus();
        } else if (onSubmit != null) {
          onSubmit();
        }
      },
      style: const TextStyle(
        color: AppColors.charcoal,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.slate, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: AppColors.slate.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.cloud,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      items: _petTypes.map((type) => DropdownMenuItem(
        value: type,
        child: Text(
          type,
          style: const TextStyle(
            color: AppColors.charcoal,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      )).toList(),
      onChanged: (val) => setState(() => _selectedType = val!),
      dropdownColor: Colors.white,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
      style: const TextStyle(color: AppColors.charcoal, fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Pet Type',
        labelStyle: TextStyle(color: AppColors.slate, fontWeight: FontWeight.w500),
        prefixIcon: Icon(Icons.pets, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.cloud,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Add Pet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
