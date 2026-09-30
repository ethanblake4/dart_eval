import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void _expectValue(String source, Object? value) {
  for (final (mode, result) in runDynamicFixture(source)) {
    expect(result, DynamicFixtureResult.value(value), reason: mode);
  }
}

void _expectTrue(String source) => _expectValue(source, true);

Future<void> _expectAsyncTrue(String source) async {
  final program = Compiler().compile({
    'nested_generic_environment': {'main.dart': source},
  });
  for (final (mode, runtime) in [
    ('fresh', Runtime.ofProgram(program)),
    ('serialized', Runtime(program.write().buffer)),
  ]) {
    expect(
      await runtime.executeLib(
        'package:nested_generic_environment/main.dart',
        'main',
      ),
      $bool(true),
      reason: mode,
    );
  }
}

void main() {
  test('reused generic calls preserve earlier captured type bindings', () {
    _expectTrue('''
      dynamic make<T>() {
        dynamic select<U extends T>(U value) {
          bool accepts(Object? candidate) => candidate is U;
          return accepts;
        }
        return select;
      }

      bool main() {
        dynamic select = make<Object?>();
        dynamic integer = select<int>(1);
        dynamic sameInteger = select<int>(2);
        var rejected = false;
        try { select<int>('wrong'); } on TypeError { rejected = true; }
        dynamic string = select<String>('s');
        dynamic nullable = select<int?>(null);
        return rejected && integer(3) && sameInteger(4) && !integer('s') &&
            string('t') && !string(3) && nullable(null) && nullable(5) &&
            !nullable('s') && !integer(null);
      }
    ''');
  });
  test('escaping closure keeps three distinct generic environments', () {
    _expectValue('''
      dynamic make<T>() {
        dynamic middle<U>() {
          int inner<V>() {
            final List<T> outer = <T>[];
            final List<U> middle = <U>[];
            final List<V> current = <V>[];
            var result = 0;
            if (T == int) result += 1;
            if (U == String) result += 2;
            if (V == double) result += 4;
            if (outer is List<int> && outer is! List<String>) result += 8;
            if (middle is List<String> && middle is! List<int>) result += 16;
            if (current is List<double> && current is! List<String>) result += 32;
            return result;
          }
          return inner;
        }
        return middle<String>();
      }

      int main() {
        dynamic escaped = make<int>();
        return escaped<double>();
      }
    ''', 63);
  });

  test('omitted bound uses the captured outer argument', () {
    _expectTrue('''
      dynamic make<T>() {
        bool inner<U extends List<T>>({int bias = 1}) =>
            (U == List<T>) && bias == 1;
        return inner;
      }

      bool main() {
        dynamic escaped = make<int>();
        return escaped() && escaped(bias: 1);
      }
    ''');
  });

  test('explicit invalid inner argument fails before entering body', () {
    _expectTrue('''
      int calls = 0;

      dynamic make<T>() {
        void inner<U extends T>(U value) { calls++; }
        return inner;
      }

      bool main() {
        dynamic escaped = make<num>();
        try {
          escaped<String>('wrong');
        } on TypeError {
          return calls == 0;
        }
        return false;
      }
    ''');
  });

  test('nested closure retains its generic runtime signature', () {
    _expectTrue('''
      dynamic make<T>() {
        bool inner<U extends List<T>>() => U == List<T>;
        return inner;
      }

      bool main() {
        dynamic escaped = make<int>();
        return escaped is bool Function<U extends List<int>>() &&
            escaped is! bool Function<U extends List<String>>();
      }
    ''');
  });

  test('exact named and omitted default calls check both owner types', () {
    _expectTrue('''
      dynamic make<T>() {
        bool inner<U>(T outer, U current, {int bias = 1}) =>
            T == int && U == String && outer is int &&
            current is String && bias == 1;
        return inner;
      }

      bool main() {
        dynamic escaped = make<int>();
        return escaped<String>(3, 'first') &&
            escaped<String>(4, 'second', bias: 1);
      }
    ''');
  });

  test('async closure keeps both generic owners after an await', () async {
    await _expectAsyncTrue('''
      dynamic make<T>() {
        Future<bool> inner<U>(U value, {int bias = 1}) async {
          await 0;
          return T == int && U == String && value is String &&
              (<T>[] is List<int>) && (<U>[] is List<String>) && bias == 1;
        }
        return inner;
      }

      Future<bool> main() async {
        dynamic escaped = make<int>();
        return await escaped<String>('value');
      }
    ''');
  });

  test('sync generator keeps both generic owners while resuming', () {
    _expectTrue('''
      dynamic make<T>() {
        Iterable<bool> inner<U>(U value) sync* {
          yield T == int;
          yield U == String;
          yield value is String;
          yield <T>[] is List<int>;
          yield <U>[] is List<String>;
        }
        return inner;
      }

      bool main() {
        dynamic escaped = make<int>();
        var count = 0;
        for (final bool check in escaped<String>('value')) {
          if (!check) return false;
          count++;
        }
        return count == 5;
      }
    ''');
  });

  test('generative constructor closure retains its class argument', () {
    _expectTrue('''
      class Holder<T> {
        late dynamic callback;

        Holder() {
          bool inner<U extends List<T>>() => U == List<T>;
          callback = inner;
        }
      }

      bool main() {
        dynamic escaped = Holder<int>().callback;
        return escaped();
      }
    ''');
  });

  test('factory closure defaults against its class argument', () {
    _expectTrue('''
      class Holder<T> {
        final dynamic callback;
        Holder._(this.callback);

        factory Holder.make() {
          bool inner<U extends List<T>>() => U == List<T>;
          return Holder<T>._(inner);
        }
      }

      bool main() {
        dynamic escaped = Holder<int>.make().callback;
        return escaped();
      }
    ''');
  });

  test('factory closure rejects an explicit bound violation', () {
    _expectTrue('''
      int calls = 0;

      class Holder<T> {
        final dynamic callback;
        Holder._(this.callback);

        factory Holder.make() {
          void inner<U extends T>() { calls++; }
          return Holder<T>._(inner);
        }
      }

      bool main() {
        dynamic escaped = Holder<num>.make().callback;
        try {
          escaped<String>();
        } on TypeError {
          return calls == 0;
        }
        return false;
      }
    ''');
  });
}
