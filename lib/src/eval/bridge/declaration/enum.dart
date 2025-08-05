import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/bridge/declaration/class.dart';
import 'package:dart_eval/src/eval/bridge/declaration/type.dart';
import 'package:json_annotation/json_annotation.dart';

part 'enum.g.dart';

@JsonSerializable(explicitToJson: true)
class BridgeEnumDef implements BridgeDeclaration {
  const BridgeEnumDef(this.type,
      {this.values = const [],
      this.methods = const {},
      this.getters = const {},
      this.setters = const {},
      this.fields = const {}});

  final BridgeTypeRef type;
  final List<String> values;
  final Map<String, BridgeMethodDef> methods;
  final Map<String, BridgeMethodDef> getters;
  final Map<String, BridgeMethodDef> setters;
  final Map<String, BridgeFieldDef> fields;

  /// Connect the generated [_$BridgeClassDeclarationFromJson] function to the `fromJson`
  /// factory.
  factory BridgeEnumDef.fromJson(Map<String, dynamic> json) =>
      _$BridgeEnumDefFromJson(json);

  /// Connect the generated [_$BridgeClassDeclarationToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeEnumDefToJson(this);

  BridgeEnumDef copyWith({BridgeTypeRef? type}) =>
      BridgeEnumDef(type ?? this.type,
          values: values,
          methods: methods,
          getters: getters,
          setters: setters,
          fields: fields);
}
