part of 'extensions.dart';

extension BridgeFunctionDefExt on BridgeFunctionDef {
  /// Extension to create a method from a function def
  BridgeMethodDef get asMethod {
    return BridgeMethodDef(this);
  }

  /// Extension to create a static method from a function def
  BridgeMethodDef get asStaticMethod {
    return BridgeMethodDef(this, isStatic: true);
  }

  /// Extension to create a constructor from a function def
  BridgeConstructorDef get asConstructor {
    return BridgeConstructorDef(this);
  }

  /// Extension to create a factory constructor from a function def
  BridgeConstructorDef get asFactory {
    return BridgeConstructorDef(this);
  }
}
