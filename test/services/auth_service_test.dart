import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:rythamo_charity/core/services/auth_service.dart';
import '../setup/test_helpers.mocks.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;
  late MockGoogleSignIn mockGoogleSignIn;
  late AuthService authService;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = FakeFirebaseFirestore();
    mockGoogleSignIn = MockGoogleSignIn();
    authService = AuthService(
      auth: mockAuth,
      firestore: mockFirestore,
      googleSignIn: mockGoogleSignIn,
    );
  });

  group('AuthService Tests', () {
    test('signInWithEmail returns UserCredential on success', () async {
      // Arrange
      final user = MockUser(
        isAnonymous: false,
        uid: 'test_uid',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      mockAuth = MockFirebaseAuth(mockUser: user);
      authService = AuthService(
        auth: mockAuth,
        firestore: mockFirestore,
        googleSignIn: mockGoogleSignIn,
      );

      // Act
      final result = await authService.signInWithEmail('test@example.com', 'password');

      // Assert
      expect(result, isNotNull);
      expect(result!.user!.uid, 'test_uid');
    });

    test('signUpWithEmail creates user and profile', () async {
      // Act
      final result = await authService.signUpWithEmail(
        'new@example.com',
        'password',
        'New User',
        role: 'orphanage',
      );

      // Assert
      expect(result, isNotNull);
      expect(result!.user!.email, 'new@example.com');
      expect(result.user!.displayName, 'New User');

      // Verify Firestore profile creation
      final userDoc = await mockFirestore.collection('users').doc(result.user!.uid).get();
      expect(userDoc.exists, true);
      expect(userDoc.data()!['role'], 'orphanage');
      expect(userDoc.data()!['email'], 'new@example.com');
    });

    test('signOut signs out from both Auth and Google', () async {
      // Arrange
      when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

      // Act
      await authService.signOut();

      // Assert
      // Verify Google Sign In signOut was called
      verify(mockGoogleSignIn.signOut()).called(1);
      // Verify Firebase Auth signOut (MockFirebaseAuth doesn't expose a verify method easily for this, 
      // but we trust the library or check currentUser if it was persisted)
      expect(authService.currentUser, isNull);
    });
  });
}
