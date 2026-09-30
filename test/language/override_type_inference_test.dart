import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:test/test.dart';

void main() {
  test('static generic members do not require instance type bindings', () {
    final program = Compiler().compile({
      'override_inference': {
        'main.dart': '''
          mixin Matches<T> {
            static int number(int value) => value;
            bool accepts(Object? value) => value is T;
          }
          class Box<T> with Matches<T> {
            static int number() => 7;
          }
          bool main() => Matches.number(3) == 3 && Box.number() == 7 &&
              Box<int>().accepts(1) && !Box<int>().accepts('wrong');
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:override_inference/main.dart', 'main'),
        true,
      );
    }
  });
  test('method parameter names do not replace inherited class types', () {
    final program = Compiler().compile({
      'override_inference': {
        'main.dart': '''
          abstract class Contract<T> { T read<U>(); }
          class Implementation<T> implements Contract<T> {
            read<T>() => throw 'unused';
          }
          Function main() => Implementation<int>().read;
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      final closure =
          runtime.executeLib('package:override_inference/main.dart', 'main')
              as $Value;
      expect(
        runtime.runtimeTypeToString(closure.$getRuntimeType(runtime)),
        '<T0>() => int',
      );
    }
  });
  test('generic overrides rebind inherited return parameters', () {
    final program = Compiler().compile({
      'override_inference': {
        'main.dart': '''
          abstract class Contract {
            T echo<T extends num>(T value);
          }
          class Implementation implements Contract {
            echo<U extends num>(U value) => value;
          }
          Function main() => Implementation().echo;
          int invoke() => Implementation().echo<int>(4);
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      final closure =
          runtime.executeLib('package:override_inference/main.dart', 'main')
              as $Value;
      expect(
        runtime.runtimeTypeToString(closure.$getRuntimeType(runtime)),
        '<T0 extends num>(T0) => T0',
      );
      expect(
        runtime.executeLib('package:override_inference/main.dart', 'invoke'),
        4,
      );
    }
  });
  test('async methods retain inherited Future payload types', () async {
    final program = Compiler().compile({
      'override_inference': {
        'main.dart': '''
          abstract class Loader<T> { Future<T> load(); }
          class IntLoader implements Loader<int> { load() async => 7; }
          Future<int> main() async => await IntLoader().load();
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        (await runtime.executeLib(
          'package:override_inference/main.dart',
          'main',
        )).$value,
        7,
      );
    }
  });
  test('method tear-offs retain inherited parameter and return types', () {
    final program = Compiler().compile({
      'override_inference': {
        'main.dart': '''
          class Wide {
            int convert(num value) => value.toInt();
          }
          class Narrow {
            num convert(int value) => value;
          }
          class Implementation implements Wide, Narrow {
            convert(value) => value.toInt();
          }
          class Optional {
            void update([int value = 0]) {}
          }
          class OptionalImplementation implements Optional {
            update([value = 1]) {}
          }
          List<Function> main() => [
            Implementation().convert, OptionalImplementation().update,
          ];
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      final result =
          runtime.executeLib('package:override_inference/main.dart', 'main')
              as List;
      final closures = result;
      expect(
        runtime.runtimeTypeToString(
          (closures[0] as $Value).$getRuntimeType(runtime),
        ),
        'int Function(num)',
      );
      expect(
        runtime.runtimeTypeToString(
          (closures[1] as $Value).$getRuntimeType(runtime),
        ),
        'void Function(int)',
      );
    }
  });
}
