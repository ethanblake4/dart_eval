# Improvement loop 8 — 2026-09-26

Starting revision: dart_eval `b6ab89c` on `xv2`; control_flow_graph remains
`b901e65` on `main`.

## Step 1: strict function compatibility before type-test folding

`function_subtype/typearg5_test.dart` failed because strict function subtype
checks inherited declaration-inference leniency for foreign type parameters.
That let `List<F<X>> is List<F<Y>>` fold to true for unrelated class parameters.
The leniency is now limited to permissive compatibility checks. Strict checks
must prove compatibility; uncertain cases use the existing reified type test.

The SDK test passes. A fresh/serialized regression checks both direct literals
and dynamic operands, for equal and unequal reified class arguments. All 1,206
broader compiler/language/interop/runtime/stdlib/security tests and 11 focused
structural tests pass; changed-file analysis is clean. No runtime changes or new
bytecode checks beyond retaining previously required type tests.

## Step 2: generic bounds in strict nested function comparisons

The broader function-type survey passed all 61 runnable tests after Step 1.
Review of the same folding path found that generic bounds were ignored, so
`List<void Function<T extends int>()>` incorrectly tested as
`List<void Function<T extends num>()>` in both directions. A host Dart probe
confirmed both results must be false.

Strict function compatibility now compares the alpha-renamed bounds in both
directions. Permissive inference remains separate, and nongeneric signatures
skip the bound loop entirely. The regression covers both list literals and
dynamic operands and retains the positive alpha-renamed case.

Validation: 1,208 broader tests, 17 focused tests, and the full default suite
(1,701 passed, 62 skipped) pass. Rebuilt and reran all 61 function-subtype/bound
SDK tests: all passed, no timeouts. Changed-file analysis is clean. No runtime
changes, wrappers, boxing, or adapter paths were introduced.

## Step 3: empty substitution fast path

Function, record, and parameterized nominal types were rebuilt even when their
substitution contained no bindings. Empty substitution now returns the original
immutable type, and `Substitution.of` reuses its existing empty instance.

Added `benchmark/compile_pipeline.dart`: a typed middleware/ETL-style registry
of 64 list-processing callbacks. It validates serialized execution before timing
compilation. Both AOT variants emit 2,818 bytes and return checksum 6,054.
31-sample pinned runs measured 34.219 vs 35.383 ms, then 33.752 vs 33.069 ms with
order reversed. The mixed-feature compiler benchmark similarly showed no
repeatable difference (17.206 vs 16.768 ms; reverse 16.908 vs 17.053 ms).
This removes allocations, but the measurements do not establish an overall
compile-time speedup. No runtime changes.

Validation: 809 compiler/language tests pass and changed-file analysis is clean.

## Step 4: simplification and final validation

Removed a redundant dynamic-return condition: the preceding condition already
excluded every case it could match. Fixed the new benchmark's multi-line `if`
formatting lint and reviewed the empty-substitution paths for aliasing; TypeRefs
remain immutable, and nonempty substitutions retain their previous behavior.

Final default suite: 1,701 passed, 62 skipped. Analysis of all changed compiler
and benchmark files is clean; generated typed-machine verification matches all
220 instructions. The sibling control_flow_graph checkout is clean and remains
at `b901e65`. No runtime or stdlib edits were made in this loop.
