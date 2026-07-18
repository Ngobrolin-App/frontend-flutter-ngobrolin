import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:ngobrolin_app/core/enums/general_enums.dart';
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
  final UserSelectionAction? userSelectionAction;
  final List<String>? excludeUsers;
  const SearchUserScreen({
    super.key,
    this.userSelectionAction,
    this.excludeUsers = const [],
  });

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  late SearchUserViewModel _searchUserViewModel;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    _searchUserViewModel = context.read<SearchUserViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchUserViewModel.setSearchQuery();
        _searchUserViewModel.setUserSelectionAction(widget.userSelectionAction);
      }
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
      if (mounted) _searchUserViewModel.setSearchQuery(query: query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchUserViewModel>(
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
              const SizedBox(height: 8),
              if (viewModel.userSelectionAction != null)
                _buildSelectionHeader(viewModel)
              else
                ActionListTile(
                  title: context.tr('new_group'),
                  icon: Mdi.account_multiple_plus,
                  onTap: () => viewModel.setUserSelectionAction(
                    UserSelectionAction.createNewGroup,
                  ),
                ),
              _buildSearchBar(),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async =>
                      viewModel.setSearchQuery(query: _searchController.text),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (viewModel.isLoading) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: constraints.maxHeight,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        );
                      }
                      if (viewModel.users.isEmpty) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: constraints.maxHeight,
                            child: EmptyState(
                              title: context.tr('no_users_found'),
                            ),
                          ),
                        );
                      }
                      return _buildUserList(viewModel);
                    },
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton:
              (viewModel.userSelectionAction != null) &&
                  viewModel.selectedUsers.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PrimaryButton(
                    text: context.tr('continue'),
                    onPressed: () {
                      if (viewModel.userSelectionAction ==
                          UserSelectionAction.createNewGroup) {
                        Navigator.of(context).pushNamed(
                          AppRoutes.createChatGroup,
                          arguments: {'members': viewModel.selectedUsers},
                        );
                      } else if (viewModel.userSelectionAction ==
                          UserSelectionAction.addNewMembers) {
                        Navigator.pop(context, viewModel.selectedUsersIds);
                      }
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.textFieldLightGrey,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(SearchUserViewModel viewModel) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: viewModel.users.length + (viewModel.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= viewModel.users.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final user = viewModel.users[index];
            final isSelected = viewModel.selectedUsers.any(
              (u) => u.id == user.id,
            );

            final bool isExcluded =
                widget.excludeUsers?.contains(user.id) ?? false;

            return UserListItem(
              user: user,
              onTap: isExcluded
                  ? null
                  : () {
                      if (viewModel.userSelectionAction != null) {
                        viewModel.toggleUserSelection(user);
                      } else {
                        Navigator.of(context).pushNamed(
                          AppRoutes.userProfile,
                          arguments: {'userId': user.id},
                        );
                      }
                    },
              actionWidget: viewModel.userSelectionAction != null
                  ? (isExcluded
                        ? Text(
                            context.tr(
                              viewModel.userSelectionAction ==
                                      UserSelectionAction.addNewMembers
                                  ? 'member'
                                  : '',
                            ),
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 12,
                            ),
                          )
                        : Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: AppColors.primary,
                          ))
                  : (!user.isPrivate
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
                              color: AppColors.white,
                              size: 16,
                            ),
                            text: context.tr('message'),
                          )
                        : null),
            );
          },
        ),
      ],
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
                context.tr(
                  viewModel.userSelectionAction?.getSelectingTranslanteKey ??
                      'select_user',
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              InkWell(
                onTap: () => viewModel.resetUserSelection(),
                child: Text(context.tr('cancel')),
              ),
            ],
          ),
        ),
        if (viewModel.selectedUsers.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: viewModel.selectedUsers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                final user = viewModel.selectedUsers[index];
                return CircleUserItemSelected(
                  user: user,
                  onRemove: () => viewModel.toggleUserSelection(user),
                );
              },
            ),
          ),
        if (viewModel.selectedUsers.isEmpty)
          Text(
            context.tr('none_selected'),
            style: TextStyle(color: AppColors.timestamp),
          ),
      ],
    );
  }
}
