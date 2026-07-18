import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/core/localization/language/en_us.dart';
import 'package:ngobrolin_app/core/localization/language_constants.dart';
import 'package:ngobrolin_app/core/models/language_model.dart';
import '../../repositories/settings_repository.dart';
import '../base_view_model.dart';

class SettingsViewModel extends BaseViewModel {
  final SettingsRepository _settingsRepository;

  Locale _locale = AppLocalizations.defaultLocale;
  Locale get locale => _locale;

  bool _privateAccount = false;
  bool get privateAccount => _privateAccount;

  static const String _logName = 'SettingsViewModel';

  String getLanguageName(String code) {
    final lang = supportedLanguages.firstWhere(
      (lang) => lang.languageCode == code,
      orElse: () => LanguageModel(
        languageCode: 'en',
        countryCode: 'US',
        name: 'English',
        translations: enUS,
      ),
    );
    return lang.name;
  }

  SettingsViewModel({SettingsRepository? settingsRepository})
    : _settingsRepository = settingsRepository ?? SettingsRepository() {
    initSettings();
  }

  Future<void> initSettings() async {
    await runBusyFuture(
      () async {
        _locale = await _settingsRepository.getLocale();

        final result = await _settingsRepository.getPrivateAccountSetting();
        final user = result.data;
        _privateAccount = user?.isPrivate ?? false;

        notifyListeners();
      },
      logName: _logName,
      logContext: 'initSettings()',
    );
  }

  Future<void> setLocale(Locale locale) async {
    await runBusyFuture(
      () async {
        await _settingsRepository.setLocale(locale);
        _locale = locale;
        notifyListeners();
      },
      logName: _logName,
      logContext: 'setLocale()',
    );
  }

  Future<bool> togglePrivateAccount(bool value) async {
    return await runBusyFuture(
          () async {
            final result = await _settingsRepository
                .updatePrivateAccountSetting(value);
            final updatedUser = result.data;

            _privateAccount = updatedUser?.isPrivate ?? value;
            notifyListeners();

            return result.isSuccess;
          },
          logName: _logName,
          logContext: 'togglePrivateAccount()',
        ) ??
        false;
  }

  Future<bool> blockAccount(String userId) async {
    return await runBusyFuture(
          () async {
            final result = await _settingsRepository.blockUser(userId);
            setSuccess(result.message);
            return result.isSuccess;
          },
          logName: _logName,
          logContext: 'blockAccount()',
        ) ??
        false;
  }

  Future<bool> unblockAccount(String userId) async {
    return await runBusyFuture(
          () async {
            final result = await _settingsRepository.unblockUser(userId);
            setSuccess(result.message);
            return result.isSuccess;
          },
          logName: _logName,
          logContext: 'unblockAccount()',
        ) ??
        false;
  }
}
