import 'dart:typed_data';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

TypedProgram makeProgram(int defaultValue, {bool descriptors = true}) {
  TypedClosureDescriptor bound(int value) => TypedClosureDescriptor(
    0,
    hasEnvironment: false,
    boundReceiver: true,
    captureCount: 1,
    positionalCount: 1,
    requiredPositional: 0,
    positionalDefaults: [value],
  );
  return TypedProgram(
    Uint8List.fromList([TypedOp.sReturn, TypedOp.rReturn]),
    functions: const [
      TypedFunction(
        0,
        argumentKinds: [TypedArgumentKind.object, TypedArgumentKind.object],
        resultKind: TypedArgumentKind.object,
      ),
      TypedFunction(
        1,
        argumentKinds: [TypedArgumentKind.object],
        resultKind: TypedArgumentKind.object,
      ),
    ],
    classes: [
      TypedClass(
        'Receiver',
        library: 'package:descriptor_receiver/main.dart',
        valueCount: 0,
        methods: {'value': 0, 'self': 1},
      ),
    ],
    closures: descriptors
        ? [
            // Same function, but not a bound method. It must be ignored.
            TypedClosureDescriptor(
              0,
              hasEnvironment: false,
              captureCount: 0,
              positionalCount: 2,
              requiredPositional: 2,
              positionalDefaults: [null, null],
            ),
            bound(defaultValue),
            bound(defaultValue + 100),
            TypedClosureDescriptor(
              1,
              hasEnvironment: false,
              boundReceiver: true,
              captureCount: 1,
              positionalCount: 0,
              requiredPositional: 0,
            ),
          ]
        : const [],
  );
}

void main() {
  test(
    'bound method defaults select the first bound descriptor per program',
    () {
      for (final encoded in [false, true]) {
        TypedProgram selected(int value) {
          final program = makeProgram(value);
          return encoded ? TypedProgram.read(program.write().buffer) : program;
        }

        final first = TypedInstance(selected(11), 0);
        final second = TypedInstance(selected(23), 0);
        expect((first.invoke('value', 0, null, null) as $int).$value, 11);
        expect((second.invoke('value', 0, null, null) as $int).$value, 23);
        expect((first.invoke('value', 0, null, null) as $int).$value, 11);

        final bare = makeProgram(0, descriptors: false);
        final receiver = TypedInstance(
          encoded ? TypedProgram.read(bare.write().buffer) : bare,
          0,
        );
        final argument = $int(91);
        expect(
          receiver.resolve(TypedMemberKind.method, 'value')!.boundClosure,
          isNull,
        );
        expect(
          identical(receiver.invoke('value', 1, argument, null), argument),
          isTrue,
        );
      }
    },
  );

  test('indexed descriptors still bind separate receivers and runtimes', () {
    final runtimeProgram = Compiler().compile({
      'descriptor_runtime': {'main.dart': 'void main() {}'},
    });
    final runtimeA = Runtime.ofProgram(runtimeProgram);
    final runtimeB = Runtime(runtimeProgram.write().buffer);
    final original = makeProgram(11);
    for (final program in [
      original,
      TypedProgram.read(original.write().buffer),
    ]) {
      final receiverA = TypedInstance(program, 0, null, runtimeA);
      final receiverB = TypedInstance(program, 0, null, runtimeB);
      final closureA = receiverA
          .resolve(TypedMemberKind.method, 'self')!
          .boundClosure!;
      final closureB = receiverB
          .resolve(TypedMemberKind.method, 'self')!
          .boundClosure!;
      expect(identical(closureA.descriptor, closureB.descriptor), isTrue);
      expect(identical(closureA, closureB), isFalse);
      expect(identical(closureA.runtime, runtimeA), isTrue);
      expect(identical(closureB.runtime, runtimeB), isTrue);
      expect(identical(closureA.invoke(0, null, null), receiverA), isTrue);
      expect(identical(closureB.invoke(0, null, null), receiverB), isTrue);
    }
  });
}
