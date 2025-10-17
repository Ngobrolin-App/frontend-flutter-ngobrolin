import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String name;
  final String username;
  final String? avatarUrl;

  const UserProfileScreen({
    Key? key,
    required this.userId,
    required this.name,
    required this.username,
    this.avatarUrl,
  }) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // Mock user data
  late Map<String, dynamic> _userData;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _userData = {
      'id': widget.userId,
      'name': widget.name,
      'username': widget.username,
      'bio': 'Hello, I am using Ngobrolin!', // Mock bio
      'avatarUrl': widget.avatarUrl,
    };

    // Check if user is blocked
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _isBlocked = settingsProvider.blockedAccounts.contains(widget.userId);
  }

  void _startChat() {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.chat,
      arguments: {'userId': widget.userId, 'name': widget.name, 'avatarUrl': widget.avatarUrl},
    );
  }

  void _toggleBlockUser() {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    if (_isBlocked) {
      // Unblock user
      settingsProvider.unblockAccount(widget.userId);
      setState(() {
        _isBlocked = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.name} has been unblocked'), backgroundColor: Colors.green),
      );
    } else {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr('block_account')),
          content: Text(context.tr('are_you_sure_block')),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.tr('no'))),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();

                // Block user
                settingsProvider.blockAccount(widget.userId);
                setState(() {
                  _isBlocked = true;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${widget.name} has been blocked'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text(context.tr('yes'), style: const TextStyle(color: AppColors.warning)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('profile'))),
      body: SingleChildScrollView(
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
                    backgroundImage: _userData['avatarUrl'] != null
                        ? NetworkImage(_userData['avatarUrl'])
                        : null,
                    child: _userData['avatarUrl'] == null
                        ? Text(
                            _userData['name'][0].toUpperCase(),
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
                    _userData['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Username
                  Text(
                    '@${_userData['username']}',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Bio
            if (_userData['bio'] != null && _userData['bio'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('bio'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_userData['bio'], style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),

            const Divider(),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Start chat button (only if not blocked)
                  if (!_isBlocked)
                    PrimaryButton(
                      text: context.tr('start_chat'),
                      onPressed: _startChat,
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                    ),

                  const SizedBox(height: 16),

                  // Block/Unblock button
                  OutlinedButton.icon(
                    onPressed: _toggleBlockUser,
                    icon: Icon(
                      _isBlocked ? Icons.person_add : Icons.block,
                      color: _isBlocked ? AppColors.primary : AppColors.warning,
                    ),
                    label: Text(
                      _isBlocked ? context.tr('unblock_user') : context.tr('block_account'),
                      style: TextStyle(color: _isBlocked ? AppColors.primary : AppColors.warning),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _isBlocked ? AppColors.primary : AppColors.warning),
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
