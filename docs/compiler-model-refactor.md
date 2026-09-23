# Compiler model refactor plan

This plan refactors the compiler's type, declaration, value, and invocation models so that each compiler decision has exactly one owner. It is based on `53751b1` (sdk_language checkpoint 39), inspected on September 22, 2026. It is a plan only; no compiler or runtime code has changed.

The work is structural. Phases 0–6 preserve observable behavior; the bugs the new model exposes are fixed in phase 7 as separate, deliberate commits. The runtime, IR operations, bytecode format, and Program envelope/payload versions do not change.

## Decisions recorded

- Keep the name `TypeRef` for the new sealed base class. About a thousand use sites reference it, and the rename buys nothing structural.
- Phases 0–6 are behavior-preserving. An incidental fix that falls out of the new model is acceptable only when it is understood, covered by a test, and called out in its commit (including any `suite.yaml` change). Deliberate semantic changes wait for phase 7.
- Order: boxing → declarations → type values → members → values and bindings → invocation → semantic fixes.
- Compile-time performance is not a primary constraint. Prefer clarity (no interning or hash-consing); still measure `benchmark/compile.dart` to catch pathological regressions.
- Nominal checks against bridge specs are spelled `isSpec(BridgeTypeSpec)`, not `isCore`. `CoreTypes` is only the `dart:core` spec table; the compiler also references `AsyncTypes`, `CollectionTypes`, `ConvertTypes`, and user bridge specs.

## Goals and non-goals

Goals:

1. `TypeRef` becomes a sealed hierarchy of immutable type values with a single equality.
2. Nominal information (supertypes, type parameters, members) moves to declaration objects. The source-versus-bridge split lives in one place instead of in `isBridge` branches throughout the compiler.
3. Boxing leaves the type model. Values carry their representation; slots (parameters, results, fields, globals) get theirs from one ABI table.
4. `Variable` becomes an SSA value. Binding identity, binding storage, and name denotation move out.
5. Invocation becomes one pipeline — resolve the target, bind arguments, emit IR — shared by method calls, operators, index operators, constructors, closures, extensions, super calls, and accessors.

Non-goals:

- No runtime, IR, or serialized-format changes. `TypedClosure`, `typed_dispatch.dart`, runtime type descriptors, and `MachineFunctionSignature` stay as they are.
- No rewrite of the declaration indexing pass in `compiler.dart`. The existing maps (`topLevelDeclarationsMap`, `instanceDeclarationsMap`, `instanceDeclarationPositions`, `visibleDeclarations`) remain the backing store; new objects are views over them.
- No new language features outside phase 7.

## Current state

All paths below are relative to `lib/src/eval/compiler/` unless stated otherwise.

### Types

`TypeRef` (`type.dart`) has 15 fields covering interface types, type parameters (`typeParameterOwner/Index/Bound`), records (`recordFields`, a `@record<...>` name, `file: -1`), function types (`functionType` attached to a `Function` ref), a lazy resolution state (`resolved`), declaration data (`extendsType`, `implementsType`, `withType`, `genericParams`), and machine data (`boxed`). Invalid states are representable: `_extensionMethodTearOff` in `variable.dart` builds a type-parameter ref with an owner but no index, which `isTypeParameter` then treats as a class named after the parameter.

There are four equalities:

| Operation | Meaning today |
| --- | --- |
| `operator ==` | Declaration identity (file and name, or type-parameter owner and index). Ignores nullability, type arguments, record fields, and function signatures. |
| `hasSameDeclarationAs` | The same as `==`, minus the `runtimeType` check. |
| `isSameSemanticType` | Deep equality after resolving both sides. |
| `semanticKey` | A string key used for runtime descriptor ids and cycle detection. |

About 115 sites compare `== CoreTypes.x.ref(ctx)` or `!= ...` and rely on `==` ignoring nullability; `helpers/invoke.dart` has a comment working around this. Because structural function types are `Function` refs carrying a signature, `t == CoreTypes.function.ref(ctx)` is true for every function type.

Supertype walking is reimplemented about eleven times, each composing `Map<(String, int), TypeRef>` substitutions by hand: `instantiatedSupertypeView`, `findSupertypeInstantiation`, `_collectViaSupertypes`, `bridgedTypeArgument`, `classTypeArguments`, `_bridgeClassTypeArguments`, `getTypeChain`, `getRuntimeIndices`, `inheritTypeArgsFrom`, the substitution chain inside `lookupFieldType`, and `_memberReturnAnnotation`, plus the `hostBindings` logic in `resolveInstanceDeclaration`. There are 84 `resolveTypeChain` calls, because any `TypeRef` may be unresolved. Resolved chains are cached in an `Expando` keyed by context and written back into `visibleTypes`.

Type-parameter owners are strings in nine formats (`class:`, `function:`, `method:`, `call:`, `tearoff:`, `extension:`, `typeAlias:`, `functionType:`, `functionTypedParam:`). `runtimeDescriptor` parses the `class:` format with `split(':')` to find the owner type. `ctx.temporaryTypes` is mutated with manual save/restore in about a dozen files. `dartCoreFile` and `unboxedAcrossFunctionBoundaries` are process-global mutable state set during compilation.

### Declarations and members

Member lookup has about fifteen entry points with different walk orders: `resolveInstanceMethod`, `_tryResolveInstanceMethod`, `hasInstanceMethod`, `resolveStaticMethod`, `resolveInstanceDeclaration`, `resolveStaticDeclaration`, `resolveScopedStaticDeclaration`, `TypeRef.lookupFieldType`, `memberOwner`, `directMemberOwner`, `concreteMemberDecl`, `superMixinMemberOwner`, the walks in `_resolveSuperReceiver` and `SuperPropertyReference._owner`, and `AlwaysReturnType.fromInstanceMethod/fromStaticMethod/fromInstanceMethodOrBuiltin`. Nearly all of them branch on `isBridge`. Member keys (`name*g`, `name*s`, `lib::_name`, `unary-`) are formatted by hand at each site.

### Boxing

Boxing is stored twice: in `TypeRef.boxed` and in `Variable.representation`. `boxIfNeeded` has a special case for values that are physically unboxed under an `Object`/`dynamic` type. For collections, "unboxed" means a native Dart `List`/`Map`/`Set` rather than the `$List`/`$Map`/`$Set` wrapper; both live in the object register bank, so `MachineRepresentation` alone cannot replace the flag. An unboxed `Null` is a raw `null` (`LoadNull`) rather than `$null`.

The rules for which parameters and results may be unboxed are re-derived in six places:

| Site | Rule |
| --- | --- |
| `declaration/function.dart` | Parameters use `typeAcrossFunctionBoundary`; the result is unboxed when non-async and unboxable; `void` has no result. |
| `declaration/method.dart` | Parameters are always boxed. The result is boxed, except an expression-bodied, non-async `==`/`!=` returning `bool`. |
| `declaration/constructor.dart` | Regular parameters use set membership in `unboxedAcrossFunctionBoundaries` (which ignores nullability, relying on `representationForType` to box `int?`). Field and super formals use `typeAcrossFunctionBoundary`. Generative constructors take a trailing integer runtime type id. |
| `expression/function.dart` | Closure parameters and results are always boxed. |
| `helpers/argument_list.dart` | `coerceArgumentForParameter` and `compileOmittedArgument` repeat the function/method/generic-parameter rule. |
| `expression/method_invocation.dart` | Result boxing is recomputed per call (`genericReturnBoxed`, `boxedBySubstitution`, `isUnboxedAcrossFunctionBoundaries`). |

### Variable

`Variable` (`variable.dart`) has 19 fields:

| Group | Fields |
| --- | --- |
| SSA value | `name` (the SSA), `type`, `representation` |
| Allocation facts | `exactType`, `concreteTypes` |
| Constant facts | `isConst`, `isConstInt` |
| Binding identity | `localName`, `frameIndex`, `declaredType`, `isFinal` |
| Binding storage | `captureCell`, `exceptionSlot`, `captureCellSlot` |
| Name denotation | `methodOffset`, `methodReturnType`, `callingConvention`, `implicitReceiver`, `boundExtension` |

A `Variable` with `name == null` and a `methodOffset` is an unmaterialized function reference. `concreteTypes` means at least four different things: possible runtime classes (devirtualization), the type denoted by a `Type` literal, the return type of a function reference (`_declarationToVariable`), and a type parameter evaluated as a value. Facts leak through `copyWith` onto reassigned copies (`null_aware.dart` notes this), and final-variable enforcement in `IdentifierReference.setValue` is gated on `local.concreteTypes.isNotEmpty`. `lookupLocal` mutates the returned variable's `localName`/`frameIndex`.

### Names

The name-resolution cascade is written four times, in `IdentifierReference.resolveType`, `getValue`, `setValue`, and `getStaticDispatch`, with different orders. For example, `resolveType` consults inherited instance fields before globals, while `getValue` consults only members the enclosing class declares before globals. Import prefixes are signaled by throwing `PrefixError`. `DeferredOrOffset.targetName` carries a receiver's SSA name as a string for method tear-offs.

### Invocation

There are several independent invocation paths:

- `compileMethodInvocation`/`_invokeWithTarget` in `expression/method_invocation.dart` (2,106 lines) do typed binding and devirtualization.
- `Variable.invoke` in `helpers/invoke.dart` handles every binary/unary operator and `[]`/`[]=`: intrinsics, then extensions, then untyped `InvokeDynamic`. User-defined operators never get parameter coercion or devirtualization, so `a.plus(b)` and `a + b` compile differently.
- `invokeClosure` in `helpers/closure.dart`.
- Constructors in `compileInstanceOf` (`instance_creation.dart`), in the implicit-`new` path of `compileMethodInvocation`, and in `dot_shorthand.dart`, plus super-constructor calls in `declaration/constructor.dart` and enum constants in `declaration/enum.dart`.
- Accessors in `Variable.getProperty` and `IdentifierReference.setValue`, each with its own copy of the devirtualization logic.

There are six argument compilers: `compileArgumentList`, `compileArgumentListWithBridge`, `compileArgumentListWithDynamic`, `compileSuperParams`, `compileSuperParamsWithBridge`, and `compileNonBridgeArgs`, plus inline binding in `Variable.invoke`'s extension path and `_compileCallArgs`. There are two type-argument inference strategies: source calls infer only from bare `T` parameter annotations; bridge calls recurse into type arguments and generic function returns.

### Confirmed bugs

These were reproduced with `eval()` on this commit. All three come from binding by iterating the static declaration's formals instead of the call's arguments.

| Program | Dart | dart_eval |
| --- | --- | --- |
| `A a = B(); a.m()` where `B.m([x = 2])` overrides `A.m([x = 1])` | uses `x = 2` | uses `x = 1` (defaults come from the static type) |
| The same call through a `dynamic` receiver | uses `x = 2` | uses `x = 2` (the runtime binds defaults correctly) |
| `f(t('p'), b: t('b'), a: t('a'))` with `f(p, {a, b})` | logs `pba` | logs `pab` (named arguments evaluate in declaration order) |
| `f(b: t('b'), t('p'), a: t('a'))` | valid | CompileError: "Not enough positional arguments" |

## Design rules

1. One owner per decision:

   | Decision | Owner |
   | --- | --- |
   | What kind of type something is | sealed `TypeRef` subclasses |
   | Supertypes and type parameters of a declaration | `TypeDecl` |
   | Source versus bridge | `SourceTypeDecl`/`BridgeTypeDecl`, `SourceMember`/`BridgeMember` |
   | Where a member is found | `MemberLookup` |
   | How a value is represented | `Variable.rep` |
   | How a slot is represented | `Abi`/`CallableAbi` |
   | What a name refers to | `Denotation` |
   | Local identity and storage | `LocalBinding` |
   | What is called | `CallResolver` → `CallTarget` |
   | How arguments are laid out | `ArgumentBinder` + `BindingPolicy` |
   | How fast it is called | `Devirtualizer`, `Intrinsics` |
   | Which IR is produced | `CallTarget` emission |

2. Use sealed classes and `switch`. No visitors, no mixin taxonomies.
3. Declaration kind is data. Origin (source or bridge) is the only subclass axis for declarations and members.
4. Keep call-site shapes where cheap and move the implementation: `spec.ref(ctx)` and `a.isAssignableTo(ctx, b)` can stay as extension methods delegating to the new services.
5. Each phase deletes what it replaces. Compatibility switches that preserve old behavior are listed explicitly and removed in phase 7.
6. During migration, run old and new logic side by side under `assert` ("shadow mode") and fail on disagreement, then delete the old logic.

## Part A: Types

### A.1 The type hierarchy

```dart
sealed class TypeRef {
  const TypeRef({required this.nullable});

  final bool nullable;

  TypeRef withNullable(bool nullable);
  TypeRef substitute(Substitution substitution);

  /// Declaration identity against any bridge spec (`CoreTypes`, `AsyncTypes`,
  /// `CollectionTypes`, user specs). Ignores nullability and type arguments,
  /// exactly like today's `== spec.ref(ctx)`.
  bool isSpec(BridgeTypeSpec spec) => false;

  bool get isDynamic => isSpec(CoreTypes.dynamic);
  bool get isVoid => isSpec(CoreTypes.voidType);
  bool get isNever => isSpec(CoreTypes.never);
  bool get isNullType => isSpec(CoreTypes.nullType);

  String get displayName;

  @override
  String toString() => displayName;
}

final class InterfaceTypeRef extends TypeRef {
  InterfaceTypeRef(this.decl, {this.arguments = const [], super.nullable = false});

  final TypeDecl decl;

  /// Empty means a raw use, exactly as today (`Future` acts as
  /// `Future<dynamic>` in both directions of assignability).
  final List<TypeRef> arguments;

  @override
  bool isSpec(BridgeTypeSpec spec) => decl.isSpec(spec);
}

final class TypeParameterTypeRef extends TypeRef {
  TypeParameterTypeRef(this.parameter, {super.nullable = false});
  final TypeParameterDef parameter;
}

final class FunctionTypeRef extends TypeRef {
  FunctionTypeRef(this.signature, {super.nullable = false});
  final FunctionSignature signature;

  /// Migration compatibility: function types are `Function` refs today, so
  /// `isSpec(CoreTypes.function)` must hold until every such check is
  /// audited in phase 3.
  @override
  bool isSpec(BridgeTypeSpec spec) =>
      spec.name == 'Function' && spec.library == 'dart:core';
}

final class RecordTypeRef extends TypeRef {
  RecordTypeRef(this.positional, Map<String, TypeRef> named, {super.nullable = false})
    : named = _sortedByName(named);

  final List<TypeRef> positional;
  final Map<String, TypeRef> named; // canonical name order
}

final class FunctionSignature {
  const FunctionSignature({
    this.typeParameters = const [],
    required this.positional,
    required this.requiredPositional,
    this.named = const {},
    required this.returnType,
  });

  final List<TypeParameterDef> typeParameters;
  final List<TypeRef> positional;
  final int requiredPositional;
  final Map<String, ({TypeRef type, bool required})> named;
  final TypeRef returnType;
}
```

`dynamic`, `void`, `Never`, `Null`, `Object`, `Function`, and `Record` remain `InterfaceTypeRef`s over their `dart:core` declarations. Dedicated subclasses would force a rewrite of every check for little gain. `isSpec` compares `library` and `name` strings; add an `identical` fast path for the canonical `const` specs if profiling ever shows it matters.

Field mapping from today's `TypeRef`:

| Field | Destination |
| --- | --- |
| `file`, `name` | `InterfaceTypeRef.decl` (`TypeDecl.library`, `TypeDecl.name`); `displayName` |
| `specifiedTypeArgs` | `InterfaceTypeRef.arguments` |
| `extendsType`, `implementsType`, `withType`, `genericParams`, `resolved` | `TypeDecl` (A.8) |
| `recordFields` | `RecordTypeRef.positional`/`named` |
| `functionType` | `FunctionTypeRef.signature` |
| `typeParameterOwner`, `typeParameterIndex`, `typeParameterBound` | `TypeParameterTypeRef.parameter` |
| `boxed` | removed (Part C) |
| `nullable` | `TypeRef.nullable` |

During phase 3, the base class may temporarily expose a deprecated `typeArguments` getter returning `const []` for non-interface types, so the 177 `specifiedTypeArgs` uses can migrate file by file. Remove it at the end of phase 3.

### A.2 Type parameters

```dart
enum TypeParameterOwnerKind {
  classLike, function, method, closure, tearOff, callSite, extension,
  typeAlias, functionTypeAnnotation, functionTypedParameter, scope,
}

final class TypeParameterOwner {
  const TypeParameterOwner(this.kind, this.library, this.name, [this.position]);

  final TypeParameterOwnerKind kind;
  final int library;
  final String name;
  final int? position;

  bool get isClassLike => kind == TypeParameterOwnerKind.classLike;
  // value equality over all four fields
}

final class TypeParameterDef {
  TypeParameterDef(this.owner, this.index, this.name);

  final TypeParameterOwner owner;
  final int index;
  final String name;

  /// Set exactly once, after every parameter of [owner] exists, so bounds
  /// may reference any parameter of the same owner (`T extends Foo<T>`,
  /// `T extends U, U extends C`). Null means unbounded, as today.
  TypeRef? get bound => _bound;
  set bound(TypeRef? value) { assert(!_boundSet); _bound = value; _boundSet = true; }

  // == and hashCode: (owner, index) only — never the bound, so F-bounds
  // cannot create equality cycles.
}
```

Each string format maps to one kind with the same key fields, so today's distinctions (for example, a method's `T` seen from its body, from a tear-off, and from a call site are different owners) are preserved exactly:

| Today | Kind | Fields |
| --- | --- | --- |
| `class:$file:$name` | `classLike` | file, class name |
| `function:$lib:$name:$pos` | `function` | lib, name, pos |
| `method:$lib:$Class.$method:$pos` | `method` | lib, `Class.method`, pos |
| `function:$lib:<anonymous>:$offset` | `closure` | lib, `<anonymous>`, offset |
| `function:${currentFunctionId ?? -1}` (default in `loadTemporaryTypes`) | `scope` | -1, `''`, function id |
| `call:$lib` | `callSite` | lib |
| `tearoff:$file:$name` | `tearOff` | file, name |
| `extension:$lib:$name` | `extension` | lib, name |
| `typeAlias:$lib:$name` | `typeAlias` | lib, name |
| `functionType:$lib:$offset` | `functionTypeAnnotation` | lib, offset |
| `functionTypedParam:$lib:$offset` | `functionTypedParameter` | lib, offset |

`callSite` owners are shared by every generic callee in a library today. Preserve that in phases 0–6 and note it as a hazard; phase 6's binder replaces call-site placeholders with the callee's own `TypeParameterDef`s.

Declaring parameters becomes one helper that replaces the two- and three-pass seeding in `loadTemporaryTypes`, `_resolveInvocationGenerics`, `EvalFunctionType.fromParts`, `_resolveTypeAlias`, and `classTypeParameterRefs`:

```dart
List<TypeParameterDef> declareTypeParameters(
  TypeParameterOwner owner,
  List<TypeParameter> nodes,
  TypeRef Function(TypeAnnotation bound, TypeScope scope) resolveBound,
);
```

Every def is created first, the scope is extended with all of them, and then bounds are resolved. Because defs are shared objects, a bound naming a later parameter sees that parameter's bound once it is set; the re-resolution pass disappears.

The runtime descriptor for a type parameter uses `owner.isClassLike` and looks the owner declaration up in the registry instead of parsing a string.

### A.3 Substitution

```dart
final class Substitution {
  const Substitution._(this._bindings);
  static const empty = Substitution._({});

  factory Substitution.of(Map<TypeParameterDef, TypeRef> bindings);

  /// The declaration's parameters mapped to [type]'s arguments. Missing
  /// arguments use the bound, or `dynamic` when unbounded — the rule
  /// `appliedTypeArguments` applies today.
  factory Substitution.forInterface(InterfaceTypeRef type);

  final Map<TypeParameterDef, TypeRef> _bindings;

  TypeRef? operator [](TypeParameterDef parameter);
  bool get isEmpty;

  /// Bindings of [other] win.
  Substitution extend(Substitution other);

  /// Applies [outer] to every binding: composition along a supertype path.
  Substitution then(Substitution outer);
}
```

Application keeps today's nullability rule: substituting `S` for `T?` produces `S` made nullable if either side is nullable. `substitute` on `FunctionTypeRef` does not substitute the signature's own `typeParameters`.

### A.4 Equality, hashing, and spec checks

After phase 3, `==` and `hashCode` are structural and include nullability:

- `InterfaceTypeRef`: identical `decl`, same nullability, pairwise-equal arguments.
- `TypeParameterTypeRef`: equal `parameter`, same nullability.
- `RecordTypeRef`: equal positional list, equal canonical named map, same nullability.
- `FunctionTypeRef`: equal signatures (positional parameter names are not part of the type, as today), same nullability. Two separately parsed generic function types have different owners and so are not equal; this matches today's `semanticKey`. Alpha-equivalence can come later.

Hash codes are memoized with `@override late final int hashCode = ...`.

Nominal checks use `isSpec(spec)` against a spec, or `sameDeclaration(a, b)` between two types. `semanticKey` is deleted; runtime type ids are keyed by the type value.

Migration of the four equalities:

| Today | After |
| --- | --- |
| `t == CoreTypes.x.ref(ctx)` / `!=` | `t.isSpec(CoreTypes.x)` / `!t.isSpec(...)` (phase 2, identical semantics) |
| `a == b` between two non-spec types | audited per site: `sameDeclaration` or structural `==` |
| `hasSameDeclarationAs` | `sameDeclaration` |
| `isSameSemanticType` | `==` |
| `semanticKey` | the type itself as a map key |

Every collection keyed by `TypeRef` changes meaning when `==` flips, so each must be audited in phase 3:

| Collection | Required keying |
| --- | --- |
| `ctx.typeRefIndexMap` (`context.dart`) | by `TypeDecl` — it maps declarations to type-table indices |
| `unboxedAcrossFunctionBoundaries` (`builtins.dart`) | deleted in phase 1 (replaced by `Abi`) |
| `ParameterTypeDependentReturnType.map` (`type.dart`) | by declaration — bridge overloads match nominally |
| `refCount`/`layer` in `TypeRef.commonBaseType` | by declaration, to keep today's least-upper-bound results (`List<int>` and `List<String>` share `List`) |
| `Set<TypeRef>` inputs to `commonBaseType`: `resolveGenericsMap` (`argument_list.dart`), `set_map.dart` `infer`, `global.dart` `_elementTypes`, `model/label.dart` `types`, list literal result types | deduplicate nominally, or accept structural deduplication with a test: `{int, int?}` currently collapses to whichever was inserted first |
| `stack` sets in `resolveTypeChain`, `_TypeRefCache.visibleLibraries` | deleted in phase 2 |

### A.5 Function types

- `EvalFunctionType`, `FunctionTypeAnnotation` (including its unresolved `name` form for bridge generics), `FunctionFormalParameter`, and `FunctionGenericParam` are replaced by `FunctionSignature`. Unresolved bridge generic names become `TypeParameterTypeRef`s owned by the function type.
- `declaredFunctionType` in `model/function_type.dart` keeps returning bare `Function` for generic callables during phases 3–6. Runtime type descriptors and tear-off `runtimeTypeId`s depend on it; the change is a phase 7 item.
- `FunctionTypeRef.isSpec(CoreTypes.function)` is true until every `Function` check is classified as `isBareFunction` (an `InterfaceTypeRef` of `Function`) or `isFunctionLike` (either form). Remove the compatibility override at the end of phase 3.

### A.6 Record types

- `RecordTypeRef` replaces the `@record<...>` name, `file: -1`, and `isRecord`. `recordTypeName` survives only as `displayName`.
- The nominal supertype of every record is `Record`. Member lookup and assignability route through it, as `lookupFieldType` and `isAssignableTo` do today.
- Today `hasSameDeclarationAs` compares record names built from field display names, so `(A,)` from two libraries that each declare a different `A` compare equal. Structural equality fixes this incidentally; if the suite changes, record it under the incidental-fix policy.

### A.7 Raw types

`arguments.isEmpty` keeps meaning a raw use throughout phases 0–6. Normalizing raw uses to instantiate-to-bounds would change assignability and inference and belongs in phase 7, if at all.

### A.8 Declarations: `TypeDecl`

```dart
enum TypeDeclKind { classDecl, mixin, enumDecl, classAlias, bridgeClass, bridgeEnum }

sealed class TypeDecl {
  TypeDecl(this.library, this.libraryUri, this.name);

  final int library;
  final String libraryUri;
  final String name;

  TypeDeclKind get kind;
  BridgeTypeSpec get spec => BridgeTypeSpec(libraryUri, name);
  bool isSpec(BridgeTypeSpec s) => name == s.name && libraryUri == s.library;

  late final List<TypeParameterDef> typeParameters = computeTypeParameters();
  late final DeclaredSupertypes supertypes = _guarded(computeSupertypes);

  /// `C<T0, ..., Tn>` over its own parameters — what `TypeRef.$this` builds.
  late final InterfaceTypeRef thisType = ...;
  InterfaceTypeRef get rawType; // no arguments, as `spec.ref(ctx)` returns today
  InterfaceTypeRef instantiate(List<TypeRef> arguments, {bool nullable = false});

  /// A bridged class whose instances are host objects (`BridgeClassDef.bridge`);
  /// used by `hasBridgeSuperclass`.
  bool get isHostBridged;

  Member? declaredMember(MemberName name);          // own instance members only
  Member? staticMember(String name, MemberKind kind);
  Member? constructor(String name);                 // '' for the unnamed one
}

final class SourceTypeDecl extends TypeDecl {
  final Declaration node; // ClassDeclaration, MixinDeclaration, EnumDeclaration, ClassTypeAlias
}

final class BridgeTypeDecl extends TypeDecl {
  final BridgeClassDef? classDef;
  final BridgeEnumDef? enumDef;
}

final class DeclaredSupertypes {
  const DeclaredSupertypes(this.superclass, this.interfaces, this.mixins);

  final InterfaceTypeRef? superclass; // in this declaration's own parameter space
  final List<InterfaceTypeRef> interfaces;
  final List<InterfaceTypeRef> mixins; // arguments already inferred

  /// Today's `allSupertypes` order: extends, implements, with.
  Iterable<InterfaceTypeRef> get all => [?superclass, ...interfaces, ...mixins];
}
```

Implementation notes:

- `computeSupertypes` moves the body of `resolveTypeChain` onto the declaration. It includes `classLikeClauses`, alias expansion in clauses, prefixed clause names, the bridge `$extends`/`$implements`/`$with` handling with parameterized `ownTypeParams`, mixin-application inference (`with M` where `M<T> on I<T>`), enums extending `Enum`, the default `Object` superclass, and `Null` extending `Object?`.
- `_guarded` detects cyclic hierarchies with an "in progress" flag and throws the same `CompileError` the current 500-step recursion guard throws.
- `TypeDeclRegistry` on the context replaces `_TypeRefCache` and `TypeRef.cache`:

  ```dart
  final class TypeDeclRegistry {
    TypeDecl? find(int library, String name);    // backed by topLevelDeclarationsMap
    TypeDecl bySpec(BridgeTypeSpec spec);         // backed by libraryMap + visible types
    TypeDecl? visible(int library, String name);  // keys include 'prefix.Name'
  }
  ```

  Declarations are created in `Compiler._cacheTypeRef`, where `TypeRef.cache` runs today. Runtime type ids must be registered in the same order, or program output changes.
- `visibleTypes` values become `TypeDecl`s (or their raw types) and are never written back after the declaration pass.
- `Refify.ref(ctx, typeArgs)` keeps its signature and becomes `ctx.types.bySpec(this).instantiate(...)`. The `dartCoreFile` side effect and the global itself are deleted; `representationForType`'s `file != dartCoreFile` test becomes a spec check.
- `ctx.bridgeTypeRefCache` keeps working for `BridgeTypeRef.type(cacheId)` refs, minus the `staticSource` boxing dimension (phase 1).

### A.9 `TypeSystem`

One service on the context holds every algorithm that needs declarations:

```dart
final class TypeSystem {
  /// [type] viewed as an instance of [target], with arguments substituted
  /// along the path. Type parameters go through their bound, records through
  /// `Record`, function types through `Function`. When a hop's clause is raw
  /// (`List<E> $extends Iterable`), falls back to positional binding, as
  /// `_collectViaSupertypes` does today.
  InterfaceTypeRef? asInstanceOf(TypeRef type, TypeDecl target);

  Iterable<InterfaceTypeRef> directSupertypes(InterfaceTypeRef type);  // substituted
  Iterable<InterfaceTypeRef> superclassChain(InterfaceTypeRef type);   // replaces extendsChain

  bool isAssignable(TypeRef from, TypeRef to, {bool forceAllowDynamic = true});
  AssignmentConversion assignmentConversion(TypeRef from, TypeRef to);
  TypeRef leastUpperBound(Iterable<TypeRef> types);  // commonBaseType, incl. getTypeChain order and tie-break
  TypeRef flatten(TypeRef type);
  TypeRef throughTypeParameters(TypeRef type);        // resolveThroughTypeParameters
  TypeRef lowerTypeParameters(TypeRef type);
  Substitution unify(TypeRef pattern, TypeRef concrete); // collectTypeParameterSubstitutions
}
```

`isAssignableTo`, `assignmentConversionTo`, and `TypeRef.commonBaseType` keep their call shapes as extension methods and factories delegating here, which avoids touching about 80 call sites.

| Replaced walker | Replacement |
| --- | --- |
| `instantiatedSupertypeView(ctx, t, file, name)` | `asInstanceOf(t, decl)` |
| `findSupertypeInstantiation(ctx, target, concrete)` | `asInstanceOf(concrete, target.decl)` |
| `collectTypeParameterSubstitutions`, `_collectViaSupertypes` | `unify` (built on `asInstanceOf`) |
| `bridgedTypeArgument(ctx, type, ref)` | `asInstanceOf(type, bridgedAncestor).arguments[index of ref]` |
| `classTypeArguments`, `_bridgeClassTypeArguments`, `_hostParamBindings`, `appliedTypeArguments` | `Substitution.forInterface(resolvedMember.viewedAs)` |
| `inheritTypeArgsFrom` | `asInstanceOf` |
| `getTypeChain` | private helper of `leastUpperBound` |
| `getRuntimeIndices` | `RuntimeTypes.supertypeIds` over `directSupertypes` |
| `extendsChain` | `superclassChain` |
| substitution chain in `lookupFieldType`, `_memberReturnAnnotation` | `ResolvedMember` (B.3) |

### A.10 `TypeFactory` and `TypeScope`

- `TypeRef.fromAnnotation`, `fromBridgeAnnotation`, `fromBridgeTypeRef`, `resolveTypeAlias`, `resolveAppliedTypeArgument`, `formalParameterAnnotationType`, and `declaredFunctionType` move into `TypeFactory`. The `TypeRef.fromAnnotation(...)` factories can remain as thin forwarders.
- `TypeScope` is an immutable chain of `Map<String, TypeRef>` with a parent. Today's `ctx.temporaryTypes` is keyed by library, because folded mixin members resolve in their own library, so keep `Map<int, TypeScope>` on the context at first.
- Replace every manual save/restore of `temporaryTypes` with `ctx.withTypeParameters(library, owner, nodes, () => ...)`. The affected files are `backend/typed_backend.dart`, `compiler.dart`, `declaration/{class,constructor,function,method}.dart`, `expression/function.dart`, `helpers/{default_value,extension}.dart`, `reference.dart`, and `type.dart`.

### A.11 `RuntimeTypes`

Move `runtimeTypeId`, `runtimeDescriptor`, `getRuntimeIndices`, `typeRefIndexMap`, `runtimeTypeDescriptorIds`, `runtimeTypeList`, and `typeNames` into `ctx.runtimeTypes`:

```dart
final class RuntimeTypes {
  int idOf(TypeRef type);
  List<int> descriptorOf(TypeRef type);
  Set<int> supertypeIds(InterfaceTypeRef type);
  int declarationIndex(TypeDecl decl);
}
```

The backend reads the same lists it reads today, and id allocation order is unchanged.

## Part B: Declarations and members

### B.1 `MemberName`

```dart
enum MemberKind { method, getter, setter, constructor }

final class MemberName {
  const MemberName(this.name, this.kind, {this.privateLibraryUri});

  final String name;
  final MemberKind kind;
  final String? privateLibraryUri;

  /// The key used by instanceDeclarationsMap, instanceDeclarationPositions,
  /// declaredInstanceMembers, and runtime member tables: `name`, `name*g`,
  /// `name*s`, `lib::_name`, and `unary-` for nullary minus.
  String get key;

  factory MemberName.operator(String symbol, int positionalArity);
}
```

This replaces `memberKey`, `memberNameKey`, `instanceMethodKey`, and the scattered `'$name*g'`, `'${ctx.libraryUri(file)}::$name'`, and `unary-` formatting.

### B.2 `Member`

```dart
sealed class Member {
  MemberOwner get owner;  // a TypeDecl or an extension
  MemberName get name;
  bool get isStatic;
  bool get isAbstract;    // abstract body: skipped by implementation lookup
  bool get isField;       // storage-backed accessor (a getter plus an optional setter)

  /// Signature in the owner's type-parameter space. Getters are `() -> T`,
  /// setters `(T) -> void`, fields expose both.
  CallSignature get signature;

  /// How a direct call reaches the compiled body; null for bridge members.
  DeferredOrOffset? get body;
}

final class SourceMember extends Member {
  final ClassMember node;       // MethodDeclaration, ConstructorDeclaration, or the field's VariableDeclaration
  final int library;
}

final class BridgeMember extends Member {
  final Object def;             // BridgeMethodDef, BridgeFieldDef, or BridgeConstructorDef
  BridgeFunctionDef? get function;
}

sealed class MemberOwner {}     // implemented by TypeDecl and ExtensionDecl (wrapping EvalExtension)
```

Constructors are members with `MemberKind.constructor` and a `ConstructorKind` (`generative`, `factory`, `redirectingFactory`, `implicitDefault`, `enumConstant`). Implicit default constructors, which have no declaration entry today, get a synthesized `SourceMember` with an empty signature.

Extension members reuse `SourceMember` with an extension owner, so their signatures and ABI come from the same code as class methods.

### B.3 `ResolvedMember`

```dart
final class ResolvedMember {
  const ResolvedMember(this.member, this.viewedAs);

  final Member member;

  /// The owner instantiated as seen from the receiver: `A<int>` for a member
  /// of `A<T>` reached from `B extends A<int>`.
  final InterfaceTypeRef viewedAs;

  Substitution get substitution => Substitution.forInterface(viewedAs);
  CallSignature get signature => member.signature.substitute(substitution);
  TypeRef get valueType => signature.returnType; // getters and fields
}
```

### B.4 `MemberLookup`

```dart
final class MemberLookup {
  /// Static typing: the member a receiver of static type [receiver] exposes.
  /// Walks the extends chain, mixins in application order, implemented
  /// interfaces, then Object. Enums fall back to Enum. Type parameters go
  /// through their bound; records to Record; function types to Function.
  /// dynamic returns null. Abstract members count.
  ResolvedMember? interfaceMember(TypeRef receiver, MemberName name);

  /// Dispatch: the concrete body that runs for an instance whose class link
  /// is [from]. Walks the extends chain with mixin members folded in, skips
  /// abstract declarations, stops at bridged superclasses. Used by super
  /// calls and devirtualization.
  ResolvedMember? implementation(InterfaceTypeRef from, MemberName name);

  Member? staticMember(TypeDecl decl, String name, MemberKind kind);

  /// Some descendant redeclares [name] (memberOverriddenInSubclass).
  bool overriddenBelow(TypeDecl decl, MemberName name);

  /// A direct call to [member] must bind `this` to its declaring link: its
  /// body uses super, or it is a storage accessor (memberNeedsOwnerLink).
  bool needsOwnerLink(Member member);
}
```

Separating `interfaceMember` from `implementation` makes explicit the distinction the current helpers apply implicitly and inconsistently.

| Replaced | Replacement |
| --- | --- |
| `resolveInstanceMethod`, `_tryResolveInstanceMethod`, `hasInstanceMethod` | `interfaceMember(..., method or getter)` |
| `resolveInstanceDeclaration`, `GetSet` | `interfaceMember` for getter and setter names |
| `TypeRef.lookupFieldType` (including `forSet` and `forFieldFormal`) | `interfaceMember(...).valueType`; field formals use `declaredMember` |
| `resolveStaticMethod`, `resolveStaticDeclaration` | `staticMember` |
| `resolveScopedStaticDeclaration` | `staticMember` over the class and its transitive mixins (a name-resolution helper) |
| `memberOwner`, `directMemberOwner`, `concreteMemberDecl` | `implementation`, `overriddenBelow` |
| `superMixinMemberOwner`, `_resolveSuperReceiver`, `SuperPropertyReference._owner` walks | `implementation` starting above the current layer |
| `memberNeedsOwnerLink` | `needsOwnerLink` |
| `AlwaysReturnType.fromInstanceMethod`, `fromStaticMethod`, `fromInstanceMethodOrBuiltin` | `ResolvedMember.signature.returnType` |

Migrate in shadow mode: for a period, every call runs both the old helper and `MemberLookup` under `assert` and compares owner declaration and member node. Delete the old helper once the full suite (including the SDK core set) agrees.

### B.5 `CallSignature`

```dart
final class CallSignature {
  const CallSignature({
    this.typeParameters = const [],
    required this.positional,
    required this.requiredPositional,
    this.named = const [],
    required this.returnType,
    this.returnOverride,
  });

  final List<TypeParameterDef> typeParameters;
  final List<ParameterSpec> positional;
  final int requiredPositional;
  final List<ParameterSpec> named; // declaration order
  final TypeRef returnType;

  /// Only for bridge `returnTypeDependency`: the return type chosen by the
  /// static type of one argument.
  final TypeRef? Function(List<TypeRef> positionalTypes, Map<String, TypeRef> namedTypes)? returnOverride;

  CallSignature substitute(Substitution substitution);
  FunctionTypeRef toFunctionType();
}

final class ParameterSpec {
  const ParameterSpec(this.name, this.type, {required this.isRequired, this.defaultValue, this.erased = false, this.node});

  final String name;
  final TypeRef type;
  final bool isRequired;
  final DefaultSource? defaultValue;

  /// The annotation names a type parameter: the ABI boxes it
  /// (coerceArgumentForParameter's `genericParameter`).
  final bool erased;

  /// Field formals, super formals, and legacy function-typed parameters
  /// need the node for their type and default rules.
  final FormalParameter? node;
}

sealed class DefaultSource {}
// SourceDefault(Expression expression, int library) — compiled in the callee's library,
//   including defaults inherited by super formals (superFormalDefault)
// BridgeNullDefault() — a null placeholder
```

Construction rules:

- Source members use `getFormalParameterType`, `resolveFieldFormalType`, and `resolveSuperFormalType`.
- A redirecting factory exposes its target's signature, as `compileArgumentList` does today.
- Bridge members use `BridgeFunctionDef.params`/`namedParams`; `returnTypeDependency` becomes `returnOverride`.

The `ReturnType` family (`AlwaysReturnType`, `BridgedReturnType`, `TargetTypeArgDependentReturnType`, `TypeArgDependentReturnType`, `ParameterTypeDependentReturnType`) exists largely because type parameters were not substituted uniformly. With `Substitution` it collapses into `CallSignature.returnType` plus `returnOverride`. `AlwaysReturnType.nullable` duplicates `TypeRef.nullable` and goes away.

### B.6 Why not `ClassRef`/`EnumRef`/`MethodRef` with mixins or bridge-specific resolvers

- Class-like declarations differ mainly in how supertypes and constructors are computed (enums extend `Enum`, mixins use `on`, class aliases use their own clauses), and that logic is already concentrated in `classLikeClauses`. Every declaration answers the same member queries, so `MethodDefiningRef`/`FieldDefiningRef` mixins would describe no real difference.
- Nearly every current helper branches on `isBridge`. Putting that branch in `SourceTypeDecl`/`BridgeTypeDecl` and `SourceMember`/`BridgeMember` removes it from callers. A single lookup walk over polymorphic declarations is simpler than two resolver subclasses that each reimplement the walk.

## Part C: Representation and ABI

### C.1 `ValueRep`

```dart
enum ValueRep {
  int(MachineRepresentation.integer),
  double(MachineRepresentation.doublePrecision),
  bool(MachineRepresentation.boolean),
  string(MachineRepresentation.string),
  nativeNull(MachineRepresentation.object),
  nativeList(MachineRepresentation.object),
  nativeMap(MachineRepresentation.object),
  nativeSet(MachineRepresentation.object),
  boxed(MachineRepresentation.object);

  const ValueRep(this.bank);
  final MachineRepresentation bank;
}
```

Mapping from today's state:

| `type.boxed` | `representation` / type | `ValueRep` |
| --- | --- | --- |
| true | object | `boxed` |
| false | `int`, `double`, `bool`, `String` (non-null) | `int`, `double`, `bool`, `string` |
| false | `Null` | `nativeNull` |
| false | `List`, `Map`, `Set` | `nativeList`, `nativeMap`, `nativeSet` |
| any | explicit non-object representation under `Object`/`dynamic` (the `boxIfNeeded` special case) | the representation's scalar rep |
| false | `num` | must be `int` or `double`; verify with the phase 1 assertion (after which `BoxNum` should be unnecessary) |

`Variable.toRep(ctx, target)` chooses operations from the source representation, not the type:

| From → to | Operation |
| --- | --- |
| scalar → `boxed` | `BoxInt`, `BoxDouble`, `BoxBool`, `BoxString` |
| `nativeNull` → `boxed` | `BoxNull` |
| `nativeList` → `boxed` | `BoxList(runtimeTypeId: idOf(type))`, boxing elements first if the element convention requires it |
| `nativeMap`/`nativeSet` → `boxed` | `BoxMap`/`BoxSet` |
| `boxed` → scalar | `Unbox(target bank)` |
| `boxed` → native collection | no-op, as `unboxIfNeeded` does today (collections never unbox) |
| `int` → `double` | not a representation change; only `convertForAssignment` emits `IntToDouble` |

`boxIfNeeded`, `unboxIfNeeded`, and `boxIntoFreshSlot` become thin wrappers during migration. In-place boxing (writing the boxed value back to the same slot and rebinding the local) stays, via the binding back-reference described in D.3. Replacing it with fresh slots everywhere changes IR and is out of scope.

Collection element conventions: list literals always box elements (`_boxListElements = true` in `collection/list.dart`), but types from `spec.ref(ctx)` can carry unboxed element types (for example, `int` from the cacheId path), which reach `boxListContents` in `_emitBoxOp` and the `MaybeBoxNull` check in `IndexedReference`. Establish with the phase 1 assertion whether these branches are live before deleting or keeping them. Either way, the decision moves to `Abi.collectionElement`.

### C.2 `Abi`

```dart
enum CallableKind { function, method, constructor, closure, fieldAccessor, initializer, bridge, dynamicCall }

abstract final class Abi {
  /// int/double/bool when non-null and not a type parameter; null otherwise.
  /// String is deliberately excluded from call boundaries (today's rule).
  static ValueRep? unboxedAcrossCalls(TypeRef type);

  static ValueRep parameter(TypeRef type, CallableKind kind, {bool erased = false});
  static ValueRep? result(TypeRef? returnType, CallableKind kind, {bool async = false, bool unboxedOperator = false});
  static ValueRep fieldStorage(TypeRef type) => ValueRep.boxed;
  static ValueRep global(TypeRef type);            // representationForType(storageType) today
  static ValueRep local(TypeRef type);             // today's default for new bindings
  static ValueRep collectionElement(TypeRef type); // boxed
}
```

The rules are those in the table under "Boxing" above. The constructor rule should be normalized to `unboxedAcrossCalls` (which checks nullability) rather than set membership; the outcome is identical because `representationForType` already boxes nullable types.

### C.3 `CallableAbi`

```dart
final class CallableAbi {
  const CallableAbi(this.parameters, this.result);

  /// All parameters in machine order: receiver, declared parameters, and
  /// hidden parameters (the trailing runtime type id of generative
  /// constructors).
  final List<ValueRep> parameters;
  final ValueRep? result;

  MachineFunctionSignature get machine;

  static CallableAbi of(Member member);
  static CallableAbi ofFunction(FunctionDeclaration declaration);
  static CallableAbi closure(int parameterCount);
}
```

`CallableAbi.of` is pure (computed from the declaration) and memoized with an `Expando` on the declaration node. It works for callees whose function id is still deferred. Callee setup (the `Parameter` ops and parameter variables in `declaration/*.dart`) and callers (argument coercion, result representation, and the `positionalUnboxed`/`namedUnboxed` flags in `tearoff.dart`) all read the same object. `ctx.functionSignatures[id]` is written from `abi.machine`.

## Part D: Values, bindings, and denotations

### D.1 `Variable`

```dart
final class Variable {
  Variable(this.ssa, this.type, this.rep, {this.facts = ValueFacts.none, this.binding});

  final SSA ssa;
  final TypeRef type;   // static (flow) type, no boxing
  final ValueRep rep;
  final ValueFacts facts;

  /// The binding this value is the current value of, if any (D.3).
  final LocalBinding? binding;

  Variable withType(TypeRef type);        // promotion; rep unchanged
  Variable withFacts(ValueFacts facts);
  Variable toRep(CompilerContext ctx, ValueRep target);

  // Existing factories keep their shapes, gaining `rep:` and `facts:`.
  factory Variable.ssa(CompilerContext ctx, Operation op, TypeRef type, {ValueRep? rep, ValueFacts facts});
  factory Variable.of(CompilerContext ctx, SSA ssa, TypeRef type, {ValueRep? rep, ValueFacts facts});
}
```

When `rep` is omitted it defaults to `Abi.local(type)`, which is today's derivation, so most of the 101 `Variable.ssa` and 38 `Variable.of` sites change only if they passed `boxed:` or `representation:`. `withType` replaces the recurring `copyWith(type: t.copyWith(boxed: local.boxed))` idiom in promotion, `as`, `restoreBoxingState`, and `_restoreSavedTypes`.

| Current field | Destination |
| --- | --- |
| `name` | `ssa` |
| `type` | `type` |
| `representation`, `type.boxed` | `rep` |
| `exactType`, `concreteTypes` (possible classes) | `facts.exact`, `facts.possibleClasses` |
| `concreteTypes` (Type-literal denotation, function return type, type-parameter value) | `TypeLiteralDenotation`, `FunctionDenotation`, `facts.denotedType` (D.4) |
| `isConst`, `isConstInt` | `facts` |
| `localName`, `frameIndex` | `LocalBinding` (via the back-reference) |
| `declaredType`, `isFinal` | `LocalBinding` |
| `captureCell`, `exceptionSlot`, `captureCellSlot` | `LocalBinding.storage` |
| `methodOffset`, `methodReturnType`, `callingConvention`, `implicitReceiver`, `boundExtension` | `Denotation`/`Receiver` (D.4); materialized closures carry a `FunctionTypeRef` |

### D.2 `ValueFacts`

```dart
final class ValueFacts {
  const ValueFacts({this.exact, this.possibleClasses = const [], this.denotedType, this.isConst = false, this.isConstInt = false});
  static const none = ValueFacts();

  final InterfaceTypeRef? exact;
  final List<InterfaceTypeRef> possibleClasses; // empty = unknown
  final TypeRef? denotedType;                    // a Type value known to denote this type
  final bool isConst;
  final bool isConstInt;

  ValueFacts join(ValueFacts other); // exact survives only if equal; possible classes union, or unknown if either is unknown
  ValueFacts cleared();              // what `widened()` keeps today
  ValueFacts forBinding();           // drops isConstInt, which never survives binding
}
```

`Variable.widened` and `joinedWith` become `facts.cleared()` and `facts.join(...)`. Final-variable enforcement in `IdentifierReference.setValue` must use `LocalBinding.isFinal` together with an explicit "initialized" state, not `concreteTypes.isNotEmpty`. Replicate today's exact outcome during phases 0–6 and record the coupling as a phase 7 item.

### D.3 `LocalBinding`

```dart
final class LocalBinding {
  LocalBinding(this.name, this.declaredType, this.storage, {required this.isFinal, required Variable initial});

  final String name;
  final TypeRef declaredType;
  final bool isFinal;
  final BindingStorage storage;

  Variable get current;          // flow-typed value; its `binding` points back here
  Variable read(CompilerContext ctx);      // readBinding: capture cell or exception slot loads
  Variable write(CompilerContext ctx, Variable value); // IdentifierReference.setValue's local branch
  void promote(TypeRef type);    // copyWithUpdate(type: ...), inferType
  void rebind(Variable value);   // in-place box/unbox, branch reconciliation
}

sealed class BindingStorage {}
final class SsaStorage extends BindingStorage {}
final class CaptureCellStorage extends BindingStorage { final SSA cell; }
final class ExceptionSlotStorage extends BindingStorage { final ExceptionSlot slot; final ExceptionSlot? cellSlot; }
```

- Scopes and `ContextSaveState` store `LocalBinding`s. Copying a save state copies each binding's current value and type, not the binding identity.
- `lookupLocal` returns the binding and no longer mutates anything.
- `copyWithUpdate`, `updated(ctx)`, `setLocal`'s `frameIndex`/`localName` assignment, and `captureBinding`'s field copying go away.
- `IndexedReference` keeps optional bindings for its receiver and index instead of re-looking them up by name.
- `resolveBranchStateDiscontinuity`, `restoreBoxingState`, `mergeBranchState`, `widenAssignedLocals`, `inferTypes`, and `uninferTypes` become operations over bindings: `rebind`, `promote`, and facts joins.

The back-reference `Variable.binding` is the one deliberate coupling left: in-place boxing of a local must update its binding. It replaces today's `localName`/`frameIndex` pair and the re-lookup through `ctx.locals`.

### D.4 Denotations, references, and receivers

```dart
sealed class Denotation {
  TypeRef readType(CompilerContext ctx);
  TypeRef writeType(CompilerContext ctx);
  Variable read(CompilerContext ctx);                   // materializes tear-offs
  Variable write(CompilerContext ctx, Variable value);
  CallTarget call(CompilerContext ctx, CallSite site);  // Part E
}

final class LocalDenotation extends Denotation { final LocalBinding binding; }
final class GlobalDenotation extends Denotation { final int library; final String globalName; }
final class FunctionDenotation extends Denotation { final Member function; final Variable? implicitReceiver; }
final class StaticMemberDenotation extends Denotation { final TypeDecl owner; final Member member; }
final class InstanceMemberDenotation extends Denotation { final Receiver receiver; final ResolvedMember member; }
final class ExtensionMemberDenotation extends Denotation { final ExtensionDecl ext; final Member member; final Substitution onBindings; final Variable? receiver; }
final class TypeLiteralDenotation extends Denotation { final TypeRef type; }
final class ExtensionNamespaceDenotation extends Denotation { final ExtensionDecl ext; }
final class TypeParameterDenotation extends Denotation { final TypeParameterTypeRef type; }
final class PrefixDenotation extends Denotation { final String prefix; final Map<String, DeclarationOrBridge> children; }
```

The existing `Reference` classes become syntax plus a lazily computed `late final Denotation denotation`:

- `resolveType(forSet)`, `getValue`, `setValue`, and `getStaticDispatch` delegate to it.
- `getStaticDispatch` and `StaticDispatch` disappear into `Denotation.call`.
- `PrefixError` becomes `PrefixDenotation`, so compiling `p.C` no longer uses exceptions for control flow.

A denotation holds a `LocalBinding`, never a `Variable` snapshot, so a compound assignment that reads, computes, and writes sees the binding's current value at each step.

Name resolution is written once, following Dart's lexical order and today's precedence:

1. Local bindings (innermost scope first).
2. Inside an extension body: the extension's own members (instance members with `#this` as the implicit receiver, statics, static fields).
3. Inside an anonymous-method body: members of the anonymous receiver.
4. Members declared by the enclosing class itself (not inherited), then enum values of an enclosing enum, then statics of the class and its transitive mixins.
5. Type parameters in scope (`_` is non-binding).
6. Library scope: visible declarations, including prefixes and `*g`/`*s` accessor keys.
7. Implicit `this`: inherited instance members, then applicable extension members.

Today the four cascades disagree at step 4: `resolveType` consults inherited fields there, while `getValue` defers them to step 7. The single cascade follows `getValue`, because it determines the emitted code. Run the old `resolveType`, `setValue`, and `getStaticDispatch` in shadow mode against the new cascade, and treat any disagreement that changes test outcomes under the incidental-fix policy.

Receivers make the special receivers explicit:

```dart
sealed class Receiver {}
final class ValueReceiver extends Receiver { final Variable value; }
final class SuperReceiver extends Receiver { final Variable self; }
final class TypeLiteralReceiver extends Receiver { final TypeRef type; }
final class ExtensionApplicationReceiver extends Receiver { final ExtensionDecl ext; final Substitution onBindings; final Variable value; }
final class PrefixReceiver extends Receiver { final PrefixDenotation prefix; }
```

`compileReceiver(Expression)` builds them:

- identifiers, prefixed identifiers, and property accesses go through references;
- `super` becomes a `SuperReceiver`;
- `E(x)` becomes an `ExtensionApplicationReceiver`;
- the cascade target and everything else become a `ValueReceiver`.

This replaces the `type == Type && concreteTypes.length == 1` checks in `method_invocation.dart`, `property_access.dart`, `function_reference.dart`, `instance_creation.dart`, and `reference.dart`, as well as `boundExtension`.

### D.5 `DeferredOrOffset`

Keep it as the link-time function key, but:

- drop `targetName` (a bound receiver lives in the denotation);
- replace `methodType` 0/1/2 with `MemberKind`;
- build it from `Member.body` instead of assembling it at call sites.

## Part E: Invocation

### E.1 Pipeline

```
syntax ──► CallSite ──► CallResolver ──► CallTarget ──► Devirtualizer ──► ArgumentBinder ──► emit ──► Variable
            (no IR)     (receiver type +   (what is      (refines         (compiles args in   (IR ops,
                         syntax shape)      called)       Virtual→Static)  source order,       result rep,
                                                                           coerces, infers)    facts)
```

Target resolution may use only the receiver's static type and facts plus the syntactic shape (arity, argument names, explicit type arguments). Arguments are compiled by the binder, because each argument's context type is its parameter's type under the current inference state.

### E.2 Call sites and shapes

```dart
final class CallSite {
  final Receiver? receiver;     // null for a bare `m(...)`
  final String? name;           // null for a function-expression call
  final CallShape shape;
  final TypeRef? context;       // the expression's context type (`bound` today)
  final AstNode source;
  final bool inConstContext;
}

final class CallShape {
  final List<ArgSource> positional;
  final List<(String, ArgSource)> named;
  final List<int> sourceOrder;  // interleaving of positional and named arguments as written
  final List<TypeAnnotation>? typeArguments;

  int get positionalArity => positional.length;
  factory CallShape.fromArgumentList(ArgumentList arguments, TypeArgumentList? typeArguments);
  factory CallShape.values(List<Variable> positional, [Map<String, Variable> named]);
}

sealed class ArgSource {}
final class ExpressionArg extends ArgSource { final Expression expression; }
final class ValueArg extends ArgSource { final Variable value; }        // operators, already-compiled operands
final class ForwardedLocal extends ArgSource { final String localName; } // super parameters
```

Null-shorting (`emitNullGuard`), cascades, `super`, `E(x)`, and implicit `this` are resolved while building the `CallSite`, never inside targets.

### E.3 Resolution rules

The resolver encodes today's precedence as one ordered list per entry point.

Bare calls `m(args)` (from `compileMethodInvocation` without a target):

1. `m` denotes an extension namespace: `E(x)` produces an `ExtensionApplicationReceiver` value, not a call.
2. `m` denotes a local or getter whose value is `dynamic` or function-typed: `ClosureCall`.
3. `m` denotes a value of another type: an extension `call` member gives an extension `StaticCall`; otherwise a `ClosureCall`, which dispatches `.call` or raises `NoSuchMethodError` at runtime.
4. `m` denotes an extension member inside its extension body: an extension `StaticCall` with the implicit receiver.
5. `m` denotes a member of the current class: resolve as `this.m(args)`.
6. `m` denotes a class: a `ConstructorCall` for the unnamed constructor, or the implicit default constructor.
7. `m` denotes a type alias: a `ConstructorCall` on the aliased type with alias-parameter inference (context first, then arguments).
8. `m` denotes a bridge function or constructor: a `BridgeCall` (`BridgeInstantiate` for non-wrapping bridge classes).
9. `m` denotes a top-level function: a `StaticCall`.

Calls with a receiver `r.m(args)` (from `_invokeWithTarget`):

1. `ExtensionApplicationReceiver`: an extension `StaticCall`, or a `MemberValueCall` (read first) for an extension getter.
2. `TypeLiteralReceiver`:
   - a static method or constructor gives a `StaticCall`/`ConstructorCall`;
   - a static field or getter gives a `MemberValueCall` (read first);
   - an instance extension member through its namespace, `E.m(receiver, ...)`, gives an extension `StaticCall` with the receiver taken from argument 0;
   - an extension member on `Type` gives an extension `StaticCall`;
   - otherwise, an instance method of the `Type` object gives a `VirtualCall` on the type value.
3. A function-typed receiver calling `.call`: `ClosureCall`.
4. A record receiver with a named field `m`: `MemberValueCall` (arguments first).
5. An interface member:
   - a method gives a `VirtualCall` (or a `BridgeCall` for bridge members);
   - a field or getter gives a `MemberValueCall`, arguments first (read first for `super`).
6. An extension member matching the arity: an extension `StaticCall`. An extension getter gives a `MemberValueCall` (read first).
7. `noSuchMethod`, which is implicit and absent from metadata: `DynamicCall`.
8. A `dynamic` receiver: an extension on `dynamic` gives an extension `StaticCall`; otherwise a `DynamicCall`.

For a `super` receiver, `implementation()` starts above the current layer (mixin members first, then the superclass chain) and gives a `StaticCall` through `LoadSuper` hops. With no concrete member, the result is a `NoSuchMethodCall`; an abstract getter produces a getter-shaped `Invocation`, and its result is then called with a `ClosureCall`.

Operators and `[]`/`[]=` (from `Variable.invoke`, in today's order):

1. Intrinsics (E.8).
2. `ExtensionApplicationReceiver`: an extension `StaticCall`.
3. No interface member: an extension member, with `unary-` mapped to the arity-0 `-`.
4. `==` or `!=` between two unmaterialized function references: a compile-time constant (keep as a special case).
5. `==` or `!=`: `EqualityCall`.
6. Otherwise, a `VirtualCall` with the `untypedLegacy` binding policy until phase 7.

### E.4 Call targets

```dart
sealed class CallTarget {
  CallSignature? get signature;   // null for DynamicCall
  BindingPolicy get policy;
  CallableAbi get abi;
  Variable emit(CompilerContext ctx, BoundCall call);
}
```

| Target | Fields | Used for | Binding policy | IR |
| --- | --- | --- | --- | --- |
| `StaticCall` | `Member`, `DeferredOrOffset`, optional receiver and owner link, extension bindings | top-level functions, static methods, extension members (receiver as argument 0), devirtualized methods, super methods | `callerFillsDefaults` | `Call`, plus `LoadSuper` hops and `typeEnvironmentReceiver` |
| `ConstructorCall` | constructor `Member`, instantiated type, `ConstructorKind`, const flag | `new`/implicit `new`, dot shorthands, type alias construction, super-constructor calls, enum constants | `callerFillsDefaults` | `Call` with hidden arguments |
| `VirtualCall` | receiver, `ResolvedMember` | instance members through a static type | `callerFillsDefaults` until phase 7, then `calleeBinds` | `InvokeDynamic` with the source shape |
| `BridgeCall` | bridge index or member, optional receiver | bridge statics, constructors, and instance members | `bridgeVector` | `InvokeExternal`, `BridgeInstantiate`, or padded `InvokeDynamic` |
| `ClosureCall` | callee value, optional `FunctionTypeRef`, optional statically known function | function-typed values | `calleeBinds` | `InvokeClosure(trusted)`, or `Call` when statically known |
| `DynamicCall` | receiver, name | `dynamic` receivers, implicit `noSuchMethod` | `calleeBinds`, boxed, no signature | `InvokeDynamic` |
| `EqualityCall` | left, right, negated flag | `==`/`!=` without an extension | — | `DynamicEquals` (+ `LogicalNot`) |
| `MemberValueCall` | the member read, `EvalOrder` | calling a field, getter, or record field value | delegates to `ClosureCall` | read, then closure call |
| `NoSuchMethodCall` | member name, getter-shaped flag | super calls on abstract members | boxed | `Invocation.method`/`Invocation.getter` via `InvokeExternal`, then `noSuchMethod` on `this` |

```dart
enum BindingPolicy {
  callerFillsDefaults, // full typed vector; omitted parameters get compiled defaults
  calleeBinds,         // supplied arguments only; the runtime binds names and defaults
  bridgeVector,        // flattened positional vector, named arguments in declaration order, null placeholders
  untypedLegacy,       // box everything, no coercion (today's operator path); removed in phase 7
}

enum EvalOrder { argumentsFirst, readFirst }
```

### E.5 Devirtualizer

`Devirtualizer.refine(VirtualCall target, Receiver receiver) → CallTarget` applies today's rules from `_invokeWithTarget` and `getProperty`:

1. Only non-bridge members. Classes with a host-bridged superclass never devirtualize (`hasBridgeSuperclass`).
2. The link type is the `SuperReceiver`'s layer, or else `facts.exact`.
3. With a link type, `implementation(link, name)` gives the direct owner.
4. Without a link type and with exactly one possible class, the direct owner is `implementation(possible, name)` provided the member is not `overriddenBelow`.
5. A direct call is allowed when there is a link type, or when `needsOwnerLink` is false. With a link type and `needsOwnerLink`, the receiver argument is the owner link reached through `LoadSuper` hops (`ownerLinkSsa`).
6. The result is a `StaticCall` with `typeEnvironmentReceiver` set to the boxed receiver.

The same object refines getter and setter accesses (E.9).

### E.6 ArgumentBinder

```dart
final class ArgumentBinder {
  BoundCall bind(
    CompilerContext ctx,
    CallTarget target,
    CallSite site, {
    BindingOptions options = BindingOptions.legacy,
  });
}

final class BindingOptions {
  const BindingOptions({required this.namedOrder, required this.allowNamedBeforePositional, required this.inference});
  static const legacy = BindingOptions(
    namedOrder: NamedOrder.declaration,
    allowNamedBeforePositional: false,
    inference: InferenceMode.legacy,
  );

  final NamedOrder namedOrder;         // declaration (today) | source
  final bool allowNamedBeforePositional;
  final InferenceMode inference;       // legacy (bare `T` for source, recursive for bridge) | unify
}

final class BoundCall {
  final Variable? receiver;            // after coercion
  final List<BoundArgument> positional; // callee order
  final List<(String, BoundArgument)> named;
  final Substitution typeArguments;
  final List<int> runtimeTypeArguments;
  final TypeRef returnType;            // substituted and lowered
  final bool trusted;                  // ClosureCall: every argument proven (_closureArgumentsProven)
  List<SSA> vector();
}

final class BoundArgument { final Variable value; final bool supplied; }
```

Algorithm:

1. **Match.** Map `CallShape` arguments to formals without emitting anything. Report unknown named arguments, missing required arguments, and extra positional arguments with today's messages. Account for `argIndexOffset` (`E.m(receiver, ...)`), leading `ValueArg`s (receivers and `before`), and `ForwardedLocal`s (super parameters bind positional formals in order and named formals by name). Under `legacy`, reproduce today's failure when a named argument precedes a positional one.
2. **Seed the substitution:**
   - the receiver view (`Substitution.forInterface(resolvedMember.viewedAs)`);
   - extension `on` bindings;
   - constructor class parameters (explicit type arguments, otherwise bounds);
   - explicit method type arguments, checked against bounds with the argument substituted into self-referential bounds (`_resolveInvocationGenerics`);
   - without explicit arguments, method parameters bound to their bounds, as today.
3. **Compile and coerce.** Iterate arguments in the configured order (declaration order under `legacy`). Compile each `ExpressionArg` with context `param.type.substitute(current)`, then coerce with `convertForAssignment` to that type and the ABI representation. Bridge arguments get `PrepareBridgeArgument` for nullable, `Null`, or `dynamic` types, reject only invalid named arguments statically, and are otherwise converted at the runtime boundary. Record inference constraints: under `legacy`, a source callee records only parameters annotated with a bare type parameter; a bridge callee recurses into type arguments and generic function returns (`_inferBridgeTypeParameters`).
4. **Solve inference.** Take the least upper bound of each parameter's constraints. Then apply downward inference: for parameters the arguments did not constrain, unify the declared return type (with placeholders) against the context type.
5. **Fill omitted arguments** by policy:
   - `callerFillsDefaults` compiles each default in the callee's library (`compileOmittedArgument`, including super-formal inheritance and the scalar or thunk choice);
   - `bridgeVector` pushes a shared null placeholder;
   - `calleeBinds` does nothing.
6. **Return type.** Substitute, apply `returnOverride` with the bound argument types, and lower remaining callee-scoped type parameters. `void` results used as values fall back to `dynamic`, as `resolveCallResultType` does.

`IndexedReference` and compound assignments read `BoundCall.receiver` and `BoundCall.positional` for the post-coercion values, replacing `InvokeResult.target` and `args`.

### E.7 Emission

| Target | Hidden and special handling | Result |
| --- | --- | --- |
| `StaticCall` | owner link via `LoadSuper` hops; `typeEnvironmentReceiver`; `typeArguments` = runtime ids of method type arguments, or `extensionCallTypeArguments` for extensions | rep from `abi.result`; facts none |
| `ConstructorCall` | generative: trailing `pushRuntimeTypeId(instantiated)`. Factory: instantiated class arguments through `typeArguments`. Enum: two leading null arguments. Implicit default: runtime type id only. Const context: `pushInternConst`. Bridge: `BridgeInstantiate` when `!wrap`, otherwise `InvokeExternal`. | `boxed`; `possibleClasses: [instantiated]`; `exact` only for generative constructors |
| `VirtualCall` | receiver boxed; `positionalCount`/`namedNames` from the bound shape; `callerLibrary`; `typeArguments` | `boxed` |
| `BridgeCall` | padded vector; instance calls use `positionalCount = vector.length` and no named names; static calls use `bridgeStaticFunctionIndices` | `boxed`; type may come from `returnOverride` |
| `ClosureCall` | callee boxed into a fresh slot plus `Assign(closure_target)`; each argument snapshotted into a fresh slot before boxing; `trusted` | `boxed` |
| `DynamicCall` | all arguments boxed; tear-offs materialized | `boxed`, `dynamic` |
| `EqualityCall` | `DynamicEquals`, then `LogicalNot` for `!=` | unboxed `bool` |
| `NoSuchMethodCall` | `Symbol` via `InvokeExternal`; arguments into a `List`/`Map`; `Invocation.method` or `Invocation.getter` | `boxed` |

### E.8 Intrinsics

`intrinsics.dart` holds a table consulted before resolution on the operator and index paths, and after binding for bridge instance calls that `_invokeWithTarget` currently routes through `Variable.invoke`:

| Receiver | Member | Condition | Emission |
| --- | --- | --- | --- |
| `String` | `+` | argument assignable to `String` | `StringOperation.concatenate` |
| `String` | `codeUnitAt`, `[]` | argument assignable to `int` | `StringOperation.codeUnitAt`/`indexAt` |
| `bool` | `!` | — | `LogicalNot` |
| `int` | `+ - < > <= >=` | argument assignable to `int` | `IntAdd`, `IntSub`, `Int*` comparisons |
| `int`/`double` | numeric operators | operand rules in `Variable.invoke`, including `int` → `double` widening | `NumericBinary` |
| `String`, native `List` | `length` getter | non-null | `StringOperation.length`, `ListLength` |
| any | `runtimeType` getter | not declared or overridden | `LoadConstantType`/`LoadTypeParameter`/`LoadRuntimeType` |
| `List`, `Map` | `[]` | `IndexedReference` fast paths | `IndexList`, `IndexMap` + `MaybeBoxNull` |

### E.9 Accessor targets

Getters and setters need no argument binding, so they get a smaller family that reuses `MemberLookup`, the `Devirtualizer`, and `Intrinsics`:

```dart
sealed class GetTarget {}
// FieldSlotGet(link hops, index, isLate) | DirectGetterCall(StaticCall) | DynamicGet(name) | BridgeStaticGet(index)
// | ExtensionGetterCall(StaticCall) | MethodTearOff(member, receiver) | IntrinsicGet

sealed class SetTarget {}
// FieldSlotSet | DirectSetterCall | DynamicSet | BridgeSet | ExtensionSetterCall | GlobalSet | LocalSet
```

This absorbs `Variable.getProperty`, the object branches of `IdentifierReference.getValue`/`setValue`, and `SuperPropertyReference`.

### E.10 Current entry points

| Current | New |
| --- | --- |
| `compileMethodInvocation`, `_invokeWithTarget`, `_resolveSuperReceiver`, `_invokeSuperNoSuchMethod`, `_invokeValue`, `_compileCallArgs`, `_applyExtension`, `_invokeExtensionMethod` | `CallSite` construction plus `CallResolver` |
| `compileNonBridgeArgs`, `ResolvedArgs`, `_resolveInvocationGenerics`, `_instantiateConstructorType`, `_inferBridgeTypeParameters` | `ArgumentBinder` |
| `Variable.invoke`, `_invokeAsFunction`, `InvokeResult` | operator entry point in `CallResolver`, `Intrinsics`, `BoundCall` |
| `invokeClosure`, `resolveCallResultType`, `_closureArgumentsProven` | `ClosureCall` plus the binder |
| `compileInstanceOf`, implicit `new` in `compileMethodInvocation`, `dot_shorthand.dart` constructor paths | `ConstructorCall` |
| super-constructor calls (`declaration/constructor.dart`), enum constants (`declaration/enum.dart`) | `ConstructorCall` with `ForwardedLocal` arguments |
| `compileArgumentList`, `compileArgumentListWithBridge`, `compileArgumentListWithDynamic`, `compileSuperParams`, `compileSuperParamsWithBridge` | `ArgumentBinder` policies |
| `invokeExtensionGetter`, the extension path in `Variable.invoke` | extension `StaticCall`, `ExtensionGetterCall` |
| `Variable.getProperty`, `IdentifierReference` object branches, `SuperPropertyReference` | `GetTarget`/`SetTarget` |
| `Reference.getStaticDispatch`, `StaticDispatch`, `_declarationToStaticDispatch` | `Denotation.call` |

## Phases

Each numbered step lands as its own commit with the verification in the next section passing.

### Phase 0: Guardrails

1. Record baselines: `dart test` count and results, the SDK core set with its `expect_fail` list, `dart analyze`, `dart run tool/generate_typed_machine.dart --check`, and `dart run benchmark/compile.dart`.
2. Add `test/language/binding_characterization_test.dart` covering the three confirmed bugs, asserting today's outcomes with comments pointing to phase 7.
3. Add `tool/ir_snapshot.dart`: load the SDK suite as `tool/run_one.dart` does, compile every core-set test plus the benchmark programs, and write a SHA-1 of `program.write()` per program to JSON; `--compare <baseline.json>` prints the programs whose output changed. Run it twice on the baseline to confirm output is deterministic. If SSA names or labels leak into the program, normalize them first. Phases 1–5 aim for zero diffs; use `dart_eval dump` to inspect any that appear.

### Phase 1: `Variable` owns boxing

1. Add `ValueRep` and a `rep` field on `Variable`, derived from today's `type.boxed`, `representation`, and type. Assert on every construction that `rep.bank == representation` and `(rep == boxed) == type.boxed`. Classify every divergence the assertion reports (expected: the `Object`/`dynamic` special case, `num`, collections, and `Null`).
2. Rewrite `boxIfNeeded`, `unboxIfNeeded`, `boxIntoFreshSlot`, and `_emitBoxOp` to switch on `rep`. Make `Variable.boxed` mean `rep == ValueRep.boxed`. Add `withType` and migrate promotion (`helpers/promotion.dart`), `as.dart`, `context.dart` (`restoreBoxingState`, `_restoreSavedTypes`), `statement/variable_declaration.dart`, and `IdentifierReference.setValue`.
3. Add `Abi` and `CallableAbi`. Use them in `declaration/function.dart`, `declaration/method.dart`, `declaration/constructor.dart`, `declaration/field.dart`, `declaration/variable.dart`, `expression/function.dart`, `helpers/default_value.dart`, `declaration/enum.dart`, `coerceArgumentForParameter`, `compileOmittedArgument`, the result boxing in `method_invocation.dart` and `invoke.dart`, and `tearoff.dart`.
4. Replace `copyWith(boxed: ...)` with representations: `Variable.ssa(..., rep:)`, `Variable.of(..., rep:)`, or `Abi.*`. For field types, remove `.copyWith(boxed: true)` in `lookupFieldType` and apply `Abi.fieldStorage` where values are stored.
5. Delete `TypeRef.boxed`, `typeAcrossFunctionBoundary`, `isUnboxedAcrossFunctionBoundaries`, the global `unboxedAcrossFunctionBoundaries`, and the `staticSource` part of `bridgeTypeRefCache`'s key. Resolve the collection element branches (C.1).

Exit criteria: no `boxed:` arguments on `TypeRef` construction or `copyWith` remain in `lib/src/eval/compiler`, and representation analysis (which throws on any conflict) is clean across the suite. `ir_snapshot` shows no diffs, or each diff is explained.

### Phase 2: Declarations own nominal information

1. Add `TypeDecl`, `SourceTypeDecl`, `BridgeTypeDecl`, and `TypeDeclRegistry`, created in `Compiler._cacheTypeRef` in today's order. Give the existing `TypeRef` a `decl` field, set by `TypeRef.cache` and carried through `copyWith`. It stays null for type parameters, records, and the extension pseudo-type built in `_declarationToVariable` (which phase 6 replaces with `ExtensionNamespaceDenotation`). Route the handful of direct `TypeRef(file, name)` constructions of declared types (for example, the enum type in `IdentifierReference.getValue`) through the registry. Reimplement `Refify.ref` over `bySpec`.
2. Add `TypeRef.isSpec(BridgeTypeSpec)` and the convenience getters over `decl` (`TypeDecl` knows its library URI, so no `ctx` is needed). Replace every `== CoreTypes.x.ref(ctx)`, `!= ...`, and comparison against another spec table's `ref(ctx)`. The semantics are identical because `==` is nominal today; function types answer as described in A.5. Delete `dartCoreFile`.
3. Move `extendsType`, `implementsType`, `withType`, `genericParams`, and `resolved` into `TypeDecl.supertypes`/`typeParameters`. Add `TypeSystem` with `asInstanceOf`, `directSupertypes`, and `superclassChain`, and migrate the walkers in A.9. Make `resolveTypeChain` return `this`, then delete it and its 84 calls. Delete `_TypeRefCache`, `TypeRef.cache`, and the `visibleTypes` write-back.
4. Extract `RuntimeTypes`.
5. Introduce `TypeScope` and `ctx.withTypeParameters`, and replace manual `temporaryTypes` save/restore.

Exit criteria: no `resolveTypeChain`, `_caches`, or `dartCoreFile` references remain; `TypeRef` no longer has supertype fields; no diffs in `ir_snapshot`.

### Phase 3: Sealed type values

Steps 1–3 add subclasses of the still-concrete `TypeRef`, so each kind can migrate on its own; the old fields stay until the kind that used them has moved. Step 4 turns the remaining concrete class into `InterfaceTypeRef` and seals the base.

1. Add `TypeParameterDef`, `TypeParameterOwner`, `declareTypeParameters`, `Substitution`, and `TypeParameterTypeRef`. Migrate every site that builds a type-parameter `TypeRef` (the 24 direct `TypeRef(...)` constructions include them) and every `Map<(String, int), TypeRef>`. Make runtime descriptors use `owner.isClassLike` instead of parsing strings.
2. Add `RecordTypeRef` and migrate record construction in `TypeRef.fromAnnotation`, `expression/record.dart`, patterns, and `recordFields` users.
3. Add `FunctionSignature` and `FunctionTypeRef`. Migrate `EvalFunctionType` users (`model/function_type.dart`, `closure.dart`, `tearoff.dart`, `substituteTypeParameters`, `lowerTypeParameters`, `runtimeDescriptor`, `_inferBridgeTypeParameters`, `backend/typed_backend.dart`). Classify every `Function` spec check as `isBareFunction` or `isFunctionLike`, and remove the compatibility override.
4. Add `InterfaceTypeRef` and seal `TypeRef`. Migrate `specifiedTypeArgs` to `arguments`.
5. Flip `==`/`hashCode` to structural. Apply the collection audit in A.4. Delete `hasSameDeclarationAs`, `isSameSemanticType`, and `semanticKey`.

Exit criteria: `TypeRef` is sealed with four subclasses. None of `typeParameterOwner`, `recordFields`, `functionType`, `EvalFunctionType`, `FunctionTypeAnnotation`, or `semanticKey` remain. Any `ir_snapshot` diffs are explained (A.6 may produce some).

### Phase 4: Members and signatures

1. Add `MemberName` and migrate key formatting.
2. Add `Member`, `SourceMember`, `BridgeMember`, `MemberOwner`, `ResolvedMember`, and `TypeDecl.declaredMember`/`staticMember`/`constructor`.
3. Add `MemberLookup`. Run it in shadow mode against every helper in the B.4 table, then migrate callers and delete the helpers.
4. Add `CallSignature` and `ParameterSpec`, built from source and bridge members. Replace `AlwaysReturnType` and the rest of the `ReturnType` family. Compute `CallableAbi.of(member)` from the signature.

Exit criteria: none of the helpers in the B.4 table remain; `ReturnType` is gone except the bridge override; no diffs in `ir_snapshot`.

### Phase 5: Values and bindings

This phase can proceed in parallel with phases 2–4.

1. Add `LocalBinding`, `BindingStorage`, and the `Variable.binding` back-reference. Migrate scopes, `ContextSaveState`, and every `lookupLocal`/`setLocal` user. Delete `localName`, `frameIndex`, `declaredType`, `isFinal`, `captureCell`, `exceptionSlot`, `captureCellSlot`, `copyWithUpdate`, and `updated`.
2. Add `ValueFacts` and migrate `exactType`, `concreteTypes` (only its possible-classes meaning), `isConst`, and `isConstInt`. Replace `widened`/`joinedWith`.

Exit criteria: `Variable` holds only `ssa`, `type`, `rep`, `facts`, `binding`, and, until phase 6, the denotation fields; no diffs in `ir_snapshot`.

### Phase 6: Invocation

Migrate one call kind per step and delete the old path in the same step.

1. Add `Denotation`, `Receiver`, and `compileReceiver`, and rebuild `Reference` on them. Remove the denotation fields from `Variable` (`methodOffset`, `methodReturnType`, `callingConvention`, `implicitReceiver`, `boundExtension`) and the `name == null` state. Delete `DeferredOrOffset.targetName` and `PrefixError`.
2. Add `CallSite`, `CallShape`, `ArgumentBinder` (with `BindingOptions.legacy`), `BoundCall`, and the `CallTarget` base. Migrate `ClosureCall` (`invokeClosure`, `funcexpr_invocation.dart`) and bare top-level/static function calls.
3. Instance calls in `method_invocation.dart`: `VirtualCall`, `BridgeCall`, `DynamicCall`, `MemberValueCall`, and the `Devirtualizer`.
4. Operators and `[]`/`[]=`: route `Variable.invoke` callers (`binary.dart`, `prefix.dart`, `postfix.dart`, `assignment.dart`, `string_interpolation.dart`, `adjacent_strings.dart`, `pattern.dart`, `for.dart`, `switch.dart`, `switch_expression.dart`, `if.dart`, `spread.dart`, `IndexedReference`) through the resolver with `untypedLegacy` and `Intrinsics`. Add `EqualityCall`.
5. Extension calls (four paths), constructors (the three expression paths plus super constructors and enum constants), `super`, and `NoSuchMethodCall`.
6. Accessors: `GetTarget` and `SetTarget`.

Exit criteria: `compileNonBridgeArgs`, `ResolvedArgs`, all `compileArgumentList*`/`compileSuperParams*` functions, `InvokeResult`, `StaticDispatch`, `Variable.invoke`, and `Variable.getProperty` are gone. `method_invocation.dart` contains only `CallSite` construction. No `ir_snapshot` diffs, except those explained by removed duplicate lookups.

### Phase 7: Semantic changes

Each item lands as its own commit with tests and any `suite.yaml` updates:

1. `VirtualCall` uses `calleeBinds`, which fixes the default-argument bug. The runtime already binds defaults for `InvokeDynamic` on evaluated methods.
2. `NamedOrder.source` and `allowNamedBeforePositional`, which fix the two evaluation-order bugs.
3. Operators move from `untypedLegacy` to typed binding and devirtualization. This is also likely a runtime speedup for user-defined operators.
4. `InferenceMode.unify` for source callees, inferring from `List<T>`-style parameters as bridge calls already do.
5. Generic function types for generic callables and tear-offs (A.5).
6. Final-variable enforcement independent of facts (D.2).
7. Per-callee type parameters instead of shared `callSite` owners (A.2).
8. Optionally, normalize raw types (A.7) and make generic function types alpha-equivalent (A.4).

## Verification

Every step must pass:

```sh
dart analyze
dart test
dart run tool/generate_typed_machine.dart --check
dart test test/sdk_language/core_test.dart   # included in `dart test`; run alone for quicker iteration
```

- The SDK suite fails both when an expected-passing test fails and when an `expect_fail` test starts passing, so it detects behavior changes in both directions. An `expect_fail` change in phases 0–6 is either reverted or documented under the incidental-fix policy.
- `tool/ir_snapshot.dart --compare` against the phase 0 baseline shows where program output changed. Refresh the baseline after each explained change.
- Shadow-mode assertions (old and new lookup or derivation compared under `assert`) are temporary and removed in the step that deletes the old code.
- Run `dart run benchmark/compile.dart` at the end of each phase. Performance is not a primary constraint, but a large regression usually means a missing memoization (hash codes, `TypeDecl.supertypes`, `CallableAbi.of`).

## Risks

- **Equality flip (phase 3).** Any collection keyed by `TypeRef` that relied on nominal equality silently changes behavior. Mitigation: the A.4 audit, done in the same commit as the flip, with `commonBaseType` inputs kept nominal.
- **Function types answering `isSpec(Function)`.** Dropping the compatibility override before every check is classified changes dispatch decisions (`type == Function && methodOffset == null`). Mitigation: classify each site in phase 3.
- **Runtime type id order.** Changing when declarations or types are registered changes program output. Mitigation: create `TypeDecl`s at the same point `TypeRef.cache` runs today, and confirm with `ir_snapshot`.
- **Evaluation order.** Moving argument compilation into the binder can accidentally reorder receiver, argument, and member-read evaluation. Mitigation: `EvalOrder` on `MemberValueCall`, `BindingOptions.legacy`, and the characterization tests.
- **Name-resolution drift.** Unifying four cascades can change which declaration a name resolves to in edge cases (inherited members versus globals). Mitigation: shadow mode against each old cascade.
- **In-place boxing.** Removing the binding back-reference too early loses rebinding of locals after `boxIfNeeded`. Mitigation: keep `Variable.binding` until in-place boxing is deliberately removed, which is not part of this plan.

## File layout

```
lib/src/eval/compiler/
  type.dart                 barrel re-exporting types/* during migration
  types/
    type_ref.dart           TypeRef hierarchy, FunctionSignature, TypeParameterDef/Owner
    substitution.dart
    type_decl.dart          TypeDecl, SourceTypeDecl, BridgeTypeDecl, TypeDeclRegistry
    type_system.dart        asInstanceOf, assignability, least upper bound, flatten, unify
    type_factory.dart       annotations, bridge refs, aliases, TypeScope
    runtime_types.dart
  members/
    member.dart             MemberName, Member, SourceMember, BridgeMember, ResolvedMember
    member_lookup.dart
    call_signature.dart     CallSignature, ParameterSpec, DefaultSource
  values/
    value_rep.dart
    abi.dart                Abi, CallableAbi
    variable.dart           Variable, ValueFacts
    binding.dart            LocalBinding, BindingStorage
  names/
    denotation.dart         Denotation, Receiver, the name-resolution cascade
    reference.dart          Reference classes over denotations
  invoke/
    call_site.dart          CallSite, CallShape, ArgSource
    call_target.dart        CallTarget variants and emission
    call_resolver.dart
    binder.dart             ArgumentBinder, BoundCall, BindingOptions
    devirtualizer.dart
    intrinsics.dart
    accessors.dart          GetTarget, SetTarget
```

Keeping `type.dart`, `variable.dart`, and `reference.dart` as re-exporting barrels until phase 6 ends avoids touching every import during the migration.
