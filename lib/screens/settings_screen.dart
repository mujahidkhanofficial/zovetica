import 'package:flutter/material.dart';
import 'package:zovetica/screens/auth_screen.dart';
import 'package:zovetica/services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import '../utils/app_notifications.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService().signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppNotifications.showError(context, 'Failed to logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
              _buildSection(
                context,
                title: 'Account',
                children: [
                  _buildSettingsTile(
                    context, 
                    icon: Icons.person_outline, 
                    title: 'Edit Profile', 
                    subtitle: 'Manage name, photo, and bio',
                    onTap: () => AppNotifications.showInfo(context, 'Edit Profile coming soon'),
                  ),
                  _buildSettingsTile(
                    context, 
                    icon: Icons.notifications_outlined, 
                    title: 'Notifications', 
                    subtitle: 'Email and push preferences',
                    onTap: () => AppNotifications.showInfo(context, 'Notification settings coming soon'),
                  ),
                  _buildSettingsTile(
                    context, 
                    icon: Icons.lock_outline, 
                    title: 'Privacy & Security', 
                    onTap: () => AppNotifications.showInfo(context, 'Privacy settings coming soon'),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              _buildSection(
                context,
                title: 'Support',
                children: [
                  _buildSettingsTile(
                    context, 
                    icon: Icons.help_outline, 
                    title: 'Help & Support', 
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    context, 
                    icon: Icons.info_outline, 
                    title: 'About Zovetica', 
                    trailing: const Text('v1.0.0', style: TextStyle(color: AppColors.slate, fontSize: 13)),
                    onTap: () {},
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Logout Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: [
                     BoxShadow(
                      color: Colors.black.withAlpha(10), // Alpha 10 ~= 0.04 opacity
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: () => _logout(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    foregroundColor: AppColors.error,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded, color: AppColors.error),
                      const SizedBox(width: 8),
                      const Text(
                        'Log Out',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ), // Padding
          ), // SingleChildScrollView
        ), // SafeArea
    ); // Scaffold
  }

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(height: 1, color: AppColors.borderLight.withAlpha(128), indent: 56),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon, 
    required String title, 
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(25), // ~0.1 opacity
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: AppColors.charcoal, // Safe fallback or direct color
        ),
      ),
      subtitle: subtitle != null ? Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.slate,
        ),
      ) : null,
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: AppColors.slate.withAlpha(128), size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
    );
  }
}

