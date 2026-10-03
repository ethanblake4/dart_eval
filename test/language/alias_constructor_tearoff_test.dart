import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('explicit alias arguments resolve in the importing library', () {
    final results = runDynamicPackages({
      'alias_scope': {
        'alias.dart': '''
          class Box<T> {
            Box(this.value);
            final T value;
          }
          typedef Alias<T> = Box<T>;
        ''',
        'main.dart': '''
          import 'alias.dart' as source;
          class LocalType {}
          bool main() => source.Alias<LocalType>.new(LocalType()).value
              is LocalType;
        ''',
      },
    }, entrypoint: 'package:alias_scope/main.dart');
    for (final (mode, result) in results) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('aliased tear-offs expand parameters when invoked', () {
    final program = Compiler().compile({
      'alias_tearoff': {
        'main.dart': r'''
          class Box<T> {
            final T value;
            Box(this.value);
            Box.named(this.value);
            Type get argument => T;
          }
          class Pair<S, T> {
            Pair();
            bool get reversed => S == String && T == int;
          }
          typedef Direct<T> = Box<T>;
          typedef Bounded<T extends num> = Box<T>;
          typedef Wrapping<T> = Box<Box<T>>;
          typedef Extra<T, S> = Box<T>;
          typedef Swapped<T, S> = Pair<S, T>;
          bool generic<T>(T value) {
            final create = Wrapping<T>.named;
            final wrapped = create(Box<T>(value));
            return wrapped.argument == (Box<T>) && wrapped.value.argument == T &&
                create == (Wrapping<T>.named);
          }
          bool main() {
            final direct = Direct.new;
            final bounded = Bounded.named;
            final wrapping = Wrapping.new;
            final extra = Extra.named;
            final swapped = Swapped.new;
            Box<Box<int>> Function(Box<int>) contextual = Wrapping.named;
            if (direct<int>(1).argument != int) return false;
            if (bounded<double>(2).argument != double) return false;
            if (wrapping<int>(Box<int>(3)).argument != Box<int>) return false;
            if (extra<int, String>(4).argument != int) return false;
            if (!swapped<int, String>().reversed) return false;
            if (Wrapping<int>.new(Box<int>(5)).argument != Box<int>) return false;
            if (!Swapped<int, String>.new().reversed) return false;
            if (contextual(Box<int>(6)).argument != Box<int>) return false;
            return identical(contextual, Box<Box<int>>.named) && generic<int>(7);
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:alias_tearoff/main.dart', 'main'),
        true,
      );
    }
  });
}
