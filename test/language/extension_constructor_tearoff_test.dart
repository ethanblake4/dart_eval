import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

const _support = r'''
// @dart=3.8
extension type const Imported(Object? value) {}
''';

const _source = r'''
// @dart=3.8
import 'support.dart' as support;
extension type const E(Null value) {}
extension type const Ref(Object? value) {}
extension type const Other(Object? value) {}
const inferred = E.new;
const E Function(Null) typed = E.new;
const imported = support.Imported.new;
bool verify() {
  final local = E.new;
  final Ref Function(Object?) reference = Ref.new;
  final raw = Object();
  if (inferred(null).value != null || typed(null).value != null) return false;
  if (!identical(local(null), null)) return false;
  if (!identical(reference(raw).value, raw)) return false;
  if (!identical(reference(null), null)) return false;
  if (!identical(imported(raw).value, raw)) return false;
  if (!identical(E.new, E.new) || !identical(inferred, local)) return false;
  if (identical(Ref.new, Other.new)) return false;
  if (local is! Null Function(Null)) return false;
  dynamic dynamicNull = local;
  dynamic dynamicRef = reference;
  if (!identical(dynamicRef(raw), raw) || dynamicNull(null) != null) return false;
  try { dynamicNull(raw); return false; } catch (_) {}
  try { dynamicNull(); return false; } catch (_) {}
  try { dynamicNull(null, null); return false; } catch (_) {}
  try { dynamicNull(value: null); return false; } catch (_) {}
  return true;
}
void main() {
  if (!verify()) throw StateError('extension constructor tear-offs');
}
''';

const _scalarSource = r'''
// @dart=3.8
extension type const Count(int value) {}
extension type const Ratio(double value) {}
extension type const Flag(bool value) {}
extension type const Text(String value) {}
class Payload {
  final int value;
  const Payload(this.value);
}
extension type const Wrapped(Payload value) {}
const inferred = Count.new;
const Count Function(int) typed = Count.new;
bool verify() {
  final count = Count.new;
  final Ratio Function(double) ratio = Ratio.new;
  final flag = Flag.new;
  final text = Text.new;
  final payload = Payload(7);
  final wrapped = Wrapped.new;
  if (inferred(3).value + typed(4).value + count(5).value != 12) return false;
  if (ratio(1.5).value != 1.5 || !flag(true).value) return false;
  if (text('value').value != 'value') return false;
  if (!identical(wrapped(payload).value, payload)) return false;
  if (!identical(Count.new, count) || count is! int Function(int)) return false;
  dynamic dynamicCount = count;
  dynamic dynamicRatio = ratio;
  dynamic dynamicFlag = flag;
  dynamic dynamicText = text;
  dynamic dynamicWrapped = wrapped;
  if (dynamicCount(9) != 9 || dynamicRatio(2.5) != 2.5) return false;
  if (dynamicFlag(false) != false || dynamicText('text') != 'text') return false;
  if (!identical(dynamicWrapped(payload), payload)) return false;
  try { dynamicCount(null); return false; } catch (_) {}
  try { dynamicCount('wrong'); return false; } catch (_) {}
  try { dynamicWrapped(Object()); return false; } catch (_) {}
  return true;
}
void main() {
  if (!verify()) throw StateError('extension representation callable ABI');
}
''';

void main() {
  for (final (name, source) in [
    ('nullable representations', _source),
    ('scalar and nominal representations', _scalarSource),
  ]) {
    test('extension constructor tear-offs with $name', () {
      final program = Compiler().compile({
        'extension_tearoff': {'main.dart': source, 'support.dart': _support},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:extension_tearoff/main.dart', 'verify'),
          true,
        );
      }
    });
  }
  for (final body in [
    'final f = E.new; f(1);',
    'final f = E.new; f();',
    'final f = E.new; f(value: null);',
  ]) {
    test('reject invalid extension constructor tear-off call: $body', () {
      expect(
        () => Compiler().compile({
          'invalid_extension_tearoff': {
            'main.dart': 'extension type E(Null value) {} void main() {$body}',
          },
        }),
        throwsA(isA<CompileError>()),
      );
    });
  }
}
