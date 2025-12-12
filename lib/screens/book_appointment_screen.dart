import 'package:flutter/material.dart';
import 'package:zovetica/models/app_models.dart';
import 'package:zovetica/services/appointment_service.dart';
import 'package:zovetica/services/pet_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import '../widgets/pet_button.dart';
import '../utils/app_notifications.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const BookAppointmentScreen({super.key, required this.doctor});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final PetService _petService = PetService();
  
  List<Pet> _myPets = [];
  String? _selectedPetId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  String _selectedType = 'General Checkup';
  final TextEditingController _notesController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingPets = true;

  final List<String> _appointmentTypes = [
    'General Checkup',
    'Vaccination',
    'Surgery',
    'Dental Care',
    'Behavioral',
    'Emergency',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _fetchPets();
  }

  Future<void> _fetchPets() async {
    try {
      final pets = await _petService.getPets();
      if (mounted) {
        setState(() {
          _myPets = pets;
          if (pets.isNotEmpty) {
            _selectedPetId = pets.first.id;
          }
          _isLoadingPets = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPets = false);
        AppNotifications.showError(context, 'Failed to load pets');
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.charcoal,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.charcoal,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedPetId == null) {
      AppNotifications.showError(context, 'Please select a pet');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formattedTime = '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      
      await _appointmentService.bookAppointment(
        doctorId: widget.doctor['id'],
        petId: _selectedPetId!,
        date: _selectedDate,
        time: formattedTime,
        type: _selectedType,
        // notes: _notesController.text, // Add notes if service supports it
      );

      if (mounted) {
        AppNotifications.showSuccess(context, 'Appointment booked successfully!');
        Navigator.pop(context); // Close screen
        Navigator.pop(context); // Close bottom sheet if open
      }
    } catch (e) {
      if (mounted) {
        AppNotifications.showError(context, 'Failed to book: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorName = "${widget.doctor['firstName']} ${widget.doctor['lastName']}";
    
    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        title: const Text(
          'Book Appointment',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
      body: _isLoadingPets
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor Summary Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: widget.doctor['image']?.isNotEmpty == true
                              ? NetworkImage(widget.doctor['image'])
                              : null,
                          backgroundColor: AppColors.primary.withAlpha(26),
                          child: widget.doctor['image']?.isNotEmpty != true
                              ? Text(
                                  doctorName[0],
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctorName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.charcoal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.doctor['specialty'] ?? 'Specialist',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.slate,
                                ),
                              ),
                              Text(
                                widget.doctor['clinic'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.slate,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Form
                  Text(
                    'Appointment Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Select Pet
                  _buildLabel('Select Pet'),
                  if (_myPets.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppColors.error),
                          const SizedBox(width: 8),
                          const Text('Please add a pet first to book.'),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPetId,
                          isExpanded: true,
                          items: _myPets.map((pet) {
                            return DropdownMenuItem(
                              value: pet.id,
                              child: Row(
                                children: [
                                  Text(pet.emoji),
                                  const SizedBox(width: 8),
                                  Text(pet.name),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedPetId = val),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Select Type
                  _buildLabel('Appointment Type'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedType,
                        isExpanded: true,
                        items: _appointmentTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedType = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date & Time
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Date'),
                            GestureDetector(
                              onTap: _selectDate,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Time'),
                            GestureDetector(
                              onTap: _selectTime,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time_rounded, size: 20, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedTime.format(context),
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: PetButton(
                      text: 'Confirm Booking',
                      onPressed: _myPets.isEmpty ? null : _submitBooking,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.slate,
        ),
      ),
    );
  }
}
