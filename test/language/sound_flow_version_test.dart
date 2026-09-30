import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

String _source(
  String version, {
  bool wrongTypes = false,
  bool repeatedLocal = false,
}) {
  final modern = version == '3.9';
  final nullable = modern != wrongTypes ? 'int' : 'int?';
  final demoted = modern != wrongTypes ? 'num' : 'Object';
  final receiver = repeatedLocal ? 'value' : 'number()';
  return '''
// @dart = $version
typedef Exactly<T> = T Function(T);
extension StaticType<T> on T {
  T check<R extends Exactly<T>>() => this;
}
int number() => 3;
int casts(bool flag) {
  int? result = 1;
  if (flag) {
    number() as Null;
    result = null;
  }
  result.check<Exactly<$nullable>>();
  return result ?? 0;
}
int main() {
  ${repeatedLocal ? 'int value = 3;' : ''}
  int? call;
  $receiver?.gcd(call = 0);
  call.check<Exactly<$nullable>>();
  int? cascade;
  $receiver?..bitLength.gcd(cascade = 0);
  cascade.check<Exactly<$nullable>>();
  int? coalesce = 1;
  $receiver ?? (coalesce = null, 0).\$2;
  coalesce.check<Exactly<$nullable>>();
  int? store = 1;
  int storeValue = $receiver;
  storeValue ??= (store = null, 0).\$2;
  store.check<Exactly<$nullable>>();
  int? tested = 1;
  if ($receiver is int) {} else { tested = null; }
  tested.check<Exactly<$nullable>>();
  int? nullTest = 1;
  if ($receiver is Null) { nullTest = null; }
  nullTest.check<Exactly<$nullable>>();
  Object object = 1;
  object as num;
  object = '';
  object = 2 as num;
  object.check<Exactly<$demoted>>();
  var caught = 0;
  try { casts(true); } on TypeError { caught++; }
  return (call ?? 0) + (cascade ?? 0) + (coalesce ?? 0) +
      (store ?? 0) + (tested ?? 0) + (nullTest ?? 0) +
      casts(false) + caught;
}
''';
}

void main() {
  test('deferred conditions promote only stable local dependencies', () {
    final program = Compiler().compile({
      'flow_version': {
        'main.dart': '''
typedef Exactly<T> = T Function(T);
extension StaticType<T> on T {
  T check<R extends Exactly<T>>() => this;
}
int stable(int? value) {
  bool present = value != null;
  late final result = present ? value.check<Exactly<int>>() : 3;
  return result;
}
void changesCondition(int? value) {
  bool present = value != null;
  late final result = present ? value.check<Exactly<int?>>() : 3;
  present = true;
}
void changesValue(int? value) {
  bool present = value != null;
  late final result = present ? value.check<Exactly<int?>>() : 3;
  value = null;
}
int main() => stable(2) + stable(null);
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:flow_version/main.dart', 'main'), 5);
    }
  });

  test('nullable tests do not narrow non-nullable late locals', () {
    final program = Compiler().compile({
      'flow_version': {
        'main.dart': '''
typedef Exactly<T> = T Function(T);
extension StaticType<T> on T {
  T check<R extends Exactly<T>>() => this;
}
int main() {
  late num number = 3;
  if (number is int?) number.check<Exactly<num>>();
  if (number is int) number.check<Exactly<int>>();
  late num? nullable = 3 as num?;
  if (nullable is int?) nullable.check<Exactly<int?>>();
  return number.toInt();
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:flow_version/main.dart', 'main'), 3);
    }
  });

  for (final version in ['3.8', '3.9']) {
    for (final repeatedLocal in [false, true]) {
      final receiver = repeatedLocal ? 'reused local' : 'call result';
      test('Dart $version flow joins retain types for $receiver', () {
        final program = Compiler().compile({
          'flow_version': {
            'main.dart': _source(version, repeatedLocal: repeatedLocal),
          },
        });
        for (final runtime in [
          Runtime.ofProgram(program),
          Runtime(program.write().buffer),
        ]) {
          expect(
            runtime.executeLib('package:flow_version/main.dart', 'main'),
            6,
          );
        }
      });

      test('Dart $version rejects wrong flow types for $receiver', () {
        expect(
          () => Compiler().compile({
            'flow_version': {
              'main.dart': _source(
                version,
                wrongTypes: true,
                repeatedLocal: repeatedLocal,
              ),
            },
          }),
          throwsA(isA<CompileError>()),
        );
      });
    }
  }
}
