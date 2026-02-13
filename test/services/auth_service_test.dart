import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pets_and_vets/services/auth_service.dart';

// Generate mocks using: dart run build_runner build
@GenerateMocks([SupabaseClient, GoTrueClient])
import 'auth_service_test.mocks.dart';

void main() {
  late AuthService authService;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    
    // Stub the auth getter to return our mock auth client
    when(mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    
    authService = AuthService(client: mockSupabaseClient);
  });

  group('AuthService Tests', () {
    test('isLoggedIn returns true when user is present', () {
      // Arrange
      when(mockGoTrueClient.currentUser).thenReturn(User(
        id: '123', 
        appMetadata: {}, 
        userMetadata: {}, 
        aud: 'authenticated', 
        createdAt: DateTime.now().toIso8601String()
      ));

      // Act
      final result = authService.isLoggedIn;

      // Assert
      expect(result, true);
    });

    test('isLoggedIn returns false when user is null', () {
      // Arrange
      when(mockGoTrueClient.currentUser).thenReturn(null);

      // Act
      final result = authService.isLoggedIn;

      // Assert
      expect(result, false);
    });
  });
}
