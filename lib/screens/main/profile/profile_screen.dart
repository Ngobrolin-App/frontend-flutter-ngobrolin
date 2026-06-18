import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/viewmodels/auth/auth_view_model.dart';
import '../../../core/viewmodels/profile/profile_view_model.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/secondary_button.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<ProfileViewModel>(
        context,
        listen: false,
      ).fetchCurrentProfile();
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('logout')),
        content: Text(dialogContext.tr('are_you_sure_logout')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.tr('no')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _logout(); // Menggunakan instance context utama widget
            },
            child: Text(
              dialogContext.tr('yes'),
              style: const TextStyle(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  // OPTIMASI: Pencegahan bug BuildContext asinkronus saat navigasi keluar
  void _logout() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    await authViewModel.signOut();

    if (!mounted) return;

    // Bersihkan seluruh stack navigasi kembali ke Login screen
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profile')),
        actions: [
          IconButton(
            icon: const Iconify(
              MaterialSymbols.settings_rounded,
              color: AppColors.white,
            ),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.settingsRoute);
            },
          ),
        ],
      ),
      // OPTIMASI: Batasi cakupan perubahan state menggunakan Consumer
      body: Consumer<ProfileViewModel>(
        builder: (context, profileViewModel, _) {
          if (profileViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = profileViewModel.user;
          if (user == null) {
            return Center(child: Text(context.tr('failed_to_load_profile')));
          }

          final displayName = user.name.trim();
          final avatarUrl = user.avatarUrl;
          final initial = displayName.isNotEmpty
              ? displayName[0].toUpperCase()
              : '?';

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile header banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: AppColors.primary,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? Text(
                                initial,
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
                        displayName.isNotEmpty ? displayName : 'User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                      if (user.email != null && user.email!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.email!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Bio Description section
                if (user.bio != null && user.bio!.isNotEmpty) ...[
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
                        Text(
                          user.bio!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                ],

                // Action buttons area
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: PrimaryButton(
                    text: context.tr('edit_profile'),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(user: user),
                        ),
                      );
                      if (mounted) {
                        profileViewModel.fetchCurrentProfile();
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: SecondaryButton(
                    text: context.tr('logout'),
                    onPressed: () => _showLogoutDialog(context),
                    borderColor: AppColors.warning,
                    textColor: AppColors.warning,
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
