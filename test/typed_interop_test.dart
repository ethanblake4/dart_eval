import 'dart:typed_data';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

class _EqualInstance implements $Instance {
  @override
  $Value? $getProperty(Runtime runtime, String identifier) => $Function(
    (runtime, target, args) => identifier == 'echo'
        ? args.single
        : $bool(args.single is _EqualInstance),
  );
  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) =>
      throw UnimplementedError();
  @override
  int $getRuntimeType(Runtime runtime) => throw UnimplementedError();
  @override
  Object get $value => throw StateError('Must preserve instance');
  @override
  Object get $reified => throw StateError('Must preserve instance');
}

void main() {
  final runtime = Runtime.ofProgram(
    Compiler().compile({
      'interop': {'main.dart': 'int main() => 0;'},
    }),
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
  test('host and bridge calls preserve live argument identity', () {
    final instance = $InstanceImpl(
      EvalClass(1, null, [], {}, {}, {}),
      null,
      [],
    );
    Object? host(Object? value) => value;
    expect(
      identical(TypedInterop.call(null, host, [instance]), instance),
      isTrue,
    );
    final bridge = $Function((runtime, target, args) => args.single);
    expect(
      identical(TypedInterop.call(runtime, bridge, [instance]), instance),
      isTrue,
    );
    expect(() => TypedInterop.call(null, bridge, [instance]), throwsStateError);
  });
  test('typed host calls preserve objects through bridge and reentry', () {
    final identity = TypedProgram(
      Uint8List.fromList([TypedOp.rArgument, 0, 0, TypedOp.rReturn]),
    );
    final bridge = $Function(
      (runtime, target, args) =>
          TypedMachine.run(
                identity,
                objectArguments: [args.single],
                runtime: runtime,
              )
              as $Value?,
    );
    final call = TypedProgram(
      Uint8List.fromList([
        TypedOp.rArgument,
        1,
        0,
        TypedOp.rOutgoing,
        0,
        0,
        TypedOp.rArgument,
        0,
        0,
        TypedOp.callHost,
        1,
        0,
        TypedOp.rReturn,
      ]),
      functions: const [
        TypedFunction(0, objectArgumentCount: 2, objectOutgoingCount: 1),
      ],
    );
    final instance = $InstanceImpl(
      EvalClass(1, null, [], {}, {}, {}),
      null,
      [],
    );
    expect(
      identical(
        TypedMachine.run(
          call,
          objectArguments: [bridge, instance],
          runtime: runtime,
        ),
        instance,
      ),
      isTrue,
    );
  });
  test('typed calls unbox primitive bridge returns', () {
    final bridge = $Function((runtime, target, args) => $int(37));
    final call = TypedProgram(
      Uint8List.fromList([
        TypedOp.rArgument,
        0,
        0,
        TypedOp.callHost,
        0,
        0,
        TypedOp.aFromR,
        TypedOp.aReturn,
      ]),
    );
    expect(
      TypedMachine.run(call, objectArguments: [bridge], runtime: runtime),
      37,
    );
    expect(
      () => TypedProgram(
        Uint8List.fromList([
          TypedOp.rArgument,
          0,
          0,
          TypedOp.callHost,
          1,
          0,
          TypedOp.rReturn,
        ]),
      ),
      throwsFormatException,
    );
  });
  test('scalar conversions accept existing bridge wrappers', () {
    expect(TypedInterop.toInt($int(3)), 3);
    expect(TypedInterop.toDouble($double(1.5)), 1.5);
    expect(TypedInterop.toBool($bool(true)), isTrue);
    expect(TypedInterop.equals(null, $String('a'), 'a'), isTrue);
    expect(TypedInterop.equals(null, const $null(), null), isTrue);
    expect(
      () => TypedInterop.toInt(_EqualInstance()),
      throwsA(isA<TypeError>()),
    );
  });
  test('equality uses instance dispatch and preserves evaluated identity', () {
    expect(
      TypedInterop.equals(runtime, _EqualInstance(), _EqualInstance()),
      isTrue,
    );
    final instance = $InstanceImpl(
      EvalClass(1, null, [], {}, {}, {}),
      null,
      [],
    );
    expect(TypedInterop.equals(runtime, instance, instance), isTrue);
    expect(TypedInterop.equals(runtime, instance, _EqualInstance()), isFalse);
  });
}
