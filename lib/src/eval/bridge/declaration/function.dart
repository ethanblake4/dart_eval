import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:json_annotation/json_annotation.dart';

part 'function.g.dart';

/// Describes a parameter of a bridged function.
@JsonSerializable(explicitToJson: true)
class BridgeParameter {
  const BridgeParameter(this.name, this.type, this.optional);

  /// The name of the parameter.
  final String name;

  /// The type of the parameter.
  final BridgeTypeAnnotation type;

  /// Whether the parameter is optional
  final bool optional;

  /// Connect the generated [_$BridgeParameterFromJson] function to the `fromJson`
  /// factory.
  factory BridgeParameter.fromJson(Map<String, dynamic> json) =>
      _$BridgeParameterFromJson(json);

  /// Connect the generated [_$BridgeParameterToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeParameterToJson(this);
}

/// A bridged function definition.
@JsonSerializable(explicitToJson: true)
class BridgeFunctionDef {
  const BridgeFunctionDef(
      {required this.returns,
      this.params = const [],
      this.namedParams = const [],
      this.generics = const {}});

  /// The return type of the function.
  final BridgeTypeAnnotation returns;

  /// The generic type parameters of the function.
  final Map<String, BridgeGenericParam> generics;

  /// The positional parameters of the function.
  final List<BridgeParameter> params;

  /// The named parameters of the function.
  final List<BridgeParameter> namedParams;

  /// Connect the generated [_$BridgeFunctionDescriptorFromJson] function to the `fromJson`
  /// factory.
  factory BridgeFunctionDef.fromJson(Map<String, dynamic> json) =>
      _$BridgeFunctionDefFromJson(json);

  /// Connect the generated [_$BridgeFunctionDescriptorToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeFunctionDefToJson(this);
}

/// Represents a bridged function declaration.
@JsonSerializable(explicitToJson: true)
class BridgeFunctionDeclaration implements BridgeDeclaration {
  const BridgeFunctionDeclaration(this.library, this.name, this.function);

  /// The function definition.
  final BridgeFunctionDef function;

  /// The library name.
  final String library;

  /// The function name.
  final String name;

  /// Connect the generated [_$BridgeFunctionDeclarationFromJson] function to the `fromJson`
  /// factory.
  factory BridgeFunctionDeclaration.fromJson(Map<String, dynamic> json) =>
      _$BridgeFunctionDeclarationFromJson(json);

  /// Connect the generated [_$BridgeFunctionDeclarationToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeFunctionDeclarationToJson(this);
}
