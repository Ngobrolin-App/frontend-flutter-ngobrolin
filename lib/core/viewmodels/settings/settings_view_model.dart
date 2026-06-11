import 'package:flutter/material.dart';
import '../../repositories/settings_repository.dart';
import '../base_view_model.dart';
import 'dart:developer' as developer;

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
      final result = await _settingsRepository.getPrivateAccountSetting();
      final user = result.data;
      _privateAccount = user?.isPrivate ?? false;
    } catch (e) {
      developer.log(
        'SettingsViewModel - initSettings() error: $e',
        name: 'SettingsViewModel',
      );
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
      developer.log(
        'SettingsViewModel - setLocale() error: $e',
        name: 'SettingsViewModel',
      );
      setError(e.toString());
    }
  }

  /// Toggles private account setting
  Future<bool> togglePrivateAccount(bool value) async {
    return await runBusyFuture(() async {
          try {
            final result = await _settingsRepository
                .updatePrivateAccountSetting(value);

            final updatedUser = result.data;

            _privateAccount = updatedUser?.isPrivate ?? value;
            notifyListeners();

            return result.isSuccess;
          } catch (e) {
            developer.log(
              'SettingsViewModel - togglePrivateAccount() error: $e',
              name: 'SettingsViewModel',
            );
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
            final result = await _settingsRepository.blockUser(userId);
            final success = result.isSuccess;

            setSuccess(result.message);

            return success;
          } catch (e) {
            developer.log(
              'SettingsViewModel - blockAccount() error: $e',
              name: 'SettingsViewModel',
            );
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
            final result = await _settingsRepository.unblockUser(userId);
            final success = result.isSuccess;

            setSuccess(result.message);

            return success;
          } catch (e) {
            developer.log(
              'SettingsViewModel - unblockAccount() error: $e',
              name: 'SettingsViewModel',
            );
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
      developer.log(
        'SettingsViewModel - isUserBlocked() error: $e',
        name: 'SettingsViewModel',
      );
      setError(e.toString());
      return false;
    }
  }
}
