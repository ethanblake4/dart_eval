import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:test/test.dart';

class _NullableCollections implements EvalPlugin {
  static const library = 'package:nullable_collections/host.dart';
  final _values = <String, Object?>{
    'hostList': <Object?>[4, 5],
    'hostMap': <Object?, Object?>{'value': 5},
    'hostSet': <Object?>{4, 5},
    'nullableElements': <Object?>[null],
    'absent': null,
  };

  @override
  String get identifier => 'nullable_collections';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    final integer = BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int));
    final string = BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string));
    final list = BridgeTypeRef(CoreTypes.list, [integer]);
    for (final (name, type) in [
      ('hostList', list),
      ('hostMap', BridgeTypeRef(CoreTypes.map, [string, integer])),
      ('hostSet', BridgeTypeRef(CoreTypes.set, [integer])),
      (
        'nullableElements',
        BridgeTypeRef(CoreTypes.list, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int), nullable: true),
        ]),
      ),
      ('absent', list),
    ]) {
      registry.defineBridgeTopLevelFunction(
        BridgeFunctionDeclaration(
          library,
          name,
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(type, nullable: true),
            params: [],
            namedParams: [],
          ),
        ),
      );
    }
  }

  @override
  void configureForRuntime(Runtime runtime) {
    for (final entry in _values.entries) {
      runtime.registerBridgeFuncRegisters(library, entry.key, (
        runtime,
        r,
        s,
        c,
      ) {
        // Exported guest collections may have erased host storage. The bridge
        // return witness supplies their declared generic arguments.
        return TypedInterop.boxExternal(
          entry.value,
          runtime: runtime,
          runtimeTypeId: runtime.bridgeCallReturnTypeId!,
        );
      });
    }
  }
}

void main() {
  final program = (Compiler()..addPlugin(_NullableCollections())).compile({
    'nullable_collections': {
      'main.dart': '''
import 'host.dart';
bool main() {
  final list = hostList();
  final map = hostMap();
  final set = hostSet();
  final elements = nullableElements();
  final missing = absent();
  return list is List<int> && list is! List<String> &&
      map is Map<String, int> && map is! Map<String, String> &&
      set is Set<int> && set is! Set<String> &&
      elements is List<int?> && elements is! List<int> &&
      elements.last == null && missing == null && missing is! List<int>;
}
''',
    },
  });
  for (final (mode, runtime) in [
    ('fresh', Runtime.ofProgram(program)),
    ('encoded', Runtime(program.write().buffer)),
  ]) {
    runtime.addPlugin(_NullableCollections());
    test('$mode nullable host returns preserve present collection types', () {
      expect(
        runtime.executeLib('package:nullable_collections/main.dart', 'main'),
        isTrue,
      );
    });
  }
}
