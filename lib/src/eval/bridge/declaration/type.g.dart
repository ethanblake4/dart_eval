// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BridgeTypeAnnotation _$BridgeTypeAnnotationFromJson(Map<String, dynamic> json) => BridgeTypeAnnotation(
      BridgeTypeReference.fromJson(json['type'] as Map<String, dynamic>),
      json['nullable'] as bool,
    );

Map<String, dynamic> _$BridgeTypeAnnotationToJson(BridgeTypeAnnotation instance) => <String, dynamic>{
      'type': instance.type,
      'nullable': instance.nullable,
    };

BridgeUnresolvedTypeReference _$BridgeUnresolvedTypeReferenceFromJson(Map<String, dynamic> json) =>
    BridgeUnresolvedTypeReference(
      json['library'] as String,
      json['name'] as String,
    );

Map<String, dynamic> _$BridgeUnresolvedTypeReferenceToJson(BridgeUnresolvedTypeReference instance) => <String, dynamic>{
      'library': instance.library,
      'name': instance.name,
    };
