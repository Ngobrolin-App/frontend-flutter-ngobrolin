class LanguageModel {
  final String languageCode;
  final String countryCode;
  final String name;
  final Map<String, String> translations;

  LanguageModel({
    required this.languageCode,
    required this.countryCode,
    required this.name,
    required this.translations,
  });
}
