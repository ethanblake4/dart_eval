part of 'extensions.dart';

extension BridgeTypeRefExt on BridgeTypeRef {
  /// Extension to create a type annotation from a [BridgeTypeRef]
  /// ```dart
  /// // Without extension method
  /// final bridged = BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int));
  ///
  /// // With extension method, you can write
  /// final bridged = BridgeTypeRef(CoreTypes.int).annotate;
  /// ```
  BridgeTypeAnnotation get annotate {
    return BridgeTypeAnnotation(this);
  }

  /// Extension to create a nullable type annotation from a [BridgeTypeRef]
  /// ```dart
  /// // Without extension method
  /// final bridged = BridgeTypeAnnotation(
  ///   BridgeTypeRef(CoreTypes.int),
  ///   nullable: true
  /// );
  ///
  /// // With extension method, you can write
  /// final bridged = BridgeTypeRef(CoreTypes.int).annotateNullable;
  /// ```
  BridgeTypeAnnotation get annotateNullable {
    return BridgeTypeAnnotation(this, nullable: true);
  }
}
