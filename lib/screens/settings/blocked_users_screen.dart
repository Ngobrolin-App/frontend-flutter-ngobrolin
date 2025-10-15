import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/settings_provider.dart';
import '../../theme/app_colors.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  // Mock data for blocked users
  final Map<String, Map<String, dynamic>> _blockedUsersData = {
    '1': {
      'id': '1',
      'name': 'John Doe',
      'username': 'johndoe',
      'avatarUrl': null,
    },
    '2': {
      'id': '2',
      'name': 'Jane Smith',
      'username': 'janesmith',
      'avatarUrl': null,
    },
  };

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final blockedUserIds = settingsProvider.blockedAccounts;
    
    // Filter blocked users based on the provider's blocked IDs
    final blockedUsers = _blockedUsersData.entries
        .where((entry) => blockedUserIds.contains(entry.key))
        .map((entry) => entry.value)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('blocked_users')),
      ),
      body: blockedUsers.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              itemCount: blockedUsers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = blockedUsers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.lightGrey,
                    backgroundImage: user['avatarUrl'] != null
                        ? NetworkImage(user['avatarUrl'])
                        : null,
                    child: user['avatarUrl'] == null
                        ? Text(
                            user['name'][0].toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  title: Text(user['name']),
                  subtitle: Text('@${user['username']}'),
                  trailing: TextButton(
                    onPressed: () => _unblockUser(context, user['id']),
                    child: Text(
                      context.tr('unblock'),
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.block,
            size: 80,
            color: AppColors.lightGrey,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('no_blocked_users'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('no_blocked_users_description'),
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _unblockUser(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('unblock_user')),
        content: Text(
          context.tr('unblock_user_confirmation'),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              // Unblock the user
              final settingsProvider = Provider.of<SettingsProvider>(
                context,
                listen: false,
              );
              settingsProvider.unblockAccount(userId);
              
              Navigator.of(context).pop();
              
              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('user_unblocked')),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              context.tr('unblock'),
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}