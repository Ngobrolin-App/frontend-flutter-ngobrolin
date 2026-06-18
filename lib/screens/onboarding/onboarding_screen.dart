import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import 'onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // SOLUSI: Kumpulkan data ke dalam List agar jumlah halaman dinamis dan terpusat
  late final List<Widget> _onboardingPages;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inisialisasi dilakukan di sini karena membutuhkan BuildContext untuk lokalisasi string
    _onboardingPages = [
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
    ];
  }

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
    if (_currentPage < _onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _onboardingPages.length;

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
                children: _onboardingPages,
              ),
            ),

            // OPTIMASI: Page indicator otomatis menyesuaikan panjang data list aktual
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                totalPages,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index
                      ? 16
                      : 8, // Efek modern: memanjang saat aktif
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
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
                text: _currentPage == totalPages - 1
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
