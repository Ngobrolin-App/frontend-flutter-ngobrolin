import 'package:flutter/material.dart';
import 'package:ngobrolin_app/bootstrap.dart';
import 'package:ngobrolin_app/core/di/service_locator.dart';
import 'package:ngobrolin_app/core/enums/general_enums.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/core/models/user_model.dart';
import 'package:ngobrolin_app/core/viewmodels/chat/chat_view_model.dart';
import 'package:ngobrolin_app/core/viewmodels/chat/create_chat_group_view_model.dart';
import 'package:ngobrolin_app/core/viewmodels/chat/group_profile_view_model.dart';
import 'package:ngobrolin_app/core/viewmodels/profile/profile_view_model.dart';
import 'package:ngobrolin_app/core/viewmodels/profile/user_profile_view_model.dart';
import 'package:ngobrolin_app/core/viewmodels/search/search_group_view_model.dart';
import 'package:ngobrolin_app/core/viewmodels/search/search_user_view_model.dart';
import 'package:ngobrolin_app/core/widgets/screens/fullscreen_image_viewer.dart';
import 'package:ngobrolin_app/core/widgets/screens/text_editor_screen.dart';
import 'package:ngobrolin_app/screens/chat/create_chat_group_screen.dart';
import 'package:ngobrolin_app/screens/chat/group_profile_screen.dart';
import 'package:ngobrolin_app/screens/main/profile/edit_profile_screen.dart';
import 'package:ngobrolin_app/screens/main/search_user/search_user_screen.dart';
import 'package:ngobrolin_app/screens/main/search_user/search_group_screen.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';
import 'package:provider/provider.dart';

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

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String main = '/main';
  static const String chat = '/chat';
  static const String createChatGroup = '/create-chat-group';
  static const String settingsRoute = '/settings';
  static const String blockedUsers = '/settings/blocked-users';
  static const String userProfile = '/user-profile';
  static const String editProfile = '/edit-profile';
  static const String groupProfile = '/group-profile';
  static const String textEditor = '/text-editor';
  static const String searchUser = '/search-user';
  static const String searchGroup = '/search-group';
  static const String fullscreenImage = '/fullscreen-image'; // <-- Rute baru

  static Route<dynamic>? generateRoute(RouteSettings settings) {
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
          builder: (_) => ChangeNotifierProvider(
            create: (_) => serviceLocator<ChatViewModel>(),
            child: ChatScreen(
              userId: args?['userId'] as String? ?? '',
              name: args?['name'] as String? ?? '',
              avatarUrl: args?['avatarUrl'] as String? ?? '',
              chatId: args?['chatId'] as String? ?? '',
            ),
          ),
        );
      case createChatGroup:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => serviceLocator<CreateChatGroupViewModel>(),
            child: CreateChatGroupScreen(
              selectedUsers: args?['selectedUsers'] != null
                  ? List<UserModel>.from(args!['selectedUsers'])
                  : [],
            ),
          ),
        );
      case settingsRoute:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case blockedUsers:
        return MaterialPageRoute(builder: (_) => const BlockedUsersScreen());
      case userProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => serviceLocator<UserProfileViewModel>(),
            child: UserProfileScreen(userId: args?['userId'] as String? ?? ''),
          ),
        );
      case editProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => serviceLocator<ProfileViewModel>(),
            child: EditProfileScreen(user: args?['user'] as UserModel),
          ),
        );
      case groupProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => serviceLocator<GroupProfileViewModel>(),
            child: GroupProfileScreen(
              conversationId: args?['conversationId'] as String? ?? '',
            ),
          ),
        );
      case textEditor:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => TextEditorScreen(
            title: args?['title'] as String? ?? '',
            initialValue: args?['initialValue'] as String?,
            description: args?['description'] as String?,
            maxLength: args?['maxLength'] as int?,
            maxLines: args?['maxLines'] as int?,
            keyboardType: args?['keyboardType'] as TextInputType?,
          ),
        );
      case searchUser:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => serviceLocator<SearchUserViewModel>(),
            child: SearchUserScreen(
              userSelectionAction:
                  args?['userSelectionAction'] as UserSelectionAction?,
              excludeUsers: args?['excludeUsers'] as List<String>? ?? [],
              includeUsers: args?['includeUsers'] as List<String>? ?? [],
            ),
          ),
        );
      case searchGroup:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => serviceLocator<SearchGroupViewModel>(),
            child: SearchGroupScreen(),
          ),
        );
      case fullscreenImage:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => FullscreenImageViewer(
            imageUrl: args?['imageUrl'] as String? ?? '',
            caption: args?['caption'] as String?,
            showDownloadButton: args?['showDownloadButton'] as bool? ?? true,
          ),
        );
      default:
        _showRouteError(settings.name);
        return null;
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
