import 'dart:io';

import 'package:dart_eval/dart_eval.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'sdk_language.dart';

void main() {
  late Directory checkout;
  late SdkSuite suite;

  void source(String name, String contents) {
    final file = File(p.join(suite.languageRoot, name));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
  }

  setUp(() {
    checkout = Directory.systemTemp.createTempSync('sdk-adjacent-directive-');
    suite = SdkSuite(
      SuiteConfig.fromYaml('sdk_commit: fixture\ncore: []\n'),
      checkout,
    );
  });

  tearDown(() => checkout.deleteSync(recursive: true));

  test('empty leading URI literals collect imports, exports and parts', () {
    source('main.dart', '''
import "" "imported.dart";
import 'exporter.dart';
part '' 'main_part.dart';
int main() => imported + exported + fromPart;
''');
    source('imported.dart', 'const imported = 1;');
    source('exporter.dart', "export '' 'exported.dart';");
    source('exported.dart', 'const exported = 2;');
    source('main_part.dart', "part of 'main.dart';\nconst fromPart = 4;");

    final fixture = suite.classify('main.dart');
    expect(fixture.kind, TestKind.runnable);
    final sources = suite.collectSources(fixture);
    final compiler = Compiler();
    setSdkEntrypoints(compiler, fixture, sources);
    final program = compiler.compileSources(sources);
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib(fixture.uri, 'main'), 7);
    }
  });

  test('adjacent URI literals still classify unsupported imports', () {
    source('main.dart', "import '' 'dart:mirrors';\nvoid main() {}");
    final fixture = suite.classify('main.dart');
    expect(fixture.kind, TestKind.unsupported);
    expect(fixture.unsupportedReason, contains('dart:mirrors'));
  });

  test('pinned juxtaposition fixture runs fresh and serialized', () async {
    final pinnedSuite = await SdkSuite.load();
    final fixture = pinnedSuite.classify('library/juxtaposition_test.dart');
    final sources = pinnedSuite.collectSources(fixture);
    final compiler = Compiler();
    setSdkEntrypoints(compiler, fixture, sources);
    final program = compiler.compileSources(sources);
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      await executeSdkMain(runtime, fixture, sources);
    }
  });
}
