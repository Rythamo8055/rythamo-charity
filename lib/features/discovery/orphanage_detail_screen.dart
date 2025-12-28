import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/orphanage_service.dart';
import '../../core/models/orphanage_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/pill_button.dart';
import '../donations/create_offer_screen.dart';

class OrphanageDetailScreen extends StatefulWidget {
  final String orphanageId;

  const OrphanageDetailScreen({super.key, required this.orphanageId});

  @override
  State<OrphanageDetailScreen> createState() => _OrphanageDetailScreenState();
}

class _OrphanageDetailScreenState extends State<OrphanageDetailScreen> {
  final OrphanageService _orphanageService = OrphanageService();
  Orphanage? _orphanage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrphanageDetails();
  }

  Future<void> _loadOrphanageDetails() async {
    final orphanage = await _orphanageService.getOrphanageById(widget.orphanageId);
    setState(() {
      _orphanage = orphanage;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.getBackground(context),
        body: const Center(child: CircularProgressIndicator(color: AppColors.mintGreen)),
      );
    }

    if (_orphanage == null) {
      return Scaffold(
        backgroundColor: AppColors.getBackground(context),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            "Orphanage not found",
            style: AppTypography.button(context).copyWith(color: AppColors.getTextSecondary(context)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.getCardBackground(context),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.getOverlay(context, opacity: 0.8),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageCarousel(),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and verified badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _orphanage!.name,
                          style: AppTypography.bigData(context).copyWith(fontSize: 32, color: AppColors.getTextPrimary(context)),
                        ),
                      ),
                      if (_orphanage!.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.mintGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppColors.mintGreen),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.checkCircle, size: 16, color: AppColors.mintGreen),
                              const SizedBox(width: 6),
                              Text(
                                'VERIFIED',
                                style: AppTypography.button(context).copyWith(fontSize: 12, color: AppColors.mintGreen),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          LucideIcons.users,
                          '${_orphanage!.currentOccupancy}/${_orphanage!.capacity}',
                          'Capacity',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          LucideIcons.alertCircle,
                          _orphanage!.urgentNeeds.length.toString(),
                          'Urgent Needs',
                          color: _orphanage!.urgentNeeds.isNotEmpty ? AppColors.salmonOrange : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // About Section
                  Text("ABOUT", style: AppTypography.sectionHeader(context)),
                  const SizedBox(height: 12),
                  Text(
                    _orphanage!.description,
                    style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context), height: 1.6),
                  ),
                  const SizedBox(height: 24),

                  // Contact Information
                  Text("CONTACT", style: AppTypography.sectionHeader(context)),
                  const SizedBox(height: 12),
                  _buildContactItem(LucideIcons.mapPin, _orphanage!.address),
                  const SizedBox(height: 8),
                  _buildContactItem(LucideIcons.phone, _orphanage!.phone),
                  const SizedBox(height: 8),
                  _buildContactItem(LucideIcons.mail, _orphanage!.email),
                  const SizedBox(height: 24),

                  // Urgent Needs
                  if (_orphanage!.urgentNeeds.isNotEmpty) ...[
                    Text("URGENT NEEDS", style: AppTypography.sectionHeader(context)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _orphanage!.urgentNeeds.map((need) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.salmonOrange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppColors.salmonOrange),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.heartHandshake, size: 14, color: AppColors.salmonOrange),
                              const SizedBox(width: 6),
                              Text(
                                need,
                                style: AppTypography.body(context).copyWith(fontSize: 12, color: AppColors.getTextPrimary(context)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Make Donation Offer Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: PillButton(
                      text: "MAKE DONATION OFFER",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateOfferScreen(
                              orphanageId: widget.orphanageId,
                              orphanageName: _orphanage!.name,
                            ),
                          ),
                        );
                      },
                      color: AppColors.mintGreen,
                      textColor: AppColors.darkCharcoalText,
                      icon: LucideIcons.gift,
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    if (_orphanage!.photoUrls.isEmpty) {
      return Container(
        color: AppColors.getCardBackground(context),
        child: Center(
          child: Icon(LucideIcons.building, size: 80, color: AppColors.getTextTertiary(context)),
        ),
      );
    }

    return PageView.builder(
      itemCount: _orphanage!.photoUrls.length,
      itemBuilder: (context, index) {
        return Image.network(
          _orphanage!.photoUrls[index],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.getCardBackground(context),
              child: Center(
                child: Icon(LucideIcons.building, size: 80, color: AppColors.getTextTertiary(context)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color ?? AppColors.mintGreen),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.bigData(context).copyWith(fontSize: 24, color: color ?? AppColors.getTextPrimary(context)),
          ),
          Text(
            label,
            style: AppTypography.body(context).copyWith(fontSize: 10, color: AppColors.getTextSecondary(context)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.getTextSecondary(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body(context).copyWith(fontSize: 14, color: AppColors.getTextPrimary(context)),
            ),
          ),
        ],
      ),
    );
  }
}
