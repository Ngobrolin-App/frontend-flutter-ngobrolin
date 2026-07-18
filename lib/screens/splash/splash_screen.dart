import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ngobrolin_app/core/viewmodels/auth/auth_view_model.dart';
import 'package:provider/provider.dart';
import '../../core/providers/socket_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import 'dart:developer' as developer;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late SocketProvider _socketProvider;
  late Function(dynamic) _socketAuthenticatedHandler;
  late Function(dynamic) _socketAuthErrorHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }

  @override
  void dispose() {
    try {
      _socketProvider.off('authenticated', _socketAuthenticatedHandler);
      _socketProvider.off('auth_error', _socketAuthErrorHandler);
    } catch (e) {
      developer.log('SplashScreen - dispose() error: $e', name: 'SplashScreen');
    }
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      if (!mounted) return;

      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      _socketProvider = Provider.of<SocketProvider>(context, listen: false);

      final isAuthValid = await authViewModel.checkAuthStatus();

      developer.log(
        'SplashScreen isAuthValid: $isAuthValid',
        name: 'SplashScreen',
      );

      if (!mounted) return;

      if (!isAuthValid) {
        developer.log('SplashScreen - API Auth failed. Redirecting to Login.');
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        return;
      }

      await _socketProvider.init();

      _socketAuthenticatedHandler = (data) {
        developer.log('SplashScreen - Socket Authenticated');
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
        }
      };

      _socketAuthErrorHandler = (data) {
        developer.log('SplashScreen - Socket Auth Error: $data');
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        }
      };

      _socketProvider.on('authenticated', _socketAuthenticatedHandler);
      _socketProvider.on('auth_error', _socketAuthErrorHandler);
    } catch (e) {
      developer.log('SplashScreen - Fatal Error: $e');
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
