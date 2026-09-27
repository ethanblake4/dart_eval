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
