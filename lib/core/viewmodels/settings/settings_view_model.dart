import 'package:flutter/material.dart';
import '../../repositories/settings_repository.dart';
import '../base_view_model.dart';
import 'dart:developer' as developer;

/// ViewModel responsible for managing application configuration preferences,
/// localizing language assets, and mutating private security boundaries.
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

  /// Initializes system properties and security flags from device disk or remote networks.
  Future<void> initSettings() async {
    setLoading(true);
    try {
      // Synchronizes localization language elements
      _locale = await _settingsRepository.getLocale();

      // Synchronizes core structural privacy options
      final result = await _settingsRepository.getPrivateAccountSetting();
      final user = result.data;
      _privateAccount = user?.isPrivate ?? false;

      notifyListeners();
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

  /// Persists and updates the context locale language identifier across app states.
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

  /// Toggles visibility profiles by mutating the core account status flags.
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

  /// Registers a restriction block sequence target against a user profile ID registry index.
  Future<bool> blockAccount(String userId) async {
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

  /// Dismantles relationship restrictions by purging targeted user credentials from local registries.
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

  /// Inspects targeted network or cache systems to confirm structural block policies.
  Future<bool> isUserBlocked(String userId) async {
    try {
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
