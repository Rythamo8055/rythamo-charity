import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/models/donation_offer_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class DonationOfferCard extends StatelessWidget {
  final DonationOffer offer;
  final VoidCallback? onTap;
  final bool showDonorName; // If true, shows donor name (for orphanage view)
  final bool showOrphanageName; // If true, shows orphanage name (for donor view)

  const DonationOfferCard({
    super.key,
    required this.offer,
    this.onTap,
    this.showDonorName = false,
    this.showOrphanageName = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getStatusColor(offer.status).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Status and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(offer.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    offer.status.name.toUpperCase(),
                    style: AppTypography.button(context).copyWith(
                      fontSize: 10,
                      color: _getStatusColor(offer.status),
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(offer.createdAt),
                  style: AppTypography.body(context).copyWith(fontSize: 12, color: AppColors.getTextSecondary(context)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title (Orphanage or Donor Name)
            if (showOrphanageName)
              Text(
                offer.orphanageName,
                style: AppTypography.button(context).copyWith(fontSize: 16),
              ),
            if (showDonorName)
              Text(
                offer.donorName,
                style: AppTypography.button(context).copyWith(fontSize: 16),
              ),
            const SizedBox(height: 8),

            // Items Summary
            Text(
              _getItemsSummary(),
              style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Footer: Delivery/Pickup Info
            Row(
              children: [
                Icon(
                  offer.deliveryOption == 'self-delivery' ? LucideIcons.package : LucideIcons.truck,
                  size: 14,
                  color: AppColors.getTextSecondary(context),
                ),
                const SizedBox(width: 6),
                Text(
                  offer.deliveryOption == 'self-delivery' ? 'Self Delivery' : 'Pickup Requested',
                  style: AppTypography.body(context).copyWith(fontSize: 12, color: AppColors.getTextSecondary(context)),
                ),
                const Spacer(),
                if (offer.photoUrls.isNotEmpty)
                  Icon(LucideIcons.image, size: 16, color: AppColors.getTextSecondary(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getItemsSummary() {
    if (offer.items.isEmpty) return 'No items';
    final summary = offer.items.map((i) => '${i.quantity} ${i.unit} ${i.name}').join(', ');
    return summary;
  }

  Color _getStatusColor(OfferStatus status) {
    switch (status) {
      case OfferStatus.pending:
        return AppColors.mutedMustard;
      case OfferStatus.accepted:
        return AppColors.mintGreen;
      case OfferStatus.rejected:
        return AppColors.salmonOrange;
      case OfferStatus.completed:
        return AppColors.periwinkleBlue;
    }
  }
}
