import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = r'''
import 'dart:collection';
int calls = 0;
Iterable<T> iterable<T>() { calls++; return <T>[]; }
Map<K, V> mapping<K, V>() {
  if (K != int || V != String) throw StateError('wrong map context');
  calls++;
  return <K, V>{};
}
class FixedInts<T> extends IterableBase<int> {
  Iterator<int> get iterator => <int>[1, 2].iterator;
}
class ReorderedMap<A, B> extends MapBase<B, A> {
  final Map<B, A> backing;
  ReorderedMap(this.backing);
  Iterable<B> get keys => backing.keys;
  A? operator [](Object? key) => backing[key];
  void operator []=(B key, A value) { backing[key] = value; }
  A? remove(Object? key) => backing.remove(key);
  void clear() => backing.clear();
}
Map<K, V> identityMap<K, V>(Map<K, V> value) => value;
Set<T> identitySet<T>(Set<T> value) => value;
Map<K, V> emptyMap<K, V>() => {};
Set<T> emptySet<T>() => {};
int main() {
  final ints = [...FixedInts<String>()];
  if (ints is! List<int> || ints is List<String> || ints.length != 2) return -1;
  final reversed = {...ReorderedMap<String, int>(<int, String>{1: 'one'})};
  if (reversed is! Map<int, String> || reversed[1] != 'one') return -2;
  Map<int, String> contextual = {...mapping()};
  if (contextual.isNotEmpty || calls != 1) return -3;
  final numbers = [1, ...<double>[2.5]];
  if (numbers is! List<num> || numbers is List<int> || numbers.length != 2) return -4;
  final inferred = [1, ...iterable()];
  if (inferred is! List<dynamic> || calls != 2) return -5;
  final typed = <int>[...iterable()];
  if (typed is! List<int> || calls != 3) return -6;
  final nestedEmpty = <int>{...{}};
  if (nestedEmpty is! Set<int> || nestedEmpty.isNotEmpty) return -7;
  final schema = identityMap({...<int, String>{1: 'one'}});
  if (schema is! Map<int, String> || schema[1] != 'one') return -8;
  final empty = emptyMap<int, String>();
  if (empty is! Map<int, String> || empty.isNotEmpty) return -9;
  final emptyElements = emptySet<int>();
  if (emptyElements is! Set<int> || emptyElements.isNotEmpty) return -10;
  final nested = [...[1], ...[2]];
  if (nested is! List<int> || nested.runtimeType != <int>[].runtimeType) return -11;
  final nestedSet = {0, ...[1], ...[2]};
  if (nestedSet is! Set<int> || nestedSet.runtimeType != <int>{}.runtimeType) return -12;
  final nestedMap = {0: 'zero', ...{1: 'one'}};
  if (nestedMap is! Map<int, String> ||
      nestedMap.runtimeType != <int, String>{}.runtimeType) return -13;
  final nullSpread = [1, ...?null];
  if (nullSpread.runtimeType != <int>[].runtimeType) return -14;
  final nullMapSpread = {1: 'one', ...?null};
  if (nullMapSpread.runtimeType != <int, String>{}.runtimeType) return -15;
  final nullSetSpread = {1, ...?null};
  if (nullSetSpread.runtimeType != <int>{}.runtimeType) return -16;
  final onlyNullSpread = [...?null];
  if (onlyNullSpread.runtimeType != <Never>[].runtimeType) return -17;
  final onlyNullMapSpread = identityMap({...?null});
  if (onlyNullMapSpread.runtimeType != <Never, Never>{}.runtimeType) return -18;
  final onlyNullSetSpread = identitySet({...?null});
  if (onlyNullSetSpread.runtimeType != <Never>{}.runtimeType) return -19;
  return 0;
}
''';

void main() {
  test(
    'spread inference views source interfaces and keeps downward context',
    () {
      final program = Compiler().compile({
        'spread_inference': {'main.dart': _source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:spread_inference/main.dart', 'main'),
          0,
        );
      }
    },
  );
}
