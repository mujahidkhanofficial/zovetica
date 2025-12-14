import 'package:flutter/material.dart';
import 'package:zovetica/screens/vet_main_screen.dart';
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
      final isBanned = userData['is_banned'] == true;

      if (isBanned) {
        await _authService.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account banned: ${userData['banned_reason'] ?? "Violation of terms"}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const AuthScreen()));
        return;
      }

      if (!mounted) return;

      // Route based on role
      // Admin and Super Admin users go to HomeScreen but have access to admin dashboard via profile
      // Doctor users go to VetMainScreen
      // Pet owners go to HomeScreen
      switch (role) {
        case "doctor":
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const VetMainScreen()));
          break;
        case "admin":
        case "super_admin":
          // Admins use the regular HomeScreen but with admin dashboard access
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HomeScreen(isAdmin: true)));
          break;
        default:
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
