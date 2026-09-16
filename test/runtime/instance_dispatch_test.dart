import 'dart:typed_data';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'exported typed instances expose methods and fields through a Runtime',
    () {
      final program = Compiler().compileTyped({
        'typed': {
          'main.dart': '''
          class Counter {
            int value;
            Counter(this.value);
            int add(int amount) { value = value + amount; return value; }
            Object echo(Object other) => other;
          }
          Counter main() => Counter(7);
        ''',
        },
      }, entrypoint: 'package:typed/main.dart');
      final instance = TypedMachine.run(program) as TypedInstance;
      final runtime = Runtime.ofProgram(
        Compiler().compile({
          'bridge': {'main.dart': 'int main() => 0;'},
        }),
      );
      expect(
        (runtime.invokeTypedObject(instance, 'add', [$int(5)]) as $int).$value,
        12,
      );
      expect((instance.$getProperty(runtime, 'value') as $int).$value, 12);
      instance.$setProperty(runtime, 'value', $int(19));
      expect((instance.getProperty('value') as $int).$value, 19);
      expect(identical(instance.invoke('echo', [instance]), instance), isTrue);
    },
  );

  TypedProgram makeProgram() => TypedProgram(
    Uint8List.fromList([
      TypedOp.sReturn,
      TypedOp.rReturn,
      TypedOp.rConstant,
      0,
      0,
      TypedOp.rReturn,
    ]),
    objects: [$int(73)],
    functions: [
      const TypedFunction(
        0,
        argumentKinds: [TypedArgumentKind.object, TypedArgumentKind.object],
      ),
      const TypedFunction(1, argumentKinds: [TypedArgumentKind.object]),
      const TypedFunction(2, argumentKinds: [TypedArgumentKind.object]),
    ],
    classes: [
      TypedClass(
        'Base',
        library: 'package:example/main.dart',
        valueCount: 1,
        methods: {'echo': 0, 'self': 1},
        getters: {'value': 2},
      ),
      TypedClass(
        'Derived',
        library: 'package:example/main.dart',
        valueCount: 0,
        methods: {'self': 2},
      ),
    ],
  );

  test('host member calls preserve boxed scalar and instance identity', () {
    final program = makeProgram();
    final receiver = TypedInstance(program, 0);
    final boxed = $int(42);
    expect(receiver, isA<$Instance>());
    expect(identical(receiver.invoke('echo', [boxed]), boxed), isTrue);
    expect(identical(receiver.invoke('echo', [receiver]), receiver), isTrue);
    expect(identical(TypedInterop.boxExternal(receiver), receiver), isTrue);
    expect(identical(TypedInterop.exportExternal(receiver), receiver), isTrue);
    expect(() => receiver.invoke('echo', const []), throwsArgumentError);
  });

  test('host adapters box native operator results from signature metadata', () {
    final program = TypedProgram(
      Uint8List.fromList([TypedOp.eTrue, TypedOp.eReturn]),
      functions: [
        const TypedFunction(
          0,
          argumentKinds: [TypedArgumentKind.object, TypedArgumentKind.object],
          resultKind: TypedArgumentKind.boolean,
        ),
      ],
      classes: [
        TypedClass(
          'Equal',
          library: 'package:example/main.dart',
          valueCount: 0,
          methods: {'==': 0},
        ),
      ],
    );
    final receiver = TypedInstance(program, 0);
    expect(TypedInterop.equals(null, receiver, $String('anything')), isTrue);
    expect(receiver.invoke('==', [null]), isA<$bool>());
  });

  test('typed getters and bound methods work without a reference Runtime', () {
    final receiver = TypedInstance(makeProgram(), 0);
    expect(
      (TypedInterop.getProperty(null, receiver, 'value') as $int).$value,
      73,
    );
    final method = TypedInterop.getProperty(null, receiver, 'echo');
    final value = $String('kept boxed');
    expect(identical(TypedInterop.call(null, method, [value]), value), isTrue);
    expect(TypedInterop.equals(null, receiver, receiver), isTrue);
    expect(
      TypedInterop.equals(null, receiver, TypedInstance(receiver.program, 0)),
      isFalse,
    );
  });

  test('base field views resolve virtual members from the derived object', () {
    final program = makeProgram();
    final base = TypedInstance(program, 0);
    final root = TypedInstance(program, 1, base);
    expect(identical(base.dispatchRoot, root), isTrue);
    final target = base.resolve(TypedMemberKind.method, 'self');
    expect(target!.functionId, 2);
    expect(identical(target.receiver, root), isTrue);
    expect(
      identical(target, root.resolve(TypedMemberKind.method, 'self')),
      isTrue,
    );
    final inherited = root.resolve(TypedMemberKind.method, 'echo');
    expect(identical(inherited!.receiver, base), isTrue);
    expect((base.invoke('self', const []) as $int).$value, 73);
    expect(TypedInterop.equals(null, root, base), isTrue);
  });
}
