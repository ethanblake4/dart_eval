import 'package:dart_eval/dart_eval_bridge.dart' show CoreTypes;

import '../context.dart';
import '../type.dart';

/// The compiler's type-algebra service. Supertypes live on [TypeDecl], so
/// every algorithm that walks a hierarchy — instantiation views, unification,
/// assignability, least upper bound, runtime supertype ids — funnels through
/// here instead of composing substitutions by hand.
final class TypeSystem {
  TypeSystem(this._ctx);

  final CompilerContext _ctx;

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
    final decl = type.decl;
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
    final decl = type.decl;
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
    final decl = type.decl;
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
      current0 = (current0 as TypeParameterTypeRef).parameter.bound ??
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
      if (identical(current.decl, target)) return current;
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
    Substitution substitutions,
  ) {
    if (pattern.isTypeParameter) {
      substitutions[(pattern as TypeParameterTypeRef).parameter] = concrete;
      return;
    }
    if (!identical(pattern.decl, concrete.decl)) {
      _unifyViaSupertypes(pattern, concrete, substitutions);
      return;
    }
    final args = pattern.typeArguments;
    for (
      var i = 0;
      i < args.length && i < concrete.typeArguments.length;
      i++
    ) {
      unify(args[i], concrete.typeArguments[i], substitutions);
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
    Substitution substitutions,
  ) {
    final queue = <TypeRef>[pattern];
    final seen = <TypeRef>{};
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (!seen.add(current)) continue;
      if (identical(current.decl, concrete.decl)) {
        if (current.typeArguments.isEmpty &&
            !identical(current, pattern) &&
            pattern.typeArguments.length ==
                concrete.typeArguments.length) {
          // The declaring class's supertype is raw; bind `pattern`'s
          // arguments positionally instead.
          final pArgs = pattern.typeArguments;
          for (var i = 0; i < pArgs.length; i++) {
            unify(pArgs[i], concrete.typeArguments[i], substitutions);
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
  Set<int> supertypeIds(TypeRef type) {
    final selfId = _ctx.runtimeTypes.idOf(type);
    final indices = {
      selfId,
      if (type is InterfaceTypeRef)
        _ctx.runtimeTypes.indexMap[type.decl] ?? selfId,
    };
    final seen = {type};
    final worklist = directSupertypes(type);
    while (worklist.isNotEmpty) {
      final supertype = worklist.removeLast();
      if (!seen.add(supertype)) continue;
      final supertypeId = _ctx.runtimeTypes.idOf(supertype);
      indices.add(supertypeId);
      if (supertype is InterfaceTypeRef) {
        indices.add(_ctx.runtimeTypes.indexMap[supertype.decl] ?? supertypeId);
      }
      worklist.addAll(directSupertypes(supertype));
    }
    return indices;
  }

  /// The [type] produced by removing every type-parameter reference —
  /// each parameter replaced by its declared bound (or `dynamic` when
  /// unbounded). Callers use this when a type leaves the scope that gave
  /// those parameters meaning — an unconstrained `T` is not a usable type
  /// for the caller.
  TypeRef lowerTypeParameters(TypeRef type) {
    final substitutions = Substitution.wrap(<TypeParameterDef, TypeRef>{});
    void collect(TypeRef t) {
      if (t.isTypeParameter) {
        final parameter = (t as TypeParameterTypeRef).parameter;
        substitutions.bindings.putIfAbsent(
          parameter,
          () => parameter.bound ?? CoreTypes.dynamic.ref(_ctx),
        );
        return;
      }
      for (final argument in t.typeArguments) {
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
    return substitutions.isEmpty
        ? type
        : type.substituteTypeParameters(substitutions);
  }

  /// Fully unwraps a type-parameter chain (`T extends U, U extends C`) to
  /// the outermost non-parameter bound, or `dynamic` when unbounded.
  TypeRef throughTypeParameters(TypeRef type) {
    var t = type;
    final seen = <TypeRef>{};
    while (t.isTypeParameter && seen.add(t)) {
      final bound = (t as TypeParameterTypeRef).parameter.bound;
      if (bound == null) {
        return CoreTypes.dynamic.ref(_ctx);
      }
      t = bound;
    }
    return t;
  }

  /// The `flatten` function from the async spec: the value type `T` such
  /// that `await`/`async` treat a `FutureOr<T>`/`Future<T>`-shaped value as
  /// `T`. `FutureOr` peels to its argument; a type implementing `Future<S>`
  /// peels to `S`, recursively. Self-referential futures
  /// (`F implements Future<F>`) return themselves.
  TypeRef flatten(TypeRef type) {
    var t = type;
    var nullable = type.nullable;
    final seen = <TypeRef>{};
    final futureDecl = _ctx.types.bySpec(CoreTypes.future);
    while (seen.add(t)) {
      if (t.name == 'FutureOr' && t.typeArguments.isNotEmpty) {
        nullable = nullable || t.nullable;
        t = t.typeArguments.first;
        continue;
      }
      final instantiation = asInstanceOf(t, futureDecl);
      if (instantiation == null) {
        return t.copyWith(nullable: t.nullable || nullable);
      }
      nullable = nullable || t.nullable;
      t = instantiation.typeArguments.isEmpty
          ? CoreTypes.dynamic.ref(_ctx)
          : instantiation.typeArguments.first;
    }
    return t.copyWith(nullable: t.nullable || nullable);
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
      final decl = current.decl;
      final classDef = decl is BridgeTypeDecl ? decl.classDef : null;
      if (classDef != null) {
        final names = classDef.type.generics.keys.toList();
        final index = names.indexOf(paramName);
        if (index < 0) continue;
        if (index < current.typeArguments.length) {
          return current.typeArguments[index];
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

  /// Given a set of [types], find their closest common ancestor type —
  /// every type's declaration-shaped chain (extends above interfaces above
  /// mixins, in declaration order) contributing to a layer-frequency pick,
  /// with assignability breaking the shallowest layer's ties.
  TypeRef leastUpperBound(Set<TypeRef> types) {
    assert(types.isNotEmpty);
    var makeNullable = types.remove(CoreTypes.nullType.ref(_ctx));
    if (types.isEmpty) {
      return CoreTypes.nullType.ref(_ctx);
    }
    if (types.length == 1) {
      return makeNullable ? types.first.copyWith(nullable: true) : types.first;
    }
    final chains = types.map(_typeChain).toList();

    // Cross-level type deduplication
    for (final chain in chains) {
      final typeSet = <TypeRef>{};
      for (final typeList in chain) {
        for (final type in [...typeList]) {
          if (!typeSet.contains(type)) {
            typeSet.add(type);
          } else {
            typeList.remove(type);
          }
        }
      }
    }

    // Count common supertypes by declaration (A.4): `List<int>` and
    // `List<String>` must meet at `List`. Decl-less types (records, type
    // parameters) key themselves — the legacy nominal identity.
    final refCount = <Object, int>{};
    final layer = <Object, int>{};
    final firstSeen = <Object, TypeRef>{};
    var i = 0;

    var passes = 0;
    t:
    while (true) {
      for (final chain in chains) {
        if (i > chain.length - 1) {
          passes++;
          if (passes > chains.length - 1) {
            break t;
          }
          continue;
        }
        final types0 = chain[i];
        for (final type in types0) {
          final key = type.decl ?? type;
          if (refCount[key] == null) {
            refCount[key] = 1;
            layer[key] = i;
            firstSeen[key] = type;
          } else {
            refCount[key] = refCount[key]! + 1;
            layer[key] = layer[key]! + i;
          }
        }
      }
      passes = 0;
      i++;
    }

    refCount.removeWhere((key, value) => value < types.length);

    final sorted = refCount.keys.toList()
      ..sort((k1, k2) => layer[k1]! - layer[k2]!);
    if (sorted.isEmpty) {
      return CoreTypes.dynamic.ref(_ctx).copyWith(nullable: makeNullable);
    }
    // Among the shallowest common supertypes, pick the one that is a subtype
    // of all the others (e.g. `num` over `Object`). When several are
    // incomparable (a class `implements B1, B2` with both shared), pick the
    // last inserted — `_typeChain` walks interfaces in reverse, so the last
    // candidate is the first-declared interface.
    final minLayer = layer[sorted[0]]!;
    final candidates = sorted
        .where((t) => layer[t] == minLayer)
        .toList(growable: false);
    final best = candidates.firstWhere(
      (c) => candidates.every(
        (o) => c == o ||
            isAssignable(firstSeen[c]!, firstSeen[o]!, forceAllowDynamic: false),
      ),
      orElse: () => candidates.last,
    );
    final bestType = firstSeen[best]!;
    return bestType.copyWith(nullable: bestType.nullable || makeNullable);
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
  }) {
    if (to.isSpec(CoreTypes.dynamic) ||
        to.isSpec(CoreTypes.voidType) ||
        (forceAllowDynamic && from.isSpec(CoreTypes.dynamic))) {
      return true;
    }

    if (from.isSpec(CoreTypes.never)) {
      // `Never` is the bottom type: assignable to every type.
      return true;
    }
    if (from.isSpec(CoreTypes.nullType)) {
      return to.nullable || to.isSpec(CoreTypes.nullType);
    }
    if (from.nullable && !to.nullable) return false;

    if (from.isTypeParameter) {
      // Same parameter — the nullability gate above already handled the
      // `E` → `E?` direction; `==` would also reject it on nullability.
      if (from is TypeParameterTypeRef &&
          to is TypeParameterTypeRef &&
          from.parameter == to.parameter) {
        return true;
      }
      // A type parameter is assignable to [to] iff its declared bound is.
      // An unbounded parameter (`<T>`) has the implicit bound `Object?`.
      return isAssignable(
        (from as TypeParameterTypeRef).parameter.bound ??
            CoreTypes.object.ref(_ctx).copyWith(nullable: true),
        to,
        forceAllowDynamic: forceAllowDynamic,
      );
    }

    final generics = overrideGenerics ?? from.typeArguments;

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
        if (sourceField == null ||
            !fieldAssignable(sourceField, entry.value)) {
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

    if (sameDeclaration(from, to) &&
        (!from.nullable || to.nullable || from.isSpec(CoreTypes.nullType))) {
      if (to.typeArguments.isNotEmpty &&
          generics.isNotEmpty &&
          generics.length != to.typeArguments.length) {
        return false;
      }
      // A raw generic (`Future` for `Future<C>`) acts like
      // `Future<dynamic>`: its missing arguments are assignable both ways.
      for (
        var i = 0;
        i < to.typeArguments.length && i < generics.length;
        i++
      ) {
        if (!isAssignable(
          generics[i],
          to.typeArguments[i],
          forceAllowDynamic: false,
        )) {
          return false;
        }
      }
      return true;
    }

    // Declaration-space supertypes carry the declaring class's parameter
    // refs (`List<E> extends Iterable<E>`); `inheritedGenerics` rebinds them
    // to [from]'s applied arguments for the recursion.
    final supertypes = from.isRecord
        ? const <TypeRef>[]
        : from.decl?.supertypes.all.toList() ?? const <TypeRef>[];
    for (final type in supertypes) {
      final inheritedGenerics = type.typeArguments.isEmpty
          ? generics
          : [
              for (final argument in type.typeArguments)
                if (argument is TypeParameterTypeRef &&
                    argument.parameter.index < generics.length)
                  generics[argument.parameter.index].copyWith(
                    nullable:
                        argument.nullable ||
                        generics[argument.parameter.index].nullable,
                  )
                else
                  argument,
            ];
      if (isAssignable(
        type,
        to,
        overrideGenerics: inheritedGenerics,
        forceAllowDynamic: false,
      )) {
        return true;
      }
    }

    return false;
  }

  /// Classifies Dart assignment compatibility of a [from] value into a
  /// [to] slot without conflating `dynamic` with a subtype proof.
  AssignmentConversion assignmentConversion(TypeRef from, TypeRef to) {
    final dynamicType = CoreTypes.dynamic.ref(_ctx);
    if (to == dynamicType || to.isSpec(CoreTypes.voidType)) {
      return AssignmentConversion.none;
    }
    if (from == dynamicType) {
      if (to.isSpec(CoreTypes.object) && to.nullable) {
        return AssignmentConversion.none;
      }
      return AssignmentConversion.runtimeCheck;
    }
    if (from.nullable &&
        !to.nullable &&
        isAssignable(
          from.copyWith(nullable: false),
          to,
          forceAllowDynamic: false,
        )) {
      return AssignmentConversion.runtimeCheck;
    }
    if (from.isSpec(CoreTypes.int) && to.isSpec(CoreTypes.double)) {
      return AssignmentConversion.intToDouble;
    }
    return isAssignable(from, to, forceAllowDynamic: false)
        ? AssignmentConversion.none
        : AssignmentConversion.invalid;
  }
}
