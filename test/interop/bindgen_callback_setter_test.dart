import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/properties.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'callback setters adapt native signatures in wrappers and bridges',
    () async {
      final directory = Directory('test').absolute.createTempSync('setter_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final source = File(p.join(directory.path, 'fixture.dart'))
        ..writeAsStringSync('''
import 'dart:async';
class Callbacks<T> {
  void Function(int)? callback;
  void Function(T)? generic;
  FutureOr<void> Function()? cancel;
  int count = 0;
}
''');
      final collection = AnalysisContextCollection(
        includedPaths: [source.path],
      );
      final result =
          await collection
                  .contextFor(source.path)
                  .currentSession
                  .getResolvedLibrary(source.path)
              as ResolvedLibraryResult;
      final element = result.element.classes.single;
      final context = BindgenContext(
        'fixture.dart',
        'package:fixture/fixture.dart',
        all: true,
        bridgeDeclarations: {},
        exportedLibMappings: {},
      )..classElement = element;
      for (final bridge in [false, true]) {
        final emitted = propertySetters(
          context,
          element,
          isBridge: bridge,
        ).replaceAll(RegExp(r'\s+'), ' ');
        expect(
          emitted,
          contains('runtime.cachedCallback(value! as EvalCallable'),
        );
        expect(emitted, contains('value is \$null ? null'));
        expect(emitted, contains('void Function(int);export=$bridge'));
        expect(emitted, contains('FutureOr<void> Function();export=$bridge'));
        expect(emitted, contains('as FutureOr<void>'));
        expect(emitted, contains('count = value.\$reified'));
        expect(emitted, isNot(contains('callback = value.\$reified')));
        expect(emitted, isNot(contains('self.\$getRuntimeType')));
        expect(emitted, contains('runtime.runtimeTypeArgumentAt('));
        if (bridge) expect(emitted, contains('final runtime = \$runtime'));
      }
    },
  );
}
