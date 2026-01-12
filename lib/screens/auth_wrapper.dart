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
        // ✅ SECURITY FIX: Fail SECURELY - deny access on error
        // Do NOT silently allow user in if security/ban check fails!
        debugPrint('❌ SECURITY: Session check failed, denying access: $e');
        await SupabaseService.client.auth.signOut();
        if (mounted) {
          setState(() {
            _session = null;  // Force re-authentication
            _userRole = null;
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

    // 3. Listen for future changes including email verification
    SupabaseService.client.auth.onAuthStateChange.listen((data) async {
      if (!mounted) return;
      
      debugPrint('🔐 Auth event: ${data.event}');
      
      // Handle sign in (including post-email-verification)
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        // User just signed in (could be login OR email verification completion)
        await _handleUserSignedIn(data.session!);
      }
      
      // Handle sign out
      if (data.event == AuthChangeEvent.signedOut) {
        if (mounted) {
          setState(() {
            _session = null;
            _userRole = null;
            _isLoading = false;
          });
        }
      }
      
      // Handle token refresh (user might have verified email)
      if (data.event == AuthChangeEvent.tokenRefreshed && data.session != null) {
        await _reloadUser(data.session);
      }
    });
  }

  /// Handle user signed in event (login or post-email-verification)
  Future<void> _handleUserSignedIn(Session session) async {
    debugPrint('👤 User signed in: ${session.user.email}');
    
    setState(() => _isLoading = true);
    
    try {
      // Check if profile exists in public.users
      final existingUser = await _userService.getUserById(session.user.id);
      
      if (existingUser == null) {
        // Profile doesn't exist - create it from auth metadata
        // This happens after email verification when email confirmation is enabled
        debugPrint('📝 Creating profile for newly verified user');
        
        final metadata = session.user.userMetadata ?? {};
        try {
          await SupabaseService.client.from('users').upsert({
            'id': session.user.id,
            'email': session.user.email,
            'name': metadata['full_name'] ?? 'User',
            'username': metadata['username'],
            'phone': metadata['phone'],
            // ✅ SECURITY: ALWAYS set role to 'pet_owner' - NEVER trust client metadata!
            // Role changes require admin action via RLS-protected operations
            'role': 'pet_owner',
            // ❌ REMOVED: specialty, clinic from metadata - these are doctor-only fields
          });
          debugPrint('✅ Profile created successfully with role: pet_owner');
        } catch (e) {
          debugPrint('⚠️ Profile creation error (might already exist): $e');
        }
      } else {
        // SECURITY: Check if user is banned
        final bannedAt = existingUser['banned_at'];
        final isBanned = existingUser['is_banned'] == true || bannedAt != null;
        
        if (isBanned) {
          debugPrint('⛔ SECURITY: User is BANNED - denying access');
          await SupabaseService.client.auth.signOut();
          if (mounted) {
            setState(() {
              _session = null;
              _userRole = null;
              _isLoading = false;
            });
          }
          return;
        }
      }
      
      // Reload user data
      await _reloadUser(session);
    } catch (e) {
      // ✅ SECURITY FIX: Fail SECURELY - deny access on error
      // Do NOT silently allow user in if security check fails!
      debugPrint('❌ SECURITY: Error during sign-in check, denying access: $e');
      await SupabaseService.client.auth.signOut();
      if (mounted) {
        setState(() {
          _session = null;  // Force re-authentication
          _userRole = null;
          _isLoading = false;
        });
      }
    }
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
