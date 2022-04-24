import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/bridge/declaration/function.dart';
import 'package:dart_eval/src/eval/bridge/declaration/type.dart';
import 'package:json_annotation/json_annotation.dart';

part 'class.g.dart';

@JsonSerializable()
class BridgeClassDeclaration implements BridgeDeclaration {
  const BridgeClassDeclaration(this.type,
      {required this.isAbstract,
      required this.constructors,
      required this.methods,
      required this.getters,
      required this.setters,
      required this.fields});

  final bool isAbstract;
  final BridgeTypeReference type;
  final Map<String, BridgeConstructorDeclaration> constructors;
  final Map<String, BridgeMethodDeclaration> methods;
  final Map<String, BridgeMethodDeclaration> getters;
  final Map<String, BridgeMethodDeclaration> setters;
  final Map<String, BridgeFieldDeclaration> fields;

  /// Connect the generated [_$BridgeClassDeclarationFromJson] function to the `fromJson`
  /// factory.
  factory BridgeClassDeclaration.fromJson(Map<String, dynamic> json) => _$BridgeClassDeclarationFromJson(json);

  /// Connect the generated [_$BridgeClassDeclarationToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeClassDeclarationToJson(this);

  BridgeClassDeclaration copyWith({BridgeTypeReference? type}) => BridgeClassDeclaration(type ?? this.type,
      isAbstract: isAbstract,
      constructors: constructors,
      methods: methods,
      getters: getters,
      setters: setters,
      fields: fields);
}

@JsonSerializable()
class BridgeMethodDeclaration implements BridgeDeclaration {
  const BridgeMethodDeclaration(this.isStatic, this.functionDescriptor);

  final bool isStatic;
  final BridgeFunctionDescriptor functionDescriptor;

  /// Connect the generated [_$BridgeMethodDeclarationFromJson] function to the `fromJson`
  /// factory.
  factory BridgeMethodDeclaration.fromJson(Map<String, dynamic> json) => _$BridgeMethodDeclarationFromJson(json);

  /// Connect the generated [_$BridgeMethodDeclarationToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeMethodDeclarationToJson(this);
}

@JsonSerializable()
class BridgeConstructorDeclaration implements BridgeDeclaration {
  const BridgeConstructorDeclaration(this.isFactory, this.functionDescriptor);

  final bool isFactory;
  final BridgeFunctionDescriptor functionDescriptor;

  /// Connect the generated [_$BridgeMethodDeclarationFromJson] function to the `fromJson`
  /// factory.
  factory BridgeConstructorDeclaration.fromJson(Map<String, dynamic> json) =>
      _$BridgeConstructorDeclarationFromJson(json);

  /// Connect the generated [_$BridgeMethodDeclarationToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeConstructorDeclarationToJson(this);
}

@JsonSerializable()
class BridgeFieldDeclaration {
  const BridgeFieldDeclaration(this.isStatic, this.nullable, this.type);

  final bool isStatic;
  final bool nullable;
  final BridgeTypeReference type;

  /// Connect the generated [_$BridgeFieldDeclarationFromJson] function to the `fromJson`
  /// factory.
  factory BridgeFieldDeclaration.fromJson(Map<String, dynamic> json) => _$BridgeFieldDeclarationFromJson(json);

  /// Connect the generated [_$BridgeFieldDeclarationToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeFieldDeclarationToJson(this);
}
