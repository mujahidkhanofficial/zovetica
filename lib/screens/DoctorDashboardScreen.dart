import 'package:flutter/material.dart';
import 'package:zovetica/services/auth_service.dart';
import 'package:zovetica/services/user_service.dart';
import 'package:zovetica/services/appointment_service.dart';
import 'doctor_profile.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import '../theme/app_shadows.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final AppointmentService _appointmentService = AppointmentService();

  String _firstName = "";
  String _address = "";
  String _profileImageUrl = "";
  List<Appointment> _appointments = [];
  List<AvailabilitySlot> _slots = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctorInfo();
    _fetchAppointments();
    _fetchAvailability();
  }

  Future<void> _fetchDoctorInfo() async {
    try {
      final userData = await _userService.getCurrentUser();
      if (userData != null) {
        setState(() {
          _firstName = userData['name']?.split(' ').first ?? '';
          _address = userData['clinic'] ?? '';
          _profileImageUrl = userData['profile_image'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error fetching doctor info: $e");
    }
  }

  Future<void> _fetchAppointments() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final appointments = await _appointmentService.getUserAppointments();
      setState(() {
        _appointments = appointments;
      });
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
    }
  }

  Future<void> _fetchAvailability() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final slots = await _appointmentService.getAvailabilitySlots(user.id);
      setState(() {
        _slots = slots.map((data) {
          return AvailabilitySlot(
            id: data['id']?.toString() ?? '',
            day: data['day'] ?? '',
            startTime: data['start_time'] ?? '',
            endTime: data['end_time'] ?? '',
          );
        }).toList();
      });
    } catch (e) {
      debugPrint("Error fetching availability: $e");
    }
  }

  Future<void> _updateAppointmentStatus(
      Appointment appointment, String status) async {
    try {
      if (status == 'rejected') {
        await _appointmentService.cancelAppointment(appointment.id.toString());
      } else {
        await _appointmentService.updateAppointmentStatus(
          appointmentId: appointment.id.toString(),
          status: status,
        );
      }
      _fetchAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _goToProfile() {
    final user = _authService.currentUser;
    if (user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorProfileScreen(
          doctorId: user.id,
        ),
      ),
    ).then((_) {
      _fetchDoctorInfo();
    });
  }

  void _showAddSlotDialog() {
    String day = '';
    String startTime = '';
    String endTime = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: const Text("Add Availability", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: "Day (e.g., Monday)",
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => day = val,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              decoration: const InputDecoration(
                labelText: "Start Time (09:00 AM)",
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => startTime = val,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              decoration: const InputDecoration(
                labelText: "End Time (05:00 PM)",
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => endTime = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: AppColors.slate)),
          ),
          ElevatedButton(
            onPressed: () {
              if (day.isNotEmpty && startTime.isNotEmpty && endTime.isNotEmpty) {
                _addAvailability(day, startTime, endTime);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _addAvailability(
      String day, String startTime, String endTime) async {
    final user = _authService.currentUser;
    if (user == null) return;

    await _appointmentService.addAvailabilitySlot(
      doctorId: user.id,
      day: day,
      startTime: startTime,
      endTime: endTime,
    );

    _fetchAvailability();
  }

  Future<void> _removeAvailability(String slotId) async {
    await _appointmentService.removeAvailabilitySlot(slotId);
    _fetchAvailability();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSlotDialog,
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            automaticallyImplyLeading: false, // Dashboard shouldn't have back button unless in nav stack context
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppGradients.primaryDiagonal,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end, // Align to bottom
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text(
                                'Doctor Dashboard',
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _firstName.isNotEmpty ? 'Welcome, Dr. $_firstName' : "Welcome, Doctor",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white.withOpacity(0.9)),
                              ),
                              if (_address.isNotEmpty)
                                Text(
                                  _address,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.white.withOpacity(0.8)),
                                ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _goToProfile,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage: _profileImageUrl.isNotEmpty
                                  ? NetworkImage(_profileImageUrl)
                                  : null,
                              backgroundColor: Colors.white,
                              child: _profileImageUrl.isEmpty
                                  ? Icon(Icons.person, size: 28, color: AppColors.primary)
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appointment Requests',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_appointments.where((a) => a.status == 'pending').isEmpty)
                    _buildEmptyState('No pending requests'),
                  ..._appointments
                      .where((a) => a.status == 'pending')
                      .map((a) => _buildAppointmentCard(a)),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Availability Schedule',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_slots.isEmpty) _buildEmptyState('No availability slots added'),
                  ..._slots.map((slot) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          boxShadow: AppShadows.card,
                        ),
                        child: ListTile(
                          leading: Icon(Icons.access_time_rounded, color: AppColors.primary),
                          title: Text(
                              "${slot.day}: ${slot.startTime} - ${slot.endTime}",
                              style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w600)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            onPressed: () => _removeAvailability(slot.id),
                          ),
                        ),
                      )),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderLight, style: BorderStyle.solid),
      ),
      child: Center(child: Text(message, style: TextStyle(color: AppColors.slate))),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                 Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        Text(
                          appointment.type,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                        ),
                        Text(
                          '${appointment.pet} • ${appointment.clinic}',
                          style: TextStyle(fontSize: 14, color: AppColors.slate),
                        ),
                     ]
                   )
                 )
            ],),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cloud,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${appointment.date} • ${appointment.time}',
                style: TextStyle(fontSize: 14, color: AppColors.charcoal, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _updateAppointmentStatus(appointment, 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _updateAppointmentStatus(appointment, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Availability model
class AvailabilitySlot {
  final String id;
  final String day;
  final String startTime;
  final String endTime;

  AvailabilitySlot({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
  });
}
