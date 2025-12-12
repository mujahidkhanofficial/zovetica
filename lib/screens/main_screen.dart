import 'package:flutter/material.dart';
import 'package:zovetica/screens/doctor_dashboard_screen.dart';
import 'package:zovetica/services/auth_service.dart';
import 'package:zovetica/services/user_service.dart';
import 'home_screen.dart';
import 'auth_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _redirectBasedOnRole();
  }

  Future<void> _redirectBasedOnRole() async {
    final user = _authService.currentUser;

    if (user == null) {
      // Not logged in → go to AuthScreen
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      return;
    }

    try {
      final userData = await _userService.getUserById(user.id);

      if (userData == null) {
        // No user data → logout
        await _authService.signOut();
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const AuthScreen()));
        return;
      }

      final role = userData['role'] ?? "pet_owner";

      if (!mounted) return;

      if (role == "doctor") {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const DoctorDashboardScreen()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      debugPrint("Error fetching role: $e");
      // On error, logout user
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a simple loading indicator while checking role
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
