import 'flavor.dart';

class FlavorConfig {
  final Flavor flavor;
  final String appName;

  static FlavorConfig? _instance;

  FlavorConfig._({required this.flavor, required this.appName});

  static void initialize({required Flavor flavor, required String appName}) {
    _instance = FlavorConfig._(flavor: flavor, appName: appName);
  }

  static FlavorConfig get instance {
    if (_instance == null) {
      throw Exception('FlavorConfig belum diinisialisasi');
    }

    return _instance!;
  }

  static bool get isDev => _instance?.flavor == Flavor.dev;

  static bool get isProd => _instance?.flavor == Flavor.prod;
}
