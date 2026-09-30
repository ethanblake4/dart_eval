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
