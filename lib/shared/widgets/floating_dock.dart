import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';

class FloatingDock extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingDock({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
          color: AppColors.getSurface(context).withValues(alpha: 0.9), // Frosted feel
            borderRadius: BorderRadius.circular(100), // Pill shape
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(context, LucideIcons.home, 0),
              const SizedBox(width: 24),
              _buildIcon(context, LucideIcons.search, 1), // Discovery
              const SizedBox(width: 24),
              _buildIcon(context, LucideIcons.gift, 2), // My Donations
              const SizedBox(width: 24),
              _buildIcon(context, LucideIcons.user, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, IconData icon, int index) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Icon(
        icon,
        color: isSelected ? AppColors.salmonOrange : AppColors.getTextTertiary(context),
        size: 28,
      ),
    );
  }
}
