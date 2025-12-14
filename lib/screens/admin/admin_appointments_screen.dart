import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../services/admin_service.dart';
import '../../models/appointment_model.dart';
import 'package:intl/intl.dart';

/// Admin Appointments Overview Screen
/// Displays all appointments with filtering and management capabilities.
class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() => _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  final AdminService _adminService = AdminService();
  final ScrollController _scrollController = ScrollController();

  List<Appointment> _appointments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  String? _selectedStatus;
  DateTime? _selectedDate;

  final List<String> _statusOptions = ['pending', 'confirmed', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreAppointments();
    }
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    _currentPage = 0;

    final appointments = await _adminService.getAllAppointments(
      page: _currentPage,
      statusFilter: _selectedStatus,
      dateFrom: _selectedDate,
      dateTo: _selectedDate,
    );

    setState(() {
      _appointments = appointments;
      _isLoading = false;
    });
  }

  Future<void> _loadMoreAppointments() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    final appointments = await _adminService.getAllAppointments(
      page: _currentPage,
      statusFilter: _selectedStatus,
      dateFrom: _selectedDate,
    );

    setState(() {
      _appointments.addAll(appointments);
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedStatus == null,
                    onSelected: (_) {
                      setState(() => _selectedStatus = null);
                      _loadAppointments();
                    },
                  ),
                  const SizedBox(width: 8),
                  ..._statusOptions.map((status) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_capitalizeFirst(status)),
                      selected: _selectedStatus == status,
                      selectedColor: _getStatusColor(status).withOpacity(0.3),
                      onSelected: (_) {
                        setState(() => _selectedStatus = status);
                        _loadAppointments();
                      },
                    ),
                  )),
                ],
              ),
            ),
          ),

          // Selected Date Banner
          if (_selectedDate != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              color: AppColors.primary.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Showing: ${DateFormat('MMMM d, yyyy').format(_selectedDate!)}',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      setState(() => _selectedDate = null);
                      _loadAppointments();
                    },
                    child: const Icon(Icons.close, size: 18, color: AppColors.primary),
                  ),
                ],
              ),
            ),

          // Appointments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _appointments.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadAppointments,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: _appointments.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _appointments.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.lg),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _buildAppointmentCard(
                              _appointments[index],
                              isDark,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: AppColors.slate),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No appointments found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Try adjusting your filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment, bool isDark) {
    final statusColor = _getStatusColor(appointment.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
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
      child: Column(
        children: [
          // Status Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _capitalizeFirst(appointment.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: ${appointment.id.length > 8 ? appointment.id.substring(0, 8) : appointment.id}...',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Date and Time
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('dd').format(appointment.dateTime),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(appointment.dateTime),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy').format(appointment.dateTime),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: AppColors.slate),
                              const SizedBox(width: 4),
                              Text(
                                appointment.time,
                                style: TextStyle(color: AppColors.slate),
                              ),
                              if (appointment.type.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Icon(Icons.medical_services, size: 16, color: AppColors.slate),
                                const SizedBox(width: 4),
                                Text(
                                  appointment.type,
                                  style: TextStyle(color: AppColors.slate),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.md),

                // Price (if available)
                if (appointment.price > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Appointment Fee'),
                      Text(
                        'PKR ${appointment.price}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),

                // Actions for non-completed/cancelled appointments
                if (appointment.status == 'pending' || appointment.status == 'confirmed') ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          onPressed: () => _cancelAppointment(appointment),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'completed':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.slate;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadAppointments();
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this appointment?'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason',
                hintText: 'Optional...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _adminService.cancelAppointment(
        appointment.id,
        reasonController.text.isEmpty ? 'Cancelled by admin' : reasonController.text,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment cancelled')),
        );
        _loadAppointments();
      }
    }

    reasonController.dispose();
  }
}
