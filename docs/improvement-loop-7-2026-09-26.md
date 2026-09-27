# Improvement loop 7 — 2026-09-26

Starting revision: dart_eval `1c16104` on `xv2`; control_flow_graph remains
`b901e65` on `main`.

## Step 1: field accessor conformance and refreshed statuses

Conformance incorrectly treated a final field as a concrete setter, rejecting
classes that should forward the interface setter to `noSuchMethod`. Field
matching now checks whether the requested accessor exists, including setters
for uninitialized late-final fields, and examines every variable in grouped
field declarations. Signature checking uses the same accessor availability.

`unsorted/mock_writable_final_field_test.dart` now passes. Regression tests
cover inherited `noSuchMethod` setter forwarding, late-final setter interfaces,
and multiple fields declared together, both fresh and serialized.

Rechecked the 21 stale expected-failure passes from the survey with the final
async-aware runner. Twenty still pass and their statuses were removed.
`async/await_type_check_test.dart` now exposes its existing failure after
awaiting main and remains listed. No failures were newly exempted.

Validation: 1,197 compiler/language/interop/runtime/stdlib/security tests pass;
39 focused inheritance tests pass; changed-file analysis and diff checks are
clean. No runtime or generated stdlib changes.

## Step 2: scoped generic function type identity

Function signature equality normalized every generic binder to the same
placeholders, so nested references to an outer parameter could collide with
references to an inner parameter. It also omitted parameter bounds entirely.
Runtime descriptor interning consequently merged distinct function types before
the runtime checker saw them.

Signature equality and hashing now use one structural key with scoped binder
indices, free-parameter identity, and parameter bounds. This handles nested
functions, interface arguments, and records without substituting new TypeRefs.

Four SDK tests now pass:

- `function_subtype/nested_function_type_test.dart`
- `function_subtype/generic_function_type_substitution_test.dart`
- `nnbd/subtyping/function_type_bounds_test.dart`
- `nnbd/subtyping/function_type_bounds_strong_test.dart`

Removed the strong-bound test's expected-failure entry. `typearg5_test.dart`
remains a separate failure and was not reclassified.

Validation: 1,197 broader tests and five new equality/hash regressions pass.
The mixed-feature compiler benchmark still emits 1,225 bytes; pinned AOT
51-sample medians were 21.271 ms before and 17.679 ms after, with wide timing
variance. No apparent compiler regression, and no runtime changes.

## Step 3: reuse nominal leaves in signature keys

Plain nominal types without arguments cannot contain bound signature references.
The structural key now reuses those TypeRefs and their cached hashes rather than
allocating a five-element key plus an empty argument list for every occurrence.
Binder-bearing and structural types still use the scoped representation.

Fresh pinned AOT compiler benchmarks (101 samples, ten warmups) measured
17.099 vs 16.874 ms, then 16.859 vs 16.839 ms in reverse order. Both emitted
1,225 bytes. The repeat is effectively neutral: this is an allocation reduction,
not evidence of a measurable overall compiler speedup. All five identity tests
pass and changed-file analysis is clean. No runtime changes.

## Step 4: review and bound-reification regression repair

The full default suite exposed `closure/tearoff_bounds_instantiation_test.dart`:
old signature interning had hidden the loss of class parameters in method bounds.
`C<T>.foo<S extends T>` described S's bound as dynamic instead of preserving T.

Descriptor construction now preserves class-owned references, including nested
`List<T>`, while retaining the existing finite erasure of cyclic callable bounds.
The existing erasure helper accepts a set of owner kinds to preserve. Runtime
reification retains a generic signature parameter's owner/index but resolves its
bound against the receiver environment. No opcode, dispatch-loop, adapter, or
call-site check was added. Reviewed the structural key and accessor helpers for
scope, nullability, named-order stability, and duplication; retained their small
shared helpers.

Validation: the default suite passes 1,699 tests with 62 skips. Three descriptor
regressions and the runtime test cover direct/nested class bounds, cyclic bounds,
subtype checks, and fresh/serialized execution. The SDK tear-off test passes.
Changed-file analysis and generated typed-machine verification are clean.

Before committing the runtime-helper change, ran the complete 22-driver AOT
sweep against a freshly compiled baseline at `5815a39`, pinned to affinity 4,
15 samples each, alternating order. All 21 execution checksums matched and both
compiler outputs remained 1,225 bytes. The sweep completed in 51 seconds;
artifacts are `.dart_tool/goal-loop7-reification-sweep/`.

31-sample repeats resolved the initial call/virtual-call outliers (each within
2% of baseline). Local-loop and string-field medians remained about 8% and 6%
slower respectively, despite those workloads not using bound reification.
These results are recorded rather than attributed to noise without evidence.
Most larger sweep workloads were within 3%; this correctness repair does not
claim an execution speedup. Benchmark logs for repeats are
`.dart_tool/goal-loop7-repeat-*-{baseline,candidate}.log`.
