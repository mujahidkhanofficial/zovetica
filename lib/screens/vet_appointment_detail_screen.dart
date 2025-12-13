import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zovetica/models/appointment_model.dart';
import 'package:zovetica/models/other_models.dart';
import 'package:zovetica/services/appointment_service.dart';
import 'package:zovetica/services/pet_service.dart';
import 'package:zovetica/theme/app_colors.dart';
import 'package:zovetica/theme/app_gradients.dart';
import 'package:zovetica/theme/app_spacing.dart';
import 'package:zovetica/theme/app_shadows.dart';
import 'package:zovetica/widgets/cached_avatar.dart';
import 'package:zovetica/widgets/custom_toast.dart';

class VetAppointmentDetailScreen extends StatefulWidget {
  final Appointment appointment;
  final VoidCallback? onStatusChanged;

  const VetAppointmentDetailScreen({
    super.key,
    required this.appointment,
    this.onStatusChanged,
  });

  @override
  State<VetAppointmentDetailScreen> createState() => _VetAppointmentDetailScreenState();
}

class _VetAppointmentDetailScreenState extends State<VetAppointmentDetailScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final PetService _petService = PetService();
  
  List<PetHealthEvent> _healthHistory = [];
  bool _isLoadingHistory = true;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.appointment.status;
    debugPrint("🖼️ Details Screen: Pet Image URL='${widget.appointment.petImage}'");
    _fetchPetHistory();
  }

  Future<void> _fetchPetHistory() async {
    if (widget.appointment.petId == null) {
      if (mounted) setState(() => _isLoadingHistory = false);
      return;
    }

    try {
      final events = await _petService.getHealthEvents(widget.appointment.petId!);
      if (mounted) {
        setState(() {
          _healthHistory = events.take(5).toList(); // Last 5 events
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await _appointmentService.updateAppointmentStatus(
        appointmentId: widget.appointment.uuid ?? widget.appointment.id.toString(),
        status: newStatus,
      );
      
      setState(() => _currentStatus = newStatus);
      widget.onStatusChanged?.call();
      
      if (mounted) {
        CustomToast.show(
          context, 
          'Appointment $newStatus', 
          type: ToastType.success
        );
        
        if (newStatus == 'rejected' || newStatus == 'cancelled') {
             Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context, 
          'Error: $e', 
          type: ToastType.error
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Appointment Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.primaryDiagonal,
          ),
        ),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Status & Time Header
            _buildHeaderCard(),
            const SizedBox(height: AppSpacing.xl),

            // 2. Pet Profile
            const Text("Patient Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.charcoal)),
            const SizedBox(height: AppSpacing.md),
            _buildPetProfileCard(),
            const SizedBox(height: AppSpacing.xl),

            // 3. Medical History
            const Text("Medical History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.charcoal)),
            const SizedBox(height: AppSpacing.md),
            _isLoadingHistory 
                ? const Center(child: CircularProgressIndicator())
                : _healthHistory.isEmpty 
                    ? _buildEmptyHistory()
                    : Column(children: _healthHistory.map((e) => _buildHistoryItem(e)).toList()),
            const SizedBox(height: AppSpacing.xl),

            // 4. Owner Info
            const Text("Pet Owner", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.charcoal)),
            const SizedBox(height: AppSpacing.md),
            _buildOwnerCard(),
            
            const SizedBox(height: 100), // Spacing for fab/buttons
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildHeaderCard() {
    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    
    switch (_currentStatus.toLowerCase()) {
      case 'accepted': 
      case 'confirmed':
        statusColor = AppColors.success; 
        statusBg = AppColors.success.withOpacity(0.1);
        statusIcon = Icons.check_circle; 
        break;
      case 'rejected': 
      case 'cancelled':
        statusColor = AppColors.error; 
        statusBg = AppColors.error.withOpacity(0.1);
        statusIcon = Icons.cancel; 
        break;
      case 'completed': 
        statusColor = AppColors.primary; 
        statusBg = AppColors.primary.withOpacity(0.1);
        statusIcon = Icons.task_alt; 
        break;
      default: 
        statusColor = Colors.orange; 
        statusBg = Colors.orange.withOpacity(0.1);
        statusIcon = Icons.access_time_filled;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      _currentStatus.toUpperCase(),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              Text(
                widget.appointment.type,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildTimeBox(widget.appointment.date.split('-').last, _monthName(widget.appointment.date), active: true),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.appointment.time, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.charcoal),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: AppColors.slate),
                        const SizedBox(width: 4),
                        Text(
                          widget.appointment.clinic.isEmpty ? "Virtual Clinic" : widget.appointment.clinic, 
                          style: const TextStyle(color: AppColors.slate, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(String dateStr) {
    try {
      final parts = dateStr.split('-');
      final month = int.parse(parts[1]);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return months[month - 1];
    } catch (e) {
      return '';
    }
  }

  Widget _buildTimeBox(String day, String month, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.cloud,
        borderRadius: BorderRadius.circular(16),
        boxShadow: active ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Column(
        children: [
          Text(
            month.toUpperCase(),
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              color: active ? Colors.white70 : AppColors.slate,
            ),
          ),
          Text(
            day,
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: active ? Colors.white : AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'pet_${widget.appointment.petId}',
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.cloud,
                boxShadow: [
                   BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: widget.appointment.petImage != null && widget.appointment.petImage!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.appointment.petImage!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (context, url, error) => const Icon(Icons.pets, color: AppColors.slate, size: 32),
                      )
                    : const Icon(Icons.pets, color: AppColors.slate, size: 32),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.appointment.pet,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Medical Checkup", // You can map this from Appointment Type if available
                    style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CachedAvatar(
          name: widget.appointment.doctor, // "doctor" field holds Owner Name in doctor view
          imageUrl: widget.appointment.ownerImage,
          radius: 28,
        ),
        title: Text(
          widget.appointment.doctor, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.charcoal),
        ),
        subtitle: const Text("Pet Owner", style: TextStyle(color: AppColors.slate)),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.cloud,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chevron_right, color: AppColors.charcoal),
        ),
        onTap: () {
          // Navigate to User Profile?
        },
      ),
    );
  }

  Widget _buildHistoryItem(PetHealthEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                event.title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.charcoal, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cloud,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${event.date.day}/${event.date.month}/${event.date.year}",
                  style: const TextStyle(fontSize: 11, color: AppColors.slate, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (event.notes != null) ...[
            const SizedBox(height: 8),
            Text(
              event.notes!, 
              style: const TextStyle(fontSize: 13, color: AppColors.slate, height: 1.4), 
              maxLines: 2, 
              overflow: TextOverflow.ellipsis,
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
     return Container(
       padding: const EdgeInsets.all(32),
       width: double.infinity,
       decoration: BoxDecoration(
         color: AppColors.cloud.withOpacity(0.5),
         borderRadius: BorderRadius.circular(20),
         border: Border.all(color: Colors.transparent),
       ),
       child: Column(
         children: [
           Icon(Icons.history_edu_rounded, color: AppColors.slate.withOpacity(0.4), size: 48),
           const SizedBox(height: 12),
           Text(
             "No medical history available", 
             style: TextStyle(color: AppColors.slate, fontWeight: FontWeight.w500),
           ),
         ],
       ),
     );
  }

  Widget _buildBottomActions() {
    if (_currentStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateStatus('rejected'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: BorderSide(color: AppColors.error.withOpacity(0.5), width: 1.5),
                    foregroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Decline", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryCta,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _updateStatus('accepted'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Accept Request", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } 
    
    if (_currentStatus == 'accepted') {
       return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: AppGradients.primaryDiagonal,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                 BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                 // Start Chat logic
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text("Message Owner", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
}
