import 'dart:convert';
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
  String path;
  final workspaceRefFile =
      File(join(projectRoot.path, '.dart_tool', 'pub', 'workspace_ref.json'));
  if (workspaceRefFile.existsSync()) {
    final workspaceRef = workspaceRefFile.readAsStringSync();
    final workspaceRefMap = json.decode(workspaceRef) as Map<String, dynamic>;
    final workspacePath = workspaceRefMap['workspaceRoot'] as String;
    path = join(normalize('${projectRoot.path}/.dart_tool/pub/$workspacePath'),
        '.dart_tool', 'package_config.json');
  } else {
    path = join(projectRoot.path, '.dart_tool', 'package_config.json');
  }
  final packageConfigFile = File(path).readAsStringSync();
  return PackageConfig.parseString(packageConfigFile, Uri.file(path));
}
