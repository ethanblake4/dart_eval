import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

const _source = r'''
// @dart=3.9
import 'dart:async';
extension type const I(int value) {}
extension type const D(double value) {}
extension type const B(bool value) {}
extension type const S(String value) {}
extension type const NI(int? value) {}
extension type const Union(FutureOr<Object?> value) {}
extension type const Ref(Object? value) {}
class Payload { final int value; Payload(this.value); }
extension type P(Payload value) {}
extension type R((int, String) value) {}
I direct(I value) => value;
I? nullable(I? value) => value;
D doubleDirect(D value) => value;
I generic<T extends I>(T value) => value;
int projection<T extends I>(T value) => value.value;
T missing<T extends I?>() => null as T;
bool genericNull<T extends Ref>(T value) => value == null;
Object? genericProject<T extends Ref>(T value) => value.value;
Object? reveal(I value) => value;
I defaulted([I value = const I(3)]) => value;
void require(bool valid, String stage) {
  if (!valid) throw StateError(stage);
}
bool verify() {
  final i = I(42);
  final d = D(1);
  final b = B(true);
  final s = S('hello');
  require(identical(i, 42) && direct(i).value == 42 && generic(i).value == 42, 'int ABI');
  require(projection(i) == 42 && defaulted().value == 3, 'generic projection and default');
  require(identical(reveal(i), 42) && nullable(null) == null && nullable(i)?.value == 42, 'nullable ABI');
  require(identical(d, 1.0) && doubleDirect(d).value == 1.0 && identical(b, true), 'double and bool ABI');
  require(identical(s, 'hello') && s.value.length == 5, 'String ABI');
  require(i is int && d is double && b is bool && s is String, 'erased type tests');
  require(I == int && D == double && B == bool && S == String, 'erased type literals');
  require((List<I>) == (List<int>) && <I>[i] is List<int>, 'collection descriptors');
  require((i, s) is (int, String), 'record descriptors');
  final nil = NI(null);
  require(nil == null && nil is! Object && nil?.value == null, 'nullable representation');
  try { nil!; return false; } catch (_) {}
  require(missing() == null, 'nullable generic bound');
  final absent = Union(null);
  require(absent == null && absent?.value == null && absent?.toString() == null, 'union representation');
  try { absent!; return false; } catch (_) {}
  require(genericNull(Ref(null)) && genericProject(Ref(null)) == null, 'generic nullable representation');
  var ref = Ref(null);
  var changed = 0;
  final replacement = ref ?? Ref(changed = 7);
  require(replacement.value == 7 && changed == 7, 'nullable representation coalescing');
  ref ??= Ref(9);
  require(ref.value == 9, 'nullable representation coalescing assignment');
  final payload = Payload(5);
  final p = P(payload);
  require(identical(p, payload) && identical(p.value, payload) && p.value.value == 5, 'nominal identity');
  final pair = (3, 'r');
  final r = R(pair);
  require(identical(r, pair) && r.value.$1 == 3 && r.value.$2 == 'r', 'record identity');
  return true;
}
void main() {
  if (!verify()) throw StateError('extension scalar ABI');
}
''';

void main() {
  test('scalar extension ABI preserves representation and nominal typing', () {
    final program = Compiler().compile({
      'extension_scalar': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:extension_scalar/main.dart', 'verify'),
        true,
      );
      expect(
        runtime.executeLib(
          'package:extension_scalar/main.dart',
          'direct',
          arguments: {'value': 42},
        ),
        42,
      );
      expect(
        runtime.executeLib(
          'package:extension_scalar/main.dart',
          'doubleDirect',
          arguments: {'value': 1.5},
        ),
        1.5,
      );
      expect(
        runtime.executeLib('package:extension_scalar/main.dart', 'defaulted'),
        3,
      );
    }
  });
  for (final body in [
    'Object consume(I value) => value;',
    'int consume(I value) => value + 1;',
    'int consume(I? value) => value.value;',
  ]) {
    test('scalar extension rejects invalid nominal access: $body', () {
      expect(
        () => Compiler().compile({
          'extension_scalar_invalid': {
            'main.dart': 'extension type I(int value) {} $body void main() {}',
          },
        }),
        throwsA(isA<CompileError>()),
      );
    });
  }
}
