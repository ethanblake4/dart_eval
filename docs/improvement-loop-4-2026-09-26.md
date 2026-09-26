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
