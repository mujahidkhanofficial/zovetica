import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zovetica/screens/vet_main_screen.dart';
import 'package:zovetica/screens/admin/admin_dashboard_screen.dart';
import 'package:zovetica/screens/home_screen.dart';
import 'package:zovetica/services/auth_service.dart';
import 'package:zovetica/services/user_service.dart';
import '../../core/network/connectivity_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// Parse Supabase auth errors into user-friendly messages
  String _getAuthErrorMessage(AuthException e) {
    final message = e.message.toLowerCase();
    
    if (message.contains('invalid login credentials') || 
        message.contains('invalid password') ||
        message.contains('invalid email')) {
      return 'Invalid email or password. Please check your credentials.';
    }
    
    if (message.contains('email not confirmed') ||
        message.contains('confirm your email')) {
      return 'Please verify your email before logging in. Check your inbox for the confirmation link.';
    }
    
    if (message.contains('too many requests') ||
        message.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    
    if (message.contains('network') || message.contains('connection')) {
      return 'Connection error. Please check your internet and try again.';
    }
    
    return e.message;
  }

  /// Parse generic errors into user-friendly messages
  String _getGenericErrorMessage(dynamic e) {
    final message = e.toString().toLowerCase();
    
    // Network connectivity issues
    if (e is SocketException || 
        message.contains('socketexception') || 
        message.contains('failed host lookup') || 
        message.contains('no address associated') ||
        message.contains('clientexception') ||
        message.contains('connection refused') ||
        message.contains('network is unreachable')) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }
    
    if (message.contains('timeout') || message.contains('timed out')) {
      return 'Connection timed out. Please try again.';
    }
    
    if (message.contains('user data not found')) {
      return 'Account not found. Please sign up first.';
    }
    
    if (message.contains('login failed')) {
      return 'Login failed. Please check your credentials.';
    }
    
    return 'Something went wrong. Please try again later.';
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Clear previous error
    setState(() => _errorMessage = null);

    // Check connectivity
    final status = await ConnectivityService.instance.checkConnectivity();
    if (status == NetworkStatus.offline) {
      if (!mounted) return;
      setState(() => _errorMessage = 'No internet connection. Please turn on data or wifi.');
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password');
      return;
    }

    try {
      setState(() => _isLoading = true);

      debugPrint('🔐 LOGIN Step 1: Attempting authentication...');
      final response = await _authService.signIn(
        email: email,
        password: password,
      );
      debugPrint('✅ LOGIN Step 1: Auth SUCCESS - User ID: ${response.user?.id}');

      if (response.user == null) {
        debugPrint('❌ LOGIN Step 1: Auth returned null user');
        throw Exception('Login failed');
      }

      debugPrint('🔍 LOGIN Step 2: Fetching user data from public.users...');
      final userData = await _userService.getUserById(response.user!.id);
      debugPrint('✅ LOGIN Step 2: User data received: $userData');

      if (userData == null) {
        debugPrint('❌ LOGIN Step 2: No user data in public.users table');
        throw Exception('User data not found');
      }

      final role = userData['role'] ?? "pet_owner";
      debugPrint('✅ LOGIN Step 3: User role is: $role');

      if (!mounted) return;

      if (role == "doctor") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VetMainScreen()),
        );
      } else if (role == "admin" || role == "super_admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()), // Updated import needed
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on AuthException catch (e) {
      debugPrint('❌ LOGIN AuthException: ${e.message}');
      debugPrint('❌ LOGIN AuthException Code: ${e.statusCode}');
      debugPrint('❌ LOGIN AuthException Details: ${e.toString()}');
      if (!mounted) return;
      setState(() => _errorMessage = _getAuthErrorMessage(e) + '\n\nCode: ${e.statusCode}\nDetails: ${e.message}'); // Show details on UI for debugging
    } on SocketException {
      debugPrint('❌ LOGIN SocketException');
      if (!mounted) return;
      setState(() => _errorMessage = 'Unable to connect. Please check your internet connection.');
    } catch (e) {
      debugPrint('❌ LOGIN Generic Error: $e');
      debugPrint('❌ LOGIN Error Type: ${e.runtimeType}');
      if (!mounted) return;
      setState(() => _errorMessage = _getGenericErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Error Message Banner
        if (_errorMessage != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.error.withAlpha(50)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _errorMessage = null),
                  child: Icon(Icons.close_rounded, color: AppColors.error, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          focusNode: _emailFocus,
          nextFocusNode: _passwordFocus,
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          focusNode: _passwordFocus,
          onSubmit: _handleLogin,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.slate,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        
        const SizedBox(height: AppSpacing.xl),
        
        // Login Button - Coral Gradient
        _buildGradientButton(
          text: 'Sign In',
          onPressed: _handleLogin,
          isLoading: _isLoading,
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Forgot Password
        TextButton(
          onPressed: () {},
          child: Text(
            'Forgot Password?',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    VoidCallback? onSubmit,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      cursorColor: AppColors.primary,
      textInputAction: nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
      onSubmitted: (_) {
        if (nextFocusNode != null) {
          nextFocusNode.requestFocus();
        } else if (onSubmit != null) {
          onSubmit();
        }
      },
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF1A1A1A),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.slate),
        floatingLabelStyle: TextStyle(color: AppColors.primary),
        prefixIcon: icon != null ? Icon(icon, color: AppColors.slate) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isLoading ? null : AppGradients.coralButton,
        color: isLoading ? AppColors.borderLight : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: isLoading
            ? null
            : [
                BoxShadow(
                  color: AppColors.accent.withAlpha(89),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
