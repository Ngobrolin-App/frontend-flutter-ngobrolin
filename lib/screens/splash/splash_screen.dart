import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ngobrolin_app/core/viewmodels/auth/auth_view_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/socket_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

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

    try {
      if (!mounted) return;
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final socketProvider = Provider.of<SocketProvider>(
        context,
        listen: false,
      );
      await authViewModel.checkAuthStatus();

      if (authViewModel.authenticated &&
          socketProvider.connected &&
          socketProvider.authenticated) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
        }
      } else {
        final isFirstTime = await _isFirstTimeUser();
        if (!mounted) return;

        final targetRoute = isFirstTime
            ? AppRoutes.onboarding
            : AppRoutes.login;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(targetRoute, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    }
  }

  Future<bool> _isFirstTimeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool('onboarding_completed') ?? false);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGeneral,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/apps_logo/app-icon-ngobrolin-enhanced-transparent.png',
              width: 200,
              height: 200,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.chat_bubble_rounded,
                size: 100,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 48),
            const SpinKitDoubleBounce(color: AppColors.primary, size: 50.0),
          ],
        ),
      ),
    );
  }
}
