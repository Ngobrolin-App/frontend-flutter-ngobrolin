import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ph.dart';
import 'package:iconify_flutter/icons/ri.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:ngobrolin_app/core/di/service_locator.dart';
import 'package:ngobrolin_app/core/utils/permission_utils.dart';
import 'package:ngobrolin_app/core/viewmodels/chat/chat_list_view_model.dart';
import 'package:ngobrolin_app/core/viewmodels/profile/profile_view_model.dart';
import 'package:ngobrolin_app/core/viewmodels/search/search_user_view_model.dart';
import 'package:ngobrolin_app/theme/app_texts.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../theme/app_colors.dart';
import 'chat_list/chat_list_screen.dart';
import 'search_user/search_user_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _initializedFromArgs = false;

  // OPTIMASI: Pastikan widget di dalam list bersifat const atau diinstansiasi dengan benar
  final List<Widget> _screens = [
    ChangeNotifierProvider(
      create: (_) => serviceLocator<ChatListViewModel>(),
      child: ChatListScreen(),
    ),
    ChangeNotifierProvider(
      create: (_) => serviceLocator<SearchUserViewModel>(),
      child: SearchUserScreen(),
    ),
    ChangeNotifierProvider(
      create: (_) => serviceLocator<ProfileViewModel>(),
      child: const ProfileScreen(),
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromArgs) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['tabIndex'] is int) {
        final idx = args['tabIndex'] as int;
        if (idx >= 0 && idx < _screens.length) {
          setState(() {
            _currentIndex = idx;
          });
        }
      }
      _initializedFromArgs = true;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionUtils.checkAndRequestNotification(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (_currentIndex == index) return;
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.deactiveButton,
        selectedLabelStyle: AppTexts.selectedBottomNavigationTextStyle,
        unselectedLabelStyle: AppTexts.unselectedBottomNavigationTextStyle,
        items: [
          BottomNavigationBarItem(
            backgroundColor: AppColors.chatBubbleUser,
            icon: Container(
              margin: EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: const Iconify(
                Ph.chat_dots_light,
                color: AppColors.deactiveButton,
              ),
            ),
            activeIcon: Container(
              margin: EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Iconify(Ph.chat_dots_fill, color: AppColors.primary),
            ),
            label: context.tr('chats'),
          ),
          BottomNavigationBarItem(
            icon: Container(
              margin: EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: const Iconify(
                Ri.search_2_line,
                color: AppColors.deactiveButton,
              ),
            ),
            activeIcon: Container(
              margin: EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,

                borderRadius: BorderRadius.circular(20),
              ),
              child: const Iconify(
                Ri.search_eye_fill,
                color: AppColors.primary,
              ),
            ),
            label: context.tr('users'),
          ),
          BottomNavigationBarItem(
            icon: Container(
              margin: EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: const Iconify(
                MaterialSymbols.person_2_outline_rounded,
                color: AppColors.deactiveButton,
              ),
            ),
            activeIcon: Container(
              margin: EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Iconify(
                MaterialSymbols.person_2_rounded,
                color: AppColors.primary,
              ),
            ),
            label: context.tr('profile'),
          ),
        ],
      ),
    );
  }
}
