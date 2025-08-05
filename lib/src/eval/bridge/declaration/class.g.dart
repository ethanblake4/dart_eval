// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BridgeClassDef _$BridgeClassDefFromJson(Map<String, dynamic> json) =>
    BridgeClassDef(
      BridgeClassType.fromJson(json['type'] as Map<String, dynamic>),
      constructors: (json['constructors'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k, BridgeConstructorDef.fromJson(e as Map<String, dynamic>)),
      ),
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
      bridge: json['bridge'] as bool? ?? false,
      wrap: json['wrap'] as bool? ?? false,
    );

Map<String, dynamic> _$BridgeClassDefToJson(BridgeClassDef instance) =>
    <String, dynamic>{
      'type': instance.type.toJson(),
      'constructors':
          instance.constructors.map((k, e) => MapEntry(k, e.toJson())),
      'methods': instance.methods.map((k, e) => MapEntry(k, e.toJson())),
      'getters': instance.getters.map((k, e) => MapEntry(k, e.toJson())),
      'setters': instance.setters.map((k, e) => MapEntry(k, e.toJson())),
      'fields': instance.fields.map((k, e) => MapEntry(k, e.toJson())),
      'bridge': instance.bridge,
      'wrap': instance.wrap,
    };

BridgeMethodDef _$BridgeMethodDefFromJson(Map<String, dynamic> json) =>
    BridgeMethodDef(
      BridgeFunctionDef.fromJson(
          json['functionDescriptor'] as Map<String, dynamic>),
      isStatic: json['isStatic'] as bool? ?? false,
    );

Map<String, dynamic> _$BridgeMethodDefToJson(BridgeMethodDef instance) =>
    <String, dynamic>{
      'functionDescriptor': instance.functionDescriptor.toJson(),
      'isStatic': instance.isStatic,
    };

BridgeConstructorDef _$BridgeConstructorDefFromJson(
        Map<String, dynamic> json) =>
    BridgeConstructorDef(
      BridgeFunctionDef.fromJson(
          json['functionDescriptor'] as Map<String, dynamic>),
      isFactory: json['isFactory'] as bool? ?? false,
    );

Map<String, dynamic> _$BridgeConstructorDefToJson(
        BridgeConstructorDef instance) =>
    <String, dynamic>{
      'functionDescriptor': instance.functionDescriptor.toJson(),
      'isFactory': instance.isFactory,
    };

BridgeFieldDef _$BridgeFieldDefFromJson(Map<String, dynamic> json) =>
    BridgeFieldDef(
      BridgeTypeAnnotation.fromJson(json['type'] as Map<String, dynamic>),
      isStatic: json['isStatic'] as bool? ?? false,
    );

Map<String, dynamic> _$BridgeFieldDefToJson(BridgeFieldDef instance) =>
    <String, dynamic>{
      'type': instance.type.toJson(),
      'isStatic': instance.isStatic,
    };
