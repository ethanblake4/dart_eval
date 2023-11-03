// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BridgeTypeAnnotation _$BridgeTypeAnnotationFromJson(
        Map<String, dynamic> json) =>
    BridgeTypeAnnotation(
      BridgeTypeRef.fromJson(json['type'] as Map<String, dynamic>),
      nullable: json['nullable'] as bool? ?? false,
    );

Map<String, dynamic> _$BridgeTypeAnnotationToJson(
        BridgeTypeAnnotation instance) =>
    <String, dynamic>{
      'type': instance.type,
      'nullable': instance.nullable,
    };

BridgeClassType _$BridgeClassTypeFromJson(Map<String, dynamic> json) =>
    BridgeClassType(
      BridgeTypeRef.fromJson(json['type'] as Map<String, dynamic>),
      $extends: json[r'$extends'] == null
          ? const BridgeTypeRef(CoreTypes.object, [])
          : BridgeTypeRef.fromJson(json[r'$extends'] as Map<String, dynamic>),
      $implements: (json[r'$implements'] as List<dynamic>?)
              ?.map((e) => BridgeTypeRef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <BridgeTypeRef>[],
      $with: (json[r'$with'] as List<dynamic>?)
              ?.map((e) => BridgeTypeRef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <BridgeTypeRef>[],
      isAbstract: json['isAbstract'] as bool? ?? false,
      generics: (json['generics'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
                k, BridgeGenericParam.fromJson(e as Map<String, dynamic>)),
          ) ??
          const <String, BridgeGenericParam>{},
    );

Map<String, dynamic> _$BridgeClassTypeToJson(BridgeClassType instance) =>
    <String, dynamic>{
      'type': instance.type,
      'isAbstract': instance.isAbstract,
      r'$extends': instance.$extends,
      r'$implements': instance.$implements,
      r'$with': instance.$with,
      'generics': instance.generics,
    };

BridgeTypeSpec _$BridgeTypeSpecFromJson(Map<String, dynamic> json) =>
    BridgeTypeSpec(
      json['library'] as String,
      json['name'] as String,
    );

Map<String, dynamic> _$BridgeTypeSpecToJson(BridgeTypeSpec instance) =>
    <String, dynamic>{
      'library': instance.library,
      'name': instance.name,
    };
