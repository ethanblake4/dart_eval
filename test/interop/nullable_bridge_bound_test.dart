import 'dart:convert';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:test/test.dart';

const _uri = 'package:nullable_bounds/host.dart';
const _t = BridgeTypeAnnotation(BridgeTypeRef.ref('T'));
const _route = BridgeTypeSpec(_uri, 'Route');
const _page = BridgeTypeSpec(_uri, 'MaterialPageRoute');
const _navigator = BridgeTypeSpec(_uri, 'Navigator');
const _host = BridgeTypeSpec(_uri, 'Host');

class _Value extends $Object {
  _Value(this.type) : super(Object());
  final int type;
  @override
  int $getRuntimeType(Runtime runtime) => type;
  @override
  $Value? $getProperty(Runtime runtime, String identifier) =>
      switch (identifier) {
        'push' => $Function(
          (runtime, target, a, b, c) => $Future.wrap(
            Future<$Value?>.value(null),
            runtime: runtime,
            runtimeTypeId: runtime.bridgeCallReturnTypeId,
          ),
        ),
        'choose' => $Function((runtime, target, a, b, c) => a as $Value?),
        _ => super.$getProperty(runtime, identifier),
      };
}

class _Plugin implements EvalPlugin {
  const _Plugin({this.nullable = true, this.jsonRoundtrip = false});
  final bool nullable;
  final bool jsonRoundtrip;
  @override
  String get identifier => _uri;

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    void define(BridgeClassDef declaration) => registry.defineBridgeClass(
      jsonRoundtrip
          ? BridgeClassDef.fromJson(
              jsonDecode(jsonEncode(declaration.toJson()))
                  as Map<String, dynamic>,
            )
          : declaration,
    );
    final objectBound = BridgeGenericParam(
      $extends: const BridgeTypeRef(CoreTypes.object),
      boundNullable: nullable,
    );
    define(
      const BridgeClassDef(
        BridgeClassType(
          BridgeTypeRef(_route),
          generics: {'T': BridgeGenericParam()},
        ),
        constructors: {},
        methods: {},
        getters: {},
        setters: {},
        fields: {},
        wrap: true,
      ),
    );
    define(
      const BridgeClassDef(
        BridgeClassType(
          BridgeTypeRef(_page),
          $extends: BridgeTypeRef(_route, [_t]),
          generics: {'T': BridgeGenericParam()},
        ),
        constructors: {
          '': BridgeConstructorDef(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(BridgeTypeRef(_page)),
              namedParams: [
                BridgeParameter(
                  'builder',
                  BridgeTypeAnnotation(
                    BridgeTypeRef.genericFunction(
                      BridgeFunctionDef(
                        returns: BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.object),
                        ),
                        params: [
                          BridgeParameter(
                            'context',
                            BridgeTypeAnnotation(
                              BridgeTypeRef(CoreTypes.object),
                            ),
                            false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  false,
                ),
              ],
            ),
          ),
        },
        methods: {},
        getters: {},
        setters: {},
        fields: {},
        wrap: true,
      ),
    );
    define(
      BridgeClassDef(
        const BridgeClassType(BridgeTypeRef(_navigator)),
        constructors: const {
          '': BridgeConstructorDef(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(BridgeTypeRef(_navigator)),
            ),
          ),
        },
        methods: {
          'push': BridgeMethodDef(
            BridgeFunctionDef(
              generics: {'T': objectBound},
              returns: const BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.future, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T'), nullable: true),
                ]),
              ),
              params: const [
                BridgeParameter(
                  'route',
                  BridgeTypeAnnotation(BridgeTypeRef(_route, [_t])),
                  false,
                ),
              ],
            ),
          ),
        },
        getters: const {},
        setters: const {},
        fields: const {},
        wrap: true,
      ),
    );
    define(
      const BridgeClassDef(
        BridgeClassType(
          BridgeTypeRef(_host),
          generics: {'E': BridgeGenericParam()},
        ),
        constructors: {
          '': BridgeConstructorDef(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(BridgeTypeRef(_host)),
            ),
          ),
        },
        methods: {
          'choose': BridgeMethodDef(
            BridgeFunctionDef(
              generics: {
                'T': BridgeGenericParam(
                  $extends: BridgeTypeRef.ref('E'),
                  boundNullable: true,
                ),
              },
              returns: _t,
              params: [BridgeParameter('value', _t, false)],
            ),
          ),
        },
        getters: {},
        setters: {},
        fields: {},
        wrap: true,
      ),
    );
    for (final name in [
      'nullableIdentity',
      'strictObject',
      'strictNum',
      'forward',
    ]) {
      final declaration = BridgeFunctionDeclaration(
        _uri,
        name,
        BridgeFunctionDef(
          generics: {
            'T': BridgeGenericParam(
              $extends: name == 'forward'
                  ? const BridgeTypeRef.ref('U')
                  : BridgeTypeRef(
                      name == 'strictNum' ? CoreTypes.num : CoreTypes.object,
                    ),
              boundNullable: name == 'nullableIdentity' || name == 'forward',
            ),
            if (name == 'forward') 'U': const BridgeGenericParam(),
          },
          returns: _t,
          params: const [BridgeParameter('value', _t, false)],
        ),
      );
      registry.defineBridgeTopLevelFunction(
        jsonRoundtrip
            ? BridgeFunctionDeclaration.fromJson(
                jsonDecode(jsonEncode(declaration.toJson()))
                    as Map<String, dynamic>,
              )
            : declaration,
      );
    }
  }

  @override
  void configureForRuntime(Runtime runtime) {
    for (final name in ['MaterialPageRoute.', 'Navigator.', 'Host.']) {
      runtime.registerBridgeFuncRegisters(
        _uri,
        name,
        (runtime, a, b, c) => _Value(runtime.bridgeConstructorTypeId!),
      );
    }
    for (final name in [
      'nullableIdentity',
      'strictObject',
      'strictNum',
      'forward',
    ]) {
      runtime.registerBridgeFuncRegisters(
        _uri,
        name,
        (runtime, a, b, c) => a as $Value?,
      );
    }
  }
}

Program _compile(String source, _Plugin plugin) =>
    (Compiler()..addPlugin(plugin)).compile({
      'nullable_bounds': {'main.dart': "import 'host.dart';\n$source"},
    });

void main() {
  for (final nullable in [false, true]) {
    test('raw bridged ancestor preserves bound nullable=$nullable', () {
      final ctx = CompilerContext()
        ..libraryMap['dart:core'] = 0
        ..libraryMap[_uri] = 1;
      for (final name in ['Object', 'dynamic', 'int']) {
        final declaration = BridgeTypeDecl(ctx, 0, 'dart:core', name);
        ctx.types.register(declaration);
        (ctx.visibleTypes[0] ??= {})[name] = declaration.rawType;
      }
      final ancestor = BridgeTypeDecl(
        ctx,
        1,
        _uri,
        'Ancestor',
        classDef: BridgeClassDef(
          BridgeClassType(
            const BridgeTypeRef(BridgeTypeSpec(_uri, 'Ancestor')),
            generics: {
              'E': BridgeGenericParam(
                $extends: const BridgeTypeRef(CoreTypes.object),
                boundNullable: nullable,
              ),
            },
          ),
          constructors: const {},
          methods: const {},
          getters: const {},
          setters: const {},
          fields: const {},
          wrap: true,
        ),
      );
      ctx.types.register(ancestor);
      (ctx.visibleTypes[1] ??= {})['Ancestor'] = ancestor.rawType;
      final child = SourceTypeDecl(
        ctx,
        1,
        _uri,
        'Child',
        parseString(
          content: 'class Child extends Ancestor {}',
        ).unit.declarations.single,
      );
      ctx.types.register(child);
      final raw = ctx.typeSystem.bridgedTypeArgument(ancestor.rawType, 'E')!;
      expect(raw.isSpec(CoreTypes.object), true);
      expect(raw.nullable, nullable);
      final inherited = ctx.typeSystem.bridgedTypeArgument(child.rawType, 'E')!;
      expect(inherited.isSpec(CoreTypes.object), true);
      expect(inherited.nullable, nullable);
      final applied = ctx.typeSystem.bridgedTypeArgument(
        ancestor.instantiate([CoreTypes.int.ref(ctx)]),
        'E',
      )!;
      expect(applied.isSpec(CoreTypes.int), true);
      expect(applied.nullable, false);
      expect(
        ctx.typeSystem.bridgedTypeArgument(ancestor.rawType, 'Missing'),
        null,
      );
    });
  }
  test('legacy bounds omit the flag and retain nonnullable semantics', () {
    const legacy = BridgeGenericParam(
      $extends: BridgeTypeRef(CoreTypes.object),
    );
    expect(legacy.toJson().containsKey('boundNullable'), false);
    final restored = BridgeGenericParam.fromJson(legacy.toJson());
    expect(restored.boundNullable, false);
    expect(BridgeGenericParam.fromJson({}).boundNullable, false);
    const nullable = BridgeGenericParam(
      $extends: BridgeTypeRef(CoreTypes.object),
      boundNullable: true,
    );
    expect(
      BridgeGenericParam.fromJson(
        jsonDecode(jsonEncode(nullable.toJson())) as Map<String, dynamic>,
      ).boundNullable,
      true,
    );
  });
  for (final jsonRoundtrip in [false, true]) {
    final plugin = _Plugin(jsonRoundtrip: jsonRoundtrip);
    test(
      'SDK route invocation and nullable bounds, declaration JSON=$jsonRoundtrip',
      () {
        final program = _compile('''
        T lexical<T>(T value) => nullableIdentity<T>(value);
        bool main() {
          Navigator().push(MaterialPageRoute(builder: (context) => Object()));
          Navigator().push<int?>(MaterialPageRoute<int?>(builder: (context) => Object()));
          return nullableIdentity<int?>(null) == null &&
              nullableIdentity(null) == null && lexical<int?>(null) == null &&
              forward<int?, int>(null) == null &&
              Host<int>().choose<int?>(null) == null &&
              Host<int?>().choose<int?>(null) == null &&
              strictObject(7) == 7 && strictNum(8) == 8;
        }
      ''', plugin);
        for (final runtime in [
          Runtime.ofProgram(program),
          Runtime(program.write().buffer),
        ]) {
          runtime.addPlugin(plugin);
          expect(
            runtime.executeLib('package:nullable_bounds/main.dart', 'main'),
            true,
          );
        }
      },
    );
    for (final invocation in [
      'Navigator().push<int>(MaterialPageRoute<String>(builder: (context) => Object()))',
      'strictObject<int?>(null)',
      'strictObject(null)',
      "strictNum<String>('bad')",
      "strictNum('bad')",
      "forward<String, int>('bad')",
      "Host<int>().choose<String>('bad')",
    ]) {
      test('reject $invocation, declaration JSON=$jsonRoundtrip', () {
        expect(
          () => _compile('void main() { $invocation; }', plugin),
          throwsA(isA<CompileError>()),
        );
      });
    }
    test(
      'nonnullable SDK control rejects original invocation, JSON=$jsonRoundtrip',
      () {
        expect(
          () => _compile('''
        void main() {
          Navigator().push(MaterialPageRoute(builder: (context) => Object()));
        }
      ''', _Plugin(nullable: false, jsonRoundtrip: jsonRoundtrip)),
          throwsA(isA<CompileError>()),
        );
      },
    );
    test('lexical nullable bound remains strict, JSON=$jsonRoundtrip', () {
      expect(
        () => _compile('''
          T lexical<T extends Object?>(T value) => strictObject<T>(value);
          void main() {}
        ''', plugin),
        throwsA(isA<CompileError>()),
      );
    });
  }
}
