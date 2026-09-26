# Fourth improvement loop, September 26, 2026

Starting revisions: dart_eval `395d9e5` on `xv2`, control_flow_graph `main`.
Linux x64, Dart SDK, CPython harness for the sdk_language suite.

## Step 1: failing sdk_language tests

The suite opened with 730 `expect_fail` entries. This pass fixed several
root causes and re-ran the full expected-failure sweep; 78 entries now pass
and their statuses were removed so regressions fail loudly.

### Call-site type coercion erased enclosing type parameters

`function_subtype/checked0_test.dart` rejected a `Foo<bool>` value passed to
a generic closure's `Foo<T>` parameter. Argument binding lowered *every* type
parameter in the formal to its bound before emitting the runtime `AssertType`,
turning `Foo<T>` into `Foo<dynamic>`-checks that dropped the class-level
parameter even though the frame's `actualOwnerType` binds it at runtime.

`bindParameterList` now lowers only the callee's own signature parameters
(`lowerTypeParameters(only: signature.typeParameters)`). Class and
enclosing-scope parameters survive into the emitted check, where the runtime
resolves them against the owner's actual type arguments. The emitted bytecode
is unchanged in count — the check was already there; it now carries the
correct type descriptor.

### Devirtualized member-name keys and interface signature binding

Calls on members declared through a mixin used the interface's signature for
devirtualized dispatch and dropped the implementation's defaults and member
key. Three linked fixes:

- `Devirtualizer` resolves the member key through `ctx.memberNameOf` (a
  private member folded in from another library registers as `uri::_name`)
  and skips mixin links in `directImplementationOwner` — a mixin hosts no
  compiled implementation; its members exist only as copies folded into each
  applying class.
- Devirtualized `StaticCall`s now pin `signature: target.signature` (the
  interface signature) for coercion — an implementation may narrow bounds
  that only hold for its checked stub — while a new `defaultsSignature`
  parameter threads the implementation's own signature through
  `bindDeclaration`/`bindParameterList` so omitted arguments take the
  *dispatch* target's default values, matching Dart semantics.
- `CallResolver` seeds bound-signature owner arguments from both the
  receiver's view and the declaring link.

### Control-flow graph: terminator edges

`flushBlock` and the switch statement's tail used `builder.then`, which
unconditionally linked every pending block to the next — including blocks
already closed by `return`/`throw`/`jump`. That produced phantom fallthrough
edges that made `nnbd/flow_analysis/write_promoted_value_in_switch_test.dart`
and others mis-merge states. control_flow_graph gained
`BasicBlockBuilder.thenUnlessTerminated`, which links only blocks whose last
op is not a terminator, and the compiler's `isTerminatorOp` predicate covers
the frontend op set.

### Switch `continue` to a case label

`L: case e:` makes `L` a `continue` target into the case body. Switch
compilation now preallocates an entry block per labeled case, registers a
`continueTarget` label that collects each jumping edge's state, and merges
those states when the case body is entered — covering both direct dispatch
and `continue L` jumps.

### Labeled statements: inner declarations survive restore

Declarations inside a labeled statement live in the enclosing block's scope
but were discarded when the labeled statement restored its pre-statement
context state. `compileLabeledStatement` now re-adds bindings whose identity
differs from the restored state's.

### Smaller fixes

- `for-in`: pending label names were drained by whichever specialized branch
  compiled first; both the index and iterator branches now re-seed them.
- Tearoff materialization probes both `uri::_x` and `_x` spellings in the
  declaration map, and instance-member tearoffs resolve their file via
  `ctx.enclosingLibrary`.
- `_TrivialGetterCall` re-types the receiver to the proven owner before
  replaying its forwarded chain (private fields are not declared on the
  receiver's interface type).
- `TypeSystem.supertypeIds` caps instantiated-supertype emission relative to
  the root type's own argument depth instead of a global bound — a bound
  instantiation legitimately adds nesting per hierarchy hop.
- `CallSignature.forDeclaration` uses the enclosing class-like as a method's
  `parameterHost` (a constructor still hosts itself).
- Anonymous-method invocations rebind the result local to the merged
  common-base type so later bound-refresh keeps the LUB.

### Validation

- `dart test test/compiler/ test/language/ test/interop/ test/runtime/
  test/stdlib/ test/security/` — all pass (1,175+).
- Full expect_fail sweep: 78 of 730 entries removed from `suite.yaml`; the
  remaining 4 stragglers checked by hand still legitimately fail
  (evacuation failure / timeouts / a crash).
- `dart analyze` on changed files: clean.

## Step 1, round 2: strict assignability and promotion regressions

Re-swept the 155-entry regression list against a rebuilt AOT runner;
fixed three more root causes. 53 tests still fail — all are now listed in
`expect_fail` with reasons (they were previously unlisted).

### Extension `on T` binds the receiver's non-nullable part

`matchExtensionOn` bound the receiver type verbatim, so `x.m()` on an
`int?` receiver under `extension E<T> on T` resolved `T := int?` — making
`R extends Exactly<T>` bounds check against `int? Function(int?)`, which
correctly rejects `int Function(int)`. Real Dart binds `T := int` (the
non-nullable part) — verified against the analyzer — so `matchExtensionOn`
now unifies a bare non-nullable type-variable pattern against
`receiverType.withNullable(false)`. Composite patterns (`on List<T>`)
still bind inner nullability verbatim.

### Type-argument bound checks use assignability, not subtyping

`R extends Exactly<T>` rejected `Object Function(Object)` against an
inferred `dynamic Function(dynamic)` bound — contravariantly, `dynamic <:
Object` is not a subtype relation, but Dart's bound conformance tolerates
`dynamic` on the parameter side while still rejecting it on the covariant
side (`Exactly<dynamic>` under an `Exactly<int>` bound fails, also
verified). `_resolveInvocationGenerics` now checks bound conformance with
`allowDynamicParameterDowncast: true` (strict `forceAllowDynamic: false`
retained, so `dynamic` itself is still not a valid argument).

### Uninferable call type arguments instantiate to their bounds

`bindSuppliedOnly` bound-defaulted every uninferred parameter but still
forwarded the (placeholder-only) `runtimeTypeArguments` list, so the
callee saw zero real type arguments. When nothing was actually inferred
the binder now emits an empty list, letting the callee instantiate to its
own bounds. Symmetrically, `instantiateRuntimeCallable` defaults unbound
signature parameters to `(parameter.bound ?? dynamic).lowerTypeParameters`
instead of returning the value unchanged — `runtimeTrue ? test : () {}`
under `void Function()` instantiates correctly. `convertForAssignment`/
`convertInitializer` also attempt `_instantiateGenericFunction` before
`.call` tear-off, so generic tear-offs coerce into non-generic function
slots.

### Known remaining root causes (53 tests, in `expect_fail`)

- **Promotion-chain layering** (~45 tests): sound-flow-analysis keeps a
  *chain* of promoted types per variable; joins intersect chains
  (`[num]`+`[num,int]` → `num`, `[num]`+`[int]` → nothing) and `finally`
  entry demotes try-promotions. Our flow tracking keeps a single current
  type, so joins/entry states disagree — a larger feature.
- **FutureOr degradation** (~2): `FutureOr<T>` is a union the compiler
  can't represent; it degrades to `dynamic`, poisoning `await` receiver
  types. Bound checks now tolerate the fallout; the union itself needs
  representation work.
- Runtime generic-function instantiation of stored closures with
  optional parameters (`instantiated_function_constant`), generic
  `.call`-method inference (`issue_56666`, `issue_61218*`), mixin-aliased
  typed direct-call targets (`private_name_mixin`), horizontal inference
  (`inference_update_1`), record field-name mismatch inference.

### Assignment context and promotion retention

`implicit_tearoff_local_assignment_test` exposed two related bugs:

- The RHS of a local `x = e` was inferred against `x`'s *current*
  (possibly promoted) type. Per the test (which pins the implemented —
  not fully spec-matching — behavior), the coercion context is the
  variable's *declared* type: `x` promoted to `Object Function()` still
  accepts `x = B()` without tearing off `B.call`. `rhsContext()` now
  returns `binding.declaredType` for local targets.
- `LocalBinding.write` retained a conforming promotion by adopting the
  *stored* type (`stored.type`), which over-promoted: `Object x = B();
  x as B; x = C()` should keep `x` at the promoted `B`, not `C`. The
  write now picks the most specific `typesOfInterest` entry the stored
  value still conforms to (`C <: B` → `B`), falling back to the declared
  type when none match.

`Map.[]`'s declared signature is `V?` — `IndexedReference`'s map fast
path now returns `V.withNullable(true)` for both `resolveType` and
`getValue`, so `String? e = m['k']` no longer incorrectly promotes to
non-null `String` (which made `e != null` fold to `true` and skipped the
`else` arm in the missing-key path).

`switch` end blocks that a `break` statement can still target must not
count as "always throws": `compileSwitchStatement` only propagates
`willAlwaysThrow` when `breakStates.isEmpty`. Similarly the `??` fast
path treated a `Null`-typed LHS as non-nullable (`Null` is not
`.nullable` but is *always* null), so `null ?? 1` truncated the rest of
`main`; `thenEdgeUnreachable` now excludes `Null` LHS.

### Regressions found and fixed in the same pass

- `typedef void Foo<A,B>(A a, B b)` applications (`Foo<Bar.A,Bar.B>`) lost
  the argument substitution when `signatureFromParts` was switched to
  always carry `typeParameterList` — the alias's parameters are the
  signature's generics only in the unapplied (`rawParams`) case; applied
  uses must resolve through `bindings`. Restored the gate (was masking as
  `Cannot assign Function to Function` on any generic-typedef field
  assignment).
- `compileSuperExpression` attached `#this`'s `LocalBinding` to the
  `LoadSuper` result so `super._f` member promotions could read/write
  facts — but `binding` means "this variable is the binding's storage":
  every binding-aware path (`unboxIfNeeded`, `boxIfNeeded`, writes)
  substituted `#this`'s current value for the `super` SSA, so
  `super.m(args)` dispatched on `this` → infinite recursion (OOM). The
  binding attach is reverted; `_promotedFieldType` now consults
  `ctx.lookupBinding('#this')` directly for the `super:`-keyed facts.
- `switch/switch_comparisons_1_test` moved out of `expect_fail` — the
  suite counts expected-failures-that-pass as failures.

Result: full `dart test` green — 1663+488 tests, only pre-existing
`expect_fail` entries.
