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


## Step 2: raw generic defaults and String comparability

Raw generic types previously skipped argument comparisons. This made a raw
`Box` count as a subtype of `Box<int>` and erased constructor type arguments.
Declarations now cache their instantiate-to-bounds defaults. Constructor
results, subtype checks, and runtime type descriptors use those defaults.
Raw supertypes use their own bounds rather than inheriting unrelated arguments
from a child class. Legacy bridges without parameter declarations retain their
existing compatibility behavior.

The stricter comparison exposed an instantiate-to-bounds variance error.
An acyclic dependency used only in a callback parameter now closes to `Never`;
covariant and invariant dependencies retain the resolved upper bound. The SDK
nested-variance matrix and the existing alias/bounds regressions pass.

String's bridge metadata omitted `Comparable<String>`, which the SDK declares
alongside `Pattern`. Added that superinterface to the existing hand-maintained
String declaration. This is the configured exception in `.dart_eval/bindgen.yaml`:
String is marked `handMaintained`, and the generator skips it. No generated
stdlib files were edited. No interpreter, runtime helper, opcode, additional
boxing, or runtime-check instructions were added in this step.

Five fresh/serialized regressions cover raw construction and factory results,
dependent bounds, raw supertypes, callback variance, and String comparability.
The 151-test survey improves from 131 to 134 passing with no regressions;
three compile failures and 14 runtime failures remain. Newly passing tests are
`generic/instanceof2`, `generic/native`, and `generic_methods/new`. SDK core
also gains `constructor/constructor12` and `type/guard_conversion`. Removed
all five expected-failure entries.

Validation: 1,780 tests pass, 62 skipped. SDK core records 430 passes, 32 expected
runtime failures and 26 expected compile failures. Targeted analysis is clean;
21 focused bounds/alias tests pass. Logs: `.dart_tool/loop13-step2-final-full.log`,
`loop13-step2-sdk.jsonl`, `loop13-step2-final-analyze.log`, and
`loop13-step2-bounds-final.log`.

The remaining `generic/instanceof` failure was localized to `List<T>.filled`
losing runtime type arguments in its wrapper. That investigation is retained
for a later correctness pass; this checkpoint does not alter List construction.


The final 22-driver AOT sweep matches all 21 execution checksums. Baseline is
4f2f939, candidate executable `.dart_tool/loop13-step2.exe`, with unchanged
control_flow_graph a0c339a. Results are in `.dart_tool/loop13-step2-sweep/`.
Initial timings were noisy, including native controls. Longer 51-sample repeats
put closures, async, exceptions, external calls, dispatch, and templates within
-6.5% to +3.4%. Compilation measures 9.691 -> 9.210 ms with unchanged 1,225 code
bytes. Callback repeats range from -10.3% to +1.3%. Call timing outliers reverse
direction with reversed process order, including large swings in unchanged
scalar cases; these runs do not establish a call performance gain or regression.
Repeat logs are `.dart_tool/loop13-step2-repeat-*` and `loop13-step2-repeat2-*`.
