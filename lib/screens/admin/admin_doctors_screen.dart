import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../services/admin_service.dart';

/// Admin Doctor Verification Screen
/// Allows viewing, approving, and rejecting doctor applications.
class AdminDoctorsScreen extends StatefulWidget {
  const AdminDoctorsScreen({super.key});

  @override
  State<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends State<AdminDoctorsScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;

  List<Map<String, dynamic>> _pendingDoctors = [];
  List<Map<String, dynamic>> _verifiedDoctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDoctors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);

    final pending = await _adminService.getAllDoctors(pendingOnly: true);
    final verified = await _adminService.getAllDoctors(verifiedOnly: true);

    setState(() {
      _pendingDoctors = pending;
      _verifiedDoctors = verified;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Verification'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pending'),
                  if (_pendingDoctors.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_pendingDoctors.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Verified'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDoctorList(_pendingDoctors, isPending: true),
                _buildDoctorList(_verifiedDoctors, isPending: false),
              ],
            ),
    );
  }

  Widget _buildDoctorList(List<Map<String, dynamic>> doctors, {required bool isPending}) {
    if (doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.hourglass_empty : Icons.verified,
              size: 64,
              color: AppColors.slate,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isPending ? 'No pending verifications' : 'No verified doctors',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDoctors,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: doctors.length,
        itemBuilder: (context, index) => _buildDoctorCard(doctors[index], isPending),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor, bool isPending) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userData = doctor['users'] as Map<String, dynamic>?;
    final name = userData?['name'] ?? 'Unknown Doctor';
    final email = userData?['email'] ?? '';
    final profileImage = userData?['profile_image'] ?? '';
    final specialty = doctor['specialty'] ?? 'General';
    final clinic = doctor['clinic'] ?? 'Not specified';
    final rating = doctor['rating']?.toString() ?? '0.0';
    final reviewsCount = doctor['reviews_count']?.toString() ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isPending
              ? AppColors.warning.withOpacity(0.5)
              : AppColors.success.withOpacity(0.5),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.secondary.withOpacity(0.1),
                  backgroundImage: profileImage.isNotEmpty
                      ? NetworkImage(profileImage)
                      : null,
                  child: profileImage.isEmpty
                      ? const Icon(Icons.person, color: AppColors.secondary)
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPending
                        ? AppColors.warning.withOpacity(0.2)
                        : AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPending ? Icons.pending : Icons.verified,
                        size: 16,
                        color: isPending ? AppColors.warning : AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPending ? 'Pending' : 'Verified',
                        style: TextStyle(
                          color: isPending ? AppColors.warning : AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // Details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(Icons.medical_services, 'Specialty', specialty),
                ),
                Expanded(
                  child: _buildDetailItem(Icons.location_on, 'Clinic', clinic),
                ),
              ],
            ),

            if (!isPending) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(Icons.star, 'Rating', rating),
                  ),
                  Expanded(
                    child: _buildDetailItem(Icons.rate_review, 'Reviews', reviewsCount),
                  ),
                ],
              ),
            ],

            // Actions for pending doctors
            if (isPending) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      onPressed: () => _showRejectDialog(doctor['id']),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                      onPressed: () => _approveDoctor(doctor['id']),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.slate),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.slate,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _approveDoctor(String doctorId) async {
    final success = await _adminService.verifyDoctor(doctorId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor approved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadDoctors();
    }
  }

  Future<void> _showRejectDialog(String doctorId) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Doctor Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'e.g., Invalid credentials...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.isNotEmpty) {
      final success = await _adminService.rejectDoctor(
        doctorId,
        reasonController.text,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doctor application rejected'),
          ),
        );
        _loadDoctors();
      }
    }

    reasonController.dispose();
  }
}
