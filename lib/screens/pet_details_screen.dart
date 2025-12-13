import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import '../data/local/database.dart';
import '../widgets/pet_button.dart';
import '../widgets/pet_input.dart';
import '../widgets/confirmation_dialog.dart';
import '../models/app_models.dart';
import '../widgets/widgets.dart';
import '../services/pet_service.dart';
import '../data/repositories/pet_repository.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import '../theme/app_shadows.dart';
import '../utils/app_notifications.dart';
import 'add_pet_screen.dart';

class PetDetailsScreen extends StatefulWidget {
  final Pet pet;

  const PetDetailsScreen({super.key, required this.pet});

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  late Pet _pet;
  final PetService _petService = PetService();
  List<PetHealthEvent> _healthEvents = [];
  bool _loadingEvents = true;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
    _fetchHealthEvents();
  }

  Future<void> _fetchHealthEvents() async {
    try {
      final events = await _petService.getHealthEvents(_pet.id);
      if (mounted) {
        setState(() {
          _healthEvents = events;
          _loadingEvents = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching events: $e');
      if (mounted) setState(() => _loadingEvents = false);
    }
  }

  Future<void> _deletePet() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pet?'),
        content: Text('Are you sure you want to delete ${_pet.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await PetRepository.instance.deletePet(_pet.id);
        if (!mounted) return;
        AppNotifications.showSuccess(context, '${_pet.name} has been deleted');
        Navigator.pop(context, true); // Return to list
      } catch (e) {
        debugPrint('Error deleting pet: $e');
        if (mounted) AppNotifications.showError(context, 'Failed to delete pet');
      }
    }
  }

  Future<void> _editPet() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPetScreen(petToEdit: _pet),
      ),
    );

    if (updated == true) {
      // Refresh pet details in real-time
      await _refreshPetDetails();
    }
  }

  Future<void> _refreshPetDetails() async {
    try {
      // Fetch the updated pet from the database
      final updatedPet = await _petService.getPetById(_pet.id);
      if (updatedPet != null && mounted) {
        setState(() {
          _pet = updatedPet;
        });
        debugPrint('Pet details refreshed: ${_pet.name}');
      }
    } catch (e) {
      debugPrint('Error refreshing pet details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _pet.ownerId == SupabaseService.currentUser?.id;
    // Mock Health Timeline Data replaced with _healthEvents

    return Scaffold(
      backgroundColor: AppColors.cloud,
      body: AppRefreshIndicator(
        onRefresh: _fetchHealthEvents,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          // HEADER
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (isOwner) ...[
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  onPressed: _editPet,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  onPressed: _deletePet,
                ),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: _pet.name,
                    child: _pet.imageUrl.isNotEmpty
                        ? CachedImage(
                            imageUrl: _pet.imageUrl,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              gradient: AppGradients.primaryDiagonal,
                            ),
                            child: Center(
                              child: Material(
                                color: Colors.transparent,
                                child: Text(
                                  _pet.emoji,
                                  style: const TextStyle(fontSize: 80),
                                ),
                              ),
                            ),
                          ),
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(179),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pet.name,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildHeaderChip(_pet.type, _getIconForType(_pet.type)),
                                const SizedBox(width: 8),
                                _buildHeaderChip(_pet.age, Icons.cake_outlined),
                                const SizedBox(width: 8),
                                _buildHeaderChip(_pet.gender, _getIconForGender(_pet.gender)),
                              ],
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatsGrid(),
                  const SizedBox(height: AppSpacing.xl),
                  
                  // DAILY CARE SECTION
                  _buildCareTasksSection(),
                  
                  const SizedBox(height: 32),

                  // HEALTH TIMELINE SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Health Timeline',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoal,
                        ),
                      ),
                      if (isOwner)
                        IconButton(
                          onPressed: () => _showHealthEventDialog(),
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add, color: AppColors.primary, size: 20),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  StreamBuilder<List<LocalHealthEvent>>(
                    stream: AppDatabase.instance.watchHealthEvents(_pet.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final events = snapshot.data!;
                      
                      if (events.isEmpty) {
                        return _buildEmptyTimeline();
                      }
                      
                      return Column(
                        children: events.map((event) => _buildTimelineItem(event)).toList(),
                      );
                    },
                  ),
                    
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildHeaderChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label.isEmpty ? 'N/A' : label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Weight', _pet.weight.isEmpty ? 'N/A' : '${_pet.weight} kg', Icons.monitor_weight_rounded)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Height', _pet.height.isEmpty ? 'N/A' : '${_pet.height} cm', Icons.height_rounded)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.slate, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(LocalHealthEvent event) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Timeline Line & Dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 20, // Top line
                  color: AppColors.borderLight,
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getEventColor(event.type),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _getEventColor(event.type).withAlpha(102),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.borderLight,
                  ),
                ),
              ],
            ),
          ),
          // Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                boxShadow: AppShadows.card,
              ),
              child: ListTile(
                onTap: () => _showHealthEventDialog(eventToEdit: event),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  event.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(event.date),
                      style: TextStyle(color: AppColors.slate, fontSize: 13),
                    ),
                    if (event.notes != null && event.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          event.notes!,
                          style: TextStyle(color: AppColors.slate.withAlpha(179), fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getEventColor(event.type).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getEventColor(event.type),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTimeline() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(Icons.monitor_heart_outlined, size: 48, color: AppColors.slate.withAlpha(77)),
          const SizedBox(height: 12),
          Text(
            'No health records yet',
            style: TextStyle(color: AppColors.slate, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'Vaccine':
        return AppColors.secondary;
      case 'Surgery':
        return AppColors.error;
      case 'Checkup':
        return AppColors.primary;
      case 'Dental':
        return Colors.orange;
      default:
        return AppColors.slate;
    }
  }
  
  IconData _getIconForType(String type) {
    switch (type) {
      case 'Dog': return Icons.pets;
      case 'Cat': return Icons.cruelty_free; // Closest to cat
      case 'Bird': return Icons.flutter_dash; 
      case 'Hamster': 
      case 'Rabbit': return Icons.pest_control_rodent;
      default: return Icons.pets;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'Vaccine':
        return Icons.medical_services;
      case 'Surgery':
        return Icons.local_hospital;
      case 'Checkup':
        return Icons.monitor_heart;
      case 'Dental':
        return Icons.cleaning_services; // Or similar
      default:
        return Icons.event_note;
    }
  }

  IconData _getIconForGender(String gender) {
     if (gender == 'Male') return Icons.male;
     if (gender == 'Female') return Icons.female;
     return Icons.help_outline;
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildCareTasksSection() {
    return StreamBuilder<List<LocalCareTask>>(
       stream: AppDatabase.instance.watchCareTasks(_pet.id),
       builder: (context, snapshot) {
         final tasks = snapshot.data ?? [];
         
         return Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(
                   'Daily Care',
                   style: TextStyle(
                     fontSize: 20,
                     fontWeight: FontWeight.bold,
                     color: AppColors.charcoal,
                   ),
                 ),
                 IconButton(
                   onPressed: _showAddCareTaskDialog,
                   icon: Container(
                     padding: const EdgeInsets.all(4),
                     decoration: BoxDecoration(
                       color: AppColors.secondary.withAlpha(26),
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: const Icon(Icons.add, color: AppColors.secondary, size: 20),
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 12),
             if (tasks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 40, color: AppColors.slate.withAlpha(77)),
                      const SizedBox(height: 8),
                      Text('No care tasks set', style: TextStyle(color: AppColors.slate)),
                    ],
                  ),
                )
             else
               ...tasks.map((task) {
                  final now = DateTime.now();
                  final isCompletedToday = task.lastCompletedAt != null && 
                      task.lastCompletedAt!.year == now.year &&
                      task.lastCompletedAt!.month == now.month &&
                      task.lastCompletedAt!.day == now.day;

                  return Dismissible(
                    key: ValueKey(task.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                       await AppDatabase.instance.deleteCareTask(task.id);
                       if (mounted) AppNotifications.showSuccess(context, 'Task deleted');
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCompletedToday ? AppColors.secondary.withAlpha(77) : AppColors.borderLight,
                        ),
                        boxShadow: AppShadows.card,
                      ),
                      child: ListTile(
                        onTap: () async {
                           final newState = !isCompletedToday;
                           await AppDatabase.instance.toggleCareTask(
                             task.id, 
                             newState ? DateTime.now() : null
                           );
                           if (newState && mounted) {
                              // Simple haptic or snackbar feedback
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Good job! ${task.title} completed.'),
                                  backgroundColor: AppColors.secondary,
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                           }
                        },
                        leading: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCompletedToday ? AppColors.secondary : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCompletedToday ? AppColors.secondary : AppColors.slate.withAlpha(100),
                              width: 2,
                            ),
                          ),
                          child: isCompletedToday 
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: isCompletedToday ? TextDecoration.lineThrough : null,
                            color: isCompletedToday ? AppColors.slate : AppColors.charcoal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: task.frequency == 'daily' 
                           ? const Icon(Icons.repeat, size: 16, color: AppColors.slate)
                           : null,
                      ),
                    ),
                  );
               }).toList(),
           ],
         );
       }
    );
  }

  Future<void> _showAddCareTaskDialog() async {
     final controller = TextEditingController();
     
     await showModalBottomSheet(
       context: context,
       isScrollControlled: true,
       backgroundColor: Colors.transparent,
       builder: (context) => Container(
          padding: EdgeInsets.only(
             bottom: MediaQuery.of(context).viewInsets.bottom + 24,
             top: 24,
             left: 24,
             right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                 'New Daily Task',
                 style: TextStyle(
                   fontSize: 20, 
                   fontWeight: FontWeight.bold,
                   color: AppColors.charcoal,
                 ),
               ),
               const SizedBox(height: 16),
               PetInput(
                 controller: controller,
                 labelText: 'Task Name',
                 hintText: 'e.g. Morning Walk, Medicine',
                 autoFocus: true,
               ),
               const SizedBox(height: 24),
               SizedBox(
                 width: double.infinity,
                 child: PetButton(
                   text: 'Add Task',
                   onPressed: () async {
                      if (controller.text.trim().isNotEmpty) {
                         await AppDatabase.instance.addCareTask(
                           LocalCareTasksCompanion(
                             petId: Value(_pet.id),
                             title: Value(controller.text.trim()),
                             createdAt: Value(DateTime.now()),
                           ),
                         );
                         if (mounted) Navigator.pop(context);
                      }
                   },
                 ),
               ),
            ],
          ),
       ),
     );
  }

  Future<void> _showHealthEventDialog({LocalHealthEvent? eventToEdit}) async {
    final isEditing = eventToEdit != null;
    final titleController = TextEditingController(text: eventToEdit?.title ?? '');
    final notesController = TextEditingController(text: eventToEdit?.notes ?? '');
    String selectedType = eventToEdit?.type ?? 'Checkup';
    DateTime selectedDate = eventToEdit?.date ?? DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    isEditing ? 'Edit Health Event' : 'Add Health Event',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoal,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: AppColors.slate),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Title Input
              PetInput(
                autoFocus: !isEditing,
                controller: titleController,
                labelText: 'Event Title',
                hintText: 'e.g. Annual Checkup',
                prefixIcon: Icons.title,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Date Picker
              _buildDatePicker(selectedDate, (date) => setState(() => selectedDate = date)),
              const SizedBox(height: 16),

              // Type Dropdown (Custom styled)
              _buildTypeDropdown(selectedType, (val) => setState(() => selectedType = val)),
              const SizedBox(height: 16),

              // Notes Input
              PetInput(
                controller: notesController,
                labelText: 'Notes (Optional)',
                hintText: 'Add any details...',
                prefixIcon: Icons.format_quote_rounded,
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 32),

              // Actions
              Row(
                children: [
                  if (isEditing)
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: PetButton(
                          text: 'Delete',
                          isOutlined: true,
                          borderColor: AppColors.error,
                          textColor: AppColors.error,
                          onPressed: () async {
                             final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (_) => ConfirmationDialog(
                                  title: 'Delete Event?',
                                  message: 'Are you sure you want to delete this event?',
                                  confirmText: 'Delete',
                                  isDestructive: true,
                                ),
                             );
                             
                             if (confirmed == true) {
                               await AppDatabase.instance.deleteHealthEvent(eventToEdit!.id);
                               if (mounted) {
                                 Navigator.pop(context); // Close modal
                               }
                             }
                          },
                        ),
                      ),
                    ),
                  
                  Expanded(
                    flex: 2,
                    child: PetButton(
                      text: isEditing ? 'Save Changes' : 'Add Event',
                      height: 50,
                      onPressed: () async {
                        if (titleController.text.isNotEmpty) {
                          if (isEditing) {
                            await AppDatabase.instance.updateHealthEvent(
                              eventToEdit!.id,
                              LocalHealthEventsCompanion(
                                title: Value(titleController.text),
                                date: Value(selectedDate),
                                type: Value(selectedType),
                                notes: Value(notesController.text),
                              ),
                            );
                          } else {
                            await AppDatabase.instance.addHealthEvent(
                              LocalHealthEventsCompanion(
                                petId: Value(_pet.id),
                                title: Value(titleController.text),
                                date: Value(selectedDate),
                                type: Value(selectedType),
                                notes: Value(notesController.text),
                                createdAt: Value(DateTime.now()),
                              ),
                            );
                          }
                          if (mounted) Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(DateTime date, Function(DateTime) onSelect) {
     return InkWell(
       onTap: () async {
         final picked = await showDatePicker(
           context: context,
           initialDate: date,
           firstDate: DateTime(2000),
           lastDate: DateTime(2100),
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
         if (picked != null) onSelect(picked);
       },
       borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
       child: Container(
         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
         decoration: BoxDecoration(
           color: AppColors.backgroundLight,
           borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
           border: Border.all(color: AppColors.borderLight),
         ),
         child: Row(
           children: [
             Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary),
             const SizedBox(width: 12),
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('Date', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                 const SizedBox(height: 2),
                 Text(
                   '${date.day}/${date.month}/${date.year}', 
                   style: TextStyle(color: AppColors.charcoal, fontSize: 16),
                 ),
               ],
             ),
           ],
         ),
       ),
     );
  }

  Widget _buildTypeDropdown(String current, Function(String) onChanged) {
    final types = ['Checkup', 'Vaccine', 'Surgery', 'Dental', 'Other'];
    return Container(
         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
         decoration: BoxDecoration(
           color: AppColors.backgroundLight,
           borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
           border: Border.all(color: AppColors.borderLight),
         ),
         child: DropdownButtonHideUnderline(
           child: DropdownButton<String>(
             dropdownColor: Colors.white,
             value: current,
             isExpanded: true,
             icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
             items: types.map((t) {
               return DropdownMenuItem(
                 value: t,
                 child: Row(
                   children: [
                     Icon(_getEventIcon(t), size: 20, color: _getEventColor(t)),
                     const SizedBox(width: 12),
                     Text(t, style: TextStyle(color: AppColors.charcoal)),
                   ],
                 ),
               );
             }).toList(),
             onChanged: (v) => onChanged(v!),
           ),
         ),
    );
  }
}
