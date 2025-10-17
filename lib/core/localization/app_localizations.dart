import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'language/en_us.dart';
import 'language/id_id.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {'en': enUS, 'id': idID};

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  String formatDate(DateTime date) {
    final DateFormat formatter = DateFormat.yMMMd(locale.toString());
    return formatter.format(date);
  }

  String formatTime(DateTime time) {
    final DateFormat formatter = DateFormat.Hm(locale.toString());
    return formatter.format(time);
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'id'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizationExtension on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this);

  String tr(String key) => AppLocalizations.of(this).translate(key);
}
