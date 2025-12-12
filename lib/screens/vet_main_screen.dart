import 'package:flutter/material.dart';
import 'package:zovetica/screens/doctor_dashboard_screen.dart';
import 'package:zovetica/screens/simple_chat_list_screen.dart';
import 'package:zovetica/screens/community_screen.dart';
import 'package:zovetica/screens/notification_screen.dart';
import 'package:zovetica/screens/profile_screen.dart';
import '../theme/app_colors.dart';

class VetMainScreen extends StatefulWidget {
  const VetMainScreen({super.key});

  @override
  State<VetMainScreen> createState() => _VetMainScreenState();
}

class _VetMainScreenState extends State<VetMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DoctorDashboardScreen(),
    const SimpleChatListScreen(),
    const CommunityScreen(),
    const NotificationScreen(),
    const ProfileScreen(),
  ];

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
                _buildNavItem(Icons.chat_bubble_rounded, Icons.chat_bubble_outline, 'Messages'),
                _buildNavItem(Icons.people_rounded, Icons.people_outline, 'Community'),
                _buildNavItem(Icons.notifications_rounded, Icons.notifications_none_rounded, 'Alerts'),
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
}
