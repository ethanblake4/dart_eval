import 'dart:convert';
import 'dart:io';

import 'package:dart_eval/dart_eval_bridge.dart';

/// The source workload used by the native package:http integration test.
List<DartSource> httpNativeSources(String url) {
  final configFile = File('.dart_tool/package_config.json');
  final packageConfig =
      jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
  final packages = (packageConfig['packages'] as List)
      .cast<Map<String, dynamic>>();
  const dependencyNames = {
    'http',
    'http_parser',
    'async',
    'meta',
    'web',
    'string_scanner',
    'typed_data',
    'collection',
    'source_span',
    'path',
    'term_glyph',
  };
  final sources = <DartSource>[];
  for (final package in packages.where(
    (package) => dependencyNames.contains(package['name']),
  )) {
    final name = package['name'] as String;
    final root = Directory.fromUri(Uri.parse('${package['rootUri']}/lib/'));
    for (final file in root.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final path = file.path.substring(root.path.length).replaceAll('\\', '/');
      sources.add(DartSource.file('package:$name/$path', file));
    }
  }
  sources.add(
    DartSource('package:probe/main.dart', '''
        import 'package:http/http.dart' as http;

        Future<String> main() async {
          final response = await http.get(Uri.parse('$url'));
          return response.body;
        }
      '''),
  );
  return sources;
}
