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

### Async helper completion follow-up

The runner now retains and drains the guest async helper after `main` returns.
`asyncTest`, manual `asyncStart`/`asyncEnd`, and async exception assertions are
tracked, so synchronous mains cannot hide failures in registered async work.
Four focused harness regressions pass. The default suite passed 1,692 tests
with 62 skips while the scalar-capture experiment was present; that experiment
was subsequently discarded after neutral benchmark results.

## Step 3: capture experiment and compiler hierarchy lookup

Added `benchmark/scalar_callbacks.dart` for pricing callbacks that retain final
integer configuration. An experiment boxed immutable scalar snapshots instead
of allocating typed capture cells. It passed focused and full tests, but a quiet
21-sample AOT repeat measured 119.807 ms baseline versus 119.466 ms candidate.
That neutral result did not justify extra boxing, so the experiment was reverted.
The benchmark remains available for future representation work.

Override conformance now lazily collects inherited covariance annotations only
when normal parameter compatibility fails. This avoids hierarchy traversal and
set allocation for ordinary overrides without changing generated guest code.
The existing mixed-feature compiler benchmark produced 1,225 bytes for both
versions. Pinned AOT runs measured 26.266 vs 18.035 ms (51 samples, candidate
first) and 25.873 vs 18.134 ms (101 samples, baseline first). Timing ranges were
wide on this host, so the roughly 30% median difference is not a general speedup
claim. The change removes work independently of those timings.

Validation: all 37 inheritance tests pass, including explicit positional and
named covariance and unrelated-type rejection; changed-file analysis is clean.
No runtime changes were made.

## Step 4: simplification and generated-code check

Shared the abstract/sealed-class predicate between interface and mixin
conformance so those paths cannot drift independently. Reviewed the async
helper changes and capture experiment; the rejected capture changes are absent
from the final tree. The focused inheritance and SDK async harness suites pass
41 tests, changed-file analysis is clean, and generated typed-machine output
matches its generator. No stdlib or runtime files were edited in this loop.
