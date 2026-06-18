import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:provider/provider.dart';
import 'package:ngobrolin_app/core/widgets/states/empty_state.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/viewmodels/search/search_user_view_model.dart';
import '../../../core/widgets/cards/user_list_item.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<SearchUserViewModel>(
        context,
        listen: false,
      ).setSearchQuery('');
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final vm = Provider.of<SearchUserViewModel>(context, listen: false);
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        vm.hasMore &&
        !vm.isLoadingMore &&
        !vm.isLoading) {
      vm.loadMoreSearchUser();
    }
  }

  void _updateSearchQuery(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      Provider.of<SearchUserViewModel>(
        context,
        listen: false,
      ).setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('users')),
        actions: [
          IconButton(
            icon: const Iconify(
              MaterialSymbols.settings_rounded,
              color: AppColors.white,
            ),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.settingsRoute);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // SOLUSI UX: Search bar ditaruh di luar kondisi loading agar tetap interaktif
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.tr('search_users'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _updateSearchQuery('');
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onChanged: (value) {
                _updateSearchQuery(value);
                setState(
                  () {},
                ); // Memicu update untuk memunculkan/menyembunyikan suffixIcon clear
              },
            ),
          ),

          // Bagian list data dikurung menggunakan Consumer agar rebuild lebih efisien
          Expanded(
            child: Consumer<SearchUserViewModel>(
              builder: (context, searchViewModel, _) {
                if (searchViewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (searchViewModel.users.isEmpty) {
                  return EmptyState(title: context.tr('no_users_found'));
                }

                return ListView.separated(
                  controller: _scrollController,
                  itemCount:
                      searchViewModel.users.length +
                      (searchViewModel.isLoadingMore ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    if (index >= searchViewModel.users.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final user = searchViewModel.users[index];

                    return UserListItem(
                      user: user,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.userProfile,
                          arguments: {'userId': user.id},
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
                      actionWidget: const Iconify(
                        Mdi.message_plus_outline,
                        color: AppColors.white,
                        size: 16,
                      ),
                      actionText: context.tr('message'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
