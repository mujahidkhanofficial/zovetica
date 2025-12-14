import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zovetica/services/supabase_service.dart';
import 'package:zovetica/services/user_service.dart';
import 'package:zovetica/services/auth_service.dart';
import '../data/repositories/user_repository.dart';
import '../widgets/widgets.dart';
import 'package:zovetica/services/pet_service.dart';
import 'package:zovetica/services/notification_service.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import '../widgets/offline_banner.dart';
import 'emergency_screen.dart';
import 'find_doctor_screen.dart';
import 'appointment_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';
import 'pet_details_screen.dart';
import 'add_pet_screen.dart';
import 'simple_chat_list_screen.dart';
import 'notification_screen.dart';
import 'ai_chat_screen.dart';
import '../data/repositories/pet_repository.dart';
import 'package:drift/drift.dart' hide Column;
import '../data/local/database.dart';
import '../utils/app_notifications.dart';
import 'admin/admin_dashboard_screen.dart';

import 'package:zovetica/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zovetica/screens/auth_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isAdmin;
  
  const HomeScreen({super.key, this.isAdmin = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final PetService _petService = PetService();
  final NotificationService _notificationService = NotificationService();
  final PetRepository _petRepo = PetRepository.instance;
  final UserRepository _userRepo = UserRepository.instance;

  String _username = "";
  List<Pet> _pets = [];

  // Mock Daily Tasks for Dashboard
  final List<Map<String, dynamic>> _dailyTasks = [
    {'time': '08:00 AM', 'title': 'Morning Walk', 'completed': true, 'type': 'activity'},
    {'time': '02:00 PM', 'title': 'Vitamin Supplement', 'completed': false, 'type': 'medication'},
    {'time': '06:00 PM', 'title': 'Evening Playtime', 'completed': false, 'type': 'activity'},
  ];

  int _selectedIndex = 0;
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _fetchUser();
    _fetchPets();
    _setupUserSubscription(); // Added call here
    _screens.addAll([
      const SizedBox(), // Placeholder for Home
      const FindDoctorScreen(),
      const AppointmentScreen(),
      const SimpleChatListScreen(),
      const ProfileScreen(),
    ]);
  }

  Future<void> _fetchUser() async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        // Try local repo first for offline support
        final localUser = await _userRepo.getUser(userId);
        if (localUser != null) {
          if (mounted) {
            setState(() {
              _username = localUser.name ?? "Pet Parent";
            });
          }
        }
        
        // Sync API
        final userData = await _userService.getCurrentUser();
        if (userData != null && mounted) {
          setState(() {
            _username = userData['name'] ?? _username;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user: $e");
    }
  }

  Future<void> _fetchPets() async {
    try {
      // Local-first: load from cache first
      final localPets = await _petRepo.getMyPets();
      if (localPets.isNotEmpty) {
        setState(() {
          _pets = localPets.map(_petRepo.localPetToPet).toList();
        });
      } else {
        // Fallback to service if no cache
        final pets = await _petService.getPets();
        setState(() {
          _pets = pets;
        });
      }
    } catch (e) {
      debugPrint('Error fetching pets: $e');
    }
  }

  RealtimeChannel? _userSubscription;

  void _setupUserSubscription() {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    _userSubscription = SupabaseService.client
        .channel('public:users:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) async {
             // Keep the real-time kick feature as user mentioned it was working
            final newRecord = payload.newRecord;
            if (newRecord != null) {
              if (newRecord['is_banned'] == true || newRecord['banned_at'] != null) {
                // User was banned - force logout
                debugPrint("User banned in real-time. Logging out.");
                await _authService.signOut();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Account banned: ${newRecord['banned_reason'] ?? "Violation of terms"}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
                  );
                }
              } else {
                 // Update local username if changed
                 if (mounted && newRecord['name'] != null) {
                   setState(() {
                     _username = newRecord['name'];
                   });
                 }
              }
            }
          },
        )
        .subscribe();
  }


  @override
  void dispose() {
    if (_userSubscription != null) {
      SupabaseService.client.removeChannel(_userSubscription!);
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _selectedIndex == 0
            ? _buildHomeContent()
            : KeyedSubtree(
                key: ValueKey<int>(_selectedIndex),
                child: _screens[_selectedIndex],
              ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomeContent() {
    return Container(
      key: const ValueKey<int>(0),
      color: AppColors.cloud,
      child: AppRefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _fetchUser(),
            _fetchPets(),
          ]);
        },
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Immersive Header with gradient
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppGradients.primaryDiagonal,
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Greeting + Notification
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: TextStyle(
                                  color: Colors.white.withAlpha(217),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _username.isNotEmpty ? _username : "Pet Parent",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          // Notification Icon with Badge
                          StreamBuilder<int>(
                            stream: _notificationService.getUnreadCountStream(),
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 0;
                              return Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(51),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const NotificationScreen()),
                                        );
                                      },
                                    ),
                                  ),
                                  if (count > 0)
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                        child: Center(
                                          child: Text(
                                            count > 9 ? '9+' : count.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Pet Spotlight Card
                      _pets.isNotEmpty ? _buildPetSpotlight(_pets.first) : _buildEmptyPetSpotlight(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Main Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions Grid
                  _buildQuickActionsGrid(),
                  const SizedBox(height: AppSpacing.xl),

                  // Daily Care Timeline
                  _buildSectionHeader(
                    "Daily Care", 
                    Icons.schedule_rounded, 
                    action: "See all",
                    onAction: () {
                      if (_pets.isNotEmpty) {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => PetDetailsScreen(pet: _pets.first))
                        );
                      }
                    }
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDailyCareFeed(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Widget _buildSectionHeader(String title, IconData icon, {String? action, VoidCallback? onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.charcoal),
            ),
          ],
        ),
        if (action != null)
          TextButton(
            onPressed: onAction ?? () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              action,
              style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _buildPetSpotlight(Pet pet) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(51)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withAlpha(51),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(51),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.success.withAlpha(128)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text("Healthy", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${pet.name} is feeling great! 🐾",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  "Next checkup in 14 days",
                  style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 13),
                ),
              ],
            ),
          ),
          Hero(
            tag: pet.name,
            child: GestureDetector(
               onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PetDetailsScreen(pet: pet)));
               },
               child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: Colors.white.withAlpha(51),
                ),
                child: ClipOval(
                  child: pet.imageUrl.isNotEmpty
                      ? CachedImage(
                          imageUrl: pet.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : Center(child: Text(pet.emoji, style: const TextStyle(fontSize: 32))),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPetSpotlight() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: TextButton.icon(
          onPressed: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPetScreen()));
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Add your first pet", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    // Create list of action cards
    final List<Widget> actionCards = [
      _buildActionCard(
        "Emergency",
        Icons.warning_amber_rounded,
        AppGradients.coralCta,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen())),
      ),
      _buildActionCard(
        "Find Vet",
        Icons.medical_services_rounded,
        AppGradients.primaryCta,
        () => setState(() => _selectedIndex = 1),
      ),
      _buildActionCard(
        "Ask AI",
        Icons.auto_awesome_rounded,
        AppGradients.primaryDiagonal,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen())),
      ),
      _buildActionCard(
        "Community",
        Icons.people_alt_rounded,
        AppGradients.warmHeader,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityScreen())),
      ),
    ];

    // Add Admin Dashboard card if user is admin
    if (widget.isAdmin) {
      actionCards.add(
        _buildActionCard(
          "Admin",
          Icons.admin_panel_settings_rounded,
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: actionCards,
      );
    });
  }

  Widget _buildActionCard(String title, IconData icon, LinearGradient gradient, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withAlpha(77),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(icon, size: 80, color: Colors.white.withAlpha(51)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildDailyCareFeed() {
    if (_pets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(16),
           border: Border.all(color: AppColors.borderLight),
        ),
        child: const Center(
          child: Text("Add a pet to track daily care tasks", style: TextStyle(color: AppColors.slate)),
        ),
      );
    }

    // Showing tasks for the first pet (Spotlight Pet)
    final spotlightPet = _pets.first;

    return StreamBuilder<List<LocalCareTask>>(
      stream: AppDatabase.instance.watchCareTasks(spotlightPet.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
           return const Center(child: CircularProgressIndicator());
        }
        
        final tasks = snapshot.data!;

        if (tasks.isEmpty) {
           return Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                Icon(Icons.task_alt_rounded, size: 40, color: AppColors.slate.withAlpha(77)),
                const SizedBox(height: 8),
                Text('No tasks for ${spotlightPet.name} today', style: TextStyle(color: AppColors.slate)),
                TextButton(
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => PetDetailsScreen(pet: spotlightPet)));
                  },
                  child: const Text('Add Tasks'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: tasks.map((task) => _buildLocalTaskItem(task)).toList(),
        );
      },
    );
  }

  Widget _buildLocalTaskItem(LocalCareTask task) {
    final now = DateTime.now();
    final isCompletedToday = task.lastCompletedAt != null && 
        task.lastCompletedAt!.year == now.year &&
        task.lastCompletedAt!.month == now.month &&
        task.lastCompletedAt!.day == now.day;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
        border: isCompletedToday ? Border.all(color: AppColors.success.withAlpha(50)) : null,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isCompletedToday ? AppColors.success.withAlpha(26) : AppColors.primary.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.pets_rounded,
            color: isCompletedToday ? AppColors.success : AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isCompletedToday ? AppColors.slate : AppColors.charcoal,
            decoration: isCompletedToday ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(task.frequency, style: TextStyle(fontSize: 12, color: AppColors.slate)),
        trailing: Checkbox(
          value: isCompletedToday,
          activeColor: AppColors.success,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          onChanged: (val) async {
             await AppDatabase.instance.toggleCareTask(
               task.id, 
               (val == true) ? DateTime.now() : null
             );
             
             if (val == true && mounted) {
                 AppNotifications.showSuccess(context, '${task.title} completed!');
             }
          },
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE9ECEF), width: 1), // AppColors.borderLight
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70, // Enterprise grade height
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.slate,
            backgroundColor: Colors.white,
            elevation: 0,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              height: 1.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              height: 1.5,
            ),
            items: [
              _buildNavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
              _buildNavItem(Icons.search_rounded, Icons.search_outlined, 'Find Vet'),
              _buildNavItem(Icons.calendar_month_rounded, Icons.calendar_today_outlined, 'Bookings'),
              _buildNavItem(Icons.chat_bubble_rounded, Icons.chat_bubble_outline, 'Messages'),
              _buildNavItem(Icons.person_rounded, Icons.person_outline, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
  
  BottomNavigationBarItem _buildNavItem(IconData active, IconData inactive, String label) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Icon(inactive, size: 24),
      ),
      activeIcon: Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Icon(active, size: 24),
        ),
      ),
      label: label,
    );
  }
}
