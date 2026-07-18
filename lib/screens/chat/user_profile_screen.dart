import 'package:flutter/material.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:ngobrolin_app/core/models/block_user_status.dart';
import 'package:ngobrolin_app/core/providers/socket_provider.dart';
import 'package:ngobrolin_app/core/viewmodels/auth/auth_view_model.dart';
import 'package:ngobrolin_app/core/widgets/buttons/secondary_button.dart';
import 'package:ngobrolin_app/core/widgets/cards/app_avatar.dart';
import 'package:ngobrolin_app/core/widgets/cards/blocked_badge.dart';
import 'package:ngobrolin_app/core/widgets/cards/note_badge.dart';
import 'package:ngobrolin_app/core/widgets/states/image_error_placeholder.dart';
import 'package:ngobrolin_app/core/widgets/texts/expandable_text_section.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/viewmodels/profile/user_profile_view_model.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Function(dynamic) _blockStatusUpdatedHandler;
  late SocketProvider _socketProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();

      _socketProvider = Provider.of<SocketProvider>(context, listen: false);
      _setupSocketHandlers();
    });
  }

  void _setupSocketHandlers() {
    final userProfileViewModel = context.read<UserProfileViewModel>();
    _blockStatusUpdatedHandler = (data) {
      try {
        userProfileViewModel.getBlockUserStatus();
      } catch (_) {}
    };

    _socketProvider.on('block_status_updated', _blockStatusUpdatedHandler);
  }

  @override
  void dispose() {
    final userProfileViewModel = context.read<UserProfileViewModel>();
    userProfileViewModel.resetBlockStatus();

    _socketProvider.off('block_status_updated', _blockStatusUpdatedHandler);
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final userProfileViewModel = Provider.of<UserProfileViewModel>(
      context,
      listen: false,
    );
    final success = await userProfileViewModel.fetchUserProfile(widget.userId);
    await userProfileViewModel.getBlockUserStatus();

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              userProfileViewModel.errorMessage ?? 'failed_to_load_profile',
            ),
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _startChat() {
    final userProfileViewModel = Provider.of<UserProfileViewModel>(
      context,
      listen: false,
    );
    final user = userProfileViewModel.user;
    if (user == null) return;
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.chat,
      arguments: {
        'userId': user.id,
        'name': user.name,
        'avatarUrl': user.avatarUrl,
      },
    );
  }

  void _toggleBlockUser() async {
    final userProfileViewModel = Provider.of<UserProfileViewModel>(
      context,
      listen: false,
    );
    final user = userProfileViewModel.user;
    final isBlocked = userProfileViewModel.isBlocked;

    if (user == null) return;

    if (isBlocked) {
      final success = await userProfileViewModel.unblockUser();
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                userProfileViewModel.successMessage ??
                    'user_unblocked_successfully',
              ),
            ),
            backgroundColor: AppColors.accent,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                userProfileViewModel.errorMessage ?? 'failed_to_unblock_user',
              ),
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } else {
      _showBlockConfirmationDialog(userProfileViewModel);
    }
  }

  void _showBlockConfirmationDialog(UserProfileViewModel viewModel) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('block_account')),
        content: Text(context.tr('are_you_sure_block')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.tr('no')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await viewModel.blockUser();
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr(
                        viewModel.successMessage ?? 'user_blocked_successfully',
                      ),
                    ),
                    backgroundColor: AppColors.accent,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr(
                        viewModel.errorMessage ?? 'failed_to_block_user',
                      ),
                    ),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
            child: Text(
              context.tr('yes'),
              style: const TextStyle(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('profile'))),
      body: Selector<UserProfileViewModel, bool>(
        selector: (_, vm) => vm.isLoading || vm.user == null,
        builder: (context, isPreparing, _) {
          if (isPreparing) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = context.read<UserProfileViewModel>().user!;

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: AppColors.primary,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: user.avatarUrl != null
                            ? () {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    insetPadding: const EdgeInsets.all(16),
                                    child: PhotoView(
                                      imageProvider: NetworkImage(
                                        user.avatarUrl!,
                                      ),
                                      initialScale:
                                          PhotoViewComputedScale.contained,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              ImageErrorPlaceholder(
                                                width: double.infinity,
                                                height: double.infinity,
                                                iconSize: 48,
                                                errorMessage: context.tr(
                                                  'failed_to_load_image',
                                                ),
                                              ),
                                    ),
                                  ),
                                );
                              }
                            : null,
                        child: AppAvatar(
                          imageUrl: user.avatarUrl,
                          name: user.name,
                          radius: 50,
                          fontSize: 40,
                          backgroundColor: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),

                      if (user.isPrivate) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Iconify(
                              MaterialSymbols.lock_outline,
                              color: AppColors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              context.tr('private_account'),
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: ExpandableTextSection(
                      title: context.tr('bio'),
                      content: user.bio!,
                    ),
                  ),
                  const Divider(),
                ],
                Selector<UserProfileViewModel, BlockUserStatus?>(
                  selector: (_, vm) => vm.blockUserStatus,
                  builder: (context, blockUserStatus, _) {
                    if (blockUserStatus?.isBlocked ?? false) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: BlockedBadge(
                          message: context.tr(
                            blockUserStatus?.blockedMessage ?? '',
                          ),
                        ),
                      );
                    } else {
                      return SizedBox();
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Selector<UserProfileViewModel, bool>(
                    selector: (_, vm) => vm.isBlocked,
                    builder: (context, isBlocked, _) {
                      // Ambil logic auth pakai read supaya nggak re-render screen
                      final authViewModel = context.read<AuthViewModel>();
                      final currentUserId = authViewModel.user?.id;
                      final isSelf = currentUserId == user.id;
                      final isPrivate = user.isPrivate;
                      final canStartChat = !isBlocked && (!isPrivate || isSelf);

                      return Column(
                        children: [
                          if (canStartChat) ...[
                            PrimaryButton(
                              text: context.tr('start_chat'),
                              onPressed: _startChat,
                              icon: const Iconify(
                                Mdi.message_plus,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          SecondaryButton(
                            text: isBlocked
                                ? context.tr('unblock_user')
                                : context.tr('block_account'),
                            onPressed: _toggleBlockUser,
                            textColor: isBlocked
                                ? AppColors.primary
                                : AppColors.warning,
                            borderColor: isBlocked
                                ? AppColors.primary
                                : AppColors.warning,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
