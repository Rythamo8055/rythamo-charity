import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/auth/welcome_screen.dart';
import 'features/orphanage/orphanage_main_wrapper.dart';
import 'main_wrapper.dart';
import 'core/services/auth_service.dart';
import 'core/services/onboarding_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RythamoCharityApp());
}

class RythamoCharityApp extends StatelessWidget {
  const RythamoCharityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Rythamo Charity',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

// Auth gate to route based on authentication state
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final OnboardingService _onboardingService = OnboardingService();
  bool? _isFirstRun;

  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    final isFirstRun = await _onboardingService.checkFirstRun();
    setState(() {
      _isFirstRun = isFirstRun;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking first run status
    if (_isFirstRun == null) {
      return const Scaffold(
        backgroundColor: AppColors.deepCharcoal,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.mintGreen),
        ),
      );
    }

    // If first run, show onboarding
    if (_isFirstRun!) {
      return const OnboardingScreen();
    }

    // Otherwise, proceed with normal auth flow
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.deepCharcoal,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.mintGreen),
            ),
          );
        }

        // If user is signed in, check their role
        if (snapshot.hasData && snapshot.data != null) {
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: AppColors.deepCharcoal,
                  body: Center(
                    child: CircularProgressIndicator(color: AppColors.mintGreen),
                  ),
                );
              }

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                // Profile doesn't exist - show welcome screen but DON'T sign out
                // This was causing donors to get logged out unexpectedly
                print("DEBUG: User profile doesn't exist for ${snapshot.data!.uid}");
                return const WelcomeScreen();
              }

              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
              final role = userData?['role'] ?? 'donor';
              
              print("DEBUG: AuthGate - User: ${snapshot.data!.uid}, Role: $role");
              
              if (role == 'orphanage') {
                return const OrphanageMainWrapper();
              } else {
                return const MainWrapper();
              }
            },
          );
        }

        // Otherwise, show welcome screen
        return const WelcomeScreen();
      },
    );
  }
}
