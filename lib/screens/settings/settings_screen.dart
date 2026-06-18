import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/fa.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:iconify_flutter/icons/ic.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/viewmodels/settings/settings_view_model.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<SettingsViewModel>(context, listen: false).initSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    // OPTIMASI: Jangan dengarkan perubahan (listen: false) di tingkat atas build
    // untuk mencegah pemborosan siklus rendering Scaffold & AppBar.
    final settingsViewModel = Provider.of<SettingsViewModel>(
      context,
      listen: false,
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings'))),
      body: Selector<SettingsViewModel, bool>(
        selector: (_, vm) => vm.isLoading,
        builder: (context, isLoading, _) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              // Language settings area
              Selector<SettingsViewModel, Locale>(
                selector: (_, vm) => vm.locale,
                builder: (context, locale, _) {
                  return ListTile(
                    title: Text(context.tr('app_language')),
                    subtitle: Text(
                      locale.languageCode == 'en' ? 'English' : 'Indonesia',
                    ),
                    leading: const Iconify(Fa.language, color: AppColors.text),
                    trailing: const Iconify(
                      MaterialSymbols.arrow_forward_ios_rounded,
                      color: AppColors.text,
                      size: 16,
                    ),
                    onTap: () => _showLanguageDialog(context),
                  );
                },
              ),

              const Divider(),

              // OPTIMASI: Isolasi SwitchListTile menggunakan Selector khusus
              // Widget hanya akan rebuild jika nilai 'privateAccount' benar-benar berubah.
              Selector<SettingsViewModel, bool>(
                selector: (_, vm) => vm.privateAccount,
                builder: (context, isPrivate, _) {
                  return SwitchListTile(
                    title: Text(context.tr('private_account')),
                    subtitle: Text(context.tr('private_account_description')),
                    value: isPrivate,
                    onChanged: (value) async {
                      await settingsViewModel.togglePrivateAccount(value);
                    },
                    secondary: const Iconify(
                      MaterialSymbols.lock_outline,
                      color: AppColors.text,
                    ),
                  );
                },
              ),

              const Divider(),

              // Blocked users link
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

              // About application
              ListTile(
                title: Text(context.tr('about_ngobrolin')),
                leading: const Iconify(
                  Mdi.information_outline,
                  color: AppColors.text,
                ),
                onTap: () {
                  _showAboutDialog(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final settingsViewModel = Provider.of<SettingsViewModel>(
      context,
      listen: false,
    );
    final currentLanguageCode = settingsViewModel.locale.languageCode;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('app_language')),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(dialogContext.tr('English')),
              value: 'en',
              groupValue: currentLanguageCode,
              onChanged: (value) =>
                  _changeLanguage(dialogContext, value, settingsViewModel),
            ),
            RadioListTile<String>(
              title: Text(dialogContext.tr('Indonesia')),
              value: 'id',
              groupValue: currentLanguageCode,
              onChanged: (value) =>
                  _changeLanguage(dialogContext, value, settingsViewModel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.tr('cancel')),
          ),
        ],
      ),
    );
  }

  void _changeLanguage(
    BuildContext dialogContext,
    String? value,
    SettingsViewModel viewModel,
  ) {
    if (value != null) {
      final newLocale = Locale(value);
      viewModel.setLocale(newLocale);
      Navigator.of(dialogContext).pop();
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AboutDialog(
        applicationName: dialogContext.tr('app_name'),
        applicationVersion: '1.0.0',
        applicationIcon: Image.asset(
          'assets/apps_logo/app-icon-ngobrolin-enhanced-transparent.png',
          width: 50,
          height: 50,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.apps, size: 50, color: AppColors.primary),
        ),
        applicationLegalese: dialogContext.tr('2025_ngobrolin'),
        children: [
          const SizedBox(height: 16),
          Text(dialogContext.tr('about_ngobrolin_description')),
        ],
      ),
    );
  }
}
