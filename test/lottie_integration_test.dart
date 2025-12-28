import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:rythamo_charity/features/onboarding/widgets/onboarding_page.dart';
import 'package:rythamo_charity/features/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('OnboardingPage renders Lottie asset', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OnboardingPage(
            imagePath: 'assets/mascot/reading.json',
            title: 'Test Title',
            description: 'Test Description',
            accentColor: Colors.blue,
          ),
        ),
      ),
    );

    // Verify Lottie widget is present
    expect(find.byType(Lottie), findsOneWidget);
  });

  testWidgets('OnboardingScreen initializes with Lottie pages', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );

    // Verify Lottie widget is present on the first page
    expect(find.byType(Lottie), findsOneWidget);
  });
}
