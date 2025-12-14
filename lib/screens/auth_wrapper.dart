import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zovetica/services/supabase_service.dart';
import 'package:zovetica/services/user_service.dart';
import 'package:zovetica/data/repositories/user_repository.dart';
import 'vet_main_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'home_screen.dart';
import 'auth_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _userRepo = UserRepository.instance;
  final _userService = UserService();
  bool _isLoading = true;
  Session? _session;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // 1. Get initial session immediately
    final session = SupabaseService.client.auth.currentSession;
    
    if (session != null) {
      // 2. If session exists, check ban status from SERVER first (security critical)
      try {
        final userData = await _userService.getUserById(session.user.id);
        
        // SECURITY: Check if user is banned
        final bannedAt = userData?['banned_at'];
        final isBanned = userData?['is_banned'] == true || bannedAt != null;
        
        debugPrint('🔒 AUTH WRAPPER SECURITY: banned_at=$bannedAt, isBanned=$isBanned');
        
        if (isBanned) {
          debugPrint('⛔ AUTH WRAPPER: User is BANNED - Invalidating session');
          await SupabaseService.client.auth.signOut();
          
          if (mounted) {
            setState(() {
              _session = null;
              _isLoading = false;
            });
          }
          return; // Stop - user will see AuthScreen
        }
        
        // User not banned, get role
        final localUser = await _userRepo.getCurrentUser();
        var role = localUser?.role ?? userData?['role'];
        
        // If not locally found, try force sync (if online)
        if (role == null) {
          final syncedUser = await _userRepo.getCurrentUser(forceRefresh: true);
          role = syncedUser?.role;
        }

        if (mounted) {
          setState(() {
            _session = session;
            _userRole = role ?? 'pet_owner'; // Default to owner if fully failed
            _isLoading = false;
          });
        }
      } catch (e) {
        // Fallback
        if (mounted) {
          setState(() {
            _session = session;
            _userRole = 'pet_owner'; 
            _isLoading = false;
          });
        }
      }
    } else {
      // No session
      if (mounted) {
        setState(() {
          _session = null;
          _isLoading = false;
        });
      }
    }

    // 3. Listen for future changes
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      if (data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.signedOut) {
         if (data.session != _session) {
            _reloadUser(data.session);
         }
      }
    });
  }

  Future<void> _reloadUser(Session? session) async {
    if (session == null) {
      setState(() {
        _session = null;
        _isLoading = false;
      });
      return;
    }

    // New session, update role
    setState(() => _isLoading = true);
    try {
      // Force refresh for new login to ensure fresh data
      final user = await _userRepo.getCurrentUser(forceRefresh: true);
      if (mounted) {
        setState(() {
          _session = session;
          _userRole = user?.role ?? 'pet_owner';
          _isLoading = false;
        });
      }
    } catch (e) {
       if (mounted) {
        setState(() {
          _session = session;
          _userRole = 'pet_owner'; // Default
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_session == null) {
      return const AuthScreen();
    }

    if (_userRole == 'doctor') {
      return const VetMainScreen();
    } else if (_userRole == 'admin' || _userRole == 'super_admin') {
      return const AdminDashboardScreen();
    } else {
      return const HomeScreen(); // OwnerMainScreen
    }
  }
}
