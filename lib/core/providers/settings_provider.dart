import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  Locale _locale = const Locale('id');
  Locale get locale => _locale;

  bool _privateAccount = false;
  bool get privateAccount => _privateAccount;

  final Set<String> _blockedAccounts = {};
  Set<String> get blockedAccounts => _blockedAccounts;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  void togglePrivateAccount(bool value) {
    _privateAccount = value;
    notifyListeners();
  }

  void blockAccount(String userId) {
    _blockedAccounts.add(userId);
    notifyListeners();
  }

  void unblockAccount(String userId) {
    _blockedAccounts.remove(userId);
    notifyListeners();
  }
}
