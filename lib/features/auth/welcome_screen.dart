import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _navigateToLogin(BuildContext context, String role) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(targetRole: role),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
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
                context: context,
                title: "I want to Donate",
                description: "Find orphanages, offer donations, and make a difference.",
                icon: LucideIcons.heartHandshake,
                color: AppColors.mintGreen,
                onTap: () => _navigateToLogin(context, 'donor'),
              ),
              
              const SizedBox(height: 24),
              
              // Orphanage Admin Option
              _buildRoleCard(
                context: context,
                title: "I manage an Orphanage",
                description: "Register your organization, post requests, and receive donations.",
                icon: LucideIcons.building,
                color: AppColors.periwinkleBlue,
                onTap: () => _navigateToLogin(context, 'orphanage'),
              ),
              
              const Spacer(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
