import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/pill_button.dart';
import '../../main_wrapper.dart';
import '../orphanage/orphanage_main_wrapper.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _selectRole(String role) async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update role in Firestore for record-keeping (optional but good practice)
        await _authService.updateUserRole(user.uid, role);
        
        if (!mounted) return;

        // Navigate to the appropriate dashboard
        if (role == 'orphanage') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OrphanageMainWrapper()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MainWrapper()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                "Welcome to Rythamo",
                style: AppTypography.sectionHeader(context).copyWith(fontSize: 28),
              ),
              const SizedBox(height: 12),
              Text(
                "How would you like to use the app?",
                style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context), fontSize: 16),
              ),
              const Spacer(),
              
              // Donor Option
              _buildRoleCard(
                title: "I want to Donate",
                description: "Find orphanages, offer donations, and make a difference.",
                icon: LucideIcons.heartHandshake,
                color: AppColors.mintGreen,
                onTap: () => _selectRole('donor'),
              ),
              
              const SizedBox(height: 24),
              
              // Orphanage Admin Option
              _buildRoleCard(
                title: "I manage an Orphanage",
                description: "Register your organization, post requests, and receive donations.",
                icon: LucideIcons.building,
                color: AppColors.periwinkleBlue,
                onTap: () => _selectRole('orphanage'),
              ),
              
              const Spacer(),
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: AppColors.mintGreen)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.getOverlay(context, opacity: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.button(context).copyWith(fontSize: 18, color: AppColors.getTextPrimary(context)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context), fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: AppColors.getTextTertiary(context)),
          ],
        ),
      ),
    );
  }
}
