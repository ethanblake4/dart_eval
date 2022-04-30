import 'package:dart_eval/src/eval/bridge/declaration/type.dart';
import 'package:json_annotation/json_annotation.dart';

part 'function.g.dart';

@JsonSerializable()
class BridgeParameter {
  const BridgeParameter(this.name, this.type, this.optional);

  final String name;
  final BridgeTypeAnnotation type;
  final bool optional;

  /// Connect the generated [_$BridgeParameterFromJson] function to the `fromJson`
  /// factory.
  factory BridgeParameter.fromJson(Map<String, dynamic> json) => _$BridgeParameterFromJson(json);

  /// Connect the generated [_$BridgeParameterToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeParameterToJson(this);
}

@JsonSerializable()
class BridgeFunctionDef {
  const BridgeFunctionDef(
      {required this.returns, this.params = const [], this.namedParams = const [], this.generics = const {}});

  final BridgeTypeAnnotation returns;
  final Map<String, BridgeGenericParam> generics;
  final List<BridgeParameter> params;
  final List<BridgeParameter> namedParams;

  /// Connect the generated [_$BridgeFunctionDescriptorFromJson] function to the `fromJson`
  /// factory.
  factory BridgeFunctionDef.fromJson(Map<String, dynamic> json) => _$BridgeFunctionDefFromJson(json);

  /// Connect the generated [_$BridgeFunctionDescriptorToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeFunctionDefToJson(this);
}
