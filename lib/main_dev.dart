import 'bootstrap.dart';
import 'flavors/flavor.dart';
import 'flavors/flavor_config.dart';

void main() {
  FlavorConfig.initialize(flavor: Flavor.dev, appName: 'Ngobrolin Dev');

  bootstrap();
}
