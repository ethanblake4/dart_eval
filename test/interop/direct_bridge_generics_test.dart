import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart' show RuntimeException;
import 'package:test/test.dart';

const _bridge = 'package:direct_generic/host.dart';
const _library = 'package:direct_generic/main.dart';
const _t = BridgeTypeAnnotation(BridgeTypeRef.ref('T'));
const _box = BridgeTypeSpec(_bridge, 'HostBox');

class _HostBox extends $Object {
  _HostBox(this.value, this.type) : super(Object());
  final $Value value;
  final int type;

  @override
  int $getRuntimeType(Runtime runtime) => type;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) =>
      switch (identifier) {
        'stored' => value,
        'choose' ||
        'shadow' => $Function((runtime, target, r, s, c) => r as $Value?),
        _ => super.$getProperty(runtime, identifier),
      };
}

class _Plugin implements EvalPlugin {
  const _Plugin();
  @override
  String get identifier => _bridge;

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass(
      const BridgeClassDef(
        BridgeClassType(
          BridgeTypeRef(_box),
          generics: {'E': BridgeGenericParam()},
        ),
        constructors: {
          '': BridgeConstructorDef(
            BridgeFunctionDef(
              generics: {'E': BridgeGenericParam()},
              returns: BridgeTypeAnnotation(BridgeTypeRef(_box)),
              params: [
                BridgeParameter(
                  'value',
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                  false,
                ),
              ],
            ),
          ),
        },
        methods: {
          'shadow': BridgeMethodDef(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
              params: [
                BridgeParameter(
                  'value',
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                  false,
                ),
              ],
              generics: {
                'E': BridgeGenericParam($extends: BridgeTypeRef(CoreTypes.num)),
              },
            ),
          ),
          'choose': BridgeMethodDef(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
              params: [
                BridgeParameter(
                  'value',
                  BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
                  false,
                ),
              ],
              generics: {
                'R': BridgeGenericParam($extends: BridgeTypeRef.ref('E')),
              },
            ),
          ),
        },
        getters: {
          'stored': BridgeMethodDef(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
            ),
          ),
        },
        setters: {},
        fields: {},
        wrap: true,
      ),
    );
    for (final name in [
      'identity',
      'wrong',
      'bounded',
      'make',
      'named',
      'dependent',
    ]) {
      registry.defineBridgeTopLevelFunction(
        BridgeFunctionDeclaration(
          _bridge,
          name,
          BridgeFunctionDef(
            returns: _t,
            generics: {
              'T': name == 'bounded'
                  ? const BridgeGenericParam(
                      $extends: BridgeTypeRef(CoreTypes.num),
                    )
                  : name == 'dependent'
                  ? const BridgeGenericParam(
                      $extends: BridgeTypeRef(CoreTypes.list, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('U')),
                      ]),
                    )
                  : const BridgeGenericParam(),
              if (name == 'dependent') 'U': const BridgeGenericParam(),
            },
            params: name == 'make' || name == 'named'
                ? const []
                : const [BridgeParameter('value', _t, false)],
            namedParams: name == 'named'
                ? const [BridgeParameter('value', _t, false)]
                : const [],
          ),
        ),
      );
    }
  }

  @override
  void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      _bridge,
      'HostBox.',
      (runtime, value, b, c) =>
          _HostBox(value as $Value, runtime.bridgeConstructorTypeId!),
    );
    for (final name in ['identity', 'bounded', 'named', 'dependent']) {
      runtime.registerBridgeFuncRegisters(_bridge, name, (
        runtime,
        value,
        b,
        c,
      ) {
        if (value is $List) {
          final resultType = runtime.bridgeCallReturnTypeId;
          expect(resultType, isNotNull);
          expect(
            runtime.runtimeTypesEqual(
              resultType!,
              runtime,
              value.$getRuntimeType(runtime),
            ),
            true,
            reason: 'host receives the exact nested return descriptor',
          );
        }
        return value as $Value?;
      });
    }
    runtime.registerBridgeFuncRegisters(
      _bridge,
      'wrong',
      (_, a, b, c) => $String('wrong'),
    );
    runtime.registerBridgeFuncRegisters(
      _bridge,
      'make',
      (_, a, b, c) => $List.wrap([$int(7)]),
    );
  }
}

Program _compile(String source) =>
    (Compiler()..addPlugin(const _Plugin())).compile({
      'direct_generic': {'main.dart': "import 'host.dart';\n$source"},
    });

void main() {
  test(
    'direct bridge own generics preserve nested types and guest identity',
    () {
      final program = _compile('''
      class Token {}
      T lexical<T>(T value) => identity<T>(value);
      T lexicalReceiver<T>(HostBox<T> box, T value) => box.choose<T>(value);
      class Box<T> {
        final T value;
        Box(this.value);
        T read() => identity<T>(value);
      }
      extension Values<T> on Iterable<T> {
        T selected() => identity<T>(first);
      }
      bool main() {
        final nested = identity<List<List<int>>>([[21]]);
        final inferred = identity([[22]]);
        final namedValue = named(value: <int>[24]);
        final boundedValue = dependent<List<int>, int>([27]);
        final hostInts = HostBox<List<int>>([28]);
        final hostText = HostBox<String>('scope');
        List<int> contextual = make();
        final token = Token();
        return nested is List<List<int>> && nested.first.first == 21 &&
            inferred is List<List<int>> && inferred.first.first == 22 &&
            contextual.first == 7 && identical(lexical(token), token) &&
            identical(identity(token), token) &&
            namedValue.first == 24 && Box<List<int>>([25]).read().first == 25 &&
            boundedValue.first == 27 &&
            hostInts.choose<List<int>>([29]).first == 29 &&
            hostText.choose<String>('other') == 'other' &&
            hostText.shadow<int>(32) == 32 && hostText.shadow(33) == 33 &&
            hostInts.choose([30]).first == 30 && hostInts.stored.first == 28 &&
            lexicalReceiver(hostInts, [31]).first == 31 &&
            lexical<List<int>>([26]).first == 26 &&
            lexical<List<String>>(['scope']).first == 'scope' &&
            <List<int>>[[23]].selected().first == 23;
      }
    ''');
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        runtime.addPlugin(const _Plugin());
        expect(runtime.executeLib(_library, 'main'), true);
      }
    },
  );

  test('nested direct bridge inference retains unresolved argument holes', () {
    final program = _compile('''
      bool main() {
        final value = identity(identity(7));
        return value == 7;
      }
    ''');
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      runtime.addPlugin(const _Plugin());
      expect(runtime.executeLib(_library, 'main'), true);
    }
  });

  for (final source in [
    "int main() => identity<int>('wrong');",
    "void main() { identity<int>(identity('wrong')); }",
    "T lexical<T>(T value) => identity<T>(identity('wrong')); void main() { lexical<int>(1); }",
    "void main() { final value = bounded(identity('wrong')); }",
    "void main() { HostBox<int>(1).choose(identity('wrong')); }",
    "String main() => identity<int>(1);",
    "String main() => bounded<String>('wrong');",
    "String main() => bounded('wrong');",
    "int main() => named<int>(value: 'wrong');",
    "int main() => identity<int, String>(1);",
    "List<String> main() => dependent<List<String>, int>(['wrong']);",
    "String main() => HostBox<int>(1).choose<String>('wrong');",
    "String main() => HostBox<String>('owner').shadow<String>('wrong');",
  ]) {
    test(
      'rejects $source',
      () => expect(() => _compile(source), throwsA(isA<CompileError>())),
    );
  }

  test('direct bridge checks the substituted host result', () {
    final program = _compile('int main() => wrong<int>(1);');
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      runtime.addPlugin(const _Plugin());
      expect(
        () => runtime.executeLib(_library, 'main'),
        throwsA(
          isA<RuntimeException>().having(
            (error) => error.caughtException,
            'cause',
            isA<TypeError>(),
          ),
        ),
      );
    }
  });

  test('dynamic arguments retain the instantiated parameter check', () {
    final program = _compile('''
      int main() {
        dynamic value = 'wrong';
        return identity<int>(value);
      }
    ''');
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      runtime.addPlugin(const _Plugin());
      expect(
        () => runtime.executeLib(_library, 'main'),
        throwsA(
          isA<RuntimeException>().having(
            (error) => error.caughtException,
            'cause',
            isA<TypeError>(),
          ),
        ),
      );
    }
  });
}
