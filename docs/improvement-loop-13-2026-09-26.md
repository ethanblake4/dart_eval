# Improvement loop 13 — 2026-09-26

## Step 1: Object? in generic function subtyping

The optional/named generic function signature matrices rejected valid relations
such as `Object? Function<T>(Object?, [Object?])` being a subtype of
`Object? Function<T>(T, [T?])`. Runtime comparison resolves the abstract
parameter's implicit bound to `dynamic`, whose supertype table contains only
itself. Walking that table could not prove `dynamic <: Object?`.

Subtype resolution now recognizes Object? as a top type, alongside dynamic.
This adds no bytecode, boxing, adapters, or interpreter dispatch changes. The
existing memoized subtype service retains the result. Three fresh/serialized
regressions cover optional/named signature variance, abstract and nullable
returns, negative comparisons against Object or a bound variable, and generic
collection returns. Native Dart probes validated their expectations.

The current 151-test generic/alias survey improves from 127 to 131 passes,
with three compile errors and 17 runtime errors remaining. Four tests newly
pass: generic_function_type_argument, method_types, named_parameters, and
optional_parameters. Removed the three corresponding explicit expected-failure
entries; generic_function_type_argument had no entry. Also removed the stale
instantiate_tearoff entry after both baseline and candidate passed it.

Baseline: dart_eval 789b4ee, control_flow_graph a0c339a. Survey artifacts:
`.dart_tool/loop13-baseline-sdk.jsonl` and `loop13-step1-sdk.jsonl`. Focused
regressions and targeted analysis pass.

The full suite passes 1,775 tests with 62 skipped. SDK core still records 34
expected runtime failures and 26 expected compile failures. Full log:
`.dart_tool/loop13-step1-full-tests.log`.

The final 22-driver AOT sweep matches all 21 execution checksums. Compilation
measures 11.840 -> 11.469 ms with unchanged 1,225 code bytes. Larger initial
call/closure timing outliers do not reproduce in reversed 51-sample comparisons:
call and closure cases range from -2.1% to +1.1%; longer async cases range from
-3.8% to +1.3%. Final executable: `.dart_tool/loop13-step1.exe`. Sweep results:
`.dart_tool/loop13-step1-sweep/`; repeat logs: `loop13-step1-repeat-*`.
