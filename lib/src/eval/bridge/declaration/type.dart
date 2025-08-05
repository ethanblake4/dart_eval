import 'package:dart_eval/src/eval/shared/types.dart';
import 'package:json_annotation/json_annotation.dart';

import 'function.dart';

part 'type.g.dart';

/// A bridged type annotation contains a type and an optional nullable flag.
@JsonSerializable(explicitToJson: true)
class BridgeTypeAnnotation {
  const BridgeTypeAnnotation(this.type, {this.nullable = false});

  final BridgeTypeRef type;
  final bool nullable;

  /// Connect the generated [_$BridgeTypeAnnotationFromJson] function to the `fromJson`
  /// factory.
  factory BridgeTypeAnnotation.fromJson(Map<String, dynamic> json) =>
      _$BridgeTypeAnnotationFromJson(json);

  /// Connect the generated [_$BridgeTypeAnnotationToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeTypeAnnotationToJson(this);
}

/// A bridged class type informs the dart_eval compiler about a class's header
/// including superclass, mixins and interfaces.
@JsonSerializable(explicitToJson: true)
class BridgeClassType {
  const BridgeClassType(
    this.type, {
    this.$extends = const BridgeTypeRef(CoreTypes.object, []),
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
  factory BridgeClassType.fromJson(Map<String, dynamic> json) =>
      _$BridgeClassTypeFromJson(json);

  /// Connect the generated [_$BridgeTypeAnnotationToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeClassTypeToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BridgeClassType &&
          runtimeType == other.runtimeType &&
          type == other.type;

  @override
  int get hashCode => type.hashCode;

  BridgeClassType copyWith({BridgeTypeRef? type}) =>
      BridgeClassType(type ?? this.type,
          isAbstract: isAbstract,
          $extends: $extends,
          $implements: $implements,
          $with: $with,
          generics: generics);
}

/// A bridge type ref is a reference to a type used by the dart_eval compiler.
class BridgeTypeRef {
  /// Reference a type by its spec (library URI and name)
  const BridgeTypeRef(this.spec, [this.typeArgs = const []])
      : cacheId = null,
        gft = null,
        ref = null,
        assert(spec != null);

  /// Reference a type by its local in-context name
  /// (e.g. a type parameter name such as T)
  const BridgeTypeRef.ref(this.ref, [this.typeArgs = const []])
      : cacheId = null,
        gft = null,
        spec = null,
        assert(ref != null);

  /// Internal use only.
  const BridgeTypeRef.type(this.cacheId, [this.typeArgs = const []])
      : ref = null,
        gft = null,
        spec = null,
        assert(cacheId != null);

  /// Reference a generic function type.
  /// Currently maps to [CoreTypes.function]
  const BridgeTypeRef.genericFunction(this.gft)
      : typeArgs = const [],
        ref = null,
        cacheId = null,
        spec = null,
        assert(gft != null);

  /// Load a type ref from its JSON representation.
  factory BridgeTypeRef.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final ta = [
      for (final arg in json['typeArgs']) BridgeTypeAnnotation.fromJson(arg)
    ];
    if (id != null) {
      return BridgeTypeRef.type(id, ta);
    }
    final gft = json['gft'];
    if (gft != null) {
      return BridgeTypeRef.genericFunction(BridgeFunctionDef.fromJson(gft));
    }
    final unresolved = json['unresolved'];
    if (unresolved != null) {
      return BridgeTypeRef(BridgeTypeSpec.fromJson(json['unresolved']), ta);
    }
    return BridgeTypeRef.ref(json['ref'], ta);
  }

  final int? cacheId;
  final String? ref;
  final BridgeFunctionDef? gft;
  final BridgeTypeSpec? spec;
  final List<BridgeTypeAnnotation> typeArgs;

  /// Convert the type ref to its JSON representation.
  Map<String, dynamic> toJson() => {
        if (cacheId != null)
          'id': cacheId!
        else if (spec != null)
          'unresolved': spec!.toJson()
        else if (gft != null)
          'gft': gft!.toJson()
        else
          'ref': ref!,
        'typeArgs': [for (final t in typeArgs) t.toJson()]
      };
}

/// A type spec is a type reference that is not yet resolved, comprised of
/// a library URI and a name.
@JsonSerializable(explicitToJson: true)
class BridgeTypeSpec {
  const BridgeTypeSpec(this.library, this.name);

  final String library;
  final String name;

  /// Connect the generated [_$BridgeUnresolvedTypeReferenceFromJson] function to the `fromJson`
  /// factory.
  factory BridgeTypeSpec.fromJson(Map<String, dynamic> json) =>
      _$BridgeTypeSpecFromJson(json);

  /// Connect the generated [_$BridgeUnresolvedTypeReferenceToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BridgeTypeSpecToJson(this);

  @override
  String toString() => '$library.$name';
}

class BridgeGenericParam {
  const BridgeGenericParam({this.$extends});

  factory BridgeGenericParam.fromJson(Map<String, dynamic> json) {
    return BridgeGenericParam(
        $extends: json.containsKey('extends')
            ? BridgeTypeRef.fromJson(json['extends'])
            : null);
  }

  final BridgeTypeRef? $extends;

  Map<String, dynamic> toJson() =>
      {if ($extends != null) 'extends': $extends!.toJson()};
}
