import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:dart_eval/src/eval/bindgen/typedefs.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('config selects SDK typedefs and an existing wrapper', () {
    final library = BindgenConfig.parse('''
version: 1
libraries:
  - uri: dart:collection
    typedefs: [IterableBase, IterableMixin]
    classes:
      Iterable:
        handMaintainedWrapper: true
''').libraries.single;

    expect(library.typedefs, ['IterableBase', 'IterableMixin']);
    expect(library.classes['Iterable']!.handMaintainedWrapper, isTrue);
    expect(library.classes['Iterable']!.handMaintained, isFalse);
  });

  test('selected aliases come from the installed Dart SDK source', () async {
    final sdk = p.dirname(p.dirname(Platform.resolvedExecutable));
    final source = File(
      p.join(sdk, 'lib', 'collection', 'iterable.dart'),
    ).readAsStringSync();

    expect(
      extractTypedefSource([source], ['IterableBase', 'IterableMixin']),
      'typedef IterableBase<E> = Iterable<E>;\n'
      'typedef IterableMixin<E> = Iterable<E>;',
    );
    expect(
      () => extractTypedefSource([source], ['MissingAlias']),
      throwsFormatException,
    );

    final collection = AnalysisContextCollection(
      includedPaths: [Directory.current.absolute.path],
    );
    final result = await collection
        .contextFor(Directory.current.absolute.path)
        .currentSession
        .getLibraryByUri('dart:collection');
    expect(result, isA<LibraryElementResult>());
    final library = (result as LibraryElementResult).element;
    expect(
      sdkTypedefSourceForLibrary(library, ['IterableBase', 'IterableMixin']),
      extractTypedefSource([source], ['IterableBase', 'IterableMixin']),
    );
    expect(
      emitTypedefDartSource('dart:collection', 'typedef A = int;'),
      contains("DartSource('dart:collection', r'''"),
    );
  });
}
