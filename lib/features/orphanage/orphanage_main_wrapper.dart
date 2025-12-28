import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/floating_dock.dart';
import '../profile/profile_screen.dart';
import 'orphanage_dashboard_screen.dart';
import 'manage_requests_screen.dart';

class OrphanageMainWrapper extends StatefulWidget {
  const OrphanageMainWrapper({super.key});

  @override
  State<OrphanageMainWrapper> createState() => _OrphanageMainWrapperState();
}

class _OrphanageMainWrapperState extends State<OrphanageMainWrapper> {
  int _currentIndex = 0;
  String _orphanageName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrphanageDetails();
  }

  Future<void> _loadOrphanageDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted) {
          setState(() {
            _orphanageName = doc.data()?['displayName'] ?? 'My Orphanage';
            _isLoading = false;
          });
        }
      } catch (e) {
        print("Error loading orphanage details: $e");
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onDockTap(int index) {
    setState(() {
      _currentIndex = index;
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

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    final List<Widget> screens = [
      const OrphanageDashboardScreen(),
      ManageRequestsScreen(orphanageId: userId, orphanageName: _orphanageName),
      const ProfileScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // If not on dashboard (index 0), return to dashboard
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          // On dashboard, show exit confirmation
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.getCardBackground(context),
              title: Text('Exit App?', style: AppTypography.sectionHeader(context)),
              content: Text('Do you want to exit the app?', style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context))),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel', style: AppTypography.button(context).copyWith(color: AppColors.getTextSecondary(context))),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Exit', style: TextStyle(color: AppColors.salmonOrange)),
                ),
              ],
            ),
          );
          
          if (shouldExit == true && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.getBackground(context),
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
            
            // Custom Dock for Orphanage Admin
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.getCardBackground(context).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIcon(LucideIcons.layoutDashboard, 0),
                      const SizedBox(width: 32),
                      _buildIcon(LucideIcons.listTodo, 1),
                      const SizedBox(width: 32),
                      _buildIcon(LucideIcons.user, 2),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onDockTap(index),
      child: Icon(
        icon,
        color: isSelected ? AppColors.periwinkleBlue : AppColors.getTextSecondary(context).withValues(alpha: 0.5),
        size: 28,
      ),
    );
  }
}
