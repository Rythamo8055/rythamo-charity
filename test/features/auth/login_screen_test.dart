import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:rythamo_charity/features/auth/login_screen.dart';
import '../../setup/test_helpers.mocks.dart';

class FakeUserCredential extends Mock implements UserCredential {
  final User? _user;
  FakeUserCredential({User? user}) : _user = user;
  
  @override
  User? get user => _user;
}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  Widget createWidgetUnderTest({VoidCallback? onLoginSuccess}) {
    return MaterialApp(
      home: LoginScreen(
        targetRole: 'donor',
        authService: mockAuthService,
        onLoginSuccess: onLoginSuccess,
      ),
    );
  }

  testWidgets('LoginScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Donor Login'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('LOG IN'), findsOneWidget);
  });

  testWidgets('Login calls signInWithEmail and triggers success callback', (WidgetTester tester) async {
    // Arrange
    final mockUser = MockUser(uid: 'test_uid', email: 'test@example.com');
    final mockCredential = FakeUserCredential(user: mockUser);
    bool successCalled = false;

    when(mockAuthService.signInWithEmail(any, any))
        .thenAnswer((_) async => mockCredential);
    when(mockAuthService.getUserRole(any))
        .thenAnswer((_) async => 'donor');

    await tester.pumpWidget(createWidgetUnderTest(
      onLoginSuccess: () => successCalled = true,
    ));

    // Act
    await tester.enterText(find.widgetWithText(TextField, 'Enter your email'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextField, '••••••••'), 'password123');
    await tester.tap(find.text('LOG IN'));
    await tester.pump(); 

    // Assert
    verify(mockAuthService.signInWithEmail('test@example.com', 'password123')).called(1);
    verify(mockAuthService.getUserRole('test_uid')).called(1);
    expect(successCalled, true);
  });

  testWidgets('Login shows error on role mismatch', (WidgetTester tester) async {
    // Arrange
    final mockUser = MockUser(uid: 'test_uid', email: 'test@example.com');
    final mockCredential = FakeUserCredential(user: mockUser);

    when(mockAuthService.signInWithEmail(any, any))
        .thenAnswer((_) async => mockCredential);
    when(mockAuthService.getUserRole(any))
        .thenAnswer((_) async => 'orphanage'); // Mismatch!
    when(mockAuthService.signOut()).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());

    // Act
    await tester.enterText(find.widgetWithText(TextField, 'Enter your email'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextField, '••••••••'), 'password123');
    await tester.tap(find.text('LOG IN'));
    await tester.pump();

    // Assert
    verify(mockAuthService.signInWithEmail(any, any)).called(1);
    verify(mockAuthService.getUserRole('test_uid')).called(1);
    verify(mockAuthService.signOut()).called(1);
    expect(find.textContaining('Account exists as ORPHANAGE'), findsOneWidget);
  });
}
