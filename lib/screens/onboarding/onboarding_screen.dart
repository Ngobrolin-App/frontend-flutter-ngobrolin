import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import 'onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 2;

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
    if (_currentPage < _numPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;

    // Navigate to login screen
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGeneral,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  context.tr('skip'),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  OnboardingPage(
                    image: 'assets/onboarding/onboarding_1.png',
                    title: context.tr('welcome_message'),
                    description: context.tr('welcome_description_1'),
                  ),
                  OnboardingPage(
                    image: 'assets/onboarding/onboarding_2.png',
                    title: context.tr('app_name'),
                    description: context.tr('welcome_description_2'),
                  ),
                ],
              ),
            ),

            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _numPages,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? AppColors.primary
                        : AppColors.lightGrey,
                  ),
                ),
              ),
            ),

            // Next/Start button
            Container(
              padding: const EdgeInsets.all(24),
              child: PrimaryButton(
                text: _currentPage == _numPages - 1
                    ? context.tr('start_now')
                    : context.tr('next'),
                onPressed: _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
