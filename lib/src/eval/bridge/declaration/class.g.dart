// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BridgeClassDef _$BridgeClassDefFromJson(Map<String, dynamic> json) => BridgeClassDef(
      BridgeClassType.fromJson(json['type'] as Map<String, dynamic>),
      constructors: (json['constructors'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, BridgeConstructorDef.fromJson(e as Map<String, dynamic>)),
      ),
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

Map<String, dynamic> _$BridgeClassDefToJson(BridgeClassDef instance) => <String, dynamic>{
      'type': instance.type,
      'constructors': instance.constructors,
      'methods': instance.methods,
      'getters': instance.getters,
      'setters': instance.setters,
      'fields': instance.fields,
    };

BridgeMethodDef _$BridgeMethodDefFromJson(Map<String, dynamic> json) => BridgeMethodDef(
      BridgeFunctionDef.fromJson(json['functionDescriptor'] as Map<String, dynamic>),
      isStatic: json['isStatic'] as bool? ?? false,
    );

Map<String, dynamic> _$BridgeMethodDefToJson(BridgeMethodDef instance) => <String, dynamic>{
      'functionDescriptor': instance.functionDescriptor,
      'isStatic': instance.isStatic,
    };

BridgeConstructorDef _$BridgeConstructorDefFromJson(Map<String, dynamic> json) => BridgeConstructorDef(
      BridgeFunctionDef.fromJson(json['functionDescriptor'] as Map<String, dynamic>),
      isFactory: json['isFactory'] as bool? ?? false,
    );

Map<String, dynamic> _$BridgeConstructorDefToJson(BridgeConstructorDef instance) => <String, dynamic>{
      'functionDescriptor': instance.functionDescriptor,
      'isFactory': instance.isFactory,
    };

BridgeFieldDef _$BridgeFieldDefFromJson(Map<String, dynamic> json) => BridgeFieldDef(
      json['isStatic'] as bool,
      json['nullable'] as bool,
      BridgeTypeRef.fromJson(json['type'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BridgeFieldDefToJson(BridgeFieldDef instance) => <String, dynamic>{
      'isStatic': instance.isStatic,
      'nullable': instance.nullable,
      'type': instance.type,
    };
