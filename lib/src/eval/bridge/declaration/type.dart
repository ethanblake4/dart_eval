import 'package:dart_eval/src/eval/shared/types.dart';
import 'package:json_annotation/json_annotation.dart';

import 'function.dart';

part 'type.g.dart';

@JsonSerializable()
class BridgeTypeAnnotation {
  const BridgeTypeAnnotation(this.type, {this.nullable = false});

  final BridgeTypeRef type;
  final bool nullable;

  /// Connect the generated [_$BridgeTypeAnnotationFromJson] function to the `fromJson`
  /// factory.
  factory BridgeTypeAnnotation.fromJson(Map<String, dynamic> json) => _$BridgeTypeAnnotationFromJson(json);

  /// Connect the generated [_$BridgeTypeAnnotationToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeTypeAnnotationToJson(this);
}

@JsonSerializable()
class BridgeClassType {
  const BridgeClassType(
    this.type, {
    this.$extends = const BridgeTypeRef.type(RuntimeTypes.objectType, []),
    this.$implements = const <BridgeTypeRef>[],
    this.$with = const <BridgeTypeRef>[],
    this.isAbstract = false,
    this.generics = const <String, BridgeGenericParam>{},
  });

  final BridgeTypeRef type;
  final bool isAbstract;
  final BridgeTypeRef? $extends;
  final List<BridgeTypeRef> $implements;
  final List<BridgeTypeRef> $with;
  final Map<String, BridgeGenericParam> generics;

  /// Connect the generated [_$BridgeTypeAnnotationFromJson] function to the `fromJson`
  /// factory.
  factory BridgeClassType.fromJson(Map<String, dynamic> json) => _$BridgeClassTypeFromJson(json);

  /// Connect the generated [_$BridgeTypeAnnotationToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeClassTypeToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BridgeClassType && runtimeType == other.runtimeType && type == other.type;

  @override
  int get hashCode => type.hashCode;

  BridgeClassType copyWith({BridgeTypeRef? type}) => BridgeClassType(type ?? this.type,
      isAbstract: isAbstract, $extends: $extends, $implements: $implements, $with: $with, generics: generics);
}

class BridgeTypeRef {
  const BridgeTypeRef.spec(this.spec, [this.typeArgs = const []])
      : cacheId = null,
        gft = null,
        ref = null;

  const BridgeTypeRef.ref(this.ref, [this.typeArgs = const []])
      : cacheId = null,
        gft = null,
        spec = null;

  const BridgeTypeRef.type(this.cacheId, [this.typeArgs = const []])
      : ref = null,
        gft = null,
        spec = null;

  const BridgeTypeRef.genericFunction(this.gft)
      : typeArgs = const [],
        ref = null,
        cacheId = null,
        spec = null;

  factory BridgeTypeRef.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final ta = [for (final arg in json['typeArgs']) BridgeTypeRef.fromJson(arg)];
    if (id != null) {
      return BridgeTypeRef.type(id, ta);
    }
    final gft = json['gft'];
    if (gft != null) {
      return BridgeTypeRef.genericFunction(gft);
    }
    final unresolved = json['unresolved'];
    if (unresolved != null) {
      return BridgeTypeRef.spec(BridgeTypeSpec.fromJson(json['unresolved']), ta);
    }
    return BridgeTypeRef.ref(json['ref'], ta);
  }

  final int? cacheId;
  final String? ref;
  final BridgeFunctionDef? gft;
  final BridgeTypeSpec? spec;
  final List<BridgeTypeRef> typeArgs;

  Map<String, dynamic> toJson() => {
        if (cacheId != null) 'id': cacheId! else if (spec != null) 'unresolved': spec!.toJson() else 'ref': ref!,
        'typeArgs': [for (final t in typeArgs) t.toJson()]
      };
}

@JsonSerializable()
class BridgeTypeSpec {
  const BridgeTypeSpec(this.library, this.name);

  final String library;
  final String name;

  /// Connect the generated [_$BridgeUnresolvedTypeReferenceFromJson] function to the `fromJson`
  /// factory.
  factory BridgeTypeSpec.fromJson(Map<String, dynamic> json) => _$BridgeTypeSpecFromJson(json);

  /// Connect the generated [_$BridgeUnresolvedTypeReferenceToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeTypeSpecToJson(this);
}

class BridgeGenericParam {
  const BridgeGenericParam({this.$extends});

  factory BridgeGenericParam.fromJson(Map<String, dynamic> json) {
    return BridgeGenericParam($extends: json['extends']);
  }

  final BridgeTypeRef? $extends;

  Map<String, dynamic> toJson() => {if ($extends != null) 'extends': $extends!.toJson()};
}
