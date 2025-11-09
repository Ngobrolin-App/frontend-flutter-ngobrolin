import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Simulate loading time
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Inisialisasi status auth (ambil token dari SharedPreferences)
    await authProvider.init();

    // Check if user is authenticated
    if (authProvider.authenticated) {
      // Navigate to main screen if authenticated
      Navigator.of(context).pushReplacementNamed(AppRoutes.main);
    } else {
      // Check if first time user
      final isFirstTime = await _isFirstTimeUser();

      if (isFirstTime) {
        // Navigate to onboarding for first time users
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      } else {
        // Navigate to login for returning users
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    }
  }

  Future<bool> _isFirstTimeUser() async {
    // Implement first time user check with SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    // Jika belum ada flag onboarding_completed, anggap first-time (true)
    final completed = prefs.getBool('onboarding_completed') ?? false;
    return !completed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGeneral,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/apps_logo/app-icon-ngobrolin-enhanced-transparent.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 48),
            // Loading indicator
            const SpinKitDoubleBounce(color: AppColors.primary, size: 50.0),
          ],
        ),
      ),
    );
  }
}
