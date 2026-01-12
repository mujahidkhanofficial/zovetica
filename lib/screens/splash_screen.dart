import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import 'auth_screen.dart';
import 'main_screen.dart';
import 'auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  final AuthService? authService;
  const SplashScreen({super.key, this.authService});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AuthService _authService;
  
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Scale animation for logo
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Bounce animation for paw
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.4, 1.0, curve: Curves.bounceOut),
      ),
    );

    // Fade animation for text
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    // Slide animation for text
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _fadeController.forward();
    });

    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthWrapper(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppGradients.primaryDiagonal,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              
              // Animated Logo
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(38),
                            blurRadius: 40,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Transform.translate(
                          offset: Offset(0, -10 * (1 - _bounceAnimation.value)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(
                              'paw_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // App Name with fade animation
              AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Column(
                        children: [
                          Text(
                            'Zovetica',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Your Pet\'s Health Companion',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withAlpha(230),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const Spacer(flex: 3),
              
              // Loading indicator
              AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withAlpha(204),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withAlpha(179),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: AppSpacing.xxxl),
              
              // Version
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withAlpha(128),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
