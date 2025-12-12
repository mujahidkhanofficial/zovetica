import 'package:flutter/material.dart';
import 'package:zovetica/services/doctor_service.dart';
import 'package:zovetica/services/user_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import 'book_appointment_wizard.dart';

class FindDoctorScreen extends StatefulWidget {
  const FindDoctorScreen({super.key});

  @override
  State<FindDoctorScreen> createState() => _FindDoctorScreenState();
}

class _FindDoctorScreenState extends State<FindDoctorScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DoctorService _doctorService = DoctorService();
  final UserService _userService = UserService();

  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _filteredDoctors = [];

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
      final doctors = await _doctorService.getDoctors();

      List<Map<String, dynamic>> doctorMaps = doctors.map((d) {
        return {
          'id': d.id.toString(),
          'name': d.name,
          'firstName': d.name.split(' ').first,
          'lastName': d.name.split(' ').length > 1 ? d.name.split(' ').last : '',
          'specialty': d.specialty,
          'location': d.clinic,
          'clinic': d.clinic,
          'image': d.image,
          'profile_image': d.image, // Doctor's profile image
          'rating': d.rating,
          'reviews_count': d.reviews,
          'contact': '',
        };
      }).toList();

      _specialties = ['All'] +
          doctorMaps
              .map((d) => d['specialty']?.toString() ?? 'Unknown')
              .toSet()
              .toList();

      _locations = ['All'] +
          doctorMaps
              .map((d) => d['location']?.toString() ?? 'Unknown')
              .toSet()
              .toList();

      setState(() {
        _doctors = doctorMaps;
        _filteredDoctors = doctorMaps;
        _selectedSpecialty = 'All';
        _selectedLocation = 'All';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching doctors: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterDoctors() {
    String search = _searchController.text.toLowerCase();

    setState(() {
      _filteredDoctors = _doctors.where((doctor) {
        bool matchesSearch = doctor['firstName'].toLowerCase().contains(search) ||
            doctor['lastName'].toLowerCase().contains(search);

        bool matchesSpecialty =
            _selectedSpecialty == 'All' || doctor['specialty'] == _selectedSpecialty;

        bool matchesLocation =
            _selectedLocation == 'All' || doctor['location'] == _selectedLocation;

        return matchesSearch && matchesSpecialty && matchesLocation;
      }).toList();
    });
  }

  void _showDoctorDetails(Map<String, dynamic> doctor) async {
    try {
      final data = await _userService.getUserById(doctor['id']);
      if (data == null) return;

      final contact = data['phone'] ?? '';
      
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildDoctorBottomSheet(data, contact),
      );
    } catch (e) {
      debugPrint("Error fetching doctor details: $e");
    }
  }

  Widget _buildDoctorBottomSheet(Map<String, dynamic> data, String contact) {
    final rating = (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0;
    final reviewCount = data['reviews_count'] ?? 0;
    final hasReviews = reviewCount > 0; // Check if doctor has any reviews
    final clinic = data['clinic'] ?? 'Zovetica Clinic';
    final isVerified = data['is_verified'] ?? true; // Assume verified for now
    
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
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.white,
                  backgroundImage: data['profile_image']?.isNotEmpty == true
                      ? NetworkImage(data['profile_image'])
                      : null,
                  child: data['profile_image']?.isEmpty != false
                      ? Text(
                          (data['name'] ?? 'D').substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        )
                      : null,
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
                data['name'] ?? '',
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
              data['specialty'] ?? 'General Veterinarian',
              style: TextStyle(
                color: AppColors.secondaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Stats row: Rating, Reviews, Experience
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
                  icon: hasReviews ? Icons.star_rounded : Icons.auto_awesome_rounded,
                  iconColor: hasReviews ? Colors.amber : AppColors.secondary,
                  value: hasReviews ? rating.toStringAsFixed(1) : 'New',
                  label: hasReviews ? 'Rating' : 'Doctor',
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
                  value: reviewCount.toString(),
                  label: 'Reviews',
                ),
                // Divider
                Container(
                  height: 40,
                  width: 1,
                  color: AppColors.borderLight,
                ),
                // Clinic
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
                  child: Icon(Icons.location_on_rounded, color: AppColors.primary),
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
                        clinic.isNotEmpty ? clinic : 'Location not specified',
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
                   Navigator.push(
                     context, 
                     MaterialPageRoute(builder: (_) => BookAppointmentWizard(doctor: data))
                   );
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
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                  style: const TextStyle(
                    color: AppColors.charcoal, // Visible text
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  dropdownColor: Colors.white,
                  items: _specialties.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s),
                  )).toList(),
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
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                  style: const TextStyle(
                    color: AppColors.charcoal, // Visible text
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  dropdownColor: Colors.white,
                  items: _locations.map((l) => DropdownMenuItem(
                    value: l,
                    child: Text(l),
                  )).toList(),
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
            
            // Clear Filters Button (Optional but helpful)
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
                          hintStyle: TextStyle(color: AppColors.slate.withAlpha(179)),
                          prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
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

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.white,
                    backgroundImage: doctor['image']?.isNotEmpty == true
                        ? NetworkImage(doctor['image'])
                        : null,
                    child: doctor['image']?.isNotEmpty != true
                        ? Text(
                            (doctor['firstName'][0] ?? '') +
                                (doctor['lastName']?.isNotEmpty == true
                                    ? doctor['lastName'][0]
                                    : ''),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${doctor['firstName']} ${doctor['lastName']}",
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
                          Text(
                            doctor['specialty'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.slate,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.slate,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              doctor['clinic'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.slate,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cloud,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
