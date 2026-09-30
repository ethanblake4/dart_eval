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
