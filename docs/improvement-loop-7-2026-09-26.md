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
