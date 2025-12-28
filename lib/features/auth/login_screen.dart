import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/auth_input_field.dart';
import '../../shared/widgets/pill_button.dart';
import 'signup_screen.dart';
import '../../main_wrapper.dart';
import '../orphanage/orphanage_main_wrapper.dart';

class LoginScreen extends StatefulWidget {
  final String targetRole;
  final AuthService? authService;
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.targetRole,
    this.authService,
    this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthService _authService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      print("DEBUG: Attempting login...");
      // 1. Perform Login
      final userCredential = await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (userCredential?.user != null) {
        print("DEBUG: Login successful. User ID: ${userCredential!.user!.uid}");
        // 2. Check Role
        final role = await _authService.getUserRole(userCredential!.user!.uid);
        print("DEBUG: Fetched role: '$role'. Target role: '${widget.targetRole}'");
        
        if (role != widget.targetRole) {
          print("DEBUG: Role mismatch! Signing out.");
          // Role mismatch! Sign out and show error.
          await _authService.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Account exists as ${role.toUpperCase()}. Please log in as a $role.'),
                backgroundColor: AppColors.salmonOrange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        } else {
          print("DEBUG: Role match. Navigating explicitly.");
          if (widget.onLoginSuccess != null) {
            widget.onLoginSuccess!();
            return;
          }
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => role == 'orphanage' 
                    ? OrphanageMainWrapper() 
                    : const MainWrapper(),
              ),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      print("DEBUG: Login error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      print("DEBUG: Attempting Google Sign-In...");
      // Pass targetRole to ensure new users get the correct role
      final userCredential = await _authService.signInWithGoogle(targetRole: widget.targetRole);
      
      if (userCredential?.user != null) {
        print("DEBUG: Google Sign-In successful. User ID: ${userCredential!.user!.uid}");
        // Check if role exists, if not assign targetRole (double check)
        final role = await _authService.getUserRole(userCredential!.user!.uid);
        print("DEBUG: Fetched role: '$role'. Target role: '${widget.targetRole}'");

        if (role == 'unknown' || role.isEmpty) {
           print("DEBUG: New user or no role. Assigning '${widget.targetRole}'");
           await _authService.updateUserRole(userCredential!.user!.uid, widget.targetRole);
           // Navigate after assigning role
           if (mounted) {
             Navigator.of(context).pushAndRemoveUntil(
               MaterialPageRoute(
                 builder: (context) => widget.targetRole == 'orphanage' 
                     ? OrphanageMainWrapper() 
                     : const MainWrapper(),
               ),
               (route) => false,
             );
           }
        } else if (role != widget.targetRole) {
           print("DEBUG: Role mismatch! Signing out.");
           // Role mismatch
           await _authService.signOut();
           throw "Account exists as ${role.toUpperCase()}. Please log in as a $role.";
        } else {
           // Role matches
           print("DEBUG: Role check passed. Navigating explicitly.");
           if (mounted) {
             Navigator.of(context).pushAndRemoveUntil(
               MaterialPageRoute(
                 builder: (context) => role == 'orphanage' 
                     ? OrphanageMainWrapper() 
                     : const MainWrapper(),
               ),
               (route) => false,
             );
           }
        }
      }
    } catch (e) {
      print("DEBUG: Google Sign-In error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.salmonOrange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDonor = widget.targetRole == 'donor';
    final roleLabel = isDonor ? "Donor" : "Orphanage";
    final accentColor = isDonor ? AppColors.mintGreen : AppColors.periwinkleBlue;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$roleLabel Login",
                style: AppTypography.sectionHeader(context).copyWith(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                "Welcome back! Please enter your details.",
                style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context)),
              ),
              const SizedBox(height: 48),
              
              AuthInputField(
                controller: _emailController,
                label: "Email",
                hint: "Enter your email",
                prefixIcon: LucideIcons.mail,
              ),
              const SizedBox(height: 24),
              
              AuthInputField(
                controller: _passwordController,
                label: "Password",
                hint: "••••••••",
                prefixIcon: LucideIcons.lock,
                isPassword: true,
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: PillButton(
                  text: _isLoading ? "LOGGING IN..." : "LOG IN",
                  onPressed: _isLoading ? null : _login,
                  color: accentColor,
                  textColor: AppColors.darkCharcoalText,
                ),
              ),
              
              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.getDivider(context))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "OR",
                      style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context), fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.getDivider(context))),
                ],
              ),
              const SizedBox(height: 24),

              // Google Sign-In button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: Icon(LucideIcons.globe, color: AppColors.getTextPrimary(context)),
                  label: Text(
                    "CONTINUE WITH GOOGLE",
                    style: AppTypography.button(context).copyWith(color: AppColors.getTextPrimary(context)),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.getSurface(context),
                    side: BorderSide(color: AppColors.getDivider(context)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => SignupScreen(targetRole: widget.targetRole)),
                    ),
                    child: Text(
                      "Sign up",
                      style: AppTypography.button(context).copyWith(color: accentColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
