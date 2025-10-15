import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

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
    // TODO: Implement first time user check with SharedPreferences
    // For now, always return true to show onboarding
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/apps_logo/app-icon-ngobrolin-enhanced-transparent.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 24),
            // App name
            const Text(
              'Ngobrolin',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            const SpinKitDoubleBounce(
              color: Colors.white,
              size: 50.0,
            ),
          ],
        ),
      ),
    );
  }
}