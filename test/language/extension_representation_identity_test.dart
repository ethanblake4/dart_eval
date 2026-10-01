import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

const _source = r'''
// @dart=3.8
extension type const E(Null value) {}
extension type Ref(Object? value) {}
E produce() => const E(null);
Ref roundTrip(Ref value) => value;
Object? disclose(Ref value) => value;
Ref lexical<Object>(Object value) => Ref(value);
bool verify() {
  const E e = E(null);
  final raw = Object();
  final reference = Ref(raw);
  final absent = Ref(null);
  if (!identical(e, null) || e.value != null || e != null) return false;
  if (!identical(reference, raw) || !identical(reference.value, raw)) return false;
  if (!identical(roundTrip(reference), raw) || !identical(disclose(reference), raw)) return false;
  if (!identical(lexical(raw), raw)) return false;
  if (!identical(new Ref(raw), raw) || !identical(Ref.new(raw), raw)) return false;
  if (!identical(absent, null) || absent.value != null || absent != null) return false;
  if (e is Object || absent is Object || e is! Object? || absent is! Object?) return false;
  if (e is! Null || e is! Ref || reference is E) return false;
  if (e?.value != null || absent?.value != null || absent?.toString() != null) return false;
  if (reference?.toString() != raw.toString()) return false;
  if (!identical(absent?..toString(), null)) return false;
  try { e!; return false; } catch (_) {}
  try { absent!; return false; } catch (_) {}
  if (!identical(reference!, raw)) return false;
  if ((e as Null) != null || !identical(raw as Ref, raw)) return false;
  final values = <E>[e];
  if (values is! List<Null> || List<E> != List<Null>) return false;
  if ((e,) is! (Null,) || produce is! Null Function()) return false;
  if (E != Null || List<Ref> != List<Object?>) return false;
  final present = <Ref>[?absent, ?reference];
  return present.length == 1 && identical(present.single, raw);
}
void main() {
  if (!verify()) throw StateError('extension representation identity');
}
''';

void main() {
  for (final version in ['3.8', '3.9']) {
    test('extension representation identity with Dart $version flow rules', () {
      final program = Compiler().compile({
        'extension_identity': {
          'main.dart': _source.replaceFirst('@dart=3.8', '@dart=$version'),
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:extension_identity/main.dart', 'verify'),
          true,
        );
      }
    });
  }

  for (final body in [
    'Null consume(E e) => e;',
    'Object consume(Ref r) => r;',
    'int consume(Ref r) => r.length;',
    'void consume(Ref r) { r.value = null; }',
    'E consume() => E(1);',
    'const r = Ref(null);',
    'E consume() => E(value: null);',
    'E consume() => E(null, null);',
  ]) {
    test('extension representation rejects invalid source: $body', () {
      expect(
        () => Compiler().compile({
          'extension_negative': {
            'main.dart':
                '''
// @dart=3.8
extension type const E(Null value) {}
extension type Ref(Object? value) {}
$body
void main() {}
''',
          },
        }),
        throwsA(isA<CompileError>()),
      );
    });
  }
}
