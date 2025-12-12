import 'package:flutter/material.dart';
import 'package:zovetica/services/auth_service.dart';
import 'package:zovetica/services/user_service.dart';
import 'package:zovetica/services/appointment_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Required for RealtimeChannel & Postgres types
import 'package:zovetica/services/supabase_service.dart';
import 'vet_appointment_detail_screen.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import 'appointment_screen.dart';
import '../theme/app_spacing.dart';
import '../theme/app_shadows.dart'; 
import '../widgets/enterprise_header.dart'; 
import '../utils/app_notifications.dart'; // Required for AppNotifications

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
  String _profileImageUrl = "";
  List<Appointment> _appointments = [];
  List<AvailabilitySlot> _slots = [];

  String? _doctorId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDoctorProfile();
  }

  Future<void> _initializeDoctorProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      // 1. Check if user is already a doctor
      final response = await SupabaseService.client
          .from('doctors')
          .select('id, user_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        _doctorId = response['id'];
      } else {
        // 2. If not, auto-register as doctor for this session/demo
        final newDoctor = await SupabaseService.client
            .from('doctors')
            .insert({
              'user_id': user.id,
              'specialty': 'General Practitioner',
              'clinic': 'Zovetica Virtual Clinic',
              'available': true,
              'verified': true,
            })
            .select()
            .single();
        _doctorId = newDoctor['id'];
        
        // Update user role to doctor
        await SupabaseService.client
          .from('users')
          .update({'role': 'doctor'})
          .eq('id', user.id);
      }

      await Future.wait([
        _fetchDoctorInfo(),
        _fetchAppointments(),
        _fetchAvailability(),
      ]);
      
      _setupRealtimeSubscription();

    } catch (e) {
      debugPrint('Error initializing doctor profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDoctorInfo() async {
    try {
      final userData = await _userService.getCurrentUser();
      if (userData != null) {
        if (mounted) {
          setState(() {
            _firstName = userData['name']?.split(' ').first ?? '';
            _profileImageUrl = userData['profile_image'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching doctor info: $e");
    }
  }

  Future<void> _fetchAppointments() async {
    if (_doctorId == null) return;

    try {
      final appointments = await _appointmentService.getDoctorAppointments(_doctorId!);
      if (mounted) {
        setState(() {
          _appointments = appointments;
        });
      }
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
    }
  }

  Future<void> _fetchAvailability() async {
    if (_doctorId == null) return;

    try {
      final slots = await _appointmentService.getAvailabilitySlots(_doctorId!);
      
      // Sort logic
      final dayOrder = {
        'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4,
        'Friday': 5, 'Saturday': 6, 'Sunday': 7
      };

      final parsedSlots = slots.map((data) {
        return AvailabilitySlot(
          id: data['id']?.toString() ?? '',
          day: data['day'] ?? '',
          startTime: data['start_time'] ?? '',
          endTime: data['end_time'] ?? '',
        );
      }).toList();

      // Sort by Day then Start Time
      parsedSlots.sort((a, b) {
        int dayA = dayOrder[a.day] ?? 8;
        int dayB = dayOrder[b.day] ?? 8;
        if (dayA != dayB) return dayA.compareTo(dayB);
        return a.startTime.compareTo(b.startTime);
      });

      if (mounted) {
        setState(() {
          _slots = parsedSlots;
        });
      }
    } catch (e) {
      debugPrint("Error fetching availability: $e");
    }
  }

  Future<void> _updateAppointmentStatus(Appointment appointment, String status) async {
    try {
      final appointmentId = appointment.uuid ?? appointment.id.toString();
      
      if (status == 'rejected') {
        await _appointmentService.cancelAppointment(appointmentId);
      } else {
        await _appointmentService.updateAppointmentStatus(
          appointmentId: appointmentId,
          status: status,
        );
      }
      _fetchAppointments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'accepted' ? 'Appointment accepted' : 'Appointment declined'),
            backgroundColor: status == 'accepted' ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }



  void _showAddSlotDialog() {
    List<String> selectedDays = [];
    String startTime = '9:00 AM'; // Fixed: Removed leading zero to match generated slots
    String endTime = '5:00 PM';   // Fixed: Removed leading zero
    
    final List<String> weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final List<String> shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75, // Better height
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Set Availability',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoal,
                          ),
                        ),
                         const SizedBox(height: 8),
                         Text(
                          'Select days and time range for your schedule.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.slate.withOpacity(0.8),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        const Text(
                          "Days",
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.charcoal, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12, // Increased spacing
                          runSpacing: 12,
                          children: List.generate(weekDays.length, (index) {
                            final day = weekDays[index];
                            final isSelected = selectedDays.contains(day);
                            return FilterChip(
                              label: Text(shortDays[index]),
                              selected: isSelected,
                              onSelected: (bool selected) {
                                setModalState(() {
                                  if (selected) {
                                    selectedDays.add(day);
                                  } else {
                                    selectedDays.remove(day);
                                  }
                                });
                              },
                              selectedColor: AppColors.primary,
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppColors.slate,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                              backgroundColor: const Color(0xFFF3F4F6),
                              side: BorderSide.none, // Cleaner no-border look
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            );
                          }),
                        ),
                        
                        const SizedBox(height: 32),
                        const Text(
                          "Time Range",
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.charcoal, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTimeInput('Start', startTime, (val) => setModalState(() => startTime = val))),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTimeInput('End', endTime, (val) => setModalState(() => endTime = val))),
                          ],
                        ),
                        
                        const SizedBox(height: 48),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: selectedDays.isEmpty ? null : () async {
                              await _performAddAvailability(selectedDays, startTime, endTime);
                              if (context.mounted) Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              disabledBackgroundColor: Colors.grey[300], // Visible inactive state
                              disabledForegroundColor: Colors.grey[500],
                              elevation: 0,
                            ),
                            child: Text(
                              selectedDays.isEmpty 
                                  ? "Select Days" 
                                  : "Add Availability (${selectedDays.length} days)",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildTimeInput(String label, String value, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, // User requested white
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.slate, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              isExpanded: true,
              dropdownColor: Colors.white, // Ensure dropdown menu is white
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
              items: _generateTimeSlots().map((time) {
                return DropdownMenuItem(value: time, child: Text(time, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.charcoal)));
              }).toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _generateTimeSlots() {
    List<String> slots = [];
    for (int i = 8; i <= 20; i++) { // 8 AM to 8 PM
      final hour = i > 12 ? i - 12 : i;
      final ampm = i >= 12 ? 'PM' : 'AM';
      slots.add('$hour:00 $ampm');
      slots.add('$hour:30 $ampm');
    }
    return slots;
  }

  Future<void> _performAddAvailability(List<String> days, String start, String end) async {
    if (_doctorId == null) return;
    
    int addedCount = 0;
    int duplicateCount = 0;

    for (var day in days) {
      // Check duplicate locally first
      bool exists = _slots.any((slot) => slot.day == day && slot.startTime == start && slot.endTime == end);
      
      if (!exists) {
        await _appointmentService.addAvailabilitySlot(
          doctorId: _doctorId!,
          day: day,
          startTime: start,
          endTime: end,
        );
        addedCount++;
      } else {
        duplicateCount++;
      }
    }

    _fetchAvailability();
    
    if (mounted) {
      String message = 'Availability updated.';
      if (addedCount > 0) message = 'Added $addedCount new slots.';
      if (duplicateCount > 0) message += (addedCount > 0 ? ' ' : '') + 'Skipped $duplicateCount duplicates.';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: addedCount > 0 ? AppColors.success : Colors.orange,
        ),
      );
    }
  }

  Future<void> _removeAvailability(String slotId) async {
    await _appointmentService.removeAvailabilitySlot(slotId);
    _fetchAvailability();
  }

  // Realtime Subscription
  RealtimeChannel? _appointmentsSubscription;

  void _setupRealtimeSubscription() {
    if (_doctorId == null) return;
    
    _appointmentsSubscription = SupabaseService.client
        .channel('public:appointments:$_doctorId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'appointments',
          // Removing filter temporarily for debugging
          // filter: PostgresChangeFilter(
          //   type: PostgresChangeFilterType.eq,
          //   column: 'doctor_id',
          //   value: _doctorId!,
          // ),
          callback: (payload) {
             debugPrint('🔴 REALTIME EVENT FIRED: ${payload.eventType}');
             debugPrint('🔴 Payload record: ${payload.newRecord}');
             
             // Manually filter in callback for now
             final newRecord = payload.newRecord;
             if (newRecord != null && newRecord['doctor_id'] == _doctorId) {
                 debugPrint('✅ Valid event for this doctor');
                 _fetchAppointments();
                 
                 if (payload.eventType == PostgresChangeEvent.insert) {
                   if (newRecord['status'] == 'pending') {
                     if (mounted) {
                       AppNotifications.showInfo(
                         context, 
                         'New Appointment Request Received!',
                         actionLabel: 'View',
                         onAction: () {}, 
                       );
                     }
                   }
                 }
             } else {
               debugPrint('⚠️ Event for different doctor or null record');
             }
          },
        )
        .subscribe((status, [error]) {
           debugPrint('🔌 Realtime Status: $status $error');
        });
  }

  @override
  void dispose() {
    _appointmentsSubscription?.unsubscribe();
    super.dispose();
  }



  void _goToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AppointmentScreen(isDoctor: true)),
    );
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _fetchDoctorInfo(),
      _fetchAppointments(),
      _fetchAvailability(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.cloud,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pendingCount = _appointments.where((a) => a.status == 'pending').length;
    final upcomingCount = _appointments.where((a) => a.status == 'accepted').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Clean off-white background
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.primaryCta,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(100),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showAddSlotDialog,
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text('Add Slot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Ensure scroll works even if content is short
          slivers: [
            // App Bar
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.primary,
              title: const Text(
                'Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: AppGradients.primaryDiagonal,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: _goToHistory,
                  icon: const Icon(Icons.history_rounded, color: Colors.white),
                  tooltip: 'Appointment History',
                ),
              ],
            ),
  
            // Stats & Content
            SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    children: [
                      _buildSectionHeader("Overview"),
                      const SizedBox(height: 12),
                      _buildStatsGrid(pendingCount, upcomingCount),
                      const SizedBox(height: 24),
                      
                      _buildSectionHeader("Appointment Requests", count: pendingCount),
                      const SizedBox(height: 12),
                      if (pendingCount == 0)
                        _buildEmptyState('No pending requests', Icons.check_circle_outline)
                      else
                        ..._appointments.where((a) => a.status == 'pending').map(_buildAppointmentCard),
                      
                      const SizedBox(height: 32),
                      
                      _buildSectionHeader("Weekly Schedule"),
                      const SizedBox(height: 12),
                      if (_slots.isEmpty)
                        _buildEmptyState('No availability configured', Icons.calendar_today_outlined)
                      else
                        _buildGroupedAvailabilityList(),
                        
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(int pending, int upcoming) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Pending", "$pending", Colors.orange),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildStatItem("Upcoming", "$upcoming", AppColors.primary), // Changed to Primary for theme
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildStatItem("Total", "${_appointments.length}", AppColors.slate),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {int? count}) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.charcoal)),
        if (count != null && count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text("$count", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          )
        ],
        const Spacer(),
        // Optional 'View All' can go here
      ],
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
               context,
               MaterialPageRoute(
                 builder: (_) => VetAppointmentDetailScreen(
                   appointment: appointment,
                   onStatusChanged: () => _fetchAppointments(), 
                 ),
               ),
             ).then((_) => _fetchAppointments());
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.cloud,
                        shape: BoxShape.circle,
                        image: appointment.petImage != null 
                           ? DecorationImage(image: NetworkImage(appointment.petImage!), fit: BoxFit.cover)
                           : null,
                      ),
                       child: appointment.petImage == null ? const Icon(Icons.pets, color: AppColors.slate, size: 20) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${appointment.type} for ${appointment.pet}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.charcoal)),
                          const SizedBox(height: 2),
                          Text(
                            "${appointment.date} • ${appointment.time}", 
                            style: const TextStyle(color: AppColors.slate, fontSize: 13, fontWeight: FontWeight.w500)
                          ),
                        ],
                      ),
                    ),
                    _buildActionButtons(appointment),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Appointment appointment) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Accept Button
        IconButton(
          onPressed: () => _updateAppointmentStatus(appointment, 'accepted'),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFDCFCE7), // Green 100
            foregroundColor: const Color(0xFF166534), // Green 800
            padding: const EdgeInsets.all(8),
          ),
          icon: const Icon(Icons.check_rounded, size: 20),
          tooltip: 'Accept',
        ),
        const SizedBox(width: 8),
        // Decline Button
        IconButton(
          onPressed: () => _updateAppointmentStatus(appointment, 'rejected'),
           style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFFEE2E2), // Red 100
            foregroundColor: const Color(0xFF991B1B), // Red 800
            padding: const EdgeInsets.all(8),
          ),
          icon: const Icon(Icons.close_rounded, size: 20),
           tooltip: 'Decline',
        ),
      ],
    );
  }

  Widget _buildGroupedAvailabilityList() {
    // Group slots by day is already handled by UI sort, but visually we can improve
    return Column(
      children: _slots.map((slot) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          leading: Container(
            width: 40,
            alignment: Alignment.centerLeft,
            child: Text(
              slot.day.substring(0, 3), // Mon, Tue
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
            ),
          ),
          title: Text(
            "${slot.startTime} - ${slot.endTime}",
            style: const TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.slate, size: 20),
            onPressed: () => _removeAvailability(slot.id),
            tooltip: 'Remove Slot',
          ),
        ),
      )).toList(),
    );
  }


  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        // border: Border.all(color: Colors.transparent), // Cleaner
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: AppColors.slate),
          ),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.slate, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

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
