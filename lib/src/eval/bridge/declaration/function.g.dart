// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'function.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BridgeParameter _$BridgeParameterFromJson(Map<String, dynamic> json) => BridgeParameter(
      json['name'] as String,
      BridgeTypeAnnotation.fromJson(json['typeAnnotation'] as Map<String, dynamic>),
      json['optional'] as bool,
    );

Map<String, dynamic> _$BridgeParameterToJson(BridgeParameter instance) => <String, dynamic>{
      'name': instance.name,
      'typeAnnotation': instance.typeAnnotation,
      'optional': instance.optional,
    };

BridgeFunctionDescriptor _$BridgeFunctionDescriptorFromJson(Map<String, dynamic> json) => BridgeFunctionDescriptor(
      BridgeTypeAnnotation.fromJson(json['returnType'] as Map<String, dynamic>),
      (json['generics'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, BridgeGenericParam.fromJson(e as Map<String, dynamic>)),
      ),
      (json['positionalParams'] as List<dynamic>)
          .map((e) => BridgeParameter.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['namedParams'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, BridgeParameter.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$BridgeFunctionDescriptorToJson(BridgeFunctionDescriptor instance) => <String, dynamic>{
      'returnType': instance.returnType,
      'generics': instance.generics,
      'positionalParams': instance.positionalParams,
      'namedParams': instance.namedParams,
    };
