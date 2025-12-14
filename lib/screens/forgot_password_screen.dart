import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zovetica/services/auth_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_notifications.dart';
import '../widgets/pet_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _loading = false;

  void _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      AppNotifications.showWarning(context, 'Please enter your email');
      return;
    }

    setState(() => _loading = true);

    try {
      await _authService.resetPassword(email);
      AppNotifications.showSuccess(context, 'Password reset email sent');
    } on AuthException catch (e) {
      AppNotifications.showError(context, e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.charcoal),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              'Enter your email to reset your password',
              style: TextStyle(fontSize: 16, color: AppColors.charcoal),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 24),
            PetButton(
              text: 'Send Reset Link',
              onPressed: _loading ? null : _resetPassword,
              isLoading: _loading,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}

