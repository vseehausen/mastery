import 'package:flutter/material.dart';

import '../../core/theme/color_tokens.dart';

/// Onboarding screen for first-time users
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

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

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    // Navigate to home screen
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          _buildWelcomePage(),
          _buildImportPage(),
          _buildSearchPage(),
          _buildSyncPage(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _currentPage > 0
                  ? () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  : null,
              child: const Text('Back'),
            ),
            Row(
              children: List.generate(
                4,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == index
                        ? context.masteryColors.accent
                        : context.masteryColors.border,
                  ),
                ),
              ),
            ),
            FilledButton(
              onPressed: _nextPage,
              child: Text(_currentPage == 3 ? 'Get Started' : 'Next'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return const _OnboardingPage(
      icon: Icons.auto_stories,
      title: 'Welcome to Mastery',
      description:
          'Your vocabulary learning companion. Import highlights from Kindle books and learn new words.',
    );
  }

  Widget _buildImportPage() {
    return const _OnboardingPage(
      icon: Icons.computer,
      title: 'Import via Desktop',
      description:
          'Connect your Kindle to your computer and use the Mastery desktop app to import vocabulary.',
    );
  }

  Widget _buildSearchPage() {
    return const _OnboardingPage(
      icon: Icons.search,
      title: 'Search & Browse',
      description:
          'Browse vocabulary by book, search across all words, and review your learning journey.',
    );
  }

  Widget _buildSyncPage() {
    return const _OnboardingPage(
      icon: Icons.cloud_sync,
      title: 'Sync to Cloud',
      description:
          'Your highlights sync automatically to the cloud, keeping your learning safe and accessible.',
    );
  }
}

/// Individual onboarding page widget
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 120, color: context.masteryColors.accent),
              const SizedBox(height: 32),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(
                      color: context.masteryColors.mutedForeground,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
