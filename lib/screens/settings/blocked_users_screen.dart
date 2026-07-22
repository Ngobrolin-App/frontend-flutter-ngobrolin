import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/widgets/states/paginated_state_builder.dart';
import 'package:ngobrolin_app/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:ngobrolin_app/core/widgets/buttons/mini_icon_text_button.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/viewmodels/settings/blocked_users_view_model.dart';
import '../../theme/app_colors.dart';
import '../../core/widgets/cards/user_list_item.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<BlockedUsersViewModel>(
        context,
        listen: false,
      ).fetchBlockedUsers();
    });
  }

  void _onScroll() {
    final vm = Provider.of<BlockedUsersViewModel>(context, listen: false);
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        vm.hasMore &&
        !vm.isLoadingMore &&
        !vm.isLoading) {
      vm.loadMoreBlockedUsers();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('blocked_users'))),
      body: Consumer<BlockedUsersViewModel>(
        builder: (context, vm, _) {
          final blockedUsers = vm.blockedUsers;

          return PaginatedStateBuilder(
            isLoading: vm.isLoading,
            isEmpty: blockedUsers.isEmpty,
            emptyMessage: context.tr('no_blocked_users'),
            emptySubtitle: context.tr(
              'no_blocked_users_description',
            ), // Gunakan parameter baru
            // Tambahkan fitur pull-to-refresh secara instan
            onRefresh: () async => vm.fetchBlockedUsers(),

            child: ListView.builder(
              physics:
                  const AlwaysScrollableScrollPhysics(), // Wajib agar RefreshIndicator berfungsi walau item sedikit
              controller: _scrollController,
              // Tambahkan 1 item ekstra untuk indikator loading pagination
              itemCount: vm.hasMore
                  ? blockedUsers.length + 1
                  : blockedUsers.length,
              itemBuilder: (context, index) {
                // Tampilkan loading di ujung bawah list
                if (index == blockedUsers.length) {
                  return vm.isLoadingMore
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink();
                }

                final user = blockedUsers[index];

                return UserListItem(
                  user: user,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.userProfile,
                    arguments: {'userId': user.id},
                  ),
                  actionWidget: MiniIconTextButton(
                    onTap: () => _unblockUser(user.id, vm),
                    icon: const Iconify(
                      MaterialSymbols.unblock_flipped,
                      color: AppColors.white,
                      size: 16,
                    ),
                    text: context.tr('unblock'),
                  ),
                );
              },
            ),
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
                  content: Text(context.tr(message)),
                  backgroundColor: success
                      ? AppColors.accent
                      : AppColors.warning,
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
