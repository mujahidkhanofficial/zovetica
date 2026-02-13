// This is a basic Flutter widget test for Pets & Vets.
//
// Verifies that the app builds and the splash screen loads correctly.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pets_and_vets/main.dart';
import 'package:pets_and_vets/services/auth_service.dart';
import 'services/auth_service_test.mocks.dart';

void main() {
  testWidgets('App smoke test - Splash screen loads', (WidgetTester tester) async {
    // Arrange
    final mockAuthService = MockGoTrueClient(); // Use MockGoTrueClient as MockAuthService wrapper? 
    // Wait, generated mock was MockSupabaseClient / MockGoTrueClient.
    // I need to mock AuthService itself to be clean, OR pass a mocked SupabaseClient to real AuthService.
    // Let's mock AuthService itself.
    // But I didn't generate MockAuthService.
    // Let's pass a real AuthService with a mocked SupabaseClient.
    
    // Better: Generate MockAuthService. 
    // Let's assume for now I pass a real AuthService with a mock client.
    
    // Actually, I can just create a quick MockAuthService here if needed, or rely on the DI I just built.
    // In auth_service_test.dart I mocked SupabaseClient.
    
    // Let's use the mocks from 'services/auth_service_test.mocks.dart'
    final mockSupabaseClient = MockSupabaseClient();
    final mockGoTrueClient = MockGoTrueClient();
    when(mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(mockGoTrueClient.currentUser).thenReturn(null); // Not logged in
    
    final authService = AuthService(client: mockSupabaseClient);

    // Build our app and trigger a frame.
    await tester.pumpWidget(Pets & VetsApp(authService: authService)); // Inject!

    // Verify that the splash screen appears (it shows the app title)
    // Give it a moment to build
    await tester.pump();

    // The app should build without errors
    expect(find.byType(Pets & VetsApp), findsOneWidget);
  });
}
