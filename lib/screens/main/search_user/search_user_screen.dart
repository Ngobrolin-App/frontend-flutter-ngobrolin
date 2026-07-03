import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:ngobrolin_app/core/widgets/buttons/primary_button.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/viewmodels/search/search_user_view_model.dart';
import '../../../core/widgets/buttons/mini_icon_text_button.dart';
import '../../../core/widgets/cards/action_list_tile.dart';
import '../../../core/widgets/cards/user_list_item.dart';
import '../../../core/widgets/cards/circle_user_item_selected.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  bool _isInit = false;
  late SearchUserViewModel _searchUserViewModel;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _searchUserViewModel = Provider.of<SearchUserViewModel>(
        context,
        listen: false,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchUserViewModel.setSearchQuery('');
      });
      _isInit = true;
    }
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
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _searchUserViewModel.hasMore &&
        !_searchUserViewModel.isLoadingMore &&
        !_searchUserViewModel.isLoading) {
      _searchUserViewModel.loadMoreSearchUser();
    }
  }

  void _updateSearchQuery(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _searchUserViewModel.setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchUserViewModel>(
      // Bungkus Scaffold dengan Consumer
      builder: (context, viewModel, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(context.tr('users')),
            actions: [
              IconButton(
                icon: const Iconify(
                  MaterialSymbols.settings_rounded,
                  color: AppColors.white,
                ),
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.settingsRoute),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: Consumer<SearchUserViewModel>(
                  builder: (context, viewModel, _) {
                    if (viewModel.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (viewModel.users.isEmpty) {
                      return EmptyState(title: context.tr('no_users_found'));
                    }
                    return _buildUserList(viewModel);
                  },
                ),
              ),
            ],
          ),
          floatingActionButton:
              viewModel.isSelectingGroupMembers &&
                  viewModel.selectedGroupMembers.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PrimaryButton(
                    text: context.tr(
                      'continue',
                    ), // Pastikan string 'continue' ada di localization
                    onPressed: () {
                      // Navigasi ke screen buat grup dengan membawa list member
                      Navigator.of(context).pushNamed(
                        AppRoutes
                            .createChatGroup, // Sesuaikan dengan route Anda
                        arguments: {'members': viewModel.selectedGroupMembers},
                      );
                    },
                  ),
                )
              : null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          _updateSearchQuery(value);
          setState(() {});
        },
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(SearchUserViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: () async => viewModel.setSearchQuery(_searchController.text),
      child: ListView(
        controller: _scrollController,
        children: [
          // Header Dinamis
          if (viewModel.isSelectingGroupMembers)
            _buildSelectionHeader(viewModel)
          else
            ActionListTile(
              title: context.tr('new_group'),
              icon: Mdi.account_multiple_plus,
              onTap: () => viewModel.setSelectingGroupMembers(true),
            ),
          const Divider(indent: 72),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount:
                viewModel.users.length + (viewModel.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              if (index >= viewModel.users.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final user = viewModel.users[index];
              final isSelected = viewModel.selectedGroupMembers.any(
                (u) => u.id == user.id,
              );
              return UserListItem(
                user: user,
                onTap: () {
                  if (viewModel.isSelectingGroupMembers) {
                    viewModel.toggleUserSelection(user);
                  } else {
                    Navigator.of(context).pushNamed(
                      AppRoutes.userProfile,
                      arguments: {'userId': user.id},
                    );
                  }
                },
                actionWidget: viewModel.isSelectingGroupMembers
                    ? Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: AppColors.primary,
                      )
                    : !user.isPrivate
                    ? MiniIconTextButton(
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.chat,
                          arguments: {
                            'userId': user.id,
                            'name': user.name,
                            'avatarUrl': user.avatarUrl,
                          },
                        ),
                        icon: const Iconify(
                          Mdi.message_plus_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                        text: context.tr('message'),
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionHeader(SearchUserViewModel viewModel) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('select_new_group_members'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              InkWell(
                onTap: () => viewModel.setSelectingGroupMembers(false),
                child: Text(context.tr('cancel')),
              ),
            ],
          ),
        ),
        if (viewModel.selectedGroupMembers.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: viewModel.selectedGroupMembers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final user = viewModel.selectedGroupMembers[index];
                return CircleUserItemSelected(
                  user: user,
                  onRemove: () => viewModel.toggleUserSelection(user),
                );
              },
            ),
          ),
      ],
    );
  }
}
