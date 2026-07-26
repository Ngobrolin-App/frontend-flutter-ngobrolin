import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:ngobrolin_app/core/widgets/cards/app_avatar.dart';
import 'package:ngobrolin_app/core/widgets/states/image_error_placeholder.dart';
import 'package:ngobrolin_app/core/widgets/texts/expandable_text_section.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/viewmodels/profile/profile_view_model.dart';
import '../../../core/widgets/buttons/primary_button.dart';
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
      context.read<ProfileViewModel>().fetchCurrentProfile();
    });
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
                          imageUrl: avatarUrl,
                          name: user.name,
                          radius: 50,
                          fontSize: 40,
                          backgroundColor: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName.isNotEmpty ? displayName : 'User',
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
                    padding: const EdgeInsets.all(20),
                    child: ExpandableTextSection(
                      title: context.tr('bio'),
                      content: user.bio!,
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
                      if (mounted) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.editProfile,
                          arguments: {'user': user},
                        ).then((onValue) {
                          profileViewModel.fetchCurrentProfile();
                        });
                      }
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
