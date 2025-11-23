import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

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
      title: 'Easy Tasks',
      description: 'Complete simple tasks and earn real money instantly',
      color: const Color(0xFF6366F1),
    ),
    OnboardingPage(
      icon: '🎮',
      title: 'Fun Games',
      description: 'Play exciting games and win amazing rewards',
      color: const Color(0xFF8B5CF6),
    ),
    OnboardingPage(
      icon: '💰',
      title: 'Real Earnings',
      description: 'Withdraw your earnings directly to your bank account',
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
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppTheme.primaryColor
                              : AppTheme.primaryColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _goToNextPage,
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                      ),
                    ),
                  ),
                  if (_currentPage < _pages.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.space16),
                      child: TextButton(
                        onPressed: widget.onComplete,
                        child: const Text('Skip'),
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
    return Container(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Center(
              child: Text(page.icon, style: const TextStyle(fontSize: 60)),
            ),
          ),
          const SizedBox(height: AppTheme.space40),
          Text(
            page.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.space16),
          Text(
            page.description,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
