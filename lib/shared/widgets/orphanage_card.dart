import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/models/orphanage_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrphanageCard extends StatelessWidget {
  final Orphanage orphanage;
  final GeoPoint? userLocation;
  final VoidCallback? onTap;

  const OrphanageCard({
    super.key,
    required this.orphanage,
    this.userLocation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final distance = userLocation != null
        ? orphanage.distanceFrom(userLocation!)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: orphanage.urgentNeeds.isNotEmpty
                ? AppColors.salmonOrange.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (orphanage.photoUrls.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.network(
                  orphanage.photoUrls.first,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(context),
                ),
              )
            else
              _buildPlaceholderImage(context),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and verified badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          orphanage.name,
                          style: AppTypography.button(context).copyWith(fontSize: 18),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (orphanage.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.mintGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.checkCircle, size: 12, color: AppColors.mintGreen),
                              const SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: AppTypography.body(context).copyWith(fontSize: 10, color: AppColors.mintGreen),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Address
                  Row(
                    children: [
                      Icon(LucideIcons.mapPin, size: 14, color: AppColors.getTextSecondary(context)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          orphanage.address,
                          style: AppTypography.body(context).copyWith(fontSize: 12, color: AppColors.getTextSecondary(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (distance != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.getSurface(context),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '${distance.toStringAsFixed(1)} km',
                            style: AppTypography.body(context).copyWith(fontSize: 10, color: AppColors.mintGreen),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stats
                  Row(
                    children: [
                      _buildStat(context, LucideIcons.users, '${orphanage.currentOccupancy}/${orphanage.capacity}', 'Capacity'),
                      const SizedBox(width: 16),
                      _buildStat(
                        context,
                        LucideIcons.alertCircle,
                        orphanage.urgentNeeds.length.toString(),
                        'Urgent Needs',
                        color: orphanage.urgentNeeds.isNotEmpty ? AppColors.salmonOrange : null,
                      ),
                    ],
                  ),

                  // Urgent needs banner
                  if (orphanage.urgentNeeds.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.salmonOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.heartHandshake, size: 16, color: AppColors.salmonOrange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Needs: ${orphanage.urgentNeeds.take(2).join(", ")}${orphanage.urgentNeeds.length > 2 ? "..." : ""}',
                              style: AppTypography.body(context).copyWith(fontSize: 11, color: AppColors.getTextPrimary(context)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Center(
        child: Icon(LucideIcons.building, size: 48, color: AppColors.getTextTertiary(context)),
      ),
    );
  }

  Widget _buildStat(BuildContext context, IconData icon, String value, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? AppColors.getTextSecondary(context)),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTypography.button(context).copyWith(fontSize: 14, color: color ?? AppColors.getTextPrimary(context)),
            ),
            Text(
              label,
              style: AppTypography.body(context).copyWith(fontSize: 9, color: AppColors.getTextSecondary(context)),
            ),
          ],
        ),
      ],
    );
  }
}
