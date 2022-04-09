// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BridgeClassDeclaration _$BridgeClassDeclarationFromJson(
        Map<String, dynamic> json) =>
    BridgeClassDeclaration(
      BridgeTypeReference.fromJson(json['type'] as Map<String, dynamic>),
      isAbstract: json['isAbstract'] as bool,
      constructors: (json['constructors'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k,
            BridgeConstructorDeclaration.fromJson(e as Map<String, dynamic>)),
      ),
      methods: (json['methods'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k, BridgeMethodDeclaration.fromJson(e as Map<String, dynamic>)),
      ),
      getters: (json['getters'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k, BridgeMethodDeclaration.fromJson(e as Map<String, dynamic>)),
      ),
      setters: (json['setters'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k, BridgeMethodDeclaration.fromJson(e as Map<String, dynamic>)),
      ),
      fields: (json['fields'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k, BridgeFieldDeclaration.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$BridgeClassDeclarationToJson(
        BridgeClassDeclaration instance) =>
    <String, dynamic>{
      'isAbstract': instance.isAbstract,
      'type': instance.type,
      'constructors': instance.constructors,
      'methods': instance.methods,
      'getters': instance.getters,
      'setters': instance.setters,
      'fields': instance.fields,
    };

BridgeMethodDeclaration _$BridgeMethodDeclarationFromJson(
        Map<String, dynamic> json) =>
    BridgeMethodDeclaration(
      json['isStatic'] as bool,
      BridgeFunctionDescriptor.fromJson(
          json['functionDescriptor'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BridgeMethodDeclarationToJson(
        BridgeMethodDeclaration instance) =>
    <String, dynamic>{
      'isStatic': instance.isStatic,
      'functionDescriptor': instance.functionDescriptor,
    };

BridgeConstructorDeclaration _$BridgeConstructorDeclarationFromJson(
        Map<String, dynamic> json) =>
    BridgeConstructorDeclaration(
      json['isFactory'] as bool,
      BridgeFunctionDescriptor.fromJson(
          json['functionDescriptor'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BridgeConstructorDeclarationToJson(
        BridgeConstructorDeclaration instance) =>
    <String, dynamic>{
      'isFactory': instance.isFactory,
      'functionDescriptor': instance.functionDescriptor,
    };

BridgeFieldDeclaration _$BridgeFieldDeclarationFromJson(
        Map<String, dynamic> json) =>
    BridgeFieldDeclaration(
      json['isStatic'] as bool,
      json['nullable'] as bool,
      BridgeTypeReference.fromJson(json['type'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BridgeFieldDeclarationToJson(
        BridgeFieldDeclaration instance) =>
    <String, dynamic>{
      'isStatic': instance.isStatic,
      'nullable': instance.nullable,
      'type': instance.type,
    };
