import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ic.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/viewmodels/settings/blocked_users_view_model.dart';
import '../../theme/app_colors.dart';
import '../../core/widgets/cards/user_list_item.dart';
import '../../core/models/user.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch blocked users when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final blockedUsersViewModel = Provider.of<BlockedUsersViewModel>(context, listen: false);
      blockedUsersViewModel.fetchBlockedUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BlockedUsersViewModel>(
      builder: (context, blockedUsersViewModel, child) {
        final blockedUsers = blockedUsersViewModel.blockedUsers;
        final isLoading = blockedUsersViewModel.isLoading;

        return Scaffold(
          appBar: AppBar(title: Text(context.tr('blocked_users'))),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : blockedUsers.isEmpty
              ? _buildEmptyState(context)
              : ListView.separated(
                  itemCount: blockedUsers.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = User.fromMinimalJson(blockedUsers[index]);

                    return UserListItem(
                      user: user,
                      onTap: () {
                        // No action on tap for blocked users
                      },
                      onActionTap: () => _unblockUser(context, user.id, blockedUsersViewModel),
                      actionText: context.tr('unblock'),
                      actionWidget: const Icon(Icons.lock_open, color: Colors.white, size: 16),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Iconify(Ic.round_block, size: 80, color: AppColors.lightGrey),
          const SizedBox(height: 16),
          Text(
            context.tr('no_blocked_users'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('no_blocked_users_description'),
            style: const TextStyle(fontSize: 16, color: AppColors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _unblockUser(
    BuildContext context,
    String userId,
    BlockedUsersViewModel blockedUsersViewModel,
  ) {
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
            onPressed: () async {
              Navigator.of(context).pop();

              // Unblock the user
              final success = await blockedUsersViewModel.unblockUser(userId);

              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? context.tr('user_unblocked') : 'Failed to unblock user'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: Text(context.tr('unblock'), style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
