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
  BridgeParameter param(BridgeTypeAnnotation type) {
    return BridgeParameter(this, type, false);
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
  BridgeParameter paramOptional(BridgeTypeAnnotation type) {
    return BridgeParameter(
      this,
      type,
      true,
    );
  }
}
