import 'package:analyzer/dart/ast/ast.dart';

import '../context.dart';
import '../type.dart';

/// The kind of declaration that owns a type parameter. Each kind maps to one
/// of the legacy owner-string formats so today's distinctions are preserved:
/// a method's `T` seen from its body, from a tear-off, and from a call site
/// are different owners.
enum TypeParameterOwnerKind {
  classLike,
  function,
  method,
  closure,
  tearOff,
  callSite,
  extension,
  typeAlias,
  functionTypeAnnotation,
  functionTypedParameter,
  scope,
}

/// Identifies which declaration's parameter space a [TypeParameterDef]
/// belongs to, without name-resolution or string parsing.
final class TypeParameterOwner {
  const TypeParameterOwner(this.kind, this.library, this.name, [this.position]);

  /// The default owner for parameters declared inside a function body that
  /// has no richer owner — scopes keyed by the enclosing function id.
  const TypeParameterOwner.scope(int functionId)
    : kind = TypeParameterOwnerKind.scope,
      library = -1,
      name = '',
      position = functionId;

  final TypeParameterOwnerKind kind;

  /// The declaring library's file index.
  final int library;

  /// The owner name in its kind's format (`'C'` for classes,
  /// `'C.m'` for methods, `'<anonymous>'`-style for closures).
  final String name;

  /// The owner's source position when the kind disambiguates by it
  /// (functions, methods, closures, function-type annotations).
  final int? position;

  /// Class, enum, mixin, or class-alias owned parameters.
  bool get isClassLike => kind == TypeParameterOwnerKind.classLike;

  /// The legacy owner-string form. Produces the same keys the scattered
  /// `'$kind:$field'` formats produced, so [TypeRef] consumers that still
  /// compare owner strings keep working during the migration.
  String get key => switch (kind) {
    TypeParameterOwnerKind.classLike => 'class:$library:$name',
    TypeParameterOwnerKind.function => 'function:$library:$name:$position',
    TypeParameterOwnerKind.method => 'method:$library:$name:$position',
    TypeParameterOwnerKind.closure => 'function:$library:<anonymous>:$position',
    TypeParameterOwnerKind.scope => 'function:$position',
    TypeParameterOwnerKind.callSite => 'call:$library:$name:$position',
    TypeParameterOwnerKind.tearOff => 'tearoff:$library:$name',
    TypeParameterOwnerKind.extension => 'extension:$library:$name',
    TypeParameterOwnerKind.typeAlias => 'typeAlias:$library:$name',
    TypeParameterOwnerKind.functionTypeAnnotation =>
      'functionType:$library:$position',
    TypeParameterOwnerKind.functionTypedParameter =>
      'functionTypedParam:$library:$position',
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypeParameterOwner &&
          kind == other.kind &&
          library == other.library &&
          name == other.name &&
          position == other.position;

  @override
  int get hashCode => Object.hash(kind, library, name, position);
}

/// One declared type parameter: its owner, its position in the owner's
/// parameter list, and (set once every parameter of the owner exists) its
/// bound. Equality is over `(owner, index)` only — never the bound — so
/// F-bounded parameters cannot create equality cycles.
final class TypeParameterDef {
  TypeParameterDef(this.owner, this.index, this.name);

  final TypeParameterOwner owner;
  final int index;
  final String name;

  TypeRef? _bound;
  bool _boundSet = false;

  /// The parameter's declared bound; null means unbounded, as before.
  TypeRef? get bound => _bound;

  /// Whether a bound was ever recorded — interned defs resolve theirs on
  /// the first bound-carrying declaration pass.
  bool get boundSet => _boundSet;

  set bound(TypeRef? value) {
    assert(!_boundSet, 'bound of $name already set');
    _bound = value;
    _boundSet = true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypeParameterDef && owner == other.owner && index == other.index;

  @override
  int get hashCode => Object.hash(owner, index);
}

/// Interned [TypeParameterDef]s, one list per [TypeParameterOwner] — an
/// owner's parameters exist in exactly one place, so a bound resolved on
/// the shared def is visible through every reference and every
/// substitution key, not just the copy that happened to carry it.
final class TypeParameterDefs {
  final _owners = <TypeParameterOwner, List<TypeParameterDef>>{};

  /// Registers [defs] as [owner]'s parameters — the first declaration
  /// wins; later calls return the interned defs unchanged. For
  /// declarations without AST parameter nodes (bridge generics).
  List<TypeParameterDef> intern(
    TypeParameterOwner owner,
    List<TypeParameterDef> defs,
  ) => _owners.putIfAbsent(owner, () => defs);

  /// Declares [owner]'s parameters from [nodes] — the first declaration
  /// wins; later calls return the interned defs unchanged.
  List<TypeParameterDef> declare(
    TypeParameterOwner owner,
    List<TypeParameter> nodes,
  ) => _owners.putIfAbsent(
    owner,
    () => [
      for (var i = 0; i < nodes.length; i++)
        TypeParameterDef(owner, i, nodes[i].name.lexeme),
    ],
  );

  /// The interned def for (`owner`, `index`) — the shared def when the
  /// owner was declared, or a fresh unbound key for substitution maps
  /// whose nominal's declaration has not resolved (or never will).
  TypeParameterDef key(TypeParameterOwner owner, int index, String name) {
    final defs = _owners[owner];
    if (defs != null && index < defs.length) return defs[index];
    return TypeParameterDef(owner, index, name);
  }
}

/// Declares [nodes] as [owner]'s type parameters: interns every
/// [TypeParameterDef] on [ctx], extends [scope] with a
/// [TypeParameterTypeRef] for each, then resolves bounds through
/// [resolveBound]. Because defs are shared objects, a bound naming a later
/// parameter sees that parameter's bound once set — the legacy
/// re-resolution pass is unnecessary.
///
/// Returns the defs in declaration order. A null [resolveBound] leaves the
/// scope seeded but bounds null (the extension `on` pattern intentionally
/// leaves parameters unbound). Re-declaring an already-bound owner only
/// re-seeds the scope — bounds stay with the first resolution.
List<TypeParameterDef> declareTypeParameters(
  CompilerContext ctx,
  TypeParameterOwner owner,
  List<TypeParameter> nodes,
  Map<String, TypeRef> scope, [
  TypeRef Function(TypeAnnotation bound)? resolveBound,
]) {
  final defs = ctx.typeParameterDefs.declare(owner, nodes);
  for (final def in defs) {
    scope[def.name] = TypeParameterTypeRef(def);
  }
  if (resolveBound == null) return defs;
  for (var i = 0; i < nodes.length && i < defs.length; i++) {
    final bound = nodes[i].bound;
    if (bound != null && !defs[i].boundSet) {
      defs[i].bound = resolveBound(bound);
    }
  }
  return defs;
}
