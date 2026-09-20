import 'dart:convert';
import 'dart:io';

import 'package:change_case/change_case.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bindgen/bindgen.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';
import 'package:dart_eval/src/eval/cli/utils.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:yaml/yaml.dart' show loadYaml, YamlList;

const defaultImports = '''
// ignore_for_file: unused_import, unnecessary_import
// ignore_for_file: always_specify_types, avoid_redundant_argument_values
// ignore_for_file: sort_constructors_first
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: prefer_is_empty
// ignore_for_file: undefined_hidden_name
// ignore_for_file: dead_code, unused_local_variable
// ignore_for_file: unnecessary_type_check, unnecessary_non_null_assertion
// ignore_for_file: sdk_version_since
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: argument_type_not_assignable_to_error_handler
// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
''';

const registryImports = '''
// ignore_for_file: unused_import, unnecessary_import

import 'package:dart_eval/dart_eval_bridge.dart';
''';

void cliBind({
  bool singleFile = false,
  bool all = false,
  bool generatePlugin = true,
}) async {
  print('Loading files...');
  final commandRoot = Directory(current);
  final projectRoot = findProjectRoot(commandRoot);

  final bindgen = Bindgen();

  _loadBindingJsons(bindgen, projectRoot);

  final packageConfig = getPackageConfig(projectRoot);

  final pubspecFile = File(join(projectRoot.path, 'pubspec.yaml'));
  final pubspec = Pubspec.parse(pubspecFile.readAsStringSync());
  final packageName = pubspec.name;

  final version = Version.parse(Platform.version.split(' ').first);
  final formatter = DartFormatter(languageVersion: version);
  for (final package in packageConfig.packages) {
    if (package.name == packageName) {
      bindgen.inject(package: package);
      break;
    }
  }

  var singleResult = '';
  var numBound = 0;

  final analyzePath = join(projectRoot.path, 'analysis_options.yaml');
  final excludes = readAnalyzerExcludes(File(analyzePath));

  Future<void> bindLoop(String pkg, Directory dir, String root) async {
    if (!dir.existsSync()) return;
    for (final file in dir.listSync()) {
      final filename = basename(file.path);
      if (file is File &&
          filename.endsWith('.dart') &&
          !filename.endsWith('.eval.dart')) {
        final p = relative(file.path, from: root).replaceAll('\\', '/');
        if (excludes.any((e) => e.matches(p))) continue;
        final uri = 'package:${posix.join(packageName, p)}';
        final output = await bindgen.parse(file, filename, uri, all);
        if (output != null) {
          print('Bound ${file.path}');
          numBound++;
          if (singleFile) {
            final ogImport = "import '$uri';\n";
            singleResult = ogImport + singleResult + output;
          } else {
            final ogImport = "import '$filename';\n";
            final outputFilename = filename.replaceAll('.dart', '.eval.dart');
            final outputFile = File(join(dir.path, outputFilename));
            final result = formatter.format(
              defaultImports + ogImport + output,
              uri: Uri.parse(uri),
            );
            outputFile.writeAsStringSync(result);
          }
        }
      } else if (file is Directory) {
        await bindLoop(pkg, file, root);
      }
    }
  }

  await bindLoop(
    packageName,
    Directory(join(projectRoot.path, 'lib')),
    join(projectRoot.path, 'lib'),
  );

  if (singleFile) {
    final outPath = join(projectRoot.path, 'lib', 'dart_eval_bindings.dart');
    final outputFile = File(outPath);
    final result = formatter.format(
      defaultImports + singleResult,
      uri: Uri.parse('package:$packageName/dart_eval_bindings.dart'),
    );
    outputFile.writeAsStringSync(result);
  }

  if (generatePlugin) {
    final pluginFile = File(join(projectRoot.path, 'lib', 'eval_plugin.dart'));
    final pluginContent =
        '''
import 'package:dart_eval/dart_eval_bridge.dart';
${[...bindgen.registerClasses, ...bindgen.registerEnums].map((e) => e.uri.substring(e.uri.indexOf('/') + 1)).toSet().map((e) => 'import \'${e.replaceAll('.dart', '.eval.dart')}\';').join('\n')}

/// [EvalPlugin] for $packageName
class ${packageName.toPascalCase()}Plugin implements EvalPlugin {
  @override
  String get identifier => 'package:${packageName.toLowerCase()}';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    ${bindgen.registerClasses.map((e) => 'registry.defineBridgeClass(\$${e.name}.\$declaration);').join('\n')}
    ${bindgen.registerEnums.map((e) => 'registry.defineBridgeEnum(\$${e.name}.\$declaration);').join('\n')}
    ${bindgen.registerFunctions.map((e) => 'registry.defineBridgeTopLevelFunction(\$${e.name}Fn.\$declaration);').join('\n')}
  }

  @override
  void configureForRuntime(Runtime runtime) {
    ${bindgen.registerClasses.map((e) => '\$${e.name}.configureForRuntime(runtime);').join('\n')}
    ${bindgen.registerEnums.map((e) => '\$${e.name}.configureForRuntime(runtime);').join('\n')}
    ${bindgen.registerFunctions.map((e) => '\$${e.name}Fn.configureForRuntime(runtime);').join('\n')}
  }
}
''';
    pluginFile.writeAsStringSync(
      formatter.format(
        pluginContent,
        uri: Uri.parse('package:$packageName/eval_plugin.dart'),
      ),
    );
    print('Generated plugin file: ${pluginFile.path}');
  } else {
    print('Skipping plugin generation.');
  }

  if (numBound == 0) {
    print(
      'No files were bound. You may need to add the @Bind annotation from '
      'the eval_annotation package, or pass the --all flag to bind all classes.',
    );
  } else {
    print('Created bindings for $numBound files.');
  }
}

/// Config-driven binding entry point: `dart_eval bind --config <yaml>`.
void cliBindFromConfig(String configPath) async {
  final commandRoot = Directory(current);
  final projectRoot = findProjectRoot(commandRoot);
  final configFile = File(
    isAbsolute(configPath) ? configPath : join(projectRoot.path, configPath),
  );
  if (!configFile.existsSync()) {
    print('Config file not found: ${configFile.path}');
    return;
  }
  final config = BindgenConfig.parse(configFile.readAsStringSync());
  config.resolveDefaults();

  final bindgen = Bindgen();
  _loadBindingJsons(bindgen, projectRoot);

  final packageConfig = getPackageConfig(projectRoot);
  final pubspecFile = File(join(projectRoot.path, 'pubspec.yaml'));
  final pubspec = Pubspec.parse(pubspecFile.readAsStringSync());
  final packageName = pubspec.name;

  final version = Version.parse(Platform.version.split(' ').first);
  final formatter = DartFormatter(languageVersion: version);
  for (final package in packageConfig.packages) {
    if (package.name == packageName) {
      bindgen.inject(package: package);
      break;
    }
  }

  var numBound = 0;

  for (final library in config.libraries) {
    final outDir = library.outDir != null
        ? Directory(join(projectRoot.path, library.outDir!))
        : commandRoot;
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }

    Map<String, String> files;
    if (library.uri.startsWith('dart:') ||
        library.uri.startsWith('package:')) {
      print('Binding ${library.uri}...');
      files = await bindgen.parseLibrary(library.uri, config, library);
    } else {
      // Relative file path source.
      final srcPath = join(projectRoot.path, library.uri);
      final srcFile = File(srcPath);
      if (!srcFile.existsSync()) {
        print('Warning: source file not found: $srcPath');
        continue;
      }
      final rel = relative(srcPath, from: projectRoot.path)
          .replaceAll('\\', '/');
      final uri = rel.startsWith('lib/')
          ? 'package:$packageName/${rel.substring(4)}'
          : rel;
      final output = await bindgen.parse(
        srcFile,
        basename(srcFile.path),
        uri,
        false,
        config: config,
        libraryConfig: library,
      );
      files = {
        if (output != null)
          basename(srcFile.path).replaceAll('.dart', '.eval.dart'): output,
      };
    }

    for (final entry in files.entries) {
      final outFile = File(join(outDir.path, entry.key));
      if (!outFile.parent.existsSync()) {
        outFile.parent.createSync(recursive: true);
      }
      final content = formatter.format(
        '$defaultImports\n${entry.value}',
        uri: Uri.parse(library.uri),
      );
      outFile.writeAsStringSync(content);
      print('Generated ${relative(outFile.path, from: projectRoot.path)}');
      numBound++;
    }

    if (library.plugin != null) {
      final plugin = library.plugin!;
      final pluginDir = Directory(
        join(outDir.path, dirname(plugin.out)),
      );
      if (!pluginDir.existsSync()) pluginDir.createSync(recursive: true);
      final pluginFile = File(join(outDir.path, plugin.out));
      final content = _pluginSource(bindgen, library, files.keys.toSet());
      pluginFile.writeAsStringSync(
        formatter.format(
          content,
          uri: Uri.parse(library.uri),
        ),
      );
      print(
        'Generated plugin ${relative(pluginFile.path, from: projectRoot.path)}',
      );
    }
  }

  // Emit `*Types` spec registries, grouped by output file.
  final registryFiles = <String, List<String>>{};
  for (final library in config.libraries) {
    final src = emitRegistrySource(config, library);
    if (src != null) {
      registryFiles.putIfAbsent(library.registry!.file, () => []).add(src);
    }
  }
  for (final entry in registryFiles.entries) {
    final registryFile = File(join(projectRoot.path, entry.key));
    if (!registryFile.parent.existsSync()) {
      registryFile.parent.createSync(recursive: true);
    }
    final content = formatter.format(
      '$registryImports\n${entry.value.join('\n')}',
      uri: Uri.parse(entry.key),
    );
    registryFile.writeAsStringSync(content);
    print(
      'Generated registry ${relative(registryFile.path, from: projectRoot.path)}',
    );
  }

  if (numBound == 0) {
    print('No bindings generated.');
  } else {
    print('Generated $numBound binding files.');
  }
}

String _pluginSource(
  Bindgen bindgen,
  BindgenLibraryConfig library,
  Set<String> files,
) {
  final plugin = library.plugin!;
  final pluginDir = dirname(plugin.out);
  final classes = bindgen.registerClasses.where((e) => files.contains(e.file));
  final enums = bindgen.registerEnums.where((e) => files.contains(e.file));
  final functions = bindgen.registerFunctions.where(
    (e) => files.contains(e.file),
  );

  final imports = <String>{
    ...plugin.imports,
    for (final e in [...classes, ...enums, ...functions])
      posix.normalize(posix.join(pluginDir, e.file)),
    for (final s in [...plugin.evalSources, ...plugin.extraSources])
      if (s.import != null) s.import!,
  };

  String evalSources() => plugin.evalSources.map((s) {
        if (s.expression != null) {
          return 'registry.addSource(${s.expression});';
        }
        final text = File(s.file!).readAsStringSync();
        return "registry.addSource(DartSource('${s.uri}', r'''\n$text\n'''));";
      }).join('\n');

  String extra(String target) => plugin.extraSources
      .where((s) => s.target == target || s.target == 'both')
      .map((s) => '${s.expression};')
      .join('\n');

  return '''
import 'package:dart_eval/dart_eval_bridge.dart';
${imports.map((e) => "import '$e';").join('\n')}

/// [EvalPlugin] for ${library.uri}
class ${plugin.className} implements EvalPlugin {
  @override
  String get identifier => '${plugin.identifier}';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    ${classes.map((e) => 'registry.defineBridgeClass(\$${e.name}.\$declaration);').join('\n')}
    ${enums.map((e) => 'registry.defineBridgeEnum(\$${e.name}.\$declaration);').join('\n')}
    ${functions.map((e) => 'registry.defineBridgeTopLevelFunction(\$${e.name}Fn.\$declaration);').join('\n')}
    ${plugin.extraDeclarations.map((e) => 'registry.defineBridgeClass($e);').join('\n')}
    ${evalSources()}
    ${extra('compile')}
  }

  @override
  void configureForRuntime(Runtime runtime) {
    ${classes.map((e) => '\$${e.name}.configureForRuntime(runtime);').join('\n')}
    ${enums.map((e) => '\$${e.name}.configureForRuntime(runtime);').join('\n')}
    ${functions.map((e) => '\$${e.name}Fn.configureForRuntime(runtime);').join('\n')}
    ${extra('runtime')}
  }
}
''';
}

void _loadBindingJsons(Bindgen bindgen, Directory projectRoot) {
  if (FileSystemEntity.typeSync('./.dart_eval/bindings') ==
      FileSystemEntityType.directory) {
    final files = Directory('./.dart_eval/bindings')
        .listSync()
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .cast<File>();

    for (final file in files) {
      print(
        'Found binding file: ${relative(file.path, from: projectRoot.path)}',
      );
      final data = file.readAsStringSync();
      final decoded = (json.decode(data) as Map).cast<String, dynamic>();
      final classList = (decoded['classes'] as List);
      for (final $class in classList.cast<Map>()) {
        bindgen.defineBridgeClass(BridgeClassDef.fromJson($class.cast()));
      }
      for (final $enum in (decoded['enums'] as List).cast<Map>()) {
        bindgen.defineBridgeEnum(BridgeEnumDef.fromJson($enum.cast()));
      }
      for (final $function in (decoded['functions'] as List).cast<Map>()) {
        bindgen.defineBridgeTopLevelFunction(
          BridgeFunctionDeclaration.fromJson($function.cast()),
        );
      }
      (decoded['exportedLibMappings'] as Map).cast<String, String>().forEach((
        key,
        value,
      ) {
        bindgen.addExportedLibraryMapping(key, value);
      });
    }
  }
}

List<Glob> readAnalyzerExcludes(File path) {
  if (!path.existsSync()) return [];
  final doc = loadYaml(path.readAsStringSync());
  final excludes = (doc['analyzer'] ?? <String, dynamic>{})['exclude'];
  if (excludes == null || excludes is! YamlList) return [];
  final reLib = RegExp(r'^lib/');
  return excludes
      .whereType<String>()
      .where((value) => value.startsWith('lib/'))
      .map((value) => Glob(value.replaceFirst(reLib, '')))
      .toList();
}
