// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enum.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BridgeEnumDef _$BridgeEnumDefFromJson(Map<String, dynamic> json) =>
    BridgeEnumDef(
      BridgeTypeRef.fromJson(json['type'] as Map<String, dynamic>),
      values: (json['values'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      methods: (json['methods'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
                k, BridgeMethodDef.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
      getters: (json['getters'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
                k, BridgeMethodDef.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
      setters: (json['setters'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
                k, BridgeMethodDef.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
      fields: (json['fields'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, BridgeFieldDef.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
    );

Map<String, dynamic> _$BridgeEnumDefToJson(BridgeEnumDef instance) =>
    <String, dynamic>{
      'type': instance.type.toJson(),
      'values': instance.values,
      'methods': instance.methods.map((k, e) => MapEntry(k, e.toJson())),
      'getters': instance.getters.map((k, e) => MapEntry(k, e.toJson())),
      'setters': instance.setters.map((k, e) => MapEntry(k, e.toJson())),
      'fields': instance.fields.map((k, e) => MapEntry(k, e.toJson())),
    };
