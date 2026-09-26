# Improvement loop, September 25, 2026

Environment: Windows x64, Dart 3.13.4, CPython 3.12.9. Starting revisions:
dart_eval `2fbafdd` on `xv2`, control_flow_graph `f0acd09` on `main`.
The local path dependency is intentional.

## Step 1: collection loop captures

The fresh SDK core baseline has 409 actual passes, 49 runtime failures and
30 compile errors. All failures are expected by the status file. The old
untracked SDK log predates the Windows path normalization and is not a baseline.
A focused collection survey has 22 passes and 13 failures across 35 runnable tests.

`control_flow_collections/for_variable_test.dart` fails because classic collection
loops reuse one captured variable cell across iterations. Statement loops already
renew the cell before the updater. Both now use `compileForLoop`, which also
shares the assigned-local scan that discards invalid allocation proofs on back
edges. Collection for-in loops now supply that scan as well.

No runtime or generated standard-library changes. Uncaptured loop variables do
not allocate cells. Regressions exercise list/map/set captures and captures in
conditions and updaters with fresh and serialized programs. The original SDK
test passes and its expected-failure entry is removed. Focused loop, collection,
closure and statement-graph tests pass; analysis of changed files is clean.

Full default suite: 1,585 passed, 62 skipped; targeted SDK case: one passed.

## Step 2: HTTP header scanning

`benchmark/http_headers.dart` and `.py` generate 32 headers per request, fold
ASCII names, hash values and extract content lengths. Inputs, integer masks,
warmups and accumulated checksums match. Guest compilation is outside timing.

The scanner read the same string/index in its loop condition and body.
control_flow_graph now offers deterministic expression reuse using dominance
and caller-supplied keys. dart_eval applies it to immutable string reads and
string unboxing, excluding functions with exceptional CFG edges. It retains
the first potentially throwing read, excludes mutable reads and allocations,
and preserves operand positions by emitting Assign nodes for duplicates.

An initial experiment applied source copy propagation too broadly. Existing
operand-order and loop tests caught it. The final pass resolves copies only
when building expression keys; the typed backend still handles operand copies.

Pinned CPU affinity 4, alternating runs, 3,000 requests and 15 samples:

| Run | Baseline AOT ms | Candidate AOT ms | CPython ms |
| --- | ---: | ---: | ---: |
| 1 | 332.325 | 220.486 | 344.430 |
| 2 | 240.317 | 222.509 | 348.477 |

The first baseline was noisy. The second comparison is a 7.4% improvement and
1.57x faster than CPython. All checksums are `48278969359664`. The focused
bytecode regression also confirms one code-unit read instead of two.

Validation: 1,588 default tests passed, 62 skipped; 99 control_flow_graph tests
passed. Changed-file analysis and control_flow_graph analysis are clean.
No runtime or standard-library changes; no opcode or serialization changes.

## Step 3a: declaration order and inherited getter types

`class/override_inference_test.dart` exposed incorrect direct-call resolution.
While compiling a recursive override, the override had no compiled position yet.
The lookup skipped it and selected the already-compiled superclass body, whose
parameter type could be narrower. Implementation lookup now uses declarations;
the existing deferred call offsets resolve after compilation. Forward calls and
recursive calls both retain the correct override.

The same SDK test then exposed getter reads discarding inherited return types
when the getter had no explicit annotation. ResolvedMember now uses the inferred
signature. The SDK test passes. Regressions cover recursive and forward calls,
conflicting inherited signatures, and getter-to-list inference in fresh and
serialized programs. All 33 inheritance tests pass and changed-file analysis is
clean. The full default run's only failure was a new test using a bare
TypedMachine for host numeric dispatch; that test now uses Runtime and passes.
No runtime changes or extra dynamic paths were added.

## Step 3b: rolling telemetry windows

`benchmark/telemetry_window.dart` and `.py` maintain sixteen-sample windows for
64 devices, flag spikes against each device's recent sum, and checksum the final
state. Both ports use the same arrays, event stream, arithmetic and updates.

Bytecode inspection found five virtual List writes in the event loop. The
compiler now uses existing direct List write instructions when allocation facts
prove the actual List element type. A widened static view does not justify an
unchecked write. Unknown receivers and unproven argument types retain dispatch.
The common-expression pass also reuses scalar unboxing of the same immutable
wrapper, retaining the first potentially throwing conversion.

Pinned CPU affinity 4, 500,000 events and 15 samples:

| Version | Median ms | Minimum ms | Maximum ms |
| --- | ---: | ---: | ---: |
| Baseline | 369.597 | 296.143 | 741.654 |
| Direct writes | 198.599 | 193.474 | 221.605 |
| Direct writes and scalar reuse | 194.933 | 190.810 | 223.492 |
| CPython | 205.460 | 201.416 | 220.712 |
| Candidate repeat | 194.456 | 190.163 | 246.239 |

All checksums are `60067362`. The final median is 47% below the baseline and
5.4% below CPython. Baseline noise exaggerates the headline reduction; a separate
300,000-event run measured 223.527 ms baseline, 120.527 ms direct writes and
121.375 ms CPython. The bytecode has no virtual List writes after the change.

Validation: 1,593 default tests passed, 62 skipped. Regressions cover direct
constructor writes, widened reified-list aliases, fixed-length errors and bounds
errors. The generated runtime check passes. No runtime, opcode, serialization or
generated standard-library files changed.

Remaining limitation found during validation: `List<int>.filled` does not retain
its reified element type for later dynamic/covariant writes. A widened constructor
test failed identically with the new optimization disabled. The optimization
leaves those unproven writes on the existing checked-dispatch path; it does not
repair the constructor metadata. Reified list literals do enforce the constraint
and are covered by the regression suite.
