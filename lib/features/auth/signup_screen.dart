import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/auth_input_field.dart';
import 'login_screen.dart';
import '../../main_wrapper.dart';
import '../orphanage/orphanage_main_wrapper.dart';

class SignupScreen extends StatefulWidget {
  final String targetRole;

  const SignupScreen({super.key, required this.targetRole});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _acceptedTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_acceptedTerms) {
      setState(() => _errorMessage = "Please accept the terms and conditions");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Sign Up
      final userCredential = await _authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        role: widget.targetRole,
      );

      // 2. Navigate explicitly
      if (userCredential?.user != null) {
        
        // 3. Navigate explicitly
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
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Pass targetRole
      final userCredential = await _authService.signInWithGoogle(targetRole: widget.targetRole);
      if (userCredential?.user != null) {
        // Check if role exists, if not assign targetRole
        final role = await _authService.getUserRole(userCredential!.user!.uid);
        if (role == 'unknown' || role.isEmpty) {
           await _authService.updateUserRole(userCredential!.user!.uid, widget.targetRole);
           // Navigate
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
           // Role mismatch
           await _authService.signOut();
           throw "Account exists as ${role.toUpperCase()}. Please log in as a $role.";
        } else {
           // Role matches
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
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Icon
                Icon(
                  LucideIcons.heart,
                  size: 80,
                  color: accentColor,
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  "JOIN AS ${roleLabel.toUpperCase()}",
                  style: AppTypography.bigData(context).copyWith(fontSize: 32, color: AppColors.getTextPrimary(context)),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "Create an account to start making a difference",
                  style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.salmonOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.salmonOrange),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertCircle, color: AppColors.salmonOrange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.body(context).copyWith(fontSize: 12, color: AppColors.salmonOrange),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Name field
                AuthInputField(
                  controller: _nameController,
                  label: "Full Name",
                  hint: "John Doe",
                  prefixIcon: LucideIcons.user,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email field
                AuthInputField(
                  controller: _emailController,
                  label: "Email",
                  hint: "your@email.com",
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: LucideIcons.mail,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                AuthInputField(
                  controller: _passwordController,
                  label: "Password",
                  hint: "••••••••",
                  isPassword: true,
                  prefixIcon: LucideIcons.lock,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password field
                AuthInputField(
                  controller: _confirmPasswordController,
                  label: "Confirm Password",
                  hint: "••••••••",
                  isPassword: true,
                  prefixIcon: LucideIcons.lock,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Terms checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
                      fillColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return accentColor;
                        }
                        return AppColors.getOverlay(context, opacity: 0.2);
                      }),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: "I accept the ",
                          style: AppTypography.body(context).copyWith(fontSize: 12, color: AppColors.getTextSecondary(context)),
                          children: [
                            TextSpan(
                              text: "Terms & Conditions",
                              style: AppTypography.body(context).copyWith(fontSize: 12, color: accentColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sign up button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: PillButton(
                    text: _isLoading ? "CREATING ACCOUNT..." : "SIGN UP",
                    onPressed: _isLoading ? null : () => _signUp(),
                    color: accentColor,
                    textColor: AppColors.darkCharcoalText,
                    icon: LucideIcons.userPlus,
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
                    onPressed: _isLoading ? null : () => _signInWithGoogle(),
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

                // Sign in link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context), // Go back to Login
                      child: Text(
                        "Sign In",
                        style: AppTypography.button(context).copyWith(color: accentColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
