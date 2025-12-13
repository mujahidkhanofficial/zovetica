import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zovetica/services/auth_service.dart';
import 'package:zovetica/services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../models/app_models.dart';
import '../../core/network/connectivity_service.dart';

class SignUpForm extends StatefulWidget {
  final VoidCallback onSwitchToLogin;

  const SignUpForm({super.key, required this.onSwitchToLogin});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.petOwner;
  String? _errorMessage;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _clinicController = TextEditingController();

  // Predefined Vet Specialties
  static const List<String> _vetSpecialties = [
    'General Practice',
    'Emergency & Critical Care',
    'Internal Medicine',
    'Surgery',
    'Dermatology',
    'Cardiology',
    'Oncology',
    'Ophthalmology',
    'Dentistry',
    'Exotic Animals',
    'Neurology',
    'Orthopedics',
  ];
  String? _selectedSpecialty;

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _clinicFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _clinicController.dispose();

    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _clinicFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  bool _validateStrongPassword(String password) {
       final regex =
        RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$');
    return regex.hasMatch(password);
  }

  String _getAuthErrorMessage(AuthException e) {
    final message = e.message.toLowerCase();
    
    if (message.contains('user already registered') || 
        message.contains('already exists') ||
        message.contains('unique constraint')) {
      return 'An account with this email or username already exists.';
    }
    
    if (message.contains('invalid email format') ||
        message.contains('valid email')) {
      return 'Please enter a valid email address.';
    }
    
    if (message.contains('password') && message.contains('weak')) {
      return 'Password is too weak. Please use a stronger password.';
    }
    
     if (message.contains('network') || message.contains('connection')) {
      return 'Connection error. Please check your internet and try again.';
    }

    return e.message;
  }

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
      return 'Unable to connect. Please check your internet connection.';
    }
    
    if (message.contains('timeout') || message.contains('timed out')) {
      return 'Connection timed out. Please try again.';
    }
    
    return 'Something went wrong. Please try again later.';
  }

  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final phone = _phoneController.text.trim();
    final clinic = _clinicController.text.trim();

    // Clear previous error
    setState(() => _errorMessage = null);

    // Check connectivity
    final status = await ConnectivityService.instance.checkConnectivity();
    if (status == NetworkStatus.offline) {
      if (!mounted) return;
      setState(() => _errorMessage = 'No internet connection. Please turn on data or wifi.');
      return;
    }

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        pass.isEmpty ||
        confirmPass.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all required fields.');
      return;
    }

    if (_selectedRole == UserRole.doctor &&
        (_selectedSpecialty == null || clinic.isEmpty)) {
      setState(() => _errorMessage = 'Please select a specialty and enter clinic name.');
      return;
    }

    if (pass != confirmPass) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    if (!_validateStrongPassword(pass)) {
      setState(() => _errorMessage = 'Password must contain Uppercase, Lowercase, Number & Special character.');
      return;
    }

    // Validate Username format
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
       setState(() => _errorMessage = 'Username can only contain letters, numbers, and underscores.');
       return;
    }

    // Validate phone format (basic - at least 10 digits)
    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid phone number (at least 10 digits).');
      return;
    }

    // Check email and phone uniqueness before signup
    try {
      setState(() => _isLoading = true);
      
      final isEmailAvailable = await _userService.isEmailUnique(email);
      if (!isEmailAvailable) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'This email is already registered. Please use a different email or login.';
        });
        return;
      }

      final isPhoneAvailable = await _userService.isPhoneUnique(phone);
      if (!isPhoneAvailable) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'This phone number is already in use. Please use a different number.';
        });
        return;
      }
    } catch (e) {
      // If uniqueness check fails, proceed anyway - server will catch duplicates
      debugPrint('Uniqueness check failed: $e');
    }

    try {
      final response = await _authService.signUp(
          email: email, 
          password: pass,
          name: "$firstName $lastName",
          username: username,
      );

      if (response.user == null) {
        throw Exception('Signup failed');
      }
      
      try {
        await _userService.createUser(
          id: response.user!.id,
          email: email,
          name: "$firstName $lastName",
          phone: phone,
          role: _selectedRole == UserRole.doctor ? "doctor" : "pet_owner",
          specialty: _selectedRole == UserRole.doctor ? _selectedSpecialty : null,
          clinic: _selectedRole == UserRole.doctor ? clinic : null,
          username: username,
        );
      } catch (e) {
         if (e.toString().contains('duplicate key') || e.toString().contains('already exists')) {
           // success (handled by trigger)
         } else {
            throw Exception("Could not save user data. Please try again.");
         }
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
                widget.onSwitchToLogin();
              },
              child: Text('Go to Login', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _getAuthErrorMessage(e));
    } on SocketException {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unable to connect. Please check your internet connection.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _getGenericErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
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
          // Role Selection
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
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
                  nextFocusNode: _usernameFocus,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          _buildTextField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.alternate_email,
            focusNode: _usernameFocus,
            nextFocusNode: _emailFocus,
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            focusNode: _emailFocus,
            nextFocusNode: _phoneFocus,
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            focusNode: _phoneFocus,
            nextFocusNode: _selectedRole == UserRole.doctor ? _clinicFocus : _passwordFocus,
          ),
          
          if (_selectedRole == UserRole.doctor) ...[
            const SizedBox(height: AppSpacing.lg),
            // Specialty Dropdown
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedSpecialty,
                decoration: InputDecoration(
                  labelText: 'Specialty *',
                  labelStyle: TextStyle(color: AppColors.slate),
                  floatingLabelStyle: TextStyle(color: AppColors.primary),
                  prefixIcon: Icon(Icons.medical_information, color: AppColors.slate),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                ),
                hint: Text('Select your specialty', style: TextStyle(color: AppColors.slate)),
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.slate),
                items: _vetSpecialties.map((specialty) {
                  return DropdownMenuItem<String>(
                    value: specialty,
                    child: Text(specialty, style: const TextStyle(color: Color(0xFF1A1A1A))),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedSpecialty = value);
                },
                dropdownColor: Colors.white,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildTextField(
              controller: _clinicController,
              label: 'Clinic/Hospital *',
              icon: Icons.local_hospital,
              focusNode: _clinicFocus,
              nextFocusNode: _passwordFocus,
            ),
          ],
          
          const SizedBox(height: AppSpacing.lg),
          
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            focusNode: _passwordFocus,
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
