import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class EmptyStateWidget extends StatelessWidget {
  final String lottiePath;
  final String message;
  final String? subMessage;
  final double height;

  const EmptyStateWidget({
    super.key,
    required this.lottiePath,
    required this.message,
    this.subMessage,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            lottiePath,
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.error, color: AppColors.salmonOrange, size: height / 2);
            },
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTypography.sectionHeader(context).copyWith(
              color: AppColors.getTextPrimary(context).withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (subMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              subMessage!,
              style: AppTypography.body(context).copyWith(
                color: AppColors.getTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
