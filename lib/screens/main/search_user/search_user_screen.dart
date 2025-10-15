import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
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
  String _searchQuery = '';
  bool _isSearching = false;

  // Mock data for user list
  final List<Map<String, dynamic>> _allUsers = [
    {
      'id': '1',
      'name': 'John Doe',
      'username': 'johndoe',
      'avatarUrl': null,
    },
    {
      'id': '2',
      'name': 'Jane Smith',
      'username': 'janesmith',
      'avatarUrl': null,
    },
    {
      'id': '3',
      'name': 'Mike Johnson',
      'username': 'mikejohnson',
      'avatarUrl': null,
    },
    {
      'id': '4',
      'name': 'Sarah Williams',
      'username': 'sarahwilliams',
      'avatarUrl': null,
    },
    {
      'id': '5',
      'name': 'David Brown',
      'username': 'davidbrown',
      'avatarUrl': null,
    },
    {
      'id': '6',
      'name': 'Emily Davis',
      'username': 'emilydavis',
      'avatarUrl': null,
    },
  ];

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _allUsers;
    }
    
    final query = _searchQuery.toLowerCase();
    return _allUsers.where((user) {
      return user['name'].toLowerCase().contains(query) ||
          user['username'].toLowerCase().contains(query);
    }).toList();
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
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  icon: const Icon(Icons.close),
                  onPressed: _stopSearch,
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _startSearch,
                ),
        ],
      ),
      body: ListView.separated(
        itemCount: _filteredUsers.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 72,
        ),
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
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
            actionIcon: Icons.chat_bubble_outline,
            actionText: context.tr('message'),
          );
        },
      ),
    );
  }
}