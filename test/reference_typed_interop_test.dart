import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/src/eval/runtime/function.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  const library = 'package:interop/main.dart';
  final program = Compiler().compile({
    'interop': {
      'main.dart': '''
        int increment(int value) => value + 1;
        double twice(double value) => value * 2.0;
        bool invert(bool value) => !value;
        String text(String value) => value;
        class Box {
          final int value;
          Box(this.value);
          int plus(int other) => value + other;
          dynamic identity(dynamic other) => other;
          bool operator ==(Object other) => true;
          int optional([int other = 1]) => value + other;
        }
        Box make() => Box(10);
      ''',
    },
  });

  for (final serialized in [false, true]) {
    test(
      'boxed dynamic calls use compiled reference signatures, serialized=$serialized',
      () {
        final runtime = serialized
            ? Runtime(program.write().buffer)
            : Runtime.ofProgram(program);
        final instance = runtime.executeLib(library, 'make');
        expect(
          TypedInterop.toInt(
            TypedInterop.invoke(runtime, instance, 'plus', [$int(7)]),
          ),
          17,
        );
        expect(
          TypedInterop.equals(runtime, instance, $String('unrelated')),
          isTrue,
        );
        expect(
          identical(
            TypedInterop.invoke(runtime, instance, 'identity', [
              instance as $Value,
            ]),
            instance,
          ),
          isTrue,
        );
        expect(
          () => TypedInterop.invoke(runtime, instance, 'optional', []),
          throwsArgumentError,
        );
        expect(
          TypedInterop.toInt(
            TypedInterop.invoke(runtime, instance, 'optional', [$int(2)]),
          ),
          12,
        );

        final declarations = program
            .topLevelDeclarations[program.bridgeLibraryMappings[library]]!;
        $Value? call(String name, $Value value) => TypedInterop.call(
          runtime,
          EvalStaticFunctionPtr(null, declarations[name]!),
          [value],
        );
        expect(TypedInterop.toInt(call('increment', $int(7))), 8);
        expect(TypedInterop.toDouble(call('twice', $double(1.5))), 3.0);
        expect(TypedInterop.toBool(call('invert', $bool(true))), isFalse);
        expect(
          TypedInterop.toStringValue(call('text', $String('value'))),
          'value',
        );
      },
    );
  }
}
