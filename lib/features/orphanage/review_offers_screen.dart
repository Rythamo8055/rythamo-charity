import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/donation_service.dart';
import '../../core/models/donation_offer_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/donation_offer_card.dart';

class ReviewOffersScreen extends StatelessWidget {
  final String orphanageId;

  const ReviewOffersScreen({super.key, required this.orphanageId});

  @override
  Widget build(BuildContext context) {
    final donationService = DonationService();

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Donation Offers", style: AppTypography.sectionHeader(context)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<DonationOffer>>(
        stream: donationService.getOrphanageOffers(orphanageId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.mintGreen));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: AppColors.getTextPrimary(context))));
          }

          final offers = snapshot.data ?? [];
          final pendingOffers = offers.where((o) => o.status == OfferStatus.pending).toList();
          final otherOffers = offers.where((o) => o.status != OfferStatus.pending).toList();

          if (offers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.inbox, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    "No offers yet",
                    style: AppTypography.button(context).copyWith(color: AppColors.getTextSecondary(context)),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (pendingOffers.isNotEmpty) ...[
                Text("PENDING REVIEW", style: AppTypography.sectionHeader(context).copyWith(fontSize: 14, color: AppColors.mutedMustard)),
                const SizedBox(height: 12),
                ...pendingOffers.map((offer) => DonationOfferCard(
                  offer: offer,
                  showDonorName: true,
                  showOrphanageName: false,
                  onTap: () => _showOfferDetails(context, offer),
                )),
                const SizedBox(height: 24),
              ],

              if (otherOffers.isNotEmpty) ...[
                Text("HISTORY", style: AppTypography.sectionHeader(context).copyWith(fontSize: 14, color: AppColors.getTextSecondary(context))),
                const SizedBox(height: 12),
                ...otherOffers.map((offer) => DonationOfferCard(
                  offer: offer,
                  showDonorName: true,
                  showOrphanageName: false,
                  onTap: () => _showOfferDetails(context, offer),
                )),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showOfferDetails(BuildContext context, DonationOffer offer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getSurface(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _OfferDetailsSheet(offer: offer),
    );
  }
}

class _OfferDetailsSheet extends StatefulWidget {
  final DonationOffer offer;

  const _OfferDetailsSheet({required this.offer});

  @override
  State<_OfferDetailsSheet> createState() => _OfferDetailsSheetState();
}

class _OfferDetailsSheetState extends State<_OfferDetailsSheet> {
  final DonationService _donationService = DonationService();
  bool _isProcessing = false;

  Future<void> _updateStatus(OfferStatus status, [String? reason]) async {
    setState(() => _isProcessing = true);
    try {
      if (status == OfferStatus.accepted) {
        await _donationService.acceptOffer(widget.offer.id);
      } else if (status == OfferStatus.rejected) {
        await _donationService.rejectOffer(widget.offer.id, reason ?? 'No reason provided');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Offer Details", style: AppTypography.sectionHeader(context)),
              IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Donor Info
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.getCardBackground(context),
                child: Icon(LucideIcons.user, color: AppColors.getTextPrimary(context)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.offer.donorName, style: AppTypography.button(context)),
                  Text("Donor", style: AppTypography.body(context).copyWith(fontSize: 12, color: AppColors.getTextSecondary(context))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Items
          Text("ITEMS", style: AppTypography.button(context).copyWith(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 8),
          ...widget.offer.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(LucideIcons.package, size: 16, color: AppColors.mintGreen),
                const SizedBox(width: 8),
                Text(
                  "${item.quantity} ${item.unit} ${item.name}",
                  style: AppTypography.body(context),
                ),
              ],
            ),
          )),
          const SizedBox(height: 24),

          // Photos
          if (widget.offer.photoUrls.isNotEmpty) ...[
            Text("PHOTOS", style: AppTypography.button(context).copyWith(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.offer.photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.offer.photoUrls[index],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Actions
          if (widget.offer.status == OfferStatus.pending) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : () => _updateStatus(OfferStatus.rejected, "Not needed right now"),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.salmonOrange),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("REJECT", style: AppTypography.button(context).copyWith(color: AppColors.salmonOrange)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : () => _updateStatus(OfferStatus.accepted),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mintGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("ACCEPT", style: AppTypography.button(context).copyWith(color: AppColors.darkCharcoalText)),
                  ),
                ),
              ],
            ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.deepCharcoal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Status: ${widget.offer.status.name.toUpperCase()}",
                textAlign: TextAlign.center,
                style: AppTypography.button(context).copyWith(color: AppColors.getTextSecondary(context)),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
