import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zovetica/screens/auth_screen.dart';
import 'package:zovetica/services/auth_service.dart';
import 'package:zovetica/services/supabase_service.dart';
import '../data/local/database.dart';
import '../data/repositories/user_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import '../utils/app_notifications.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final UserRepository _userRepo = UserRepository.instance;
  
  String _userName = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = _authService.currentUser;
    if (user != null) {
      final localUser = await _userRepo.getUser(user.id);
      if (mounted && localUser != null) {
        setState(() => _userName = localUser.name ?? '');
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService().signOut();
    } catch (e) {
      debugPrint('Server logout failed (offline?): $e');
    } finally {
      if (!context.mounted) return;
      
      try {
        await AppDatabase.instance.clearAllData();
      } catch (e) {
        debugPrint('Error clearing local data: $e');
      }

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  // ============================================
  // EDIT PROFILE - Change Name
  // ============================================
  void _showEditNameDialog() {
    final nameController = TextEditingController(text: _userName);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Edit Name', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.charcoal)),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: AppColors.charcoal, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: const TextStyle(color: AppColors.slate),
                  hintText: 'Enter your name',
                  hintStyle: TextStyle(color: AppColors.slate.withOpacity(0.7)),
                  filled: true,
                  fillColor: AppColors.cloud,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    final newName = nameController.text.trim();
                    if (newName.isEmpty) return;
                    
                    setModalState(() => isSaving = true);
                    
                    try {
                      final userId = _authService.currentUser?.id;
                      if (userId != null) {
                        // Update Supabase
                        await SupabaseService.client
                            .from('users')
                            .update({'name': newName})
                            .eq('id', userId);
                        
                        // Update local cache
                        await _userRepo.getCurrentUser(forceRefresh: true);
                        
                        if (mounted) {
                          setState(() => _userName = newName);
                          Navigator.pop(context);
                          AppNotifications.showSuccess(context, 'Name updated successfully');
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppNotifications.showError(context, 'Failed to update name');
                      }
                    } finally {
                      if (context.mounted) setModalState(() => isSaving = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // PRIVACY & SECURITY - Change Password
  // ============================================
  void _showPrivacySecuritySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('Privacy & Security', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.charcoal)),
            const SizedBox(height: 24),
            _buildOptionTile(
              icon: Icons.lock_outline,
              title: 'Change Password',
              subtitle: 'Update your password',
              onTap: () {
                Navigator.pop(context);
                _showChangePasswordDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();
    bool isSaving = false;
    bool showCurrentPassword = false;
    bool showNewPassword = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, 
                  height: 4, 
                  decoration: BoxDecoration(
                    color: Colors.grey[300], 
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_outline, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold, 
                            color: AppColors.charcoal,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Enter your current password to continue',
                          style: TextStyle(fontSize: 13, color: AppColors.slate),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 28),
              
              // Current Password
              Text(
                'Current Password',
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w600, 
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: currentPasswordController,
                obscureText: !showCurrentPassword,
                style: const TextStyle(color: AppColors.charcoal, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Enter current password',
                  hintStyle: TextStyle(color: AppColors.slate.withOpacity(0.7)),
                  filled: true,
                  fillColor: AppColors.cloud,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), 
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.key_outlined, color: AppColors.slate),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showCurrentPassword ? Icons.visibility_off : Icons.visibility, 
                      color: AppColors.slate,
                    ),
                    onPressed: () => setModalState(() => showCurrentPassword = !showCurrentPassword),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // New Password
              Text(
                'New Password',
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w600, 
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: newPasswordController,
                obscureText: !showNewPassword,
                style: const TextStyle(color: AppColors.charcoal, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Enter new password',
                  hintStyle: TextStyle(color: AppColors.slate.withOpacity(0.7)),
                  filled: true,
                  fillColor: AppColors.cloud,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), 
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showNewPassword ? Icons.visibility_off : Icons.visibility, 
                      color: AppColors.slate,
                    ),
                    onPressed: () => setModalState(() => showNewPassword = !showNewPassword),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Confirm Password
              Text(
                'Confirm New Password',
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w600, 
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                obscureText: !showNewPassword,
                style: const TextStyle(color: AppColors.charcoal, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Confirm new password',
                  hintStyle: TextStyle(color: AppColors.slate.withOpacity(0.7)),
                  filled: true,
                  fillColor: AppColors.cloud,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), 
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                ),
              ),
              
              const SizedBox(height: 28),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    debugPrint('🔐 Update Password button pressed!');
                    
                    final currentPassword = currentPasswordController.text.trim();
                    final newPassword = newPasswordController.text.trim();
                    final confirm = confirmController.text.trim();
                    
                    debugPrint('Current: ${currentPassword.isNotEmpty}, New: ${newPassword.isNotEmpty}, Confirm: ${confirm.isNotEmpty}');
                    
                    // Validation
                    if (currentPassword.isEmpty) {
                      debugPrint('❌ Validation failed: current password empty');
                      AppNotifications.showError(context, 'Please enter your current password');
                      return;
                    }
                    if (newPassword.isEmpty) {
                      AppNotifications.showError(context, 'Please enter a new password');
                      return;
                    }
                    if (newPassword.length < 6) {
                      AppNotifications.showError(context, 'New password must be at least 6 characters');
                      return;
                    }
                    if (newPassword == currentPassword) {
                      AppNotifications.showError(context, 'New password must be different from current');
                      return;
                    }
                    if (newPassword != confirm) {
                      AppNotifications.showError(context, 'New passwords do not match');
                      return;
                    }
                    
                    setModalState(() => isSaving = true);
                    
                    try {
                      // Step 1: Verify current password by re-authenticating
                      final user = _authService.currentUser;
                      if (user?.email == null) {
                        throw Exception('User session expired. Please login again.');
                      }
                      
                      // Re-authenticate to verify current password
                      final authResponse = await SupabaseService.client.auth.signInWithPassword(
                        email: user!.email!,
                        password: currentPassword,
                      );
                      
                      if (authResponse.user == null) {
                        throw AuthException('Current password is incorrect');
                      }
                      
                      // Step 2: Update password
                      final updateResponse = await SupabaseService.client.auth.updateUser(
                        UserAttributes(password: newPassword),
                      );
                      
                      if (updateResponse.user == null) {
                        throw Exception('Failed to update password. Please try again.');
                      }
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        AppNotifications.showSuccess(context, 'Password updated successfully! 🔐');
                      }
                    } on AuthException catch (e) {
                      if (context.mounted) {
                        String errorMsg;
                        if (e.message.toLowerCase().contains('invalid') || 
                            e.message.toLowerCase().contains('credentials')) {
                          errorMsg = 'Current password is incorrect';
                        } else if (e.message.toLowerCase().contains('weak')) {
                          errorMsg = 'Password is too weak. Use a stronger password';
                        } else if (e.message.toLowerCase().contains('same')) {
                          errorMsg = 'New password cannot be the same as old password';
                        } else {
                          errorMsg = e.message;
                        }
                        AppNotifications.showError(context, errorMsg);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppNotifications.showError(context, 'Something went wrong. Please try again.');
                        debugPrint('Password change error: $e');
                      }
                    } finally {
                      if (context.mounted) setModalState(() => isSaving = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Update Password', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // ACCOUNT DELETION
  // ============================================
  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded, 
                    color: AppColors.error, 
                    size: 40,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'Delete Account?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Description
                const Text(
                  'This action cannot be undone. All your data, pets, appointments, and messages will be permanently deleted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.slate,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Password Field
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.charcoal, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: const TextStyle(color: AppColors.slate),
                    hintText: 'Enter your password to confirm',
                    hintStyle: TextStyle(color: AppColors.slate.withOpacity(0.7)),
                    filled: true,
                    fillColor: AppColors.cloud,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), 
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.error),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isDeleting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.charcoal,
                          side: const BorderSide(color: AppColors.borderLight),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Delete Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isDeleting ? null : () async {
                          final password = passwordController.text.trim();
                          if (password.isEmpty) {
                            AppNotifications.showError(context, 'Please enter your password');
                            return;
                          }
                          
                          setDialogState(() => isDeleting = true);
                          
                          try {
                            // Re-authenticate with password
                            final user = _authService.currentUser;
                            if (user?.email == null) throw Exception('User not found');
                            
                            await SupabaseService.client.auth.signInWithPassword(
                              email: user!.email!,
                              password: password,
                            );
                            
                            // Delete user data from tables
                            final userId = user.id;
                            
                            // Clear local database first
                            await AppDatabase.instance.clearAllData();
                            
                            // Delete from Supabase tables
                            await SupabaseService.client.from('notifications').delete().eq('user_id', userId);
                            await SupabaseService.client.from('pets').delete().eq('owner_id', userId);
                            await SupabaseService.client.from('posts').delete().eq('user_id', userId);
                            
                            // Sign out
                            await SupabaseService.client.auth.signOut();
                            
                            if (context.mounted) {
                              Navigator.pop(context);
                              _showAccountDeletedSuccess();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setDialogState(() => isDeleting = false);
                              final errorMsg = e.toString().toLowerCase().contains('invalid')
                                  ? 'Incorrect password'
                                  : 'Something went wrong. Please try again.';
                              AppNotifications.showError(context, errorMsg);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isDeleting
                            ? const SizedBox(
                                height: 18, 
                                width: 18, 
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, 
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Delete',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAccountDeletedSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppGradients.primaryCta,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Account Deleted',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.charcoal),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your account has been successfully deleted. We\'re sorry to see you go!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.slate, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.charcoal)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.slate)) : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.slate, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppGradients.primaryDiagonal)),
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
                      title: 'Edit Name', 
                      subtitle: _userName.isNotEmpty ? _userName : 'Tap to set your name',
                      onTap: _showEditNameDialog,
                    ),
                    _buildSettingsTile(
                      context, 
                      icon: Icons.lock_outline, 
                      title: 'Privacy & Security', 
                      subtitle: 'Password and security settings',
                      onTap: _showPrivacySecuritySheet,
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
                      onTap: () => AppNotifications.showInfo(context, 'Contact us at support@zovetica.com'),
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
                
                const SizedBox(height: AppSpacing.lg),
                
                // Danger Zone
                _buildSection(
                  context,
                  title: 'Danger Zone',
                  children: [
                    _buildSettingsTile(
                      context, 
                      icon: Icons.delete_forever_outlined, 
                      title: 'Delete Account', 
                      subtitle: 'Permanently delete your account',
                      onTap: _showDeleteAccountDialog,
                      isDestructive: true,
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
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: TextButton(
                    onPressed: () => _logout(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                      foregroundColor: AppColors.error,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Log Out', style: TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: title == 'Danger Zone' ? AppColors.error : AppColors.slate,
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
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 2))],
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
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.primary;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDestructive ? AppColors.error : AppColors.charcoal),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.slate)) : null,
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: AppColors.slate.withAlpha(128), size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
    );
  }
}
