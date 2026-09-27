# Improvement loop 10 — 2026-09-26

Starting revision: dart_eval `909ea4e` on `xv2`; control_flow_graph remains
`b901e65` on `main`.

## Step 1: extendable Iterable and SDK aliases

The current SDK defines IterableBase and IterableMixin as typedefs of Iterable.
The binding configuration previously registered IterableBase only as a type
specification, and Iterable's wrapper could not be extended. The binding
generator now copies selected SDK typedef declarations into a generated
DartSource and generates an Iterable bridge alongside the existing collection
wrapper. The wrapper's collection semantics remain in place.

Generating this bridge exposed missing support for abstract constructors,
generic bridge classes/methods, default values, and the register ABI of inherited
methods. These are fixed in the generator. Native factories on bridge classes
return wrapped native values, including boxing iterable elements. The existing
wrapper is retained through the new handMaintainedWrapper configuration option.
All binding bodies and typedef declarations are generated from SDK sources.

SDK superclass methods can consume a guest-defined Iterator through a host
adapter. This allocation occurs only when crossing that interface boundary;
ordinary iteration and the interpreter dispatch loop are unchanged. Constructor
lookup resolves typedef superclasses to their actual declaration. Exact-type
optimizations now reject native facades for direct field/accessor access and
ordinary direct method calls; lexical super calls retain their required direct
target.

Focused fresh/serialized tests cover inherited length/first/contains/elementAt,
map/toList, the IterableBase alias, and super.length. Three more sync_star tests
and loop/for_in_side_effects_test now pass; their expected-failure entries are
removed. Iterable-as-mixin and async* remain separate work.

Review added fresh/serialized regressions for wrapped list iterators,
Iterable.withIterator returning a guest iterator, map returning guest objects,
and followedBy receiving another guest iterable. Generated superclass calls and
native bridge factories now explicitly export callback results and iterable
arguments; ordinary wrapper output retains its existing calling convention.
Iterator elements are exported lazily, preserving guest object identity.

Validation: the 90 focused superclass, stdlib, bridge-inheritance, and binding
generator tests pass. Analyzer reports no issues in the changed generator,
runtime adapter, or generated Iterable bridge. Regeneration produces 47 binding
files without changes to existing generated wrappers.

The final default suite passes 1,721 tests with 62 skipped. The SDK core runner
reports 427 passing cases, with 35 known failures and 26 known compile errors
still tracked by the suite; this is not an all-SDK-pass claim.

The final 22-driver AOT sweep uses the pre-change generator-delegation candidate
as baseline, 15 samples per driver, alternating order, and CPU affinity mask 4.
All 21 execution checksums match. Compiler median is 17.407 ms versus 17.766 ms
baseline (-2.0%); application benchmark medians range from -4.8% to +1.8%.
Logs and summary are in `.dart_tool/iterable-bridge-sweep/`.

The initial closure-direct (+5.1%) and bound-callback (+5.0%) outliers do not
persist in 51-sample reversed-order repeats: -0.4% and -0.7%, respectively,
with matching checksums. All repeated closure cases fall between -0.9% and
-0.2%; callback cases range from -11.8% to +1.7%. No persistent regression was
observed in these measurements.

## Step 2: generic declaration identity and bounded alias inference

Captured local generic functions previously shared the default placeholder
owner for an entire library. A later declaration could reuse an earlier
function's parameter count and bounds. Default declaration owners now include
the type-parameter list's source position. A focused fresh/serialized regression
uses two captured functions with different parameter lists and bounds.

Constructor aliases also discarded their own declared bounds during contextual
inference. For `T<X extends int> = C<List<X>>`, a `C<Iterable<num>>` context
incorrectly instantiated X as num. Alias parameters now share resolved bound
definitions; inferred arguments intersect with those bounds before expansion.
Dependent bounds propagate across parameters, including forward references
and parameters omitted from the alias body. Bare aliases resolve default
arguments through their bound dependencies; references within a cycle close to
dynamic, or Never in a contravariant function parameter. Self, mutual, and
contravariant defaults were checked against native Dart. Instantiated legacy
function aliases retain no signature-owned generic parameters.

Focused tests cover generative, factory, and redirecting-factory aliases and
forward-dependent bounds, each with fresh and serialized runtimes. These are
compiler changes only: no added bytecode checks, adapters, or runtime changes.
The three SDK `infer_aliased_*_11_test.dart` cases now pass and their expected
failures are removed. The generic/function_bounds test now compiles and reaches
a separate runtime failure: omitted type arguments do not reject a super-bounded
instantiation. That remaining failure stays tracked.

Explicit constructor syntax now also preserves the alias expansion:
`T<int>` for `T<X> = C<List<X>>` constructs `C<List<int>>`, including named
factories. Previously the raw syntax arguments overwrote the expanded ones.

The default suite passes 1,730 tests with 62 skipped; all nine focused tests
pass after the final variance correction. Analyzer is clean for the changed
compiler files and focused tests.

A fresh post-correction AOT runner verifies all 65 runnable nonfunction alias
tests plus eight legacy function-alias regression cases: 56 pass, 17 retain
their known failures, and none time out. All eight regression cases pass.
There are no unexpected outcomes against the updated statuses. Results are in
`.dart_tool/loop10-step2-verified-alias-and-regressions.jsonl`.

## Step 3: lazy SSA def-use graph materialization

A fresh CPU profile of the 64-stage compile_pipeline workload found backend
graph work dominating compilation: buildSSA accounted for 280 samples and graph
vertex lookup for 206, out of 896 samples under _compileSources. The SSA edge
graph duplicated existing definition/use maps and was rebuilt during renaming
and every metadata refresh, even though internal consumers only maintained it.

control_flow_graph now constructs that graph on first access. SSA renaming and
refresh retain the indexed maps; dead-code removal invalidates the cached edge
view. The standalone SSAComputationData graph getter remains available and lazy.
The cache's lifetime is documented, and five focused tests cover edges, rewrite
refresh, clone refresh, and DCE before/after graph access. No runtime or bytecode
changes are involved.

Two AOT comparisons of compile_pipeline (31 samples, 64 stages, CPU affinity 4,
reversed run order) measured 36.708 -> 25.737 ms and 32.767 -> 25.186 ms:
29.9% and 23.1% lower compilation medians. Both produced 2,818 code bytes and
checksum 6,054. Baseline binaries were built at dart_eval 9c90056 with sibling
control_flow_graph b901e65 before editing. Logs use `.dart_tool/loop10-pipeline-*`.

Validation: 104 control_flow_graph tests pass, and dart_eval's default suite
passes 1,730 with 62 skipped. Analyzer is clean for the changed graph files.
The full 22-driver AOT sweep matches all 21 execution checksums. The standard
compile driver improves from 17.465 to 14.199 ms (-18.7%), retaining 1,225 code
bytes. Logs are in `.dart_tool/loop10-lazy-ssa-sweep/`.

51-sample reversed-order repeats resolve initial execution outliers: typed
dispatch medians are unchanged, call cases range from +0.1% to +1.5%, and global
cases from -5.7% to +0.1%. The synthetic object-reference interpreter in the
dispatch benchmark remains 6.5–7.9% slower; this is the benchmark's separate
comparison loop, not dart_eval's interpreter. Async callback repeat is +2.1%;
other async cases range from -36.8% to unchanged. All repeat checksums match.

Performance implementation checkpoint: control_flow_graph `5ce204c` on main.
