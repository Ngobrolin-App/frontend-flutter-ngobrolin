import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../repositories/settings_repository.dart';
import '../base_view_model.dart';

class SettingsViewModel extends BaseViewModel {
  final SettingsRepository _settingsRepository;

  Locale _locale = const Locale('id');
  Locale get locale => _locale;

  bool _privateAccount = false;
  bool get privateAccount => _privateAccount;

  SettingsViewModel({SettingsRepository? settingsRepository})
    : _settingsRepository = settingsRepository ?? SettingsRepository() {
    initSettings();
  }

  /// Initializes settings from storage
  Future<void> initSettings() async {
    setLoading(true);
    try {
      // Load locale
      _locale = await _settingsRepository.getLocale();

      // Load private account setting
      _privateAccount = await _settingsRepository.getPrivateAccountSetting();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  /// Sets the application locale
  void setLocale(Locale locale) async {
    try {
      await _settingsRepository.setLocale(locale);
      _locale = locale;
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Toggles private account setting
  Future<bool> togglePrivateAccount(bool value) async {
    return await runBusyFuture(() async {
          try {
            final success = await _settingsRepository
                .updatePrivateAccountSetting(value);
            if (success) {
              _privateAccount = value;
            }
            return success;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Blocks a user account
  Future<bool> blockAccount(String userId, String username, String name) async {
    return await runBusyFuture(() async {
          try {
            final success = await _settingsRepository.blockUser(userId);

            return success;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Unblocks a user account
  Future<bool> unblockAccount(String userId) async {
    return await runBusyFuture(() async {
          try {
            final success = await _settingsRepository.unblockUser(userId);

            return success;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Checks if a user is blocked
  Future<bool> isUserBlocked(String userId) async {
    try {
      // If not in cache, check with API
      return await _settingsRepository.isUserBlocked(userId);
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }
}
