import 'package:flutter/material.dart';
import 'package:pets_and_vets/screens/auth/login_form.dart';
import 'package:pets_and_vets/screens/auth/signup_form.dart';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                const SizedBox(height: 60),
                
                // Logo - Minimalist, no container
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Image.asset(
                    'logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Welcome Text
                const Text(
                  'Welcome to Pets & Vets',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Your pet\'s health companion',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.slate.withAlpha(180),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                // Tab Bar - Refined for white background
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.borderLight.withAlpha(100),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: AppGradients.coralButton,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withAlpha(60),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.slate,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
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
                  height: 650, // Adjusted height
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
