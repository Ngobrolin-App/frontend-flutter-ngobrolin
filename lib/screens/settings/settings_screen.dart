import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/fa.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:iconify_flutter/icons/ic.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/viewmodels/settings/settings_view_model.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsViewModel = Provider.of<SettingsViewModel>(context, listen: false);
      settingsViewModel.initSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final settingsViewModel = Provider.of<SettingsViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings'))),
      body: settingsViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Language settings
                ListTile(
                  title: Text(context.tr('app_language')),
                  subtitle: Text(
                    settingsViewModel.locale.languageCode == 'en' ? 'English' : 'Indonesia',
                  ),
                  leading: const Iconify(Fa.language, color: AppColors.text),
                  trailing: const Iconify(
                    MaterialSymbols.arrow_forward_ios_rounded,
                    color: AppColors.text,
                    size: 16,
                  ),
                  onTap: () => _showLanguageDialog(context),
                ),

                const Divider(),

                // Private account toggle
                SwitchListTile(
                  title: Text(context.tr('private_account')),
                  subtitle: Text(context.tr('private_account_description')),
                  value: settingsViewModel.privateAccount,
                  onChanged: (value) async {
                    // Update both old and new providers
                    await settingsViewModel.togglePrivateAccount(value);
                    settingsProvider.togglePrivateAccount(value);
                  },
                  secondary: const Iconify(MaterialSymbols.lock_outline, color: AppColors.text),
                ),

                const Divider(),

                // Blocked users
                ListTile(
                  title: Text(context.tr('blocked_users')),
                  leading: const Iconify(Ic.round_block, color: AppColors.text),
                  trailing: const Iconify(
                    MaterialSymbols.arrow_forward_ios_rounded,
                    color: AppColors.text,
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.blockedUsers);
                  },
                ),

                const Divider(),

                // About app
                ListTile(
                  title: Text(context.tr('about_ngobrolin')),
                  leading: const Iconify(Mdi.information_outline, color: AppColors.text),
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
    final settingsViewModel = Provider.of<SettingsViewModel>(context, listen: false);

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
                groupValue: settingsViewModel.locale.languageCode,
                onChanged: (value) {
                  if (value != null) {
                    // Update both old and new providers
                    settingsViewModel.setLocale(const Locale('en'));
                    settingsProvider.setLocale(const Locale('en'));
                    Navigator.of(context).pop();
                  }
                },
              ),
              onTap: () {
                // Update both old and new providers
                settingsViewModel.setLocale(const Locale('en'));
                settingsProvider.setLocale(const Locale('en'));
                Navigator.of(context).pop();
              },
            ),

            // Indonesian option
            ListTile(
              title: const Text('Indonesia'),
              leading: Radio<String>(
                value: 'id',
                groupValue: settingsViewModel.locale.languageCode,
                onChanged: (value) {
                  if (value != null) {
                    // Update both old and new providers
                    settingsViewModel.setLocale(const Locale('id'));
                    settingsProvider.setLocale(const Locale('id'));
                    Navigator.of(context).pop();
                  }
                },
              ),
              onTap: () {
                // Update both old and new providers
                settingsViewModel.setLocale(const Locale('id'));
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
        applicationName: context.tr('app_name'),
        applicationVersion: '1.0.0',
        applicationIcon: Image.asset(
          'assets/apps_logo/app-icon-ngobrolin-enhanced-transparent.png',
          width: 50,
          height: 50,
        ),
        applicationLegalese: context.tr('2025_ngobrolin'),
        children: [const SizedBox(height: 16), Text(context.tr('about_ngobrolin_description'))],
      ),
    );
  }
}
