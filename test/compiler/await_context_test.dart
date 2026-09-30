import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const _library = 'package:await_context/main.dart';
Future<void> _expectTrue(String source) async {
  final program = Compiler().compile({
    'await_context': {'main.dart': source},
  });
  for (final (mode, runtime) in [
    ('fresh', Runtime.ofProgram(program)),
    ('serialized', Runtime(program.write().buffer)),
  ]) {
    expect(
      await runtime.executeLib(_library, 'main'),
      $bool(true),
      reason: mode,
    );
  }
}

void main() {
  test(
    'throw supplies Object context through await and generic calls',
    () async {
      await _expectTrue('''
      import 'dart:async';
      typedef Exactly<T> = T Function(T);
      extension StaticType<T> on T {
        T expectStaticType<R extends Exactly<T>>() => this;
      }
      T id<T>(T value) => value;
      Future<bool> main() async {
        try {
          throw await id(Future.value('caught'))
            ..expectStaticType<Exactly<FutureOr<Object>>>();
        } on String catch (value) {
          return value == 'caught';
        }
        return false;
      }
    ''');
    },
  );
  test(
    'await forwards numeric contexts to plain and Future literals',
    () async {
      await _expectTrue('''
      Future<bool> main() async {
        double number = await 1;
        double future = await Future.value(2);
        dynamic numericValue = number;
        return numericValue is double && number == 1.0 && future == 2.0;
      }
    ''');
    },
  );
  test(
    'await forwards context to plain and Future collection values',
    () async {
      await _expectTrue('''
      Future<bool> main() async {
        List<int> plain = await [];
        List<int> future = await Future.value([]);
        List<int> explicitConstructor = await new Future.value([]);
        Map<String, int> map = await {};
        plain.add(1);
        future.add(2);
        explicitConstructor.add(3);
        map['value'] = 4;
        return plain is List<int> && future is List<int> &&
            explicitConstructor is List<int> &&
            map is Map<String, int> && plain.single == 1 &&
            future.single == 2 && explicitConstructor.single == 3 &&
            map['value'] == 4;
      }
    ''');
    },
  );
  test(
    'uninformative await contexts preserve upward constructor inference',
    () async {
      await _expectTrue('''
      typedef Exactly<T> = T Function(T);
      extension StaticType<T> on T {
        T expectStaticType<R extends Exactly<T>>() => this;
      }
      class Base {}
      class Leaf extends Base {}
      T id<T>(T value) => value;
      Future<T> wrap<T>(T value) => Future.value(value);
      Future<bool> main() async {
        dynamic value = await id((null as Future<Base>?) ??
            (Future.value(Leaf())..expectStaticType<Exactly<Future<Leaf>>>()));
        await ((null as Future<Base>?) ??
            (Future.value(Leaf())..expectStaticType<Exactly<Future<Leaf>>>()));
        List<int> generic = await wrap([]);
        return value is Leaf && generic is List<int> &&
            await Future.value(7) == 7 && await Future.value(8) != 7;
      }
    ''');
    },
  );
}
