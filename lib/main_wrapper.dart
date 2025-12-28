import 'package:flutter/material.dart';
import 'features/home/home_screen.dart';
import 'features/requests/browse_requests_screen.dart';
import 'features/discovery/orphanage_discovery_screen.dart';
import 'features/donations/my_donations_screen.dart';
import 'features/profile/profile_screen.dart';
import 'shared/widgets/floating_dock.dart';
import 'core/theme/app_colors.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const OrphanageDiscoveryScreen(),
    const MyDonationsScreen(),
    const ProfileScreen(),
  ];

  void _onDockTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: Stack(
        children: [
          // Main Content
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          
          // Persistent Dock
          FloatingDock(
            currentIndex: _currentIndex,
            onTap: _onDockTap,
          ),
        ],
      ),
    );
  }
}
