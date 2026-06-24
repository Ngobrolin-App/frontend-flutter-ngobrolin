import 'package:ngobrolin_app/core/localization/language/en_us.dart';
import 'package:ngobrolin_app/core/localization/language/id_id.dart';
import 'package:ngobrolin_app/core/localization/language/ja_jp.dart';
import 'package:ngobrolin_app/core/localization/language/zh_cn.dart';
import 'package:ngobrolin_app/core/models/language_model.dart';

final List<LanguageModel> supportedLanguages = [
  LanguageModel(
    languageCode: 'id',
    countryCode: 'ID',
    name: 'Indonesia',
    translations: idID,
  ),
  LanguageModel(
    languageCode: 'en',
    countryCode: 'US',
    name: 'English',
    translations: enUS,
  ),
  LanguageModel(
    languageCode: 'ja',
    countryCode: 'JP',
    name: 'Japanese',
    translations: jaJP,
  ),
  LanguageModel(
    languageCode: 'zh',
    countryCode: 'CN',
    name: 'Chinese (Simplified)',
    translations: zhCN,
  ),
];

final LanguageModel defaultLanguage = supportedLanguages.first;
