import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:iconify_flutter/icons/ri.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    // Initialize search with empty query to get random users
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchViewModel = Provider.of<SearchUserViewModel>(context, listen: false);
      // searchViewModel.searchUsers();
      searchViewModel.searchUsersDummy();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
    final searchViewModel = Provider.of<SearchUserViewModel>(context, listen: false);
    searchViewModel.setSearchQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    final searchViewModel = Provider.of<SearchUserViewModel>(context);
    final users = searchViewModel.users;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: context.tr('search_users'),
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: _updateSearchQuery,
              )
            : Text(context.tr('users')),
        actions: [
          _isSearching
              ? IconButton(
                  icon: Iconify(MaterialSymbols.close_rounded, color: AppColors.white),
                  onPressed: _stopSearch,
                )
              : IconButton(
                  icon: Iconify(Ri.search_2_line, color: AppColors.white),
                  onPressed: _startSearch,
                ),
        ],
      ),
      body: searchViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: users.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final user = users[index];
                return UserListItem(
                  id: user['id'],
                  name: user['name'],
                  username: user['username'],
                  avatarUrl: user['avatarUrl'],
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.userProfile,
                      arguments: {
                        'userId': user['id'],
                        'name': user['name'],
                        'username': user['username'],
                        'avatarUrl': user['avatarUrl'],
                      },
                    );
                  },
                  onActionTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.chat,
                      arguments: {
                        'userId': user['id'],
                        'name': user['name'],
                        'avatarUrl': user['avatarUrl'],
                      },
                    );
                  },
                  actionWidget: Iconify(Mdi.message_plus_outline, color: AppColors.white, size: 16),
                  actionText: context.tr('message'),
                );
              },
            ),
    );
  }
}
