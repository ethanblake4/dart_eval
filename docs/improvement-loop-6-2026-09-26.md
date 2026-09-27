# Sixth improvement loop, September 26, 2026

Starting revision: dart_eval `e30f2aa` on `xv2`; control_flow_graph remains
`b901e65` on `main`.

## Step 1: interface conformance and async test completion

The fresh isolated survey identified missing-implementation errors in classes
that inherit a user-defined `noSuchMethod`. Interface conformance now uses
the existing implementation lookup to recognize superclass and mixin handlers.
Only missing members are excused; incompatible concrete implementations still
fail. Private interface members from other libraries do not require a locally
nameable implementation. Sealed classes are treated as implicitly abstract by
both interface and mixin conformance checks.

Nine previously failing SDK tests now pass:

- `generic/mock_test.dart`
- `no_such_method/nsm4_test.dart`
- `mixin_declaration/mixin_declaration_nsm_test.dart`
- `inference_update_2/field_promotion_and_no_such_method_abstract_field_test.dart`
- `regress/regress25550_test.dart`
- `regress/regress30121_test.dart`
- `regress/regress33009_test.dart`
- `sealed_class/sealed_class_extend_test.dart`
- `sealed_class/sealed_class_implement_test.dart`

The private-setter multitest now reaches its intended runtime error instead
of failing compilation. It still needs SDK multitest outcome handling, so
its expected-failure status remains. Related promotion/noSuchMethod restriction
tests now reach runtime failures or later compiler failures and remain open.

The SDK harness and diagnostic runners now await async `main` results. A
synthetic test confirms that an error after a delayed await reports failure.
Synchronous mains launching callbacks through the existing `async_helper`
shim are still not fully awaited; that needs separate completion tracking.

Validation: default suite passes 1,682 tests with 62 skips. The added negative
conformance regression also passes, and the focused inheritance/async-harness
run passes 36 tests. Changed-file analysis is clean. No runtime changes or
extra bytecode checks.

## Step 2: inherited covariant parameter annotations

Interface conformance required contravariance even for parameters marked
`covariant` in a superclass or superinterface. The member lookup now exposes
the explicit annotations using its existing hierarchy traversal, and override
checks accept narrowing for those parameters. Unrelated types remain invalid.
Covariance induced by a generic class parameter is kept separate: it affects
runtime checks but does not by itself authorize a narrowed override, verified
against the host Dart analyzer.

Three previously failing SDK tests now pass:

- `covariant/override_covariant_class_test.dart`
- `regress/regress31596_covariant_declaration_test.dart`
- `unsorted/cascaded_forwarding_stubs_test.dart`

The forwarding tear-off tests now get past conformance and reach distinct
runtime-signature assertions. Three other covariant tests still report missing
runtime checks. Their failure statuses remain.

Validation: the compiler/language/interop/runtime/stdlib/security run passes
1,195 tests. The focused inheritance suite passes 37 tests, including inherited
positional/named covariance and rejection of unrelated parameter types. No
runtime changes or additional call-site checks were introduced.
