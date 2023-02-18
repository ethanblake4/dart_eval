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
      'type': instance.type,
      'optional': instance.optional,
    };

BridgeFunctionDef _$BridgeFunctionDefFromJson(Map<String, dynamic> json) =>
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation.fromJson(
          json['returns'] as Map<String, dynamic>),
      params: (json['params'] as List<dynamic>?)
              ?.map((e) => BridgeParameter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      namedParams: (json['namedParams'] as List<dynamic>?)
              ?.map((e) => BridgeParameter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      generics: (json['generics'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
                k, BridgeGenericParam.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
    );

Map<String, dynamic> _$BridgeFunctionDefToJson(BridgeFunctionDef instance) =>
    <String, dynamic>{
      'returns': instance.returns,
      'generics': instance.generics,
      'params': instance.params,
      'namedParams': instance.namedParams,
    };

BridgeFunctionDeclaration _$BridgeFunctionDeclarationFromJson(
        Map<String, dynamic> json) =>
    BridgeFunctionDeclaration(
      json['library'] as String,
      json['name'] as String,
      BridgeFunctionDef.fromJson(json['function'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BridgeFunctionDeclarationToJson(
        BridgeFunctionDeclaration instance) =>
    <String, dynamic>{
      'function': instance.function,
      'library': instance.library,
      'name': instance.name,
    };
