import 'package:dart_eval/dart_eval_bridge.dart';

const $enumDeclaration = BridgeClassDef(
  BridgeClassType(
    BridgeTypeRef(CoreTypes.enumType),
    $extends: BridgeTypeRef(CoreTypes.object),
    isAbstract: true,
  ),
  constructors: {},
  methods: {},
  getters: {
    'index': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
      ),
    ),
    'name': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
      ),
    ),
  },
  wrap: true,
);
