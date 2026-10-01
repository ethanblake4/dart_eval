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
