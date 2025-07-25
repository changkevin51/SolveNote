import 'package:flutter/material.dart';
import 'package:saber/main_common.dart' as common;
import 'package:saber/data/flavor_config.dart';

Future<void> main(List<String> args) async {
  FlavorConfig.setup(
    flavor: const String.fromEnvironment('FLAVOR'),
    appStore: const String.fromEnvironment('APP_STORE'),
    shouldCheckForUpdatesByDefault:
        const bool.fromEnvironment('UPDATE_CHECK', defaultValue: true),
    dirty: const bool.fromEnvironment('DIRTY', defaultValue: false),
  );

  await common.main(args);
}
