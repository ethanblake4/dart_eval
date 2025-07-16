part of 'extensions.dart';

extension BridgeTypeSpecExt on BridgeTypeSpec {
  /// Extension to create a type ref from a type spec
  BridgeTypeRef get ref {
    return BridgeTypeRef(this);
  }

  /// Extension to create a type ref from a spec, with type args
  BridgeTypeRef refWith(List<BridgeTypeAnnotation> typeArgs) {
    return BridgeTypeRef(this, typeArgs);
  }
}
