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
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _initializedFromArgs = false;

  // OPTIMASI: Pastikan widget di dalam list bersifat const atau diinstansiasi dengan benar
  final List<Widget> _screens = const [
    ChatListScreen(),
    SearchUserScreen(),
    ProfileScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromArgs) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['tabIndex'] is int) {
        final idx = args['tabIndex'] as int;
        if (idx >= 0 && idx < _screens.length) {
          // Validasi batas indeks agar tidak out of bounds
          setState(() {
            _currentIndex = idx;
          });
        }
      }
      _initializedFromArgs = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // SOLUSI: Menggunakan IndexedStack untuk menjaga state/posisi scroll semua screen
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (_currentIndex == index)
            return; // Cegah rebuild jika mengetuk tab yang sama
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType
            .fixed, // Memastikan layout tab tetap konsisten
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.deactiveButton,
        items: [
          BottomNavigationBarItem(
            icon: const Iconify(
              Ph.chat_dots_light,
              color: AppColors.deactiveButton,
            ),
            activeIcon: const Iconify(
              Ph.chat_dots_fill,
              color: AppColors.primary,
            ),
            label: context.tr('chats'),
          ),
          BottomNavigationBarItem(
            icon: const Iconify(
              Ri.search_2_line,
              color: AppColors.deactiveButton,
            ),
            activeIcon: const Iconify(
              Ri.search_eye_fill,
              color: AppColors.primary,
            ),
            label: context.tr('users'),
          ),
          BottomNavigationBarItem(
            icon: const Iconify(
              MaterialSymbols.person_2_outline_rounded,
              color: AppColors.deactiveButton,
            ),
            activeIcon: const Iconify(
              MaterialSymbols.person_2_rounded,
              color: AppColors.primary,
            ),
            label: context.tr('profile'),
          ),
        ],
      ),
    );
  }
}
