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
