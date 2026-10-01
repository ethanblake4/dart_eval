import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const _source = r'''
import 'dart:async';
Iterable<T> ints<T>(dynamic values) {
  if (T != int) throw StateError('expected int source context');
  return values;
}
Iterable<T> strings<T>(dynamic values) {
  if (T != String) throw StateError('expected String source context');
  return values;
}
Stream<T> intEvents<T>(dynamic values) {
  if (T != int) throw StateError('expected int Stream context');
  return Stream<T>.fromIterable(values);
}
Stream<T> stringEvents<T>(dynamic values) {
  if (T != String) throw StateError('expected String Stream context');
  return Stream<T>.fromIterable(values);
}
Future<int> main() async {
  final text = <String>[for (int n in ints([1, 2])) n.toString()];
  if (text.join(',') != '1,2') return -1;
  final lengths = <int>[for (String s in strings(['a', 'bbb'])) s.length];
  if (lengths.join(',') != '1,3') return -2;
  final inferred = [for (int n in ints([3])) n.toString()];
  if (inferred is! List<String> || inferred.single != '3') return -3;
  final asyncText = <String>[await for (int n in intEvents([4, 5])) n.toString()];
  if (asyncText.join(',') != '4,5') return -4;
  final asyncLengths = <int>[await for (String s in stringEvents(['cc', 'dddd'])) s.length];
  if (asyncLengths.join(',') != '2,4') return -5;
  final asyncInferred = [await for (int n in intEvents([6])) n.toString()];
  if (asyncInferred is! List<String> || asyncInferred.single != '6') return -6;
  return 0;
}
''';

void main() {
  test(
    'collection for source context follows the declared loop variable',
    () async {
      final program = Compiler().compile({
        'for_source_context': {'main.dart': _source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          await runtime.executeLib(
            'package:for_source_context/main.dart',
            'main',
          ),
          $int(0),
        );
      }
    },
  );
}
