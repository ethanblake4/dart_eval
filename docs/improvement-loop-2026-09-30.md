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
