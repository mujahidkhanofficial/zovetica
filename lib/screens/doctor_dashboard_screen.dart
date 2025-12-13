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
import '../widgets/widgets.dart'; 
import '../utils/app_notifications.dart';
import '../widgets/custom_toast.dart';
import '../services/notification_service.dart';
import '../data/repositories/appointment_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/local/database.dart'; // LocalDoctorsCompanion
import 'package:drift/drift.dart' show Value;

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final AuthService _authService = AuthService();
  // Repositories
  final AppointmentRepository _appointmentRepo = AppointmentRepository.instance;
  final UserRepository _userRepo = UserRepository.instance;

  String _firstName = "";
  String _profileImageUrl = "";
  Stream<List<LocalAppointment>>? _appointmentsStream; // Added Stream
  List<Appointment> _appointments = []; // Keep as fallback/cache for stats? Or remove? 
  // Let's keep _appointments populated by Stream listener or just rely on StreamBuilder for list.
  // Ideally, use StreamBuilder. But for Stats (pending count), we need headers.
  
  List<AvailabilitySlot> _slots = [];

  String? _doctorId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _initializeDoctorProfile();
  }

  Future<void> _initializeNotifications() async {
    await NotificationService().init();
    await NotificationService().requestPermissions();
  }

  Future<void> _initializeDoctorProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final localDoc = await _appointmentRepo.getDoctorByUserId(user.id);
      
      if (localDoc != null) {
        _doctorId = localDoc.id;
        _appointmentsStream = _appointmentRepo.watchDoctorAppointments(_doctorId!); // Init Stream immediately
        
        if (mounted) setState(() => _isLoading = false);
        
        await Future.wait([
          _fetchDoctorInfo(),
          _fetchAvailability(forceRefresh: false),
        ]);
        
        _syncDoctorProfile(user.id);
      } else {
        await _syncDoctorProfile(user.id);
        if (mounted) setState(() => _isLoading = false);
        
        if (_doctorId != null) {
           _appointmentsStream = _appointmentRepo.watchDoctorAppointments(_doctorId!); // Init Stream
          await Future.wait([
            _fetchDoctorInfo(),
            _fetchAvailability(),
          ]);
        }
      }

      _setupRealtimeSubscription();

    } catch (e) {
      debugPrint('Error initializing doctor profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncDoctorProfile(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('doctors')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        final syncedId = response['id'];
        
        if (_doctorId != null && _doctorId != syncedId) {
             debugPrint("⚠️ Doctor ID Mismatch Detected! Local: $_doctorId vs Remote: $syncedId");
             await _appointmentRepo.deleteDoctor(_doctorId!);
             
             if (mounted) {
               setState(() {
                 _doctorId = syncedId;
                 _appointmentsStream = _appointmentRepo.watchDoctorAppointments(_doctorId!);
               });
             }
             Future.microtask(() => _appointmentRepo.syncDoctorAppointments(_doctorId!));
        }

        _doctorId = syncedId;
        _appointmentsStream ??= _appointmentRepo.watchDoctorAppointments(_doctorId!);
        
        await _appointmentRepo.upsertDoctor(LocalDoctorsCompanion(
           id: Value(response['id']),
           userId: Value(userId),
           name: Value(response['name'] ?? 'Doctor'),
           specialty: Value(response['specialty']),
           clinic: Value(response['clinic']),
           available: Value(response['available'] ?? true),
           verified: Value(response['verified'] ?? false),
           createdAt: Value(DateTime.now()),
           isSynced: const Value(true),
        ));
      } else {
        // Auto-register logic (for new doctors)
         final newDoctor = await SupabaseService.client
            .from('doctors')
            .insert({
              'user_id': userId,
              'specialty': 'General Practitioner',
              'clinic': 'Zovetica Virtual Clinic',
              'available': true,
              'verified': true,
            })
            .select()
            .single();
            
        _doctorId = newDoctor['id'];
        
        // Cache new doctor
         await _appointmentRepo.upsertDoctor(LocalDoctorsCompanion(
          id: Value(newDoctor['id']),
          userId: Value(userId),
           name: Value('Doctor'),
           specialty: Value('General Practitioner'),
           clinic: Value('Zovetica Virtual Clinic'),
          available: const Value(true),
          verified: const Value(true),
          createdAt: Value(DateTime.now()),
          isSynced: const Value(true),
        ));

        // Update role
        await SupabaseService.client
          .from('users')
          .update({'role': 'doctor'})
          .eq('id', userId);
      }
    } catch (e) {
      debugPrint('Error syncing doctor profile: $e');
    }
  }

  Future<void> _fetchDoctorInfo() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Local first
        final localUser = await _userRepo.getUser(user.id);
        
        if (localUser != null) {
          if (mounted) {
            setState(() {
              _firstName = localUser.name?.split(' ').first ?? '';
              _profileImageUrl = localUser.profileImage ?? '';
            });
          }
        }
        
        // Background sync (handled by sync engine usually, but we can trigger specific sync if needed)
        // For now, rely on cached data or SyncEngine.
      }
    } catch (e) {
      debugPrint("Error fetching doctor info: $e");
    }
  }

  Future<void> _fetchAppointments({bool forceRefresh = false}) async {
    if (_doctorId == null) return;

    try {
      // 1. Immediate local load
      if (!forceRefresh) {
        final localApps = await _appointmentRepo.getDoctorAppointments(_doctorId!, forceRefresh: false);
        if (mounted && localApps.isNotEmpty) {
           setState(() {
            _appointments = localApps.map(_appointmentRepo.localToAppointment).toList();
          });
        }
      }

      // 2. Trigger sync if needed (or if force refresh)
      // Note: getDoctorAppointments(forceRefresh: true) handles sync then get
      if (forceRefresh || _appointments.isEmpty) {
         final syncedApps = await _appointmentRepo.getDoctorAppointments(_doctorId!, forceRefresh: true);
         if (mounted) {
           setState(() {
             _appointments = syncedApps.map(_appointmentRepo.localToAppointment).toList();
           });
           debugPrint("📊 Dashboard UI Updated: ${_appointments.length} appointments in state.");
           debugPrint("   - Pending: ${_appointments.where((a) => a.status == 'pending').length}");
           debugPrint("   - Upcoming: ${_appointments.where((a) => a.status == 'accepted').length}");
         }
      }
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
    }
  }

  Future<void> _fetchAvailability({bool forceRefresh = false}) async {
    if (_doctorId == null) return;

    try {
      final localSlots = await _appointmentRepo.getAvailabilitySlots(_doctorId!, forceRefresh: forceRefresh);
      
      final parsedSlots = localSlots.map(_appointmentRepo.localSlotToSlot).toList();

      // Sort logic (can rely on repo sort, but repo sort is by day string? Repo sort is by day/time too)
      // The repo query: orderBy([(s) => OrderingTerm.asc(s.day), (s) => OrderingTerm.asc(s.startTime)])
      // But day is string "Monday", so alpha sort. We need custom sort.
      
      final dayOrder = {
        'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4,
        'Friday': 5, 'Saturday': 6, 'Sunday': 7
      };

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
        await _appointmentRepo.cancelAppointment(appointmentId);
      } else {
        await _appointmentRepo.updateAppointmentStatus(appointmentId, status);
      }
      // UI refresh via local fetch
      _fetchAppointments();
      
      if (mounted) {
        CustomToast.show(
          context, 
          status == 'accepted' ? 'Appointment accepted' : 'Appointment declined', 
          type: status == 'accepted' ? ToastType.success : ToastType.error
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, 'Error: $e', type: ToastType.error);
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
                        
                        // Use StatefulBuilder's state for loading
                        Builder(
                          builder: (context) {
                            bool isAdding = false;
                            return StatefulBuilder(
                              builder: (context, setButtonState) {
                                return SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: (selectedDays.isEmpty || isAdding) ? null : () async {
                                      setButtonState(() => isAdding = true);
                                      await _performAddAvailability(selectedDays, startTime, endTime);
                                      if (context.mounted) Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      disabledBackgroundColor: isAdding ? AppColors.primary.withOpacity(0.7) : Colors.grey[300],
                                      disabledForegroundColor: isAdding ? Colors.white : Colors.grey[500],
                                      elevation: 0,
                                    ),
                                    child: isAdding
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            selectedDays.isEmpty 
                                                ? "Select Days" 
                                                : "Add Availability (${selectedDays.length} days)",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                  ),
                                );
                              },
                            );
                          },
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
        await _appointmentRepo.addAvailabilitySlot(
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
    await _appointmentRepo.removeAvailabilitySlot(slotId);
    _fetchAvailability();
  }

  // Realtime Subscription
  RealtimeChannel? _appointmentsSubscription;

  void _setupRealtimeSubscription() {
    if (_doctorId == null) return;
    
    // Unsubscribe existing
    if (_appointmentsSubscription != null) {
      SupabaseService.client.removeChannel(_appointmentsSubscription!);
    }

    debugPrint('🔌 Setting up Realtime for Doctor: $_doctorId');

    _appointmentsSubscription = SupabaseService.client
        .channel('public:appointments:$_doctorId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'appointments',
          // REMOVED FILTER to debug if events are being sent at all
          callback: (payload) {
             debugPrint('🔴 RECIEVED REALTIME EVENT!');
             debugPrint('   Type: ${payload.eventType}');
             debugPrint('   Record: ${payload.newRecord}');
             debugPrint('   Old: ${payload.oldRecord}');
             
             final newRecord = payload.newRecord;
             if (newRecord != null) {
                 // Check if it matches our doctor (Handle strict or loose comparison)
                 final eventDoctorId = newRecord['doctor_id']?.toString();
                 
                 debugPrint('   Event Doctor ID: $eventDoctorId');
                 debugPrint('   My Doctor ID: $_doctorId');
                 
                 if (eventDoctorId == _doctorId) {
                     debugPrint('✅ MATCH! Valid event for this doctor');
                     
                     // Trigger sync
                     Future.microtask(() => _appointmentRepo.syncDoctorAppointments(_doctorId!));
                     
                     if (payload.eventType == PostgresChangeEvent.insert) {
                       if (newRecord['status'] == 'pending') {
                         NotificationService().showNotification(
                           id: newRecord['id'].hashCode,
                           title: 'New Appointment Request',
                           body: 'A new patient has requested an appointment.',
                         );

                         if (mounted) {
                           CustomToast.show(
                             context, 
                             'New Appointment Request!',
                             type: ToastType.info
                           );
                         }
                       }
                     }
                 } else {
                    debugPrint('⚠️ Event ignored (ID mismatch)');
                 }
             }
          },
        )
        .subscribe((status, [error]) {
           debugPrint('🔌 Realtime Status: $status $error');
           if (status == RealtimeSubscribeStatus.subscribed) {
             debugPrint('✅ Realtime Connected!');
             // Connected silently
           } else if (status == RealtimeSubscribeStatus.closed || status == RealtimeSubscribeStatus.timedOut) {
              debugPrint('❌ Realtime Disconnected/Error: $error');
           }
        });
  }

  @override
  void dispose() {
    if (_appointmentsSubscription != null) {
      SupabaseService.client.removeChannel(_appointmentsSubscription!);
    }
    super.dispose();
  }



  void _goToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AppointmentScreen(isDoctor: true, doctorId: _doctorId)),
    );
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _fetchDoctorInfo(),
      _fetchAppointments(forceRefresh: true),
      _fetchAvailability(forceRefresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _appointmentsStream == null) {
      return const Scaffold(
        backgroundColor: AppColors.cloud,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
      body: StreamBuilder<List<LocalAppointment>>(
        stream: _appointmentsStream,
        builder: (context, snapshot) {
          // Convert stream data to UI models
          final localApps = snapshot.data ?? [];
          final currentAppointments = localApps.map(_appointmentRepo.localToAppointment).toList();
          
          // Calculate stats from stream data
          final pendingCount = currentAppointments.where((a) => a.status == 'pending').length;
          final upcomingCount = currentAppointments.where((a) => a.status == 'accepted').length;

          // Update local cache reference if needed for other methods (optional, but good for debug)
          _appointments = currentAppointments;

          return AppRefreshIndicator(
            onRefresh: _refreshData,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
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
                            ...currentAppointments.where((a) => a.status == 'pending').map(_buildAppointmentCard),
                          
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
          );
        }
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
    return GestureDetector(
      onLongPress: () {
        // Hidden Debug Menu
        showDialog(context: context, builder: (ctx) => AlertDialog(
          title: const Text("Debug Info"),
          content: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text("User ID: ${_authService.currentUser?.id}"),
               const SizedBox(height: 8),
               Text("Doctor ID (Table): $_doctorId"),
               const SizedBox(height: 8),
               Text("Appointments: ${_appointments.length}"),
               const SizedBox(height: 8),
               Text("Pending: ${_appointments.where((a) => a.status == 'pending').length}"),
             ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _syncDoctorProfile(_authService.currentUser!.id).then((_) {
                  _fetchAppointments(forceRefresh: true);
                });
              }, 
              child: const Text("Force Sync")
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
          ],
        ));
      },
      child: Row(
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
      ),
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


