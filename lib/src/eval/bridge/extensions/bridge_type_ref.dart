part of 'extensions.dart';

extension BridgeTypeRefExt on BridgeTypeRef {
  ///Extension to wrap 'BridgeTypeRef' with [BridgeTypeAnnotation]()
  ///```dart
  /////Without Extension method
  ///final bridged_ = BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType));
  /////With Extension method, you can write
  ///final annotatedBridged = RuntimeType.int.bridged.annotate;
  ///```
  BridgeTypeAnnotation get annotate {
    return BridgeTypeAnnotation(this);
  }
}
