import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
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
      icon: '🎯',
      title: 'Complete Simple Tasks',
      description:
          'Earn ₹0.10-₹0.20 per task by completing surveys, social shares, and more. Fast & easy!',
      details: ['📝 Surveys & Reviews', '🔗 Social Shares', '⭐ App Ratings'],
      color: const Color(0xFF6366F1),
    ),
    OnboardingPage(
      icon: '🎮',
      title: 'Play & Earn Games',
      description:
          'Win up to ₹0.08 per game. Play Tic-Tac-Toe, Memory Match, and more. 30-min cooldown.',
      details: ['🎯 Tic-Tac-Toe', '🧩 Memory Match', '❓ Quiz Games'],
      color: const Color(0xFF8B5CF6),
    ),
    OnboardingPage(
      icon: '🎰',
      title: 'Spin & Win',
      description:
          'Spin the daily wheel once per day for random rewards between ₹0.05-₹1.00. Free spins!',
      details: ['Daily Free Spin', 'Random Rewards', '💎 Bonus Multipliers'],
      color: const Color(0xFFFFB800),
    ),
    OnboardingPage(
      icon: '📺',
      title: 'Watch Ads & Earn',
      description:
          'Watch short video ads and earn ₹0.02-₹0.05 per ad. Up to 15 ads per day.',
      details: ['30-sec Videos', 'Instant Credit', 'No Spam'],
      color: const Color(0xFF00D9C0),
    ),
    OnboardingPage(
      icon: '💰',
      title: 'Withdraw Your Money',
      description:
          'Reach ₹50 minimum balance and withdraw directly to your UPI or bank account.',
      details: ['₹50 Minimum', '24-48hr Processing', 'Real Money'],
      color: const Color(0xFFEC4899),
    ),
    OnboardingPage(
      icon: '📈',
      title: 'Daily Limit & Rewards',
      description:
          'Max earning: ₹1.50/day. Referrals: Earn ₹2 per friend. Streaks: Bonus rewards!',
      details: ['₹1.50/Day Cap', '👥 Referral Bonus', '🔥 Streak Multipliers'],
      color: const Color(0xFF00E676),
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
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: page.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: page.color.withValues(alpha: 0.2),
                    blurRadius: 32,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Text(page.icon, style: const TextStyle(fontSize: 80)),
              ),
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
  final String icon;
  final String title;
  final String description;
  final List<String>? details;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.details,
  });
}
