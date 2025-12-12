import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zovetica/services/supabase_service.dart';
import 'package:zovetica/services/user_profile_service.dart';
import 'vet_main_screen.dart';
import 'home_screen.dart';
import 'auth_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseService.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Handle initial loading state of the stream
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final session = snapshot.data?.session;
        
        // No session -> Login
        if (session == null) {
          return const AuthScreen();
        }

        // User is logged in, fetch role
        return FutureBuilder<String?>(
          future: UserProfileService().getUserRole(session.user.id),
          builder: (context, roleSnapshot) {
             if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
             }
             
             final role = roleSnapshot.data;
             
             if (role == 'doctor') {
               return const VetMainScreen();
             } else {
               // Default to Owner Screen (HomeScreen represents OwnerMainScreen)
               return const HomeScreen(); 
             }
          },
        );
      },
    );
  }
}
