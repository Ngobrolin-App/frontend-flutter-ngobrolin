import 'package:flutter/material.dart';

// Screens
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login/login_screen.dart';
import '../screens/auth/register/register_screen.dart';
import '../screens/main/main_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String chat = '/chat';
  static const String settingsRoute = '/settings';
  static const String blockedUsers = '/settings/blocked-users';
  static const String userProfile = '/user-profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case main:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case chat:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            userId: args?['userId'] as String? ?? '',
            name: args?['name'] as String? ?? '',
            avatarUrl: args?['avatarUrl'] as String?,
          ),
        );
      case settingsRoute:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case blockedUsers:
        return MaterialPageRoute(builder: (_) => const BlockedUsersScreen());
      case userProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => UserProfileScreen(
            userId: args?['userId'] as String? ?? '',
            name: args?['name'] as String? ?? '',
            username: args?['username'] as String? ?? '',
            avatarUrl: args?['avatarUrl'] as String?,
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}

// Placeholder classes for screens that haven't been created yet
class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Blocked Users Screen')),
    );
  }
}

class UserProfileScreen extends StatelessWidget {
  final String userId;
  final String name;
  final String username;
  final String? avatarUrl;

  const UserProfileScreen({
    Key? key,
    required this.userId,
    required this.name,
    required this.username,
    this.avatarUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('User Profile Screen: $name')),
    );
  }
}