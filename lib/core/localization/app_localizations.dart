import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ngobrolin_app/core/localization/language_constants.dart';
import 'package:ngobrolin_app/core/models/language_model.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Locale defaultLocale = Locale(
    defaultLanguage.languageCode,
    defaultLanguage.countryCode,
  );

  static final List<Locale> supportedLocales = supportedLanguages
      .map((l) => Locale(l.languageCode, l.countryCode))
      .toList();

  static final Set<String> supportedCodes = supportedLanguages
      .map((l) => l.languageCode)
      .toSet();

  static bool isSupported(Locale locale) =>
      supportedCodes.contains(locale.languageCode);

  static final Map<String, LanguageModel> _languageMap = {
    for (var lang in supportedLanguages) lang.languageCode: lang,
  };

  String translate(String key) {
    final language = _languageMap[locale.languageCode] ?? _languageMap['en'];
    return language?.translations[key] ?? key;
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';

    // Konversi ke waktu lokal HP pengguna
    final localDate = date.toLocal();
    final DateFormat formatter = DateFormat.yMMMd(locale.toString());
    return formatter.format(localDate);
  }

  String formatTime(DateTime time) {
    final DateTime localTime = time.toLocal();
    final DateFormat formatter = DateFormat.Hm(locale.toString());
    return formatter.format(localTime);
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Panggil method static yang baru Anda buat
    return AppLocalizations.isSupported(locale);
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
