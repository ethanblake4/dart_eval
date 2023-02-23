part of 'extensions.dart';

extension BridgeParameterExt on String {
  /// Extension to wrap 'key' with [BridgeParameter]()
  /// ```dart
  /// //Without Extension method
  /// final keyUnwrapped = BridgeParameter('icon', BridgeTypeAnnotation($IconData.$type), false);
  /// //With Extension method, you can write
  /// final keyWrapped = 'icon'.param($IconData.$type);
  /// ```
  /// See [paramOptional] for optional named param
  /// See [paramNullable] for nullable param
  BridgeParameter param(BridgeTypeRef ref) {
    return BridgeParameter(this, BridgeTypeAnnotation(ref), false);
  }

  /// Extension to wrap 'key' with [BridgeParameter]()
  /// ```dart
  /// //Without Extension method
  /// final keyUnwrapped = BridgeParameter('icon', BridgeTypeAnnotation($IconData.$type), true);
  /// //With Extension method you can write
  /// final keyWrapped = 'icon'.paramOptional($IconData.$type);
  /// ```
  /// See [paramOptional] for optional named param
  /// See [paramOptionalNullable] for nullable param
  BridgeParameter paramOptional(BridgeTypeRef ref) {
    return BridgeParameter(
      this,
      BridgeTypeAnnotation(ref),
      true,
    );
  }

  /// See [param] docs for usage
  BridgeParameter paramNullable(BridgeTypeRef ref) {
    return BridgeParameter(
      this,
      BridgeTypeAnnotation(ref, nullable: true),
      false,
    );
  }

  /// Same as [paramOptional], See [paramOptional] docs for usage
  BridgeParameter paramOptionalNullable(BridgeTypeRef ref) {
    return BridgeParameter(
      this,
      BridgeTypeAnnotation(ref, nullable: true),
      true,
    );
  }
}
