import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/viewmodels/auth/auth_view_model.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  // OPTIMASI: Ekstraksi logika pemanggilan API ke metode terpisah dengan pelindung `mounted`
  Future<void> _loadUserProfile() async {
    final userProfileViewModel = Provider.of<UserProfileViewModel>(
      context,
      listen: false,
    );
    final success = await userProfileViewModel.fetchUserProfile(widget.userId);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              userProfileViewModel.errorMessage ?? 'failed_to_load_profile',
            ),
          ),
        ),
      );
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
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      _showBlockConfirmationDialog(userProfileViewModel);
    }
  }

  // OPTIMASI: Memisahkan dialog konfirmasi untuk merapikan alur kontrol asinkronus
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
                    backgroundColor: Colors.green,
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
                    backgroundColor: Colors.red,
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
    // OPTIMASI: Menggunakan context.watch secara granular untuk menghindari pembungkusan menyeluruh oleh Consumer
    final userProfileViewModel = context.watch<UserProfileViewModel>();
    final user = userProfileViewModel.user;
    final isBlocked = userProfileViewModel.isBlocked;
    final isLoading = userProfileViewModel.isLoading;

    if (isLoading || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUserId = authViewModel.user?.id;
    final isSelf = currentUserId == user.id;
    final isPrivate = user.isPrivate;
    final canStartChat = !isBlocked && (!isPrivate || isSelf);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('profile'))),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.primary,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(
                            (user.name.trim().isNotEmpty)
                                ? (user.name.trim()[0].toUpperCase())
                                : '?',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (user.bio != null && user.bio!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          context.tr('bio'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(user.bio!, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  const Divider(),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (canStartChat)
                    PrimaryButton(
                      text: context.tr('start_chat'),
                      onPressed: _startChat,
                      icon: const Iconify(
                        Mdi.message_plus,
                        color: AppColors.white,
                      ),
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _toggleBlockUser,
                    icon: Icon(
                      isBlocked ? Icons.person_add : Icons.block,
                      color: isBlocked ? AppColors.primary : AppColors.warning,
                    ),
                    label: Text(
                      isBlocked
                          ? context.tr('unblock_user')
                          : context.tr('block_account'),
                      style: TextStyle(
                        color: isBlocked
                            ? AppColors.primary
                            : AppColors.warning,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isBlocked
                            ? AppColors.primary
                            : AppColors.warning,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
