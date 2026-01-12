import 'package:flutter/material.dart';
import 'package:zovetica/services/admin_service.dart';
import 'package:zovetica/services/auth_service.dart';
import 'package:zovetica/screens/auth/login_form.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_shadows.dart';
import 'admin_users_screen.dart';
import 'admin_posts_screen.dart';
import 'admin_doctors_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _adminService.getDashboardStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  void _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginForm()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.primaryDiagonal,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsGrid(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildQuickActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int crossAxisCount = width > 600 ? 4 : 2;
        // Calculate aspect ratio to prevent overflow
        // Box Height ~ 100-110 for Row layout. Width = (Screen Width - Spacing) / 2
        final double itemWidth = (width - 16) / 2;
        final double itemHeight = 110; 
        final double childAspectRatio = itemWidth / itemHeight;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard(
              'Total Users',
              _stats?['total_users']?.toString() ?? '0',
              Icons.group_rounded,
              AppColors.primary,
            ),
            _buildStatCard(
              'Doctors',
              _stats?['total_doctors']?.toString() ?? '0',
              Icons.medical_services_rounded,
              AppColors.secondary,
            ),
            _buildStatCard(
              'Appointments',
              _stats?['total_appointments']?.toString() ?? '0',
              Icons.calendar_today_rounded,
              AppColors.accent,
            ),
            _buildStatCard(
              'Posts',
              _stats?['total_posts']?.toString() ?? '0',
              Icons.article_rounded,
              AppColors.lavender,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoal,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.slate,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final pendingCount = _stats?['pending_doctors'] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Management',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionTile(
          'User Management',
          'Manage doctors, pet owners, and bans',
          Icons.manage_accounts_rounded,
          AppColors.primary,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          'Doctor Verification',
          'Approve or reject doctor applications',
          Icons.verified_user_rounded,
          AppColors.secondary,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDoctorsScreen())),
          badgeCount: pendingCount,
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          'Content Moderation',
          'Review flagged posts and comments',
          Icons.shield_rounded,
          AppColors.accent,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPostsScreen())),
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          'Broadcast Notification',
          'Send alerts to all users',
          Icons.notifications_active_rounded,
          AppColors.golden,
          _showBroadcastDialog,
        ),
      ],
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap, {int badgeCount = 0}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.slate.withAlpha(128)),
          ],
        ),
      ),
    );
  }

  void _showBroadcastDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
         title: Row(
           children: [
             Icon(Icons.notifications_active_rounded, color: AppColors.golden),
             const SizedBox(width: 8),
             const Text("Broadcast Alert"),
           ],
         ),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             TextField(
               controller: titleController,
               decoration: const InputDecoration(
                  labelText: "Title", 
                  border: OutlineInputBorder(),
                  hintText: "Important Update"
               ),
             ),
             const SizedBox(height: 12),
             TextField(
               controller: messageController,
               decoration: const InputDecoration(
                  labelText: "Message", 
                  border: OutlineInputBorder(),
                  hintText: "System maintenance at 2 AM..."
               ),
               maxLines: 3,
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(ctx),
             child: const Text("Cancel"),
           ),
           ElevatedButton(
             style: ElevatedButton.styleFrom(
               backgroundColor: AppColors.primary,
               foregroundColor: Colors.white,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
             ),
             onPressed: () async {
                if (titleController.text.isNotEmpty && messageController.text.isNotEmpty) {
                  // TODO: Implement actual broadcast logic in AdminService
                   Navigator.pop(ctx);
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text("Broadcast sent successfully!"))
                   );
                }
             }, 
             child: const Text("Send"),
           ),
         ],
      ),
    );
  }
}
