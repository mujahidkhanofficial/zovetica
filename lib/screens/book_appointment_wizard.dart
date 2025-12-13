import 'package:flutter/material.dart';
import 'package:zovetica/models/app_models.dart';
import 'package:zovetica/models/time_slot.dart';
import 'package:zovetica/services/appointment_service.dart';
import 'package:zovetica/services/pet_service.dart';
import 'package:zovetica/services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import '../utils/app_notifications.dart';

/// Professional Multi-Step Appointment Booking Wizard
/// Redesigned with enterprise-level UI and multi-pet selection
class BookAppointmentWizard extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const BookAppointmentWizard({super.key, required this.doctor});

  @override
  State<BookAppointmentWizard> createState() => _BookAppointmentWizardState();
}

class _BookAppointmentWizardState extends State<BookAppointmentWizard>
    with SingleTickerProviderStateMixin {
  final AppointmentService _appointmentService = AppointmentService();
  final PetService _petService = PetService();
  final NotificationService _notificationService = NotificationService();
  final PageController _pageController = PageController();

  late AnimationController _animationController;
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isLoadingSlots = false;

  // Step 1: Multiple Pet Selection
  List<Pet> _myPets = [];
  final Set<String> _selectedPetIds = {};

  // Step 2: Date Selection
  List<DateTime> _availableDates = [];
  DateTime? _selectedDate;

  // Step 3: Service Type & Time Selection
  List<Map<String, dynamic>> _availableSlots = [];
  String? _selectedTime;
  AppointmentType _selectedType = AppointmentType.predefinedTypes.first;

  // Step titles for progress
  final List<String> _stepTitles = ['Pets', 'Date', 'Service', 'Confirm'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadInitialData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final pets = await _petService.getPets();
      final dates = await _appointmentService.getAvailableDates(widget.doctor['id']);

      if (mounted) {
        setState(() {
          _myPets = pets;
          _availableDates = dates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppNotifications.showError(context, 'Failed to load data');
      }
    }
  }

  Future<void> _loadSlotsForDate(DateTime date) async {
    setState(() => _isLoadingSlots = true);
    try {
      final slots = await _appointmentService.getAvailableSlotsForDate(
        widget.doctor['id'],
        date,
      );
      if (mounted) {
        setState(() {
          _availableSlots = slots;
          _selectedTime = null;
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSlots = false);
        AppNotifications.showError(context, 'Failed to load time slots');
      }
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedPetIds.isEmpty || _selectedDate == null || _selectedTime == null) {
      AppNotifications.showError(context, 'Please complete all steps');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Book for each selected pet
      for (final petId in _selectedPetIds) {
        await _appointmentService.bookWithSlotCheck(
          doctorUserId: widget.doctor['id'],
          petId: petId,
          date: _selectedDate!,
          time: _selectedTime!,
          type: _selectedType.name,
          priceInPKR: _selectedType.priceInPKR,
        );
      }

      // Send notification to doctor
      final dateStr = '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
      final petCount = _selectedPetIds.length;
      final petNames = _myPets
          .where((p) => _selectedPetIds.contains(p.id))
          .map((p) => p.name)
          .join(', ');

      // Send notification to doctor (optional - don't fail booking if this errors)
      try {
        // Use doctor's user_id for notification, fallback to id
        final doctorUserId = widget.doctor['user_id'] ?? widget.doctor['id'];
        await _notificationService.createNotification(
          userId: doctorUserId,
          type: 'message', // Using 'message' type as DB constraint doesn't allow 'appointment'
          title: 'New Appointment Request',
          body: 'You have a ${_selectedType.name} appointment for $petCount pet(s) ($petNames) on $dateStr at $_selectedTime',
        );
      } catch (notifError) {
        // Notification failed but booking succeeded - don't block the flow
        debugPrint('⚠️ Notification failed: $notifError');
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog(petCount);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppNotifications.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showSuccessDialog(int petCount) {
    final selectedPets = _myPets.where((p) => _selectedPetIds.contains(p.id)).toList();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient - Full bleed
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: const BoxDecoration(
                    gradient: AppGradients.primaryCta,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Booking Confirmed!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content section with padding
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildDialogInfoRow(Icons.pets_rounded, 'Pets', selectedPets.map((p) => p.name).join(', ')),
                      const SizedBox(height: 12),
                      _buildDialogInfoRow(Icons.calendar_today_rounded, 'Date', 
                          '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                      const SizedBox(height: 12),
                      _buildDialogInfoRow(Icons.access_time_rounded, 'Time', _selectedTime ?? ''),
                      const SizedBox(height: 12),
                      _buildDialogInfoRow(_selectedType.icon, 'Service', _selectedType.name),
                      const SizedBox(height: 20),
                      // Notice
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 20, color: AppColors.secondary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'The doctor will confirm your appointment shortly.',
                                style: TextStyle(fontSize: 13, color: AppColors.charcoal),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Done Button
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: AppGradients.coralButtonDecoration(radius: 14),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.home_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Back to Home',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: AppColors.slate)),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.charcoal)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      body: SafeArea(
        child: _isLoading && _myPets.isEmpty
            ? _buildLoadingState()
            : Column(
                children: [
                  _buildHeader(),
                  _buildProgressStepper(),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStep1PetSelection(),
                        _buildStep2DateSelection(),
                        _buildStep3ServiceAndTime(),
                        _buildStep4Confirmation(),
                      ],
                    ),
                  ),
                  _buildNavigationBar(),
                ],
              ),
      ),
    );
  }

  // ============ HEADER ============
  Widget _buildHeader() {
    final doctorName = "${widget.doctor['firstName'] ?? ''} ${widget.doctor['lastName'] ?? ''}".trim();
    final displayName = widget.doctor['name'] ?? doctorName;
    
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 16),
      decoration: const BoxDecoration(
        gradient: AppGradients.primaryDiagonal,
      ),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, 
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          // Title Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Book Appointment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'with Dr. ${displayName.isNotEmpty ? displayName : "Veterinarian"}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Doctor Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(100), width: 2),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundImage: widget.doctor['profile_image']?.isNotEmpty == true
                  ? NetworkImage(widget.doctor['profile_image'])
                  : null,
              backgroundColor: Colors.white.withAlpha(30),
              child: widget.doctor['profile_image']?.isNotEmpty != true
                  ? Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'D',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ============ PROGRESS STEPPER ============
  Widget _buildProgressStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: List.generate(_stepTitles.length, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isCurrent ? 44 : 36,
                      height: isCurrent ? 44 : 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isActive ? AppGradients.primaryCta : null,
                        color: isActive ? null : AppColors.borderLight,
                        boxShadow: isCurrent
                            ? [BoxShadow(
                                color: AppColors.primary.withAlpha(60),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )]
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive ? Colors.white : AppColors.slate,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isCurrent ? 16 : 14,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _stepTitles[index],
                      style: TextStyle(
                        color: isActive ? AppColors.charcoal : AppColors.slate,
                        fontSize: 12,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (index < _stepTitles.length - 1)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.only(bottom: 24, left: 4, right: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: index < _currentStep 
                            ? AppColors.secondary 
                            : AppColors.borderLight,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ============ STEP 1: MULTI-PET SELECTION ============
  Widget _buildStep1PetSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.pets_rounded,
            title: 'Select Your Pets',
            subtitle: 'Choose one or more pets for this appointment',
          ),
          const SizedBox(height: 20),
          if (_myPets.isEmpty)
            _buildEmptyPetsState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _myPets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final pet = _myPets[index];
                final isSelected = _selectedPetIds.contains(pet.id);
                return _buildPetCard(pet, isSelected);
              },
            ),
          if (_selectedPetIds.length > 1) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(20),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.secondary.withAlpha(50)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, 
                      color: AppColors.secondaryDark, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_selectedPetIds.length} pets selected. Each will have a separate appointment at the same time.',
                      style: TextStyle(
                        color: AppColors.secondaryDark,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPetCard(Pet pet, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedPetIds.remove(pet.id);
          } else {
            _selectedPetIds.add(pet.id);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: AppColors.primary.withAlpha(25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )]
              : [BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )],
        ),
        child: Row(
          children: [
            // Pet Avatar with Image
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: pet.imageUrl.isEmpty && isSelected 
                    ? AppGradients.primaryCta 
                    : null,
                color: pet.imageUrl.isEmpty && !isSelected 
                    ? AppColors.cloud 
                    : null,
                borderRadius: BorderRadius.circular(16),
                border: isSelected 
                    ? Border.all(color: AppColors.primary, width: 2)
                    : Border.all(color: AppColors.borderLight),
                image: pet.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(pet.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: pet.imageUrl.isEmpty
                  ? Center(
                      child: Text(
                        pet.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Pet Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet.breed} • ${pet.age}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ),
            ),
            // Selection Indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected ? AppGradients.primaryCta : null,
                border: isSelected 
                    ? null 
                    : Border.all(color: AppColors.borderLight, width: 2),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ============ STEP 2: DATE SELECTION ============
  Widget _buildStep2DateSelection() {
    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June',
                        'July', 'August', 'September', 'October', 'November', 'December'];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.calendar_month_rounded,
            title: 'Choose a Date',
            subtitle: 'Select an available appointment date',
          ),
          const SizedBox(height: 20),
          if (_availableDates.isEmpty)
            _buildEmptyState(
              icon: Icons.event_busy_rounded,
              title: 'No Available Dates',
              subtitle: 'The doctor has no available slots in the next 30 days',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: _availableDates.length,
              itemBuilder: (context, index) {
                final date = _availableDates[index];
                final isSelected = _selectedDate?.day == date.day &&
                    _selectedDate?.month == date.month &&
                    _selectedDate?.year == date.year;
                return _buildDateCard(date, isSelected, monthNames);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDateCard(DateTime date, bool isSelected, List<String> monthNames) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final isToday = DateTime.now().day == date.day && 
                    DateTime.now().month == date.month;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedDate = date);
        _loadSlotsForDate(date);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.primaryCta : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: isSelected ? null : Border.all(color: AppColors.borderLight),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: AppColors.primary.withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayNames[date.weekday - 1],
              style: TextStyle(
                color: isSelected ? Colors.white.withAlpha(200) : AppColors.slate,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.charcoal,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              monthNames[date.month - 1].substring(0, 3),
              style: TextStyle(
                color: isSelected ? Colors.white.withAlpha(200) : AppColors.slate,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isToday) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withAlpha(40) 
                      : AppColors.accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'TODAY',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============ STEP 3: SERVICE & TIME ============
  Widget _buildStep3ServiceAndTime() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Service Type Section - Horizontal chips
          Text(
            'Select Service',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          // Wrap for service chips - responsive layout
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppointmentType.predefinedTypes.map((type) {
              final isSelected = _selectedType.id == type.id;
              return _buildServiceChip(type, isSelected);
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Selected service details
          _buildSelectedServiceInfo(),
          
          const SizedBox(height: 20),

          // Time Slots Section
          Text(
            'Select Time',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedDate != null 
                ? 'Available slots for ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                : 'Please select a date first',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoadingSlots)
            _buildLoadingSlots()
          else if (_availableSlots.isEmpty)
            _buildNoSlotsMessage()
          else
            _buildTimeSlotGrid(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildServiceChip(AppointmentType type, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.coralButton : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: isSelected ? null : Border.all(color: AppColors.borderLight),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: AppColors.accent.withAlpha(40),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type.icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              type.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedServiceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withAlpha(30)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_selectedType.icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedType.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_selectedType.durationMinutes} min • ${_selectedType.formattedPrice}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _selectedType.formattedPrice,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.secondaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSlotsMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 40,
            color: AppColors.slate.withAlpha(150),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedDate == null 
                ? 'Select a date first' 
                : 'No slots available',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedDate == null
                ? 'Go back and pick a date to see time slots'
                : 'Try selecting a different date',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.slate,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotGrid() {
    // Group by label
    final Map<String, List<Map<String, dynamic>>> groupedSlots = {};
    for (final slot in _availableSlots) {
      final label = slot['label'] as String? ?? 'Available';
      groupedSlots.putIfAbsent(label, () => []).add(slot);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedSlots.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Row(
                children: [
                  Icon(
                    entry.key == 'Morning' 
                        ? Icons.wb_sunny_rounded
                        : entry.key == 'Afternoon'
                            ? Icons.wb_cloudy_rounded
                            : Icons.nights_stay_rounded,
                    size: 16,
                    color: AppColors.slate,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.value.map((slot) {
                final isAvailable = slot['isAvailable'] as bool;
                final isSelected = _selectedTime == slot['time'];
                return _buildTimeChip(slot, isSelected, isAvailable);
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTimeChip(Map<String, dynamic> slot, bool isSelected, bool isAvailable) {
    return GestureDetector(
      onTap: isAvailable ? () => setState(() => _selectedTime = slot['time']) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.primaryCta : null,
          color: !isAvailable
              ? AppColors.borderLight.withAlpha(80)
              : isSelected
                  ? null
                  : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: !isAvailable || isSelected
              ? null
              : Border.all(color: AppColors.borderLight),
        ),
        child: Text(
          slot['displayTime'] as String,
          style: TextStyle(
            color: !isAvailable
                ? AppColors.slate.withAlpha(120)
                : isSelected
                    ? Colors.white
                    : AppColors.charcoal,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
            decoration: !isAvailable ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }

  // ============ STEP 4: CONFIRMATION ============
  Widget _buildStep4Confirmation() {
    final selectedPets = _myPets.where((p) => _selectedPetIds.contains(p.id)).toList();
    final totalPrice = _selectedType.priceInPKR * selectedPets.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.fact_check_rounded,
            title: 'Review Booking',
            subtitle: 'Please confirm your appointment details',
          ),
          const SizedBox(height: 20),

          // Summary Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 20,
                offset: const Offset(0, 4),
              )],
            ),
            child: Column(
              children: [
                // Pets
                _buildConfirmationItem(
                  icon: Icons.pets_rounded,
                  label: 'Pets',
                  value: selectedPets.map((p) => '${p.emoji} ${p.name}').join(', '),
                ),
                _buildDivider(),
                // Date
                _buildConfirmationItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: _selectedDate != null
                      ? '${_getDayName(_selectedDate!.weekday)}, ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Not selected',
                ),
                _buildDivider(),
                // Time
                _buildConfirmationItem(
                  icon: Icons.access_time_rounded,
                  label: 'Time',
                  value: _selectedTime ?? 'Not selected',
                ),
                _buildDivider(),
                // Service
                _buildConfirmationItem(
                  icon: _selectedType.icon,
                  label: 'Service',
                  value: _selectedType.name,
                ),
                _buildDivider(),
                // Duration
                _buildConfirmationItem(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: '${_selectedType.durationMinutes} minutes',
                ),
                _buildDivider(),
                // Price
                _buildConfirmationItem(
                  icon: Icons.payments_rounded,
                  label: 'Total',
                  value: 'PKR ${_formatNumber(totalPrice)}',
                  isPrimary: true,
                  subValue: selectedPets.length > 1 
                      ? '${_selectedType.formattedPrice} × ${selectedPets.length} pets'
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Policy Notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.info.withAlpha(30)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_rounded, color: AppColors.info, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking Policy',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoal,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Payment will be collected at the clinic. Free cancellation up to 24 hours before the appointment.',
                        style: TextStyle(
                          color: AppColors.slate,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationItem({
    required IconData icon,
    required String label,
    required String value,
    bool isPrimary = false,
    String? subValue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPrimary 
                  ? AppColors.accent.withAlpha(20) 
                  : AppColors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, 
                color: isPrimary ? AppColors.accent : AppColors.primary, 
                size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.slate,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isPrimary ? 20 : 16,
                    color: isPrimary ? AppColors.accent : AppColors.charcoal,
                  ),
                ),
                if (subValue != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subValue,
                    style: TextStyle(
                      color: AppColors.slate,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: AppColors.borderLight, indent: 20, endIndent: 20);
  }

  // ============ NAVIGATION BAR ============
  Widget _buildNavigationBar() {
  final canProceed = _currentStep == 0
      ? _selectedPetIds.isNotEmpty
      : _currentStep == 1
          ? _selectedDate != null
          : _currentStep == 2
              ? _selectedTime != null
              : true;

  return Container(
    padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(
        color: Colors.black.withAlpha(8),
        blurRadius: 20,
        offset: const Offset(0, -4),
      )],
    ),
    child: Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: AppColors.slate,
                side: BorderSide(color: AppColors.borderLight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: _currentStep == 0 ? 1 : 2,
          child: canProceed
              // Active state - coral gradient button
              ? Container(
                  decoration: AppGradients.coralButtonDecoration(radius: AppSpacing.radiusMd),
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : (_currentStep < 3 ? _nextStep : _confirmBooking),
                    icon: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Icon(
                            _currentStep < 3 
                                ? Icons.arrow_forward_rounded 
                                : Icons.check_rounded,
                            size: 20,
                          ),
                    label: Text(
                      _currentStep < 3 ? 'Continue' : 'Confirm Booking',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                  ),
                )
              // Inactive state - professional outline style with muted gradient
              : Container(
                  decoration: BoxDecoration(
                    color: AppColors.cloud,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.borderLight,
                      width: 1.5,
                    ),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: null,
                    icon: Icon(
                      _currentStep < 3 
                          ? Icons.arrow_forward_rounded 
                          : Icons.check_rounded,
                      size: 20,
                      color: AppColors.slate.withAlpha(120),
                    ),
                    label: Text(
                      _currentStep < 3 ? 'Continue' : 'Confirm Booking',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.slate.withAlpha(150),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: AppColors.slate.withAlpha(120),
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    ),
  );
}

  // ============ SHARED COMPONENTS ============
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: AppGradients.primaryCta,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.slate,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: AppColors.slate.withAlpha(150)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.slate,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPetsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.warning.withAlpha(40)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.pets_rounded, size: 40, color: AppColors.warning),
          ),
          const SizedBox(height: 20),
          Text(
            'No Pets Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please add a pet to your profile before booking an appointment.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.slate,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Loading...',
            style: TextStyle(color: AppColors.slate),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSlots() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  // ============ HELPERS ============
  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
