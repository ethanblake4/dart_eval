import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('FutureOr generic membership', () {
    final program = Compiler().compile({
      'futureor_types': {
        'main.dart': r'''
import 'dart:async' show FutureOr;

bool acceptsNull<T>() => null is T;

bool main() =>
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

  test('FutureOr Type identity and source subtyping', () {
    final program = Compiler().compile({
      'futureor_identity': {
        'main.dart': r'''
import 'dart:async' show FutureOr;

Type typeOf<T>() => T;

bool sameHash(Type a, Type b) => a.hashCode == b.hashCode;
bool distinct(Type a, Type b) => a != b;

List<bool> main() => [
  sameHash(FutureOr<Object>, Object),
  sameHash(FutureOr<dynamic>, dynamic),
  sameHash(FutureOr<Never>, Future<Never>),
  sameHash(FutureOr<Null>, typeOf<Future<Null>?>()),
  sameHash(typeOf<FutureOr<Object?>?>(), typeOf<Object?>()),
  sameHash(typeOf<FutureOr<String?>?>(), FutureOr<String?>),
  distinct(FutureOr<FutureOr<String>>, FutureOr<String>),
  <FutureOr<String?>>[] is! List<Object>,
  <FutureOr<int>>[] is List<Object>,
  <FutureOr<int>>[] is! List<Future<Object>>,
  <FutureOr<Never>>[] is List<Future<Never>>,
  <FutureOr<Null>>[] is List<Future<Null>?>,
  distinct(typeOf<FutureOr<int>?>(), typeOf<FutureOr<int?>>()),
];
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:futureor_identity/main.dart', 'main'),
        List.filled(13, true),
      );
    }
  });
}
