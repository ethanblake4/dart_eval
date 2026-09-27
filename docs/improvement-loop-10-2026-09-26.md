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
