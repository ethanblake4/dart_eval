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

This checkpoint contains only the independent compiler promotion and FutureOr
fixes. Their new witnesses pass with native Dart and both evaluated loading
modes. The full working tree passes 1937 ordinary tests with 62 skips. SDK-full
has 2315 actual passes, 251 compile errors and 134 expected failures, with 362
skips and no unexpected outcomes. Full analysis retains the two existing
diagnostics. The compiler subset passes all 1930 ordinary tests with 62 skips against
the previous bindings in an isolated checkout. Its focused analysis is clean.
Five stale SDK expectations are removed after fresh and serialized checks.

Generated collection bindings, the hand-maintained Map lookup correction and
coupled ordinary indexing changes remain uncommitted. The user deferred
performance experiments and benchmark sweeps until an explicit resume, so
their required AOT validation is pending. Correctness work continues.

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
