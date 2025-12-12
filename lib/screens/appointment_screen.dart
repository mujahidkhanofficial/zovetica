import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import '../services/appointment_service.dart';
import '../widgets/confirmation_dialog.dart';
import '../services/review_service.dart'; // Review Service
import '../widgets/review_modal.dart'; // Review Modal
import 'find_doctor_screen.dart';

class AppointmentScreen extends StatefulWidget {
  final bool isDoctor;
  const AppointmentScreen({super.key, this.isDoctor = false});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  // Your sample data (replace with Firestore later)
  final AppointmentService _appointmentService = AppointmentService();
  final ReviewService _reviewService = ReviewService(); // Add ReviewService
  
  @override
  void initState() {
    super.initState();
    if (!widget.isDoctor) {
      _checkPendingReviews();
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
    setState(() {});
    if (!widget.isDoctor) {
      _checkPendingReviews(); // Re-check on pull-to-refresh
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
            Text(
              widget.isDoctor ? 'Appointment History' : 'My Appointments',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // FutureBuilder for count? Or just rely on list length below.
             Text(
              widget.isDoctor ? 'Track your past visits' : 'Manage your visits',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70, // Fixed withAlpha 
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
      body: SafeArea(
        child: RefreshIndicator( // Added Refresh
          onRefresh: _refresh,
          child: FutureBuilder<List<Appointment>>(
            future: widget.isDoctor 
                ? _appointmentService.getMyDoctorAppointments() 
                : _appointmentService.getUserAppointments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                 return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              final appointments = snapshot.data ?? [];
              
              if (appointments.isEmpty) {
                 return _buildEmptyState();
              }
              
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100), // Extra bottom padding for FAB
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  return _buildAppointmentCard(appointments[index]);
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: widget.isDoctor ? null : Container(
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
      ),
    );
  }

  // No Appointment UI
  Widget _buildEmptyState() {
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
              Icons.calendar_today_rounded,
              size: 56,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Appointments Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Book your first visit with a specialized vet.',
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
      default:
        statusColor = AppColors.slate;
        statusBgColor = AppColors.slate.withAlpha(30);
        statusIcon = Icons.info_rounded;
    }
    
    final isPending = appointment.status.toLowerCase() == 'pending';
    final isActive = ['pending', 'accepted', 'confirmed'].contains(appointment.status.toLowerCase());
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: isPending 
            ? Border.all(color: AppColors.warning.withAlpha(60), width: 1.5)
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
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withAlpha(26),
                      backgroundImage: appointment.doctorImage?.isNotEmpty == true
                          ? NetworkImage(appointment.doctorImage!)
                          : null,
                      child: appointment.doctorImage?.isNotEmpty != true
                          ? Text(
                              appointment.doctor.split(' ').last[0],
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
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

                // Actions - only show for active appointments
                if (isActive) ...[
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
                                  final newDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                                  
                                  await _appointmentService.rescheduleAppointment(
                                    appointmentId: appointment.uuid ?? appointment.id.toString(),
                                    newDate: newDate,
                                    newTime: selectedTimeSlot!,
                                  );
                                  
                                  setState(() {});
                                  if (mounted) {
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.white),
                                            const SizedBox(width: 10),
                                            Text('Appointment rescheduled to $newDate at $selectedTimeSlot'),
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
                          disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
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
