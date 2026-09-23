import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/model/function_type.dart';

import 'context.dart';
import 'errors.dart';
import 'types/function_type.dart';
import 'types/substitution.dart';
import 'types/type_decl.dart';
import 'types/type_parameter.dart';
import 'member/member.dart';
import 'member/member_name.dart';

export 'types/substitution.dart';
export 'types/type_decl.dart';
export 'types/type_system.dart';
export 'types/runtime_types.dart';
export 'types/type_scope.dart';
export 'types/type_parameter.dart';
export 'types/function_type.dart';

/// The action required to assign a value to a typed slot.
enum AssignmentConversion {
  /// The source type is a subtype of the destination type.
  none,

  /// Dart permits the assignment, but the value must be checked at runtime.
  runtimeCheck,

  /// Dart rejects the assignment statically.
  invalid,

  /// `int` into a `double` context — requires an `int → double` widening.
  intToDouble,
}

/// Reference to a type in the compiler — a sealed hierarchy of immutable
/// type values: [InterfaceTypeRef] (nominal `C<T...>`),
/// [TypeParameterTypeRef], [FunctionTypeRef], and [RecordTypeRef]. The
/// declaration a nominal type names owns its resolved structure
/// (supertypes, type parameters) through [CompilerContext.typeSystem].
sealed class TypeRef {
  const TypeRef({required this.nullable});

  /// The declaring library of the named type — the declaration's library
  /// for interface/function types, the owner library for type parameters,
  /// -1 for records, and the caller's for decl-less nominals.
  int get file;

  /// The simple name — the declaration's name, the parameter's name for
  /// type parameters, or the canonical `@record` name for records.
  String get name;

  /// The declaration this type names — null for type parameters, records,
  /// and decl-less nominals.
  TypeDecl? get decl;

  /// Interim bridge for type arguments: [InterfaceTypeRef.arguments] on
  /// interface types, empty everywhere else. Migrated readers take
  /// `arguments`; this accessor is removed when every use classifies.
  List<TypeRef> get typeArguments => const [];

  final bool nullable;

  /// A decl-less nominal — the extension namespace pseudo-type and other
  /// legacy encodings not yet re-homed onto a [TypeDecl]. Interim factory
  /// for the migration; removed with [_UnresolvedTypeRef].
  factory TypeRef.unresolved(int file, String name) =>
      _UnresolvedTypeRef(file, name, nullable: false);

  /// Given a set of [TypeRef]s, find their closest common ancestor type.
  factory TypeRef.commonBaseType(CompilerContext ctx, Set<TypeRef> types) =>
      ctx.typeSystem.leastUpperBound(types);

  /// Create a [TypeRef] from a [TypeAnnotation] and library ID.
  factory TypeRef.fromAnnotation(
    CompilerContext ctx,
    int library,
    TypeAnnotation typeAnnotation, {
    Map<String, TypeRef> typeParameters = const {},
  }) {
    if (typeAnnotation is GenericFunctionType) {
      return functionTypeFromAnnotation(
        ctx,
        library,
        typeAnnotation,
        typeParameters: typeParameters,
      );
    }
    if (typeAnnotation is RecordTypeAnnotation) {
      final positional = <TypeRef>[
        for (final field in typeAnnotation.positionalFields)
          TypeRef.fromAnnotation(
            ctx,
            library,
            field.type,
            typeParameters: typeParameters,
          ),
      ];
      final named = <String, TypeRef>{
        for (final field
            in typeAnnotation.namedFields?.fields ??
                <RecordTypeAnnotationNamedField>[])
          field.name.lexeme: TypeRef.fromAnnotation(
            ctx,
            library,
            field.type,
            typeParameters: typeParameters,
          ),
      };
      return RecordTypeRef(
        positional,
        named,
        nullable: typeAnnotation.question != null,
      );
    }
    typeAnnotation as NamedType;
    final prefix = typeAnnotation.importPrefix;
    final n = prefix == null
        ? typeAnnotation.name.stringValue ?? typeAnnotation.name.value()
        : '${prefix.name.lexeme}.${typeAnnotation.name.lexeme}';
    final unspecifiedType =
        typeParameters[n] ??
        ctx.typeScopes[library]?[n] ??
        ctx.visibleTypes[library]?[n];
    if (unspecifiedType == null) {
      final alias = ctx.typeAliases[library]?[n];
      if (alias != null) {
        return resolveTypeAlias(
          ctx,
          library,
          alias,
          nullable: typeAnnotation.question != null,
          typeArgs: typeAnnotation.typeArguments?.arguments,
          callerTypeParameters: typeParameters,
        );
      }
      // `FutureOr<T>` is a union type (`Future<T> | T`), which this compiler
      // cannot represent; it degrades to `dynamic` so `is`/`as` and
      // assignability checks remain permissive in both directions.
      if (n == 'FutureOr') {
        return CoreTypes.dynamic.ref(ctx);
      }
      throw CompileError(
        'Unknown type $n',
        typeAnnotation.parent,
        library,
        ctx,
      );
    }
    final typeArgs = typeAnnotation.typeArguments;
    if (typeArgs != null) {
      final resolved = <TypeRef>[];
      for (final arg in typeArgs.arguments) {
        resolved.add(
          TypeRef.fromAnnotation(
            ctx,
            library,
            arg,
            typeParameters: typeParameters,
          ),
        );
      }
      return unspecifiedType.copyWith(
        typeArguments: resolved,
        nullable: typeAnnotation.question != null || unspecifiedType.nullable,
      );
    }
    // A bare type-parameter reference keeps the nullability of its bound
    // value — `T` is nullable when T resolves to `String?`.
    return unspecifiedType.copyWith(
      nullable: typeAnnotation.question != null || unspecifiedType.nullable,
    );
  }

  /// Create a [TypeRef] from a [BridgeTypeAnnotation].
  factory TypeRef.fromBridgeAnnotation(
    CompilerContext ctx,
    BridgeTypeAnnotation typeAnnotation, {
    TypeRef? specifyingType,
    TypeRef? specifiedType,
    Map<String, TypeRef> typeParameters = const {},
  }) {
    return TypeRef.fromBridgeTypeRef(
      ctx,
      typeAnnotation.type,
      specifyingType: specifyingType,
      specifiedType: specifiedType,
      typeParameters: typeParameters,
    ).copyWith(nullable: typeAnnotation.nullable);
  }

  factory TypeRef.fromBridgeTypeRef(
    CompilerContext ctx,
    BridgeTypeRef typeReference, {
    TypeRef? specifyingType,
    TypeRef? specifiedType,
    Map<String, TypeRef> typeParameters = const {},
  }) {
    final cacheId = typeReference.cacheId;
    if (cacheId != null) {
      final t = ctx.runtimeTypes.list[cacheId];
      return ctx.bridgeTypeRefCache.putIfAbsent(cacheId, () => t);
    }
    final spec = typeReference.spec;
    if (spec != null) {
      final arguments = <TypeRef>[];
      for (final arg in typeReference.typeArgs) {
        arguments.add(
          TypeRef.fromBridgeAnnotation(
            ctx,
            arg,
            specifiedType: specifiedType,
            typeParameters: typeParameters,
          ),
        );
      }
      final lib =
          ctx.libraryMap[spec.library] ??
          (throw CompileError('Bridge: cannot find library ${spec.library}'));
      final typeSpec =
          ctx.visibleTypes[lib]![spec.name] ??
          (throw CompileError(
            'Bridge: cannot find type ${spec.name} in library ${spec.library}',
          ));
      return typeSpec.copyWith(typeArguments: arguments);
    }
    final ref = typeReference.ref;
    if (ref != null) {
      final typeParameter = typeParameters[ref];
      if (typeParameter != null) return typeParameter;
      specifiedType ??= ctx.visibleTypes[ctx.library]![ctx.currentClassName];

      if (specifiedType == null) {
        return CoreTypes.dynamic.ref(ctx);
      }

      final declaration =
          ctx.topLevelDeclarationsMap[specifiedType.file]![specifiedType.name]!;
      if (!declaration.isBridge) {
        // `ref` is declared on a bridge type, but [specifiedType] is a plain
        // class — resolve through a bridged ancestor in its chain (e.g. a
        // Dart class extending `List<T>`), else degrade to dynamic.
        return ctx.typeSystem.bridgedTypeArgument(specifiedType, ref) ??
            CoreTypes.dynamic.ref(ctx);
      }
      final dec = declaration.bridge!;
      if (dec is! BridgeClassDef) {
        throw CompileError(
          'Trying to resolve bridged generic type $ref on $specifiedType, which is not a bridge class',
        );
      }

      final genericIndex = dec.type.generics.keys.toList().indexWhere(
        (key) => key == ref,
      );
      if (genericIndex >= 0 &&
          genericIndex < specifiedType.typeArguments.length) {
        return specifiedType.typeArguments[genericIndex];
      }
      final generic = dec.type.generics[ref];
      if (generic == null) return CoreTypes.dynamic.ref(ctx);
      final $extends = generic.$extends;
      final boundType = $extends == null
          ? CoreTypes.dynamic.ref(ctx)
          : TypeRef.fromBridgeTypeRef(ctx, $extends);

      if (specifyingType != null && genericIndex >= 0) {
        final instantiatedType =
            [
              specifyingType,
              ...ctx.typeSystem.superclassChain(specifyingType),
            ].firstWhereOrNull(
              (candidate) =>
                  sameDeclaration(candidate, specifiedType!) &&
                  genericIndex < candidate.typeArguments.length,
            );
        if (instantiatedType != null) {
          final resolvedDeclaredType =
              instantiatedType.typeArguments[genericIndex];
          if (!resolvedDeclaredType.isAssignableTo(ctx, boundType)) {
            throw CompileError(
              "Type argument $resolvedDeclaredType does not conform to type parameter $ref's"
              "bound ($boundType)",
            );
          }
          return resolvedDeclaredType;
        }
      }

      return boundType;
    }
    final gft = typeReference.gft;
    if (gft != null) {
      return FunctionTypeRef(
        functionSignatureFromBridgeFunctionDef(
          ctx,
          gft,
          typeParameters: typeParameters,
        ),
        decl: ctx.types.bySpec(CoreTypes.function),
      );
    }
    throw CompileError(
      'No support for looking up types by other bridge annotation types',
    );
  }

  static TypeRef? $this(CompilerContext ctx) {
    final currentClass = ctx.currentClass;
    if (currentClass == null) {
      return null;
    }
    final ref = TypeRef.lookupDeclaration(
      ctx,
      ctx.enclosingLibrary ?? ctx.library,
      currentClass,
    );
    // Inside the class, `this` is self-instantiated: `C<T>` where `T` is the
    // class's own parameter — not the raw declaration type `C<dynamic>`.
    final decl = ref.decl;
    if (decl != null && decl.typeParameters.isNotEmpty) {
      final params = classLikeClauses(currentClass).$4;
      final refs = classTypeParameterRefs(ref.file, ref.name, params);
      if (refs.isNotEmpty) {
        return ref.copyWith(typeArguments: refs.values.toList());
      }
    }
    return ref;
  }

  factory TypeRef.lookupDeclaration(
    CompilerContext ctx,
    int library,
    Declaration dec, {
    String? prefix,
  }) {
    final name = declarationName(dec);
    return ctx
            .visibleTypes[library]!['${prefix != null ? '$prefix.' : ''}$name'] ??
        (throw CompileError('Class/enum $name not found'));
  }


  /// Whether this type names the declaration [spec] refers to. Nullability
  /// and type arguments are ignored, matching today's nominal `==`.
  bool isSpec(BridgeTypeSpec spec) => decl?.isSpec(spec) ?? false;

  /// Whether this type's declaration lives in `dart:core`.
  bool get isDartCore => decl?.isDartCore ?? false;

  /// Records have no declaration — the canonical `@record` name is the only
  /// identity.
  bool get isRecord => this is RecordTypeRef;

  /// An interface `Function` type with no resolved signature — a bare
  /// `Function` annotation or a generic callable whose signature wasn't
  /// lowered. Distinct from [isFunctionLike], which also covers
  /// [FunctionTypeRef]s.
  bool get isBareFunction =>
      this is InterfaceTypeRef && isSpec(CoreTypes.function);

  /// Anything callable-as-`Function`: a bare `Function` interface type or
  /// a structural [FunctionTypeRef].
  bool get isFunctionLike => isBareFunction || this is FunctionTypeRef;

  /// Whether every value of this type reports exactly this runtime type:
  /// leaf classes that cannot be subclassed (`int`, `double`, `bool`,
  /// `String`, `Null`) and records built entirely of them. Nullable and
  /// subclassable types can hold values whose runtime type is narrower.
  /// Used to skip record-type reification when it can never change the
  /// declared record type.
  bool hasFixedRuntimeType(CompilerContext ctx) {
    if (nullable) return false;
    final self = this;
    if (self is RecordTypeRef) {
      return self.positional.every((t) => t.hasFixedRuntimeType(ctx)) &&
          self.named.values.every((t) => t.hasFixedRuntimeType(ctx));
    }
    return isSpec(CoreTypes.int) ||
        isSpec(CoreTypes.double) ||
        isSpec(CoreTypes.bool) ||
        isSpec(CoreTypes.string) ||
        isSpec(CoreTypes.nullType);
  }


  bool get isTypeParameter => this is TypeParameterTypeRef;

  bool get isClassTypeParameter {
    final self = this;
    return self is TypeParameterTypeRef && self.parameter.owner.isClassLike;
  }

  /// Whether the runtime descriptor for this type embeds a type parameter,
  /// so its id must be resolved against the active type environment.
  bool get requiresTypeEnvironment =>
      isTypeParameter ||
      typeArguments.any((arg) => arg.requiresTypeEnvironment);


  /// Classifies Dart assignment compatibility of a [this] value into a
  /// [slot] without conflating `dynamic` with a subtype proof.
  AssignmentConversion assignmentConversionTo(
    CompilerContext ctx,
    TypeRef slot,
  ) => ctx.typeSystem.assignmentConversion(this, slot);

  /// Checks whether a value of this type can be assigned to the
  /// field of the type [slot]. This is the main check for assignments,
  /// but also useful to check for function types.
  ///
  /// When [forceAllowDynamic] is set (which is the default), immediately
  /// returns "true" if [this] or [slot] are of the dynamic type. Disable
  /// when needed to enforce type strictness.
  ///
  /// You most likely won't need to use [overrideGenerics]: it uses the
  /// type arguments by default, as it should.
  bool isAssignableTo(
    CompilerContext ctx,
    TypeRef slot, {
    List<TypeRef>? overrideGenerics,
    bool forceAllowDynamic = true,
  }) => ctx.typeSystem.isAssignable(
    this,
    slot,
    overrideGenerics: overrideGenerics,
    forceAllowDynamic: forceAllowDynamic,
  );

  TypeRef copyWith({
    TypeDecl? decl,
    List<TypeRef>? typeArguments,
    bool? nullable,
  }) {
    final self = this;
    if (self is RecordTypeRef) {
      return RecordTypeRef(
        self.positional,
        self.named,
        nullable: nullable ?? self.nullable,
      );
    }
    if (self is TypeParameterTypeRef) {
      return TypeParameterTypeRef(
        self.parameter,
        nullable: nullable ?? self.nullable,
        file: self._file,
      );
    }
    if (self is FunctionTypeRef) {
      return FunctionTypeRef(
        self.signature,
        decl: decl ?? self.decl,
        nullable: nullable ?? self.nullable,
      );
    }
    if (self is InterfaceTypeRef) {
      return InterfaceTypeRef(
        decl ?? self.decl,
        arguments: typeArguments ?? self.arguments,
        nullable: nullable ?? self.nullable,
      );
    }
    return _UnresolvedTypeRef(
      self.file,
      self.name,
      nullable: nullable ?? self.nullable,
    );
  }

  /// Replaces every free type-parameter reference inside this type with its
  /// declared bound (or `dynamic` when unbounded). Callers use this when a
  /// type leaves the scope that gave those parameters meaning — an
  /// unconstrained `T` is not a usable type for the caller.
  TypeRef lowerTypeParameters(CompilerContext ctx) =>
      ctx.typeSystem.lowerTypeParameters(this);

  /// Replaces retained type-parameter references anywhere inside this type.
  TypeRef substituteTypeParameters(Substitution substitutions) {
    final self = this;
    if (self is TypeParameterTypeRef) {
      final replacement = substitutions[self.parameter];
      if (replacement != null) {
        return replacement.copyWith(nullable: nullable || replacement.nullable);
      }
      return this;
    }
    if (typeArguments.isEmpty &&
        self is! RecordTypeRef &&
        self is! FunctionTypeRef) {
      return this;
    }

    if (self is RecordTypeRef) {
      return RecordTypeRef(
        [
          for (final type in self.positional)
            type.substituteTypeParameters(substitutions),
        ],
        {
          for (final entry in self.named.entries)
            entry.key: entry.value.substituteTypeParameters(substitutions),
        },
        nullable: self.nullable,
      );
    }
    if (self is FunctionTypeRef) {
      // The signature's own type parameters are not substituted; refs to
      // them simply miss the outer substitution map.
      final signature = self.signature;
      return FunctionTypeRef(
        FunctionSignature(
          typeParameters: signature.typeParameters,
          positional: [
            for (final type in signature.positional)
              type.substituteTypeParameters(substitutions),
          ],
          requiredPositional: signature.requiredPositional,
          named: {
            for (final entry in signature.named.entries)
              entry.key: (
                type: entry.value.type.substituteTypeParameters(substitutions),
                required: entry.value.required,
              ),
          },
          returnType: signature.returnType.substituteTypeParameters(
            substitutions,
          ),
        ),
        decl: self.decl,
        nullable: self.nullable,
      );
    }
    return copyWith(
      typeArguments: [
        for (final argument in typeArguments)
          argument.substituteTypeParameters(substitutions),
      ],
    );
  }


  @override
  String toString() {
    return name;
  }

  /// Convert to string while clarifying the source file if the name is the same
  /// as another type being printed.
  String toStringClear(CompilerContext ctx, TypeRef other) {
    if (name == other.name) {
      String? library;
      for (final entry in ctx.libraryMap.entries) {
        if (entry.value == file) {
          library = entry.key;
        }
      }
      return '$name (from "$library")';
    } else {
      return name;
    }
  }

  static void loadTemporaryTypes(
    CompilerContext ctx,
    List<TypeParameter>? typeParams, {
    int? library,
    TypeParameterOwner? owner,
    bool resolveBounds = true,
  }) {
    if (typeParams == null) return;
    final lib = library ?? ctx.library;
    final temps = ctx.typeParameterScope(lib);
    declareTypeParameters(
      owner ?? TypeParameterOwner.scope(ctx.currentFunctionId ?? -1),
      typeParams,
      temps,
      resolveBounds
          ? (bound) => TypeRef.fromAnnotation(ctx, lib, bound)
          : null,
    );
  }
}

/// The superclass, mixin, implements, and type-parameter clauses of a
/// class-like declaration — class, enum, mixin, or class type alias — in one
/// record. For a mixin the "superclass" is its `on` clause constraint, and for
/// a class type alias (`class C = S with M`) the clauses come from the alias
/// itself. Returns nulls for declarations without such clauses.
(NamedType?, List<NamedType>, List<NamedType>, TypeParameterList?)
classLikeClauses(Declaration? dec) => switch (dec) {
  ClassDeclaration(
    :final extendsClause,
    :final withClause,
    :final implementsClause,
    :final namePart,
  ) =>
    (
      extendsClause?.superclass,
      withClause?.mixinTypes.toList() ?? const <NamedType>[],
      implementsClause?.interfaces.toList() ?? const <NamedType>[],
      namePart.typeParameters,
    ),
  EnumDeclaration(
    :final withClause,
    :final implementsClause,
    :final namePart,
  ) =>
    (
      null,
      withClause?.mixinTypes.toList() ?? const <NamedType>[],
      implementsClause?.interfaces.toList() ?? const <NamedType>[],
      namePart.typeParameters,
    ),
  MixinDeclaration(
    :final onClause,
    :final implementsClause,
    :final typeParameters,
  ) =>
    (
      onClause?.superclassConstraints.firstOrNull,
      const <NamedType>[],
      implementsClause?.interfaces.toList() ?? const <NamedType>[],
      typeParameters,
    ),
  ClassTypeAlias(
    :final superclass,
    :final withClause,
    :final implementsClause,
    :final typeParameters,
  ) =>
    (
      superclass,
      withClause.mixinTypes.toList(),
      implementsClause?.interfaces.toList() ?? const <NamedType>[],
      typeParameters,
    ),
  _ => (null, const <NamedType>[], const <NamedType>[], null),
};

/// For `super` in a class declared with `with` mixins, the mixin-application
/// layer's members are folded into the applying class's declaration maps.
/// Returns the applying class's [TypeRef] — under which the folded member is
/// compiled — when [name] resolves to a member of one of those mixins
/// (checked last-to-first, matching application order). Returns null when the
/// member being compiled is itself folded in from a mixin — `super` there
/// refers to the mixin's `on` constraint — or when no mixin declares [name].
TypeRef? superMixinMemberOwner(CompilerContext ctx, String name) {
  if (ctx.memberDeclaringClass != null) return null;
  final hostDecl = ctx.currentClass;
  if (hostDecl == null) return null;
  for (final mixinType in classLikeClauses(hostDecl).$2.reversed) {
    final prefix = mixinType.importPrefix;
    final mixinName = prefix == null
        ? mixinType.name.lexeme
        : '${prefix.name.lexeme}.${mixinType.name.lexeme}';
    var ref = ctx.visibleTypes[ctx.library]![mixinName];
    final alias = ctx.typeAliases[ctx.library]?[mixinName];
    if (ref == null && alias != null) {
      ref = resolveTypeAlias(
        ctx,
        ctx.library,
        alias,
        typeArgs: mixinType.typeArguments?.arguments,
      );
    }
    if (ref == null) continue;
    final declarations = ctx.instanceDeclarationsMap[ref.file]?[ref.name];
    if (declarations == null) continue;
    if (declarations.containsKey(name) ||
        declarations.containsKey(MemberName.getter(name).key) ||
        declarations.containsKey(MemberName.setter(name).key)) {
      return TypeRef.lookupDeclaration(ctx, ctx.library, hostDecl);
    }
  }
  return null;
}

/// Normalizes a parsed constructor name: `.new` names the unnamed
/// constructor, whose internal name is the empty string.
String ctorNameOf(String? name) => name == 'new' ? '' : name ?? '';

/// Splits an instance-creation's type head into the class-name key and the
/// constructor selector. The analyzer represents `p.C()`, `p.C.n()`, and
/// `C.n()` alike as `NamedType(importPrefix: first, name: second)` plus an
/// optional trailing selector, so whether the first segment is an import
/// prefix (vs. the class itself) is decided by [ctx]'s visible declarations.
(String typeName, String ctorName) splitConstructorTypeName(
  CompilerContext ctx,
  int library,
  NamedType type,
  String? trailingSelector,
) {
  final ctorName = ctorNameOf(trailingSelector);
  final prefix = type.importPrefix;
  if (prefix != null &&
      ctx.visibleDeclarations[library]?[prefix.name.lexeme]?.children != null) {
    // `prefix.C.new`: trailing selector already folded into [ctorName].
    return ('${prefix.name.lexeme}.${type.name.lexeme}', ctorName);
  }
  if (prefix != null) {
    // `C.new` parses `C` as the prefix and `new` as the type name.
    if (type.name.lexeme == 'new') {
      return (prefix.name.lexeme, '');
    }
    return (prefix.name.lexeme, type.name.lexeme);
  }
  return (type.name.lexeme, ctorName);
}

/// A nominal type — `C<T...>` over its [TypeDecl]. `dynamic`, `void`,
/// `Never`, `Null`, `Object`, `Function`, and `Record` are interface
/// types over their `dart:core` declarations too; dedicated subclasses
/// would force a rewrite of every check for no gain.
final class InterfaceTypeRef extends TypeRef {
  InterfaceTypeRef(
    this.decl, {
    List<TypeRef> arguments = const [],
    super.nullable = false,
  }) : arguments = List.unmodifiable(arguments);

  @override
  final TypeDecl decl;

  /// Empty means a raw use — `Future` acts as `Future<dynamic>` in both
  /// directions of assignability, exactly as the legacy empty
  /// `specifiedTypeArgs` did.
  final List<TypeRef> arguments;

  @override
  int get file => decl.library;

  @override
  String get name => decl.name;

  @override
  List<TypeRef> get typeArguments => arguments;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterfaceTypeRef &&
          nullable == other.nullable &&
          _sameDecl(decl, other.decl) &&
          _listEquals(arguments, other.arguments);

  @override
  late final int hashCode = Object.hash(
    decl.library,
    decl.name,
    nullable,
    Object.hashAll(arguments),
  );
}

/// Whether two declarations name the same nominal type — the registry
/// shares instances, so identity is the fast path; library + name is the
/// ground truth.
bool _sameDecl(TypeDecl a, TypeDecl b) =>
    identical(a, b) || (a.library == b.library && a.name == b.name);

/// Whether two types name the same declaration — nominal identity only,
/// ignoring nullability and arguments. This is what the legacy `==` and
/// `hasSameDeclarationAs` meant for non-parameter types.
bool sameDeclaration(TypeRef a, TypeRef b) {
  if (a.isTypeParameter || b.isTypeParameter) {
    return a is TypeParameterTypeRef &&
        b is TypeParameterTypeRef &&
        a.parameter == b.parameter;
  }
  return (a.file == b.file || a.isRecord) && a.name == b.name;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// A type-parameter reference — `T` inside the scope that declared it.
/// The shared [TypeParameterDef] is the identity; [typeParameterBound]
/// reads the def's bound so copies stay live as bounds resolve.
final class TypeParameterTypeRef extends TypeRef {
  TypeParameterTypeRef(this.parameter, {super.nullable = false, int? file})
    : _file = file;

  /// The declared parameter — its owner and index are the identity, its
  /// bound resolves on the def after seeding.
  final TypeParameterDef parameter;

  /// An explicit library override — the owner library otherwise.
  final int? _file;

  @override
  int get file => _file ?? parameter.owner.library;

  @override
  String get name => parameter.name;

  @override
  TypeDecl? get decl => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypeParameterTypeRef &&
          nullable == other.nullable &&
          parameter == other.parameter;

  @override
  late final int hashCode = Object.hash(parameter, nullable);
}

/// A record type — `(<T...>, {name: T...})`. The canonical `@record`
/// name is derived from
/// [positional]/[named] at construction so unported readers keep working.
final class RecordTypeRef extends TypeRef {
  factory RecordTypeRef(
    List<TypeRef> positional,
    Map<String, TypeRef> named, {
    bool nullable = false,
  }) {
    final sorted = _sortedByName(named);
    return RecordTypeRef._(
      List.unmodifiable(positional),
      Map.unmodifiable(sorted),
      _canonicalName(positional, sorted),
      nullable: nullable,
    );
  }

  RecordTypeRef._(
    this.positional,
    this.named,
    this.name, {
    super.nullable = false,
  });

  /// Positional fields in declaration order.
  final List<TypeRef> positional;

  /// Named fields in canonical (name-sorted) order.
  final Map<String, TypeRef> named;

  @override
  final String name;

  @override
  int get file => -1;

  @override
  TypeDecl? get decl => null;

  /// The canonical `@record` name: positionals in order, then named
  /// fields sorted — the single identity every record producer shares.
  static String _canonicalName(
    List<TypeRef> positional,
    Map<String, TypeRef> named,
  ) {
    final name = StringBuffer('@record<');
    var first = true;
    void comma() {
      if (first) {
        first = false;
      } else {
        name.write(',');
      }
    }

    for (final field in positional) {
      comma();
      name.write('$field');
    }
    if (named.isNotEmpty) {
      comma();
      name.write('{');
      var i = 0;
      for (final entry in named.entries) {
        if (i > 0) name.write(',');
        name.write('${entry.key}:${entry.value}');
        i++;
      }
      name.write('}');
    }
    name.write('>');
    return name.toString();
  }

  static Map<String, TypeRef> _sortedByName(Map<String, TypeRef> named) {
    final entries = named.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return {for (final entry in entries) entry.key: entry.value};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordTypeRef &&
          nullable == other.nullable &&
          _listEquals(positional, other.positional) &&
          _mapEquals(named, other.named);

  @override
  late final int hashCode = Object.hash(
    name,
    nullable,
    Object.hashAll(positional),
    Object.hashAll(named.entries),
  );
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

/// A function type — `R Function<P...>(positional..., {name: T...})`.
/// The `Function` declaration stays attached so supertypes
/// (`Function <: Object`) resolve as before.
final class FunctionTypeRef extends TypeRef {
  FunctionTypeRef(
    this.signature, {
    required this.decl,
    super.nullable = false,
  });

  final FunctionSignature signature;

  @override
  final TypeDecl decl;

  @override
  int get file => decl.library;

  @override
  String get name => decl.name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FunctionTypeRef &&
          nullable == other.nullable &&
          signature == other.signature;

  @override
  late final int hashCode = Object.hash(signature, nullable);
}

/// Interim member of the sealed set: a decl-less nominal — the extension
/// namespace pseudo-type and legacy encodings still using the grab-bag
/// fields. Removed once every construction resolves a [TypeDecl].
final class _UnresolvedTypeRef extends TypeRef {
  _UnresolvedTypeRef(this.file, this.name, {super.nullable = false});

  @override
  final int file;

  @override
  final String name;

  @override
  TypeDecl? get decl => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _UnresolvedTypeRef &&
          nullable == other.nullable &&
          file == other.file &&
          name == other.name;

  @override
  late final int hashCode = Object.hash(file, name, nullable);
}

/// Computes the [ReturnType] of a bridged function descriptor, including
/// parameter-type-dependent return types carried by
/// [BridgeFunctionDef.returnTypeDependency].
ReturnType bridgeFunctionReturnType(
  CompilerContext ctx,
  BridgeFunctionDef fd, {
  TypeRef? specifiedType,
  Map<String, TypeRef> typeParameters = const {},
}) {
  AlwaysReturnType toReturnType(BridgeTypeAnnotation annotation) =>
      AlwaysReturnType(
        TypeRef.fromBridgeAnnotation(
          ctx,
          annotation,
          specifiedType: specifiedType,
          typeParameters: typeParameters,
        ),
        annotation.nullable,
      );
  final dep = fd.returnTypeDependency;
  if (dep == null) {
    return toReturnType(fd.returns);
  }
  return ParameterTypeDependentReturnType(
    {
      for (final c in dep.cases)
        (() {
          final when = TypeRef.fromBridgeTypeRef(ctx, c.when);
          return when.decl ?? when;
        })(): toReturnType(c.then),
    },
    paramIndex: dep.paramIndex,
    paramName: dep.paramName,
    fallback: toReturnType(dep.fallback ?? fd.returns),
  );
}

abstract class ReturnType {
  AlwaysReturnType? toAlwaysReturnType(
    CompilerContext ctx,
    TypeRef? targetType,
    List<TypeRef?> argTypes,
    Map<String, TypeRef?> namedArgTypes, {
    List<TypeRef> typeArgs = const [],
  });
}

class BridgedReturnType implements ReturnType {
  final BridgeTypeSpec spec;
  final bool nullable;

  BridgedReturnType(this.spec, this.nullable);

  @override
  AlwaysReturnType? toAlwaysReturnType(
    CompilerContext ctx,
    TypeRef? targetType,
    List<TypeRef?> argTypes,
    Map<String, TypeRef?> namedArgTypes, {
    List<TypeRef> typeArgs = const [],
  }) {
    final rt = TypeRef.fromBridgeTypeRef(ctx, BridgeTypeRef(spec));
    return AlwaysReturnType(rt, nullable);
  }
}

/// Resolves an instance member's declared return type with the declaring
/// class's type parameters in scope, instantiated to [receiverType]'s
/// arguments when the member is declared on the receiver's own class.
AlwaysReturnType _memberReturnAnnotation(
  CompilerContext ctx,
  TypeRef receiverType,
  ClassMember member,
  TypeRef? fallback, {
  int? declaringFile,
}) {
  final returnType = (member as MethodDeclaration).returnType;
  final host = member.parent?.parent;
  final hostName = host is Declaration ? declarationName(host) : null;
  final hostTypeParams = host is Declaration ? classLikeClauses(host).$4 : null;
  if (hostName == null) {
    return AlwaysReturnType.fromAnnotation(
      ctx,
      receiverType.file,
      returnType,
      fallback,
    );
  }
  final hostFile = declaringFile ?? receiverType.file;
  final rt = AlwaysReturnType.fromAnnotation(
    ctx,
    hostFile,
    returnType,
    fallback,
    typeParameters: classTypeParameterRefs(hostFile, hostName, hostTypeParams),
  );
  if (rt.type == null ||
      hostTypeParams == null ||
      hostTypeParams.typeParameters.isEmpty) {
    return rt;
  }
  // Instantiate the declaring class's parameters from the receiver — either
  // the receiver itself or the matching transitive supertype (`C<E>` in
  // `class B<T> with M<T>` where `M<S> implements C<S>`).
  final declaringType = hostName == receiverType.name
      ? receiverType
      : ctx.typeSystem.asInstanceOf(
          receiverType,
          ctx.types.find(hostFile, hostName),
        );
  if (declaringType == null || declaringType.typeArguments.isEmpty) {
    return rt;
  }
  final hostDecl = declaringType.decl;
  final subs = Substitution.wrap({
    for (var i = 0; i < hostTypeParams.typeParameters.length; i++)
      (hostDecl?.typeParameters[i] ??
              TypeParameterDef(
                TypeParameterOwner(
                  TypeParameterOwnerKind.classLike,
                  hostFile,
                  hostName,
                ),
                i,
                '',
              )): declaringType.typeArguments[i],
  });
  return AlwaysReturnType(rt.type!.substituteTypeParameters(subs), rt.nullable);
}

class AlwaysReturnType implements ReturnType {
  const AlwaysReturnType(this.type, this.nullable);

  factory AlwaysReturnType.fromAnnotation(
    CompilerContext ctx,
    int library,
    TypeAnnotation? typeAnnotation,
    TypeRef? fallback, {
    Map<String, TypeRef> typeParameters = const {},
  }) {
    final rt = typeAnnotation;
    if (rt != null) {
      return AlwaysReturnType(
        TypeRef.fromAnnotation(
          ctx,
          library,
          rt,
          typeParameters: typeParameters,
        ),
        rt.question != null,
      );
    } else {
      return AlwaysReturnType(fallback, true);
    }
  }

  factory AlwaysReturnType.fromInstanceMethod(
    CompilerContext ctx,
    TypeRef type,
    String method,
    TypeRef? fallback,
  ) {
    final member = ctx.memberLookup
        .interfaceMember(
          type,
          ctx.memberNameOf(method, MemberKind.method),
          superclassFirst: true,
        )
        .member;
    if (member is BridgeMember) {
      return bridgeFunctionReturnType(
        ctx,
        (member.def as BridgeMethodDef).functionDescriptor,
        specifiedType: type,
      ).toAlwaysReturnType(ctx, type, const [], const {})!;
    }
    final d = (member as SourceMember).node;
    if (d is! MethodDeclaration) {
      // A field holding a callable — its call signature isn't modelled here.
      return AlwaysReturnType(fallback ?? CoreTypes.dynamic.ref(ctx), true);
    }
    return _memberReturnAnnotation(
      ctx,
      type,
      d,
      fallback,
      declaringFile: member.library,
    );
  }

  factory AlwaysReturnType.fromStaticMethod(
    CompilerContext ctx,
    TypeRef type,
    String method,
    TypeRef? fallback,
  ) {
    final member = ctx.memberLookup.staticMember(
          type,
          method,
          MemberKind.method,
        ) ??
        (throw CompileError('Cannot find static method $type.$method'));
    if (member is BridgeMember) {
      if (member.def is! BridgeMethodDef) {
        return AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
      }
      final fn = (member.def as BridgeMethodDef).functionDescriptor;
      return bridgeFunctionReturnType(
        ctx,
        fn,
        specifiedType: type,
      ).toAlwaysReturnType(ctx, type, const [], const {})!;
    }
    final d = (member as SourceMember).node;
    if (d is ConstructorDeclaration) {
      return AlwaysReturnType(type, false);
    }
    return AlwaysReturnType.fromAnnotation(
      ctx,
      type.file,
      (d as MethodDeclaration).returnType,
      fallback,
    );
  }

  static AlwaysReturnType? fromInstanceMethodOrBuiltin(
    CompilerContext ctx,
    TypeRef type,
    String method,
    List<TypeRef?> argTypes,
    Map<String, TypeRef?> namedArgTypes, {
    List<TypeRef> typeArgs = const [],
    bool $static = false,
  }) {
    final lookupType = ctx.typeSystem.throughTypeParameters(type);
    if (lookupType.isSpec(CoreTypes.dynamic)) {
      return AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
    }

    if ($static) {
      final member = ctx.memberLookup.staticMember(
            lookupType,
            method,
            MemberKind.method,
          ) ??
          (throw CompileError('Cannot find static method $lookupType.$method'));
      if (member is BridgeMember) {
        final bridge = member.def;
        final fd = bridge is BridgeMethodDef
            ? bridge.functionDescriptor
            : bridge is BridgeConstructorDef
            ? bridge.functionDescriptor
            : null;
        if (fd == null) {
          return AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
        }
        return bridgeFunctionReturnType(ctx, fd).toAlwaysReturnType(
          ctx,
          lookupType,
          argTypes,
          namedArgTypes,
          typeArgs: typeArgs,
        );
      }
      final d = (member as SourceMember).node;
      if (d is ConstructorDeclaration) {
        return AlwaysReturnType(lookupType, false);
      }
      return AlwaysReturnType.fromAnnotation(
        ctx,
        lookupType.file,
        (d as MethodDeclaration).returnType,
        CoreTypes.dynamic.ref(ctx),
      );
    }

    if (method == 'noSuchMethod') {
      // `Object.noSuchMethod` is implicit — absent from declaration metadata.
      return AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
    }
    final member = ctx.memberLookup
        .interfaceMember(
          lookupType,
          ctx.memberNameOf(method, MemberKind.method),
          superclassFirst: true,
        )
        .member;
    if (member is BridgeMember) {
      final fd = (member.def as BridgeMethodDef).functionDescriptor;
      return bridgeFunctionReturnType(
        ctx,
        fd,
        specifiedType: lookupType,
      ).toAlwaysReturnType(
        ctx,
        lookupType,
        argTypes,
        namedArgTypes,
        typeArgs: typeArgs,
      );
    }
    final d = (member as SourceMember).node;
    if (d is! MethodDeclaration) {
      // A field holding a callable — its call signature isn't modelled here.
      return AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
    }
    return _memberReturnAnnotation(
      ctx,
      lookupType,
      d,
      CoreTypes.dynamic.ref(ctx),
      declaringFile: member.library,
    );
  }

  final TypeRef? type;
  final bool nullable;

  @override
  AlwaysReturnType? toAlwaysReturnType(
    CompilerContext ctx,
    TypeRef? targetType,
    List<TypeRef?> argTypes,
    Map<String, TypeRef?> namedArgTypes, {
    List<TypeRef> typeArgs = const [],
  }) {
    var resolved = type;
    if (resolved == null) return this;
    // Class-scoped parameter references take their bindings from the
    // receiver (e.g. `List<int>.first` resolves `E` to `int`).
    final targetSubs = targetType == null
        ? null
        : ctx.typeSystem.appliedArguments(targetType);
    if (targetSubs != null && targetSubs.isNotEmpty) {
      resolved = resolved.substituteTypeParameters(targetSubs);
    }
    // Any remaining free parameters are callee-scoped and were never bound
    // at this call site — an unconstrained `T` is meaningless to the caller,
    // so lower each to its declared bound (or `dynamic`).
    final lowered = resolved.lowerTypeParameters(ctx);
    return identical(lowered, resolved)
        ? this
        : AlwaysReturnType(lowered, nullable);
  }
}

class ParameterTypeDependentReturnType implements ReturnType {
  const ParameterTypeDependentReturnType(
    this.map, {
    this.paramIndex,
    this.paramName,
    this.fallback,
  });

  final int? paramIndex;
  final String? paramName;
  final Map<Object, AlwaysReturnType> map;
  final AlwaysReturnType? fallback;

  @override
  AlwaysReturnType? toAlwaysReturnType(
    CompilerContext ctx,
    TypeRef? targetType,
    List<TypeRef?> argTypes,
    Map<String, TypeRef?> namedArgTypes, {
    List<TypeRef> typeArgs = const [],
  }) {
    AlwaysReturnType? resolvedType;
    if (paramIndex != null && paramIndex! < argTypes.length) {
      final watched = argTypes[paramIndex!];
      resolvedType = map[watched?.decl ?? watched];
    } else if (paramName != null) {
      final watched = namedArgTypes[paramName];
      resolvedType = map[watched?.decl ?? watched];
    }

    if (resolvedType == null) {
      return fallback;
    }
    return resolvedType;
  }
}

class TargetTypeArgDependentReturnType implements ReturnType {
  const TargetTypeArgDependentReturnType(this.typeArgIndex);

  final int typeArgIndex;

  @override
  AlwaysReturnType? toAlwaysReturnType(
    CompilerContext ctx,
    TypeRef? targetType,
    List<TypeRef?> argTypes,
    Map<String, TypeRef?> namedArgTypes, {
    List<TypeRef> typeArgs = const [],
  }) {
    return AlwaysReturnType(targetType!.typeArguments[typeArgIndex], false);
  }
}

class TypeArgDependentReturnType implements ReturnType {
  const TypeArgDependentReturnType(this.typeArgIndex);

  final int typeArgIndex;

  @override
  AlwaysReturnType? toAlwaysReturnType(
    CompilerContext ctx,
    TypeRef? targetType,
    List<TypeRef?> argTypes,
    Map<String, TypeRef?> namedArgTypes, {
    List<TypeRef> typeArgs = const [],
  }) {
    return AlwaysReturnType(typeArgs[typeArgIndex], false);
  }
}

/// Maps each parameter of [typeParameters] to a resolvable [TypeRef] belonging
/// to the declaring class `file:name` — the scope in which clause types like
/// `extends C<T>` and parameter bounds are resolved.
Map<String, TypeRef> classTypeParameterRefs(
  int file,
  String name,
  TypeParameterList? typeParameters,
) {
  final scope = <String, TypeRef>{};
  declareTypeParameters(
    TypeParameterOwner(TypeParameterOwnerKind.classLike, file, name),
    typeParameters?.typeParameters ?? const <TypeParameter>[],
    scope,
  );
  return scope;
}

extension Refify on BridgeTypeSpec {
  TypeRef ref(
    CompilerContext ctx, [
    List<BridgeTypeAnnotation> typeArgs = const [],
  ]) {
    return ctx.types.bySpec(this).instantiate([
      for (final arg in typeArgs) TypeRef.fromBridgeAnnotation(ctx, arg),
    ]);
  }
}

/// Resolves a `typedef` use to the type it aliases. Function-type aliases
/// (`typedef void F()`, `typedef F = void Function()`) map to `Function`;
/// named-type aliases (`typedef X = List<int>`) resolve recursively. Type
/// parameters on the alias are bound (and substituted by any supplied type
/// arguments) while the underlying annotation resolves.
TypeRef resolveTypeAlias(
  CompilerContext ctx,
  int library,
  TypeAlias alias, {
  bool nullable = false,
  List<TypeAnnotation>? typeArgs,
  Map<String, TypeRef> callerTypeParameters = const {},
  bool rawParams = false,
}) {
  // Resolve supplied type arguments first — they are finite annotations that
  // may legally mention this same alias (`Fcov<Fcov<Never>>`). Only the
  // alias's own body resolution is guarded against recursion.
  final argRefs = typeArgs == null
      ? null
      : [
          for (final arg in typeArgs)
            TypeRef.fromAnnotation(
              ctx,
              library,
              arg,
              typeParameters: callerTypeParameters,
            ),
        ];
  if (!ctx.resolvingTypeAliases.add(alias)) {
    throw CompileError(
      'Type alias ${alias.name.lexeme} references itself recursively',
      alias,
      library,
      ctx,
    );
  }
  try {
    return _resolveTypeAlias(
      ctx,
      library,
      alias,
      nullable: nullable,
      argRefs: argRefs,
      callerTypeParameters: callerTypeParameters,
      rawParams: rawParams,
    );
  } finally {
    ctx.resolvingTypeAliases.remove(alias);
  }
}

TypeRef _resolveTypeAlias(
  CompilerContext ctx,
  int library,
  TypeAlias alias, {
  bool nullable = false,
  List<TypeRef>? argRefs,
  Map<String, TypeRef> callerTypeParameters = const {},
  bool rawParams = false,
}) {
  final typeParameters =
      switch (alias) {
        GenericTypeAlias(:final typeParameters) => typeParameters,
        FunctionTypeAlias(:final typeParameters) => typeParameters,
        ClassTypeAlias(:final typeParameters) => typeParameters,
        _ => null,
      }?.typeParameters ??
      const <TypeParameter>[];
  // Bind the alias's own type parameters inside its body. With concrete
  // arguments, substitute them. Without arguments the alias instantiates to
  // bounds (`typedef TB<T extends C> = T` referenced bare is `TB<C>`); with
  // [rawParams] the parameters stay abstract type-parameter references so a
  // caller performing downward inference can substitute them itself. The body
  // resolves against the alias's own file — it may name types private to that
  // library.
  final declLibrary = ctx.typeAliasFiles[alias] ?? library;
  final aliasOwner = TypeParameterOwner(
    TypeParameterOwnerKind.typeAlias,
    declLibrary,
    alias.name.lexeme,
  );
  final bindings = <String, TypeRef>{};
  for (var i = 0; i < typeParameters.length; i++) {
    final param = typeParameters[i];
    final arg = argRefs == null || i >= argRefs.length ? null : argRefs[i];
    final bound = param.bound;
    if (arg != null) {
      bindings[param.name.lexeme] = arg;
    } else if (rawParams) {
      bindings[param.name.lexeme] = TypeParameterTypeRef(
        TypeParameterDef(aliasOwner, i, param.name.lexeme),
        file: declLibrary,
      );
    } else if (bound == null) {
      bindings[param.name.lexeme] = CoreTypes.dynamic.ref(ctx);
    } else {
      // A recursive bound (`X extends A<X>`) sees the parameter itself.
      bindings[param.name.lexeme] = TypeParameterTypeRef(
        TypeParameterDef(aliasOwner, i, param.name.lexeme),
        file: declLibrary,
      );
      bindings[param.name.lexeme] = TypeRef.fromAnnotation(
        ctx,
        declLibrary,
        bound,
        typeParameters: bindings,
      );
    }
  }

  final TypeRef target;
  if (alias is GenericTypeAlias) {
    final functionType = alias.functionType;
    target = functionType == null
        ? TypeRef.fromAnnotation(
            ctx,
            declLibrary,
            alias.type,
            typeParameters: bindings,
          )
        : functionTypeFromAnnotation(
            ctx,
            declLibrary,
            functionType,
            typeParameters: bindings,
          );
  } else if (alias is FunctionTypeAlias) {
    // Legacy `typedef R f(P...)` syntax declares the signature inline. The
    // alias's parameters become the signature's own generics only under
    // [rawParams] (downward inference); otherwise [bindings] instantiate
    // them so the result is a plain function type.
    target = FunctionTypeRef(
      functionSignatureFromParts(
        ctx,
        declLibrary,
        returnType: alias.returnType,
        typeParameterList: rawParams ? alias.typeParameters : null,
        parameterList: alias.parameters,
        owner: TypeParameterOwner(
          TypeParameterOwnerKind.typeAlias,
          declLibrary,
          alias.name.lexeme,
        ),
        typeParameters: bindings,
      ),
      decl: ctx.types.bySpec(CoreTypes.function),
    );
  } else {
    target = CoreTypes.function.ref(ctx);
  }
  return target.copyWith(nullable: nullable || target.nullable);
}

/// Resolves a type argument in a `with`/`extends` application: a bare name
/// matching one of [classParams] resolves to that parameter's [TypeRef];
/// other named types resolve their arguments recursively (so `List<U>`
/// resolves when `U` is a parameter of the applying class). Concrete
/// arguments resolve normally. Returns null when the argument resolves to
/// none of these.
TypeRef? resolveAppliedTypeArgument(
  CompilerContext ctx,
  int libraryIndex,
  String ownerClassName,
  List<TypeParameter>? classParams,
  TypeAnnotation arg,
) {
  if (arg is NamedType) {
    if (arg.importPrefix == null) {
      final index = (classParams ?? const <TypeParameter>[]).indexWhere(
        (p) => p.name.lexeme == arg.name.lexeme,
      );
      if (index >= 0) {
        final bound = classParams![index].bound;
        final parameter = TypeParameterDef(
          TypeParameterOwner(
            TypeParameterOwnerKind.classLike,
            libraryIndex,
            ownerClassName,
          ),
          index,
          arg.name.lexeme,
        );
        parameter.bound = bound == null
            ? CoreTypes.dynamic.ref(ctx)
            : TypeRef.fromAnnotation(ctx, libraryIndex, bound);
        return TypeParameterTypeRef(parameter);
      }
    }
    final prefix = arg.importPrefix;
    final name = prefix == null
        ? arg.name.lexeme
        : '${prefix.name.lexeme}.${arg.name.lexeme}';
    final base = ctx.visibleTypes[libraryIndex]?[name];
    if (base != null) {
      final nestedArgs = arg.typeArguments?.arguments;
      if (nestedArgs == null) return base;
      return base.copyWith(
        typeArguments: [
          for (final nested in nestedArgs)
            resolveAppliedTypeArgument(
                  ctx,
                  libraryIndex,
                  ownerClassName,
                  classParams,
                  nested,
                ) ??
                CoreTypes.dynamic.ref(ctx),
        ],
      );
    }
  }
  try {
    return TypeRef.fromAnnotation(ctx, libraryIndex, arg);
  } on CompileError {
    return null;
  }
}

/// Finds an application of [mixinOwner] in [decl]'s `with` clause, including
/// through entries that are themselves mixin applications (`class C = S with
/// M`, `mixin class`). Returns the mixin's parameter names mapped to their
/// effective types under [substitutions], or null when [mixinOwner] is not
/// applied anywhere in the clause.
Map<String, TypeRef>? findMixinApplication(
  CompilerContext ctx,
  Declaration decl,
  int declFile,
  String declName,
  Declaration mixinOwner,
  int ownerLibrary,
  Substitution substitutions,
) {
  for (final mixinType in classLikeClauses(decl).$2) {
    final prefix = mixinType.importPrefix;
    final mixinName = prefix == null
        ? mixinType.name.lexeme
        : '${prefix.name.lexeme}.${mixinType.name.lexeme}';
    final ref = ctx.visibleTypes[declFile]?[mixinName];
    if (ref == null) continue;
    final mixinDecl =
        ctx.topLevelDeclarationsMap[ref.file]?[ref.name]?.declaration;
    final mixinParams =
        switch (mixinDecl) {
          MixinDeclaration m => m.typeParameters?.typeParameters,
          ClassDeclaration c => c.namePart.typeParameters?.typeParameters,
          ClassTypeAlias a => a.typeParameters?.typeParameters,
          _ => null,
        } ??
        const <TypeParameter>[];
    final appliedArgs = mixinType.typeArguments?.arguments;
    final classParams = classLikeClauses(decl).$4?.typeParameters;
    // Each parameter's effective type under the substitutions accumulated so
    // far (bounds apply when the application omits an argument).
    final applied = <String, TypeRef>{
      for (var i = 0; i < mixinParams.length; i++)
        mixinParams[i].name.lexeme:
            resolveAppliedMixinArg(
              ctx,
              declFile,
              declName,
              classParams,
              appliedArgs != null && i < appliedArgs.length
                  ? appliedArgs[i]
                  : null,
              substitutions,
            ) ??
            substitutedParamBound(ctx, declFile, mixinParams[i], substitutions),
    };
    if (identical(mixinDecl, mixinOwner)) {
      return applied;
    }
    if (mixinDecl is ClassDeclaration || mixinDecl is ClassTypeAlias) {
      final inner = findMixinApplication(
        ctx,
        mixinDecl!,
        ref.file,
        ref.name,
        mixinOwner,
        ownerLibrary,
        Substitution.of({
          ...substitutions.bindings,
          for (var i = 0; i < mixinParams.length; i++)
            (ref.decl?.typeParameters[i] ??
                    TypeParameterDef(
                      TypeParameterOwner(
                        TypeParameterOwnerKind.classLike,
                        ref.file,
                        ref.name,
                      ),
                      i,
                      '',
                    )): applied[mixinParams[i].name.lexeme]!,
        }),
      );
      if (inner != null) return inner;
    }
  }
  return null;
}

/// Resolves a type argument in a `with` clause entry: a bare name matching
/// one of the applying class's own type parameters resolves to that
/// parameter; other named types resolve with their arguments resolved
/// recursively (so `List<U>` resolves when `U` is the alias's parameter).
/// [substitutions] are applied to the result.
TypeRef? resolveAppliedMixinArg(
  CompilerContext ctx,
  int declFile,
  String declName,
  List<TypeParameter>? classParams,
  TypeAnnotation? arg,
  Substitution substitutions,
) {
  if (arg == null) return null;
  return resolveAppliedTypeArgument(
    ctx,
    declFile,
    declName,
    classParams,
    arg,
  )?.substituteTypeParameters(substitutions);
}

/// The bound of a mixin type parameter, substituted through [substitutions].
TypeRef substitutedParamBound(
  CompilerContext ctx,
  int file,
  TypeParameter param,
  Substitution substitutions,
) {
  final bound = param.bound;
  return bound == null
      ? CoreTypes.dynamic.ref(ctx)
      : TypeRef.fromAnnotation(
          ctx,
          file,
          bound,
        ).substituteTypeParameters(substitutions);
}

/// For [member] folded into [applier] from a mixin or mixin-class (possibly
/// through a chain of mixin applications), seeds [CompilerContext.typeScopes] in the
/// member's declaring library so its type parameters resolve to the applied
/// arguments, expressed in [applier]'s own type parameters.
void seedFoldedMemberTypeParams(
  CompilerContext ctx,
  Declaration applier,
  ClassMember member,
  int memberLibrary,
  int applierLibrary,
) {
  final owner = member.parent?.parent;
  if (owner is! Declaration || identical(owner, applier)) {
    return;
  }
  final applied = findMixinApplication(
    ctx,
    applier,
    applierLibrary,
    declarationName(applier),
    owner,
    memberLibrary,
    Substitution.empty,
  );
  if (applied == null) return;
  ctx.typeParameterScope(memberLibrary).addAll(applied);
}

/// Dart's "no declared type" inference widens a `Null`-typed initializer to
/// `dynamic` (`var x = null`, `var f = null`): an uninhabited declared type
/// would reject every later assignment.
TypeRef widenedInferredType(CompilerContext ctx, TypeRef type) =>
    type.isSpec(CoreTypes.nullType) ? CoreTypes.dynamic.ref(ctx) : type;
