# Improvement loop 11 — 2026-09-26

## Step 1: omitted generic function arguments

Dynamic invocation previously skipped type-argument bound validation when no
arguments were supplied. Runtime fallback followed raw bounds, so recursive
bounds such as `T extends Iterable<T>` entered the function instead of throwing.

Closure descriptors now carry finite instantiate-to-bound defaults computed by
the compiler's existing type-system helper, in declaration order. The compiler
retains parameter definitions instead of a duplicate list of their bounds.
Bytecode version 127 serializes and validates the new defaults. The interpreter
source generator supplies the callee's resolved defaults through its existing
fallback type environment; checked invocation and parameter checks use the same
arguments. Defaults resolve once per closure/runtime against the captured class
and callable environment. Nongeneric calls do not allocate type arguments.

An initial implementation repeated default resolution checks at frame entry and
regressed closure benchmarks by 7–8%. Reusing the resolved entry environment
removed that regression: a 31-sample AOT repeat measured closure cases from
-2.2% to +1.3% against the untouched baseline. The final 22-driver AOT sweep matches all 21 execution checksums. The
largest positive execution delta after repeating the lone >5% outlier is +4.2%;
compile time is 14.391 -> 14.632 ms (+1.7%) with 1,225 code bytes unchanged. Baseline was built at dart_eval
fae56c7 and control_flow_graph 291b1f4 before editing. Logs are in
`.dart_tool/loop11-verified-sweep/`; the final binary is
`.dart_tool/loop11-sweep-final.exe`. A 51-sample interval-overlap repeat
resolves the initial +7.1% outlier at 7.788 -> 7.697 ms (-1.2%), with the
same checksum.

The SDK generic/function_bounds_test now passes its instantiate-to-bounds and
argument-checking sections. Its type-formatting section still fails the first
signature pattern, and its subtype section accepts a G<double> cast that should
fail. The test remains expected-failing. A separate existing issue confuses
outer and inner callable parameter owners by position; composite captured bounds
such as `U extends List<T>` need owner-aware environments in a later step.

The default suite passes 1,737 tests with 62 skipped, including seven new
fresh/serialized regressions. Final review added a low-level cache-lifetime
regression: a runtime-free closure discards cached type IDs before a context-free
call. That test and all seven language regressions pass after the correction.
Analyzer is clean for changed source and tests; generated interpreter output is
verified by the runtime suite. Expected-failure SDK statuses remain unchanged.


## Step 2: generic signature identity, substitution, and display

Generic function aliases previously interned their inner parameters using only
the annotation's source position. Resolving `G<num>` could fix the inner bound
for later `G<int>` or `G<double>` references. Annotation binders now specialize
by their outer type environment; declaration/body owners remain canonical.
Substituting an outer argument also substitutes generic bounds, cloning and
renaming the inner binder when its bounds change instead of mutating shared
parameter definitions.

Raw aliases now choose recursive default holes using the alias parameter's
variance. Covariant and contravariant occurrences use opposite extrema; invariant
occurrences use dynamic in both directions. This preserves generic assignments
through both ordinary and nested function aliases.

Runtime signature bounds retain their symbolic references for subtype checks and
display. Type-parameter fallback descriptors still break cycles, including the
previously failing mutually recursive class-bound case. Generic type strings show
bound variables, dependent bounds, and nested scopes. Local function signatures
also retain explicit return annotations instead of replacing them with a narrower
body-inferred type. No interpreter dispatch or stdlib binding changes are needed.

The complete SDK generic/function_bounds_test now passes and its expected-failure
entry is removed. The neighboring generic/f_bounded_quantification3_test and both
super_bounded_types_and_variance tests also pass. A fresh AOT survey of 151
runnable generic, generic-method, and alias tests passes 113, with 38 known
failures and no timeouts or unexpected outcomes. Results are in
`.dart_tool/loop11-step2-verified-sdk.jsonl`.

The full project suite passes 1,746 tests with 62 skipped. Three additional raw
alias variance/bound-substitution regressions pass separately, in both fresh and
serialized runtimes. Focused tests also cover alias resolution order, dependent
and nested generic type display, explicit return types, and mutual class bounds.


The final 22-driver AOT sweep matches all 21 execution checksums. Compilation
measured 15.251 -> 14.415 ms with 1,225 code bytes unchanged. 51-sample repeats
resolve the positive execution outliers: virtual calls range +1.2% to +2.4%,
callbacks -1.7% to +3.7%, and the actual typed dispatch cases -0.1% to +0.2%.
The benchmark's separate synthetic object-reference dispatch loop remains up to
12.4% slower; it is not dart_eval's interpreter. Async callback is +0.7% on
repeat. Logs are in `.dart_tool/loop11-step2-verified-sweep/` and
`.dart_tool/loop11-step2-repeat-*`. Baseline is bb55aac; final candidate is
`.dart_tool/loop11-step2-final-sweep.exe`. Analyzer is clean for changed files.

## Step 3: sparse compiler graphs

The compile-pipeline profile still spent 189 of 810 compiler samples building
SSA. Graph construction was a substantial part of that cost. The graph library's
positive-integer strategy uses an indexed list for every adjacency map, allocating
through the largest neighbor ID even when a block has only one successor.

control_flow_graph a0c339a switches CFG, DJ, and dominator-tree storage to ordinary
insertion-ordered maps. SSA renaming also reuses cached dominators and transfers
the version map to the last dominated child, copying only for siblings. Phi
insertion skips merge-set computation when there are no global variables.

Two 51-sample AOT pipeline comparisons measured 25.561 -> 20.799 ms and
25.555 -> 20.864 ms (about 19% faster). A 101-sample reverse-order repeat measured
30.134 -> 20.076 ms. All produced 2,818 code bytes and checksum 6,054. The full
22-driver AOT sweep matched all 21 execution checksums; its mixed-feature compiler
benchmark measured 13.960 -> 11.539 ms (17.3% faster), retaining 1,225 code bytes.

51-sample repeats resolved execution outliers in calls, closures, and external
calls (largest remaining increase 3.2%). Async measurements were noisy at 250
iterations; repeating with 2,500 iterations left every case unchanged or faster.
Artifacts: `.dart_tool/loop11-step3-sweep/`, `loop11-step3-repeat-*`, and
`loop11-step3-pipeline-*`. Baseline executables use dart_eval a18eb05 and
control_flow_graph 291b1f4. No runtime changes were needed.

All 104 control_flow_graph tests pass, and analysis of the four changed source
files is clean. The complete dart_eval suite passes 1,749 tests with 62 skipped.
Its SDK core harness still records 35 runtime failures and 26 compile errors
covered by expected-failure entries; this checkpoint does not complete the goal.
