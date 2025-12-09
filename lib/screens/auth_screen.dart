import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zovetica/screens/DoctorDashboardScreen.dart';
import 'package:zovetica/services/auth_service.dart';
import 'package:zovetica/services/user_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import '../utils/app_notifications.dart';
import 'home_screen.dart';
import '../models/app_models.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  UserRole _selectedRole = UserRole.petOwner;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _clinicController = TextEditingController();

  // Focus nodes for keyboard navigation
  final _loginEmailFocus = FocusNode();
  final _loginPasswordFocus = FocusNode();
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _signupEmailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _specialtyFocus = FocusNode();
  final _clinicFocus = FocusNode();
  final _signupPasswordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _clinicController.dispose();
    // Dispose focus nodes
    _loginEmailFocus.dispose();
    _loginPasswordFocus.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _signupEmailFocus.dispose();
    _phoneFocus.dispose();
    _specialtyFocus.dispose();
    _clinicFocus.dispose();
    _signupPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  bool _validateStrongPassword(String password) {
    final regex =
        RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$');
    return regex.hasMatch(password);
  }

  /// Parse Supabase auth errors into user-friendly messages
  String _getAuthErrorMessage(AuthException e) {
    final message = e.message.toLowerCase();
    
    // User already exists
    if (message.contains('user already registered') || 
        message.contains('already exists') ||
        message.contains('unique constraint')) {
      return 'An account with this email already exists. Please login instead.';
    }
    
    // Invalid credentials
    if (message.contains('invalid login credentials') || 
        message.contains('invalid password') ||
        message.contains('invalid email')) {
      return 'Invalid email or password. Please check your credentials.';
    }
    
    // Email not confirmed
    if (message.contains('email not confirmed') ||
        message.contains('confirm your email')) {
      return 'Please verify your email before logging in. Check your inbox for the confirmation link.';
    }
    
    // Too many requests
    if (message.contains('too many requests') ||
        message.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    
    // Network error
    if (message.contains('network') || message.contains('connection')) {
      return 'Connection error. Please check your internet and try again.';
    }
    
    // Invalid email format
    if (message.contains('invalid email format') ||
        message.contains('valid email')) {
      return 'Please enter a valid email address.';
    }
    
    // Weak password
    if (message.contains('password') && message.contains('weak')) {
      return 'Password is too weak. Please use a stronger password.';
    }
    
    // Default to original message
    return e.message;
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      AppNotifications.showWarning(context, "Please enter both email and password");
      return;
    }

    try {
      setState(() => _isLoading = true);

      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed');
      }

      final userData = await _userService.getUserById(response.user!.id);

      if (userData == null) {
        throw Exception('User data not found');
      }

      final role = userData['role'] ?? "pet_owner";

      if (!mounted) return;

      if (role == "doctor") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DoctorDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on AuthException catch (e) {
      AppNotifications.showError(context, _getAuthErrorMessage(e));
    } catch (e) {
      AppNotifications.showError(context, "Login failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final specialty = _specialtyController.text.trim();
    final clinic = _clinicController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        pass.isEmpty ||
        confirmPass.isEmpty) {
      AppNotifications.showWarning(context, "Please fill in all required fields.");
      return;
    }

    if (_selectedRole == UserRole.doctor &&
        (specialty.isEmpty || clinic.isEmpty)) {
      AppNotifications.showWarning(context, "Please fill in specialty and clinic.");
      return;
    }

    if (pass != confirmPass) {
      AppNotifications.showWarning(context, "Passwords do not match");
      return;
    }

    if (!_validateStrongPassword(pass)) {
      AppNotifications.showWarning(context, 
          "Password must contain Uppercase, Lowercase, Number & Special character");
      return;
    }

    try {
      setState(() => _isLoading = true);

      final response = await _authService.signUp(
          email: email, password: pass);

      if (response.user == null) {
        throw Exception('Signup failed');
      }

      // Save user in database
      try {
        await _userService.createUser(
          id: response.user!.id,
          email: email,
          name: "$firstName $lastName",
          phone: phone,
          role: _selectedRole == UserRole.doctor ? "doctor" : "pet_owner",
          specialty: _selectedRole == UserRole.doctor ? specialty : null,
          clinic: _selectedRole == UserRole.doctor ? clinic : null,
        );
      } catch (e) {
        throw Exception(
            "Could not save user data. Please try again. $e");
      }

      if (!mounted) return;

      // Show confirmation email dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.mark_email_read_rounded, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              const Text('Check Your Email'),
            ],
          ),
          content: Text(
            'A confirmation link has been sent to $email. Please verify your email to complete registration.',
            style: TextStyle(color: AppColors.slate, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _tabController.animateTo(0); // Switch to Login tab
              },
              child: Text('Go to Login', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } on AuthException catch (e) {
      AppNotifications.showError(context, _getAuthErrorMessage(e));
    } catch (e) {
      AppNotifications.showError(context, "Signup failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                const SizedBox(height: 50),
                
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryCta,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🐾', style: TextStyle(fontSize: 48)),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Welcome Text
                Text(
                  'Welcome to Zovetica',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your pet\'s health companion',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.slate,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: AppGradients.coralButton,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.slate,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    tabs: const [
                      Tab(text: 'Login'),
                      Tab(text: 'Sign Up'),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Tab Content
                SizedBox(
                  height: 520,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLoginForm(),
                      _buildSignUpForm(),
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

  Widget _buildLoginForm() {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          focusNode: _loginEmailFocus,
          nextFocusNode: _loginPasswordFocus,
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          focusNode: _loginPasswordFocus,
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

  Widget _buildSignUpForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Role Selection
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _roleButton(UserRole.petOwner, Icons.pets, "Pet Owner"),
                _roleButton(UserRole.doctor, Icons.medical_services, "Doctor"),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Name Row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person_outline,
                  focusNode: _firstNameFocus,
                  nextFocusNode: _lastNameFocus,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  focusNode: _lastNameFocus,
                  nextFocusNode: _signupEmailFocus,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            focusNode: _signupEmailFocus,
            nextFocusNode: _phoneFocus,
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            focusNode: _phoneFocus,
            nextFocusNode: _selectedRole == UserRole.doctor ? _specialtyFocus : _signupPasswordFocus,
          ),
          
          if (_selectedRole == UserRole.doctor) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildTextField(
              controller: _specialtyController,
              label: 'Specialty',
              icon: Icons.medical_information,
              focusNode: _specialtyFocus,
              nextFocusNode: _clinicFocus,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildTextField(
              controller: _clinicController,
              label: 'Clinic/Hospital',
              icon: Icons.local_hospital,
              focusNode: _clinicFocus,
              nextFocusNode: _signupPasswordFocus,
            ),
          ],
          
          const SizedBox(height: AppSpacing.lg),
          
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            focusNode: _signupPasswordFocus,
            nextFocusNode: _confirmPasswordFocus,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.slate,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            icon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            focusNode: _confirmPasswordFocus,
            onSubmit: _handleSignUp,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.slate,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Sign Up Button
          _buildGradientButton(
            text: _selectedRole == UserRole.doctor
                ? "Create Doctor Account"
                : "Create Account",
            onPressed: _handleSignUp,
            isLoading: _isLoading,
          ),
        ],
      ),
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
    TextInputAction? textInputAction,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      cursorColor: AppColors.primary,
      textInputAction: textInputAction ?? (nextFocusNode != null ? TextInputAction.next : TextInputAction.done),
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
                  color: AppColors.accent.withOpacity(0.35),
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

  Widget _roleButton(UserRole role, IconData icon, String title) {
    final bool selected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: selected ? AppGradients.primaryCta : null,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : AppColors.slate,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.slate,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
