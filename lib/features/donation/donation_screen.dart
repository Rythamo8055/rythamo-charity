import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/bento_card.dart';
import '../../shared/widgets/input_field.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/doodle.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  bool _isSearching = false;
  bool _driverFound = false;

  void _handleRequestPickup() async {
    setState(() {
      _isSearching = true;
    });

    // Mock network delay
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isSearching = false;
        _driverFound = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepCharcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("REQUEST PICKUP", style: AppTypography.sectionHeader(context)),
            const SizedBox(height: 32),

            if (!_driverFound) ...[
              // Input Form
              const InputField(hintText: "Pickup Location"),
              const SizedBox(height: 16),
              const InputField(hintText: "What are you donating?"),
              const SizedBox(height: 16),
              const InputField(hintText: "Notes for driver"),
              
              const Spacer(),

              // Chat Bubble Insight
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.lighterGraphite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.mintGreen,
                      radius: 20,
                      child: Icon(LucideIcons.bot, color: AppColors.darkCharcoalText, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Orphanage 'Hope House' is low on rice and blankets.",
                            style: AppTypography.body(context).copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.deepCharcoal,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              "Donate Rice",
                              style: AppTypography.button(context).copyWith(
                                color: AppColors.salmonOrange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: PillButton(
                  text: _isSearching ? "FINDING DRIVER..." : "REQUEST PICKUP",
                  onPressed: _isSearching ? () {} : _handleRequestPickup,
                  icon: _isSearching ? LucideIcons.loader2 : LucideIcons.car,
                ),
              ),
            ] else ...[
              // Driver Found State
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Doodle(color: AppColors.mintGreen, size: 200),
                      const SizedBox(height: 32),
                      Text(
                        "DRIVER FOUND!",
                        style: AppTypography.bigData(context).copyWith(fontSize: 32),
                      ),
                      const SizedBox(height: 16),
                      BentoCard(
                        backgroundColor: AppColors.lighterGraphite,
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.white,
                            child: Icon(LucideIcons.user, color: AppColors.deepCharcoal),
                          ),
                          title: Text("Michael is 5 mins away", style: AppTypography.button(context).copyWith(color: Colors.white)),
                          subtitle: Text("Toyota Prius • ABC 123", style: AppTypography.body(context).copyWith(color: Colors.white70, fontSize: 14)),
                          trailing: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.salmonOrange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.phone, color: AppColors.deepCharcoal, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
