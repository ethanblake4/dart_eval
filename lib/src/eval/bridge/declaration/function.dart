import 'package:dart_eval/src/eval/bridge/declaration/type.dart';
import 'package:json_annotation/json_annotation.dart';
part 'function.g.dart';

@JsonSerializable()
class BridgeParameter {
  const BridgeParameter(this.name, this.typeAnnotation, this.optional);

  final String name;
  final BridgeTypeAnnotation typeAnnotation;
  final bool optional;

  /// Connect the generated [_$BridgeParameterFromJson] function to the `fromJson`
  /// factory.
  factory BridgeParameter.fromJson(Map<String, dynamic> json) => _$BridgeParameterFromJson(json);

  /// Connect the generated [_$BridgeParameterToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeParameterToJson(this);
}

@JsonSerializable()
class BridgeFunctionDescriptor {
  const BridgeFunctionDescriptor(this.returnType, this.generics, this.positionalParams, this.namedParams);

  final BridgeTypeAnnotation returnType;
  final Map<String, BridgeGenericParam> generics;
  final List<BridgeParameter> positionalParams;
  final Map<String, BridgeParameter> namedParams;

  /// Connect the generated [_$BridgeFunctionDescriptorFromJson] function to the `fromJson`
  /// factory.
  factory BridgeFunctionDescriptor.fromJson(Map<String, dynamic> json) => _$BridgeFunctionDescriptorFromJson(json);

  /// Connect the generated [_$BridgeFunctionDescriptorToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeFunctionDescriptorToJson(this);
}
