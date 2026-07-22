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
  final _debouncer = Debouncer(milliseconds: 400);

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
    _debouncer.dispose();
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

  void _onSearchChanged(String query) {
    _debouncer.run(() {
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
                Row(
                  children: [
                    Expanded(
                      child: ActionListTile(
                        padding: EdgeInsets.only(
                          top: 8,
                          bottom: 8,
                          left: 16,
                          right: 4,
                        ),
                        title: context.tr('new_group'),
                        icon: Mdi.account_multiple_plus,
                        onTap: () => viewModel.setUserSelectionAction(
                          UserSelectionAction.createNewGroup,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ActionListTile(
                        padding: EdgeInsets.only(
                          top: 8,
                          bottom: 8,
                          left: 4,
                          right: 16,
                        ),
                        title: context.tr('join_group'),
                        icon: Mdi.account_multiple,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.searchGroup);
                        },
                      ),
                    ),
                  ],
                ),
              CustomSearchBar(
                controller: _searchController,
                hintText: context.tr('search_users'),
                onChanged: _onSearchChanged,
                onClear: () => _onSearchChanged(''),
              ),
              Expanded(
                child: PaginatedStateBuilder(
                  isLoading: viewModel.isLoading,
                  isEmpty: viewModel.users.isEmpty,
                  emptyMessage: 'no_users_found',
                  onRefresh: () async =>
                      viewModel.setSearchQuery(query: _searchController.text),
                  child: _buildUserList(viewModel),
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

  Widget _buildUserList(SearchUserViewModel viewModel) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      children: [
        ListView.builder(
          shrinkWrap: true,
          padding: (viewModel.userSelectionAction != null)
              ? EdgeInsets.only(bottom: 64)
              : EdgeInsets.only(bottom: 16),
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
