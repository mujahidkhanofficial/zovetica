import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zovetica/services/auth_service.dart';
import 'package:zovetica/services/user_service.dart';
import 'package:zovetica/services/storage_service.dart';
import 'package:zovetica/services/appointment_service.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import '../theme/app_shadows.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String doctorId;

  const DoctorProfileScreen({super.key, required this.doctorId});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();
  final AppointmentService _appointmentService = AppointmentService();

  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  List<Appointment> _appointments = [];
  bool _isEditing = false;
  bool _isLoading = true;
  String _profileImageUrl = '';
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _fetchDoctorInfo();
    _fetchAppointments();
  }

  Future<void> _fetchDoctorInfo() async {
    try {
      final data = await _userService.getUserById(widget.doctorId);
      if (data != null) {
        setState(() {
          _nameController.text = data['name'] ?? '';
          _specializationController.text = data['specialty'] ?? '';
          _contactController.text = data['phone'] ?? '';
          _emailController.text = data['email'] ?? '';
          _addressController.text = data['clinic'] ?? '';
          _profileImageUrl = data['profile_image'] ?? '';
        });
      } else {
        _useMockProfile();
      }
    } catch (e) {
      debugPrint("Error fetching doctor info: $e");
      _useMockProfile();
    }
  }

  void _useMockProfile() {
    setState(() {
      _nameController.text = 'Dr. Sarah Smith';
      _specializationController.text = 'Veterinary Surgeon';
      _contactController.text = '+1 (555) 123-4567';
      _emailController.text = 'sarah.smith@zovetica.com';
      _addressController.text = '123 Pet Lane, Paw City, NY';
      _profileImageUrl = 'https://i.pravatar.cc/300?img=5'; // Mock image
    });
  }

  Future<void> _fetchAppointments() async {
    try {
      final appointments = await _appointmentService.getUserAppointments();
      if (appointments.isEmpty) {
        _useMockAppointments();
      } else {
        setState(() {
          _appointments = appointments;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
      _useMockAppointments();
    }
  }

  void _useMockAppointments() {
    setState(() {
      _appointments = [
        Appointment(
          id: 101,
          doctor: 'Dr. Sarah Smith',
          clinic: 'Paws & Claws Clinic',
          date: 'Today',
          time: '2:30 PM',
          pet: 'Max',
          type: 'Surgery Consultation',
          status: 'confirmed',
        ),
        Appointment(
          id: 102,
          doctor: 'Dr. Sarah Smith',
          clinic: 'Paws & Claws Clinic',
          date: 'Yesterday',
          time: '11:00 AM',
          pet: 'Luna',
          type: 'Vaccination',
          status: 'completed',
        ),
      ];
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    return await _storageService.uploadProfileImage(imageFile);
  }

  Future<void> _saveChanges() async {
    try {
      String? imageUrl;

      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      }

      await _userService.updateUser(
        userId: widget.doctorId,
        name: _nameController.text,
        phone: _contactController.text,
        specialty: _specializationController.text,
        clinic: _addressController.text,
        profileImage: imageUrl,
      );

      setState(() {
        _isEditing = false;
        if (imageUrl != null) {
          _profileImageUrl = imageUrl;
          _imageFile = null;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Header
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: AppGradients.primaryDiagonal,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          GestureDetector(
                            onTap: _isEditing ? _pickImage : null,
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.primaryDiagonal,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.white,
                                    backgroundImage: _imageFile != null
                                        ? FileImage(_imageFile!)
                                        : (_profileImageUrl.isNotEmpty
                                                ? NetworkImage(_profileImageUrl)
                                                : null)
                                            as ImageProvider<Object>?,
                                    child: (_profileImageUrl.isEmpty &&
                                            _imageFile == null)
                                        ? Icon(Icons.person,
                                            size: 50, color: AppColors.slate)
                                        : null,
                                  ),
                                ),
                                if (_isEditing)
                                  Positioned(
                                    bottom: 0,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt,
                                          color: Colors.white, size: 16),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    if (!_isEditing)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                        icon: const Icon(Icons.edit_rounded, color: Colors.white),
                        tooltip: 'Edit Profile',
                      ),
                    if (_isEditing)
                      IconButton(
                        onPressed: _saveChanges,
                        icon: const Icon(Icons.check_rounded, color: Colors.white),
                        tooltip: 'Save',
                      ),
                  ],
                ),

                // Form Fields
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildInputField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person_outline),
                        const SizedBox(height: AppSpacing.md),
                        _buildInputField(
                            controller: _specializationController,
                            label: 'Specialization',
                            icon: Icons.medical_services_outlined),
                        const SizedBox(height: AppSpacing.md),
                        _buildInputField(
                            controller: _contactController,
                            label: 'Phone Number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone),
                        const SizedBox(height: AppSpacing.md),
                        _buildInputField(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: AppSpacing.md),
                        _buildInputField(
                            controller: _addressController,
                            label: 'Clinic Address',
                            icon: Icons.location_on_outlined),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        Text(
                          'My Appointments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Appointments List
                _appointments.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 48,
                                    color: AppColors.slate.withOpacity(0.5)),
                                const SizedBox(height: 8),
                                Text(
                                  "No upcoming appointments",
                                  style: TextStyle(color: AppColors.slate),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _buildAppointmentCard(
                                  _appointments[index]);
                            },
                            childCount: _appointments.length,
                          ),
                        ),
                      ),

                // Logout Button
                 SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: TextButton.icon(
                      onPressed: _logout,
                      icon: Icon(Icons.logout_rounded,
                          color: AppColors.accent, size: 20),
                      label: Text(
                        'Log Out',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.accent.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
              ],
            ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _isEditing ? Colors.white : AppColors.cloud,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: _isEditing
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        keyboardType: keyboardType,
        style: TextStyle(
          color: _isEditing ? AppColors.charcoal : AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.slate),
          prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent, // Handled by container
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: AppShadows.card,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.pets, color: AppColors.secondary),
        ),
        title: Text(
          "${appointment.pet} (${appointment.type})",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            "${appointment.date} • ${appointment.time}",
            style: TextStyle(color: AppColors.slate),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: appointment.status == 'accepted'
                ? AppColors.secondary.withOpacity(0.2)
                : Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            appointment.status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: appointment.status == 'accepted'
                  ? AppColors.secondary
                  : Colors.blue,
            ),
          ),
        ),
      ),
    );
  }
}
