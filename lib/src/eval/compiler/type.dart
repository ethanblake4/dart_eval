import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

import 'context.dart';
import 'errors.dart';
import 'types/function_type.dart';
import 'types/substitution.dart';
import 'types/type_decl.dart';
import 'types/type_parameter.dart';

export 'types/substitution.dart';
export 'types/type_factory.dart';
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
  /// Thin forwarder onto [TypeFactory]; resolution lives there.
  factory TypeRef.fromAnnotation(
    CompilerContext ctx,
    int library,
    TypeAnnotation typeAnnotation, {
    Map<String, TypeRef> typeParameters = const {},
  }) {
    return ctx.typeFactory.fromAnnotation(
      library,
      typeAnnotation,
      typeParameters: typeParameters,
    );
  }

  /// Create a [TypeRef] from a [BridgeTypeAnnotation].
  /// Thin forwarder onto [TypeFactory]; resolution lives there.
  factory TypeRef.fromBridgeAnnotation(
    CompilerContext ctx,
    BridgeTypeAnnotation typeAnnotation, {
    TypeRef? specifyingType,
    TypeRef? specifiedType,
    Map<String, TypeRef> typeParameters = const {},
  }) {
    return ctx.typeFactory.fromBridgeAnnotation(
      typeAnnotation,
      specifyingType: specifyingType,
      specifiedType: specifiedType,
      typeParameters: typeParameters,
    );
  }

  factory TypeRef.fromBridgeTypeRef(
    CompilerContext ctx,
    BridgeTypeRef typeReference, {
    TypeRef? specifyingType,
    TypeRef? specifiedType,
    Map<String, TypeRef> typeParameters = const {},
  }) {
    return ctx.typeFactory.fromBridgeTypeRef(
      typeReference,
      specifyingType: specifyingType,
      specifiedType: specifiedType,
      typeParameters: typeParameters,
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
      final refs = classTypeParameterRefs(ctx, ref.file, ref.name, params);
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
      ctx,
      owner ?? TypeParameterOwner.scope(ctx.currentFunctionId ?? -1),
      typeParams,
      temps,
      resolveBounds ? (bound) => TypeRef.fromAnnotation(ctx, lib, bound) : null,
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
      ref = ctx.typeFactory.resolveTypeAlias(
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
  return a.runtimeType == b.runtimeType && a.file == b.file && a.name == b.name;
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
  RecordTypeRef withNullable(bool nullable) => nullable == this.nullable
      ? this
      : RecordTypeRef(positional, named, nullable: nullable);

  @override
  TypeRef substituteTypeParameters(Substitution substitutions) => RecordTypeRef(
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
  FunctionTypeRef(this.signature, {required this.decl, super.nullable = false});

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
  };

  /// The simple name — the declaration's name, the parameter's name for
  /// type parameters, the canonical `@record` name for records, and the
  /// registration name for extension namespaces.
  String get name => switch (this) {
    InterfaceTypeRef ref => ref.name,
    FunctionTypeRef ref => ref.name,
    TypeParameterTypeRef ref => ref.name,
    RecordTypeRef ref => ref.name,
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
  CompilerContext ctx,
  int file,
  String name,
  TypeParameterList? typeParameters,
) {
  final scope = <String, TypeRef>{};
  declareTypeParameters(
    ctx,
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
