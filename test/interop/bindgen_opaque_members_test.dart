import 'dart:io';

import 'package:dart_eval/src/eval/bindgen/bindgen.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'opaque classes bind only explicit members through native wrappers',
    () async {
      final directory = Directory(
        'test',
      ).absolute.createTempSync('opaque_members_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final source = File(p.join(directory.path, 'native.dart'))
        ..writeAsStringSync('''
class Element {
  int calls = 0;
  void markNeedsBuild() { calls++; }
  bool get dirty => calls > 0;
  bool get hiddenGetter => false;
  void hidden() { throw StateError('must remain excluded'); }
}
class Child extends Element {}
''');
      final uri = source.uri.toString();
      final config = BindgenConfig.parse('''
version: 1
libraries:
  - uri: $uri
    classes:
      Element:
        file: native.dart
        opaque: true
        methods:
          markNeedsBuild:
            include: true
          hidden:
            include: false
        getters:
          dirty:
            include: true
      Child:
        file: native.dart
        opaque: true
''')..resolveDefaults();
      final generated = await Bindgen().parse(
        source,
        'native.dart',
        uri,
        false,
        config: config,
        libraryConfig: config.libraries.single,
      );
      File(p.join(directory.path, 'native.eval.dart')).writeAsStringSync('''
import 'native.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
$generated
''');
      File(p.join(directory.path, 'run.dart')).writeAsStringSync(
        r"""
import 'native.dart';
import 'native.eval.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
void main() {
  final declaration = $Element.$declaration;
  if (declaration.constructors.isNotEmpty ||
      declaration.methods.keys.join() != 'markNeedsBuild' ||
      declaration.getters.keys.join() != 'dirty' || declaration.fields.isNotEmpty) {
    throw StateError('opaque member selection leaked');
  }
  final compiler = Compiler()
    ..defineBridgeClass(declaration)..defineBridgeClass($Child.$declaration);
  final program = compiler.compile({'probe': {'main.dart': '''
import 'NATIVE_URI';
bool invoke(Child child) { child.markNeedsBuild(); return child.dirty; }
'''}});
  for (final runtime in [Runtime.ofProgram(program), Runtime(program.write().buffer)]) {
    final native = Child();
    final dirty = runtime.executeLib('package:probe/main.dart', 'invoke', arguments: {
      'child': $Child.wrap(native),
    });
    if (native.calls != 1 || dirty != true) throw StateError('native method/getter dispatch did not run');
  }
  Object? failure;
  try {
    compiler.compile({'probe': {'main.dart': '''
import 'NATIVE_URI';
void invoke(Child child) { child.hidden(); }
'''}});
  } catch (error) { failure = error; }
  if (failure == null || !failure.toString().contains('Unknown method')) {
    throw StateError('excluded native member was admitted: $failure');
  }
}
"""
            .replaceAll('NATIVE_URI', uri),
      );
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        p.join(directory.path, 'run.dart'),
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'opaque selected signatures contribute to supporting dependency closure',
    () async {
      final directory = Directory(
        'test',
      ).absolute.createTempSync('opaque_closure_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final dependency = File(p.join(directory.path, 'dependency.dart'))
        ..writeAsStringSync('class Needed {}\nclass Excluded {}');
      final source = File(p.join(directory.path, 'native.dart'))
        ..writeAsStringSync('''
import 'dependency.dart';
class Element {
  Needed selected(Needed value) => value;
  Excluded hidden(Excluded value) => value;
}
''');
      final config = BindgenConfig.parse('''
version: 1
libraries:
  - uri: ${source.uri}
    classes:
      Element:
        opaque: true
        methods:
          selected:
            include: true
''')..resolveDefaults();
      final closure = await Bindgen().supportingTypes(config);
      expect(closure, [
        (uri: dependency.uri.toString(), name: 'Needed', isEnum: false),
      ]);
    },
  );
}
