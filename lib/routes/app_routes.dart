import 'package:flutter/material.dart';
import 'package:ngobrolin_app/bootstrap.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';

// Screens
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login/login_screen.dart';
import '../screens/auth/register/register_screen.dart';
import '../screens/auth/forgot_password/forgot_password_screen.dart';
import '../screens/auth/forgot_password/reset_password_screen.dart';
import '../screens/main/main_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/chat/user_profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/blocked_users_screen.dart';
import 'dart:developer' as developer;

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String main = '/main';
  static const String chat = '/chat';
  static const String settingsRoute = '/settings';
  static const String blockedUsers = '/settings/blocked-users';
  static const String userProfile = '/user-profile';

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    developer.log(
      'AppRoutes: Navigating to: ${settings.name}',
      name: 'AppRoutes',
    );
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case resetPassword:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(token: args?['token'] as String?),
        );
      case main:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
          settings: settings,
        );
      case chat:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            userId: args?['userId'] as String? ?? '',
            name: args?['name'] as String? ?? '',
            avatarUrl: args?['avatarUrl'] as String? ?? '',
            chatId: args?['chatId'] as String? ?? '',
          ),
        );
      case settingsRoute:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case blockedUsers:
        return MaterialPageRoute(builder: (_) => const BlockedUsersScreen());
      case userProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) =>
              UserProfileScreen(userId: args?['userId'] as String? ?? ''),
        );
      default:
        _showRouteError(settings.name);
        return null;
      // return MaterialPageRoute(
      //   builder: (_) => Scaffold(
      //     body: Center(child: Text('No route defined for ${settings.name}')),
      //   ),
      // );
    }
  }

  static void _showRouteError(String? routeName) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('route_not_found')}: $routeName'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }
}
