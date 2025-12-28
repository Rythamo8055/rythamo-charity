import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class InputField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final VoidCallback? onSearchTap;

  const InputField({
    super.key,
    required this.hintText,
    this.controller,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lighterGraphite,
        borderRadius: BorderRadius.circular(100), // Exaggerated pill shape
      ),
      padding: const EdgeInsets.only(left: 24, right: 8, top: 4, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTypography.body(context),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTypography.body(context).copyWith(
                  color: AppColors.white.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (onSearchTap != null)
            GestureDetector(
              onTap: onSearchTap,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.salmonOrange,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.search,
                  color: AppColors.darkCharcoalText,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
