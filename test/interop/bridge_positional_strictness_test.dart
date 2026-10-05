import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart' show RuntimeException;
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const host = 'package:strict_bridge/host.dart';
const guest = 'package:strict_bridge/main.dart';
const contextType = BridgeTypeRef(BridgeTypeSpec(host, 'Context'));
const directionType = BridgeTypeRef(BridgeTypeSpec(host, 'Direction'));
const axisType = BridgeTypeRef(BridgeTypeSpec(host, 'Axis'));
const intType = BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int));

Compiler compiler() => Compiler()
  ..defineBridgeClasses([
    const BridgeClassDef(
      BridgeClassType(contextType),
      constructors: {},
      wrap: true,
    ),
    const BridgeClassDef(
      BridgeClassType(directionType),
      constructors: {},
      wrap: true,
    ),
    const BridgeClassDef(
      BridgeClassType(axisType),
      constructors: {},
      wrap: true,
    ),
    const BridgeClassDef(
      BridgeClassType(BridgeTypeRef(BridgeTypeSpec(host, 'Lookup'))),
      constructors: {},
      methods: {
        'maybeOf': BridgeMethodDef(
          BridgeFunctionDef(
            returns: intType,
            params: [
              BridgeParameter(
                'context',
                BridgeTypeAnnotation(contextType),
                false,
              ),
            ],
            namedParams: [
              BridgeParameter(
                'direction',
                BridgeTypeAnnotation(directionType, nullable: true),
                true,
              ),
            ],
          ),
          isStatic: true,
        ),
      },
      wrap: true,
    ),
  ])
  ..defineBridgeTopLevelFunction(
    const BridgeFunctionDeclaration(
      host,
      'convert',
      BridgeFunctionDef(
        returns: intType,
        params: [
          BridgeParameter(
            'direction',
            BridgeTypeAnnotation(directionType),
            false,
          ),
        ],
      ),
    ),
  );

Program compile(String source) => compiler().compile({
  'strict_bridge': {'main.dart': "import 'host.dart';\n$source"},
});

class _Nominal extends $Object {
  _Nominal(this.spec) : super(Object());
  final BridgeTypeSpec spec;
  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(spec);
}

int nativeLookup(Object context) => 7;
int nativeConvert(Object direction) => 9;

void main() {
  for (final encoded in [false, true]) {
    test(
      'static calls retain callable coercion and nullable arguments encoded=$encoded',
      () {
        final program = Compiler().compile({
          'strict_apply': {
            'main.dart': '''
class Callable { int call(int n) => n + 1; }
int empty() => 4;
int main() => Function.apply(Callable(), [2], null) + Function.apply(empty, null, null);
''',
          },
        });
        final runtime = encoded
            ? Runtime(program.write().buffer)
            : Runtime.ofProgram(program);
        expect(runtime.executeLib('package:strict_apply/main.dart', 'main'), 7);
      },
    );
  }
  for (final encoded in [false, true]) {
    test('dynamic arguments retain runtime checks encoded=$encoded', () {
      final program = compile('''
int lookup(dynamic context) => Lookup.maybeOf(context);
int convertDirection(dynamic direction) => convert(direction);
''');
      final runtime = encoded
          ? Runtime(program.write().buffer)
          : Runtime.ofProgram(program);
      var calls = 0;
      runtime.registerBridgeFuncRegisters(host, 'Lookup.maybeOf', (_, r, s, c) {
        calls++;
        return $int(7);
      });
      runtime.registerBridgeFuncRegisters(host, 'convert', (_, r, s, c) {
        calls++;
        return $int(9);
      });
      expect(
        runtime.executeLib(
          guest,
          'lookup',
          arguments: {'context': _Nominal(contextType.spec!)},
        ),
        7,
      );
      expect(
        runtime.executeLib(
          guest,
          'convertDirection',
          arguments: {'direction': _Nominal(directionType.spec!)},
        ),
        9,
      );
      for (final invalid in [$int(1), _Nominal(axisType.spec!)]) {
        expect(
          () => runtime.executeLib(
            guest,
            'lookup',
            arguments: {'context': invalid},
          ),
          throwsA(isA<RuntimeException>()),
        );
        expect(
          () => runtime.executeLib(
            guest,
            'convertDirection',
            arguments: {'direction': invalid},
          ),
          throwsA(isA<RuntimeException>()),
        );
      }
      expect(calls, 2);
    });
  }
  for (final encoded in [false, true]) {
    test('nominal bridge positives encoded=$encoded', () {
      final program = compile('''
int lookup(Context context, Direction direction) => Lookup.maybeOf(context, direction: direction);
int convertDirection(Direction direction) => convert(direction);
''');
      final runtime = encoded
          ? Runtime(program.write().buffer)
          : Runtime.ofProgram(program);
      runtime.registerBridgeFuncRegisters(
        host,
        'Lookup.maybeOf',
        (_, r, s, c) => $int(nativeLookup((r as $Value).$reified)),
      );
      runtime.registerBridgeFuncRegisters(
        host,
        'convert',
        (_, r, s, c) => $int(nativeConvert((r as $Value).$reified)),
      );
      final context = _Nominal(contextType.spec!);
      final direction = _Nominal(directionType.spec!);
      expect(
        runtime.executeLib(
          guest,
          'lookup',
          arguments: {'context': context, 'direction': direction},
        ),
        nativeLookup(context.$reified),
      );
      expect(
        runtime.executeLib(
          guest,
          'convertDirection',
          arguments: {'direction': direction},
        ),
        nativeConvert(direction.$reified),
      );
    });
  }
  for (final entry in {
    'static positional primitive': 'int f() => Lookup.maybeOf(1);',
    'static positional nominal': 'int f(Axis axis) => Lookup.maybeOf(axis);',
    'top-level positional primitive': 'int f() => convert(1);',
    'top-level positional nominal': 'int f(Axis axis) => convert(axis);',
    'static named nominal':
        'int f(Context context, Axis axis) => Lookup.maybeOf(context, direction: axis);',
  }.entries) {
    test('rejects ${entry.key}', () {
      expect(() => compile(entry.value), throwsA(isA<CompileError>()));
    });
  }
  test('native guest declarations reject wrong nominal and primitive', () {
    for (final argument in ['1', 'Axis()']) {
      expect(
        () => Compiler().compile({
          'strict_native': {
            'main.dart':
                '''
class Context {}
class Axis {}
class Lookup { static int maybeOf(Context context) => 7; }
int convert(Context context) => 9;
int f() => Lookup.maybeOf($argument);
''',
          },
        }),
        throwsA(isA<CompileError>()),
      );
      expect(
        () => Compiler().compile({
          'strict_native': {
            'main.dart':
                '''
class Context {}
class Axis {}
int convert(Context context) => 9;
int f() => convert($argument);
''',
          },
        }),
        throwsA(isA<CompileError>()),
      );
    }
  });
}
