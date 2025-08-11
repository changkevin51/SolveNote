import 'package:saber/main_common.dart' as common;
import 'package:saber/data/flavor_config.dart';

Future<void> main(List<String> args) async {
  FlavorConfig.setup(
    flavor: const String.fromEnvironment('FLAVOR'),
    appStore: const String.fromEnvironment('APP_STORE'),
    dirty: const bool.fromEnvironment('DIRTY', defaultValue: false),
  );

  await common.main(args);
}
