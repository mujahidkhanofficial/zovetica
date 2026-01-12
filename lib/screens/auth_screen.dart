import 'package:flutter/material.dart';
import 'package:zovetica/screens/auth/login_form.dart';
import 'package:zovetica/screens/auth/signup_form.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _switchToLogin() {
    _tabController.animateTo(0);
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
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(50),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Image.asset(
                        'paw_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Welcome Text
                const Text(
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
                        color: Colors.black.withAlpha(10),
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
                  height: 600, // Increased height to accommodate new fields
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                       const SingleChildScrollView(child: LoginForm()),
                       SignUpForm(onSwitchToLogin: _switchToLogin),
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
}
