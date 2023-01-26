part of 'extensions.dart';

extension BridgedRuntimeTypeExt on int {
  ///Extension to wrap 'int' of Dart's RuntimeType with [BridgeTypeRef.type]()
  ///```dart
  /////Without Extension method
  ///final bridged_ = BridgeTypeRef.type(RuntimeType.int);
  /////With Extension method, you can write
  ///final bridged = RuntimeType.int.bridged;
  ///```
  BridgeTypeRef get bridged {
    return BridgeTypeRef.type(this);
  }
}
