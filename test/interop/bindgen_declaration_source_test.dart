import 'dart:convert';
import 'dart:io';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bindgen/declaration_source.dart';
import 'package:test/test.dart';

const _classSpec = BridgeTypeSpec(
  "package:fixture/it's_\$lib\n.dart",
  "Odd\$'Widget\n🦋",
);
const _baseSpec = BridgeTypeSpec('package:fixture/base.dart', 'Base');
const _enumSpec = BridgeTypeSpec('package:fixture/enum.dart', 'Mode');

const _callbackFunction = BridgeFunctionDef(
  returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R\$eturn')),
  params: [
    BridgeParameter(
      'callback\narg',
      BridgeTypeAnnotation(
        BridgeTypeRef.ref('T', [
          BridgeTypeAnnotation(BridgeTypeRef(_baseSpec), nullable: true),
        ]),
      ),
      true,
    ),
  ],
  generics: {
    'R\$eturn': BridgeGenericParam(
      $extends: BridgeTypeRef(_baseSpec),
      boundNullable: true,
    ),
  },
);

const _signature = BridgeFunctionDef(
  returns: BridgeTypeAnnotation(
    BridgeTypeRef(_baseSpec, [
      BridgeTypeAnnotation(BridgeTypeRef.ref('T'), nullable: true),
    ]),
  ),
  returnTypeDependency: BridgeReturnTypeDependency(
    paramIndex: 1,
    paramName: 'named\$selector\n',
    cases: [
      BridgeReturnTypeCase(
        BridgeTypeRef(_classSpec),
        BridgeTypeAnnotation(BridgeTypeRef(_enumSpec), nullable: true),
      ),
      BridgeReturnTypeCase(
        BridgeTypeRef.ref('T'),
        BridgeTypeAnnotation(BridgeTypeRef.genericFunction(_callbackFunction)),
      ),
    ],
    fallback: BridgeTypeAnnotation(BridgeTypeRef(_baseSpec)),
  ),
  generics: {
    'T\$\'\n': BridgeGenericParam(
      $extends: BridgeTypeRef(_baseSpec),
      boundNullable: true,
    ),
    'U': BridgeGenericParam(),
  },
  params: [
    BridgeParameter(
      'first\'\$\n',
      BridgeTypeAnnotation(BridgeTypeRef(_classSpec), nullable: true),
      false,
      defaultValueSource: '"quote\' \$value"\nsecond line',
    ),
  ],
  namedParams: [
    BridgeParameter(
      'named',
      BridgeTypeAnnotation(BridgeTypeRef.genericFunction(_callbackFunction)),
      true,
      defaultValueSource: "'quoted'\t\u0001",
    ),
  ],
);

const _classDeclaration = BridgeClassDef(
  BridgeClassType(
    BridgeTypeRef(_classSpec, [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))]),
    $extends: BridgeTypeRef(_baseSpec),
    $implements: [BridgeTypeRef(_enumSpec)],
    $with: [BridgeTypeRef.ref('Mixin')],
    isAbstract: true,
    isMixinClass: true,
    generics: {
      'T': BridgeGenericParam(
        $extends: BridgeTypeRef(_baseSpec),
        boundNullable: true,
      ),
    },
  ),
  constructors: {
    "named\$'\n": BridgeConstructorDef(_signature, isFactory: true),
  },
  methods: {
    'method': BridgeMethodDef(_signature, isStatic: true, isAbstract: true),
  },
  getters: {'value': BridgeMethodDef(_signature)},
  setters: {'value': BridgeMethodDef(_signature, isStatic: true)},
  fields: {
    'field': BridgeFieldDef(
      BridgeTypeAnnotation(BridgeTypeRef.genericFunction(_callbackFunction)),
      isStatic: true,
    ),
  },
  bridge: true,
  wrap: false,
);

const _enumDeclaration = BridgeEnumDef(
  BridgeTypeRef(_enumSpec),
  values: ['one', "two\$'\n"],
  methods: {'call': BridgeMethodDef(_signature)},
  getters: {'name': BridgeMethodDef(_signature, isAbstract: true)},
  setters: {'name': BridgeMethodDef(_signature, isStatic: true)},
  fields: {
    'index': BridgeFieldDef(
      BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
      isStatic: true,
    ),
  },
);

const _functionDeclaration = BridgeFunctionDeclaration(
  "package:fixture/top'\$level.dart\n",
  'top\$Function',
  _signature,
);

const _defaultClassDeclaration = BridgeClassDef(
  BridgeClassType(BridgeTypeRef(_classSpec)),
  constructors: {
    '': BridgeConstructorDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(_classSpec)),
      ),
    ),
  },
  bridge: true,
);

void main() {
  test('default source uses a double-quoted Dart string literal', () {
    final source = bridgeParameterSource(
      const BridgeParameter(
        'home',
        BridgeTypeAnnotation(BridgeTypeRef(_baseSpec)),
        false,
        defaultValueSource: 'm.Defaults.home',
      ),
    );

    expect(source, contains('defaultValueSource: "m.Defaults.home"'));
  });

  test('rendered expressions reconstruct bridge metadata', () async {
    final expected = <String, Object?>{
      'class': _classDeclaration.toJson(),
      'defaultClass': _defaultClassDeclaration.toJson(),
      'enum': _enumDeclaration.toJson(),
      'functionDeclaration': _functionDeclaration.toJson(),
      'function': _signature.toJson(),
      'parameter': const BridgeParameter(
        "last'\$param\n",
        BridgeTypeAnnotation(BridgeTypeRef(_classSpec), nullable: true),
        true,
        defaultValueSource: 'default\r\n\u0000',
      ).toJson(),
      'spec': _classSpec.toJson(),
      'typeRefSpec': const BridgeTypeRef(_classSpec).toJson(),
      'typeRefRef': const BridgeTypeRef.ref('T\$param', [
        BridgeTypeAnnotation(BridgeTypeRef(_baseSpec)),
      ]).toJson(),
      'typeRefFunction': const BridgeTypeRef.genericFunction(
        _callbackFunction,
      ).toJson(),
      'annotation': const BridgeTypeAnnotation(
        BridgeTypeRef(_classSpec),
        nullable: true,
      ).toJson(),
    };

    final expressions = [
      bridgeDeclarationSource(_classDeclaration),
      bridgeDeclarationSource(_defaultClassDeclaration),
      bridgeDeclarationSource(_enumDeclaration),
      bridgeDeclarationSource(_functionDeclaration),
      bridgeFunctionSource(_signature),
      bridgeParameterSource(
        const BridgeParameter(
          "last'\$param\n",
          BridgeTypeAnnotation(BridgeTypeRef(_classSpec), nullable: true),
          true,
          defaultValueSource: 'default\r\n\u0000',
        ),
      ),
      bridgeTypeSpecSource(_classSpec),
      bridgeTypeRefSource(const BridgeTypeRef(_classSpec)),
      bridgeTypeRefSource(
        const BridgeTypeRef.ref('T\$param', [
          BridgeTypeAnnotation(BridgeTypeRef(_baseSpec)),
        ]),
      ),
      bridgeTypeRefSource(
        const BridgeTypeRef.genericFunction(_callbackFunction),
      ),
      bridgeTypeAnnotationSource(
        const BridgeTypeAnnotation(BridgeTypeRef(_classSpec), nullable: true),
      ),
    ];
    expect(expressions.join('\n'), isNot(contains('const ')));

    final script =
        '''
import 'dart:convert';
import 'dart:io';

import 'package:dart_eval/dart_eval_bridge.dart';

void main() {
  const classDeclaration = ${bridgeDeclarationSource(_classDeclaration)};
  const defaultClassDeclaration = ${bridgeDeclarationSource(_defaultClassDeclaration)};
  const enumDeclaration = ${bridgeDeclarationSource(_enumDeclaration)};
  const functionDeclaration = ${bridgeDeclarationSource(_functionDeclaration)};
  const function = ${bridgeFunctionSource(_signature)};
  const parameter = ${bridgeParameterSource(const BridgeParameter("last'\$param\n", BridgeTypeAnnotation(BridgeTypeRef(_classSpec), nullable: true), true, defaultValueSource: 'default\r\n\u0000'))};
  const spec = ${bridgeTypeSpecSource(_classSpec)};
  const typeRefSpec = ${bridgeTypeRefSource(const BridgeTypeRef(_classSpec))};
  const typeRefRef = ${bridgeTypeRefSource(const BridgeTypeRef.ref('T\$param', [BridgeTypeAnnotation(BridgeTypeRef(_baseSpec))]))};
  const typeRefFunction = ${bridgeTypeRefSource(const BridgeTypeRef.genericFunction(_callbackFunction))};
  const annotation = ${bridgeTypeAnnotationSource(const BridgeTypeAnnotation(BridgeTypeRef(_classSpec), nullable: true))};

  final actual = <String, Object?>{
    'class': classDeclaration.toJson(),
    'defaultClass': defaultClassDeclaration.toJson(),
    'enum': enumDeclaration.toJson(),
    'functionDeclaration': functionDeclaration.toJson(),
    'function': function.toJson(),
    'parameter': parameter.toJson(),
    'spec': spec.toJson(),
    'typeRefSpec': typeRefSpec.toJson(),
    'typeRefRef': typeRefRef.toJson(),
    'typeRefFunction': typeRefFunction.toJson(),
    'annotation': annotation.toJson(),
  };
  stdout.write(base64Encode(utf8.encode(jsonEncode(actual))));
}
''';

    final directory = await Directory.systemTemp.createTemp(
      'dart_eval_declaration_source_',
    );
    try {
      final scriptFile = File(
        '${directory.path}${Platform.pathSeparator}main.dart',
      );
      await scriptFile.writeAsString(script);
      final packageConfig = File(
        '${Directory.current.path}${Platform.pathSeparator}.dart_tool'
        '${Platform.pathSeparator}package_config.json',
      );
      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=${packageConfig.path}',
        scriptFile.path,
      ], workingDirectory: Directory.current.path);

      expect(
        result.exitCode,
        0,
        reason: 'Generated Dart failed to run:\n${result.stderr}\n$script',
      );
      final actual = jsonDecode(
        utf8.decode(base64Decode(result.stdout as String)),
      );
      expect(actual, equals(expected));
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('callbacks can replace inline type expressions', () {
    const renderer = BridgeDeclarationSource(
      specSource: _customSpecSource,
      typeRefSource: _customTypeRefSource,
      annotationSource: _customAnnotationSource,
    );
    const spec = BridgeTypeSpec('package:aliases/alias.dart', 'Alias');
    const type = BridgeTypeRef(spec);
    const annotation = BridgeTypeAnnotation(type, nullable: true);

    expect(renderer.typeSpec(spec), r'$spec');
    expect(renderer.typeRef(type), r'$type');
    expect(renderer.typeAnnotation(annotation), r'$nullableAnnotation');
  });

  test('resolved cache ids cannot be emitted as source', () {
    expect(
      () => bridgeTypeRefSource(const BridgeTypeRef.type(123)),
      throwsUnsupportedError,
    );
  });
}

String? _customSpecSource(BridgeTypeSpec spec) =>
    spec.library == 'package:aliases/alias.dart' ? r'$spec' : null;

String? _customTypeRefSource(BridgeTypeRef type) =>
    type.spec?.library == 'package:aliases/alias.dart' ? r'$type' : null;

String? _customAnnotationSource(BridgeTypeAnnotation annotation) =>
    annotation.nullable ? r'$nullableAnnotation' : null;
