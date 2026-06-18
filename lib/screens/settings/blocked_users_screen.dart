import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ic.dart';
import 'package:ngobrolin_app/core/widgets/states/empty_state.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/viewmodels/settings/blocked_users_view_model.dart';
import '../../theme/app_colors.dart';
import '../../core/widgets/cards/user_list_item.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<BlockedUsersViewModel>(
        context,
        listen: false,
      ).fetchBlockedUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    // OPTIMASI: Pindahkan Scaffold ke luar Consumer agar tidak ikut rebuild menyeluruh
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('blocked_users'))),
      body: Consumer<BlockedUsersViewModel>(
        builder: (context, blockedUsersViewModel, _) {
          if (blockedUsersViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final blockedUsers = blockedUsersViewModel.blockedUsers;

          if (blockedUsers.isEmpty) {
            return EmptyState(
              image: const Iconify(
                Ic.round_block,
                size: 80,
                color: AppColors.lightGrey,
              ),
              title: context.tr('no_blocked_users'),
              subtitle: context.tr('no_blocked_users_description'),
            );
          }

          return ListView.separated(
            itemCount: blockedUsers.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = blockedUsers[index];

              return UserListItem(
                user: user,
                onTap: () {},
                onActionTap: () => _unblockUser(user.id, blockedUsersViewModel),
                actionText: context.tr('unblock'),
                actionWidget: const Icon(
                  Icons.lock_open,
                  color: Colors.white,
                  size: 16,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _unblockUser(String userId, BlockedUsersViewModel viewModel) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('unblock_user')),
        content: Text(
          dialogContext.tr('unblock_user_confirmation'),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.tr('cancel')),
          ),
          TextButton(
            onPressed: () async {
              // Tutup dialog terlebih dahulu menggunakan dialogContext
              Navigator.of(dialogContext).pop();

              // Eksekusi API Unblock
              final success = await viewModel.unblockUser(userId);

              // Amankan pengecekan jika state widget sudah tidak aktif/dihancurkan
              if (!mounted) return;

              // Ambil pesan dari view model atau gunakan fallback lokalisasi bahasa
              final message = success
                  ? context.tr(viewModel.successMessage ?? 'user_unblocked')
                  : context.tr(
                      viewModel.errorMessage ?? 'failed_to_unblock_user',
                    );

              // Tampilkan notifikasi tunggal secara bersih
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: success ? Colors.green : Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              dialogContext.tr('unblock'),
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
