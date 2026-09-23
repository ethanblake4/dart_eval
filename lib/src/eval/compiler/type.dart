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

  final bool nullable;

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
      final nullability =
          typeAnnotation.question != null || unspecifiedType.nullable;
      return switch (unspecifiedType) {
        InterfaceTypeRef() => unspecifiedType.copyWith(
          arguments: resolved,
          nullable: nullability,
        ),
        _ => unspecifiedType.withNullable(nullability),
      };
    }
    // A bare type-parameter reference keeps the nullability of its bound
    // value — `T` is nullable when T resolves to `String?`.
    return unspecifiedType.withNullable(
      typeAnnotation.question != null || unspecifiedType.nullable,
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
    ).withNullable(typeAnnotation.nullable);
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
      return (typeSpec as InterfaceTypeRef).copyWith(
        arguments: arguments,
      );
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
        return (ref as InterfaceTypeRef).copyWith(
          arguments: refs.values.toList(),
        );
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

  /// A copy of this type with nullability set — implemented per variant
  /// because a nominal's copy carries different data than a record's.
  TypeRef withNullable(bool nullable);

  /// Replaces retained type-parameter references anywhere inside this
  /// type — per-variant: a parameter looks itself up, composites recurse
  /// into their parts, and nominals recurse into their arguments.
  TypeRef substituteTypeParameters(Substitution substitutions);

  /// Replaces every free type-parameter reference inside this type with its
  /// declared bound (or `dynamic` when unbounded). Callers use this when a
  /// type leaves the scope that gave those parameters meaning — an
  /// unconstrained `T` is not a usable type for the caller.
  TypeRef lowerTypeParameters(CompilerContext ctx) =>
      ctx.typeSystem.lowerTypeParameters(this);


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
    final mixinDecl = ctx.types.find(ref.file, ref.name);
    if (mixinDecl == null) continue;
    if (ctx.memberLookup.declaredAccessor(mixinDecl, name) != null) {
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

  final TypeDecl decl;

  /// Empty means a raw use — `Future` acts as `Future<dynamic>` in both
  /// directions of assignability, exactly as the legacy empty
  /// `specifiedTypeArgs` did.
  final List<TypeRef> arguments;

  /// The declaring library.
  int get file => decl.library;

  /// The declaration's simple name.
  String get name => decl.name;

  /// [arguments] through the nominal view.
  List<TypeRef> get typeArguments => arguments;

  InterfaceTypeRef copyWith({
    TypeDecl? decl,
    List<TypeRef>? arguments,
    bool? nullable,
  }) => InterfaceTypeRef(
    decl ?? this.decl,
    arguments: arguments ?? this.arguments,
    nullable: nullable ?? this.nullable,
  );

  @override
  InterfaceTypeRef withNullable(bool nullable) =>
      nullable == this.nullable ? this : copyWith(nullable: nullable);

  @override
  TypeRef substituteTypeParameters(Substitution substitutions) {
    if (arguments.isEmpty) return this;
    return copyWith(
      arguments: [
        for (final argument in arguments)
          argument.substituteTypeParameters(substitutions),
      ],
    );
  }

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
  final da = a.decl;
  final db = b.decl;
  if (da != null && db != null) {
    return _sameDecl(da, db);
  }
  // Decl-less shapes match by canonical name within the same library —
  // records by shape, extension namespaces by (library, name).
  return a.runtimeType == b.runtimeType &&
      a.file == b.file &&
      a.name == b.name;
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

  /// The owner library.
  int get file => _file ?? parameter.owner.library;

  /// The parameter's declared name.
  String get name => parameter.name;

  TypeParameterTypeRef copyWith({bool? nullable}) => TypeParameterTypeRef(
    parameter,
    nullable: nullable ?? this.nullable,
    file: _file,
  );

  @override
  TypeParameterTypeRef withNullable(bool nullable) =>
      nullable == this.nullable ? this : copyWith(nullable: nullable);

  @override
  TypeRef substituteTypeParameters(Substitution substitutions) {
    final replacement = substitutions[parameter];
    if (replacement == null) return this;
    return replacement.withNullable(nullable || replacement.nullable);
  }

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

  /// The canonical `@record` name.
  final String name;

  /// Records own no library — nominal file lookups answer -1.
  int get file => -1;

  @override
  RecordTypeRef withNullable(bool nullable) =>
      nullable == this.nullable
          ? this
          : RecordTypeRef(positional, named, nullable: nullable);

  @override
  TypeRef substituteTypeParameters(Substitution substitutions) =>
      RecordTypeRef(
        [
          for (final type in positional)
            type.substituteTypeParameters(substitutions),
        ],
        {
          for (final entry in named.entries)
            entry.key: entry.value.substituteTypeParameters(substitutions),
        },
        nullable: nullable,
      );

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

  final TypeDecl decl;

  /// The declaring library.
  int get file => decl.library;

  /// The declaration's simple name.
  String get name => decl.name;

  FunctionTypeRef copyWith({
    FunctionSignature? signature,
    TypeDecl? decl,
    bool? nullable,
  }) => FunctionTypeRef(
    signature ?? this.signature,
    decl: decl ?? this.decl,
    nullable: nullable ?? this.nullable,
  );

  @override
  FunctionTypeRef withNullable(bool nullable) =>
      nullable == this.nullable ? this : copyWith(nullable: nullable);

  @override
  TypeRef substituteTypeParameters(Substitution substitutions) {
    // The signature's own type parameters are not substituted; refs to
    // them simply miss the outer substitution map.
    final s = signature;
    return copyWith(
      signature: FunctionSignature(
        typeParameters: s.typeParameters,
        positional: [
          for (final type in s.positional)
            type.substituteTypeParameters(substitutions),
        ],
        requiredPositional: s.requiredPositional,
        named: {
          for (final entry in s.named.entries)
            entry.key: (
              type: entry.value.type.substituteTypeParameters(substitutions),
              required: entry.value.required,
            ),
        },
        returnType: s.returnType.substituteTypeParameters(substitutions),
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FunctionTypeRef &&
          nullable == other.nullable &&
          signature == other.signature;

  @override
  late final int hashCode = Object.hash(signature, nullable);
}

/// The pseudo-type of an extension's namespace value — `E` used as an
/// expression (`E.m(recv)` explicit application, `E.staticM`). Not a value
/// type: it exists only to route member resolution and equality through
/// the extension's namespace.
final class ExtensionNamespaceTypeRef extends TypeRef {
  ExtensionNamespaceTypeRef(this.library, this.extensionName, {
    super.nullable = false,
  });

  /// The library declaring the extension.
  final int library;

  /// The extension's registration name — synthesized for unnamed
  /// extensions.
  final String extensionName;

  /// The declaring library.
  int get file => library;

  /// The extension's registration name.
  String get name => extensionName;

  @override
  ExtensionNamespaceTypeRef withNullable(bool nullable) =>
      nullable == this.nullable
          ? this
          : ExtensionNamespaceTypeRef(
              library,
              extensionName,
              nullable: nullable,
            );

  @override
  TypeRef substituteTypeParameters(Substitution substitutions) => this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtensionNamespaceTypeRef &&
          nullable == other.nullable &&
          library == other.library &&
          extensionName == other.extensionName;

  @override
  late final int hashCode = Object.hash(library, extensionName, nullable);
}

/// The nominal view of a [TypeRef] — which library declared it, what it's
/// called, its declaration when it has one, and its type arguments. Every
/// variant answers these, but they are classifications over the sealed
/// set, not shared fields: a record has no library, a type parameter has
/// no declaration, and only an interface type has arguments.
extension TypeRefNominal on TypeRef {
  /// The declaring library — the declaration's library for interface and
  /// function types, the owner library for type parameters, the
  /// extension's library for its namespace, and -1 for records.
  int get file => switch (this) {
    InterfaceTypeRef ref => ref.file,
    FunctionTypeRef ref => ref.file,
    TypeParameterTypeRef ref => ref.file,
    RecordTypeRef() => -1,
    ExtensionNamespaceTypeRef ref => ref.file,
  };

  /// The simple name — the declaration's name, the parameter's name for
  /// type parameters, the canonical `@record` name for records, and the
  /// registration name for extension namespaces.
  String get name => switch (this) {
    InterfaceTypeRef ref => ref.name,
    FunctionTypeRef ref => ref.name,
    TypeParameterTypeRef ref => ref.name,
    RecordTypeRef ref => ref.name,
    ExtensionNamespaceTypeRef ref => ref.name,
  };

  /// The declaration this type names — null for type parameters, records,
  /// and extension namespaces.
  TypeDecl? get decl => switch (this) {
    InterfaceTypeRef(:final decl) || FunctionTypeRef(:final decl) => decl,
    _ => null,
  };

  /// [InterfaceTypeRef.arguments] on interface types, empty everywhere
  /// else.
  List<TypeRef> get typeArguments => switch (this) {
    InterfaceTypeRef(:final arguments) => arguments,
    _ => const [],
  };
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
  InterfaceTypeRef ref(
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
  return target.withNullable(nullable || target.nullable);
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
      return (base as InterfaceTypeRef).copyWith(
        arguments: [
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
