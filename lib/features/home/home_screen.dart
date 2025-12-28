import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/services/missions_service.dart';
import '../../core/services/donation_service.dart';
import '../../core/services/orphanage_service.dart';
import '../../core/services/request_service.dart';
import '../../core/models/donation_offer_model.dart';
import '../../core/models/orphanage_model.dart';
import '../../core/models/item_request_model.dart';

import 'package:lottie/lottie.dart';
import '../../shared/widgets/bento_card.dart';
import '../../shared/widgets/pulse_card.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/error_state_widget.dart';
import '../requests/browse_requests_screen.dart';
import '../donations/create_offer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _user = FirebaseAuth.instance.currentUser;
  final _donationService = DonationService();
  final _orphanageService = OrphanageService();
  final _requestService = RequestService();

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 60, 16, 120 + MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            // Greeting Section
            Row(
              children: [
                Lottie.asset(
                  'assets/mascot/greeting.json',
                  height: 60,
                  width: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, color: Colors.red);
                  },
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "HELLO, ${_user?.displayName?.split(' ').first ?? 'FRIEND'}!",
                      style: AppTypography.sectionHeader(context),
                    ),
                    Text(
                      "Ready to make an impact?",
                      style: AppTypography.body(context).copyWith(
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 24),

            // Hero Card - Total Donations
            StreamBuilder<List<DonationOffer>>(
              stream: _donationService.getUserDonations(_user!.uid),
              builder: (context, snapshot) {
                int totalItems = 0;
                if (snapshot.hasData) {
                  for (var offer in snapshot.data!) {
                    if (offer.status == OfferStatus.completed) {
                      for (var item in offer.items) {
                        totalItems += item.quantity;
                      }
                    }
                  }
                }

                return BentoCard(
                  backgroundColor: AppColors.periwinkleBlue,
                  height: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.heart, color: AppColors.darkCharcoalText),
                          const SizedBox(width: 8),
                          Text(
                            "TOTAL DONATIONS",
                            style: AppTypography.sectionHeader(context).copyWith(
                              color: AppColors.darkCharcoalText.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "$totalItems Items",
                        style: AppTypography.bigData(context).copyWith(
                          color: AppColors.darkCharcoalText,
                        ),
                      ),
                      Text(
                        "Donated to those in need",
                        style: AppTypography.body(context).copyWith(
                          color: AppColors.darkCharcoalText,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Quick Donate Section
            Text("QUICK DONATE", style: AppTypography.sectionHeader(context)),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  _buildQuickDonateCard(context, "Food", LucideIcons.utensils, AppColors.salmonOrange),
                  const SizedBox(width: 12),
                  _buildQuickDonateCard(context, "Clothes", LucideIcons.shirt, AppColors.periwinkleBlue),
                  const SizedBox(width: 12),
                  _buildQuickDonateCard(context, "Books", LucideIcons.book, AppColors.mintGreen),
                  const SizedBox(width: 12),
                  _buildQuickDonateCard(context, "Toys", LucideIcons.gamepad2, AppColors.mutedMustard),
                  const SizedBox(width: 12),
                  _buildQuickDonateCard(context, "Medical", LucideIcons.pill, Colors.pinkAccent),
                  const SizedBox(width: 12),
                  _buildQuickDonateCard(context, "Other", LucideIcons.box, Colors.teal),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Masonry Grid
            StaggeredGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                // Partner Orphanages
                StreamBuilder<List<Orphanage>>(
                  stream: _orphanageService.getAllOrphanages(),
                  builder: (context, snapshot) {
                    final orphanages = snapshot.data ?? [];
                    return StaggeredGridTile.count(
                      crossAxisCellCount: 1,
                      mainAxisCellCount: 1,
                      child: BentoCard(
                        backgroundColor: AppColors.salmonOrange,
                        onTap: () {
                          _showPartnerOrphanagesModal(context, orphanages);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(LucideIcons.home, color: AppColors.darkCharcoalText),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${orphanages.length}",
                                  style: AppTypography.bigData(context).copyWith(
                                    fontSize: 40,
                                    color: AppColors.darkCharcoalText,
                                  ),
                                ),
                                Text(
                                  "Orphanages",
                                  style: AppTypography.body(context).copyWith(
                                    color: AppColors.darkCharcoalText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Active Requests
                StreamBuilder<List<ItemRequest>>(
                  stream: _requestService.getActiveRequests(),
                  builder: (context, snapshot) {
                    final requests = snapshot.data ?? [];
                    return StaggeredGridTile.count(
                      crossAxisCellCount: 1,
                      mainAxisCellCount: 1,
                      child: BentoCard(
                        backgroundColor: AppColors.mutedMustard,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const BrowseRequestsScreen()),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(LucideIcons.activity, color: AppColors.darkCharcoalText),
                            Text(
                              "${requests.length}\nActive\nRequests",
                              style: AppTypography.button(context).copyWith(fontSize: 18, color: AppColors.darkCharcoalText),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Next Pickup
                StreamBuilder<List<DonationOffer>>(
                  stream: _donationService.getUserDonations(_user!.uid),
                  builder: (context, snapshot) {
                    DonationOffer? nextPickup;
                    if (snapshot.hasData) {
                      final pickups = snapshot.data!
                          .where((o) => 
                            (o.status == OfferStatus.pending || o.status == OfferStatus.accepted) && 
                            o.deliveryOption == 'pickup-requested'
                          )
                          .toList();
                      pickups.sort((a, b) => a.preferredPickupTime.compareTo(b.preferredPickupTime));
                      if (pickups.isNotEmpty) {
                        nextPickup = pickups.first;
                      }
                    }

                    return StaggeredGridTile.count(
                      crossAxisCellCount: 2,
                      mainAxisCellCount: 0.8,
                      child: BentoCard(
                        backgroundColor: AppColors.getCardBackground(context),
                        onTap: nextPickup != null ? () {
                          _showPickupDetailsModal(context, nextPickup!);
                        } : null,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("NEXT PICKUP", style: AppTypography.sectionHeader(context)),
                                  const SizedBox(height: 8),
                                  if (nextPickup != null) ...[
                                    Text(
                                      DateFormat('MMM d, h:mm a').format(nextPickup.preferredPickupTime),
                                      style: AppTypography.button(context).copyWith(color: AppColors.getTextPrimary(context)),
                                    ),
                                    Text(
                                      nextPickup.status == OfferStatus.accepted ? "Driver Assigned" : "Pending Driver",
                                      style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context)),
                                    ),
                                  ] else
                                    Text("No scheduled pickups", style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context))),
                                ],
                              ),
                            ),
                            const Icon(LucideIcons.car, color: AppColors.mintGreen, size: 40),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // THE PULSE Section
            Text("THE PULSE", style: AppTypography.sectionHeader(context)),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: StreamBuilder<QuerySnapshot>(
                stream: MissionsService().getRecentActivity(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ErrorStateWidget(
                      message: "Could not load updates",
                      onRetry: () => setState(() {}),
                      retryText: "RETRY",
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: AppColors.mintGreen));
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const EmptyStateWidget(
                      lottiePath: 'assets/mascot/sleeping.json',
                      message: "No recent activity",
                      height: 100,
                    );
                  }

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final category = data['category'] as String? ?? 'Others';
                      
                      Color accentColor;
                      switch (category) {
                        case 'Food': accentColor = AppColors.periwinkleBlue; break;
                        case 'Clothes': accentColor = AppColors.salmonOrange; break;
                        case 'Books': accentColor = AppColors.mintGreen; break;
                        case 'Toys': accentColor = AppColors.mutedMustard; break;
                        default: accentColor = AppColors.mintGreen;
                      }

                      return PulseCard(
                        title: data['title'] ?? 'Update',
                        time: data['time'] ?? 'Just now',
                        accentColor: accentColor,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDonateCard(BuildContext context, String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateOfferScreen(initialCategory: title),
          ),
        );
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.getOverlay(context, opacity: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.button(context).copyWith(fontSize: 12, color: AppColors.getTextPrimary(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showPartnerOrphanagesModal(BuildContext context, List<Orphanage> orphanages) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getSurface(context),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("PARTNER ORPHANAGES", style: AppTypography.sectionHeader(context)),
            const SizedBox(height: 16),
            Expanded(
              child: orphanages.isEmpty 
                ? const EmptyStateWidget(
                    lottiePath: 'assets/mascot/sad.json',
                    message: "No partners yet",
                    subMessage: "We are working on onboarding more orphanages.",
                    height: 150,
                  )
                : ListView.builder(
                    itemCount: orphanages.length,
                    itemBuilder: (context, index) {
                      final orphanage = orphanages[index];
                      return ListTile(
                        title: Text(orphanage.name, style: AppTypography.button(context).copyWith(color: AppColors.getTextPrimary(context))),
                        subtitle: Text("${orphanage.currentOccupancy} Children • ${orphanage.address}", style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context))),
                        trailing: Icon(LucideIcons.chevronRight, color: AppColors.getTextPrimary(context)),
                        onTap: () {
                           // TODO: Navigate to Orphanage Details
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPickupDetailsModal(BuildContext context, DonationOffer offer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getSurface(context),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("PICKUP DETAILS", style: AppTypography.sectionHeader(context)),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.mintGreen,
                  child: Icon(LucideIcons.user, color: AppColors.darkCharcoalText),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Driver Assigned", style: AppTypography.button(context).copyWith(color: AppColors.getTextPrimary(context), fontSize: 20)),
                    Text("Status: ${offer.status.name.toUpperCase()}", style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Time: ${DateFormat('h:mm a').format(offer.preferredPickupTime)}", style: AppTypography.bigData(context).copyWith(fontSize: 24)),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.salmonOrange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.phone, color: AppColors.darkCharcoalText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
