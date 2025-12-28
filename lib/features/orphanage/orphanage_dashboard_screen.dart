import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/donation_service.dart';
import '../../core/services/orphanage_service.dart';
import '../../core/models/donation_offer_model.dart';
import '../../core/models/orphanage_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'review_offers_screen.dart';
import 'manage_requests_screen.dart';
import 'orphanage_profile_setup_screen.dart';

class OrphanageDashboardScreen extends StatefulWidget {
  const OrphanageDashboardScreen({super.key});

  @override
  State<OrphanageDashboardScreen> createState() => _OrphanageDashboardScreenState();
}

class _OrphanageDashboardScreenState extends State<OrphanageDashboardScreen> {
  final DonationService _donationService = DonationService();
  final OrphanageService _orphanageService = OrphanageService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  
  Orphanage? _orphanageProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadOrphanageProfile();
  }

  Future<void> _loadOrphanageProfile() async {
    if (_currentUser == null) return;
    try {
      // In a real app, we'd query by userId. For now, we'll assume one exists or handle null.
      // Since we don't have a direct getByUserId in the service yet that returns a single object easily without stream,
      // we'll just fetch all and filter (inefficient but works for prototype) or add a method.
      // Actually, let's just show a "Setup Profile" button if we can't find it.
      
      // For now, let's just use a dummy ID if we can't find one, or prompt to create.
      setState(() => _isLoadingProfile = false);
    } catch (e) {
      setState(() => _isLoadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) return const Center(child: Text("Please log in"));

    // We need the orphanage ID to fetch offers. 
    // For this prototype, let's assume the user has one orphanage profile.
    // We'll use a StreamBuilder to find it.
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: StreamBuilder<Orphanage?>(
          stream: _orphanageService.getMyOrphanageStream(_currentUser!.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.mintGreen));
            }

            final myOrphanage = snapshot.data;

            final bool hasProfile = myOrphanage != null;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Dashboard", style: AppTypography.sectionHeader(context)),
                          Text(
                            hasProfile ? myOrphanage!.name : "Welcome Admin",
                            style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context)),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        backgroundColor: AppColors.mintGreen,
                        child: Text(
                          hasProfile ? myOrphanage!.name[0] : "A",
                          style: const TextStyle(color: AppColors.darkCharcoalText, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  if (!hasProfile)
                    _buildSetupCard(context)
                  else ...[
                    // Stats Grid
                    _buildStatsGrid(myOrphanage!.id),
                    const SizedBox(height: 32),

                    // Quick Actions
                    Text("QUICK ACTIONS", style: AppTypography.sectionHeader(context).copyWith(fontSize: 14)),
                    const SizedBox(height: 16),
                    _buildActionTile(
                      icon: LucideIcons.inbox,
                      title: "Review Donations",
                      subtitle: "Check pending offers",
                      color: AppColors.mintGreen,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ReviewOffersScreen(orphanageId: myOrphanage.id)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActionTile(
                      icon: LucideIcons.listPlus,
                      title: "Manage Requests",
                      subtitle: "Update urgent needs",
                      color: AppColors.periwinkleBlue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManageRequestsScreen(
                            orphanageId: myOrphanage.id,
                            orphanageName: myOrphanage.name,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActionTile(
                      icon: LucideIcons.settings,
                      title: "Profile Settings",
                      subtitle: "Update info & photos",
                      color: AppColors.getTextPrimary(context),
                      onTap: () {
                        // TODO: Navigate to Profile Edit
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSetupCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.salmonOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.salmonOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.salmonOrange),
          const SizedBox(height: 16),
          Text(
            "Profile Incomplete",
            style: AppTypography.button(context).copyWith(fontSize: 18, color: AppColors.salmonOrange),
          ),
          const SizedBox(height: 8),
          Text(
            "Please set up your orphanage profile to start receiving donations.",
            textAlign: TextAlign.center,
            style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrphanageProfileSetupScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.salmonOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Setup Profile"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(String orphanageId) {
    return StreamBuilder<List<DonationOffer>>(
      stream: _donationService.getOrphanageOffers(orphanageId),
      builder: (context, snapshot) {
        final offers = snapshot.data ?? [];
        final pending = offers.where((o) => o.status == OfferStatus.pending).length;
        final completed = offers.where((o) => o.status == OfferStatus.completed).length;
        final accepted = offers.where((o) => o.status == OfferStatus.accepted).length;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard("Pending", pending.toString(), AppColors.mutedMustard),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard("Active", accepted.toString(), AppColors.mintGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard("History", completed.toString(), AppColors.periwinkleBlue),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTypography.sectionHeader(context).copyWith(fontSize: 24, color: color)),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.body(context).copyWith(fontSize: 12, color: AppColors.getTextSecondary(context))),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.button(context)),
                  Text(subtitle, style: AppTypography.body(context).copyWith(fontSize: 12, color: AppColors.getTextSecondary(context))),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: AppColors.getTextTertiary(context), size: 20),
          ],
        ),
      ),
    );
  }
}
