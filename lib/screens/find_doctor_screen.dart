import 'package:flutter/material.dart';
import 'package:pets_and_vets/services/doctor_service.dart';
import 'package:pets_and_vets/services/user_service.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import '../theme/app_shadows.dart';
import 'book_appointment_wizard.dart';
import '../data/repositories/doctor_repository.dart';
import '../widgets/widgets.dart';

class FindDoctorScreen extends StatefulWidget {
  const FindDoctorScreen({super.key});

  @override
  State<FindDoctorScreen> createState() => _FindDoctorScreenState();
}

class _FindDoctorScreenState extends State<FindDoctorScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  final DoctorRepository _doctorRepo = DoctorRepository.instance;

  List<Doctor> _doctors = [];
  List<Doctor> _filteredDoctors = [];

  String? _selectedSpecialty;
  String? _selectedLocation;

  List<String> _specialties = [];
  List<String> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      // Helper to process and display doctors
      void updateDoctorsList(List<Doctor> doctorsList) {
        _specialties = ['All'] +
            doctorsList
                .map((d) => d.specialty)
                .where((s) => s.isNotEmpty)
                .toSet()
                .toList();

        _locations = ['All'] +
            doctorsList
                .map((d) => d.clinic)
                .where((l) => l.isNotEmpty)
                .toSet()
                .toList();

        if (mounted) {
          setState(() {
            _doctors = doctorsList;
            _filteredDoctors = doctorsList;
            if (_selectedSpecialty == null) {
              _selectedSpecialty = 'All';
              _selectedLocation = 'All';
            }
            _isLoading = false;
          });

          // Re-apply filters if they exist
          if (_searchController.text.isNotEmpty ||
              _selectedSpecialty != 'All' ||
              _selectedLocation != 'All') {
            _filterDoctors();
          }
        }
      }

      // 1. Load from local cache immediately
      final localDoctors = await _doctorRepo.getDoctors();
      if (localDoctors.isNotEmpty) {
        final doctors = localDoctors.map(_doctorRepo.localDoctorToDoctor).toList();
        updateDoctorsList(doctors);
      } else {
        if (mounted) setState(() => _isLoading = true);
      }

      // 2. Sync from server
      await _doctorRepo.syncDoctors();

      // 3. Update from cache again (guaranteed fresh)
      final updatedLocal = await _doctorRepo.getDoctors();
      final doctors = updatedLocal.map(_doctorRepo.localDoctorToDoctor).toList();
      updateDoctorsList(doctors);
    } catch (e) {
      debugPrint("Error fetching doctors: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterDoctors() {
    String search = _searchController.text.toLowerCase();

    setState(() {
      _filteredDoctors = _doctors.where((doctor) {
        bool matchesSearch = doctor.name.toLowerCase().contains(search);

        bool matchesSpecialty = _selectedSpecialty == 'All' ||
            doctor.specialty == _selectedSpecialty;

        bool matchesLocation =
            _selectedLocation == 'All' || doctor.clinic == _selectedLocation;

        return matchesSearch && matchesSpecialty && matchesLocation;
      }).toList();
    });
  }

  void _showDoctorDetails(Doctor doctor) async {
    try {
      // Fetch full user details if possible for contact info
      // Use userId if available, otherwise fallback to basic doctor info
      Map<String, dynamic>? userData;
      if (doctor.userId != null) {
        userData = await _userService.getUserById(doctor.userId!);
      }

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildDoctorBottomSheet(doctor, userData),
      );
    } catch (e) {
      debugPrint("Error fetching doctor details: $e");
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildDoctorBottomSheet(doctor, null),
      );
    }
  }

  Widget _buildDoctorBottomSheet(Doctor doctor, Map<String, dynamic>? userData) {
    
    // Merge doctor data with potential user data enhancements
    final isVerified = true; // Assume listed doctors are verified
    final contact = userData?['phone'] ?? ''; // Info from UserService
    
    // We strictly use the Doctor model for display as it is the source of truth for the listing
    // But we might enrich it with userData for things like specific verified status if available

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Doctor avatar with verification badge
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryCta,
                  shape: BoxShape.circle,
                ),
                child: CachedAvatar(
                  imageUrl: doctor.image,
                  name: doctor.name,
                  radius: 50,
                  backgroundColor: AppColors.white,
                ),
              ),
              // Verified badge
              if (isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Name with verified text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                doctor.name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // Specialty badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(38),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              doctor.specialty,
              style: TextStyle(
                color: AppColors.secondaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.cloud,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Rating
                _buildStatItem(
                  icon: doctor.reviews > 0
                      ? Icons.star_rounded
                      : Icons.auto_awesome_rounded,
                  iconColor: doctor.reviews > 0
                      ? Colors.amber
                      : AppColors.secondary,
                  value: doctor.reviews > 0
                      ? doctor.rating.toStringAsFixed(1)
                      : 'New',
                  label: doctor.reviews > 0 ? 'Rating' : 'Doctor',
                ),
                // Divider
                Container(
                  height: 40,
                  width: 1,
                  color: AppColors.borderLight,
                ),
                // Reviews
                _buildStatItem(
                  icon: Icons.reviews_rounded,
                  iconColor: AppColors.primary,
                  value: doctor.reviews.toString(),
                  label: 'Reviews',
                ),
                // Divider
                Container(
                  height: 40,
                  width: 1,
                  color: AppColors.borderLight,
                ),
                // Status
                _buildStatItem(
                  icon: Icons.verified_user_rounded,
                  iconColor: AppColors.secondary,
                  value: 'Verified',
                  label: 'Status',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Clinic location
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.cloud,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(Icons.location_on_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clinic Location',
                        style: TextStyle(
                          color: AppColors.slate,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        doctor.clinic.isNotEmpty
                            ? doctor.clinic
                            : 'Location not specified',
                        style: TextStyle(
                          color: AppColors.charcoal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Book button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppGradients.coralButton,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withAlpha(89),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  // Need to pass a map to BookAppointmentWizard as it expects Map
                  // Or we update Wizard too? Let's keep Wizard as implies for now and adapt
                  // Construct map from doctor object + user data if needed
                  final doctorMap = {
                     'id': doctor.id,
                     'user_id': doctor.userId,
                     'name': doctor.name,
                     'specialty': doctor.specialty,
                     'clinic': doctor.clinic,
                     'image': doctor.image,
                     'profile_image': doctor.image,
                     'rating': doctor.rating,
                     'reviews_count': doctor.reviews,
                     'contact': contact,
                  };

                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              BookAppointmentWizard(doctor: doctorMap)));
                },
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: const Center(
                  child: Text(
                    'Book Appointment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.slate,
          ),
        ),
      ],
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Filter Doctors',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 24),

            // Specialty
            Text(
              'Specialty',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.slate,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedSpecialty,
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary),
                  style: const TextStyle(
                    color: AppColors.charcoal, // Visible text
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  dropdownColor: Colors.white,
                  items: _specialties
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSpecialty = val;
                      _filterDoctors();
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Location
            Text(
              'Location',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.slate,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedLocation,
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary),
                  style: const TextStyle(
                    color: AppColors.charcoal, // Visible text
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  dropdownColor: Colors.white,
                  items: _locations
                      .map((l) => DropdownMenuItem(
                            value: l,
                            child: Text(l),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedLocation = val;
                      _filterDoctors();
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Clear Filters Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedSpecialty = 'All';
                    _selectedLocation = 'All';
                    _filterDoctors();
                  });
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Reset Filters',
                  style: TextStyle(
                    color: AppColors.slate,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              'Find a Doctor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${_filteredDoctors.length} doctors available',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withAlpha(230),
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
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(20),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => _filterDoctors(),
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(
                          color: AppColors.charcoal,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search specialists...',
                          hintStyle:
                              TextStyle(color: AppColors.slate.withAlpha(179)),
                          prefixIcon:
                              Icon(Icons.search_rounded, color: AppColors.primary),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      gradient: AppGradients.coralButton,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withAlpha(102),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Doctor List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDoctors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(13),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_search_rounded,
                                size: 60,
                                color: AppColors.primary.withAlpha(128),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No doctors found',
                              style: TextStyle(
                                fontSize: 20,
                                color: AppColors.charcoal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filters',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.slate,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: _filteredDoctors.length,
                        itemBuilder: (context, index) {
                          final doctor = _filteredDoctors[index];
                          return _buildDoctorCard(doctor);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDoctorDetails(doctor),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                // Avatar with gradient border
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryCta,
                    shape: BoxShape.circle,
                  ),
                  child: CachedAvatar(
                    imageUrl: doctor.image,
                    name: doctor.name,
                    radius: 32,
                    backgroundColor: AppColors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.medical_services_outlined,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              doctor.specialty,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.slate,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: AppColors.golden,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            doctor.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.charcoal,
                            ),
                          ),
                          Text(
                            ' (${doctor.reviews} reviews)',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.slate,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status badge
                _buildStatusBadge(doctor.available),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool available) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: available
            ? AppColors.secondary.withAlpha(38)
            : AppColors.slate.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: available ? AppColors.secondary : AppColors.slate,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            available ? 'Available' : 'Busy',
            style: TextStyle(
              color: available ? AppColors.secondaryDark : AppColors.slate,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
