import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/services/onboarding_service.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/page_indicator.dart';
import '../../utils/page_transitions.dart';
import '../auth/welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingService _onboardingService = OnboardingService();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'image': 'assets/mascot/reading.json',
      'title': 'Make a Difference',
      'description': 'Connect with orphanages and help children in need. Every contribution counts.',
      'color': AppColors.mintGreen,
    },
    {
      'image': 'assets/mascot/teaching.json',
      'title': 'Easy Donations',
      'description': 'Browse requests, choose what matters to you, and donate with just a few taps.',
      'color': AppColors.salmonOrange,
    },
    {
      'image': 'assets/mascot/celebrating.json',
      'title': 'Build Community',
      'description': 'Join a community of donors and orphanages working together for a better future.',
      'color': AppColors.periwinkleBlue,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _completeOnboarding() async {
    await _onboardingService.setOnboardingComplete();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageTransitions.slideRight(const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: Stack(
          children: [
            // Page View
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return OnboardingPage(
                  imagePath: page['image'],
                  title: page['title'],
                  description: page['description'],
                  accentColor: page['color'],
                );
              },
            ),

            // Skip Button (hidden on last page)
            if (_currentPage < _pages.length - 1)
              Positioned(
                top: 16,
                right: 16,
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    'Skip',
                    style: AppTypography.body(context).copyWith(
                      color: AppColors.getTextSecondary(context),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

            // Bottom Section with Indicator and Button
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Page Indicator
                  PageIndicator(
                    currentPage: _currentPage,
                    totalPages: _pages.length,
                  ),

                  const SizedBox(height: 40),

                  // Next/Get Started Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pages[_currentPage]['color'],
                          foregroundColor: AppColors.darkCharcoalText,
                          elevation: 8,
                          shadowColor: _pages[_currentPage]['color']
                              .withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _pages.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                                style: AppTypography.button(context).copyWith(
                                  fontSize: 18,
                                  color: AppColors.deepCharcoal,
                                ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage == _pages.length - 1
                                  ? LucideIcons.check
                                  : LucideIcons.arrowRight,
                              size: 20,
                              color: AppColors.darkCharcoalText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
