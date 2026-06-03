import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  Locale _locale = const Locale('id');
  Locale get locale => _locale;

  bool _privateAccount = false;
  bool get privateAccount => _privateAccount;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  void togglePrivateAccount(bool value) {
    _privateAccount = value;
    notifyListeners();
  }
}
