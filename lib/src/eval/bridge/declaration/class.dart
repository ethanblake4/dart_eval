import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/bridge/declaration/function.dart';
import 'package:dart_eval/src/eval/bridge/declaration/type.dart';
import 'package:json_annotation/json_annotation.dart';

part 'class.g.dart';

/// A bridged class definition, used to inform the dart_eval compiler of
/// a class's structure, properties, and methods when it is defined outside
/// of dart_eval.
@JsonSerializable()
class BridgeClassDef implements BridgeDeclaration {
  const BridgeClassDef(this.type,
      {required this.constructors,
      required this.methods,
      required this.getters,
      required this.setters,
      required this.fields,
      this.bridge = false,
      this.wrap = false});

  final BridgeClassType type;
  final Map<String, BridgeConstructorDef> constructors;
  final Map<String, BridgeMethodDef> methods;
  final Map<String, BridgeMethodDef> getters;
  final Map<String, BridgeMethodDef> setters;
  final Map<String, BridgeFieldDef> fields;
  final bool bridge;
  final bool wrap;

  /// Connect the generated [_$BridgeClassDeclarationFromJson] function to the `fromJson`
  /// factory.
  factory BridgeClassDef.fromJson(Map<String, dynamic> json) => _$BridgeClassDefFromJson(json);

  /// Connect the generated [_$BridgeClassDeclarationToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeClassDefToJson(this);

  BridgeClassDef copyWith({BridgeClassType? type}) => BridgeClassDef(type ?? this.type,
      constructors: constructors,
      methods: methods,
      getters: getters,
      setters: setters,
      fields: fields,
      bridge: bridge,
      wrap: wrap);
}

/// A bridged method definition, used to inform the dart_eval compiler about
/// a method's properties when it is defined outside of dart_eval.
@JsonSerializable()
class BridgeMethodDef implements BridgeDeclaration {
  const BridgeMethodDef(this.functionDescriptor, {this.isStatic = false});

  final BridgeFunctionDef functionDescriptor;
  final bool isStatic;

  /// Connect the generated [_$BridgeMethodDeclarationFromJson] function to the `fromJson`
  /// factory.
  factory BridgeMethodDef.fromJson(Map<String, dynamic> json) => _$BridgeMethodDefFromJson(json);

  /// Connect the generated [_$BridgeMethodDeclarationToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeMethodDefToJson(this);
}

/// A bridged constructor definition, used to inform the dart_eval compiler of
/// a constructor's properties when it is defined outside of dart_eval.
@JsonSerializable()
class BridgeConstructorDef implements BridgeDeclaration {
  const BridgeConstructorDef(this.functionDescriptor, {this.isFactory = false});

  final BridgeFunctionDef functionDescriptor;
  final bool isFactory;

  /// Connect the generated [_$BridgeMethodDeclarationFromJson] function to the `fromJson`
  /// factory.
  factory BridgeConstructorDef.fromJson(Map<String, dynamic> json) => _$BridgeConstructorDefFromJson(json);

  /// Connect the generated [_$BridgeMethodDeclarationToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeConstructorDefToJson(this);
}

/// A bridged field definition, used to inform the dart_eval compiler of
/// a field's properties and type when it is defined outside of dart_eval.
@JsonSerializable()
class BridgeFieldDef {
  const BridgeFieldDef(this.type, {this.isStatic = false});

  final BridgeTypeAnnotation type;
  final bool isStatic;

  /// Connect the generated [_$BridgeFieldDeclarationFromJson] function to the `fromJson`
  /// factory.
  factory BridgeFieldDef.fromJson(Map<String, dynamic> json) => _$BridgeFieldDefFromJson(json);

  /// Connect the generated [_$BridgeFieldDeclarationToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeFieldDefToJson(this);
}
