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

/// A single case of a [BridgeReturnTypeDependency]: when the watched argument
/// has the static type [when], the function returns [then].
@JsonSerializable(explicitToJson: true)
class BridgeReturnTypeCase {
  const BridgeReturnTypeCase(this.when, this.then);

  /// The static type of the watched argument that triggers this case.
  final BridgeTypeRef when;

  /// The return type produced when this case matches.
  final BridgeTypeAnnotation then;

  /// Connect the generated [_$BridgeReturnTypeCaseFromJson] function to the
  /// `fromJson` factory.
  factory BridgeReturnTypeCase.fromJson(Map<String, dynamic> json) =>
      _$BridgeReturnTypeCaseFromJson(json);

  /// Connect the generated [_$BridgeReturnTypeCaseToJson] function to the
  /// `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeReturnTypeCaseToJson(this);
}

/// A return type that depends on the static type of one argument. The watched
/// argument is identified by [paramIndex] (a positional parameter index) or
/// [paramName] (a named parameter name). When the argument's static type
/// matches a case's [BridgeReturnTypeCase.when], the return type is that
/// case's `then`; otherwise [fallback] applies (defaulting to the function's
/// declared `returns`).
@JsonSerializable(explicitToJson: true)
class BridgeReturnTypeDependency {
  const BridgeReturnTypeDependency({
    this.paramIndex,
    this.paramName,
    required this.cases,
    this.fallback,
  });

  /// The index of the positional parameter whose static type decides the
  /// return type.
  final int? paramIndex;

  /// The name of the named parameter whose static type decides the return
  /// type.
  final String? paramName;

  /// The case list consulted in order.
  final List<BridgeReturnTypeCase> cases;

  /// The return type when no case matches. Defaults to the function's
  /// declared `returns`.
  final BridgeTypeAnnotation? fallback;

  /// Connect the generated [_$BridgeReturnTypeDependencyFromJson] function to
  /// the `fromJson` factory.
  factory BridgeReturnTypeDependency.fromJson(Map<String, dynamic> json) =>
      _$BridgeReturnTypeDependencyFromJson(json);

  /// Connect the generated [_$BridgeReturnTypeDependencyToJson] function to
  /// the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeReturnTypeDependencyToJson(this);
}

/// A bridged function definition.
@JsonSerializable(explicitToJson: true)
class BridgeFunctionDef {
  const BridgeFunctionDef({
    required this.returns,
    this.params = const [],
    this.namedParams = const [],
    this.generics = const {},
    this.returnTypeDependency,
  });

  /// The return type of the function.
  final BridgeTypeAnnotation returns;

  /// An optional parameter-type-dependent return type. When present it
  /// refines [returns] based on the static type of one argument; [returns]
  /// remains the static signature used for tear-offs and the default when no
  /// dependency case matches.
  final BridgeReturnTypeDependency? returnTypeDependency;

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
