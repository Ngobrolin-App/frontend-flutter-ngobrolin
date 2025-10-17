import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ph.dart';
import 'package:iconify_flutter/icons/ri.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import '../../core/localization/app_localizations.dart';
import '../../theme/app_colors.dart';
import 'chat_list/chat_list_screen.dart';
import 'search_user/search_user_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const ChatListScreen(),
    const SearchUserScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Iconify(Ph.chat_dots_light, color: AppColors.deactiveButton),
            activeIcon: Iconify(Ph.chat_dots_fill, color: AppColors.primary),
            label: context.tr('chats'),
          ),
          BottomNavigationBarItem(
            icon: Iconify(Ri.search_2_line, color: AppColors.deactiveButton),
            activeIcon: Iconify(Ri.search_eye_fill, color: AppColors.primary),
            label: context.tr('users'),
          ),
          BottomNavigationBarItem(
            icon: Iconify(
              MaterialSymbols.person_2_outline_rounded,
              color: AppColors.deactiveButton,
            ),
            activeIcon: Iconify(MaterialSymbols.person_2_rounded, color: AppColors.primary),
            label: context.tr('profile'),
          ),
        ],
      ),
    );
  }
}
