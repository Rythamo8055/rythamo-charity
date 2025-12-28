import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/models/item_request_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class RequestCard extends StatelessWidget {
  final ItemRequest request;
  final VoidCallback? onTap;
  final bool showOrphanageName;
  final VoidCallback? onActionPressed;
  final String actionLabel;

  const RequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.showOrphanageName = true,
    this.onActionPressed,
    this.actionLabel = "Help",
  });

  @override
  Widget build(BuildContext context) {
    final progress = request.quantityFulfilled / request.quantityNeeded;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getPriorityColor(request.priority).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Priority & Category
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(request.priority).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.alertCircle, size: 12, color: _getPriorityColor(request.priority)),
                      const SizedBox(width: 4),
                      Text(
                        request.priority.name.toUpperCase(),
                        style: AppTypography.button(context).copyWith(
                          fontSize: 10,
                          color: _getPriorityColor(request.priority),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  request.category,
                  style: AppTypography.body(context).copyWith(fontSize: 12, color: AppColors.getTextSecondary(context)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title & Orphanage
            Text(
              request.itemName,
              style: AppTypography.button(context).copyWith(fontSize: 18),
            ),
            if (showOrphanageName) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(LucideIcons.building, size: 14, color: AppColors.getTextSecondary(context)),
                  const SizedBox(width: 6),
                  Text(
                    request.orphanageName,
                    style: AppTypography.body(context).copyWith(fontSize: 14, color: AppColors.getTextSecondary(context)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${request.quantityFulfilled} / ${request.quantityNeeded} ${request.unit}",
                      style: AppTypography.body(context).copyWith(fontSize: 12, color: AppColors.getTextSecondary(context)),
                    ),
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: AppTypography.button(context).copyWith(fontSize: 12, color: AppColors.mintGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.getDivider(context),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.mintGreen),
                    minHeight: 6,
                  ),
                ),
              ],
            ),

            // Action Button (Optional)
            if (onActionPressed != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onActionPressed,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.mintGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(actionLabel, style: AppTypography.button(context).copyWith(color: AppColors.mintGreen)),
                ),
              ),
            ],
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 400.ms, curve: Curves.easeOut)
    .slideX(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  Color _getPriorityColor(RequestPriority priority) {
    switch (priority) {
      case RequestPriority.urgent:
        return AppColors.salmonOrange;
      case RequestPriority.high:
        return AppColors.mutedMustard;
      case RequestPriority.medium:
        return AppColors.periwinkleBlue;
      case RequestPriority.low:
        return AppColors.mintGreen;
    }
  }
}

