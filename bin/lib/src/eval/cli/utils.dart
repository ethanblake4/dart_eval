import 'dart:io';

import 'package:package_config/package_config_types.dart';
import 'package:path/path.dart';

Directory findProjectRoot(Directory start) {
  var projectRoot = start;
  while (true) {
    final files = projectRoot.listSync();
    if (files
        .any((file) => (file is File && file.path.endsWith('pubspec.yaml')))) {
      break;
    }
    projectRoot = projectRoot.parent;
  }
  return projectRoot;
}

PackageConfig getPackageConfig(Directory projectRoot) {
  final path = join(projectRoot.path, '.dart_tool', 'package_config.json');
  final packageConfigFile = File(path).readAsStringSync();
  return PackageConfig.parseString(packageConfigFile, Uri.parse(path));
}
