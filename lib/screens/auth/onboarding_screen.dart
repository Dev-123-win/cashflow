import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_assets.dart';
import '../../widgets/zen_card.dart';
import '../../widgets/scale_button.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      assetPath: AppAssets.onboardingEarn,
      title: 'Earn Real Money',
      description:
          'Complete tasks, play games, and watch ads to earn cash rewards.',
      details: ['Complete simple tasks', 'Play fun games', 'Watch short ads'],
      color: const Color(0xFF6366F1),
    ),
    OnboardingPage(
      assetPath: AppAssets.onboardingPlay,
      title: 'Daily Rewards',
      description:
          'Spin the wheel daily and build streaks for bonus rewards.',
      details: ['Daily free spin', 'Streak bonuses', 'Referral rewards'],
      color: const Color(0xFF8B5CF6),
    ),
    OnboardingPage(
      assetPath: AppAssets.onboardingWithdraw,
      title: 'Withdraw Anytime',
      description:
          'Reach ₹50 and withdraw directly to your UPI or bank account.',
      details: ['₹50 minimum', 'UPI/Bank transfer', '24-48hr processing'],
      color: const Color(0xFFEC4899),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPageContent(_pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? _pages[_currentPage].color
                              : AppTheme.textTertiary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),
                  ScaleButton(
                    onTap: _goToNextPage,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.space16,
                      ),
                      decoration: BoxDecoration(
                        color: _pages[_currentPage].color,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        boxShadow: [
                          BoxShadow(
                            color: _pages[_currentPage].color.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_currentPage < _pages.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.space16),
                      child: TextButton(
                        onPressed: widget.onComplete,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
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

  Widget _buildPageContent(OnboardingPage page) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppTheme.space24),
            Container(
              height: 280,
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.space24),
              child: SvgPicture.asset(page.assetPath, fit: BoxFit.contain),
            ),
            const SizedBox(height: AppTheme.space48),
            Text(
              page.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              page.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            // Show details list if available
            if (page.details != null && page.details!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space32),
              ZenCard(
                padding: const EdgeInsets.all(AppTheme.space16),
                color: page.color.withValues(alpha: 0.05),
                border: Border.all(
                  color: page.color.withValues(alpha: 0.2),
                  width: 1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...page.details!.map(
                      (detail) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.space8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: page.color,
                              size: 20,
                            ),
                            const SizedBox(width: AppTheme.space12),
                            Expanded(
                              child: Text(
                                detail,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String assetPath;
  final String title;
  final String description;
  final List<String>? details;
  final Color color;

  OnboardingPage({
    required this.assetPath,
    required this.title,
    required this.description,
    required this.color,
    this.details,
  });
}
