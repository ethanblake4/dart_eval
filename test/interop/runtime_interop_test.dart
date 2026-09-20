import 'dart:typed_data';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

class _EqualInstance implements $Instance {
  @override
  $Value? $getProperty(Runtime runtime, String identifier) => $Function(
    (runtime, target, r, s, c) => identifier == 'echo'
        ? r as $Value
        : $bool(r is _EqualInstance),
  );
  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) =>
      throw UnimplementedError();
  @override
  int $getRuntimeType(Runtime runtime) => throw UnimplementedError();
  @override
  Object get $value => this;
  @override
  Object get $reified => throw StateError('Must preserve instance');
}

class _BridgeParent implements $Instance {
  @override
  $Value? $getProperty(Runtime runtime, String identifier) =>
      switch (identifier) {
        'echo' => $Function((runtime, target, r, s, c) => r as $Value?),
        'toString' => $Function(
          (runtime, target, r, s, c) => $String('bridge parent'),
        ),
        '==' => $Function((runtime, target, r, s, c) => $bool(true)),
        _ => throw StateError('Unknown bridge property $identifier'),
      };
  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) =>
      throw UnimplementedError();
  @override
  int $getRuntimeType(Runtime runtime) => throw UnimplementedError();
  @override
  Object get $value => this;
  @override
  Object get $reified => throw StateError('Must preserve instance');
}

void main() {
  final runtime = Runtime.ofProgram(
    Compiler().compile({
      'interop': {'main.dart': 'int main() => 0;'},
    }),
  );
  test(
    'typed children invoke inherited bridge methods and Object overrides',
    () {
      final program = TypedProgram(
        Uint8List.fromList([TypedOp.returnNull]),
        classes: [TypedClass('Child', library: 'test', valueCount: 0)],
      );
      final parent = TypedInstance(program, 0, _BridgeParent());
      final child = TypedInstance(program, 0, parent);
      final argument = _EqualInstance();
      expect(
        identical(
          TypedInterop.invoke(runtime, child, 'echo', 1, argument, null),
          argument,
        ),
        isTrue,
      );
      expect(TypedInterop.invoke(runtime, child, 'echo', 1, null, null), isNull);
      expect(
        (TypedInterop.invoke(runtime, child, 'toString', 0, null, null) as $String).$value,
        'bridge parent',
      );
      expect(TypedInterop.equals(runtime, child, argument), isTrue);
    },
  );

  test('typed methods invoke an existing evaluated class instance', () {
    final existing = Runtime.ofProgram(
      Compiler().compile({
        'existing': {
          'main.dart': '''
        class Box {
          final int value;
          Box(this.value);
          int plus(int other) => value + other;
        }
        Box make() => Box(10);
      ''',
        },
      }),
    );
    final instance = existing.executeLib('package:existing/main.dart', 'make');
    final program = Compiler().compileTyped({
      'typed': {'main.dart': 'int main(dynamic receiver) => receiver.plus(7);'},
    }, entrypoint: 'package:typed/main.dart');
    expect(
      TypedMachine.run(program, objectArguments: [instance], runtime: existing),
      17,
    );
  });
  test('source dynamic methods reuse existing instance bridge dispatch', () {
    final program = Compiler().compileTyped({
      'typed': {
        'main.dart':
            'dynamic main(dynamic receiver, dynamic value) => receiver.echo(value);',
      },
    }, entrypoint: 'package:typed/main.dart');
    final value = _EqualInstance();
    expect(
      identical(
        TypedMachine.run(
          program,
          objectArguments: [_EqualInstance(), value],
          runtime: runtime,
        ),
        value,
      ),
      isTrue,
    );
  });
  test(
    'source equality dispatches to existing instances and scalar wrappers',
    () {
      final program = Compiler().compileTyped({
        'typed': {'main.dart': 'bool main(dynamic a, dynamic b) => a == b;'},
      }, entrypoint: 'package:typed/main.dart');
      expect(
        TypedMachine.run(
          program,
          objectArguments: [_EqualInstance(), _EqualInstance()],
          runtime: runtime,
        ),
        isTrue,
      );
      expect(
        TypedMachine.run(
          program,
          objectArguments: [_EqualInstance(), const $null()],
          runtime: runtime,
        ),
        isFalse,
      );
      expect(
        TypedMachine.run(
          program,
          objectArguments: [$int(12), 12],
          runtime: runtime,
        ),
        isTrue,
      );
    },
  );
  test('typed calls unbox primitive bridge returns', () {
    final bridge = $Function((runtime, target, r, s, c) => $int(37));
    final call = TypedProgram(
      Uint8List.fromList([
        TypedOp.callHost,
        0,
        0,
        TypedOp.aFromR,
        TypedOp.aReturn,
      ]),
      functions: const [
        TypedFunction(0, argumentKinds: [TypedArgumentKind.object]),
      ],
    );
    expect(
      TypedMachine.run(call, objectArguments: [bridge], runtime: runtime),
      37,
    );
    expect(
      () => TypedProgram(
        Uint8List.fromList([TypedOp.callHost, 1, 0, TypedOp.rReturn]),
      ),
      throwsFormatException,
    );
  });
  test('scalar conversions require explicit bridge wrappers', () {
    expect(() => TypedInterop.toInt(3), throwsA(isA<TypeError>()));
    expect(() => TypedInterop.toDouble(1.5), throwsA(isA<TypeError>()));
    expect(() => TypedInterop.toBool(true), throwsA(isA<TypeError>()));
    expect(TypedInterop.toInt($int(3)), 3);
    expect(TypedInterop.toDouble($double(1.5)), 1.5);
    expect(TypedInterop.toBool($bool(true)), isTrue);
    expect(TypedInterop.equals(runtime, $String('a'), $String('a')), isTrue);
    expect(TypedInterop.equals(null, null, null), isTrue);
    expect(
      () => TypedInterop.toInt(_EqualInstance()),
      throwsA(isA<TypeError>()),
    );
  });
  test('host boundary normalizes scalars without reading instance values', () {
    final instance = _EqualInstance();
    expect(identical(TypedInterop.boxExternal(instance), instance), isTrue);
    expect(identical(TypedInterop.exportExternal(instance), instance), isTrue);
    expect(TypedInterop.boxExternal(3), isA<$int>());
    expect(TypedInterop.boxExternal(const $null()), isNull);
    expect(TypedInterop.exportExternal($String('value')), 'value');
    final closure = $Closure((runtime, target, r, s, c) => r as $Value?);
    expect(
      identical(TypedInterop.call(runtime, closure, 1, instance, null), instance),
      isTrue,
    );
  });
  test('equality uses instance dispatch', () {
    expect(
      TypedInterop.equals(runtime, _EqualInstance(), _EqualInstance()),
      isTrue,
    );
  });
}
