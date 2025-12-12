import 'package:flutter/material.dart';
import 'package:zovetica/models/appointment_model.dart';
import 'package:zovetica/models/other_models.dart';
import 'package:zovetica/services/appointment_service.dart';
import 'package:zovetica/services/pet_service.dart';
import 'package:zovetica/theme/app_colors.dart';
import 'package:zovetica/theme/app_spacing.dart';
import 'package:zovetica/theme/app_shadows.dart';

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
    _fetchPetHistory();
  }

  Future<void> _fetchPetHistory() async {
    if (widget.appointment.petId == null) {
      setState(() => _isLoadingHistory = false);
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
        appointmentId: widget.appointment.id.toString(),
        status: newStatus,
      );
      
      setState(() => _currentStatus = newStatus);
      widget.onStatusChanged?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment $newStatus')),
        );
        if (newStatus == 'rejected' || newStatus == 'cancelled') {
             Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Appointment Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
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
            const Text("Patient Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),
            _buildPetProfileCard(),
            const SizedBox(height: AppSpacing.xl),

            // 3. Medical History
            const Text("Medical History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),
            _isLoadingHistory 
                ? const Center(child: CircularProgressIndicator())
                : _healthHistory.isEmpty 
                    ? _buildEmptyHistory()
                    : Column(children: _healthHistory.map((e) => _buildHistoryItem(e)).toList()),
            const SizedBox(height: AppSpacing.xl),

            // 4. Owner Info
            const Text("Pet Owner", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
    IconData statusIcon;
    
    switch (_currentStatus.toLowerCase()) {
      case 'accepted': statusColor = AppColors.success; statusIcon = Icons.check_circle; break;
      case 'rejected': statusColor = AppColors.error; statusIcon = Icons.cancel; break;
      case 'completed': statusColor = AppColors.primary; statusIcon = Icons.task_alt; break;
      default: statusColor = Colors.orange; statusIcon = Icons.access_time_filled;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.appointment.date, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  widget.appointment.time, 
                  style: const TextStyle(color: AppColors.slate, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  _currentStatus.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.cloud,
              borderRadius: BorderRadius.circular(12),
              image: widget.appointment.petImage != null 
                  ? DecorationImage(image: NetworkImage(widget.appointment.petImage!), fit: BoxFit.cover)
                  : null,
            ),
            child: widget.appointment.petImage == null 
                ? const Icon(Icons.pets, color: AppColors.slate, size: 32)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.appointment.pet,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.appointment.type, // Usually type of appointment, but maybe 'Dog - Vaccination'
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerCard() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: widget.appointment.ownerImage != null ? NetworkImage(widget.appointment.ownerImage!) : null,
        child: widget.appointment.ownerImage == null ? const Icon(Icons.person) : null,
      ),
      title: Text(widget.appointment.doctor, style: const TextStyle(fontWeight: FontWeight.bold)), // Remember: doctor field has OwnerName in Vet Mode
      subtitle: const Text("Tap to view profile"),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Navigate to User Profile?
      },
    );
  }

  Widget _buildHistoryItem(PetHealthEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
        color: AppColors.cloud.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                event.title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.charcoal),
              ),
              Text(
                "${event.date.day}/${event.date.month}/${event.date.year}",
                style: const TextStyle(fontSize: 12, color: AppColors.slate),
              ),
            ],
          ),
          if (event.notes != null) ...[
            const SizedBox(height: 4),
            Text(event.notes!, style: const TextStyle(fontSize: 13, color: AppColors.slate), maxLines: 2, overflow: TextOverflow.ellipsis),
          ]
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
     return Container(
       padding: const EdgeInsets.all(24),
       width: double.infinity,
       decoration: BoxDecoration(
         color: AppColors.cloud.withOpacity(0.3),
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: AppColors.borderLight, style: BorderStyle.solid),
       ),
       child: Column(
         children: [
           Icon(Icons.history_edu_rounded, color: AppColors.slate.withOpacity(0.5), size: 40),
           const SizedBox(height: 8),
           Text("No medical history available", style: TextStyle(color: AppColors.slate)),
         ],
       ),
     );
  }

  Widget _buildBottomActions() {
    if (_currentStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateStatus('rejected'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.error),
                    foregroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Decline"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateStatus('accepted'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("Accept Request"),
                ),
              ),
            ],
          ),
        ),
      );
    } 
    
    if (_currentStatus == 'accepted') {
       return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: () {
               // Start Chat logic
            },
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text("Message Owner"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
}
