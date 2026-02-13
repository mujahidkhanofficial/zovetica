import 'package:flutter/material.dart';
import 'package:pets_and_vets/screens/doctor_dashboard_screen.dart';
import 'package:pets_and_vets/screens/simple_chat_list_screen.dart';
import 'package:pets_and_vets/screens/community_screen.dart';
import 'package:pets_and_vets/screens/notification_screen.dart';
import 'package:pets_and_vets/screens/profile_screen.dart';
import '../theme/app_colors.dart';
import '../services/notification_service.dart';
import '../services/global_chat_manager.dart';
import '../services/auth_service.dart';
import '../widgets/badge_widget.dart';

class VetMainScreen extends StatefulWidget {
  const VetMainScreen({super.key});

  @override
  State<VetMainScreen> createState() => _VetMainScreenState();
}

class _VetMainScreenState extends State<VetMainScreen> {
  int _selectedIndex = 0;
  final _authService = AuthService();

  final List<Widget> _screens = [
    const DoctorDashboardScreen(),
    const SimpleChatListScreen(),
    const CommunityScreen(),
    const NotificationScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeGlobalChat();
  }

  Future<void> _initializeGlobalChat() async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        await GlobalChatManager.instance.initialize(userId);
        debugPrint('✅ GlobalChatManager initialized (Doctor)');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to initialize GlobalChatManager: $e');
    }
  }

  @override
  void dispose() {
    GlobalChatManager.instance.dispose();
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.borderLight, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.slate,
              backgroundColor: Colors.transparent,
              elevation: 0,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              items: [
                _buildNavItem(Icons.dashboard_rounded, Icons.dashboard_outlined, 'Dashboard'),
                _buildNavItemWithBadge(
                  Icons.chat_bubble_rounded,
                  Icons.chat_bubble_outline,
                  'Messages',
                  NotificationService().getUnreadCountStream(),
                ),
                _buildNavItem(Icons.people_rounded, Icons.people_outline, 'Community'),
                _buildNavItemWithBadge(
                  Icons.notifications_rounded,
                  Icons.notifications_none_rounded,
                  'Alerts',
                  NotificationService().getUnreadCountStream(),
                ),
                _buildNavItem(Icons.person_rounded, Icons.person_outline, 'Profile'),
              ],
            ),
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

  BottomNavigationBarItem _buildNavItemWithBadge(
    IconData active,
    IconData inactive,
    String label,
    Stream<int> badgeCountStream,
  ) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: StreamBuilder<int>(
          stream: badgeCountStream,
          initialData: 0,
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return BadgeWidget(
              count: count,
              child: Icon(inactive, size: 24),
            );
          },
        ),
      ),
      activeIcon: Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: StreamBuilder<int>(
            stream: badgeCountStream,
            initialData: 0,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return BadgeWidget(
                count: count,
                child: Icon(active, size: 24),
              );
            },
          ),
        ),
      ),
      label: label,
    );
  }
}
