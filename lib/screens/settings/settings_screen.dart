import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/settings_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings')),
      ),
      body: ListView(
        children: [
          // Language settings
          ListTile(
            title: Text(context.tr('app_language')),
            subtitle: Text(
              settingsProvider.locale.languageCode == 'en' ? 'English' : 'Indonesia',
            ),
            leading: const Icon(Icons.language),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageDialog(context),
          ),
          
          const Divider(),
          
          // Private account toggle
          SwitchListTile(
            title: Text(context.tr('private_account')),
            subtitle: Text(context.tr('private_account_description')),
            value: settingsProvider.privateAccount,
            onChanged: (value) {
              settingsProvider.togglePrivateAccount(value);
            },
            secondary: const Icon(Icons.lock_outline),
          ),
          
          const Divider(),
          
          // Blocked users
          ListTile(
            title: Text(context.tr('blocked_users')),
            leading: const Icon(Icons.block),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.blockedUsers);
            },
          ),
          
          const Divider(),
          
          // About app
          ListTile(
            title: const Text('About Ngobrolin'),
            leading: const Icon(Icons.info_outline),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('app_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // English option
            ListTile(
              title: const Text('English'),
              leading: Radio<String>(
                value: 'en',
                groupValue: settingsProvider.locale.languageCode,
                onChanged: (value) {
                  if (value != null) {
                    settingsProvider.setLocale(const Locale('en'));
                    Navigator.of(context).pop();
                  }
                },
              ),
              onTap: () {
                settingsProvider.setLocale(const Locale('en'));
                Navigator.of(context).pop();
              },
            ),
            
            // Indonesian option
            ListTile(
              title: const Text('Indonesia'),
              leading: Radio<String>(
                value: 'id',
                groupValue: settingsProvider.locale.languageCode,
                onChanged: (value) {
                  if (value != null) {
                    settingsProvider.setLocale(const Locale('id'));
                    Navigator.of(context).pop();
                  }
                },
              ),
              onTap: () {
                settingsProvider.setLocale(const Locale('id'));
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('cancel')),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'Ngobrolin',
        applicationVersion: '1.0.0',
        applicationIcon: Image.asset(
          'assets/apps_logo/app-icon-ngobrolin-enhanced-transparent.png',
          width: 50,
          height: 50,
        ),
        applicationLegalese: '© 2023 Ngobrolin',
        children: [
          const SizedBox(height: 16),
          const Text(
            'Ngobrolin is a chat application that allows you to connect with friends and family.',
          ),
        ],
      ),
    );
  }
}