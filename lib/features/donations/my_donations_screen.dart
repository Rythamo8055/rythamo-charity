import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/donation_service.dart';
import '../../core/models/donation_offer_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/donation_offer_card.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/error_state_widget.dart';
import 'create_offer_screen.dart';

class MyDonationsScreen extends StatelessWidget {
  const MyDonationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final donationService = DonationService();

    if (user == null) {
      return const Center(child: Text("Please log in to view donations"));
    }

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("MY DONATIONS", style: AppTypography.sectionHeader(context)),
                  Text(
                    "Track your contributions",
                    style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context), fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<DonationOffer>>(
                stream: donationService.getUserDonations(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget(message: "Fetching your donations...");
                  }

                  if (snapshot.hasError) {
                    return ErrorStateWidget(
                      message: "Could not load donations",
                      onRetry: () => (context as Element).markNeedsBuild(),
                    );
                  }

                  final offers = snapshot.data ?? [];

                  if (offers.isEmpty) {
                    return const EmptyStateWidget(
                      lottiePath: 'assets/mascot/idle.json',
                      message: "No donations yet",
                      subMessage: "Start by discovering orphanages nearby",
                      height: 200,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: offers.length,
                    itemBuilder: (context, index) {
                      return DonationOfferCard(
                        offer: offers[index],
                        showOrphanageName: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateOfferScreen(
                                existingOffer: offers[index],
                              ),
                            ),
                          );
                        },
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
}
