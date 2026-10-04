import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart' show TypedRuntimeInterop;
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/src/eval/shared/types.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  test('List toList retains descriptor provenance across runtimes', () {
    final program = Compiler().compile({
      'list_origin': {'main.dart': 'int main() => 0;'},
    });
    final origin = Runtime.ofProgram(program);
    final destination = Runtime(program.write().buffer);
    origin.executeLib('package:list_origin/main.dart', 'main');
    destination.executeLib('package:list_origin/main.dart', 'main');
    destination.internParameterizedType(CoreTypes.list, [
      destination.lookupType(CoreTypes.int),
    ]);
    final values = $List.wrap(
      <Object?>[],
      runtime: origin,
      runtimeTypeId: origin.internParameterizedType(CoreTypes.list, [
        origin.lookupType(CoreTypes.string),
      ]),
    );
    final copy =
        TypedInterop.invoke(destination, values, 'toList', 0, null, null)
            as $List;
    expect(
      destination.runtimeTypeToString(copy.$getRuntimeType(destination)),
      'List<String>',
    );
    expect(
      () => TypedInterop.invoke(destination, copy, 'add', 1, $int(1), null),
      throwsA(isA<TypeError>()),
    );
  });
  for (final (name, source, expected) in [
    (
      'sublist and toList retain guest element type and checked writes',
      r'''
class A {}
class B {}
int main() {
  final values = List<A>.empty(growable: true);
  dynamic slice = values.sublist(0);
  dynamic copy = values.toList();
  if (slice is! List<A> || slice is List<B>) return 1;
  if (copy is! List<A> || copy is List<B>) return 2;
  try { slice.add(B()); return 3; } catch (error) {
    if (error is! TypeError) return 4;
  }
  try { copy.add(null); return 5; } catch (error) {
    if (error is! TypeError) return 6;
  }
  copy.add(A());
  return copy.length;
}
''',
      1,
    ),
    (
      'bulk writes retain storage typing and range error order',
      r'''
int main() {
  final values = List<int>.filled(4, 0);
  values.setRange(0, 4, [1, 2, 3, 4]);
  values.setRange(1, 4, values, 0);
  values.setAll(0, [7]);
  try { values.setRange(10, 11, values); return 0; } catch (error) {
    if (error is! RangeError) return 1;
  }
  try { values.setRange(0, 1, values, null as dynamic); return 2; }
  catch (error) { if (error is! TypeError) return 3; }
  return values[0] * 1000 + values[1] * 100 + values[2] * 10 + values[3];
}
''',
      7123,
    ),
  ]) {
    test(name, () {
      final program = Compiler().compile({
        'list_result': {'main.dart': source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:list_result/main.dart', 'main'),
          expected,
        );
      }
    });
  }
}
