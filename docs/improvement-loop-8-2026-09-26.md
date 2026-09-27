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
