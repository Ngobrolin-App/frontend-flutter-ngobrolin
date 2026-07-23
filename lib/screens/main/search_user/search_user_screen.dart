import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:ngobrolin_app/core/enums/general_enums.dart';
import 'package:ngobrolin_app/core/utils/debouncer.dart';
import 'package:ngobrolin_app/core/widgets/buttons/primary_button.dart';
import 'package:ngobrolin_app/core/widgets/inputs/custom_search_bar.dart';
import 'package:ngobrolin_app/core/widgets/states/paginated_state_builder.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/viewmodels/search/search_user_view_model.dart';
import '../../../core/widgets/buttons/mini_icon_text_button.dart';
import '../../../core/widgets/cards/action_list_tile.dart';
import '../../../core/widgets/cards/user_list_item.dart';
import '../../../core/widgets/cards/circle_user_item_selected.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import 'dart:developer' as developer;

class SearchUserScreen extends StatefulWidget {
  final UserSelectionAction? userSelectionAction;
  final List<String>? excludeUsers;
  final List<String>? includeUsers;

  const SearchUserScreen({
    super.key,
    this.userSelectionAction,
    this.excludeUsers = const [],
    this.includeUsers = const [],
  });

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  late SearchUserViewModel _searchUserViewModel;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _debouncer = Debouncer(milliseconds: 400);

  final Set<String> _processedIncludes = {};

  @override
  void initState() {
    super.initState();
    developer.log('initstate() ', name: 'SearchUserScreen');
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchUserViewModel = context.read<SearchUserViewModel>();
      if (mounted) {
        _searchUserViewModel.setSearchQuery();
        _searchUserViewModel.setUserSelectionAction(widget.userSelectionAction);
      }
    });
  }

  @override
  void dispose() {
    developer.log('dispose() ', name: 'SearchUserScreen');
    Future.microtask(() {
      _searchUserViewModel.resetAllUserSearchData();
    });
    _debouncer.dispose();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Fixed: Added safety checks to prevent pagination bugs on short lists
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= (maxScroll - 200) &&
        maxScroll > 0 &&
        _searchUserViewModel.hasMore &&
        !_searchUserViewModel.isLoadingMore &&
        !_searchUserViewModel.isLoading) {
      _searchUserViewModel.loadMoreSearchUser();
    }
  }

  void _onSearchChanged(String query) {
    _debouncer.run(() {
      if (mounted) _searchUserViewModel.setSearchQuery(query: query);
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
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.settingsRoute),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          Selector<SearchUserViewModel, (UserSelectionAction?, int)>(
            selector: (_, vm) =>
                (vm.userSelectionAction, vm.selectedUsers.length),
            builder: (context, data, _) {
              final action = data.$1;
              if (action != null) {
                return _buildSelectionHeader(context);
              }
              return Row(
                children: [
                  Expanded(
                    child: ActionListTile(
                      padding: const EdgeInsets.only(
                        top: 8,
                        bottom: 8,
                        left: 16,
                        right: 4,
                      ),
                      title: context.tr('new_group'),
                      icon: Mdi.account_multiple_plus,
                      onTap: () => context
                          .read<SearchUserViewModel>()
                          .setUserSelectionAction(
                            UserSelectionAction.createNewGroup,
                          ),
                    ),
                  ),
                  Expanded(
                    child: ActionListTile(
                      padding: const EdgeInsets.only(
                        top: 8,
                        bottom: 8,
                        left: 4,
                        right: 16,
                      ),
                      title: context.tr('join_group'),
                      icon: Mdi.account_multiple,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.searchGroup),
                    ),
                  ),
                ],
              );
            },
          ),

          CustomSearchBar(
            controller: _searchController,
            hintText: context.tr('search_users'),
            onChanged: _onSearchChanged,
            onClear: () => _onSearchChanged(''),
          ),

          Expanded(
            child: Consumer<SearchUserViewModel>(
              builder: (context, viewModel, _) {
                return PaginatedStateBuilder(
                  isLoading: viewModel.isLoading,
                  isEmpty: viewModel.users.isEmpty,
                  emptyMessage: context.tr('no_users_found'),
                  onRefresh: () async =>
                      viewModel.setSearchQuery(query: _searchController.text),
                  child: _buildUserList(viewModel),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton:
          Selector<SearchUserViewModel, (UserSelectionAction?, int)>(
            selector: (_, vm) =>
                (vm.userSelectionAction, vm.selectedUsers.length),
            builder: (context, data, _) {
              final action = data.$1;
              final selectedCount = data.$2;

              if (action != null && selectedCount > 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PrimaryButton(
                    text: context.tr('continue'),
                    onPressed: () {
                      final vm = context.read<SearchUserViewModel>();
                      if (action == UserSelectionAction.createNewGroup) {
                        Navigator.of(context).pushNamed(
                          AppRoutes.createChatGroup,
                          arguments: {'members': vm.selectedUsers},
                        );
                      } else if (action == UserSelectionAction.addNewMembers) {
                        Navigator.pop(context, vm.selectedUsersIds);
                      }
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildUserList(SearchUserViewModel viewModel) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      padding: (viewModel.userSelectionAction != null)
          ? const EdgeInsets.only(bottom: 64)
          : const EdgeInsets.only(bottom: 16),
      itemCount: viewModel.users.length + (viewModel.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= viewModel.users.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final user = viewModel.users[index];
        final isSelected = viewModel.selectedUsers.any((u) => u.id == user.id);
        final bool isExcluded = widget.excludeUsers?.contains(user.id) ?? false;
        final bool isIncluded = widget.includeUsers?.contains(user.id) ?? false;

        if (isIncluded &&
            viewModel.userSelectionAction != null &&
            !_processedIncludes.contains(user.id)) {
          _processedIncludes.add(user.id);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            viewModel.addUserSelection(user);
          });
        }

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
    );
  }

  Widget _buildSelectionHeader(BuildContext context) {
    final viewModel = context.read<SearchUserViewModel>();
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
        Selector<SearchUserViewModel, List<dynamic>>(
          selector: (_, vm) => vm.selectedUsers,
          builder: (context, selectedUsers, _) {
            if (selectedUsers.isEmpty) {
              return Text(
                context.tr('none_selected'),
                style: const TextStyle(color: AppColors.timestamp),
              );
            }
            return SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: selectedUsers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  final user = selectedUsers[index];
                  return CircleUserItemSelected(
                    user: user,
                    onRemove: () => context
                        .read<SearchUserViewModel>()
                        .toggleUserSelection(user),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
