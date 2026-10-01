import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_collections.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

final class _ObservedMap extends $Map {
  _ObservedMap() : super.wrap({});

  int reads = 0;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    if (identifier != '[]') return super.$getProperty(runtime, identifier);
    reads++;
    return $Function((runtime, target, r, s, c) => $int(73));
  }
}

final class _ObservedList extends $List {
  _ObservedList() : super.wrap([]);

  int reads = 0;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    if (identifier != '[]') return super.$getProperty(runtime, identifier);
    reads++;
    return $Function((runtime, target, r, s, c) => $int(91));
  }
}

void main() {
  test('native indexing retains boxed identities and null keys', () {
    final program = Compiler().compile({
      'native_index': {'main.dart': 'int main() => 0;'},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      final value = $String('same object');
      final backing = TypedCollections.newMap(runtime)
        ..[const $null()] = value
        ..[$String('empty')] = const $null();
      final map = $Map<dynamic, dynamic>.wrap(backing);
      $Value? lookup(Object? key) =>
          TypedInterop.invoke(runtime, map, '[]', 1, key, null);
      expect(lookup(null), same(value));
      expect(lookup(const $null()), same(value));
      expect(lookup($String('empty')), isNull);
      expect(lookup($String('missing')), isNull);
      final list = $List<dynamic>.wrap([value, const $null()]);
      expect(
        TypedInterop.invoke(runtime, list, '[]', 1, $int(0), null),
        same(value),
      );
      expect(
        TypedInterop.invoke(runtime, list, '[]', 1, $int(1), null),
        isNull,
      );
      expect(
        () => TypedInterop.invoke(runtime, list, '[]', 1, $int(2), null),
        throwsRangeError,
      );
      expect(
        () => TypedInterop.invoke(runtime, list, '[]', 1, $String('bad'), null),
        throwsA(isA<TypeError>()),
      );
    }
  });

  test('native wrapper subclasses retain their member dispatch', () {
    final runtime = Runtime.ofProgram(
      Compiler().compile({
        'native_index': {'main.dart': 'int main() => 0;'},
      }),
    );
    final map = _ObservedMap();
    final list = _ObservedList();
    expect(
      (TypedInterop.invoke(runtime, map, '[]', 1, $int(0), null) as $int)
          .$value,
      73,
    );
    expect(
      (TypedInterop.invoke(runtime, list, '[]', 1, $int(0), null) as $int)
          .$value,
      91,
    );
    expect(map.reads, 1);
    expect(list.reads, 1);
  });
}
