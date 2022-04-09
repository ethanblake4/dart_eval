import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/shared/types.dart';
import 'package:json_annotation/json_annotation.dart';

import 'function.dart';

part 'type.g.dart';

@JsonSerializable()
class BridgeTypeAnnotation {
  const BridgeTypeAnnotation(this.type, this.nullable);

  final BridgeTypeReference type;
  final bool nullable;

  /// Connect the generated [_$BridgeTypeAnnotationFromJson] function to the `fromJson`
  /// factory.
  factory BridgeTypeAnnotation.fromJson(Map<String, dynamic> json) => _$BridgeTypeAnnotationFromJson(json);

  /// Connect the generated [_$BridgeTypeAnnotationToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeTypeAnnotationToJson(this);
}

class BridgeClassTypeDeclaration {
  static const int typeBridge = 0;
  static const int typeBuiltin = 1;

  const BridgeClassTypeDeclaration(this.library,
      this.name, {
        this.$extends = const BridgeTypeReference.type(RuntimeTypes.objectType, []),
        this.$implements = const <BridgeTypeReference>[],
        this.$with = const <BridgeTypeReference>[],
        this.isAbstract = false,
        this.generics = const <String, BridgeGenericParam>{},
      }) : builtin = null;

  const BridgeClassTypeDeclaration.builtin(this.builtin)
      : library = null,
        name = null,
        isAbstract = false,
        $extends = const BridgeTypeReference.type(RuntimeTypes.objectType, []),
        generics = const <String, BridgeGenericParam>{},
        $implements = const <BridgeTypeReference>[],
        $with = const <BridgeTypeReference>[];

  final bool isAbstract;
  final TypeRef? builtin;
  final String? library;
  final String? name;
  final BridgeTypeReference? $extends;
  final List<BridgeTypeReference> $implements;
  final List<BridgeTypeReference> $with;
  final Map<String, BridgeGenericParam> generics;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is BridgeClassTypeDeclaration &&
              runtimeType == other.runtimeType &&
              builtin == other.builtin &&
              library == other.library &&
              name == other.name;

  @override
  int get hashCode => builtin.hashCode ^ library.hashCode ^ name.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'type': builtin == null ? typeBridge : typeBuiltin,
      'extends': $extends?.toJson(),
      'implements': [for (final $i in $implements) $i.toJson()],
      'with': [for (final $w in $implements) $w.toJson()],
      'generics': generics.map((key, value) => MapEntry(key, value.toJson()))
    };
  }

}

class BridgeTypeReference {
  const BridgeTypeReference.unresolved(this.unresolved, this.typeArgs)
      : cacheId = null,
        gft = null,
        ref = null;

  const BridgeTypeReference.ref(this.ref, this.typeArgs)
      : cacheId = null,
        gft = null,
        unresolved = null;

  const BridgeTypeReference.type(this.cacheId, this.typeArgs)
      : ref = null,
        gft = null,
        unresolved = null;

  const BridgeTypeReference.genericFunction(this.gft)
      : typeArgs = const [],
        ref = null,
        cacheId = null,
        unresolved = null;

  factory BridgeTypeReference.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final ta = [for (final arg in json['typeArgs']) BridgeTypeReference.fromJson(arg)];
    if (id != null) {
      return BridgeTypeReference.type(id, ta);
    }
    final gft = json['gft'];
    if (gft != null) {
      return BridgeTypeReference.genericFunction(gft);
    }
    final unresolved = json['unresolved'];
    if (unresolved != null) {
      return BridgeTypeReference.unresolved(BridgeUnresolvedTypeReference.fromJson(json['unresolved']), ta);
    }
    return BridgeTypeReference.ref(json['ref'], ta);
  }

  final int? cacheId;
  final String? ref;
  final BridgeFunctionDescriptor? gft;
  final BridgeUnresolvedTypeReference? unresolved;
  final List<BridgeTypeReference> typeArgs;

  Map<String, dynamic> toJson() =>
      {
        if (cacheId != null) 'id': cacheId! else
          if (unresolved != null) 'unresolved': unresolved!.toJson() else
            'ref': ref!,
        'typeArgs': [for (final t in typeArgs) t.toJson()]
      };
}

@JsonSerializable()
class BridgeUnresolvedTypeReference {
  const BridgeUnresolvedTypeReference(this.library, this.name);

  final String library;
  final String name;

  /// Connect the generated [_$BridgeUnresolvedTypeReferenceFromJson] function to the `fromJson`
  /// factory.
  factory BridgeUnresolvedTypeReference.fromJson(Map<String, dynamic> json) =>
      _$BridgeUnresolvedTypeReferenceFromJson(json);

  /// Connect the generated [_$BridgeUnresolvedTypeReferenceToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeUnresolvedTypeReferenceToJson(this);
}

class BridgeGenericParam {
  const BridgeGenericParam({this.$extends});

  factory BridgeGenericParam.fromJson(Map<String, dynamic> json) {
    return BridgeGenericParam($extends: json['extends']);
  }

  final BridgeTypeReference? $extends;

  Map<String, dynamic> toJson() =>
      {
        if ($extends != null) 'extends': $extends!.toJson()
      };
}