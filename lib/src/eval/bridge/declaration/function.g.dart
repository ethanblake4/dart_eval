// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'function.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BridgeParameter _$BridgeParameterFromJson(Map<String, dynamic> json) =>
    BridgeParameter(
      json['name'] as String,
      BridgeTypeAnnotation.fromJson(json['type'] as Map<String, dynamic>),
      json['optional'] as bool,
    );

Map<String, dynamic> _$BridgeParameterToJson(BridgeParameter instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type.toJson(),
      'optional': instance.optional,
    };

BridgeReturnTypeCase _$BridgeReturnTypeCaseFromJson(
  Map<String, dynamic> json,
) => BridgeReturnTypeCase(
  BridgeTypeRef.fromJson(json['when'] as Map<String, dynamic>),
  BridgeTypeAnnotation.fromJson(json['then'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BridgeReturnTypeCaseToJson(
  BridgeReturnTypeCase instance,
) => <String, dynamic>{
  'when': instance.when.toJson(),
  'then': instance.then.toJson(),
};

BridgeReturnTypeDependency _$BridgeReturnTypeDependencyFromJson(
  Map<String, dynamic> json,
) => BridgeReturnTypeDependency(
  paramIndex: (json['paramIndex'] as num?)?.toInt(),
  paramName: json['paramName'] as String?,
  cases: (json['cases'] as List<dynamic>)
      .map((e) => BridgeReturnTypeCase.fromJson(e as Map<String, dynamic>))
      .toList(),
  fallback: json['fallback'] == null
      ? null
      : BridgeTypeAnnotation.fromJson(json['fallback'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BridgeReturnTypeDependencyToJson(
  BridgeReturnTypeDependency instance,
) => <String, dynamic>{
  'paramIndex': instance.paramIndex,
  'paramName': instance.paramName,
  'cases': instance.cases.map((e) => e.toJson()).toList(),
  'fallback': instance.fallback?.toJson(),
};

BridgeFunctionDef _$BridgeFunctionDefFromJson(Map<String, dynamic> json) =>
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation.fromJson(
        json['returns'] as Map<String, dynamic>,
      ),
      params:
          (json['params'] as List<dynamic>?)
              ?.map((e) => BridgeParameter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      namedParams:
          (json['namedParams'] as List<dynamic>?)
              ?.map((e) => BridgeParameter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      generics:
          (json['generics'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              BridgeGenericParam.fromJson(e as Map<String, dynamic>),
            ),
          ) ??
          const {},
      returnTypeDependency: json['returnTypeDependency'] == null
          ? null
          : BridgeReturnTypeDependency.fromJson(
              json['returnTypeDependency'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$BridgeFunctionDefToJson(BridgeFunctionDef instance) =>
    <String, dynamic>{
      'returns': instance.returns.toJson(),
      'generics': instance.generics.map((k, e) => MapEntry(k, e.toJson())),
      'params': instance.params.map((e) => e.toJson()).toList(),
      'namedParams': instance.namedParams.map((e) => e.toJson()).toList(),
      'returnTypeDependency': instance.returnTypeDependency?.toJson(),
    };

BridgeFunctionDeclaration _$BridgeFunctionDeclarationFromJson(
  Map<String, dynamic> json,
) => BridgeFunctionDeclaration(
  json['library'] as String,
  json['name'] as String,
  BridgeFunctionDef.fromJson(json['function'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BridgeFunctionDeclarationToJson(
  BridgeFunctionDeclaration instance,
) => <String, dynamic>{
  'function': instance.function.toJson(),
  'library': instance.library,
  'name': instance.name,
};
