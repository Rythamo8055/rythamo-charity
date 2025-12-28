import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BentoCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double? height;
  final VoidCallback? onTap;

  const BentoCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.getCardBackground(context),
          borderRadius: BorderRadius.circular(32), // Hyper-rounded
        ),
        child: child,
      ),
    );
  }
}
