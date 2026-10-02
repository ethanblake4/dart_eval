# Improvement loop, 2026-09-30

Baseline: dart_eval `d0922b2`, control_flow_graph `a0c339a`.
Evidence lives in `.dart_tool/improvement_loop/`.

## Correctness pass 1

The ordinary suite had 13 errors plus one SDK core mismatch. The SDK full
suite had 25 unexpected mismatches and still contains listed expected failures.
The sibling CFG suite passed all 104 tests.

Async return validation rejected erased Future results after replacing the
payload check with strict FutureOr assignability. Accept an erased payload at
this compiler boundary; the existing async completion validates the actual
payload. Statically incompatible concrete payloads remain rejected.

Throw-only block closures inferred Null because their return collection was
empty. Infer Never when the body has no return values and cannot fall through;
fallthrough already contributes Null. This restores Future.then callbacks that
only throw. Updated the IR effects fixture for Await's type descriptor argument.

No runtime, opcode, extra boxing, or emitted check changes in this pass.
Targeted analysis is clean; async and IR effects suites pass all 61 tests.
The functions suite passes. Async generator and native Future metadata failures
remain for the next pass. Logs: `step1-focused.log`, `step1-language.log`.

## Correctness pass 2

Devirtualized calls bound against an abstract covariant interface could invoke
an inherited concrete method with a narrower parameter type without checking
the argument. Check the concrete implementation only when its parameter differs
from the bound interface and the supplied argument is not statically safe.
This uses existing AssertType instructions; runtime and dispatch are unchanged.

Fresh and serialized regressions and related virtual-call suites pass all 17
tests; targeted analysis is clean. The three override_covariant SDK tests pass.
Removed their stale expected-failure entries.

## Correctness pass 3

Constructor references were rejected outright. Cached compiler wrappers now
expose their callable signatures and supply the hidden class type argument to
generative constructors. Factories receive their class type environment through
the existing callable channel. Parameters retain their declared native ABI.

Four regressions cover fresh and serialized generative/factory/redirecting
constructors, defaults, generic instantiation, implicit constructors and identity.
The constructor entrypoint suite and targeted analysis pass. The SDK tear_off
and unnamed_new tests pass; removed both stale expected-failure entries.
Runtime and stdlib are unchanged by this pass.

## Correctness pass 4

Native Future wrappers lost their payload descriptors, so the await type gate
could leave File, Socket, generated codec and deferred-loading Futures unawaited.
The binding generator now stamps Future/Stream payload types and preserves
receiver generics. Regenerated the stdlib using generate_stdlib. Existing
hand-maintained IO bindings and the synthetic deferred-loading hook receive
equivalent metadata. StreamIterator, nullable StreamController.add and guest
AssertionError behavior are preserved through generator hooks/configuration.

Bridge constructor call metadata carries the instantiated result type. Nested
Future factories retain their Future payload while ordinary factories adopt it;
generic constructor types resolve in the caller's environment. The bytecode
format is now 130. No extra instructions or new opcodes were introduced.
Async FutureOr return annotations now retain their payload descriptor.
Dynamic `??` context uses the left operand's type for right-side inference.

Ordinary suite: 1836 passed, 62 skipped, two stale codec-version assertions;
both codec suites pass after updating those assertions and adding constructor
metadata roundtrip/bounds coverage. All 14 async tests pass, including nested
factory identity, and native metadata tests pass fresh and serialized.
Full SDK suite: 2247 passed, 148 failed, 306 compile errors, 361 skipped.
Removed three newly passing expected failures. Twenty unexpected cases remain,
including a native Dart 3.13.4 disagreement with the pinned return_throw fixture.
The await context pair exposes an older dynamic-for-FutureOr inference shortcut
and is planned for the next compiler pass. Analysis reports only the existing
path-dependency warning and benchmark import info.

The final 22-driver AOT sweep matched all 21 execution checksums. Most runtime
medians stayed close to baseline; calls showed a regression. Two longer repeats
and a standalone calls executable narrow it to primitive/mixed static calls,
with method/polymorphic/boxed calls close to baseline. This remains an explicit
performance investigation for the next step; the hot dispatch source is
unchanged. Evidence: step4-aot/summary.csv, calls-repeat2-*.log,
calls-standalone.log, dart-test-step4.log, sdk-full-step4.log.

## Runtime performance pass

The real-world generic batch reducer repeated five equivalent immutable type
environment allocations plus bound/parameter descriptor resolution on each
checked dynamic invocation. Reuse the closure's most recent environment by
type-argument values, and cache resolved parameter types and proven bounds
for the runtime/environment/owner tuple. Every supplied value is still checked.
The cache holds one instantiation, so memory use does not grow with call sites.
Low-level closures without type-owner metadata retain the existing path.

The longer 100000-batch AOT repeat improved from 834.360 ms to 219.133 ms,
73.7%, with identical checksum 75012761700. The initial 50000-batch comparison
was 384.328 ms to 171.296 ms. Captured environments survive later calls with
different arguments; invalid values and bounds remain rejected. The 62 generic
language/ownership tests and 59 closure/default tests pass.

The final full 22-driver AOT sweep against correctness pass 4 matched all 21
execution checksums. Most non-call cases remained within a few percent. Calls
still show unstable AOT timings, so retain the earlier comparison as a separate
investigation rather than claiming a general call improvement. An independent
baseline worktree confirms identical primitive/mixed bytecode, function ABI,
register/spill metadata and constant/side tables. The difference is outside
compiler lowering. Logs: perf-aot/summary.csv, generic-checked-repeat.log,
generic-before-repeat2.log, call-code-{baseline,candidate}.json.

## Cleanup and Astra review

An Astra medium review found recursive binding wrapping discarded the receiver
type owner, erasing nested async payloads. Forward that owner through a shared
recursive wrapping helper, Future payloads and returned callbacks. A generated
AsyncBox<T> execution regression exercises Stream<Future<T>>, Future<Stream<T>>
and List<Future<T>> with fresh and serialized runtimes. It passes along with
the existing generated bridge execution test.

Named the checked-call record, documented snapshot comparison, fixed the new
brace lint and formatted the Future factory helpers. Kept the two short cache
key comparisons rather than introducing another abstraction. Astra found no
other concrete cache, constructor or codec issue.

Two complete stdlib regenerations were idempotent across 89 tracked files.
The ordinary suite passes all 1840 checks; SDK full has the same 20 unexpected
cases and no stale expected failures. Analysis contains only the pre-existing
path-dependency warning and benchmark import info. The final 22-driver cleanup
AOT sweep matches all 21 execution checksums. Logs: dart-test-cleanup.log,
sdk-full-cleanup.log, cleanup-bindgen-final.log, cleanup-final-analyze.log,
cleanup-aot/summary.csv.

## Second cycle, correctness pass 1

Await now supplies the specified FutureOr context instead of a dynamic
surrogate. Collection and constructor inference select the matching union
branch; an uninformative context retains upward inference. Equality no longer
passes its bool result context to operands. The hand-maintained Future.value
declaration now expresses FutureOr<T>?, allowing general bridge inference to
replace its constructor-specific workaround.

Bridge constructors written as method invocations now use constructor lowering.
Previously a Future.value inside a native Future.sync callback inherited the
outer constructor's type metadata, leaving collection Futures unawaited. Each
constructor now carries its own inferred type through existing metadata.
No runtime checks, adapters or extra bytecode instructions were introduced.

All 18 focused async/context tests pass fresh and serialized, including a
reentrant native callback regression with awaited list, map and set elements.
Both SDK await-context cases and all three collection-await cases pass.
Targeted analysis is clean. These five paths had no expect_fail entries.

## Second cycle, correctness pass 2

Flow analysis now respects the Dart 3.9 feature boundary. Older libraries keep
both statically possible flow joins and discard promotion interests after full
demotion; current libraries retain modern pruning and folded bytecode.
Chained null-aware cascades use the analyzer's complete cascade predicate.

Nullable type tests no longer incorrectly narrow a non-nullable local. Native
Dart 3.13.4 confirms this for ordinary and late Object/num locals. Deferred
initializers may use a boolean condition's recorded promotions only when its
local dependencies are never assigned in the containing function. Existing
write-capture and epoch checks remain.

All ten enabled/disabled sound-flow SDK fixtures and three related nnbd cases
pass fresh and serialized. Six focused regressions check both language
versions, reject the opposite version's inferred types and retain mutation
barriers. Targeted analysis is clean, with no runtime changes. The newly
passing SDK paths have no expect_fail entries.

## Second cycle, correctness pass 3

Method callable metadata was reconstructed from written annotations, erasing
types supplied by override inference. A shared method type builder now reuses
the resolved member signature for runtime metadata, tear-offs and body return
context. Async methods consequently retain inherited Future payload types.
Inherited generic method parameters are rebound by position to the overriding
method's scope, including differently named parameters. An inherited return
type constrains call inference as a written annotation does.

Three regressions cover runtime tear-off types, generic substitution and async
payloads in fresh and serialized runtimes. All 58 focused tear-off, generic,
extension and async tests pass. The complete SDK override_inference fixture
passes, and targeted analysis is clean. Runtime code is unchanged.

## Second cycle, correctness pass 4

Redirecting factories retain their own checked signatures and argument shapes.
Their physical slots accommodate the redirect target's inherited defaults;
generic factory parameters retain their erased representation. The forwarder
binds target arguments normally, including extra optional target parameters.
Default expressions and thunks resolve in the declaring library across redirect
chains. Field initializers run before initializer-list effects, matching Dart.

A native-valid SDK fixture exposed an omitted null default inherited by a
factory's int parameter. Supplied null still fails that factory's check; the
omitted compiled default must reach the wider target. Dynamic closure invocation
therefore checks supplied arguments rather than rechecking filled defaults.
The interpreter dispatch and bytecode format are unchanged.

Closure creation boxes by-value scalar captures once into their environment,
preventing a const local's later scalar representation from conflicting with
captured object storage. Broad validation also exposed two mixin regressions
from pass 3. Method metadata now snapshots applied class parameters before a
method parameter can shadow their names. Regressions cover both mixin tear-offs
and class/method parameters sharing a name.

The pinned async/return_throw_test.dart fixture expects an async error to be
caught by a try around return f(). Its complete source fails identically under
native Dart 3.13.4: the return leaves try before the Future error arrives. It is
excluded with that explicit reason; the language regression preserves native
return-versus-return-await behavior. Native evidence is retained in
native_return_throw_fixture.dart and native_return_throw_fixture.log under the
ignored improvement-loop directory.

The ordinary suite passes all 1871 checks, with 62 SDK/harness skips. Named
redirect regressions now cover both generic and non-generic targets; their
resolution uses the existing class lookup instead of reparsing a constructor
suffix as part of a type name. All 13 focused factory and constructor tear-off
checks pass, as do 77 focused closure checks and the repaired mixin cases.

The full scan exposed additional regressions, repaired before checkpointing:
static generic members do not require instance type bindings; throw operands
receive Object context through await; pre-3.9 Never tests remain unreachable;
nullable tested types record non-null promotion interests. Native List writes
preserve the boxed local when the same value supplies an integer index, avoiding
an SSA representation conflict without adding instructions or runtime checks.
Late field initializers retain their previous ordering after initializer-list
effects; complete lazy late-field initialization remains a separate group.
The newly passing nnbd/syntax/class_member_declarations status is removed.

Final SDK-full validation has four unexpected outcomes, down from twenty
before this cycle, and no stale statuses. The remaining paths are anonymous
method break/continue, function-type least upper bound, recursive-bound greatest
closure, and regress23408. Expected failures remain for later cycles.
Analysis reports only the existing path-dependency warning and benchmark import
info. Logs: cycle2-ordinary-verified.log, sdk-full-cycle2-verified.log,
cycle2-final-analyze.log.

The final isolated 22-driver AOT comparison matches all 21 execution checksums.
Most medians stay near the saved pre-validation-change executable; omitted-
default callbacks improve. Longer, order-reversed repeats reduce the initial
polymorphic-call difference to about 1–3%; native-Future awaits remain about
4–7% slower. Retain these measurements for the performance pass rather than
claiming an across-the-board improvement. Evidence: cycle2-correctness-aot/
summary.csv, cycle2-correctness-aot/median-changes.csv and
cycle2-correctness-repeat.log.

## Second cycle, runtime performance pass

Allow the AOT compiler to inline frame entry/return helpers. Inactive cached
frames already have cleared metadata, so entry only installs current bindings.
A function's precomputed storage flag lets a storage-free leaf reuse any
cleared leaf frame without invoking the capacity-growth helper. Spill-heavy
callees retain existing growth checks; suspended frames still detach, and
returns still release references. No opcode or serialized format changes.

Removing repeated resets alone showed no consistent gain. The combined change
improves primitive and polymorphic calls about 8% in the longer order-reversed
500000-iteration repeats. Rendering 50000 invoices improves from 419.937 to
397.107 ms and from 415.830 to 391.300 ms, about 5–6%, with identical checksum
1840803250. The retained patch stays within frame helpers and one derived flag
per function.

All 150 runtime, nested ownership, async and generator checks pass, including
fresh/serialized calls alternating spill-heavy and storage-free leaves.
Targeted analysis is clean. The final isolated 22-driver AOT sweep matches all
21 execution checksums: primitive calls improve 7.3%, polymorphic calls 11.6%,
noncapturing closure calls 7.6%, and invoice rendering 2.3% in that shorter run.
The tiny sync benchmark's one-microsecond difference disappears in 50000-call
repeats; native-Future awaits and callbacks improve in those longer repeats.
No material regression is reproduced. Logs: cycle2-frame-final-tests.log,
cycle2-frame-leaf-repeat.log, cycle2-frame-async-repeat.log,
cycle2-frame-aot/summary.csv and cycle2-frame-aot/median-changes.csv.

## Second cycle, cleanup pass

Astra medium reviewed the second cycle. Its three findings covered chained
factory storage, omitted generic defaults, and inherited defaults resolving in
the caller's class. Redirect parameter lookup is now shared by defaults and
physical ABI resolution. Storage resolution follows the entire chain, composing
generic substitutions and preserving erasure at every hop. Omitted arguments
use the same ABI calculation as supplied arguments.

Default expressions compile in their declaring lexical class and library.
Scalar evaluation resolves class constants before top-level constants, and
caller locals, extension/anonymous receiver context, and type parameters are
isolated and restored. Astra's follow-up identified the generic caller scope
leak; a concrete class and a caller type parameter with the same name now remain
separate. Native, fresh-program, and serialized regressions cover each finding.
No runtime helpers, dispatch instructions, or generated stdlib files change
in this cleanup. The newly passing method/as_constants_test status is removed.

Final ordinary validation passes 1877 tests with 62 skips. SDK-full has the
same four unexpected outcomes as before cleanup; the scalar static-default
regression regress4515170 now passes too, and its stale status is removed and
verified directly. SDK aggregate: 2266 passed, 139 failed, 295 compile errors.
The 15 focused factory/default checks pass fresh and serialized. Analysis has
only the existing path-dependency warning and benchmark import info. Evidence:
cycle2-cleanup-ordinary-final.log, sdk-full-cycle2-cleanup.log,
cycle2-cleanup-stale-verified.log and cycle2-cleanup-analyze.log.

A separate native-valid nested-local-constant default remains a pre-existing
limitation, confirmed against the HEAD thunk implementation and preserved in
native_default_scope/nested.dart for a later correctness pass.

The final isolated 22-driver AOT sweep matches all 21 execution checksums.
Longer order-reversed repeats do not reproduce the initial shared-capture
slowdown; boxed-call results vary by order. Mixed-object calls remain about
10–28% slower across the two longer comparisons. Their full serialized
programs are byte-identical before/after cleanup, as are boxed-call and captured
closure programs, and runtime source is unchanged. An AOT code-generation or
layout effect is a hypothesis, not an established cause; retain this unresolved
measurement for the next performance pass. Compiler repeats span 12.5–13.4 ms
on both hosts with equal bytecode size. Evidence: cycle2-cleanup-aot/summary.csv,
cycle2-cleanup-aot/median-changes.csv, cycle2-cleanup-repeat-*.log,
and cycle2-cleanup-bytecode-comparison.log.

## Third cycle, correctness pass 1

Factory results need an exact receiver layout before direct field-slot access.
A factory returning a subclass can inherit the same field while storing it on
another superclass link. Getter and setter lowering now require an exact type
or a declared leaf class for that shortcut. Owner-independent method dispatch
keeps its previous devirtualization. Direct, deferred, native, and serialized
regressions cover base and subclass storage; regress23408 now passes.

An anonymous block with only external jumps has no result-producing exit.
Lowering preserves its terminated builder instead of selecting a detached exit
block. A do-loop only propagates body divergence when its exit has no incoming
edges. The SDK break/continue fixture and fresh/serialized nested-label and
finally regressions pass. The installed native compiler does not support that
experimental syntax; an equivalent explicit-block program returns the same
result, 428.

Type-parameter subtype expansion now detects active recursive relations and
can use the whole bound when neither FutureOr member proves the relation.
Least upper bounds close only the parameter's own recursive occurrences,
respect variance, retain bound nullability, and apply function/interface rules
before general subtyping. Both previously unexpected least-upper-bound and
greatest-closure fixtures pass. Another greatest-closure fixture remains an
expected compile error. Native Dart agrees on the function/union regression;
its compiler crashes on the recursive-bound probe. The latter's static
expectations follow the SDK fixture and installed analyzer rules.

Ordinary validation passes 1882 tests with 62 skips. SDK-full passes all 2700
harness checks with 362 skips and no unexpected outcomes or stale statuses.
Actual SDK outcomes are 2270 passed, 136 failed, and 294 compile errors; those
remaining nonpassing outcomes still require later cycles. Focused checks cover
48 type-system cases, 26 anonymous-block cases, 11 anonymous SDK fixtures, and
46 factory/layout cases. No runtime or generated stdlib changes occur in this
pass. Logs: cycle3-pass1-ordinary.log, sdk-full-cycle3-pass1.log,
cycle3-lub-before.log, cycle3-lub-after.log, and cycle3-lub-sdk.log. Full analysis
has only the existing dependency warning and benchmark import info after
fixing two new brace-style infos; focused type-system analysis is clean.

## Third cycle, correctness pass 2

Branch joins now restore reconciled local representations after choosing the
surviving flow snapshot. Previously, a statically unreachable null edge could
leave the compiler using a pre-reconciliation boxed view of an integer SSA
slot. Repeated null-aware calls and cascades on the same scalar exposed the
conflict. The fix reuses existing bookkeeping and emits no bytecode.

Null assertions in guarded property access now record field promotions on
the successful branch. Member reads and cascade result facts honor the Dart
3.8/3.9 split: older non-cascaded null-aware reads use the declared field type,
and newly promoted cascade facts only escape a nonnullable modern guard.
Both SDK null-aware-field fixtures pass fresh and serialized. Twelve focused
checks cover versioned static types, reused scalar locals, and nullable
receivers. Logs: cycle3-flow-before.log, cycle3-flow-after.log,
cycle3-flow-focused.log, and cycle3-field-promotion-after.log.
Native Dart also returns the expected result 10 under both language versions;
focused analysis is clean. Evidence: cycle3-field-native.log and
cycle3-flow-analyze.log. The two field-access statuses are removed.

Closure parameter types are resolved before compiling their defaults, so
contextual const collections keep their inferred element types. Named contexts
match by name, and each literal retains its own optional calling shape.
The existing ignoreDefaults flag avoids creating an untyped thunk first.
Native, fresh, and serialized regressions pass, including the SDK contextual
default fixture; 81 focused closure, capture, and await checks pass.
Its stale status is removed too.

Ordinary-class primary headers lower into existing constructor and field AST
nodes through an isolated adapter for the pinned analyzer. Original tokens,
type annotations, defaults, and expressions keep their source locations.
Named generic constructors, redirects, mutable/final declaring parameters,
initializer scope, and body scope reuse ordinary lowering. Native checks
confirmed that nondeclaring header parameters remain visible in the body,
while declaring and super formals resolve through fields or lexical names.
Late field initializers and function-typed declaring parameters are explicitly
unsupported; declaration-initializer closure capture remains a later group.

Field formals retain a separate initial boxed value while initializer arithmetic
can change the local's representation. No additional boxing is required.
The allocator removes the snapshot copy for a simple constructor, verified by
identical whole-program bytecode arrays. Six focused constructor regressions
pass fresh and serialized; five positive native sources agree. The primary SDK
survey found six passing expected-failure fixtures, whose statuses are removed.

Initial broad validation exposed a native HTTP callback regression: its newly
correct List<String> parameter check saw a generated List<dynamic> view.
The binding generator now reifies known List arguments using the same metadata
helper as Future and Stream. The hand-maintained List view forwards that
metadata into its existing wrapper fields, preserving lazy conversion and
writeback without allocating another adapter. All generated stdlib edits come
from generate_stdlib; a second run has identical hashes. The configured
hand-maintained collection-view implementation is the only direct stdlib edit.

The HTTP integration and native-Future/bindgen checks pass after regeneration.
The new mapped-list regression checks typed callback admission, rejection of a
wrong element type, lazy reads, and writeback in fresh and serialized programs.
All five wrapper tests pass, and focused generator/view analysis is clean.
Evidence: cycle3-list-focused.log, cycle3-list-wrappers-verified.log,
cycle3-list-analyze.log, and cycle3-list-generate-idempotence.log.
The same initial SDK run identified one more passing initializing-formal
wildcard fixture; its stale status is removed, bringing this pass's removals
to ten.

Final ordinary validation passes 1896 tests with 62 skips. SDK-full passes
2700 harness checks with 362 skips and no unexpected outcomes or stale
statuses. Actual SDK outcomes are 2280 passed, 134 failed, and 286 compile
errors. Full analysis has only the existing dependency warning and benchmark
unused-import info. Logs: cycle3-pass2-ordinary-verified.log,
sdk-full-cycle3-pass2-verified.log, and cycle3-pass2-analyze-verified.log.

The final AOT comparison against checkpoint 398086a ran all 22 drivers with
seven samples, alternating executable order and using CPU affinity mask 4.
All 21 execution checksums matched. Most cases stayed close; overflow calls
and named-default binding initially appeared 75% and 68% slower, respectively.
Longer reverse-order runs with 15 samples did not reproduce either slowdown:
overflow calls took 135.527 ms versus 141.386 ms, and named-default binding
took 32314 us versus 32622 us. Whole serialized programs for all six call
cases and eleven dynamic cases are byte-identical to the baseline. The short
runs contain large timing spikes, so their medians do not establish a
regression. No interpreter implementation changed in this pass. Evidence:
cycle3-pass2-aot/summary.csv, its calls-repeat and dynamic-repeat logs, and
cycle3-pass2-bytecode-comparison.log. The earlier cleanup's mixed-object-call
timing issue remains a separate question for the performance pass.

## Third cycle, correctness pass 3

Refutable patterns now branch directly to the failed case after each test.
Object getters, list indexing, nested matches, and guards execute only after
their prerequisites pass. List patterns check type and exact length; record
patterns check shape before field reads, including empty records. The existing
intrinsic null comparison handles null-check patterns without calling an
overridden equality operator. Known successful checks emit no branch, and
the graph avoids constructing boolean joins for each conjunction. No runtime
opcode, adapter, or interpreter change is needed.

Successful pattern edges carry the refined matched type through logical AND
and record fields. The original subject receives that promotion only when it
is promotable and the guard does not reassign it. Pattern variables live in
the guard and successful body, while enclosing locals merge failed-edge
effects. A failed guard can mutate a switch source without changing the
snapshot tested by later cases. OR alternative binding and short-circuit
lowering remain a separate group.

Two new regressions cover native results 38 and 1, fresh and serialized,
including skipped getters/guards, short and long lists, wrong record shapes,
empty records, variable shadowing, and guard reassignment. The logical-AND SDK
static witness passes with assertions enabled. Initial focused validation
passes eleven tests, including the existing pattern cases and the promoted
type-parameter witness; pattern compiler analysis is clean.

Mixin upper-bound depth now counts ordered application layers before the
named class, with the existing alias distinction. Both issue_61218 fixtures
pass fresh and serialized, and a native static witness agrees. Type-parameter
promotion retains the original parameter's lexical nullability while allowing
a nullable effective bound; nullable locals can still narrow to nonnullable
values. This avoids changing an intersection of X1 with C1<X1>? into X1?.

Primary declaration-initializer closures are scanned in constructor parameter
scope through the existing capture analysis, and duplicate field-initializer
visits are skipped. Body closures continue to capture fields. The original
header token identifies a lowered primary constructor without a new registry.
Native checks confirm initializing and super formals are implicitly final;
their immutable captures reuse existing boxed values instead of capture cells.
Fifteen focused tests pass fresh and serialized, with four native positive
capture witnesses and the primary parameter-scope SDK fixture passing too.
The first ordinary sweep exposed getter lookup through an unrelated interface
pattern in package:http. Object-pattern reads now use the explicitly tested
interface, whose getters are valid after its type check succeeds. The first
SDK sweep exposed two typed-pattern shadowing regressions; the promotion slot
is now resolved before the pattern can declare a variable with the subject's
name. A third native/fresh/serialized regression returns 15 and covers both
corrections. The HTTP integration passes, and both affected SDK fixtures pass
fresh and serialized with assertions enabled.

Thirteen stale expectations are removed after dual-runtime verification.
These include the primary scope fixture, two mixin joins, greatest_closure_1,
nullable object patterns, logical-AND/record/object/cast flow, exhaustiveness
fallback, unary-pattern parentheses, and both pattern-null flow versions.
Evidence: cycle3-pass3-pattern-probes.log, cycle3-pass3-flow-probes.log,
cycle3-pattern-regressions.log, and
cycle3-pass3-pattern-regressions-probes.log. The remaining list/rest, OR,
guard-capture and collection if-case flow probes remain expected failures.
Final ordinary validation passes 1906 tests with 62 skips. SDK-full passes
2700 harness checks with 362 skips and no unexpected outcomes or stale
statuses. Actual SDK outcomes are 2293 passed, 133 failed, and 274 compile
errors. Full analysis initially found one new brace-style info, fixed without
changing behavior; focused reanalysis is clean. The dependency warning and
benchmark import info remain pre-existing. Diff checks pass. Final logs:
cycle3-pass3-ordinary-verified.log, sdk-full-cycle3-pass3-verified.log,
cycle3-pass3-analyze-verified.log, and cycle3-pattern-final-style.log.

## Third cycle, correctness pass 4

Logical OR patterns now have separate alternative blocks. The left failure
edge selects the right alternative; successful edges join compatible bindings
before the guard. Both arms keep a shared register representation when possible.
Captured OR variables allocate one existing capture cell after the join, including
nested alternatives. Pattern-variable annotations retain their declared type
while a nonnullable matched value can promote a nullable binding. OR joins retain
common explicit type proofs, including intermediate AND promotions, rather than
inventing a promotion from the alternatives' least upper bound.

Capture analysis now models pattern declarations and their guard/body scopes.
Adjacent switch cases give each guard an independent binding and the shared
body a separate binding, allocating cells only for names actually captured.
If-case variables do not shadow outer variables in the else branch. Collection
if-case elements evaluate the subject once and use the same guarded-pattern
graph as statements and switch expressions. No new runtime operation is needed.

Function-typed primary parameters lower into ordinary generated field AST
annotations. Direct generic function-valued fields, getters and record members
now supply their declared signature to argument inference before reading the
member. The actual getter still runs after its arguments, preserving Dart's
evaluation order. Instantiated generic results survive that read; nongeneric
member calls retain existing result refinement from promoted callable metadata.
The separate primary late-initializer restriction remains explicit.

Focused validation covers native and fresh/serialized results for both OR
alternatives, skipped getters, captured-variable mutation, nullable joins,
common scalar/record proofs, collection list/set/map cases and generic member
calls. The SDK logical-or flow, guard capture and guard scope fixtures pass
with assertions enabled in both runtime modes. Seventy-seven capture checks
and sixty-eight generic-member/primary/binding/closure checks pass; targeted
analysis is clean. Ordinary validation passes 1915 tests with 62 skips.

Four stale SDK expectations are removed after assertion-enabled dual-runtime
checks: logical-or flow, guard capture, guard scope and identifier-when-not.
The final SDK sweep passes all 2700 harness checks with 362 skips and no
unexpected outcomes or stale statuses. Actual SDK outcomes are 2297 passed,
133 failed and 270 compile errors. Logs: cycle4-ordinary.log,
sdk-full-cycle4-verified.log, cycle4-focused-sdk-probes.log and
cycle4-stale-probe.log. The fixes use existing runtime operations.
The final OR regression also checks a third nested alternative, captures of
preceding AND bindings and getter writes to captured outer locals; native and
both evaluated runtimes agree. Full analysis retains only the existing
dependency warning and benchmark import info. Diff checks pass.

## Third cycle, runtime performance pass

The retained frame-leaf and cleanup executables were measured in A-B-B-A order
under CPU affinity mask 4, using 500000 call iterations and fifteen samples.
Mixed-call medians differ by about 0.17%, and primitive medians by about 0.25%.
The earlier cleanup slowdown does not reproduce in this control. Evidence:
cycle3-perf-control.log and its timestamped raw output.

A frame-context dirty flag with a cold cleanup helper was tested and removed.
It made method calls and the log-record workload somewhat faster but slowed
primitive calls and closures by roughly 4-8%. The selected implementation uses
a compiler-selected plain static-call opcode instead: no pending receiver or
type-argument metadata is loaded, cleared or installed for those calls.
Frame reuse, depth checks and cleanup continue through their existing paths.
The opcode is generated from the authoritative machine specification. All 386
previous opcode constants retain their IDs; the new hot opcode is 220.

Known nongeneric declaring owners also omit receiver type metadata, allowing
ordinary class methods to use that path. Method-owned generic arguments still
travel independently. Generic declaring classes and mixins retain the receiver;
extensions and unknown owners remain conservative. A regression covers methods
inherited by a generic descendant, actual receiver-type tests, escaped method
type arguments and generic mixin/super calls. Both evaluated modes agree on
the preliminary witness, and forty-four focused generic checks pass.

Preliminary fifteen-sample AOT comparisons show roughly 8% faster primitive
calls for the plain-call candidate and 9% faster method calls after owner
metadata elision. The log-record workload improves about 4%. Initial closure
regressions of 18% and 5-7% do not reproduce in longer, reverse-order A-B-B-A
runs at 500000 iterations. All five complete serialized closure programs are
byte-identical between the plain-call and owner-elision candidates. Their
direct-call timing differs by about 5%, leaving the selected candidate still
faster than the original baseline but showing the limit of small timing deltas.
Evidence: cycle3-candidate-a-preliminary.log, cycle3-plain-call-comparison.log,
cycle3-member-metadata-comparison.log, cycle3-closure-abba.log and
cycle3-closure-bytecode-b.log/cycle3-closure-bytecode-c.log.

Final ordinary validation passes 1917 tests with 62 skips. SDK-full passes
2700 harness checks with 362 skips, no unexpected outcomes and no stale
expectations; actual outcomes remain 2297 passed, 133 failed and 270 compile
errors. Full analysis reports only the existing dependency warning and benchmark
import info. The machine generator check passes, and regenerating all 55 stdlib
files produces no changes.

The final full AOT sweep compares cycle3-performance-baseline.exe with
cycle3-member-metadata.exe using fifteen samples, alternating execution order
and CPU affinity mask 4. All 22 drivers complete and all 21 execution checksums
match. Log records improve about 5%, template rendering about 13%, and virtual
calls about 14-16%. The sweep initially flags double-object dispatch and bound
member callbacks amid timing spikes. Longer C-B-B-C repeats use 2500000 dispatch
iterations and 50000 callback iterations: double-object dispatch improves about
4.6%, bound member callbacks about 1.1%, and the other cases are flat or faster.
The large slowdown flags do not reproduce. Final evidence is in
cycle3-final-ordinary.log, cycle3-final-sdk-full.log, cycle3-final-analyze.log,
cycle3-performance-final-aot/summary.csv and cycle3-aot-outlier-abba.log.
The final member-environment witness also passes natively with assertions enabled.

## Third cycle, cleanup pass

The requested Astra medium review identified a list-pattern refutation bug:
matching a subject of an unrelated static class could reuse that static type
as the runtime test and accept a zero-valued length getter. List patterns now
test their actual List type before any access. Successful accesses retain a
more specific subject type only when it is assignable to the tested List type.
The regression verifies rejection and that the unrelated getter is never read;
native and fresh/serialized witnesses all return zero. No runtime instructions
change in this fix.

Capture analysis and OR joins now share one small AST-only pattern-declaration
traversal. The join helper retains its BasicBlock<Operation> type, and the plain
call comment describes owner metadata precisely. Astra's follow-up source review
finds no remaining concerns in the cleanup patch. The focused group passes 85
checks; full ordinary validation passes 1918 tests with 62 skips. Full analysis
retains the two existing non-error diagnostics; generator and diff checks pass.
Evidence: cycle3-cleanup-focused.log, cycle3-cleanup-ordinary.log,
cycle3-cleanup-analyze.log, zero_length_native.log and zero_length_eval.log.

SDK-full remains harness-clean at 2700 checks and 362 skips, with actual
outcomes 2297 passed, 133 failed and 270 compile errors; no expectations become
stale. The final cleanup AOT sweep completes all 22 drivers and matches all 21
execution checksums against the preceding performance checkpoint. Compile code
size is unchanged at 1224 bytes. Larger reverse-order repeats resolve the
bound-callback timing spike: about 1% faster; alternating dynamic calls differ
by about 1.4%. The runtime edit is a documentation-only clarification. Logs:
cycle3-cleanup-sdk-full.log, cycle3-cleanup-final-aot-build.log,
cycle3-cleanup-final-aot-run.log, cycle3-cleanup-final-aot/summary.csv and
cycle3-cleanup-outlier-abba.log. The sibling control_flow_graph remains clean
at a0c339a.

## Fourth cycle, first correctness pass

Map patterns now test their required Map type, then evaluate entries in source
order. A lookup precedes the nullable-value presence check; missing keys refute
the pattern, present nulls remain valid for nullable value types, and extra
keys are accepted. Nonnullable values need only the lookup. A free generic
value parameter shares its nullability test across entries. Failed earlier
subpatterns skip later key lookups, and map patterns never read length.

List patterns support prefix, matching rest and suffix elements. Plain rest
and untyped wildcards avoid unnecessary member calls. Only-rest patterns skip
length; other rest patterns check minimum length and calculate suffix indexes
from that length. Statically known source List implementations use their own
index operator. Pattern context schemas combine element constraints, including
Iterable rest bindings and contravariant function parameters.

Omitted object-pattern arguments use the existing unifier followed by seeded
instantiate-to-bounds. The inference keeps lexical parameter identities,
dependent bounds and aliases, and closes unfilled recursive bounds with
Object?. Explicit arguments determine getter types independently of whether
the tested interface can promote the subject.

Irrefutable declarations and assignments reuse the existing short-circuit
pattern graph. Shape and presence failures throw StateError. Assignments check
all extracted values before storing any target, including captured locals.
The former whole-pattern assignment check confused a context schema with the
required subject type and rejected valid statically typed dynamic collections;
validation now happens during destructuring. Dynamic subjects retain contextual
collection checks. These changes use existing runtime instructions and bindings.

All ten new witnesses pass natively with assertions enabled and in fresh
and serialized evaluated runtimes. Eleven focused checks, including the existing
nullable OR regression, pass. Focused analysis reports no issues. Native
comparisons cover failed-assignment atomicity and distinguish contextual dynamic
casts from element pattern failures. A typed-variable check retains the earlier
non-null proof when the declaration annotation is nullable.

Final ordinary validation passes 1928 tests with 62 skips. Full analysis retains
only the existing dependency warning and benchmark import info; diff checks
pass. Nine stale SDK expectations are removed after assertion-enabled fresh
and serialized checks. SDK-full then passes all 2700 harness checks with 362
skips and no unexpected outcomes. Actual outcomes improve from 2297 passed,
270 compile errors and 133 failures to 2306 passed, 259 compile errors and 135
failures. Eleven fixtures move beyond their previous compiler error, nine of
them passing completely. Logs: cycle4-pass1-focused-final.log,
cycle4-pass1-final-ordinary.log, cycle4-pass1-final-analyze.log,
cycle4-pass1-final-sdk-full-verified.log and
cycle4-pass1-dual-sdk-stale-probes.log. MapBase inheritance, switch-statement
subject promotion and unknown guest List indexing remain separate follow-ups.

## Fourth cycle, second correctness pass

Switch statements now promote their original subject on successful pattern
edges, including later cases and parenthesized subjects. Both switch forms
track the subject's write epoch: matching the original snapshot cannot promote
a local reassigned by an earlier failed guard. Native Dart and both evaluated
loading modes agree on the new subject-promotion witness.

FutureOr membership lowering is shared by `is`, patterns, casts and checked
assignment conversions. The union tests Future<T> and T instead of using the
erased Object? descriptor. Ordinary nominal checks retain their existing
instructions. Invalid union assertions use the existing TypeError assertion
path; no runtime instruction or interpreter change is required. The focused
witness covers function false positives, nullable members, accepted futures
and rejected explicit, implicit and pattern casts.

MapBase and ListBase now have generated bridge and wrapper bindings. SDK
default implementations use the existing superclass fallback and call the
guest primitives. Generator fixes preserve inherited setters, wrapper type
parameters, instantiated SDK owner metadata, lazy Iterable exports and
collection identity across generic callback/result boundaries. Generated
MapEntry keys use the existing collection box cache. No SDK method bodies are
copied or written manually.

Ordinary List/Map reads and list-pattern reads require allocation or storage
proof before selecting native indexing. Guest implementations and uncertain
boxed receivers use existing operator dispatch. Indexed reference types use
the actual List/Map interface arguments, including nongeneric and reordered
subclasses. Proven native allocations keep their original instructions;
uncertain receivers can require boxed arguments and call instructions. The
user deferred performance work and benchmark sweeps until an explicit resume.
These bindings and their coupled indexing changes remain uncommitted until
the required AOT check can run.

Focused tests cover inherited defaults, guest operator calls, compound writes,
unknown native lists and collection/custom guest object keys. Existing Iterable
and typedef regressions pass. Source mixin application remains a separate
task. An untyped MapBase callback inference issue and the existing built-in
Object wrapper identity limitation are not addressed by these generator fixes.

SDK probes now pass non_interface_object_pattern_test.dart and
version_2_29_changes_test.dart. The object-inference fixture advances from a
compiler error to its inferBound runtime assertion. A separate native witness
identifies incorrect constructor inference: D(0) becomes D<num>, or D<dynamic>
under Object context, whereas native Dart infers D<int> in both cases. The
schema fixture's remaining error is localized to List<int> inference for an
untyped identifier pattern at line 59. These are the next correctness targets.

Repeated generation is identical across 90 generated files and registries.
All four collection witnesses pass natively with assertions enabled and return
13, 7, 13 and 9, matching both evaluated loading modes. Final ordinary validation
passes 1937 tests with 62 skips, including the Map lookup regression.
A low-level unknown-List fixture now supplies
the Runtime required by normal operator dispatch. Three stale SDK expectations
are removed after assertion-enabled fresh and serialized verification:
list/mixin_test.dart, patterns/non_interface_object_pattern_test.dart and
patterns/version_2_29_changes_test.dart.

SDK-full also exposed five generic-method regressions through the new Map
operator dispatch. The established hand-maintained Map binding had an
incorrect `K -> V` lookup descriptor instead of SDK `Object? -> V?` semantics,
and its implementation rejected null keys. Correcting the descriptor and
normalizing null to the canonical boxed null key fixes all five fixtures in
both loading modes. A native and dual-runtime witness covers missing,
incompatible and nullable keys, including instance precedence over an Object
extension operator. The generated files remain identical after this manual
binding correction.

Final SDK-full has 2315 actual passes, 251 compile errors and 134 expected
runtime failures, with 362 skipped fixtures and no unexpected outcomes. All
2700 harness checks pass. Nine stale entries have been verified in fresh and
serialized runtimes and removed in the working tree. Full analysis retains
only the existing dependency warning and benchmark import info. Logs:
cycle4-pass2-final2-ordinary.log, cycle4-pass2-final2-analyze.log and
cycle4-pass2-final2-sdk-full.log.

The independent promotion and FutureOr compiler fixes are checkpointed
separately. Against the previous bindings, the isolated compiler checkpoint
passes all 1930 ordinary tests with 62 skips and clean focused analysis. Five
SDK fixtures pass in both loading modes; only those five stale expectations
are checkpointed. The four collection-dependent removals stay with their
bindings. Generated bindings, the manual Map signature correction and
coupled ordinary indexing fixes stay in the working tree pending AOT
validation. Performance experiments and sweeps are deferred at the user's
request; correctness work continues.

## Fourth cycle, third correctness pass

Omitted pattern-schema components now have a compiler-only unknown type.
Unlike explicit dynamic annotations, these components let List, Map and
record literals infer their missing types from values. Schema GLB combines
nested holes with concrete sibling constraints. Remaining holes close before
runtime metadata registration; no interpreter operation is added.

Constructor inference now retains class parameters until supplied arguments
have been analyzed. Field formals query the declaring class's parameterized
type instead of erasing it through raw default arguments. Contexts constrain
parameters before collection literals compile, and broad contexts still obey
declared bounds. Named constructors retain the binder's inferred result.
Unresolved alias parameters remain available for inference.

Native comparisons and both evaluated loading modes agree on plain, explicit
new, named and factory construction, Object contexts, broader superclass
contexts and List<num> literal contexts. Focused compatibility checks caught
and fixed an alias-constructor regression. The SDK schema fixture now passes
in both modes. The object-pattern inference fixture exposed one more issue:
super formals must substitute the superclass parameter through the subclass's
parameterized superclass view. A transformed List<T> forwarding witness covers
that substitution.

SDK-full caught a constructor tear-off regression at `A.new<double>(42)`.
Global initializer inference had erased the callable's signature to dynamic,
so the caller did not widen the integer literal. Preserving field-formal types
made the existing closure argument check expose that lost context. Global
constructor tear-offs now retain their source signature, including explicit
class arguments and static fields. A focused fresh and serialized witness
covers these calls, and regress60816 now passes in both modes.

Final primary validation passes 1944 ordinary tests with 62 skips. SDK-full
has 2320 actual passes, 250 compile errors and 130 expected runtime failures;
all 2700 harness checks pass, with 362 skips. Full analysis retains only the
two existing diagnostics. Five stale entries are verified in both loading
modes and removed: patterns/schema_test.dart,
patterns/object_pattern_inference_test.dart, switch/issue_60375_test.dart,
implicit_creation/implicit_new_or_const_generic_test.dart and
patterns/implicit_instantiation_test.dart. Logs:
cycle4-pass3-final-ordinary-after-tearoff.log,
cycle4-pass3-final-analyze-after-tearoff.log and
cycle4-pass3-final-sdk-after-tearoff.log.

Against the previous bindings, the compiler-only checkpoint passes all 1937
ordinary tests with 62 skips and 12 focused cases. All five stale fixtures and
regress60816 pass in fresh and serialized runtimes. Focused analysis has no
errors; it reports three null-aware collection style infos, two in existing
code and one in constructor_type.dart. Logs:
cycle4-pass3-compiler-snapshot-ordinary.log,
cycle4-pass3-compiler-snapshot-analyze.log and
cycle4-pass3-compiler-snapshot-dual-probes-targeted.log.

The collection bindings and their coupled indexing changes remain pending
AOT validation. Performance experiments and benchmark sweeps stay deferred
until the user explicitly resumes them.

The Object-typed list-rest metadata failure is isolated in an ignored probe.
It comes from the existing hand-maintained List.sublist wrapper losing generic
metadata. The schema witness checks static inference and returned contents;
the separate runtime binding issue remains pending alongside AOT validation.

## Fourth cycle, fourth correctness pass

Abstract superclass getters now use the existing getter-shaped noSuchMethod
call and convert its result to the getter's declared type on the real receiver.
Callable getters share that read path, retaining the function signature for
argument inference and checking an invalid getter result before evaluating
arguments. Native Dart, fresh evaluation and serialized evaluation agree on
integer-literal widening and getter/check/argument order. The superclass
noSuchMethod SDK fixture passes in both loading modes. The final focused
scope passes 74 cases, and scoped analysis is clean.

Private direct calls now use the compiled member body's library when forming
the lookup key. Super calls inside a typedef-named mixin locate the current
layer by its resolved declaration. The original private-name mixin SDK test
passes in both loading modes, as do 44 focused compatibility cases and the
native witness. No interpreter changes are involved.

SDK multitests now compile each named case and the untagged baseline as
separate programs. Tagged lines from other cases stay blank, preserving line
numbers and import URIs. The selected root determines dependencies and expected
outcomes. Results aggregate under the original fixture path only after every
eligible case runs; an unsupported runnable case prevents a partially checked
fixture being reported as passing. Raw combined-source collection is rejected
with guidance to materialize variants first. The focused harness and async
scope passes 16 tests with clean analysis.

The expanded inventory also caught a launcher omission: SDK main functions
with required arguments were called with none. Selected-source ASTs now supply
the VM's empty argument list and null message using its two/one/zero positional
argument preference. Root and part declarations determine the signature;
imported libraries' main functions do not participate. Named defaults remain
unsupplied. All 24 launcher, multitest and async checks pass with clean analysis.
The original main/main fixture passes in both evaluated loading modes.

Compiler failures and runtime failures now have separate outcome boundaries.
A compiler StateError can no longer satisfy an expected runtime error. This
exposed main/no_main as a real missing-entrypoint limitation, so its expectation
remains. A focused test covers both synchronous and isolated execution.

All eligible variants of 29 stale fixtures pass in fresh and serialized
evaluation. Their expectation entries are removed. Expanding multitests exposed
21 additional failing fixture paths, recorded with the observed variant and
failure reason. These are existing correctness gaps, not passing tests. Native
execution with the pinned SDK's real expect package confirms all 13 runtime
failures and 13 compiler failures pass natively. The missing-main variant alone
fails native launch as expected. Logs: pass4-native-runtime-summary-final.log,
pass4-native-compile-summary.log and
cycle4-pass4-stale-and-new-variant-probes.log.

The existing await-chain regression relied on timers started within a few
milliseconds of one another. It now orders completion through the futures
themselves. All 11 regression cases pass, and native execution prints the same
sequence. No async runtime code changed.

The compiler-only snapshot passes all 1993 ordinary tests with 63 skips and
has clean scoped analysis. Its 29 stale fixtures pass 153 eligible variants
in each loading mode; 357 negative or unsupported variants are skipped, with
no failures or compile errors. Logs: pass4-snapshot-ordinary.log,
pass4-snapshot-analyze.log and pass4-snapshot-stale-dual.log.

The final primary SDK-full run reports 2511 actual passes, 243 compile errors,
126 runtime failures and one unsupported aggregate. Its only two harness
failures are additional stale expectations, metadata/metadata_builtin_test.dart
and unsorted/local_var_in_annotation_test.dart. Both pass in each loading mode
against both primary and previous bindings. Their rows are removed, bringing
this pass to 31 stale removals. Logs: pass4-primary-sdk-full-final.log,
pass4-primary-new-stales-dual.log and pass4-snapshot-new-stales-dual.log.
The 369 genuinely failing fixture paths remain work for later cycles.

Final primary ordinary validation passes all 2000 tests with 63 skips. Both
targeted SDK harness checks pass after their stale rows are removed. Logs:
pass4-primary-ordinary-final.log and pass4-primary-final-*.out.

The user has resumed performance experiments and AOT sweeps. Generated
bindings and coupled indexing changes remain uncommitted until their final
AOT validation.
## Fourth cycle performance work

The user resumed the full loop. Correctness checkpoint 2676c4a is pushed.
The collection generator, generated bindings and coupled indexing changes
from the second correctness pass remain in the working tree. Their first
AOT screen compares all 22 drivers against the saved pre-binding executable,
with seven samples on CPU affinity mask 4. Any accepted runtime changes will
receive a final full sweep with fifteen samples before commit.

Prepared experiments target repeated virtual-call resolution, bound-method
descriptor scans for transient handler instances, and unary host callback
argument allocation. Production runtime code remains unchanged during baseline
capture. The descriptor workload checks native reference checksums and both
fresh and serialized execution, varying reachable handler implementations.

The first 22-driver seven-sample screen matches all execution checksums.
Several primitive controls vary substantially across short runs. Longer
ABBA repeats confirm identical primitive-call bytecode between the current
compiler with previous bindings and the held binding build. Those controls
do not establish a reliable binding regression; raw results are retained in
cycle4-performance-held-screen, cycle4-performance-targeted-abba and
cycle4-performance-binding-abba.

A 13-line native List/Map lookup experiment bypassed callable adaptation for
exact wrappers while retaining subclass dispatch. All 65 focused tests and
scoped analysis passed, but paired AOT runs were consistently about 55% slower
for configuration validation and 43% slower for template rendering. The
experiment is rejected and the runtime patch is removed. Logs are retained
under cycle4-native-index-fastpath-abba. Production runtime source is again
identical to the correctness checkpoint while the descriptor baseline is
captured from the promoted many_handlers benchmark.

Bound-method binding now uses a lazy per-program index of the first bound
descriptor for each function. It retains receiver and runtime binding at each
member, without caching closures across instances. The new many_handlers
benchmark creates transient instances of 8, 32 and 128 reachable handler
classes, checks a native reference checksum, and measures fresh and serialized
programs. Compilation stays outside the measured interval.

Fifteen-sample ABBA repeats at 100,000 records show about 4% improvement with
8 handlers, 5–7% with 32 and 11–15% with 128. Longer call, dynamic and virtual
call controls are roughly flat, with matching checksums. Repeated isolated
cold runs at 128 handlers show a one-time first-call cost of about 20–27
microseconds. Sparse storage avoids allocating one descriptor slot for every
free function in programs with few bound methods. The dense-array alternative
remains an ignored draft. Logs: cycle4-descriptor-candidate-abba,
cycle4-descriptor-runtime-controls and cycle4-descriptor-cold-128.

All 132 focused descriptor, codec, bound closure, type environment, virtual
argument, dynamic dispatch, inheritance and omitted generic checks pass.
Scoped analysis is clean. The descriptor candidate is preserved as a separate
AOT executable before testing unary callback allocation. Final full-suite
runtime validation and AOT measurements remain pending.

The first unary callback specialization lived inside the general invocation
method. Long ABBA repeats measured a 14.5% improvement for unary callbacks,
but an 11.4% regression for omitted defaults and 4–7% regressions in the
zero-argument controls. That version is rejected. The next experiment moves
the specialization to the host call entry point and restores the general
invocation method unchanged. Both candidates retain the original scalar
casts, generic bounds, supplied-argument checks and defining type context.
Logs for the rejected version: cycle4-unary-runtime-controls and
cycle4-unary-callback-long-abba.

The host-only specialization improves unary callbacks by about 29% in
one-million-call, fifteen-sample ABBA repeats. Omitted defaults and bound
zero-argument methods are flat; captured zero-argument controls are about
2% slower. All 123 focused unary, closure, default, generic and covariance
checks pass, with clean analysis. Longer call and dynamic controls show no
repeatable material regression. Logs: cycle4-unary-host-callback-abba and
cycle4-unary-host-runtime-controls.

A full 22-driver, fifteen-sample AOT sweep against the saved pre-binding
baseline matches all 21 execution checksums. It includes the compilation
driver, which has no execution checksum. The sweep flags configuration
validation, template rendering and two dynamic cases. Same-checkpoint ABBA
attribution shows those deltas are not caused by the host unary change:
configuration and template medians are flat to slightly faster, and dynamic
collection writes are within about 1%. Results are retained under
cycle4-unary-host-final-aot and cycle4-unary-host-attribution. The older-baseline
regressions remain part of the final assessment, rather than being dismissed
because the targeted callback benchmark improved.

A further experiment caches the bound Map index callback per wrapper. It
targets allocation during the interface dispatch required for unknown Map
implementations. The callback retains its receiver and reads the live backing
map; subclass property overrides remain on their existing dispatch path.
Its 27 focused tests pass with clean analysis, but ABBA controls show flat
configuration validation and slower or noisy template medians. The cache
provides no consistent benefit and is removed, avoiding an extra field on
every map wrapper. Logs remain under cycle4-map-index-cache-controls.

Accepted runtime source is restored to the descriptor index and host-only
unary specialization measured by cycle4-unary-host-final-aot. The previous
full sweep remains the final AOT check for that exact runtime source. Ordinary
and SDK-full tests and final scoped analysis follow before commit.

Final validation passes all 2006 ordinary tests with 63 skips. SDK-full
passes its expectation harness and reports 2511 actual passes, 243 compiler
errors, 126 runtime failures and one unsupported aggregate. The 369 genuinely
failing fixture paths remain for the next correctness cycle. All 47 changed
or new Dart files have clean scoped analysis, including regenerated bindings,
runtime code, compiler code, benchmarks and tests. Logs: cycle4-final-ordinary,
cycle4-final-sdk-full and cycle4-final-analyze.

The performance checkpoint includes the previously held collection generator
and SDK-generated bindings, their coupled compiler dispatch/type projection
changes, the Map lookup signature/null-key correction, and four verified stale
expectation removals. The descriptor index and host unary fast path are the
only accepted runtime experiments. No interpreter loop or bytecode format
change is included. The final full AOT sweep ran before this checkpoint.

## Cycle 4 cleanup

Astra medium reviewed the cycle's compiler, binding generator, SDK harness and
accepted runtime changes. It found nullable Iterable bridge getters exporting
null through the nonnullable adapter. Nullable Iterable and Iterator getters now
evaluate the guest getter once and return null for either host null or boxed
null before exporting a non-null value. A generated-bridge regression exercises
these cases, guest iterables and iterators, and generic values in both loading
modes. Nonnullable generated getter output stays unchanged.

The generator shares erased native argument boxing through wrapBridgeArgument.
Callback parameter names are resolved once. List patterns delegate index
dispatch to IndexedReference, which already selects native or interface access.
Astra's follow-up review found no further concerns in these changes.

All 88 focused tests pass and scoped analysis is clean. SDK regeneration exits
successfully with all 90 generated output and registry hashes unchanged. Logs:
cycle4-cleanup-focused-final, cycle4-cleanup-stdlib-generation and the matching
cycle4-cleanup-stdlib-before/after SHA-256 records. Runtime source is unchanged
from the performance checkpoint, retaining its final full AOT validation.

The final ordinary suite passes all 2007 tests with 63 skips. Its log is
cycle4-cleanup-ordinary. The previous SDK-full survey still identifies 369
genuinely failing fixture paths for the next correctness cycle.

Four targeted SDK positives also pass: list/mixin, both modern and legacy
and_extension_member fixtures, and patterns/version_2_29_changes. Whole-project
analysis finds no code errors. It retains the development path-dependency
warning for the sibling CFG checkout. The unused virtual_calls benchmark import
reported by analysis is removed.

## Cycle 5 correctness pass 1

For-in statements and collection elements now bind patterns through the shared
destructuring compiler. This covers index, iterator and await-for loops. Pattern
bindings and capture cells are created in each iteration's body scope. Ordinary
loop-variable capture renewal still precedes reading the current element. The
await-for declaration setup reuses the synchronous helper instead of duplicating
it. Element types are projected through Iterable or Stream, rather than read
from unrelated type parameters of the implementing class.

Native witnesses confirm that for-in pattern refutation throws StateError.
Dedicated iteration binding contexts preserve that behavior while retaining
ordinary declaration assignment checks and final bindings. Tests cover mutable
and final captures, shadowing, loop exits, protocol iteration, destructuring
failures, collection elements and contextual numeric literal inference in both
loading modes.

Await-for patterns also exposed partial record schemas reaching a bridge
constructor's runtime metadata. Bridge argument inference now completes the
schema from the argument's formal interface view and closes unconstrained holes.
Constructor emission uses the resolved bound call when its earlier context still
contains holes. A custom iterable with an unrelated generic parameter exercises
the Stream.fromIterable boundary. The hand-maintained Stream wrapper exports
guest iterables lazily through the existing adapter; native wrapped iterables
retain their direct path.

Folded mixin members now reuse the class hierarchy's cached inferred mixin type
arguments. Explicit arguments and ordered bound fallback remain intact. Native
and both loading modes cover imported mixins, alias chains, prior mixins,
dependent bounds and folded-body type checks. Two legacy expectation rows are
removed after all runnable variants pass. The modern runtime-type fixture still
fails and remains listed.

The hand-maintained Set wrapper gains its missing unnamed factory. It uses the
existing typed linked-hash backing and constructor type witness. The test checks
contextual and deferred generic types, covariant add rejection, guest equality
and hash collisions, lookup identity and insertion order. Set.from is unchanged.

The ordinary suite passes 2013 tests with 63 skips. SDK-full reports 2521 passed,
239 compile errors, 120 runtime failures and one unsupported fixture. Compared
with the preceding checkpoint, ten more fixtures pass and no new failures appear.
Eight additional stale expectation entries are removed, covering the generic Set
constructor, for-in pattern checks and temporary-variable regressions. All ten
removed fixtures pass a variant-aware recheck in fresh and serialized modes.
SDK-tagged negative variants remain excluded by the suite's existing policy.

Logs are cycle5-pass1-ordinary, cycle5-pass1-sdk-full and
cycle5-sdk-removed-status-recheck. The full 22-driver AOT sweep completes with all
21 execution checksums matching the accepted cycle4-unary-host baseline.
Long ABBA repeats use dispatch at 2.5 million iterations, calls at one million
and external_calls at 500,000, with 15 samples and affinity mask 4. Every repeat
checksum matches. Calls and external_calls stay within about two percent of the
baseline. Typed scalar dispatch is flat to 1.5 percent faster. Object-reference
dispatch measures 3.6 to 7.7 percent slower, with large within-run ranges. This
remains unresolved timing evidence for the next performance pass; the large
initial sweep swings are not reported as improvements. Raw results and run order
are in cycle5-final-aot-flagged-abba.

Scoped analysis is clean across all nine changed production Dart files and three
new language tests. Native initializer diagnostics also pass, confirming the
ordering and lazy-field expectations used to prepare the next correctness pass.

## Cycle 5 correctness pass 2

Non-late declaration initializers now execute even when an initializing formal
or initializer-list entry supplies the final stored value. The existing store
suppression remains intact. Redirecting constructors still delegate without
repeating initialization. The shared evaluation helper retains declaring-library
and folded-mixin type contexts. Its names now distinguish evaluation from storage.
Late-field lowering is outside this fix.

Folded mixin tear-offs now recover covariance evidence from the original member
signature when their declaring mixin has no compiled method body. The runtime
function type erases covariant class-parameter occurrences as Dart requires;
static signatures and physical argument checks keep the applied class types.
Negative occurrences and method-local generic parameters retain their types.

Both native witnesses pass. All 36 focused constructor, late-field, covariance,
function-type and mixin tests pass, with clean scoped analysis. The SDK field
initialization-order variant and both runnable modern mixin inference variants
pass fresh and serialized. Their two stale expectation entries are removed.
The field fixture's negative early-super variant retains its expected compile
error. The full ordinary run has 2014 passes, 63 skips and one stale expectation
assertion for final/field_initialization_order. That additional fixture passes
fresh and serialized; removing its row resolves the sole assertion and yields
2015 passing tests. Full SDK validation reports 2525 passing fixtures, 239 compile
errors, 116 runtime failures and one unsupported fixture. Its only assertion
failure is another stale row for modern previous-mixin inference. The fixture
passes fresh and serialized, so that fourth expectation entry is removed. No new
SDK failures appear. Logs are cycle5-pass2-ordinary, cycle5-pass2-sdk-full and the
matching field-sdk-variants and mixin-previous-variants rechecks.

The run_one SDK diagnostic tool now materializes multitest variants and respects
the suite's negative-test policy. Compilation and runtime construction failures
cannot satisfy an expected runtime-error case. Each variant keeps the existing
guest exception-field and stack diagnostics, and failures return a nonzero exit.
The helper is formatted and scoped analysis is clean. Smoke checks cover an
ordinary constructor fixture, the initialization-order multitest with its skipped
negative, and a genuinely expected runtime-error variant from async_star_invalid.
Runtime source is unchanged, so this checkpoint adds no new AOT requirement.

## Cycle 5 correctness pass 3

Object's hand-maintained equality adapter now preserves guest instances,
functions and Type descriptors instead of reading their unsupported native value.
Guest instances use their dispatch root so an inherited method's superclass view
still identifies the same object. The identical intrinsic applies the same root
normalization and preserves Type descriptors in mixed comparisons. Its existing
descriptor equality for two Type values remains intact. Custom guest equality
continues to dispatch through the guest operator, with its argument checks.

Lexical super equality now bypasses ordinary virtual equality. Object's default
operator compares the actual receiver through the existing identical intrinsic,
since the runtime elides Object's superclass storage link. Source superclass
operators use the existing lexical static call path; super != negates that same
operator's result. Tests check inherited identity, distinct instances, overridden
operators and their call counts in both loading modes.

The native superclass oracle returns zero, all 66 focused tests pass and scoped
analysis is clean. The ordinary suite has 2016 passes, 63 skips and two stale
expectation assertions. Both fixtures pass fresh and serialized rechecks, yielding
2018 passing tests after removing their rows. A third targeted SDK fixture also
passes both loading modes. The three removed expectation entries are
operator/equality_covariant, type/constants and constants_2018/equals. Their
negative multitest variants retain the suite's existing skip policy. The
covariant equality fixture exercises mixed primitive/guest comparisons; lexical
super behavior is covered independently by the new regression test.

SDK-full exits successfully with 2528 passing fixtures, 239 compile errors,
113 runtime failures and one unsupported fixture. All remaining genuine failures
retain their expectation entries. This is three additional passing fixtures with
no new failures compared with pass 2. Logs are cycle5-pass3-ordinary,
cycle5-pass3-sdk-full and the matching focused, scoped-analysis and dual-mode
SDK rechecks.

The exact equality candidate completes all 22 AOT drivers with 15 samples and
affinity mask 4; all 21 execution checksums match the exact c6838f2 baseline.
The initial captured-void callback result is 18.2 percent slower. Two longer
ABBA blocks at 300,000 calls per sample narrow this to 8.0 percent, with large
OS outliers but distinct centers. Other callback cases measure 0.6 to 3.4
percent slower. This callback timing remains a follow-up for the performance
pass, rather than being dismissed by the initial sweep's threshold.

The callback's guest program, functions and closure metadata are byte-for-byte
identical before and after the compiler changes: 154 code bytes and 15 functions.
An isolated build with only the Object/identical runtime changes measures about
1.1 percent faster than baseline in the same longer comparison. The combined
build measures about 9.3 percent slower than that runtime-only build. Thus the
slowdown accompanies the compiler changes or the combined AOT layout; the new
runtime adapters do not account for it in isolation. No speculative runtime
branch or adapter is added to perturb this unrelated callback workload. Results
are in cycle5-pass3-equality-aot, cycle5-pass3-callback-abba and
cycle5-runtime-attribution-abba. The retained validation checkout is reused at
c6838f2 for this attribution; all builds and measurements are serialized.

## Cycle 5 correctness pass 4

Implicit object invocation now requires a method named call. A callable field or
getter is still valid for explicit member invocation, but it cannot make the
object itself callable. The existing noSuchMethod path receives the original
positional, named and generic arguments when the implicit call has no method.
Successful guest methods retain their existing invocation path.

Native bridge wrappers can expose guest subclasses through bridgeData. Implicit
invocation now consults that guest instance, and a compiler class flag permits
bridge fallback only when the nearest concrete call declaration is a bridge
method. Interface promises do not count as implementations. Source overrides
and folded mixins retain guest dispatch. The flag survives immutable program
copies and serialization; strict codec version 131 includes and validates it.

Dynamic member invocation through a getter result must remain distinct from a
function-expression call. Native controls confirm that dynamic holder.item()
may read the returned object's call getter, while (holder.item)() and statically
typed holder.item() reject that object without reading its call getter. The
guest getter-result forwarding path preserves this distinction, including named
and generic method calls. Ordinary explicit recursive getter invocation remains
unchanged.

All 53 focused tests, both native oracles and scoped analysis pass. Every runnable
variant of call/method_must_not_be_field and call/method_must_not_be_getter passes
fresh and serialized, so both stale expectation entries are removed. Their
negative variants retain the suite's skip policy. In particular, case 01 still
needs a static compiler rejection and is staged as a separate compiler task.
The ordinary suite passes with 2020 tests and 63 skips after updating two codec
version assertions. SDK-full exits successfully with 2530 passing fixtures,
239 compile errors, 111 runtime failures and 363 skipped outcomes. No new
failures or stale expectations appear.

The exact candidate completes all 22 AOT drivers at affinity mask 4 with 15
samples. All 21 execution checksums match the accepted pass-3 executable; both
compile-driver outputs are 1271 bytes. The larger initial mixed-dispatch and
declared-direct virtual-call timing flags do not persist in longer reverse-ABBA
runs. All three virtual-call cases improve about 1 to 2 percent. Object-reference
dispatch varies between runs and averages 3.2 to 5.2 percent slower across its
integer, double and mixed cases. This remains a performance control to investigate.

At 500,000 base callback calls, captured-void improves 7.0 percent, captured-value
is flat, default adapters improve 12.5 percent and bound members improve 8.4
percent. The one-argument callback has a large candidate outlier, with run medians
of 128.5 and 95.4 milliseconds, so its average cannot establish a stable change.
No unrelated runtime change is added to alter AOT layout. These timing limits
carry into the performance pass. Logs are cycle6-pass4-final-aot and
cycle6-pass4-final-abba despite this checkpoint belonging to cycle 5. The exact
accepted executable is cycle6-pass4-final.exe, SHA-256
a14bb43b96c9d129568420ff7ccc602624e772954e81013fb1562655c3948afa.

## Cycle 5 performance pass

Unknown List parameters previously paid member resolution and bridge invocation
for every indexed read, including allocation of the List adapter's callable.
The new callIndex instruction reads trusted native storage directly. Internal
VM and host boxing use a final TypedNativeList wrapper through the existing
generative constructor; there are no extra fields, views or allocations. The
existing final MappedListView is also eligible. Public wrappers and custom
subclasses keep ordinary dispatch.

The generator shares the complete callVirtual handler as callIndex's fallback,
preserving guest resolution, argument checks and direct VM frame entry. Existing
register arguments, clobbers and call-site metadata remain unchanged. The native
read retains the original boxed-index conversion, RangeError behavior, element
identity and null normalization. Compiler selection and cold program validation
share the indexed-read call-site predicate. Strict codec version 132 records the
changed instruction set. All machine and opcode output is regenerated.

The new indexed_aggregation benchmark weights aligned columns through a List
parameter, using native, guest-custom and mixed receivers. Native Dart and both
evaluator loading modes agree at 5000 batches: 6897500, 7177500 and 7037500.
The exact accepted pass-4 baseline is compiled before production changes. At
25000 batches and 15 samples with affinity mask 4, reverse-ABBA native medians
are 113.839/112.840 milliseconds for baseline and 44.408/44.204 for candidate,
about 61 percent faster. Mixed medians are 115.469/116.020 versus 68.715/70.425,
about 40 percent faster. Guest baseline medians range from 131.698 to 140.394;
settled candidate runs center near 87 milliseconds, about 34 percent faster.
Drifting candidate guest runs reach 110.376 and 156.184 milliseconds and remain
in the raw logs. These are host timing limits, not discarded checksum failures.

All 76 focused tests pass, including compiled fresh/serialized custom dispatch,
mapped lazy storage, aliases, defining runtimes, invalid writes and malformed
indexed-read bytecode. Scoped analysis has no errors; three style infos are
reserved for the cleanup pass. Generator output also passes its deterministic
check.

The exact candidate completes all 22 AOT drivers against the accepted pass-4
executable. All 21 execution checksums match, and both compile-driver outputs
are 1271 bytes. Initial call and dynamic timing flags of about 25 to 32 percent
do not persist in longer reverse-ABBA controls. Polymorphic calls average about
2 percent slower, boxed calls are flat and overflow calls about 1 percent slower.
Stable dynamic dispatch is flat; alternating dynamic dispatch remains about
5 to 6 percent slower. Config validation differs by about 1 percent and templates
are about 3 percent slower. Callback cases stay within about 4 percent, with bound
members slightly faster. These modest timing costs remain in the record.

The dispatch driver is a non-indexed ALU/storage control. Its initial large
improvements also disappear in longer runs; it does not establish an indexing
benefit. The measured benefit comes from indexed_aggregation, with matching
native, guest and mixed behavior. All benchmarks and builds are serialized.
Results are cycle5-trusted-list/full22-aot, controls-abba.log, abba.log and
guest-repeat.log. The exact full-sweep candidate is native_field_sweep-candidate.exe,
SHA-256 CFA3168C1A9F792E52E9D83DF83CBA496B1D19B90292C7C6E288E60439B595A0.
The final ordinary suite passes with 2024 tests and 63 skips. SDK-full exits
successfully with 2530 passing fixtures, 239 compile errors, 111 expected runtime
failures and one unsupported skip. No new failures or stale expectations appear.

## Cycle 5 cleanup

Astra medium reviewed the complete cycle from 815d62f through the performance
checkpoint and the cleanup working diff. It found no additional actionable
correctness, architectural or simplification issues. The short Object/identical
boundary conversions remain local; introducing another cross-library helper for
them would add more machinery than it removes.

TypedNativeList now forwards its inherited constructor parameters directly and
no longer imports Runtime solely for their explicit annotations. Generator and
benchmark string construction use interpolation, and the observed test wrapper
is private. Generated machine/opcode output remains byte-for-byte unchanged.
Generator checks pass before and after formatting, scoped analysis has no issues,
all 76 focused tests pass and the three native/fresh/serialized benchmark
checksums remain unchanged. The final exact-source sweep completes all 22 AOT
drivers with 15 samples and affinity mask 4. All 21 execution checksums match,
and both compile-driver outputs are 1271 bytes. The cleanup executable is
byte-for-byte identical to the accepted performance candidate, with the same
CFA3168C1A9F792E52E9D83DF83CBA496B1D19B90292C7C6E288E60439B595A0 SHA-256.
No timing attribution or repeated broad run is needed for identical executable
output. Logs are cycle5-trusted-list/cleanup-full22-aot. The ordinary and SDK-full
results from the performance checkpoint remain the broad validation for this
behavior-preserving cleanup.

## Cycle 6 correctness pass 1

Raw constructor contexts now supply the declaration's instantiate-to-bounds
arguments before downward inference. A raw Box<T extends A> annotation therefore
keeps Box<A> when its constructor receives an AA, while inferred and explicitly
typed Box<AA> expressions retain their narrower type. The focused test covers
local, return, field, parameter and inherited-interface contexts, dependent
bounds and unconstrained Object contexts.

Generic extension matching now deconstructs FutureOr payloads and structural
function signatures. An actual FutureOr retains its own payload; Future values
supply their element type. Nullable Futures still require null-aware access.
Function matching uses the existing type unifier and strict assignability after
substitution, including optional parameters accepted by the extension's signature.

The SDK fixture also exposed anonymous extensions sharing an empty parameter
owner name. Compilation and declaration signatures now use each extension's
registered name, consistent with member lookup and on-type substitution. Named
extensions keep their direct name lookup. The regression combines anonymous
extensions with different parameter names and arities, plus a generic method.

These changes affect only compilation. They add no runtime checks, adapters,
boxing or interpreter instructions. Native assertions and fresh/serialized
extension controls pass. All 24 focused tests pass and scoped analysis is clean.
The final ordinary suite passes with 2028 tests and 63 skips. SDK-full records
2532 passing fixtures, 238 compile errors, 110 expected runtime failures and one
unsupported skip. Its only assertion failures are the two stale expectations for
generic/generic_test.dart and extension_methods/static_extension_silly_types_test.dart.
Every runnable variant of both fixtures passes fresh and serialized validation;
their negative 01 variants follow the existing negative:skip policy. After
removing those exact expectations, the filtered final SDK harness passes both
fixtures. No new failures appear. Logs are cycle6-pass1-final-ordinary.log and
cycle6-pass1-sdk-full.log. There remain 348 genuine compile/runtime failures.

## Cycle 6 correctness pass 2

Implicit value calls now require an actual call method in the receiver's static
interface. Fields and getters named call do not qualify, even when their values
are functions. The check reads source declaration kind and bridged method kind,
uses the existing cycle-safe effective-bound traversal, and preserves inherited,
mixin, abstract-interface, generic-bound, dynamic, Function and extension calls.
A getter shadows an extension method instead of granting an implicit call.
Explicit property calls remain valid. This emits no additional bytecode.

Nested raw types previously used different child IDs from their explicit default
instantiations, despite equal descriptor contents and printed types. RuntimeTypes
now memoizes descriptor component IDs by immutable integer rows. The first equal
completed row supplies the representative. Direct type IDs, declaration IDs,
binder identities and runtime equality remain unchanged. Caching the allocated
ID before descent preserves existing cyclic references without copying type trees
or changing instantiate-to-bounds rules.

Native controls, all 42 focused tests and scoped analysis pass. Every runnable
cyclic_type_test.dart variant passes fresh and serialized validation, including
the formerly failing nested contractive and noncontractive cases. Its exact
expect_fail entry is removed. The getter/field implicit-call fixtures retain all
positive behavior; their negative 01 variants now produce CompileError under an
explicit diagnostic probe. Negative 02 implicit tear-off diagnostics remain a
separate existing limitation.

The ordinary suite passes with 2036 tests and 63 skips. SDK-full records 2535
passing fixtures, 238 compile errors, 107 expected runtime failures and one
unsupported skip. Its only assertion failures are newly stale expectations for
generic/f_bounded_quantification4_test.dart and unsorted/cyclic_type2_test.dart.
Both fixtures pass fresh/serialized probes; their exact entries are removed and
the final filtered harness passes. The previously verified cyclic_type_test.dart
entry was removed before the broad run. No new failures appear. Logs are
cycle6-pass2-ordinary.log and cycle6-pass2-sdk-full.log. There remain 345 genuine
compile/runtime failures. No runtime benchmark gate is needed for these compiler
changes; an exact accepted executable will precede the next runtime fix.

## Cycle 6 correctness pass 3

Legacy function-typed formals with omitted return annotations now retain their
structural function signatures. An unwritten return type defaults to dynamic,
including nested signatures. One shared annotation predicate also recognizes
function suffixes in default, closure and accessor paths; ordinary omitted field
and super formals keep their existing inferred types. Dynamic generic functions
are rejected at these non-generic parameter boundaries by the existing type
check operations. A dynamic argument now receives the required AssertType at
that boundary, where the erased dynamic parameter previously needed no check.
No adapter or new runtime conversion machinery is introduced.

The broad SDK check exposed a previously hidden contextual method tear-off
problem: c.bar on C<int> retained the declaration's T in its static signature.
Materialization now substitutes the bound receiver's view of the declaring
class, including inherited views. Callable-owned type parameters remain generic;
explicit lexical-super and extension bindings keep their existing precedence.
Runtime covariance erasure still uses the original parameter declarations.

Iterable.map checks guest callback generic arity before constructing its lazy
result, including an empty input. TypedClosure and TypedMember supply existing
descriptor metadata; bound members need no temporary closure. The original
callback is retained, with no adapter or per-element check. Implicitly and
explicitly instantiated callbacks and ordinary methods remain valid.

String.contains now unwraps its declared native Pattern parameter, accepting
both String and RegExp, and honors the optional startIndex. Argument count gates
the optional register read. String and Iterable use their existing explicit
hand-maintained wrapper exceptions in .dart_eval/bindgen.yaml; generated SDK
wrappers are unchanged.

Native controls and all 19 focused tests pass. Both runnable function_dcall
variants and the generic_function_parameter fixture pass fresh and serialized
execution. The final ordinary suite passes with 2039 tests and 63 skips.
SDK-full records 2536 passing fixtures, 238 compile errors, 106 expected runtime
failures and one unsupported skip. Its sole assertion failure is the verified
stale expectation for generic/function_dcall_test.dart, which is removed. The
earlier broad run exposed the contextual tear-off regression; these final
results include its correction, with no new failures. There remain 344 genuine
compile/runtime failures. Final broad logs are cycle6-pass3-fix/ordinary-final
and sdk-full-final; diagnostic and dual logs distinguish actual SDK fixtures
from the separate twelve-marker native witness.

The final runtime gate compares the exact pass-2 baseline executable BC69DBC0
with the accepted candidate CD1B9EC2. All 22 AOT benchmark drivers complete;
their 21 execution checksums match and the compile fixture remains 1271 bytes.
Long ABBA and reverse BAAB controls clear the initial large dispatch and call
regressions. Combined dispatch and call medians are generally within 0-3%;
template rendering is flat and external-call controls differ by less than 2%.
The dynamic receiver-stable control retains a roughly 4-6% cost in those longer
paired runs, with unchanged byte count of 26426. Its source does not use the new
callback check, so the cause is not established and no performance gain is
claimed for this correctness pass.

An isolated never-inline annotation on the cold callback helper fails to show
a repeatable benefit. Dynamic timings reverse between ABBA and BAAB orders,
callbacks are mostly flat and calls remain within about 2.5%. The annotation is
reverted, restoring the exact source of CD1B9EC2. Full-sweep evidence is in
cycle6-pass3-fix/aot-final; longer controls are in long-abba-final, and rejected
trial evidence is in pragma-trial/abba. These results justify retaining the
small correctness boundary check without changing the interpreter loop.

## Cycle 6 correctness pass 4

Loop analysis now separates break exits from continue backedges. Update and
condition headers join the body and continue states; post-loop analysis joins
the false-condition state with break states only. A body/backedge proof no
longer erases facts guaranteed by the false condition. Do-loop headers retain
their conservative pre-loop state, matching native Dart's rejection of
assignment-only narrowing.

Loop labels expose their existing saved jump lists to enclosing try/finally
analysis. A completing finalizer overlays its write summaries onto jumps that
cross it, checking binding identity and preserving the saved SSA and storage.
Nested finalizers apply in order; jumps originating inside a finalizer are
excluded from its own overlay. Terminal finalizers preserve prior predecessor
proofs, as verified against native Dart. Try blocks without finally skip the
pending-label scan. The saved-state bookkeeping adds no runtime checks or
adapters, and runtime source is unchanged.

The native witness includes a finite finalizer that overrides a break with a
continue, temporarily demotes the value, then reaches the false-condition exit.
All 66 focused tests pass and scoped analysis is clean. Both runnable do-loop
variants and the while-loop baseline pass fresh and serialized SDK probes;
their negative 01 variants retain the expected Object.length compile error.
The ordinary suite passes with 2051 tests and 63 skips. SDK-full records 2538
passing fixtures, 236 compile errors, 106 expected runtime failures and one
unsupported skip. Its only assertion failures are the two verified stale
expectations for nnbd/type_promotion/do_condition_is_not_type_test.dart and
while_condition_false_test.dart. Only those entries are removed and the final
filtered harness passes both fixtures. There remain
342 genuine compile/runtime failures, with no new failures. Broad and focused
logs are retained in cycle6-pass4. Runtime source is unchanged, so this pass
requires no runtime AOT gate.

## Dart 3 minimum policy

The SDK suite now sets min_sdk: '3.0', following the requested evaluated-source
support floor. Numeric major/minor comparison handles versions such as 3.10.
The analyzer's recognized language override determines eligibility for each
fixture root and selected multitest variant; ordinary comments and strings do
not act as overrides. Explicitly old relative SDK helpers also make their
importing fixture unsupported. Unversioned helpers, package shims and vendored
packages retain their existing loading behavior. Later Dart 3 feature gates
remain meaningful.

All 33 SDK harness checks pass and scoped analysis is clean. An actual-source
audit identifies nine expect_fail entries entirely blocked by the new floor,
including one modern root importing a Dart 2.19 helper. Only those obsolete
entries are removed. These are policy exclusions, not correctness fixes or
newly passing fixtures. The staged Dart 2 compatibility implementation is
retired; modern horizontal-inference work remains relevant. Audit evidence is
cycle6-performance-baseline/min-sdk-audit.json; the final filtered harness
confirms all nine fixtures skip for the minimum-version reasons.
Runtime/compiler source is
unchanged by this policy checkpoint, so the frozen performance baseline remains
valid.

## Cycle 6 runtime performance

Repeated Map indexing still resolves a member and creates a closure before
reading canonical storage. callIndex now reads the backing map directly for
the final internal TypedNativeMap wrapper. VM Map boxing and the existing lazy
host boxing/adoption boundaries construct that wrapper. It adds no instance
fields or extra allocations, backing copies or adapters. The List branch stays
first; ordinary public Map wrappers and guest MapBase implementations retain the
shared virtual-call fallback. Null keys and null/missing results use the same
normalization as the original adapter; checked writes and runtime ownership
are unchanged. Generator output is regenerated, with no opcode/codec change.

The new inventory_pricing benchmark prices weighted purchase baskets against
a host feed, a guest contract-price view, or alternating rows. Seven lookups
cover named SKU prices, a null freight key, a discontinued null value and a
missing SKU. All twelve native controls and twelve fresh/serialized evaluator
controls match an independent numeric oracle. New runtime tests cover VM
boxing through export-cache restoration, nulls, identity, host aliases,
custom dispatch, defining-runtime metadata and invalid writes. Guest hashing
can throw through the fast read, be caught, and allow a later successful query.
All 65 focused Map/List checks pass; scoped analysis and generator check pass.

The exact 23-driver baseline FFAE7E15 precedes runtime changes. Candidate
49EFA1E6 uses the same benchmark sources. The initial 64-run pilot improves
native inventory by 31-35%, configuration validation by 13.4% and template
rendering by 9.0%; numeric-field and telemetry controls are flat. A subsequent
48-run ABBA and reverse BAAB check uses 100000 baskets and fifteen samples:
native fresh/serialized improve 36.7%/36.9%, mixed improves 5.9%/6.0%, and guest
costs 2.7%/2.6%. At 200000 dynamic iterations, the initial 10-15% flags reduce
to 2-4% costs; ordinary and virtual-call controls are flat. Those modest costs
are retained as a tradeoff for the repeated Map-read gains. Raw pilot, long
controls and oracle evidence are in cycle6-performance-baseline.
The final full 23-driver AOT sweep matches all 22 execution checksums and the
1271-byte compile output. Native inventory improves 35-36%, configuration
validation 16.1% and template rendering 12.0%. Large timing changes in unrelated
dispatch/call cases are not attributed to this Map change. The sweep raises
25.5% overflow-argument and 22-24% exception flags, so a bounded ABBA/BAAB repeat
uses the same exact binaries at 500000 call iterations and 100000 exception
iterations, with fifteen samples. Overflow arguments are flat at -0.3%; noTry
is +0.1% and handledThrow -3.6%. Other controls range from -2.1% to +3.4%.
The first call process is an outlier; the reverse order is flat. The large
flags do not reproduce, and no timing cause is established. All sixteen repeat
processes match their checksums. The small measured costs remain accepted.

Ordinary tests pass with 2053 tests and 86 skips. SDK-full satisfies every
expectation, recording 2404 passing fixtures, 230 compile errors, 103 runtime
failures and three reported unsupported skips. There are no new failures or
stale assertions. The 333 supported compile/runtime failures replace the prior
342 after the nine policy exclusions; this runtime pass adds no correctness
fixes. Full sweep, bounded repeat and broad logs are retained alongside the
earlier controls in cycle6-performance-baseline.

## Cycle 6 cleanup

The cleanup skips the tear-off declaring-class view lookup when there are no
class parameters to substitute. Finalizer bookkeeping stores one eager list
of crossing jump snapshots instead of retaining unused list-owner tuples and
nesting another loop. Test-only source, configuration and Map wrapper helpers
are private. Runtime behavior and generated output are unchanged.

The requested Astra medium review finds no actionable issues across cycle 6
and this cleanup. It confirms String and Iterable edits follow the explicit
hand-maintained binding exceptions and machine output has matching generator
changes. All 110 focused compiler, flow, runtime and SDK harness checks pass;
scoped analysis and diff checks are clean. Evidence is in cycle6-cleanup. The
runtime performance checkpoint already passed its full AOT gate; this cleanup
does not change runtime source and requires no additional sweep.

## Cycle 7 correctness pass 1

Record return contexts now unify field types only when positional counts and
named keysets match completely. A mismatched shape contributes no partial
constraints. Matching and nested fields reuse ordinary unification, including
literal int-to-double context conversion and name-order independence.

Two further controls expose metadata issues. Inferred generic calls formerly
erased a caller's type parameter to dynamic; they now retain its descriptor for
the existing frame type environment. A temporary reversal of that one condition
makes the caller-forwarding check fail in both runtime modes while record checks
still pass. Native Dart passes the same forwarding control. The descriptor
component interner now includes completed root rows too, so nested records use
the same canonical field IDs as runtime resolution. Previously their outer
runtime types displayed identically but compared unequal despite equal inner
types. These compiler changes add no runtime source, adapters, boxing or new
bytecode operations.

All eight new semantic controls pass natively and in fresh/serialized evaluator
checks. The initial focused group passes 62 tests; final focused checks pass
12 tests after adding the independent caller regression. Scoped analysis is
clean. Ordinary tests pass with 2054 tests and 86 skips. SDK-full records 2405
passing fixtures, 229 compile errors, 103 runtime failures and three reported
unsupported skips, with only the verified stale expectation for
records/type_inference_field_name_mismatch_test.dart. The actual fixture passes
fresh/serialized, only that stale entry is removed, and its final filtered
harness passes. Supported compile/runtime failures decrease from 333 to 332,
with no new failures. Evidence is retained in cycle7-record-context.

## Cycle 7 correctness pass 2

Extension selection retains the receiver's lexical type parameter instead of
replacing it with its bound. Instance-member lookup uses the effective bound,
including nullability and chained parameters. Promotion intersections are
erased from inferred extension arguments while their lexical identity remains.
Explicit dynamic bounds retain dynamic invocation until promotion supplies a
concrete bound. Native and fresh/serialized controls cover bounded, unbounded,
promoted, nullable and chained receivers, plus instance-member precedence.

The ordinary suite exposed an inherited bridge callback regression: a guest
Iterable subclass was looked up by its guest name inside the bridge library,
leaving its callback element parameter unresolved. Bridge argument contexts
now use the resolved declaring-owner view, which also projects reordered
subclass type arguments correctly. Focused imported, multihop and alias controls
exercise map/where callbacks through the existing canonical toList path.
Separate prefixed type-argument lookup and Iterable getter reification failures
found while developing these controls remain recorded for subsequent passes;
they are not counted as fixed. No runtime, generated stdlib, adapters, boxing or
new bytecode operations are added by this pass.

Ordinary tests pass with 2055 tests and 86 skips. The additional imported
callback fixture was added after broad discovery and passes separately;
the final focused group passes nine tests, with native controls and clean scoped
analysis. SDK-full records 2406 passing fixtures, 229 compile errors, 102 runtime
failures and three reported unsupported skips. Its only stale assertion is
extension_methods/static_extension_resolution_7_test.dart. The final source
passes that actual fixture fresh/serialized, only its expectation is removed,
and the filtered harness passes. Supported compile/runtime failures decrease
from 332 to 331, with no new failures. Evidence is retained in
cycle7-extension-bounds.

## Cycle 7 correctness pass 3

Spread sources receive Iterable element contexts for Lists and Sets, or Map
key/value contexts for Maps. Null-aware source contexts are nullable. Source
arguments come from the instantiated Iterable/Map view, so fixed and reordered
inherited parameters contribute their actual element types. Raw shape validation
retains the existing per-element checks for dynamically typed sources.

Collection literals use schema holes until upward inference completes and refresh
their exact allocation proofs with the inferred type. Context selects ambiguous
Map/Set literals before source peeking; empty literals retain declared generic
parameters. Proven raw collection runtimeType accesses use existing constant-type
instructions. A statically null spread supplies no element evidence. A literal
containing only null spreads infers Never; a truly empty literal defaults dynamic.
Collection for sources use the existing loop-variable Iterable/Stream context,
independently of the output element type. No runtime source, new opcode, adapter
or additional boxing is introduced.

Nineteen spread controls and six transformed loop-source controls pass natively,
including await for. All 80 focused tests pass; scoped analysis and diff checks
are clean. The ordinary suite passes 2058 tests with 86 skips. SDK-full records
2410 passing fixtures, 224 compile errors, 103 runtime failures and three reported
unsupported skips. Its only mismatches are four newly passing expected failures:
regress/regress50905_test.dart, spread_collections/inference_test.dart,
spread_collections/null_spread_context_test.dart and type_variable/promotion_test.dart.
All four and the four regressions discovered during development pass fresh and
serialized probes. Only those four stale entries are removed; their final filtered
harness passes. Supported compile/runtime failures decrease from 331 to 327,
with no new failing fixtures. Evidence is retained in cycle7-spread.

## Cycle 7 correctness pass 4

Null-aware List, Set and Map elements compile under nullable element contexts,
evaluate once and contribute their non-null types. Known-present values add no
guard; known-null map keys compile their values on a disconnected inference arm,
so graph cleanup removes value-side execution. Collection element results separate
bottom-type inference from abrupt evaluation: ?null contributes Never without
ending the literal, and an if/for body can throw while its enclosing element
still completes. Nullable type parameters retain their lexical identity through
non-null bound intersections. Map keys are snapshotted before value evaluation
can reassign their source local.

Invocation binding retains fully known preliminary downward solutions instead of
overwriting them with argument inference. Bound refinement intersects outer
nullability, so int? under `extends num` fixes int; nominal generic arguments
retain their own nullability. Whole dynamic contexts still permit upward
inference. Shorthand selector chains use the outer context to select a namespace,
while the receiver call infers independently. Parentheses block that namespace
propagation, matching the native compiler's rejection. Dart 3.8 null-key value
arms retain their older flow-demotion rule without gaining an executable edge.

Nested closure compilation exposed a stale snapshot: write capture was marked
after saving a nullable local's earlier non-null promotion. Snapshot restoration
now retains the binding's declared type, clears value facts and preserves its
write epoch when closures can write it. Type-inference restoration also rejects
those stale promotions. The capture controls run in fresh and serialized modes.
This pass changes no runtime source, generated stdlib, opcode or adapter.

Native witnesses pass 25 null-aware controls, a 17-row downward-inference report,
three capture scenarios, seven valid shorthand scenarios and both 3.8/3.9 flow
versions. Native Dart rejects the parenthesized shorthand receiver covered by a
negative compiler test. The corrected broader focus passes 193 tests; final focus
after shorthand and flow-version fixes passes 82 tests. Scoped analysis is clean.
The final ordinary suite passes 2067 tests with 86 skips. SDK-full records 2414
passing fixtures, 220 compile errors, 103 runtime failures and three reported
unsupported skips. Its only mismatches are four newly passing expected failures:
null_aware_elements/const_literals_test.dart, evaluation_order_test.dart,
type_inference_simple_positive_test.dart and sound_flow_analysis/null_aware_map_entry_test.dart.
All four and both SDK regressions found during development pass fresh and
serialized probes on the final source. Only those four stale entries are removed.
Bytecode checks confirm [?1] matches [1] and an absent key's value call is removed.
Supported compile/runtime failures decrease from 327 to 323, with no new failing
fixtures. The final filtered SDK-full harness passes all four removed rows.
Evidence is retained in cycle7-null-aware and cycle7-downward-inference.

## Cycle 7 performance

Dynamic native List.add calls now lower to a checked append instruction when the
call is an ordinary method with one positional argument and no named or type
arguments. Only the final TypedNativeList wrapper takes the direct path. It uses
the existing cached element-type check and the wrapper's backing-list add; custom
wrappers, guest ListBase overrides and Set.add retain ordinary dispatch. The
existing List bridge delegates to the same helper. No backing copy, wrapper,
adapter, extra boxing or argument marshalling is introduced. List is explicitly
hand-maintained in .dart_eval/bindgen.yaml for its runtime semantics.

The machine and opcode tables are regenerated from generate_typed_machine.dart.
The new normal opcode shifts later IDs, so TypedCodec advances from 132 to 133.
Cold validation rejects incompatible append call-site shapes. Codec tests use the
declared version for their serialized header and reject the previous inner version.

Native validation and 86 focused tests pass, including fresh/serialized execution,
invalid writes before mutation, host aliases and export identity, custom property
dispatch, guest overrides and Set.add's bool result. Defining-runtime cache flips
are tested across fresh/serialized instances of the same program, rather than
different numeric descriptor layouts; the existing import helper is unchanged.
An initial test incorrectly expected an exported boxed null to remain boxed.
Both direct and ordinary dispatch normalize that argument to null at the entry
boundary; the corrected control checks both paths. Analysis and the generator
check are clean at 223 normal and 165 extended instructions.

The ordinary run passes 2069 tests with 86 skips and finds only two hard-coded
version-132 assertions. After their correction, all four global-codec tests pass,
including the obsolete-version control. SDK-full passes with its unchanged footer
of 2414 passes, 220 compile errors, 103 runtime failures and three reported skips;
no expectation changes or new semantic failures occur.

Unchanged baseline and candidate AOT executables run serially at affinity mask 4.
The five-workload pilot uses ABBA then BAAB, four process medians per side and
15 samples per invocation. Dynamic receiver writes improve from 26.612 to 17.170 ms
(-35.5%); unknown-value writes improve from 24.657 to 14.460 ms (-41.4%). Both order
blocks improve, and every checksum matches. Other dynamic rows range from -4.3%
to +2.1%; JSON is +0.1%, calls range -0.3% to +2.1%, inventory is -0.9%/-0.4% and
virtual calls range +0.0% to +1.4%. A failed initial pilot attempt is discarded:
its PowerShell process object lost the exit code after refresh. The ignored runner
retains the native handle and checks a non-null exit code before recording a run.

The final exact-executable 23-driver AOT sweep matches all 22 execution checksums;
both compile outputs are 1271 bytes. It shows -35.6%/-34.5% for the two append rows.
Initial single-pair flags include callbacks +5.4%, virtual calls +5.9%, inventory
+6.1% and a sync-async control at 0.008 versus 0.013 ms. A 32-process repeat uses
longer callbacks, virtual, inventory and async workloads with both orders and
15 samples. The flagged callback becomes -2.7%/-0.6%, virtual rows stay within
2.5%, inventory within 1.3%, and syncFunction improves in both orders. Other
callback controls move by up to 3.5%; these modest changes remain in the evidence.
Dynamic receiver-alternating's single-sweep +5.0% is +0.5% in the longer eight-run
pilot. Unrelated gains such as globals -8.9% are not attributed to append dispatch.

Baseline SHA256: DBCE352D1F16AA27934962329A4B6A9D4AECFA7FDA4BD7A2EA66844BB2317BDE.
Candidate SHA256: 403E65DCA8AD7695626ABCF56AB87F41DB9FA7B3C44ABBE81A835E95FF559754.
Evidence is retained in cycle7-list-add-performance, including pilot-abba-baab-verified,
full23-aot/named-median-changes.csv and bounded-controls. The runtime candidate is
accepted for its repeatable append gains with no persistent large control slowdown.

## Cycle 7 cleanup

Nested runtime-type components reuse descriptorOf's already registered canonical
row instead of copying and interning it a second time. The original per-type ID
is still cached before descent, preserving recursive bounds. Append tests retain
semantic and malformed-codec controls; the assertion-only opcode-presence test is
removed. The performance phase's bytecode inspection remains recorded evidence.

The explicitly configured Astra medium reviewer finds no actionable issues across
c86f9b4..459b195 and the cleanup diff. Scoped analysis is clean and 106 focused
tests pass, covering record contexts, raw and recursive type identity, nested
generic environments, omitted bounds, type descriptors, append/native List and
codecs. No runtime, opcode or generator source changes in this pass, so the final
23-driver AOT sweep remains valid. Evidence is retained in cycle7-cleanup.

## Cycle 8 correctness pass 1

Wide integer tokens in double contexts now use their mathematical value rather
than the parser's nullable or signed int cache. Small integers keep the existing
fast path; other tokens are checked for finite, exact double representation at
compile time. High-bit hexadecimal tokens therefore retain their unsigned double
value, while ordinary int contexts retain Dart's signed hexadecimal behavior.
Inexact and overflowing double literals are rejected.

Custom binary operators now supply their substituted formal operand context,
including inherited and extension operators. Index and setter contexts reuse the
same resolver helper. Primitive arithmetic and equality keep their existing
context rules, and operands retain their existing single evaluation and snapshot.

The larger SDK fixture then exposed omitted constructor defaults being emitted
as null: scalar-default evaluation had also read the absent cached int value.
Default evaluation now shares the contextual literal parser for guest calls,
closure descriptors and exports, preserving wide values and negative zero without
adding runtime conversions. Explicit constructor type annotations resolve in the
caller's library, including imported, named, redirecting and lexical generic calls.

The native wide/default and operator witnesses pass. Native CFE rejects all eight
precision/range controls and the inexact custom-operator operand. Scoped analysis
is clean; 57 focused tests pass, including fresh/serialized execution, omitted
defaults, constructor/method tear-offs, closures and direct host export defaults.
Both double_literals/double_literal_coercion_test.dart and
double_literals/implicit_double_context_test.dart pass fresh and serialized.
The ordinary suite passes 2076 tests with 86 skips. Temporary representation
diagnostics used to locate the default bug are fully removed. No runtime, opcode,
generator or stdlib source changes are made in this pass.

SDK-full reports 2416 passes, 218 compile errors, 103 runtime failures and three
reported skips. The two verified numeric fixtures are its only expectation
mismatches, and their stale expect_fail entries are removed. Genuine supported
failures decrease from 323 to 321; language-floor skips remain separate.
The actual filtered SDK-full harness passes both fixtures after the exclusions
are removed. Evidence is retained in cycle8-pass1.

## Cycle 8 correctness pass 2

Callable argument inference now includes the specialized function type produced
by implicit .call coercion. Original argument evidence remains intact; only a
nominal-to-nongeneric-function conversion contributes additional constraints.
The source-call and function-value binders use the same rule. The conversion
context replaces only unresolved invocation-owned parameters with holes, keeping
resolved dynamic/Object and enclosing parameters meaningful.

Contextual generic callable inference keeps lower and upper constraints separate.
Inputs choose their least upper bound, outputs constrain the result from above,
and declared bounds are checked after substitution. This prevents a permissive
Object return context from overwriting an input's String constraint. Nullable,
dependent, recursive, repeated and nested callable controls agree with native
Dart. Null-only and dependent upper-only cases retain the previous inference
path; this pass does not introduce a recursive-bound solver.

Known and virtual method reads reuse existing tear-off specialization machinery,
and already-specialized tear-offs avoid a second instantiation. Receiver
evaluation order and authoritative overriding dispatch are preserved. A generic
callable under a FutureOr context is rejected consistently with native Dart;
an initially proposed positive control was invalid and is retained as negative
evidence instead. No runtime, opcode, adapter implementation or stdlib changes
are made.

Integer tokens directly under unary minus now validate the signed raw token
when its cached value is absent or wrapped. This admits decimal int minimum,
including separators, and rejects directly negated out-of-range hex tokens.
Parentheses retain ordinary unsigned-hex wrapping. The existing unary Negate
operation and contextual double path are unchanged, and scalar defaults share
the correction through the common literal parser.

Native witnesses pass, and native CFE rejects all six integer range controls,
the invalid numeric callable bound and generic FutureOr coercion. The native
callable type arguments are String for the nullable/F-bound/nested controls,
int for the numeric bound, num/int for dependent bounds, and num for repeated
inputs and the bounded producer. Scoped analysis is clean and 112 focused tests
pass before adding the separately verified FutureOr negative regression.
The exact inference/issue_56666_test.dart and number/separators_test.dart both
pass fresh and serialized. Evidence is retained in cycle8-pass2.

The ordinary suite passes 2088 tests with 86 skips. SDK-full reports 2418 passes,
217 compile errors, 102 runtime failures and three reported skips. Its only
expectation mismatches are the two verified fixtures above, whose stale
expect_fail entries are removed. Genuine supported failures decrease from 321
to 319; language-floor skips remain separate.
The actual filtered SDK-full harness passes both fixtures after the exclusions
are removed, with exit 0 and two passes.

## Cycle 8 correctness pass 3

The compiler now admits bodyless nongeneric extension types with an unnamed
primary constructor and a Null or Object? representation. Their source types
remain nominal. Construction and representation-field projection retain the
same SSA value and its representation facts, with no guest class allocation.
Representation fields are read-only, and private projection uses the defining
library. Unsupported members, implements clauses, generics and scalar
representations remain explicit compilation errors for later passes.

Runtime descriptor IDs erase outer extension types to their representation,
including nullable and nested descriptor components. No extension class row is
registered. Declaration annotations resolve outside caller type-parameter
scopes, so a caller parameter named Object cannot alter the representation.

A separate representation-nullability predicate preserves source nullability
while correcting null equality, postfix assertions, null-aware selectors and
cascades, casts, type-test folding and pattern null checks. Native witnesses
confirm that E(Null) and Ref(Object?) can hold null despite a nonnullable source
annotation. Identity, nested collection/record/function descriptors, casts,
call boundaries and null operations pass fresh and serialized with both Dart
3.8 and 3.9 flow rules. All eight invalid source controls reject both natively
and in Eval. An initial nullable type-literal expression was invalid native
syntax and was replaced with the valid List<Ref>/List<Object?> comparison.

Public Symbol literals now use the existing const interning operation after
their existing generated bridge construction. Private-symbol behavior and
nonconst Symbol construction are unchanged. Native evidence confirms public
literal/const identity and nonconst equality/hash without canonical nonconst
identity. No generated binding, runtime or opcode changes are made.

Scoped analysis is clean. The expanded compatibility focus passes 128 tests;
the final core group adds the second language-version control and passes all
11 tests. Original SDK regress_53610, literal_runtime_1 and triple-shift fixtures
pass fresh and serialized. The ordinary run reports 2098 passes, 86 skips and
one stale triple-shift expectation mismatch. Its actual filtered core harness
passes after removing that exclusion, giving 2099 passing ordinary cases.
The actual filtered SDK-full harness passes all three verified fixtures after
their stale exclusions are removed. Final SDK-full exits 0 with 2421 passes,
216 compile errors, 100 runtime failures and three reported skips, with no
expectation mismatches. Genuine supported failures decrease from 319 to 316;
language-floor skips remain separate. Evidence is retained in cycle8-pass3.

## Cycle 8 correctness pass 4

Bodyless nongeneric extension types now admit scalar, nominal, record and union
representations. Source typing remains nominal: an int representation does not
make its extension type assignable to Object or expose int operators. The
compiler erases the representation when selecting parameter/result register
banks, export metadata and runtime descriptors. Construction, projection and
constructor tear-offs keep the underlying value without allocating a guest
class. Tear-offs reuse the captureless closure cache and ordinary function ABI.
Generic-bound projection follows the effective bound, and nullable extension
annotations still reject unguarded representation-field access.

Runtime nullability follows erased extension representations, FutureOr arguments
and effective type-parameter bounds. Ordinary types do not allocate a visited
set; recursive bounds are guarded only when traversed. Native witnesses confirm
nullable union and generic-bound equality, assertions, selectors, coalescing and
coalescing assignment. This predicate also determines reachable null branches,
while source type joins continue to use nominal subtype rules.

Arithmetic +, -, * and % infer their right operand from the uncontextualized
left operand and the result context. A shared result rule handles int/double/num
bounds and Never operands. Proven generic numeric operands use a detached
primitive view for intrinsic selection; source bindings keep their nominal
types. Compound assignment snapshots the left read before evaluating the right
operand, checks storage against the lvalue and preserves the operator's result
type on the expression.

Native Dart rejects int += dynamic and a custom Object-returning operator
assigned back into its narrower class. The old blanket dynamic-result relabel
admitted both invalid cases, and is removed. Its invalid positive regression is
replaced with compiler-negative evidence. Valid double/num and custom-class
results retain their static types, and genuinely dynamic operator results retain
dynamic expression typing after checked storage. Covariant collection writes
still reject an incompatible result before modifying storage.

No runtime, opcode, generated binding or stdlib changes are made. Native scalar
and constructor tear-off witnesses pass, invalid nominal accesses are rejected,
and focused scalar controls pass fresh and serialized.

The first full ordinary run exposed two earlier inference defects hidden by
permissive arithmetic typing. Untyped foreach variables supplied a concrete
dynamic element context, turning an integer literal into List<dynamic>; they now
supply a schema hole while retaining the outer Iterable/Stream context. Explicit
declared loop types keep their checked conversions. Coalescing assignment now
records the surviving lvalue's non-null promotion on its branch before joining
it with the write branch. Nullable RHS and captured-write controls prevent
overpromotion. These corrections preserve valid integer accumulation, HLC drift
calculations and source_span offsets without weakening assignment checks.

The negative controls also expose an older implicit nullable downcast in
assignment conversion. Dart rejects int? assigned or returned as int; the
compiler no longer substitutes a runtime assertion for that error. Dynamic
downcasts retain their existing checks, and nullable sources do not qualify for
literal int-to-double widening. Nullable receiver operators resolve applicable
nullable extensions before rejecting ordinary dispatch; equality and nullable
Object members keep their existing rules. These are compiler checks, with no
additional bytecode on valid ordinary paths.

Known bridge operators validate positional argument types against their
substituted formals, matching the existing source-operator checks. This exposes
nullable String interpolation being lowered directly as String concatenation.
Only nonnullable Strings bypass toString now; nullable values use the existing
conversion path. A changing getter control verifies that a preceding null check
does not alter the later observed value or duplicate getter evaluation.

The stricter checks exposed invalid positive fixtures that returned nullable
map lookups or RegExp matches as nonnullable values, used nullable lookups in
arithmetic, or cast an Object-valued factory field only after addition. Their
sources now assert the known present values or cast the field before adding.
The tested bridge, collection and redirect behavior is preserved. Native
witnesses distinguish these source corrections from compiler regressions.

Null-aware index writes also exposed a lost narrowing view: boxing consulted
the original binding and restored its nullable type inside the guard. The
guard now passes a detached view of the same SSA value, preserving its
representation and facts without emitting another operation.

Native index-write, map-return and redirect-default witnesses pass; the old
nullable map-return controls are rejected by the native compiler. Scoped
analysis is clean and formatting changes no Dart files. The final affected
focus passes all 123 cases. The final ordinary suite exits 0 with 2124 passes,
86 skips and no failures. The first SDK-full sweep exposed three inference
regressions and four more stale exclusions. An uninformative await context now
uses a schema hole rather than an artificial type parameter, so Future.value
can infer int before arithmetic or yielding. Contextual bridge constructor
arguments containing a schema hole must likewise complete argument inference
before reaching runtime metadata. Focused static-type controls cover both paths.

The four additional fixtures cover extension representation field promotion,
extension pattern exhaustiveness, nullable interpolation through a mixin, and
cyclic classes containing extension types. Their original sources pass native
Dart with assertions and both fresh and serialized Eval execution. All four
stale exclusions are removed, bringing this pass to seven removed entries.
After the inference corrections, scoped analysis is clean, the final affected
focus passes 98 cases, and the additional async, generator, shorthand,
constructor, await and foreach controls pass 44 cases. All three SDK regressions
pass fresh and serialized. The final SDK-full rerun exits 0 with 2428 passes,
211 compile errors, 98 runtime failures and three reported skips, with no
expectation mismatches. Genuine supported SDK failures decrease from 316 to
309. The 2124-pass ordinary run precedes the final await/constructor corrections;
the 98- and 44-case focused runs and final full SDK sweep validate those
corrections. Evidence is retained under cycle8-pass4. No validation process
remains running.

The user paused after this checkpoint. The read-only performance survey
identified boxed integer index dispatch as a candidate and recorded its plan
under `.dart_tool/improvement_loop/cycle8-int-index-plan.md`.

## Cycle 8 runtime performance pass

Dynamic indexed reads now keep a compiler-proven integer index in the integer
register. The private `InvokeDynamic` marker selects a generated `callIndexInt`
opcode only when its single index argument comes from `BoxInt` through SSA
copies. Native and mapped lists read with that integer. Maps, guest operators,
and other wrappers box the index on the cold branch and use the existing member
dispatch. Dead-use cleanup removes the original box when nothing else needs it.
The bytecode version is 135; the new opcode sits after existing regular opcodes
to preserve their IDs.

The paired AOT pilot used eight ABBA/BAAB runs with 15 samples per run and
matched every checksum. Native indexed aggregation improved 9.4% at 16 columns
and 12.4% at 1024 columns. Mixed receivers improved 5.8% and 6.6%; guest-only
receivers improved 3.4% and 3.9%. The longer width exercises indexes beyond
the small boxed-integer cache. Existing virtual-call and inventory-pricing
controls moved less than 2% in that pilot.

The final 23-driver AOT sweep compared executables from baseline `e5730760`
and the candidate with identical benchmark sources. All 22 execution checksums
matched. Short runs contained large outliers in unrelated call, closure,
dispatch and exception cases. Longer reversed-order repeats reduced the
overflow-call difference to 1.9%, global access to 1.2%, handled throws to
0.4%, and closure direct/overflow cases to at most 2.2%. The longer double
object-reference dispatch control was 6.7% slower, while default-adapter
closures were 9.1% faster. Logs and executable hashes are under
`.dart_tool/improvement_loop/cycle8-int-index-performance/`, especially
`pilot-tail`, `full23-aot-tail`, `repeat-outliers-1`, and `repeat-tail-2`.

The async, dynamic-call, and JSON benchmarks had source types that the current
compiler correctly rejected. Their callback results now carry explicit integer
types or casts; both benchmark executables use the same corrected sources.
Focused index, mapped-list, guest override, bounds and codec checks pass fresh
and serialized. SDK-full still passes all harness expectations with 2428 actual
passes, 211 expected compile errors and 98 expected runtime failures. The
serial ordinary run has one failure: `http_native_test.dart` uses the HTTP
bridge directory whose three tracked files were already deleted in the working
tree. Full analysis reports only the existing path-dependency warning.

## Cycle 8 cleanup and review

Astra reviewed the integer-index lowering, generated handler, codec validation,
and benchmark inputs. Its one performance finding was that the new integer-index
handler still used virtual dispatch for native maps. The generator now reads
native-map keys directly with a boxed integer, matching the existing index
handler. The generated machine was regenerated from its source.

The cleanup candidate passed the final 23-driver AOT sweep, with matching
checksums for all 22 execution drivers. Its paired, 15-sample index pilot
improved native indexing by 7.4% at width 16 and 11.7% at width 1024. Mixed
receivers improved 6.5% and 7.3%; guest receivers improved 4.0% and 5.7%.
Virtual-call and inventory-pricing controls were within 1.2%. A short dynamic
row in the full sweep varied by 39%; an eight-run, 15-sample repeat put the
steady baseline and candidate medians at about 850 and 845 microseconds.
Evidence is under `.dart_tool/improvement_loop/cycle8-int-index-performance/`
in `full23-aot-cleanup` and `pilot-cleanup`.

The review also identified a likely extension-type projection bug in
`extensionRepresentationField`: retaining the extension receiver's binding can
restore its nominal type during boxing. That concern belongs in the next
correctness pass, with a targeted witness before changing the compiler.

## Cycle 9 correctness pass 1: extension representation fields

The review witness reproduced a compile error: reading `I.value` from an
extension-type parameter appeared to have type `int`, but boxing followed its
local binding and restored type `I` before a numeric operator checked its
argument. Representation field reads now use a detached view of the same SSA
value, retaining its representation and value facts. This emits no bytecode.
The witness passes fresh and serialized execution; the existing extension
representation identity tests and scoped analysis also pass.

## Cycle 9 correctness pass 2: contextual closures and empty globals

Unannotated closure parameters in a `Null` or `Never` downward context now
weaken to `Object?`, including bounded type parameters. Explicit annotations
and unresolved inference variables keep their existing behavior. A new test
covers positional, named, bounded and dynamic calls in fresh and serialized
execution; the pinned closure fixture passes, so its stale exclusion is gone.

Global type inference previously treated a bare empty `{}` as `Set`, while
literal compilation and Dart treat it as `Map`. The inference helper now
classifies empty untyped literals as maps. Mutable, const and forwarded globals
pass fresh and serialized regression tests; explicitly typed empty sets stay
sets. Both affected deferred SDK fixtures pass and their exclusions are gone.
These are compiler-only changes with no added runtime operations.

The first full SDK sweep exposed two more stale exclusions after the empty-map
fix: the constant-map fixture and a regression using a top-level empty map.
Both pass when selected individually. Their exclusions were removed as well,
for five removed entries in this pass.
The final SDK-full rerun passes with 2,433 actual passes, 207 expected compile
errors, 97 expected runtime failures, and three reported skips.

## Cycle 9 correctness pass 3: collection shape, enums, and global arguments

Collection literals that infer Set or Map from a spread now compile that spread
inside its original `if` or `for` guard. The compiler changes the allocation
operation already emitted before the guard when the spread establishes Map
shape; it emits no extra runtime operations. Both `if` branches contribute
shape evidence. Fresh and serialized tests cover skipped spreads, evaluation
order, repeated loop evaluation, and a map entry in the alternate branch.

Source enums now synthesize one const `values` list global in declaration
order. Qualified, typedef, and bare reads share its identity. Existing
collection operations and const interning supply the implementation, with no
runtime change. The new enum test covers generic bounds, enhanced enum
fields, list identity and immutability. The pinned duplicate enum fixture
passes, so its stale exclusion is removed. The broader enhanced enum fixture
still reaches a separate generic enum constant typing failure.

The setter fixtures exposed a top-level inference error: `<dynamic>[Child()]`
was recorded as `List<Child>`, because global type inference discarded explicit
collection type arguments. List, Set and Map global literals now preserve those
arguments. This lets dynamic field writes use their existing runtime type
checks without adding a new dispatch path. The two setter SDK fixtures pass;
their stale exclusions are removed. A fresh and serialized regression covers
all three collection kinds and the runtime field check.

The first full SDK sweep found four more newly passing fixtures: an enum
`values` equality regression and three tests with top-level `<dynamic>` lists.
All four pass in a focused rerun, and their stale exclusions are removed.
SDK-full then passes with 2,440 actual passes, 200 expected compile errors,
97 expected runtime failures, and three reported skips.
The ordinary language and runtime suites pass all 937 tests, and scoped
analysis is clean.

## Cycle 9 correctness pass 4: spread evidence and primitive interfaces

For all-spread literals, an emission-free prepass now finds statically known
Map spreads after an earlier dynamic spread. This selects Map before compiling
any spread, preserving guard and loop evaluation order. The prepass handles
local declared types, parentheses, casts, and explicit map literals; scoped
loop and pattern bindings retain the guarded fallback. Focused fresh and
serialized tests pass, including a bytecode-count comparison showing no extra
operations. The SDK collection groups retain their configured passing status.

The hand-maintained `num` bridge declaration now records the SDK's
`Comparable<num>` interface. This makes integer and double values assignable
to `Comparable` without a compiler special case or runtime change. The pinned
intersection fixture and a fresh/serialized primitive subtype regression pass;
its stale exclusion is removed.

Generic enum constants now retain explicit or inferred type arguments through
constructor binding, global type metadata and static reads. A generic enum
constant referenced before its declaration compiles its initializer once in a
saved compiler scope; ordinary enum compilation reuses that result. Redirecting
enum constructors also forward their synthetic index and name arguments.
Fresh, serialized and native witnesses cover forward references, bounds,
named and redirecting constructors, and constant references from another
initializer. The broader enhanced-enum SDK fixture advances past its generic
type errors but still fails at a separate callable-enum expression.
The full SDK suite passes with 2,442 actual passes, 199 expected compile
errors, 96 expected runtime failures, and three reported skips. The
`unsorted/core_type_check_test.dart` exclusion also became stale and was
removed.

## Cycle 9 correctness pass 5: callable enums and double division

Calls written directly on enum constants now resolve the constant and bind its
instance `call` method through the ordinary source-method path. Explicit and
inferred type arguments, named arguments, optional defaults, and typedef
access pass fresh and serialized tests. The broader enhanced-enum SDK fixture
still fails at its separate enum `super` representation: enum instances do not
have the superclass object chain expected by `LoadSuper`. A small attempt to
admit `super` in enum methods was reverted after a `Null.index` failure.

The hand-maintained `num` wrapper declared truncating division but did not
expose it on double values. Its direct bridge method now uses Dart's `~/`
operator. The focused global-initializer and expression regression passes in
fresh and serialized runtimes; the pinned compile-time-constant SDK fixture
passes and its stale exclusion is removed. SDK-full passes with 2,443 actual
passes, 199 expected compile errors, 95 expected runtime failures, and three
reported skips. The ordinary language and runtime suites pass all 943 tests,
and scoped analysis is clean. Because the `num` bridge has a runtime change,
the full 23-driver AOT sweep compared the current candidate against the saved
cycle 8 cleanup executable before commit. All 22 execution checksums matched;
the compiler driver completed separately. Results are under
`.dart_tool/improvement_loop/cycle9-pass5/full23-aot/`.

## Cycle 9 runtime performance pass

The typed instance member cache was allocating two maps for each newly
constructed receiver even when that receiver used only a few methods. A
32-handler record-processing benchmark exposed that cost. Typed instances now
retain the first two resolved members in inline slots and allocate the member
maps only when a third distinct member is used. The slots preserve member
identity, including base views of derived objects, and are copied into the map
at promotion. Bytecode, calling conventions, boxing and the interpreter loop
are unchanged.

Several alternatives were measured and reverted: lazily creating the original
map, inlining `TypedDispatch.resolve`, and a weak call-site cache. Each lost
throughput or gave no stable benefit on the rotating-handler benchmark. Removing
member caching entirely improved that benchmark but slowed repeated-receiver
dynamic calls by roughly 25–30%, so the two-slot design keeps both patterns
fast.

The paired 15-sample AOT pilot used ABBA/BAAB ordering and matched all
checksums. The median of four process medians moved from about 20.3 to 17.4 ms
for one handler (-14.1%) and 24.8 to 22.2 ms for 32 handlers (-10.8%) over
30,000 records. Repeated-receiver dynamic calls also improved in that pilot;
the stable-receiver row fell about 12.6% and alternating receivers about 8.2%.
Evidence is under `.dart_tool/improvement_loop/cycle9-performance/`.
The final ordinary language and runtime suites pass all 943 tests, including
the base-view member-identity regression. SDK-full retains 2,443 actual passes,
199 expected compile errors, 95 expected runtime failures, and three reported
skips. Scoped analysis is clean. The final 23-driver AOT sweep on the exact
candidate matches all 22 execution checksums. Its short overflow-call and
protected-no-throw rows varied; longer, 15-sample ABBA/BAAB repeats put the
overflow call near 21–22 ms on both sides and handled throws near 114 ms.
Polymorphic calls improved from roughly 14.2 to 12.9 ms in that repeat.

## Cycle 9 cleanup and review

Astra reviewed the cycle's compiler, bridge and runtime changes. Its actionable
finding was that all-spread Map inference still missed later statically typed
top-level calls, getters and globals after an initial dynamic spread. The
prepass now reuses the compiler's conservative expression-type inference for
those forms, without evaluating an expression or emitting bytecode. A focused
fresh/serialized regression also checks that a local function shadowing a
top-level Map producer does not supply false Map evidence.

The two-slot typed member cache retains its inline fields, which avoid new
allocations in the measured short-lived object pattern. Six redundant slot
clears after promotion to the map were removed, and the uncached lookup comment
now describes both its early and promoted-map uses.
The focused spread and instance-dispatch tests pass, scoped analysis is clean,
and SDK-full retains 2,443 actual passes with its expected-failure counts.
The final 23-driver AOT sweep compares the cleanup executable against the
performance checkpoint; all 22 execution checksums match. Evidence is under
`.dart_tool/improvement_loop/cycle9-cleanup/`.

## Cycle 10 correctness pass 1: bridged function identity

The pinned compile-time-constant fixture exposed repeated tear-offs of the
same bridged function producing distinct forwarding function bodies. Runtime
constant interning uses that body identity, so an alias of `identical` did not
match a later tear-off of `identical`. The compiler now shares one forwarding
body per bridged function index. This removes duplicate generated functions
without adding runtime work or bytecode. The focused SDK fixture and ordinary
tear-off tests pass; its stale `expect_fail` entry was removed.

## Cycle 10 correctness pass 2: interleaved record field types

Record literals retain field values in source order, including interleaved
named fields, while the runtime type builder assumed positional values came
first. It now uses the record layout mapping to locate each positional value.
Fresh and serialized regressions cover different field types, reordered
labels, null and nested records. The pinned SDK runtime-type fixture passes,
and its stale `expect_fail` entry was removed. The 23-driver AOT sweep against
the cycle 9 cleanup host matched all 22 execution checksums before commit;
evidence is under `.dart_tool/improvement_loop/cycle10-pass2/`.

## Cycle 10 correctness pass 3: abstract operator forwarding

An abstract operator declared by a concrete source class with a source
`noSuchMethod` had no compiled entry, so dynamic calls reached the handler
without checking the operator's argument and return types. The compiler now
emits a checked forwarder only when the class has no inherited concrete
operator implementation. A focused fresh/serialized regression verifies
argument rejection before handler side effects, return checking, invocation
shape, and inherited concrete behavior. Object's concrete equality operator
also stays inherited when a class declares abstract `==`. The pinned
unsigned-shift fixture passes and its stale `expect_fail` entry was removed.
SDK-full found no execution regression after the equality refinement; its
four expected-failure mismatches are newly passing late-field cases from the
parallel pass, whose entries are removed with that checkpoint.

## Cycle 10 correctness pass 4: lazy instance field initializers

Late instance initializers were evaluated during construction, before `this`
was bound, and could neither defer work nor retry after a throw. Constructors
now leave late slots uninitialized. A generated getter evaluates its initializer
on the first read and stores only a successful result. One appended typed opcode
tests the existing late-field sentinel; existing opcode numbers and ordinary
field access stay unchanged. The machine sources were regenerated from their
generator. Focused fresh/serialized tests cover `this`, inheritance, mixins,
single evaluation, assignment before read, retry after throw and cached null.
The SDK-full run found four stale expected-failure entries for related late
field fixtures, all removed. With those entries removed, SDK-full passes with
2,450 actual passes, 194 expected compile errors, 93 expected runtime failures,
and three skips. The final 23-driver AOT sweep against the cycle 10 pass 2
host matched all 22 execution checksums before commit; evidence is under
`.dart_tool/improvement_loop/cycle10-pass4/`.

## Cycle 10 correctness pass 5: generic Map factories

The hand-maintained `Map` bridge constructed wrappers without the runtime's
resolved constructor type id. Thus `Map<T, T>()` inside `A<T>` appeared as
`Map<dynamic, dynamic>` even for `A<int>`, including an inherited initializer
in `B<int>`. All four factory wrappers now retain that id, following the
existing `Set` bridge pattern. A fresh/serialized regression covers unnamed,
`from`, `of`, and `fromEntries` factories through an inherited generic class.
The pinned initializer fixture passes and its stale `expect_fail` entry was
removed. SDK-full passes with 2,451 actual passes, 194 expected compile errors,
92 expected runtime failures, and three skips. The 23-driver AOT sweep against
the cycle 10 pass 4 host matched all 22 execution checksums; evidence is under
`.dart_tool/improvement_loop/cycle10-pass5/`.
The ordinary language and runtime suites pass all 950 tests, and scoped
analysis of the bridge and regression is clean.

## Cycle 10 runtime performance pass: string-key maps

The frame-entry inlining experiments were reverted. Moving all entry helpers
out of the dispatch caused a large default-adapter call regression. Outlining
only frame reuse showed about 1.4% slower primitive calls and 2.2% slower exact
closures in alternating 15-sample AOT runs, with little dispatch benefit.

String-key map literals can use the host map's ordinary key equality because
`$String` already compares and hashes by value. The compiler now selects a
one-byte `NewStringMap` opcode for non-nullable String keys; other maps retain
the guest equality/hash backing. The opcode was appended to the hot instruction
table without renumbering existing opcodes or adding per-access checks. Fresh
and serialized tests cover distinct equal String wrappers and guest object
keys. In alternating 15-sample AOT runs, `config_validation` improved from
about 91.70 to 88.07 ms (4.0%); `json_codec` was roughly flat at 273.26 versus
272.26 ms. The 23-driver AOT sweep matched all 22 execution checksums. Raw
measurements are under `.dart_tool/improvement_loop/cycle10-performance/`.
SDK-full finished with 2451 actual passes, 194 expected compile failures, 92
expected runtime failures, and three skips. The ordinary language and runtime
suites passed all 951 tests.

## Cycle 10 cleanup

An Astra medium review found that constructor field initialization still
carried an unused late-field option and a duplicate fallback compilation path.
Removed both, made the evaluated initializer map required, and kept the field
index advancing for every declaration. Extracted the late getter initializer
and abstract operator forwarding predicate from their nested body compilers.
These are compiler-only refactors; no runtime or generated opcode changed.
Focused tests and scoped analysis passed. SDK-full remained at 2451 actual
passes, 194 expected compile failures, 92 expected runtime failures, and three
skips; all 951 ordinary language and runtime tests passed.

## Cycle 11 pass 1: guest patterns in String.split

The String bridge cast every split pattern to `$String`, so a guest class
implementing `Pattern` threw a type error before its matches were read.
String patterns still use the host split path; guest patterns now invoke
`allMatches` and apply the SDK's checked substring loop. This also surfaces
the expected `RangeError` for a malformed match range. The exact SDK fixture
and a fresh/serialized regression passed, and the stale `string/split_test`
expect-fail entry was removed.

## Cycle 11 pass 2: recursive global initialization

The typed global state rejected every recursive initializer call. Dart permits
bounded reentry for mutable globals; the outer initializer writes its eventual
result. A final global instead rejects the outer write when an inner call has
already stored a value. The state helper now follows those rules, with no
change to the initialized-global load path. Native Dart witnesses, direct and
serialized global regressions, and `lazy/static3_test.dart` pass. SDK-full also
showed `lazy/static8_test.dart` passing; both stale expect-fail entries were
removed. The full 23-driver AOT sweep completed with all
22 execution checksums matching the previous candidate; measurements are in
`.dart_tool/improvement_loop/cycle11-pass2/full23-aot/`.

## Cycle 11 pass 3: typed bridge tear-offs and collection inference

The `set_literals/const_set_literal_test.dart` fixture first exposed that a
bridge method tear-off was typed as bare `Function`, losing the method's
signature. Preserving that signature exposed a second issue: a generic
callable argument received its erased bound as collection context, making a
set literal infer `Set<dynamic>` instead of `Set<int>`. Unbound type parameters
now remain inference holes in that context, and closure metadata closes those
holes after inference. Focused bridge tear-off and generic callback tests pass
in fresh and serialized runtimes. The SDK const-set fixture and its related
`unsorted/bottom_test.dart` regression pass. The stale expect-fail entry was
removed.

## Cycle 11 pass 4: assertion messages

The assertion bridge eagerly stringified guest message objects and lost their
identity. Assertion statements now use an internal bridge entry that preserves
guest messages and gives null-message assertion failures the expected text;
direct `AssertionError()` retains its constructor behavior. The exact SDK
fixture and a fresh/serialized regression pass, and its stale expect-fail
entry was removed. SDK-full passed with 2456 actual passes, 192 expected compile
failures, 89 expected runtime failures, and three skips. All 958 ordinary
language and runtime tests passed. The final 23-driver AOT sweep matched all
22 execution checksums; measurements are under
`.dart_tool/improvement_loop/cycle11-final/full23-aot/`.

## Cycle 11 pass 5: generic List constructors

Six hand-maintained List factory wrappers discarded the resolved constructor
type ID. Lists created through `List.empty`, `filled`, `from`, `of`, `generate`,
and `unmodifiable` now retain that ID and their owning runtime, matching the
Map and Set wrappers. The `list/is_test.dart` SDK fixture passes; a direct and
serialized regression covers explicit type arguments, generic receivers, and
wrong-type dynamic writes. SDK-full also found `generic/instanceof_test.dart`
newly passing, so both stale expect-fail entries were removed. The final
23-driver AOT candidate included this change and matched all 22 execution
checksums. SDK-full passed with 2458 actual passes, 192 expected compile
failures, 87 expected runtime failures, and three skips. All 959 ordinary
language and runtime tests passed.

## Cycle 11 runtime performance: alternating child frames

The first two experiments did not justify a change: string-specific
`StringBuffer.write` matched the generic path in alternating AOT runs, and
inlining global or dispatch helpers gave noisy or slower results. They were
reverted.

Calls alternating between two callees made a parent frame retarget its one
cached child on every call. A second inactive child slot now lets the parent
reuse each callee's frame and its spill arrays; suspended children still
detach before reuse. The existing frame-reuse test covers alternating storage,
clearing, recursion, exceptions, and suspension. In paired 15-sample AOT runs,
`json_codec` improved from 267.48/267.74 ms to 258.76/256.15 ms (about 4%).
`event_bus` improved from 73.35/73.68 ms to 72.20/70.59 ms in the same
alternating process order. The full 23-driver sweep matched all 22 execution
checksums. Raw measurements are under
`.dart_tool/improvement_loop/cycle11-performance/`.
SDK-full remained at 2458 actual passes, 192 expected compile failures, 87
expected runtime failures, and three skips. All 959 ordinary language and
runtime tests passed.

## Cycle 11 cleanup review

The Astra review identified three small duplications. Invocation binding now
builds the generic context-hole substitution once and shares its application
between argument compilation and coercion. Method tear-offs share signature
setup for declared and bridge methods. The guest-pattern split loop appends
its trailing substring in one place. None changes runtime dispatch.

The review also found that the five nonempty List constructors could stamp a
type onto elements that bypassed their erased host-list checks. They now
validate elements as each constructor consumes them. A native Dart witness
confirmed that formatting an assertion error does not invoke the message
object's `toString`; the assertion regression now checks that behavior too.
SDK-full remained at 2458 actual passes, 192 expected compile failures, 87
expected runtime failures, and three skips. All 961 ordinary language and
runtime tests passed. The final 23-driver AOT sweep matched all 22 execution
checksums; measurements are under
`.dart_tool/improvement_loop/cycle11-cleanup/full23-aot/`.

## Cycle 12 pass 1: raw Map literal context

A raw `Map` declaration supplies `dynamic` for both type arguments of a map
literal. The compiler had treated that context as absent and inferred the
literal's key and value types from its entries. It now uses the raw context,
while `var` inference and an explicit `Map<String, int>` context remain
precise. A native Dart witness, the exact `map/literal7_test.dart` fixture,
and a fresh/serialized regression pass. The stale expect-fail entry was
removed. This compiler-only change adds no runtime checks or bytecode.

## Cycle 12 pass 2: forwarding method tear-offs

An inherited method body can have a wider bound tear-off signature when its
receiver implements a covariant interface. One closure descriptor was shared
by the base and implementing classes, so the latter kept the base signature.
The backend now emits sparse receiver-specific signature IDs where they
differ. A bound `TypedMember` selects the receiver's ID; lexical `super`
tear-offs keep their declaring signature. The new metadata is encoded in
typed programs (codec version 136). Ordinary method dispatch and the
interpreter loop are unchanged.

Both forwarding-stub SDK fixtures and two related `regress31596` fixtures now
pass, so all four stale expect-fail entries were removed. Fresh/serialized
regressions cover generic and explicit interfaces, named arguments, sibling
classes, allocation order, and `super` tear-offs. SDK-full passed with 2463
actual passes, 192 expected compile failures, 82 expected runtime failures,
and three skips. All 966 ordinary language/runtime and new closure tests
passed. The final 23-driver AOT sweep matched all 22 execution checksums;
measurements are under `.dart_tool/improvement_loop/cycle12-pass2/full23-aot/`.

## Cycle 12 pass 3: dynamic spread sources

Spreading a dynamic non-collection tried to read `iterator` or `entries`,
raising `NoSuchMethodError` where Dart requires a type error. A dynamic spread
source now receives one collection-shape check inside the existing null-aware
guard, before iteration. Static sources keep their existing path, and element
checks still validate entries. The exact `spread_collections/runtime_error`
SDK fixture and a fresh/serialized regression pass. Its expect-fail entry was
removed.
SDK-full passed with 2466 actual passes, 191 expected compile failures, 80
expected runtime failures, and three skips after the three cycle 12 fixes.
All 970 ordinary language/runtime and closure tests passed. The combined
23-driver AOT sweep matched all 22 execution checksums against pass 2;
measurements are under `.dart_tool/improvement_loop/cycle12-pass3-5/full23-aot/`.

## Cycle 12 pass 4: bridged Error stack traces

Guest throws wrap a bridged host `Error`, so the VM records a trace on the
wrapper and leaves the original error's `stackTrace` null. Exception transfer
now initializes the original error's first trace before guest catch or async
delivery, preserving object identity and any previously recorded trace. The
exact `stack_trace/error_runtime_test.dart` fixture and fresh/serialized
regressions pass. Its stale expect-fail entry was removed. This change is on
the exception path; the interpreter loop is unchanged. The combined SDK,
ordinary, and AOT results above include this fix.

## Cycle 12 pass 5: subclassable Invocation binding

The SDK's `Invocation` has factory constructors and can be subclassed, but
its generated wrapper exposed only the factory side. The binding is now a
hand-maintained exception that keeps the SDK-derived declaration and
factory wrappers together with a subclassable bridge. The bindgen config
routes `Invocation` to that file, so stdlib regeneration preserves it.
The exact `no_such_method/no_such_method2_test.dart` fixture, a native witness,
and fresh/serialized guest and host getter regressions pass. Its stale
expect-fail entry was removed. No runtime dispatch code changed. The combined
SDK, ordinary, and AOT results above include this fix.

## Cycle 12 performance: frame object cleanup

Call-heavy benchmarks pointed to object register and spill cleanup at function
return. `TypedFrame.leave()` now clears its three object storage lists with a
small indexed loop instead of three `fillRange` calls. The frame still clears
every retained object reference before caching; no bytecode or interpreter
dispatch changes are needed.

The 23-driver, 15-sample full AOT sweep against the pass-5 baseline matched
all 22 execution checksums. In that run, `event_bus` fell from 71.106 to
67.211 ms, `json_codec` from 261.392 to 238.703 ms, and `callbacks` from
2.586 to 2.327 ms. A reverse-order paired rerun confirmed the call-path
effect: method calls fell from 8.388/8.404 to 7.656/7.564 ms, boxed arguments
from 13.476/13.588 to 12.282/12.252 ms, and event bus from 75.022/71.628
to 67.667/67.108 ms. The primitive call path was flat. The complete sweep
and per-driver logs are under
`.dart_tool/improvement_loop/cycle12-performance/frame-clear-loop/full23-aot/`.
SDK-full then passed with 2466 actual passes, 191 expected compile failures,
80 expected runtime failures, and three skips. All 970 ordinary language,
runtime, and forwarding tear-off tests passed.

## Cycle 12 cleanup

The Astra medium review found one duplicate comment in the hand-maintained
`Invocation` binding; it is removed. The review found no other actionable
style, correctness, or performance issues in the cycle 12 changes.
