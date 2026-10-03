import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

import '../sdk_language/sdk_language.dart';

void main() {
  test('FutureOr Type display and generic membership', () {
    final program = Compiler().compile({
      'futureor_types': {
        'main.dart': r'''
import 'dart:async' show FutureOr;

Type typeOf<T>() => T;
bool acceptsNull<T>() => null is T;

bool main() =>
    '${FutureOr<String>}' == 'FutureOr<String>' &&
    '${typeOf<FutureOr<String?>?>()}' == 'FutureOr<String?>' &&
    '${FutureOr<dynamic>}' == 'dynamic' &&
    '${typeOf<FutureOr<Object>?>()}' == 'Object?' &&
    '${FutureOr<Null>}' == 'Future<Null>?' &&
    '${FutureOr<Never>}' == 'Future<Never>' &&
    '${FutureOr<FutureOr<String>>}' == 'FutureOr<FutureOr<String>>' &&
    '${typeOf<FutureOr<String?>?>()}' == 'FutureOr<String?>' &&
    acceptsNull<FutureOr<String?>>() &&
    !acceptsNull<FutureOr<String>>() &&
    <String>[] is List<FutureOr<String>> &&
    <Future<String>>[] is List<FutureOr<String>>;
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:futureor_types/main.dart', 'main'),
        true,
      );
    }
  });

  test('pinned FutureOr Type fixture runs fresh and serialized', () async {
    final suite = await SdkSuite.load();
    final fixture = suite.classify('type_object/futureor_tostring_test.dart');
    final sources = suite.collectSources(fixture);
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
