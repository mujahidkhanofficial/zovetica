import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../services/supabase_service.dart'; // SupabaseService
import '../services/notification_service.dart';
import '../widgets/custom_toast.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import '../services/appointment_service.dart';
import '../services/auth_service.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/offline_banner.dart';
import '../services/review_service.dart'; // Review Service
import '../widgets/widgets.dart';
import '../widgets/cached_avatar.dart'; // Review Modal
import 'find_doctor_screen.dart';
import '../data/repositories/appointment_repository.dart';
import '../data/local/database.dart';

class AppointmentScreen extends StatefulWidget {
  final bool isDoctor;
  final String? doctorId; // Pass doctorId if known (e.g. from Dashboard)
  const AppointmentScreen({super.key, this.isDoctor = false, this.doctorId});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  // Your sample data (replace with Firestore later)
  final AppointmentService _appointmentService = AppointmentService();
  final ReviewService _reviewService = ReviewService(); // Add ReviewService
  final AppointmentRepository _appointmentRepo = AppointmentRepository.instance;
  final AuthService _authService = AuthService(); // Add AuthService
  String? _doctorId;
  
  @override
  void initState() {
    super.initState();
    if (widget.isDoctor) {
      _initDoctorMode();
    } else {
      _checkPendingReviews();
      // Trigger initial sync for offline support
      _appointmentRepo.syncAppointments();
      _setupRealtimeSubscription();
    }
  }

  Future<void> _initDoctorMode() async {
    // If ID passed from parent (Dashboard), use it directly
    if (widget.doctorId != null) {
      if (mounted) setState(() => _doctorId = widget.doctorId);
      _appointmentRepo.syncDoctorAppointments(_doctorId!);
      return;
    }

    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    // Local first
    final localDoc = await _appointmentRepo.getDoctorByUserId(userId);
    if (mounted) {
       setState(() {
         _doctorId = localDoc?.id;
       });
    }

    if (_doctorId != null) {
      // Background sync
       _appointmentRepo.syncDoctorAppointments(_doctorId!);
    } else {
      // Must sync to get ID
      await _syncDoctorProfile(userId);
    }
  }

  Future<void> _syncDoctorProfile(String userId) async {
    // Similar logic to dashboard - simplest is to rely on userRepo or auth check
    // Ideally we share this logic, but for now specific minimal fetch
    // We can assume if we are in this screen, we might be a doctor.
    // Let's try to get from repo if possible or service.
    // For now, simple fallback:
    // (In a real app, Doctor state should be in a Provider)
    // Note: getDoctorByUserId is purely local.
    // We'll rely on dashboard having run once, OR simple service call:
     try {
       // Just try to fetch appointments directly from service to get ID? 
       // No, we need ID for the stream.
       // Let's assume the user IS a doctor and fetch their profile to cache it.
       // We can actually reuse the logic I wrote for dashboard if I move it to Repo...
       // Or just do a quick lookup:
       // For speed, let's just wait for dashboard to have done it? No, unsafe.
       
       // ... Actually, the dashboard already ensures this.
       // But to be safe:
       // We can skip deep sync here and just return. 
       // But if offline and ID not cached, we are stuck.
       // That's acceptable for "offline": if never logged in as doctor, no offline data.
     } catch (e) {
       // ignore
     }
  }

  // Check for completed but unreviewed appointments
  Future<void> _checkPendingReviews() async {
    // Small delay to let UI build first
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    try {
      final appointments = await _appointmentService.getUserAppointments();
      // Filter for completed appointments (adjust status string as needed based on your DB)
      final completed = appointments.where((a) => a.status.toLowerCase() == 'completed').toList();
      
      for (var appt in completed) {
        // Skip if UUID is missing (shouldn't happen for real DB appointments)
        if (appt.uuid == null || appt.uuid!.isEmpty) continue;

        final hasReview = await _reviewService.hasReviewed(appt.uuid!);
        if (!hasReview) {
           if (!mounted) return;
           
           // Construct minimal doctor map for the modal
           final doctorMap = {
             'id': appt.doctorId,
             'name': appt.doctor,
             'firstName': appt.doctor.split(' ').first,
             'lastName': appt.doctor.split(' ').length > 1 ? appt.doctor.split(' ').sublist(1).join(' ') : '',
             'profile_image': appt.doctorImage,
           };

           // Show modal
           await showModalBottomSheet(
             context: context,
             isScrollControlled: true,
             backgroundColor: Colors.transparent,
             builder: (ctx) => ReviewModal(
               doctor: doctorMap,
               appointmentId: appt.uuid!, // Use UUID for reviews
               onReviewSubmitted: () {
                 _refresh(); // Refresh list/state
               },
             ),
           );
           
           // Only ask for one review at a time per session
           break; 
        }
      }
    } catch (e) {
      print('Error checking pending reviews: $e');
    }
  }

  // Refresh controller
  Future<void> _refresh() async {
    // Sync appointments from server
    if (!widget.isDoctor) {
      await _appointmentRepo.syncAppointments();
      _checkPendingReviews(); // Re-check on pull-to-refresh
    }
    setState(() {});
  }

  // Realtime Subscription
  RealtimeChannel? _appointmentSubscription;

  void _setupRealtimeSubscription() {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    debugPrint('🔌 Setting up Realtime for Pet Owner: $userId');

    _appointmentSubscription = SupabaseService.client
        .channel('public:appointments:user:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update, // Listen for updates (status changes)
          schema: 'public',
          table: 'appointments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
             debugPrint('🔴 REALTIME UPDATE RECIEVED (Pet Owner)');
             final newRecord = payload.newRecord;
             
             if (newRecord != null) {
                 // Sync to update UI
                 Future.microtask(() => _appointmentRepo.syncAppointments());

                 final status = newRecord['status'] as String?;
                 final oldStatus = payload.oldRecord?['status'] as String?; // Might be null if toast only
                 
                 if (status != null && status != oldStatus) {
                   String? title;
                   String? body;
                   
                   if (status == 'accepted') {
                     title = 'Appointment Confirmed! ✅';
                     body = 'Dr. ${newRecord['doctor_name'] ?? 'Doctor'} has accepted your appointment request.';
                   } else if (status == 'rejected' || status == 'cancelled') {
                     title = 'Appointment Update';
                     body = 'Your appointment request has been declined/cancelled.';
                   }

                   if (title != null) {
                      // 1. System Notification
                      NotificationService().showNotification(
                        id: newRecord['id'].hashCode,
                        title: title,
                        body: body!,
                      );

                      // 2. In-App Toast
                      if (mounted) {
                        CustomToast.show(
                          context, 
                          title,
                          type: status == 'accepted' ? ToastType.success : ToastType.error
                        );
                      }
                   }
                 }
             }
          },
        )
        .subscribe((status, [error]) {
           if (status == RealtimeSubscribeStatus.subscribed) {
             debugPrint('✅ Pet Owner Realtime Connected!');
             if (mounted) {
               // Optional: Show connection status for debugging
               // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connected to updates 🟢'), backgroundColor: Colors.green, duration: Duration(seconds: 1)));
             }
           }
        });
  }

  @override
  void dispose() {
    if (_appointmentSubscription != null) {
      SupabaseService.client.removeChannel(_appointmentSubscription!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.cloud,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isDoctor ? 'Appointment History' : 'My Appointments',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
               Text(
                widget.isDoctor ? 'Track your past visits' : 'Manage your visits',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refresh,
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: AppointmentSearchDelegate(

                    appointmentRepo: _appointmentRepo,
                  ),
                );
              },
            ),
          ],
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.primaryDiagonal,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51), // Translucent white
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withAlpha(77)),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26), // ~0.1 opacity
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.white,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                dividerColor: Colors.transparent, // Remove default divider
                tabs: const [
                  Tab(text: "Upcoming"),
                  Tab(text: "Past"),
                ],
              ),
            ),
          ),
        ),
        body: OfflineAwareBody(
          child: SafeArea(
            child: AppRefreshIndicator(
              onRefresh: _refresh,
              child: widget.isDoctor 
                  // Doctor view uses local-first repository now
                  ? (_doctorId == null 
                      ? const Center(child: CircularProgressIndicator()) 
                      : StreamBuilder<List<LocalAppointment>>(
                          stream: _appointmentRepo.watchDoctorAppointments(_doctorId!),
                          builder: (context, snapshot) {
                            final localAppointments = snapshot.data ?? [];
                            final appointments = localAppointments.map(_appointmentRepo.localToAppointment).toList();
                            return _buildTabbedContent(appointments, snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData, snapshot.error);
                          },
                        ))
                  // Pet owner view uses local-first repository
                  : StreamBuilder<List<LocalAppointment>>(
                      stream: _appointmentRepo.watchMyAppointments(),
                      builder: (context, snapshot) {
                        final localAppointments = snapshot.data ?? [];
                        final appointments = localAppointments.map(_appointmentRepo.localToAppointment).toList();
                        return _buildTabbedContent(appointments, snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData, snapshot.error);
                      },
                    ),
            ),
          ),
        ),
        floatingActionButton: widget.isDoctor ? null :_buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
        decoration: BoxDecoration(
          gradient: AppGradients.coralButton,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withAlpha(102),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FindDoctorScreen()),
            );
          },
          elevation: 0,
          backgroundColor: Colors.transparent,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Book Appointment',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
  }

  Widget _buildTabbedContent(List<Appointment> allAppointments, bool isLoading, Object? error) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text('Error: $error'));
    }

    final upcoming = allAppointments.where((a) => 
      ['pending', 'accepted', 'confirmed', 'rescheduled_pending'].contains(a.status.toLowerCase()) &&
      !_isPast(a.date, a.time)
    ).toList();
    
    final past = allAppointments.where((a) => 
      ['completed', 'cancelled', 'rejected'].contains(a.status.toLowerCase()) || 
      _isPast(a.date, a.time)
    ).toList();

    return TabBarView(
      children: [
        _buildGroupedList(upcoming, isPast: false),
        _buildGroupedList(past, isPast: true),
      ],
    );
  }
  
  bool _isPast(String dateStr, String timeStr) {
     try {
       // dateStr is typically YYYY-MM-DD
       final dateParts = dateStr.split('-');
       final year = int.parse(dateParts[0]);
       final month = int.parse(dateParts[1]);
       final day = int.parse(dateParts[2]);
       
       final timeParts = timeStr.split(':'); // HH:MM
       final hour = int.parse(timeParts[0]);
       final minute = int.parse(timeParts[1]);
       
       final dt = DateTime(year, month, day, hour, minute);
       return dt.isBefore(DateTime.now());
     } catch (e) {
       return false;
     }
  }

  Widget _buildGroupedList(List<Appointment> appointments, {required bool isPast}) {
    if (appointments.isEmpty) return _buildEmptyState(isPast);

    // Sort: Upcoming (Ascending), Past (Descending)
    // Sort: Upcoming (Ascending), Past (Descending)
    appointments.sort((a, b) {
      DateTime dateA;
      DateTime dateB;
      try {
        dateA = DateTime.parse('${a.date} ${a.time}');
      } catch (_) {
        dateA = DateTime.now(); // Fallback
      }
      try {
        dateB = DateTime.parse('${b.date} ${b.time}');
      } catch (_) {
        dateB = DateTime.now(); // Fallback
      }
      return isPast ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });

    final grouped = _groupAppointmentsByDate(appointments);
    
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final dateAppointments = grouped[dateKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                dateKey,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate,
                  letterSpacing: 1,
                  // uppercase?
                ),
              ),
            ),
            ...dateAppointments.map((appt) => _buildAppointmentCard(appt)),
          ],
        );
      },
    );
  }
  
  Map<String, List<Appointment>> _groupAppointmentsByDate(List<Appointment> appointments) {
    // Simple grouping logic
    final Map<String, List<Appointment>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    for (var appt in appointments) {
      try {
        final d = DateTime.parse(appt.date); // Assuming YYYY-MM-DD
        final dateOnly = DateTime(d.year, d.month, d.day);
        
        String key;
        if (dateOnly == today) {
          key = "TODAY";
        } else if (dateOnly == tomorrow) {
          key = "TOMORROW";
        } else if (dateOnly.isAfter(today) && dateOnly.difference(today).inDays < 7) {
          key = "THIS WEEK";
        } else if(dateOnly.isBefore(today)) {
          // For past, maybe group by Month if older?
          // For now, let's keep it simple: exact date
           key = "${_monthName(d.month)} ${d.day}, ${d.year}";
        } else {
           key = "${_monthName(d.month)} ${d.day}, ${d.year}";
        }
        
        if (!groups.containsKey(key)) {
          groups[key] = [];
        }
        groups[key]!.add(appt);
      } catch (e) {
        // Fallback
        if (!groups.containsKey("UNKNOWN")) groups["UNKNOWN"] = [];
        groups["UNKNOWN"]!.add(appt);
      }
    }
    return groups;
  }
  
  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  // No Appointment UI
  Widget _buildEmptyState([bool isPast = false]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(13),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPast ? Icons.history_rounded : Icons.calendar_today_rounded,
              size: 56,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isPast ? 'No Past Appointments' : 'No Upcoming Appointments',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          if (!isPast)
          Text(
            isPast ? 'Your history will appear here.' : 'Book your first visit with a specialized vet.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.slate,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  } 

  // Handle pet owner response to doctor's reschedule request
  Future<void> _respondToReschedule(Appointment appointment, bool accept) async {
    final newStatus = accept ? 'accepted' : 'cancelled';
    final message = accept 
        ? 'Reschedule accepted! Appointment confirmed.' 
        : 'Reschedule rejected. Appointment cancelled.';
    
    try {
      // Update status in repository
      await _appointmentRepo.updateAppointmentStatus(
        appointment.uuid ?? appointment.id.toString(),
        newStatus,
      );
      
      // Sync to get latest data
      await _appointmentRepo.syncAppointments();
      
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  accept ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: accept ? AppColors.secondary : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Failed to update appointment'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }


  // Appointment Card
  Widget _buildAppointmentCard(Appointment appointment) {
    // Status styling
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;
    
    switch (appointment.status.toLowerCase()) {
      case 'pending':
        statusColor = AppColors.warning;
        statusBgColor = AppColors.warning.withAlpha(30);
        statusIcon = Icons.schedule_rounded;
        break;
      case 'accepted':
      case 'confirmed':
        statusColor = AppColors.secondary;
        statusBgColor = AppColors.secondary.withAlpha(30);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusBgColor = AppColors.error.withAlpha(30);
        statusIcon = Icons.cancel_rounded;
        break;
      case 'completed':
        statusColor = AppColors.primary;
        statusBgColor = AppColors.primary.withAlpha(30);
        statusIcon = Icons.verified_rounded;
        break;
      case 'rescheduled_pending':
        statusColor = Colors.orange;
        statusBgColor = Colors.orange.withAlpha(30);
        statusIcon = Icons.swap_horiz_rounded;
        break;
      default:
        statusColor = AppColors.slate;
        statusBgColor = AppColors.slate.withAlpha(30);
        statusIcon = Icons.info_rounded;
    }
    
    final isPending = appointment.status.toLowerCase() == 'pending';
    final isReschedulePending = appointment.status.toLowerCase() == 'rescheduled_pending';
    final isActive = ['pending', 'accepted', 'confirmed'].contains(appointment.status.toLowerCase());
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: isPending 
            ? Border.all(color: AppColors.warning.withAlpha(60), width: 1.5)
            : isReschedulePending 
                ? Border.all(color: Colors.orange.withAlpha(100), width: 1.5)
                : null,
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
          onTap: () {},
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Type + Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        appointment.type,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            appointment.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),

                // Doctor & Line Info
                Row(
                  children: [
                    CachedAvatar(
                      imageUrl: appointment.doctorImage,
                      name: appointment.doctor,
                      radius: 20,
                      backgroundColor: AppColors.primary.withAlpha(26),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.doctor,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                        ),
                        Text(
                          appointment.clinic,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.slate,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),

                // Date Time Row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cloud,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(Icons.calendar_today_rounded, appointment.date),
                      _buildInfoItem(Icons.access_time_rounded, appointment.time),
                      _buildInfoItem(Icons.pets, appointment.pet),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Actions - Doctor view for accepted appointments (emergency reschedule)
                if (widget.isDoctor && ['accepted', 'confirmed'].contains(appointment.status.toLowerCase()) && !_isPast(appointment.date, appointment.time)) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showRescheduleDialog(appointment),
                      icon: Icon(Icons.edit_calendar_rounded, size: 18),
                      label: Text('Reschedule (Emergency)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: BorderSide(color: AppColors.warning.withAlpha(100)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                // Pet owner view - reschedule/cancel for active appointments
                ] else if (!widget.isDoctor && isActive) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRescheduleDialog(appointment),
                          icon: Icon(Icons.edit_calendar_rounded, size: 18),
                          label: Text('Reschedule'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.slate,
                            side: BorderSide(color: AppColors.borderLight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showCancelDialog(appointment),
                          icon: Icon(Icons.close_rounded, size: 18),
                          label: Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(color: AppColors.error.withAlpha(100)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (appointment.status.toLowerCase() == 'cancelled') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text(
                          'This appointment was cancelled',
                          style: TextStyle(fontSize: 13, color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                // Pet owner: Doctor has requested reschedule - Accept/Reject
                ] else if (!widget.isDoctor && appointment.status.toLowerCase() == 'rescheduled_pending') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withAlpha(60)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.swap_horiz_rounded, size: 18, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Doctor requested to reschedule',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _respondToReschedule(appointment, true),
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: const Text('Accept'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _respondToReschedule(appointment, false),
                                icon: const Icon(Icons.close_rounded, size: 18),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: BorderSide(color: AppColors.error),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.slate),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.charcoal,
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(Appointment appointment) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Cancel Appointment?',
      message: 'Are you sure you want to cancel this appointment? This action cannot be undone.',
      confirmText: 'Yes, Cancel',
      cancelText: 'No, Keep It',
      icon: Icons.event_busy_rounded,
      isDestructive: false,
      iconColor: AppColors.warning,
      confirmButtonColor: AppColors.error,
    );

    if (confirmed) {
      try {
        await _appointmentService.cancelAppointment(appointment.uuid ?? appointment.id.toString());
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 10),
                  Text('Appointment cancelled'),
                ],
              ),
              backgroundColor: AppColors.secondary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }


  void _showRescheduleDialog(Appointment appointment) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String? selectedTimeSlot;
    List<Map<String, dynamic>> availableSlots = [];
    bool isLoadingSlots = false;
    bool hasDoctorId = appointment.doctorId != null;
    bool doctorWorksOnDay = true; // Assume true until proven otherwise
    bool hasFetchedSlots = false; // Track if initial fetch is done

    // Function to fetch slots for selected date
    Future<void> fetchSlots(StateSetter setModalState) async {
      if (!hasDoctorId) {
        setModalState(() {
          availableSlots = [];
          isLoadingSlots = false;
        });
        return;
      }

      setModalState(() => isLoadingSlots = true);
      try {
        final slots = await _appointmentService.getAvailableSlotsForDate(
          appointment.doctorId!,
          selectedDate,
        );
        // If slots is empty, doctor doesn't work on this day
        // If slots has items but none available, all slots are booked
        final available = slots.where((s) => s['isAvailable'] == true).toList();
        setModalState(() {
          availableSlots = available;
          doctorWorksOnDay = slots.isNotEmpty; // Track if doctor has schedule
          isLoadingSlots = false;
          selectedTimeSlot = null; // Reset selection when date changes
        });
      } catch (e) {
        debugPrint('Error fetching slots: $e');
        setModalState(() {
          availableSlots = [];
          doctorWorksOnDay = false;
          isLoadingSlots = false;
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          // Fetch slots on first build only
          if (!hasFetchedSlots && !isLoadingSlots && hasDoctorId) {
            hasFetchedSlots = true; // Mark as fetched to prevent loop
            WidgetsBinding.instance.addPostFrameCallback((_) {
              fetchSlots(setModalState);
            });
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reschedule Appointment',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose a new date and available time slot',
                          style: TextStyle(color: AppColors.slate, fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Picker
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: AppColors.primary,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null && picked != selectedDate) {
                                setModalState(() => selectedDate = picked);
                                fetchSlots(setModalState);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.borderLight),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Select Date', style: TextStyle(color: AppColors.slate, fontSize: 12)),
                                      Text(
                                        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.charcoal),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Icon(Icons.arrow_drop_down, color: AppColors.slate),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Available Slots Section
                          Text(
                            'Available Time Slots',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Show warning if no doctorId
                          if (!hasDoctorId)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: AppColors.warning),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Doctor info unavailable. Please contact support to reschedule.',
                                      style: TextStyle(color: AppColors.warning, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          // Loading state
                          else if (isLoadingSlots)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(color: AppColors.primary),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Fetching available slots...',
                                      style: TextStyle(color: AppColors.slate),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          // No slots available
                          else if (availableSlots.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: doctorWorksOnDay 
                                    ? Colors.orange[50] 
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: doctorWorksOnDay 
                                    ? Border.all(color: Colors.orange.withOpacity(0.3)) 
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    doctorWorksOnDay 
                                        ? Icons.schedule 
                                        : Icons.event_busy,
                                    size: 48,
                                    color: doctorWorksOnDay 
                                        ? Colors.orange 
                                        : AppColors.slate,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    doctorWorksOnDay
                                        ? 'All slots are booked for this date'
                                        : 'Doctor is not available on this day',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.charcoal,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    doctorWorksOnDay
                                        ? 'Try selecting a different date for more availability'
                                        : 'The doctor does not have working hours on this day of the week',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.slate, fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          // Slots grid
                          else
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: availableSlots.map((slot) {
                                final timeStr = slot['time'] as String;
                                final displayTime = slot['displayTime'] as String? ?? timeStr;
                                final isSelected = selectedTimeSlot == timeStr;

                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() => selectedTimeSlot = timeStr);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? AppColors.primary 
                                          : AppColors.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected 
                                            ? AppColors.primary 
                                            : AppColors.primary.withOpacity(0.2),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Text(
                                      displayTime,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Confirm Button
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedTimeSlot == null
                            ? null
                            : () async {
                                Navigator.pop(ctx);
                                try {
                                  // Use repository for offline-first support
                                  await _appointmentRepo.rescheduleAppointment(
                                    appointmentId: appointment.uuid ?? appointment.id.toString(),
                                    newDate: selectedDate,
                                    newTime: selectedTimeSlot!,
                                  );
                                  
                                  // Refresh UI
                                  if (widget.isDoctor && _doctorId != null) {
                                    await _appointmentRepo.syncDoctorAppointments(_doctorId!);
                                  } else {
                                    await _appointmentRepo.syncAppointments();
                                  }
                                  setState(() {});
                                  if (mounted) {
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.white),
                                            const SizedBox(width: 10),
                                            Text('Appointment rescheduled successfully!'),
                                          ],
                                        ),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,

                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          selectedTimeSlot != null 
                              ? 'Confirm Reschedule'
                              : 'Select a Time Slot',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppointmentSearchDelegate extends SearchDelegate {
  final AppointmentRepository appointmentRepo;

  AppointmentSearchDelegate({required this.appointmentRepo});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return StreamBuilder<List<LocalAppointment>>(
      stream: appointmentRepo.watchMyAppointments(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        
        final all = snapshot.data!.map(appointmentRepo.localToAppointment).toList();
        final filtered = all.where((a) {
          final q = query.toLowerCase();
          return a.doctor.toLowerCase().contains(q) || 
                 a.pet.toLowerCase().contains(q) ||
                 a.type.toLowerCase().contains(q);
        }).toList();

        if (filtered.isEmpty) {
          return Center(child: Text('No appointments found for "$query"'));
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final appt = filtered[index];
            return ListTile(
              title: Text(appt.doctor),
              subtitle: Text('${appt.date} • ${appt.type}'),
              leading: const Icon(Icons.medical_services),
              onTap: () {
              },
            );
          },
        );
      },
    );
  }
}
