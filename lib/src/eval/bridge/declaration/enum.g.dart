// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enum.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BridgeEnumDef _$BridgeEnumDefFromJson(Map<String, dynamic> json) => BridgeEnumDef(
      BridgeTypeRef.fromJson(json['type'] as Map<String, dynamic>),
      values: (json['values'] as List<dynamic>).map((e) => e as String).toList(),
      methods: (json['methods'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, BridgeMethodDef.fromJson(e as Map<String, dynamic>)),
      ),
      getters: (json['getters'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, BridgeMethodDef.fromJson(e as Map<String, dynamic>)),
      ),
      setters: (json['setters'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, BridgeMethodDef.fromJson(e as Map<String, dynamic>)),
      ),
      fields: (json['fields'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, BridgeFieldDef.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$BridgeEnumDefToJson(BridgeEnumDef instance) => <String, dynamic>{
      'type': instance.type,
      'values': instance.values,
      'methods': instance.methods,
      'getters': instance.getters,
      'setters': instance.setters,
      'fields': instance.fields,
    };
