import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/models/conversation_model.dart';
import 'package:ngobrolin_app/core/utils/debouncer.dart';
import 'package:ngobrolin_app/core/viewmodels/search/search_group_view_model.dart';
import 'package:ngobrolin_app/core/widgets/buttons/primary_button.dart';
import 'package:ngobrolin_app/core/widgets/cards/app_avatar.dart';
import 'package:ngobrolin_app/core/widgets/cards/group_list_item.dart';
import 'package:ngobrolin_app/core/widgets/inputs/custom_search_bar.dart';
import 'package:ngobrolin_app/core/widgets/modals/app_bottom_sheet.dart';
import 'package:ngobrolin_app/core/widgets/states/paginated_state_builder.dart';
import 'package:ngobrolin_app/core/widgets/texts/expandable_text_section.dart';
import 'package:ngobrolin_app/routes/app_routes.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_localizations.dart';

class SearchGroupScreen extends StatefulWidget {
  const SearchGroupScreen({super.key});

  @override
  State<SearchGroupScreen> createState() => _SearchGroupScreenState();
}

class _SearchGroupScreenState extends State<SearchGroupScreen> {
  late SearchGroupViewModel _searchGroupViewModel;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _debouncer = Debouncer(milliseconds: 400);
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    _searchGroupViewModel = context.read<SearchGroupViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchGroupViewModel.setSearchQuery();
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
        _searchGroupViewModel.hasMore &&
        !_searchGroupViewModel.isLoadingMore &&
        !_searchGroupViewModel.isLoading) {
      _searchGroupViewModel.loadMoreSearchGroups();
    }
  }

  void _onSearchChanged(String query) {
    _debouncer.run(() {
      if (mounted) _searchGroupViewModel.setSearchQuery(query: query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchGroupViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          appBar: AppBar(title: Text(context.tr('groups'))),
          body: Column(
            children: [
              const SizedBox(height: 8),
              CustomSearchBar(
                controller: _searchController,
                hintText: context.tr('search_groups'),
                onChanged: _onSearchChanged,
                onClear: () => _onSearchChanged(''),
              ),
              Expanded(
                child: PaginatedStateBuilder(
                  isLoading: viewModel.isLoading,
                  isEmpty: viewModel.groups.isEmpty,
                  emptyMessage: context.tr('no_groups_found'),
                  onRefresh: () async =>
                      viewModel.setSearchQuery(query: _searchController.text),
                  child: _buildGroupList(viewModel),
                ),
              ),
            ],
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  void _joinGroupConversation({required String conversationId}) async {
    if (conversationId.isEmpty) {
      return;
    }

    final success = await _searchGroupViewModel.joinGroupConversation(
      conversationId: conversationId,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            success
                ? (_searchGroupViewModel.successMessage ?? 'join_group_success')
                : (_searchGroupViewModel.errorMessage ?? 'join_group_failed'),
          ),
        ),
        backgroundColor: success ? AppColors.accent : AppColors.warning,
      ),
    );

    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.main,
        (route) => false,
      );
      Navigator.pushNamed(
        context,
        AppRoutes.chat,
        arguments: {'chatId': conversationId},
      );
    }
  }

  void _showGroupDetail(ConversationModel group) {
    AppBottomSheet.show(
      context: context,
      child: ChangeNotifierProvider<SearchGroupViewModel>.value(
        value: _searchGroupViewModel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row (Close, Title, Edit)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      context.tr('group_details'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Full Content (Scrollable)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    AppAvatar(
                      imageUrl: group.groupImage,
                      name: group.name,
                      radius: 50,
                      fontSize: 40,
                      backgroundColor: AppColors.lightGrey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      group.name ?? '',
                      maxLines: 3,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                        overflow: TextOverflow.ellipsis,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (group.totalParticipants != null) ...[
                      SizedBox(height: 4),
                      Text(
                        context.tr(
                          'number_of_members',
                          args: {'number': group.totalParticipants.toString()},
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                    if (group.groupDescription != null &&
                        (group.groupDescription?.isNotEmpty ?? false)) ...[
                      SizedBox(height: 16),
                      ExpandableTextSection(
                        title: context.tr('group_description'),
                        content: group.groupDescription ?? '',
                        maxLines: 2,
                      ),
                    ],
                    SizedBox(height: 16),
                    if (group.isMember != null)
                      Selector<SearchGroupViewModel, bool>(
                        selector: (_, vm) => vm.isLoading,
                        builder: (context, isLoading, _) {
                          return PrimaryButton(
                            isLoading: isLoading,
                            text: (group.isMember ?? false)
                                ? 'open_conversation'
                                : 'join_group',
                            onPressed: (group.isMember ?? false)
                                ? () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.chat,
                                      arguments: {'chatId': group.id},
                                    );
                                  }
                                : () {
                                    _joinGroupConversation(
                                      conversationId: group.id,
                                    );
                                  },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupList(SearchGroupViewModel viewModel) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount:
              viewModel.groups.length + (viewModel.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= viewModel.groups.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final group = viewModel.groups[index];

            return GroupListItem(
              group: group,
              onTap: () => _showGroupDetail(group),
              actionWidget: (group.isMember ?? false)
                  ? Container(
                      margin: EdgeInsets.only(left: 8),
                      child: Text(
                        context.tr('joined'),
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.grey,
                        ),
                      ),
                    )
                  : null,
            );
          },
        ),
      ],
    );
  }
}
