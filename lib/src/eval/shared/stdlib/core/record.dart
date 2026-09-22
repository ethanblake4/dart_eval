import 'package:dart_eval/dart_eval_bridge.dart';

const $recordCls = BridgeClassDef(
  BridgeClassType(BridgeTypeRef(CoreTypes.record), isAbstract: false),
  constructors: {},
  methods: {
    '==': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
        params: [
          BridgeParameter(
            'other',
            BridgeTypeAnnotation(
              BridgeTypeRef(CoreTypes.dynamic),
              nullable: true,
            ),
            false,
          ),
        ],
      ),
    ),
    'toString': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
        params: [],
      ),
    ),
  },
  getters: {
    'hashCode': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
        params: [],
      ),
    ),
    'runtimeType': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.type)),
        params: [],
      ),
    ),
  },
  wrap: true,
);
