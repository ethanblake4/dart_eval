import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart' show $Value;
import 'package:dart_eval/src/eval/ir/bridge.dart' show InvokeExternal;
import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void _expectTrue(String source) {
  for (final (mode, result) in runDynamicFixture(source)) {
    expect(result, const DynamicFixtureResult.value(true), reason: mode);
  }
}

void main() {
  test(
    'deferred variance inference emits only the actual loading check',
    () async {
      for (final constructor in [
        'prefix.Consumer<Never>()',
        '(prefix.Consumer())',
        '(prefix.Consumer.named())',
      ]) {
        final compiler = Compiler();
        final program = compiler.compile({
          'deferred_variance': {
            'consumer.dart': '''
            // @dart=3.13
            class Consumer<in T> { Consumer(); Consumer.named(); }
          ''',
            'main.dart':
                '''
            // @dart=3.13
            import 'consumer.dart';
            import 'consumer.dart' deferred as prefix;
            Type inferred<T>(Consumer<T> value) => T;
            Future<void> load() => prefix.loadLibrary();
            bool main() => inferred($constructor) == Never;
          ''',
          },
        });
        final check =
            program.bridgeFunctionMappings[program
                .bridgeLibraryMappings['dart:core']]!['deferred_checkLoaded'];
        final checks = [
          for (final graph in compiler.functionGraphs.values)
            for (final block in graph.graph.vertices)
              for (final operation in graph[block]!.code)
                if (operation is InvokeExternal &&
                    operation.externalFunctionId == check)
                  operation,
        ];
        expect(checks, hasLength(1), reason: constructor);
        for (final runtime in [
          Runtime.ofProgram(program),
          Runtime(program.write().buffer),
        ]) {
          final loaded = runtime.executeLib(
            'package:deferred_variance/main.dart',
            'load',
          );
          await ((loaded is $Value ? loaded.$reified : loaded) as Future<void>);
          expect(
            runtime.executeLib('package:deferred_variance/main.dart', 'main'),
            true,
          );
        }
      }
    },
  );

  test(
    'imported variance inference ignores grouping and respects shadowing',
    () {
      final packages = {
        'variance_spelling': {
          'consumer.dart': '''
          // @dart=3.13
          class Consumer<in T> {
            Consumer();
            Consumer.named();
            static Consumer<num> create() => Consumer<num>();
          }
        ''',
          'main.dart': '''
          // @dart=3.13
          import 'consumer.dart';
          import 'consumer.dart' as prefix;
          int calls = 0;
          Type inferred<T>(Consumer<T> value) => T;
          Consumer<num> make() {
            calls++;
            return prefix.Consumer<num>();
          }
          class Factory {
            prefix.Consumer<num> Consumer() {
              calls++;
              return prefix.Consumer<num>();
            }
          }
          bool shadowed() {
            final prefix = Factory();
            final Consumer = make;
            return inferred(prefix.Consumer()) == num &&
                inferred(Consumer()) == num;
          }
          bool main() =>
              inferred(Consumer()) == Never &&
              inferred(((Consumer()))) == Never &&
              inferred(prefix.Consumer()) == Never &&
              inferred((prefix.Consumer())) == Never &&
              inferred(Consumer.named()) == Never &&
              inferred(prefix.Consumer.named()) == Never &&
              inferred((prefix.Consumer.named())) == Never &&
              inferred(Consumer.create()) == num &&
              inferred(make()) == num && shadowed() && calls == 3;
        ''',
        },
      };
      for (final (mode, result) in runDynamicPackages(
        packages,
        entrypoint: 'package:variance_spelling/main.dart',
      )) {
        expect(result, const DynamicFixtureResult.value(true), reason: mode);
      }
    },
  );

  test('raw recursive function bounds use alias variance', () {
    _expectTrue('''
      typedef Cov<X extends void Function(X)> = X Function();
      typedef Con<X extends void Function(X)> = void Function(X);
      typedef Inv<X extends void Function(X)> = X Function(X);
      Type typeOf<T>() => T;

      bool main() =>
          typeOf<Cov>() == typeOf<Cov<void Function(Never)>>() &&
          typeOf<Con>() == typeOf<Con<void Function(dynamic)>>() &&
          typeOf<Inv>() == typeOf<Inv<void Function(dynamic)>>();
    ''');
  });

  test('raw recursive nominal bounds use alias variance', () {
    _expectTrue('''
      class A<T> {}
      typedef Cov<X extends A<X>> = X Function();
      typedef Con<X extends A<X>> = void Function(X);
      typedef Inv<X extends A<X>> = X Function(X);
      Type typeOf<T>() => T;

      bool main() =>
          typeOf<Cov>() == typeOf<Cov<A<dynamic>>>() &&
          typeOf<Con>() == typeOf<Con<A<Never>>>() &&
          typeOf<Inv>() == typeOf<Inv<A<dynamic>>>();
    ''');
  });

  test('substituting an outer parameter updates generic function bounds', () {
    final program = Compiler().compile({
      'generic_bound_substitution': {
        'main.dart': '''
          typedef F<X> = void Function<Y extends X>();
          F<X> toF<X>(X source) => throw 0;

          void check(int source) {
            var fs = toF(source);
            F<int> target = fs;
          }

          bool main() {
            check;
            return true;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib(
          'package:generic_bound_substitution/main.dart',
          'main',
        ),
        true,
      );
    }
  });
}
