import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:iconify_flutter/icons/ri.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/viewmodels/search/search_user_view_model.dart';
import '../../../core/widgets/cards/user_list_item.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({Key? key}) : super(key: key);

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Timer? _debounce;

  // Scroll controller for pagination
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mulai dengan query kosong agar backend mengembalikan semua user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchViewModel = Provider.of<SearchUserViewModel>(context, listen: false);
      searchViewModel.setSearchQuery('');

      // Attach scroll listener for load more
      _scrollController.addListener(() {
        final vm = Provider.of<SearchUserViewModel>(context, listen: false);
        if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
            vm.hasMore &&
            !vm.isLoadingMore) {
          vm.loadMore();
        }
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();

      // Reset search query in ViewModel
      final searchViewModel = Provider.of<SearchUserViewModel>(context, listen: false);
      searchViewModel.setSearchQuery('');
    });
  }

  void _updateSearchQuery(String query) {
    // Debounce 400ms sebelum memanggil search
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final searchViewModel = Provider.of<SearchUserViewModel>(context, listen: false);
      searchViewModel.setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchViewModel = Provider.of<SearchUserViewModel>(context);
    final users = searchViewModel.users;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('users')),
        actions: [
          IconButton(
            icon: Iconify(MaterialSymbols.settings_rounded, color: AppColors.white),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.settingsRoute);
            },
          ),
        ],
      ),
      body: searchViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar di bawah AppBar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: context.tr('search_users'),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onChanged: _updateSearchQuery,
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    itemCount: users.length + (searchViewModel.isLoadingMore ? 1 : 0),
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
                    itemBuilder: (context, index) {
                      if (index >= users.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final user = User.fromMinimalJson(users[index]);

                      return UserListItem(
                        user: user,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.userProfile,
                            arguments: {
                              'userId': user.id,
                              'name': user.name,
                              'username': user.username,
                              'avatarUrl': user.avatarUrl,
                            },
                          );
                        },
                        onActionTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.chat,
                            arguments: {
                              'userId': user.id,
                              'name': user.name,
                              'avatarUrl': user.avatarUrl,
                            },
                          );
                        },
                        actionWidget: Iconify(
                          Mdi.message_plus_outline,
                          color: AppColors.white,
                          size: 16,
                        ),
                        actionText: context.tr('message'),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
