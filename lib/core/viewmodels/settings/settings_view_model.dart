import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../repositories/settings_repository.dart';
import '../base_view_model.dart';

class SettingsViewModel extends BaseViewModel {
  final SettingsRepository _settingsRepository;

  Locale _locale = const Locale('id');
  Locale get locale => _locale;

  bool _privateAccount = false;
  bool get privateAccount => _privateAccount;

  final Set<String> _blockedAccounts = {};
  Set<String> get blockedAccounts => _blockedAccounts;

  List<Map<String, dynamic>> _blockedUsers = [];
  List<Map<String, dynamic>> get blockedUsers => _blockedUsers;

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

      // Load blocked users
      await fetchBlockedUsers();
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
            final success = await _settingsRepository.updatePrivateAccountSetting(value);
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

            if (success) {
              _blockedAccounts.add(userId);

              // Add to blocked users list
              _blockedUsers.add({
                'id': userId,
                'username': username,
                'name': name,
                'avatarUrl': null,
              });
            }

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

            if (success) {
              _blockedAccounts.remove(userId);
              _blockedUsers.removeWhere((user) => user['id'] == userId);
            }

            return success;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Fetches the list of blocked users
  Future<bool> fetchBlockedUsers() async {
    return await runBusyFuture(() async {
          try {
            final users = await _settingsRepository.getBlockedUsers();

            // Update blocked accounts set
            _blockedAccounts.clear();
            for (final user in users) {
              _blockedAccounts.add(user.id);
            }

            // Convert to map format for compatibility with existing UI
            _blockedUsers = users
                .map(
                  (user) => {
                    'id': user.id,
                    'username': user.username,
                    'name': user.name,
                    'avatarUrl': user.avatarUrl,
                  },
                )
                .toList();

            return true;
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
      // Check local cache first
      if (_blockedAccounts.contains(userId)) {
        return true;
      }

      // If not in cache, check with API
      return await _settingsRepository.isUserBlocked(userId);
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }
}
