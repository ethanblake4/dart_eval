import 'dart:math' as math;

import 'package:dart_eval/dart_eval_bridge.dart' show AsyncTypes, CoreTypes;

import '../context.dart';
import '../type.dart';

/// The compiler's type-algebra service. Supertypes live on [TypeDecl], so
/// every algorithm that walks a hierarchy — instantiation views, unification,
/// assignability, least upper bound, runtime supertype ids — funnels through
/// here instead of composing substitutions by hand.
final class TypeSystem {
  TypeSystem(this._ctx);

  final CompilerContext _ctx;

  // Recursive bounds may revisit the same subtype question without making
  // progress. Keep this only for active type-parameter expansions.
  final _activeParameterRelations = <(TypeRef, TypeRef, bool, bool)>{};

  /// Maps [type]'s declared parameters to the applied arguments — the
  /// substitution that resolves member and supertype annotations written in
  /// the declaration's own parameter space. Refs constructed without
  /// parameter declarations still map positional arguments into the class's
  /// parameter namespace.
  Substitution appliedArguments(TypeRef type) =>
      Substitution.forInterface(type);

  /// The `extends` superclass of [type], instantiated through [type]'s
  /// arguments — null for type parameters, non-class refs, and `Object`.
  TypeRef? superclassOf(TypeRef type) {
    if (type.isTypeParameter) return null;
    if (type.isRecord) return CoreTypes.record.ref(_ctx);
    final decl = nominalDeclOf(type) ?? _ctx.types.find(type.file, type.name);
    if (decl == null) return null;
    final superclass = decl.supertypes.superclass;
    if (superclass == null) return null;
    final substitutions = appliedArguments(type);
    return substitutions.isEmpty
        ? superclass
        : superclass.substituteTypeParameters(substitutions);
  }

  /// The `implements` interfaces of [type], instantiated.
  List<TypeRef> interfacesOf(TypeRef type) {
    final decl = nominalDeclOf(type) ?? _ctx.types.find(type.file, type.name);
    if (decl == null || type.isTypeParameter || type.isRecord) {
      return const [];
    }
    final substitutions = appliedArguments(type);
    return [
      for (final i in decl.supertypes.interfaces)
        substitutions.isEmpty ? i : i.substituteTypeParameters(substitutions),
    ];
  }

  /// The `with` mixins of [type], instantiated.
  List<TypeRef> mixinsOf(TypeRef type) {
    final decl = nominalDeclOf(type) ?? _ctx.types.find(type.file, type.name);
    if (decl == null || type.isTypeParameter || type.isRecord) {
      return const [];
    }
    final substitutions = appliedArguments(type);
    return [
      for (final m in decl.supertypes.mixins)
        substitutions.isEmpty ? m : m.substituteTypeParameters(substitutions),
    ];
  }

  /// Every direct supertype of [type] in the historical order — superclass,
  /// interfaces, mixins — instantiated through [type]'s arguments. Records
  /// have a single nominal supertype, `Record`; type parameters report none
  /// (use [throughTypeParameters] for the bound view).
  List<TypeRef> directSupertypes(TypeRef type) => [
    if (type.isTypeParameter)
      ...const <TypeRef>[]
    else if (type.isRecord)
      CoreTypes.record.ref(_ctx)
    else ...[
      ?superclassOf(type),
      ...interfacesOf(type),
      ...mixinsOf(type),
    ],
  ];

  /// The transitive `extends` chain of [type], instantiated — replaces the
  /// old extendsChain getter.
  Iterable<TypeRef> superclassChain(TypeRef type) sync* {
    var current = superclassOf(type);
    while (current != null) {
      yield current;
      current = superclassOf(current);
    }
  }

  /// [type] viewed as an instance of [target], with arguments substituted
  /// along the path. Type parameters go through their bound, records through
  /// `Record`, function types through `Function`. Replaces
  /// `findSupertypeInstantiation`, `instantiatedSupertypeView`, and
  /// `inheritTypeArgsFrom`.
  TypeRef? asInstanceOf(TypeRef type, TypeDecl? target) {
    if (target == null) return null;
    var current0 = type;
    if (current0.isTypeParameter) {
      current0 =
          (current0 as TypeParameterTypeRef).effectiveBound ??
          CoreTypes.dynamic.ref(_ctx);
    }
    if (current0.isRecord) {
      current0 = CoreTypes.record.ref(_ctx);
    }
    if (current0 is FunctionTypeRef) {
      current0 = CoreTypes.function.ref(_ctx);
    }
    final queue = <TypeRef>[current0];
    final seen = <TypeRef>{};
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (!seen.add(current)) continue;
      final currentDecl =
          nominalDeclOf(current) ?? _ctx.types.find(current.file, current.name);
      if (currentDecl != null &&
          (identical(currentDecl, target) ||
              (currentDecl.library == target.library &&
                  currentDecl.name == target.name))) {
        return current;
      }
      queue.addAll(directSupertypes(current));
    }
    return null;
  }

  /// Unifies [pattern] against [concrete] positionally, recording the
  /// binding for each type-parameter slot encountered (unifying `List~X~`
  /// with `List~num~` binds X to num). Replaces
  /// `collectTypeParameterSubstitutions`.
  void unify(
    TypeRef pattern,
    TypeRef concrete,
    Map<TypeParameterDef, TypeRef> substitutions,
  ) {
    if (pattern.isTypeParameter) {
      substitutions[(pattern as TypeParameterTypeRef).parameter] = concrete;
      return;
    }
    // `FutureOr<S>` unifies through whichever branch matches the concrete's
    // shape — a `Future<int>` argument binds S through `Future<S>`, a plain
    // `int` binds it directly.
    if (pattern is InterfaceTypeRef &&
        pattern.decl.isSpec(AsyncTypes.futureOr)) {
      final s = interfaceArgumentsOf(pattern).isEmpty
          ? CoreTypes.dynamic.ref(_ctx)
          : interfaceArgumentsOf(pattern).first;
      final instantiation = asInstanceOf(
        concrete,
        _ctx.types.bySpec(CoreTypes.future),
      );
      if (instantiation != null) {
        unify(
          _ctx.types.bySpec(CoreTypes.future).instantiate([s]),
          instantiation,
          substitutions,
        );
      } else {
        unify(s, concrete, substitutions);
      }
      return;
    }
    if (pattern is FunctionTypeRef && concrete is FunctionTypeRef) {
      // Signature-shaped unification: positional and named parameters,
      // then the return type — `void Function(X)` against
      // `void Function(num)` binds X to num.
      final ps = pattern.signature;
      final cs = concrete.signature;
      for (
        var i = 0;
        i < ps.positional.length && i < cs.positional.length;
        i++
      ) {
        unify(ps.positional[i], cs.positional[i], substitutions);
      }
      for (final e in ps.named.entries) {
        final c = cs.named[e.key];
        if (c != null) unify(e.value.type, c.type, substitutions);
      }
      unify(ps.returnType, cs.returnType, substitutions);
      return;
    }
    if (!identical(nominalDeclOf(pattern), nominalDeclOf(concrete))) {
      _unifyViaSupertypes(pattern, concrete, substitutions);
      return;
    }
    final args = interfaceArgumentsOf(pattern);
    for (
      var i = 0;
      i < args.length && i < interfaceArgumentsOf(concrete).length;
      i++
    ) {
      unify(args[i], interfaceArgumentsOf(concrete)[i], substitutions);
    }
  }

  /// Unifies [pattern] against [concrete] via [pattern]'s declared
  /// supertypes (e.g. `List~X~` against `Iterable~num~` reaches
  /// `Iterable~X~`). When a hop's clause is raw (`List~E~ extends
  /// Iterable`), falls back to positional binding, as the old
  /// `_collectViaSupertypes` did.
  void _unifyViaSupertypes(
    TypeRef pattern,
    TypeRef concrete,
    Map<TypeParameterDef, TypeRef> substitutions,
  ) {
    // The covariant argument shape — `Iterable~T~` against `List~int~` —
    // instantiates [pattern]'s declaration out of [concrete]'s supertypes
    // (`Iterable~int~`) and unifies positionally, binding T to int.
    final instantiation = asInstanceOf(concrete, nominalDeclOf(pattern));
    if (instantiation != null) {
      unify(pattern, instantiation, substitutions);
      return;
    }
    final queue = <TypeRef>[pattern];
    final seen = <TypeRef>{};
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (!seen.add(current)) continue;
      if (identical(nominalDeclOf(current), nominalDeclOf(concrete))) {
        if (interfaceArgumentsOf(current).isEmpty &&
            !identical(current, pattern) &&
            interfaceArgumentsOf(pattern).length ==
                interfaceArgumentsOf(concrete).length) {
          // The declaring class's supertype is raw; bind `pattern`'s
          // arguments positionally instead.
          final pArgs = interfaceArgumentsOf(pattern);
          for (var i = 0; i < pArgs.length; i++) {
            unify(pArgs[i], interfaceArgumentsOf(concrete)[i], substitutions);
          }
        } else {
          unify(current, concrete, substitutions);
        }
        return;
      }
      queue.addAll(directSupertypes(current));
    }
  }

  /// Every runtime type index a value of [type] may report `is`/`as` success
  /// for: its own id plus every declared supertype's, walked with
  /// substitutions applied at each hop.
  ///
  /// [maxEmittedArgDepth] bounds instantiated-supertype emission — a
  /// self-nesting interface (`F<T> implements Future<F<F<T>>>`) generates
  /// deeper instantiations at every hop and the closure would never
  /// terminate. The bound is absolute, not relative to [type]'s depth: a
  /// deep instantiated argument is itself registered and expanded, so a
  /// root-relative bound would let each new root re-base the limit — the
  /// classic divergent-future explosion. Supertypes beyond the bound
  /// contribute only their nominal index.
  Set<int> supertypeIds(TypeRef type, {int? maxEmittedArgDepth}) {
    final selfId = _ctx.runtimeTypes.idOf(type);
    final indices = {
      selfId,
      if (type is InterfaceTypeRef)
        _ctx.runtimeTypes.indexMap[type.decl] ?? selfId,
    };
    final seen = {type};
    final worklist = directSupertypes(type);
    final maxSuperDepth = maxEmittedArgDepth;
    while (worklist.isNotEmpty) {
      final supertype = worklist.removeLast();
      if (!seen.add(supertype)) continue;
      if (maxSuperDepth != null &&
          typeArgumentDepth(supertype) > maxSuperDepth) {
        if (supertype is InterfaceTypeRef) {
          indices.add(
            _ctx.runtimeTypes.indexMap[supertype.decl] ??
                _ctx.runtimeTypes.idOf(supertype.decl.rawType),
          );
        }
        continue;
      }
      final supertypeId = _ctx.runtimeTypes.idOf(supertype);
      indices.add(supertypeId);
      if (supertype is InterfaceTypeRef) {
        indices.add(_ctx.runtimeTypes.indexMap[supertype.decl] ?? supertypeId);
      }
      worklist.addAll(directSupertypes(supertype));
    }
    return indices;
  }

  /// Argument depth needed by a root and its instantiated hierarchy. Visit
  /// each declaration once so expanding inheritance cycles cannot diverge.
  int supertypeArgumentDepth(TypeRef type) {
    var depth = 0;
    final seen = <(int, String)>{};
    final worklist = [type];
    while (worklist.isNotEmpty) {
      final current = worklist.removeLast();
      final currentDepth = typeArgumentDepth(current);
      if (currentDepth > depth) depth = currentDepth;
      if (!seen.add((current.file, current.name))) continue;
      worklist.addAll(directSupertypes(current));
    }
    return depth;
  }

  /// The [type] produced by removing every type-parameter reference —
  /// each parameter replaced by its declared bound (or `dynamic` when
  /// unbounded). Callers use this when a type leaves the scope that gave
  /// those parameters meaning — an unconstrained `T` is not a usable type
  /// for the caller. When [only] is given, parameters outside the set are
  /// kept: they belong to the caller's own scope and stay meaningful.
  TypeRef lowerTypeParameters(
    TypeRef type, {
    Set<TypeParameterDef>? only,

    /// Parameter owner kinds that lower even when absent from [only] —
    /// alias-owned parameters embedded in a formal are inference variables
    /// at the call boundary, independent of how the call seeded its
    /// generic map.
    Set<TypeParameterOwnerKind> kinds = const {},
  }) {
    final bindings = <TypeParameterDef, TypeRef>{};
    void collect(TypeRef t) {
      if (t.isTypeParameter) {
        final parameter = (t as TypeParameterTypeRef).parameter;
        if (bindings.containsKey(parameter) ||
            (only != null &&
                !only.contains(parameter) &&
                !kinds.contains(parameter.owner.kind))) {
          return;
        }
        final bound = parameter.bound ?? CoreTypes.dynamic.ref(_ctx);
        bindings[parameter] = bound;
        // A bound can itself hold parameters (`T extends U, U extends C`)
        // — collect them too so they substitute away below.
        collect(bound);
        return;
      }
      for (final argument in interfaceArgumentsOf(t)) {
        collect(argument);
      }
      if (t is RecordTypeRef) {
        for (final field in t.positional) {
          collect(field);
        }
        for (final field in t.named.values) {
          collect(field);
        }
      }
      if (t is FunctionTypeRef) {
        collect(t.signature.returnType);
        for (final parameter in t.signature.positional) {
          collect(parameter);
        }
        for (final parameter in t.signature.named.values) {
          collect(parameter.type);
        }
      }
    }

    collect(type);
    if (bindings.isEmpty) return type;
    final substitution = Substitution.of(bindings);
    // Bound chains substitute one hop per pass (`T -> U -> C`); re-apply
    // until none of the lowered parameters remains — bounded by the
    // collected binding count.
    var lowered = type;
    var passes = bindings.length;
    do {
      lowered = lowered.substituteTypeParameters(substitution);
    } while (_mentionsAnyParameter(lowered, bindings.keys.toSet()) &&
        passes-- > 0);
    return lowered;
  }

  /// Default arguments expand acyclic bounds and erase references within a
  /// bound cycle: `X extends Comparable<X>` defaults to `Comparable<dynamic>`.
  /// Inferred arguments remain fixed; pattern inference closes bound cycles
  /// with [recursiveDefault] instead of the usual variance-dependent defaults.
  Map<TypeParameterDef, TypeRef> instantiateToBounds(
    List<TypeParameterDef> parameters, {
    TypeRef? aliasType,
    Map<TypeParameterDef, TypeRef> knownTypes = const {},
    TypeRef? recursiveDefault,
  }) {
    if (parameters.isEmpty) return const {};
    final variances = aliasType == null
        ? const <TypeParameterDef, int>{}
        : _parameterVariances(aliasType);
    final dependencies = {
      for (final parameter in parameters)
        parameter: [
          if (parameter.bound != null)
            for (final candidate in parameters)
              if (_mentionsAnyParameter(parameter.bound!, {candidate}))
                candidate,
        ],
    };
    bool reaches(
      TypeParameterDef from,
      TypeParameterDef target,
      Set<TypeParameterDef> visited,
    ) {
      if (knownTypes.containsKey(from)) return false;
      if (from == target) return true;
      if (!visited.add(from)) return false;
      return dependencies[from]!.any((next) => reaches(next, target, visited));
    }

    final defaults = <TypeParameterDef, TypeRef>{...knownTypes};
    TypeRef resolve(TypeParameterDef parameter) => defaults.putIfAbsent(
      parameter,
      () {
        final upper = <TypeParameterDef, TypeRef>{};
        final lower = <TypeParameterDef, TypeRef>{};
        final boundVariances = parameter.bound == null
            ? const <TypeParameterDef, int>{}
            : _parameterVariances(parameter.bound!);
        for (final dependency in dependencies[parameter]!) {
          if (reaches(dependency, parameter, {})) {
            final variance = variances[parameter] ?? 1;
            upper[dependency] =
                recursiveDefault ??
                (variance == 2 ? CoreTypes.never : CoreTypes.dynamic).ref(_ctx);
            lower[dependency] =
                recursiveDefault ??
                (variance == 1 ? CoreTypes.never : CoreTypes.dynamic).ref(_ctx);
          } else {
            upper[dependency] = resolve(dependency);
            lower[dependency] = boundVariances[dependency] == 2
                ? CoreTypes.never.ref(_ctx)
                : upper[dependency]!;
          }
        }
        return _closeBound(
          parameter.bound ?? CoreTypes.dynamic.ref(_ctx),
          Substitution.of(upper),
          Substitution.of(lower),
        );
      },
    );
    for (final parameter in parameters) {
      resolve(parameter);
    }
    return defaults;
  }

  /// Positive and negative occurrences are bits 1 and 2; their union is
  /// invariant. A generic function's bounds are always invariant.
  Map<TypeParameterDef, int> _parameterVariances(TypeRef type) {
    final occurrences = <TypeParameterDef, int>{};
    void visit(TypeRef type, int variance) {
      switch (type) {
        case TypeParameterTypeRef(:final parameter):
          occurrences[parameter] = (occurrences[parameter] ?? 0) | variance;
        case InterfaceTypeRef(:final arguments):
          for (final argument in arguments) {
            visit(argument, variance);
          }
        case RecordTypeRef(:final positional, :final named):
          for (final field in [...positional, ...named.values]) {
            visit(field, variance);
          }
        case FunctionTypeRef(:final signature):
          for (final parameter in signature.typeParameters) {
            final bound = parameter.bound;
            if (bound != null) visit(bound, 3);
          }
          final opposite = variance == 3 ? 3 : 3 - variance;
          for (final parameter in signature.positional) {
            visit(parameter, opposite);
          }
          for (final parameter in signature.named.values) {
            visit(parameter.type, opposite);
          }
          visit(signature.returnType, variance);
      }
    }

    visit(type, 1);
    return occurrences;
  }

  /// Recursive-bound holes use the opposite extremum in function parameters.
  TypeRef _closeBound(TypeRef type, Substitution upper, Substitution lower) {
    if (upper.isEmpty) return type;
    TypeRef close(TypeRef type) => _closeBound(type, upper, lower);
    return switch (type) {
      TypeParameterTypeRef() => type.substituteTypeParameters(upper),
      InterfaceTypeRef(:final arguments) =>
        arguments.isEmpty
            ? type
            : type.copyWith(arguments: arguments.map(close).toList()),
      RecordTypeRef(:final positional, :final named) => RecordTypeRef(
        positional.map(close).toList(),
        {for (final field in named.entries) field.key: close(field.value)},
        nullable: type.nullable,
      ),
      FunctionTypeRef(:final signature) => type.copyWith(
        signature: FunctionSignature(
          typeParameters: signature.typeParameters,
          positional: [
            for (final parameter in signature.positional)
              _closeBound(parameter, lower, upper),
          ],
          requiredPositional: signature.requiredPositional,
          named: {
            for (final entry in signature.named.entries)
              entry.key: (
                type: _closeBound(entry.value.type, lower, upper),
                required: entry.value.required,
              ),
          },
          returnType: close(signature.returnType),
        ),
      ),
    };
  }

  /// Whether [type] mentions any parameter in [parameters].
  bool _mentionsAnyParameter(TypeRef type, Set<TypeParameterDef> parameters) {
    var found = false;
    void visit(TypeRef t) {
      if (found) return;
      if (t.isTypeParameter) {
        found = parameters.contains((t as TypeParameterTypeRef).parameter);
        return;
      }
      for (final argument in interfaceArgumentsOf(t)) {
        visit(argument);
      }
      if (t is RecordTypeRef) {
        for (final field in t.positional) {
          visit(field);
        }
        for (final field in t.named.values) {
          visit(field);
        }
      }
      if (t is FunctionTypeRef) {
        visit(t.signature.returnType);
        for (final parameter in t.signature.positional) {
          visit(parameter);
        }
        for (final parameter in t.signature.named.values) {
          visit(parameter.type);
        }
      }
    }

    visit(type);
    return found;
  }

  /// Replaces every remaining type-parameter reference inside [type] with
  /// `dynamic`. Erasure is the fallback after [lowerTypeParameters] for
  /// bounds that cannot be represented — cyclic F-bounds like
  /// `S extends Built<S, B>` never reach a parameter-free form.
  TypeRef eraseTypeParameters(
    TypeRef type, {
    Set<TypeParameterOwnerKind> preserveKinds = const {},
  }) {
    final parameters = <TypeParameterDef>{};
    void collect(TypeRef t) {
      if (t.isTypeParameter) {
        final parameter = (t as TypeParameterTypeRef).parameter;
        if (!preserveKinds.contains(parameter.owner.kind)) {
          parameters.add(parameter);
        }
        return;
      }
      for (final argument in interfaceArgumentsOf(t)) {
        collect(argument);
      }
      if (t is RecordTypeRef) {
        for (final field in t.positional) {
          collect(field);
        }
        for (final field in t.named.values) {
          collect(field);
        }
      }
      if (t is FunctionTypeRef) {
        collect(t.signature.returnType);
        for (final parameter in t.signature.positional) {
          collect(parameter);
        }
        for (final parameter in t.signature.named.values) {
          collect(parameter.type);
        }
      }
    }

    collect(type);
    if (parameters.isEmpty) return type;
    return type.substituteTypeParameters(
      Substitution.of({
        for (final parameter in parameters)
          parameter: CoreTypes.dynamic.ref(_ctx),
      }),
    );
  }

  /// Fully unwraps a type-parameter chain (`T extends U, U extends C`) to
  /// the outermost non-parameter bound, or `dynamic` when unbounded.
  TypeRef throughTypeParameters(TypeRef type) {
    var t = type;
    final seen = <TypeRef>{};
    while (t.isTypeParameter && seen.add(t)) {
      final bound = (t as TypeParameterTypeRef).effectiveBound;
      if (bound == null) {
        return CoreTypes.dynamic.ref(_ctx);
      }
      t = bound;
    }
    return t;
  }

  /// The `flatten` function from the async spec: the value type `T` such
  /// that `await`/`async` treat a `FutureOr<T>`/`Future<T>`-shaped value as
  /// `T`. A `FutureOr<S>` surface peels once to `S`; a `Future<S>` (or a
  /// class implementing it) peels recursively. The superinterface step
  /// itself cannot recurse — divergent futures
  /// (`D implements Future<D<D<T>>>`) would otherwise expand forever.
  TypeRef flatten(TypeRef type) {
    var t = type;
    var nullable = type.nullable;
    // A type parameter keeps its shape unless the bound itself is a
    // future — `X extends Future<S>` awaits to `S`, `X extends
    // FutureOr<S>` awaits to `S`, otherwise `await x` stays `X`.
    if (t is TypeParameterTypeRef) {
      final bound = t.effectiveBound;
      if (bound == null) return t;
      if (bound is InterfaceTypeRef && bound.decl.isSpec(AsyncTypes.futureOr)) {
        return flatten(bound).withNullable(bound.nullable || nullable);
      }
      final instantiation = asInstanceOf(
        bound,
        _ctx.types.bySpec(CoreTypes.future),
      );
      if (instantiation == null) return t;
      // `X extends Future<A>?` awaits to `A?` — the bound's own
      // nullability distributes onto the flattened result.
      return (interfaceArgumentsOf(instantiation).isEmpty
              ? CoreTypes.dynamic.ref(_ctx)
              : interfaceArgumentsOf(instantiation).first)
          .withNullable(bound.nullable || nullable);
    }
    if (t.name == 'FutureOr' && interfaceArgumentsOf(t).isNotEmpty) {
      // `FutureOr<S>` unwraps once — `flatten(FutureOr<S>)` is `S`, not
      // `flatten(S)` — so `FutureOr<Future<int>>` awaits to `Future<int>`.
      return interfaceArgumentsOf(
        t,
      ).first.withNullable(interfaceArgumentsOf(t).first.nullable || nullable);
    }
    final instantiation = asInstanceOf(t, _ctx.types.bySpec(CoreTypes.future));
    if (instantiation != null) {
      nullable = nullable || t.nullable;
      t = interfaceArgumentsOf(instantiation).isEmpty
          ? CoreTypes.dynamic.ref(_ctx)
          : interfaceArgumentsOf(instantiation).first;
    }
    return t.withNullable(t.nullable || nullable);
  }

  /// Resolves [paramName] — a generic parameter declared by a bridge class —
  /// through [type]'s supertypes when [type] itself is a plain class. A Dart
  /// class extending or mixing a bridged generic maps the bridge's parameters
  /// to its applied arguments positionally. Returns null when no bridged ancestor declares
  /// [paramName]. Replaces `bridgedTypeArgument`.
  TypeRef? bridgedTypeArgument(TypeRef type, String paramName) {
    final seen = <String>{};
    final worklist = <TypeRef>[type];
    while (worklist.isNotEmpty) {
      final current = worklist.removeLast();
      if (!seen.add('${current.file}:${current.name}')) continue;
      final decl = nominalDeclOf(current);
      final classDef = decl is BridgeTypeDecl ? decl.classDef : null;
      if (classDef != null) {
        final names = classDef.type.generics.keys.toList();
        final index = names.indexOf(paramName);
        if (index < 0) continue;
        if (index < interfaceArgumentsOf(current).length) {
          return interfaceArgumentsOf(current)[index];
        }
        final bound = classDef.type.generics[paramName]!.$extends;
        return bound == null
            ? CoreTypes.dynamic.ref(_ctx)
            : TypeRef.fromBridgeTypeRef(_ctx, bound);
      }
      worklist.addAll(directSupertypes(current));
    }
    return null;
  }

  /// The greatest closure of a context type: every inference hole —
  /// represented as an unfilled type parameter — becomes `Object?`.
  /// `Iterable<_>` closes to `Iterable<Object?>`, the upper bound the
  /// conditional/`??=` rules test the joined type against.
  TypeRef greatestClosure(TypeRef type) => switch (type) {
    TypeParameterTypeRef() => CoreTypes.object.ref(_ctx).withNullable(true),
    InterfaceTypeRef(:final arguments) =>
      arguments.isEmpty
          ? type
          : type.copyWith(
              arguments: [for (final arg in arguments) greatestClosure(arg)],
            ),
    RecordTypeRef(:final positional, :final named) => RecordTypeRef(
      [for (final field in positional) greatestClosure(field)],
      {
        for (final entry in named.entries)
          entry.key: greatestClosure(entry.value),
      },
      nullable: type.nullable,
    ),
    FunctionTypeRef(:final signature) => type.copyWith(
      signature: FunctionSignature(
        typeParameters: signature.typeParameters,
        positional: [
          for (final field in signature.positional) greatestClosure(field),
        ],
        requiredPositional: signature.requiredPositional,
        named: {
          for (final entry in signature.named.entries)
            entry.key: (
              type: greatestClosure(entry.value.type),
              required: entry.value.required,
            ),
        },
        returnType: greatestClosure(signature.returnType),
      ),
    ),
  };

  /// Given a set of [types], find their closest common ancestor type —
  /// every type's declaration-shaped chain (extends above interfaces above
  /// mixins, in declaration order) contributing to a layer-frequency pick,
  /// with assignability breaking the shallowest layer's ties.
  TypeRef leastUpperBound(Set<TypeRef> types) {
    assert(types.isNotEmpty);
    // Nullability joins upward too — `int` and `int?` meet at `int?`.
    final makeNullable =
        types.remove(CoreTypes.nullType.ref(_ctx)) ||
        types.any((type) => type.nullable);
    if (types.isEmpty) {
      return CoreTypes.nullType.ref(_ctx);
    }
    if (types.length == 1) {
      return makeNullable ? types.first.withNullable(true) : types.first;
    }
    // Mirroring the analyzer's `InterfaceLeastUpperBoundHelper`: subtype
    // either way, a shared declaration merges arguments point-wise, and
    // otherwise the winner is the deepest *exactly-instantiated* common
    // supertype — `Iterable<int>`/`Iterable<double>` meet at
    // `Iterable<num>`, while `int`/`String` skip `Comparable<num>`/
    // `Comparable<String>` (different instantiations) and meet at `Object`.
    var result = types.first.withNullable(false);
    for (final other in types.skip(1)) {
      final next = _pairwiseUpperBound(result, other.withNullable(false));
      result = next;
    }
    return result.withNullable(result.nullable || makeNullable);
  }

  /// The pairwise LUB step behind [leastUpperBound]: function and parameter
  /// rules precede interface subtyping. A shared declaration merges arguments
  /// covariantly (Dart classes are covariant unless declared `in`/`inout`,
  /// which dart_eval does not model),
  /// and incomparable types intersect their superinterface *instantiations*
  /// — the set element keeps its type arguments, so `Comparable<num>` and
  /// `Comparable<String>` never meet — then takes the unique deepest.
  TypeRef _pairwiseUpperBound(TypeRef a, TypeRef b) {
    if (a.isSpec(CoreTypes.never)) {
      return b.withNullable(b.nullable || a.nullable);
    }
    if (b.isSpec(CoreTypes.never)) {
      return a.withNullable(a.nullable || b.nullable);
    }
    if (a.isSpec(CoreTypes.nullType)) return b.withNullable(true);
    if (b.isSpec(CoreTypes.nullType)) return a.withNullable(true);
    // Function/interface joins use Object before the general subtype rule.
    // A function below FutureOr<Function> still joins that union at Object.
    final mixedFunction = (a is FunctionTypeRef) != (b is FunctionTypeRef);
    if (mixedFunction &&
        a is! TypeParameterTypeRef &&
        b is! TypeParameterTypeRef &&
        !a.isSpec(CoreTypes.dynamic) &&
        !b.isSpec(CoreTypes.dynamic) &&
        !a.isSpec(CoreTypes.voidType) &&
        !b.isSpec(CoreTypes.voidType)) {
      final other = a is FunctionTypeRef ? b : a;
      if (other.isSpec(CoreTypes.function)) return other;
      return leastUpperBound({CoreTypes.object.ref(_ctx), other});
    }
    if (a.isAssignableTo(_ctx, b, forceAllowDynamic: false)) return b;
    if (b.isAssignableTo(_ctx, a, forceAllowDynamic: false)) return a;
    if (a is TypeParameterTypeRef) {
      return leastUpperBound({_closedParameterBound(a), b});
    }
    if (b is TypeParameterTypeRef) {
      return leastUpperBound({a, _closedParameterBound(b)});
    }
    if (a.isSpec(CoreTypes.object) || b.isSpec(CoreTypes.object)) {
      final other = a.isSpec(CoreTypes.object) ? b : a;
      return CoreTypes.object.ref(_ctx).withNullable(!_isNonNullable(other));
    }
    // Identically-shaped signatures meet pointwise: the return type joins
    // upward while parameters meet at their greatest lower bound, matching
    // the analyzer's function-type rule — `C1<int> Function()` and
    // `C2<int> Function()` meet at `A Function()`.
    if (a is FunctionTypeRef && b is FunctionTypeRef) {
      final sa = a.signature;
      final sb = b.signature;
      if (sa.positional.length == sb.positional.length &&
          sa.requiredPositional == sb.requiredPositional &&
          sa.named.length == sb.named.length &&
          sa.named.keys.every(sb.named.containsKey) &&
          sa.typeParameters.length == sb.typeParameters.length) {
        return a.copyWith(
          signature: FunctionSignature(
            typeParameters: sa.typeParameters,
            positional: [
              for (var i = 0; i < sa.positional.length; i++)
                greatestLowerBound(sa.positional[i], sb.positional[i]),
            ],
            requiredPositional: sa.requiredPositional,
            named: {
              for (final entry in sa.named.entries)
                entry.key: (
                  type: greatestLowerBound(
                    entry.value.type,
                    sb.named[entry.key]!.type,
                  ),
                  required: entry.value.required,
                ),
            },
            returnType: _pairwiseUpperBound(sa.returnType, sb.returnType),
          ),
        );
      }
    }
    if (a is InterfaceTypeRef && b is InterfaceTypeRef) {
      final declA = nominalDeclOf(a);
      final declB = nominalDeclOf(b);
      if (declA != null && identical(declA, declB)) {
        final argsA = interfaceArgumentsOf(a);
        final argsB = interfaceArgumentsOf(b);
        if (argsA.isNotEmpty && argsA.length == argsB.length) {
          return a.copyWith(
            arguments: [
              for (var i = 0; i < argsA.length; i++)
                _pairwiseUpperBound(argsA[i], argsB[i]),
            ],
          );
        }
      }
    }
    final common = _superinterfaceSet(a)
      ..add(a)
      ..retainAll(_superinterfaceSet(b)..add(b));
    if (common.isEmpty) {
      return CoreTypes.dynamic.ref(_ctx);
    }
    // Deepest unique inheritance path to Object wins; a tied depth level is
    // skipped wholesale, so `C1<int>`/`C2<double>` land on `A` rather than
    // one of the two `B<num>` instantiations.
    final depths = {for (final type in common) type: _inheritanceDepth(type)};
    for (var depth = depths.values.fold(0, math.max); depth >= 0; depth--) {
      final atDepth = [
        for (final entry in depths.entries)
          if (entry.value == depth) entry.key,
      ];
      if (atDepth.length == 1) return atDepth.first;
    }
    return CoreTypes.dynamic.ref(_ctx);
  }

  /// Close only this parameter's recursive occurrences, respecting variance.
  TypeRef _closedParameterBound(TypeParameterTypeRef type) => _closeBound(
    type.effectiveBound ?? CoreTypes.object.ref(_ctx).withNullable(true),
    Substitution.of({
      type.parameter: CoreTypes.object.ref(_ctx).withNullable(true),
    }),
    Substitution.of({type.parameter: CoreTypes.never.ref(_ctx)}),
  );

  bool _isNonNullable(TypeRef type, [Set<TypeParameterDef>? visiting]) {
    if (type.nullable ||
        type.isSpec(CoreTypes.nullType) ||
        type.isSpec(CoreTypes.dynamic) ||
        type.isSpec(CoreTypes.voidType)) {
      return false;
    }
    if (type is TypeParameterTypeRef) {
      final active = visiting ?? <TypeParameterDef>{};
      final bound = type.effectiveBound;
      return bound != null &&
          active.add(type.parameter) &&
          _isNonNullable(bound, active);
    }
    if (type.isSpec(AsyncTypes.futureOr)) {
      final arguments = interfaceArgumentsOf(type);
      return arguments.isNotEmpty && _isNonNullable(arguments.first, visiting);
    }
    return true;
  }

  /// The lower bound used by pattern context schemas and function parameters.
  /// Function parameters join upwards because their positions are contravariant.
  TypeRef greatestLowerBound(TypeRef a, TypeRef b) {
    if (a.isSpec(CoreTypes.dynamic)) return b;
    if (b.isSpec(CoreTypes.dynamic)) return a;
    if (a.isAssignableTo(_ctx, b, forceAllowDynamic: false)) return a;
    if (b.isAssignableTo(_ctx, a, forceAllowDynamic: false)) return b;
    if (a is FunctionTypeRef && b is FunctionTypeRef) {
      final sa = a.signature;
      final sb = b.signature;
      if (sa.typeParameters.isEmpty &&
          sb.typeParameters.isEmpty &&
          sa.positional.length == sb.positional.length &&
          sa.requiredPositional == sb.requiredPositional &&
          sa.named.length == sb.named.length &&
          sa.named.keys.every(sb.named.containsKey)) {
        return a.copyWith(
          nullable: a.nullable && b.nullable,
          signature: FunctionSignature(
            positional: [
              for (var i = 0; i < sa.positional.length; i++)
                leastUpperBound({sa.positional[i], sb.positional[i]}),
            ],
            requiredPositional: sa.requiredPositional,
            named: {
              for (final entry in sa.named.entries)
                entry.key: (
                  type: leastUpperBound({
                    entry.value.type,
                    sb.named[entry.key]!.type,
                  }),
                  required:
                      entry.value.required && sb.named[entry.key]!.required,
                ),
            },
            returnType: greatestLowerBound(sa.returnType, sb.returnType),
          ),
        );
      }
    }
    return CoreTypes.never.ref(_ctx);
  }

  /// All of [type]'s superinterfaces as *instantiated* types (self
  /// included), mirroring `computeSuperinterfaceSet`: the intersection of
  /// two of these sets only matches equal instantiations.
  Set<TypeRef> _superinterfaceSet(TypeRef type) => {
    for (final layer in _typeChain(type)) ...layer,
  };

  /// The longest inheritance path from [type] to `Object` (analyzer's
  /// `computeLongestInheritancePathToObject`), counting superclass,
  /// interface, and mixin edges. Decl-less types (records, parameters)
  /// bottom out at 0.
  int _inheritanceDepth(TypeRef type) {
    final visiting = <Object>{};
    int depth(TypeRef t) {
      final key = nominalDeclOf(t) ?? t;
      if (!visiting.add(key)) return 0;
      var best = 0;
      for (final supertype in interfacesOf(t)) {
        final d = depth(supertype) + 1;
        if (d > best) best = d;
      }
      final superclass = superclassOf(t);
      if (superclass != null) {
        var superDepth = depth(superclass);
        final mixins = mixinsOf(t);
        for (final mixin in mixins) {
          superDepth = math.max(superDepth, depth(mixin)) + 1;
        }
        // Each application adds an intermediate class. A named alias is
        // itself the last application, rather than another subclass.
        if (mixins.isNotEmpty &&
            nominalDeclOf(t)?.kind == TypeDeclKind.classAlias) {
          superDepth--;
        }
        best = math.max(best, superDepth + 1);
      }
      visiting.remove(key);
      return best;
    }

    return depth(type);
  }

  /// The declaration-shaped chain for [type]: `[this]`, then layers of
  /// supertypes — the superclass's own chain forms the deepest layers while
  /// interfaces and mixins fill layer 0 upward in declaration order.
  /// Supertypes are declared in the declaring class's parameter space, so
  /// they arrive already substituted through the applied arguments —
  /// otherwise `C1<int>` and `C2<int>` would see `B<C1.T>` and `B<C2.T>` as
  /// unrelated types.
  List<List<TypeRef>> _typeChain(TypeRef type) {
    final l1extends = superclassOf(type);
    final l2extends = l1extends == null
        ? const <List<TypeRef>>[]
        : _typeChain(l1extends);
    final chain = <List<TypeRef>>[
      if (l1extends != null && l2extends.isEmpty) [l1extends],
      ...l2extends,
    ];

    for (final imp in interfacesOf(type).reversed) {
      if (chain.isEmpty) {
        chain.add([]);
      }
      chain[0].add(imp);
      final tc = _typeChain(imp);
      for (var i = 0; i < tc.length; i++) {
        if (chain.length < i + 2) {
          chain.add([]);
        }
        chain[i + 1].addAll(tc[i]);
      }
    }

    for (final w in mixinsOf(type).reversed) {
      if (chain.isEmpty) {
        chain.add([]);
      }
      chain[0].add(w);
      final tc = _typeChain(w);
      for (var i = 0; i < tc.length; i++) {
        while (chain.length <= i + 1) {
          chain.add([]);
        }
        chain[i + 1].addAll(tc[i]);
      }
    }

    return [
      [type],
      ...chain,
    ];
  }

  /// Whether a value of type [from] can be assigned to a slot of type [to].
  /// This is the main check for assignments, but is also useful for
  /// function types.
  ///
  /// When [forceAllowDynamic] is set (the default), immediately returns
  /// true if either side is `dynamic`. Disable to enforce type strictness.
  ///
  /// [overrideGenerics] substitutes the viewed-as type arguments while
  /// walking declaration-space supertypes (which carry parameter refs).
  bool isAssignable(
    TypeRef from,
    TypeRef to, {
    List<TypeRef>? overrideGenerics,
    bool forceAllowDynamic = true,
    // Dart's *assignment* relation additionally permits implicit downcasts
    // out of `dynamic` inside function-type components — `void Function(int)`
    // is assignable to `void Function(dynamic)` though not a subtype. The
    // `is` fold and other strict callers leave this off.
    bool allowDynamicParameterDowncast = false,
  }) {
    if (to.isSpec(CoreTypes.dynamic) ||
        to.isSpec(CoreTypes.voidType) ||
        (forceAllowDynamic && from.isSpec(CoreTypes.dynamic))) {
      return true;
    }
    // `dynamic <: T` whenever `T` is a top type (`dynamic`, `void`, or a
    // nullable `Object`) — a genuine subtype fact, not the `dynamic`
    // downcast leniency [forceAllowDynamic] controls.
    if (from.isSpec(CoreTypes.dynamic)) {
      // `dynamic <: FutureOr<S>` reduces to `dynamic <: S` — the `Future`
      // member is never a strict supertype of `dynamic`.
      if (to is InterfaceTypeRef && to.decl.isSpec(AsyncTypes.futureOr)) {
        final s = interfaceArgumentsOf(to);
        final inner = s.isEmpty
            ? CoreTypes.dynamic.ref(_ctx)
            : s.first.withNullable(to.nullable || s.first.nullable);
        return isAssignable(from, inner, forceAllowDynamic: forceAllowDynamic);
      }
      return to.isSpec(CoreTypes.object) && to.nullable;
    }

    if (from.isSpec(CoreTypes.never)) {
      // `Never` is the bottom type: assignable to every type.
      return true;
    }
    if (from.isSpec(CoreTypes.nullType)) {
      if (to.nullable || to.isSpec(CoreTypes.nullType)) return true;
      // `Null <: FutureOr<S>` reduces to `Null <: S` — `Null` is never a
      // `Future`. `FutureOr<void>` accepts it because `void` is a top type.
      if (to is InterfaceTypeRef && to.decl.isSpec(AsyncTypes.futureOr)) {
        final s = interfaceArgumentsOf(to);
        return s.isNotEmpty &&
            isAssignable(from, s.first, forceAllowDynamic: forceAllowDynamic);
      }
      return false;
    }
    // A `FutureOr` target defers the nullability check to its members —
    // `Object? <: FutureOr<Object?>` holds through the `Object?` member
    // even though the union itself is not marked nullable.
    if (from.nullable &&
        !to.nullable &&
        !(to is InterfaceTypeRef && to.decl.isSpec(AsyncTypes.futureOr))) {
      return false;
    }

    if (from is TypeParameterTypeRef) {
      // Same parameter — the nullability gate above already handled the
      // `E` → `E?` direction; `==` would also reject it on nullability.
      if (to is TypeParameterTypeRef && from.parameter == to.parameter) {
        return true;
      }
      final relation = (
        from,
        to,
        forceAllowDynamic,
        allowDynamicParameterDowncast,
      );
      if (!_activeParameterRelations.add(relation)) return false;
      try {
        // A union target decomposes before the bound fallback — `S` is a
        // member of `FutureOr<S>` even though the bound `Object?` is not
        // assignable to it.
        if (to is InterfaceTypeRef && to.decl.isSpec(AsyncTypes.futureOr)) {
          final s = interfaceArgumentsOf(to).isEmpty
              ? CoreTypes.dynamic.ref(_ctx)
              : interfaceArgumentsOf(to).first;
          final future = _ctx.types.bySpec(CoreTypes.future).instantiate([
            s,
          ], nullable: to.nullable);
          if (isAssignable(
                from,
                future,
                forceAllowDynamic: forceAllowDynamic,
                allowDynamicParameterDowncast: allowDynamicParameterDowncast,
              ) ||
              isAssignable(
                from,
                s.withNullable(to.nullable || s.nullable),
                forceAllowDynamic: forceAllowDynamic,
                allowDynamicParameterDowncast: allowDynamicParameterDowncast,
              )) {
            return true;
          }
        }
        // A type parameter is assignable to [to] iff its declared bound is
        // (or the promoted bound, `X & S`, when flow analysis narrowed it).
        // An unbounded parameter (`<T>`) has the implicit bound `Object?`.
        return isAssignable(
          from.effectiveBound ?? CoreTypes.object.ref(_ctx).withNullable(true),
          to,
          forceAllowDynamic: forceAllowDynamic,
          allowDynamicParameterDowncast: allowDynamicParameterDowncast,
        );
      } finally {
        _activeParameterRelations.remove(relation);
      }
    }

    // `FutureOr<S>` is the union `Future<S> | S`: a target accepts a value
    // when either branch does; a union source is assignable only when BOTH
    // branches are. Nullability of the union distributes to each branch.
    if (from is InterfaceTypeRef && from.decl.isSpec(AsyncTypes.futureOr)) {
      final s = interfaceArgumentsOf(from).isEmpty
          ? CoreTypes.dynamic.ref(_ctx)
          : interfaceArgumentsOf(from).first;
      final future = _ctx.types.bySpec(CoreTypes.future).instantiate([
        s,
      ], nullable: from.nullable);
      return isAssignable(
            future,
            to,
            forceAllowDynamic: forceAllowDynamic,
            allowDynamicParameterDowncast: allowDynamicParameterDowncast,
          ) &&
          isAssignable(
            s.withNullable(from.nullable || s.nullable),
            to,
            forceAllowDynamic: forceAllowDynamic,
            allowDynamicParameterDowncast: allowDynamicParameterDowncast,
          );
    }

    if (to is InterfaceTypeRef && to.decl.isSpec(AsyncTypes.futureOr)) {
      final s = interfaceArgumentsOf(to).isEmpty
          ? CoreTypes.dynamic.ref(_ctx)
          : interfaceArgumentsOf(to).first;
      final future = _ctx.types.bySpec(CoreTypes.future).instantiate([
        s,
      ], nullable: to.nullable);
      return isAssignable(
            from,
            future,
            forceAllowDynamic: forceAllowDynamic,
            allowDynamicParameterDowncast: allowDynamicParameterDowncast,
          ) ||
          isAssignable(
            from,
            s.withNullable(to.nullable || s.nullable),
            forceAllowDynamic: forceAllowDynamic,
            allowDynamicParameterDowncast: allowDynamicParameterDowncast,
          );
    }
    final generics = overrideGenerics ?? _effectiveTypeArguments(from);
    final targetGenerics = _effectiveTypeArguments(to);

    // Records are structural: `hasSameDeclarationAs` alone would require
    // identical field types. A record is assignable when both sides have
    // the same shape and every field type is assignable positionally/by
    // name.
    if (from is RecordTypeRef && to is RecordTypeRef) {
      if (from.nullable && !to.nullable) return false;
      bool fieldAssignable(TypeRef source, TypeRef target) =>
          isAssignable(source, target, forceAllowDynamic: forceAllowDynamic) ||
          // A `dynamic` field coerces by implicit downcast.
          source.isSpec(CoreTypes.dynamic);
      if (from.positional.length != to.positional.length) return false;
      for (var i = 0; i < from.positional.length; i++) {
        if (!fieldAssignable(from.positional[i], to.positional[i])) {
          return false;
        }
      }
      for (final entry in to.named.entries) {
        final sourceField = from.named[entry.key];
        if (sourceField == null || !fieldAssignable(sourceField, entry.value)) {
          return false;
        }
      }
      return from.named.length == to.named.length;
    }

    // A record's only nominal supertype is Record (itself <: Object), so it
    // is assignable wherever Record is.
    if (from.isRecord) {
      return isAssignable(
        CoreTypes.record.ref(_ctx),
        to,
        forceAllowDynamic: forceAllowDynamic,
      );
    }

    if (from is FunctionTypeRef && to is FunctionTypeRef) {
      return _isFunctionTypeAssignable(
        from,
        to,
        forceAllowDynamic: forceAllowDynamic,
        allowDynamicParameterDowncast: allowDynamicParameterDowncast,
      );
    }

    // The unparameterized `Function` type shares its declaration with every
    // signature — `Function <: int Function()` must not succeed here.
    if (to is FunctionTypeRef && from.isSpec(CoreTypes.function)) {
      return false;
    }

    if (sameDeclaration(from, to) &&
        (!from.nullable || to.nullable || from.isSpec(CoreTypes.nullType))) {
      // Older bridges may omit parameter declarations even when their
      // annotations supply arguments. Compare every argument available;
      // source classes always have their declared defaults above.
      if (generics.isNotEmpty &&
          targetGenerics.isNotEmpty &&
          generics.length != targetGenerics.length) {
        return false;
      }
      for (var i = 0; i < targetGenerics.length && i < generics.length; i++) {
        if (!isAssignable(
          generics[i],
          targetGenerics[i],
          forceAllowDynamic: false,
        )) {
          return false;
        }
      }
      return true;
    }

    // Declaration-space supertypes carry the declaring class's parameter
    // refs — including nested ones (`Divergent<T> implements
    // Future<Divergent<Divergent<T>>>`) — so substitute [from]'s applied
    // arguments throughout each supertype before the recursion.
    final decl = nominalDeclOf(from);
    final supertypes = from.isRecord
        ? const <TypeRef>[]
        : decl?.supertypes.all.toList() ?? const <TypeRef>[];
    final parameters = decl?.typeParameters ?? const <TypeParameterDef>[];
    final substitution = Substitution.of({
      for (var i = 0; i < parameters.length && i < generics.length; i++)
        parameters[i]: generics[i],
    });
    for (final type in supertypes) {
      final instantiated = substitution.isEmpty
          ? type
          : type.substituteTypeParameters(substitution);
      if (isAssignable(instantiated, to, forceAllowDynamic: false)) {
        return true;
      }
    }

    return false;
  }

  List<TypeRef> _effectiveTypeArguments(TypeRef type) => switch (type) {
    InterfaceTypeRef(arguments: [], :final decl) => decl.defaultTypeArguments,
    _ => interfaceArgumentsOf(type),
  };

  /// Structural function-type subtype check, mirroring the runtime's
  /// `isTypedValueType` comparison of signature descriptors. Parameters are
  /// contravariant; a generic target's parameters are renamed onto the
  /// source's so bound references compare as the same variable.
  bool _isFunctionTypeAssignable(
    FunctionTypeRef source,
    FunctionTypeRef target, {
    required bool forceAllowDynamic,
    required bool allowDynamicParameterDowncast,
  }) {
    final sourceSignature = source.signature;
    final targetSignature = target.signature;
    if (sourceSignature.requiredPositional >
            targetSignature.requiredPositional ||
        sourceSignature.positional.length < targetSignature.positional.length) {
      return false;
    }
    if (sourceSignature.typeParameters.length !=
        targetSignature.typeParameters.length) {
      return false;
    }
    final substitutions = Substitution.of({
      for (var i = 0; i < targetSignature.typeParameters.length; i++)
        targetSignature.typeParameters[i]: TypeParameterTypeRef(
          sourceSignature.typeParameters[i],
        ),
    });
    TypeRef renamedTarget(TypeRef type) =>
        type.substituteTypeParameters(substitutions);

    // A type parameter that survives renaming belongs to an enclosing
    // generic context (the callee's `T` in `int Function(T)`), not to the
    // signature — it is a constraint-inference variable, so the component
    // compare can't disprove it during permissive inference. Strict subtype
    // checks must prove compatibility before folding an `is` expression.
    bool hasForeignParameter(TypeRef type) {
      if (type is TypeParameterTypeRef) {
        return !sourceSignature.typeParameters.contains(type.parameter);
      }
      if (type is FunctionTypeRef) {
        final signature = type.signature;
        return signature.positional.any(hasForeignParameter) ||
            signature.named.values.any((p) => hasForeignParameter(p.type)) ||
            hasForeignParameter(signature.returnType);
      }
      if (type is RecordTypeRef) {
        return type.positional.any(hasForeignParameter) ||
            type.named.values.any(hasForeignParameter);
      }
      return interfaceArgumentsOf(type).any(hasForeignParameter);
    }

    // Strict generic function subtyping requires equivalent bounds after
    // alpha-renaming. Otherwise nested function types could make an `is`
    // expression fold to true despite different permitted instantiations.
    if (!forceAllowDynamic && sourceSignature.typeParameters.isNotEmpty) {
      final defaultBound = CoreTypes.object.ref(_ctx).withNullable(true);
      for (var i = 0; i < sourceSignature.typeParameters.length; i++) {
        final sourceBound =
            sourceSignature.typeParameters[i].bound ?? defaultBound;
        final targetBound = renamedTarget(
          targetSignature.typeParameters[i].bound ?? defaultBound,
        );
        if (!isAssignable(sourceBound, targetBound, forceAllowDynamic: false) ||
            !isAssignable(targetBound, sourceBound, forceAllowDynamic: false)) {
          return false;
        }
      }
    }
    // A `void` target accepts any return; `dynamic` satisfies any target.
    // A `void` source return is not permissive (`void() <: int()` fails).
    final targetReturn = renamedTarget(targetSignature.returnType);
    if (!targetReturn.isSpec(CoreTypes.voidType) &&
        !sourceSignature.returnType.isSpec(CoreTypes.dynamic) &&
        !(forceAllowDynamic && hasForeignParameter(targetReturn)) &&
        !isAssignable(
          sourceSignature.returnType,
          targetReturn,
          forceAllowDynamic: forceAllowDynamic,
          allowDynamicParameterDowncast: allowDynamicParameterDowncast,
        )) {
      return false;
    }
    // Contravariant: the target's parameter must be assignable to the
    // source's. A `dynamic` target parameter accepts only a dynamic (or
    // `Object?`) source — matching the runtime's permissive check.
    bool parameterAssignable(TypeRef targetType, TypeRef sourceType) {
      if (targetType.isSpec(CoreTypes.dynamic)) {
        // Assignment additionally permits the implicit `dynamic` downcast.
        return allowDynamicParameterDowncast ||
            sourceType.isSpec(CoreTypes.dynamic) ||
            (sourceType.isSpec(CoreTypes.object) && sourceType.nullable);
      }
      if (forceAllowDynamic && hasForeignParameter(targetType)) return true;
      return isAssignable(
        targetType,
        sourceType,
        forceAllowDynamic: forceAllowDynamic,
        allowDynamicParameterDowncast: allowDynamicParameterDowncast,
      );
    }

    for (var i = 0; i < targetSignature.positional.length; i++) {
      if (!parameterAssignable(
        renamedTarget(targetSignature.positional[i]),
        sourceSignature.positional[i],
      )) {
        return false;
      }
    }
    for (final entry in targetSignature.named.entries) {
      final sourceParameter = sourceSignature.named[entry.key];
      if (sourceParameter == null ||
          (!entry.value.required && sourceParameter.required) ||
          !parameterAssignable(
            renamedTarget(entry.value.type),
            sourceParameter.type,
          )) {
        return false;
      }
    }
    for (final entry in sourceSignature.named.entries) {
      if (entry.value.required &&
          !(targetSignature.named[entry.key]?.required ?? false)) {
        return false;
      }
    }
    return true;
  }

  /// Classifies Dart assignment compatibility of a [from] value into a
  /// [to] slot without conflating `dynamic` with a subtype proof.
  AssignmentConversion assignmentConversion(TypeRef from, TypeRef to) {
    if (to.isSpec(CoreTypes.dynamic) || to.isSpec(CoreTypes.voidType)) {
      return AssignmentConversion.none;
    }
    if (from.isSpec(CoreTypes.dynamic)) {
      if (to.isSpec(CoreTypes.object) && to.nullable) {
        return AssignmentConversion.none;
      }
      return AssignmentConversion.runtimeCheck;
    }
    if (from.nullable &&
        !to.nullable &&
        isAssignable(
          from.withNullable(false),
          to,
          forceAllowDynamic: false,
          allowDynamicParameterDowncast: true,
        )) {
      return AssignmentConversion.runtimeCheck;
    }
    if (from.isSpec(CoreTypes.int) && to.isSpec(CoreTypes.double)) {
      return AssignmentConversion.intToDouble;
    }
    return isAssignable(
          from,
          to,
          forceAllowDynamic: false,
          allowDynamicParameterDowncast: true,
        )
        ? AssignmentConversion.none
        : AssignmentConversion.invalid;
  }
}
