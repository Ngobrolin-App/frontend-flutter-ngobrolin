import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/viewmodels/auth/auth_view_model.dart';
import '../../../core/viewmodels/profile/profile_view_model.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/secondary_button.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);
      profileViewModel.initWithUserData({
        'id': 'current_user',
        'name': 'Current User',
        'username': 'currentuser',
        'bio': 'Hello, I am using Ngobrolin!',
        'avatarUrl': null,
      });
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('logout')),
        content: Text(context.tr('are_you_sure_logout')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('no')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout(context);
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

  void _logout(BuildContext context) async {
    // Use both old and new providers for backward compatibility
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    // Sign out from both
    authProvider.signOut();
    authViewModel.signOut();

    // Navigate to login screen
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final profileViewModel = Provider.of<ProfileViewModel>(context);
    final userData = profileViewModel.userData;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profile')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.settingsRoute);
            },
          ),
        ],
      ),
      body: profileViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    color: AppColors.primary,
                    child: Column(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: userData['avatarUrl'] != null
                              ? NetworkImage(userData['avatarUrl'])
                              : null,
                          child: userData['avatarUrl'] == null
                              ? Text(
                                  userData['name'][0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Name
                        Text(
                          userData['name'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Username
                        Text(
                          '@${userData['username']}',
                          style: const TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  // Bio
                  if (userData['bio'] != null && userData['bio'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            userData['bio'],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),

                  const Divider(),

                  // Edit profile button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: PrimaryButton(
                      text: context.tr('edit_profile'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProfileScreen(userData: userData),
                          ),
                        );
                      },
                    ),
                  ),

                  // Logout button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SecondaryButton(
                      text: context.tr('logout'),
                      onPressed: () => _showLogoutDialog(context),
                      borderColor: AppColors.warning,
                      textColor: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
