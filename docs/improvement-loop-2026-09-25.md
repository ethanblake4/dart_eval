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
