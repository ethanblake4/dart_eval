# Register and branch checkpoint

Production now uses no X, the full numeric fused-branch family, and direct
short-circuit lowering for conditions. The generator emits 231 instructions,
leaving 25 one-byte opcode slots. Strings and collections keep using the object
bank; this change does not reserve those slots for a particular future intrinsic.

## Compiler and ABI

- The first boolean argument uses E. Further booleans share R/S/C with excess
  numeric and object arguments, then use the existing single overflow list.
- All six int and double comparisons can fuse with a single-use conditional
  branch. Short signed16 and wide absolute32 targets are supported.
- Negation swaps branch destinations. It does not invert floating predicates,
  which would change unordered NaN results.
- Condition-only `&&`, `||`, and `!` produce direct control-flow edges in if,
  while, for, do, ternary, and collection conditions. Leaf checks still validate
  dynamic booleans; RHS effects only execute when required. Local boxing state
  is reconciled at each edge. Materialized logical expressions retain their
  existing value semantics.
- Conditions containing type tests use the existing lowering until promotion
  can track individual condition edges.

Envelope version 104 and typed payload version 116 reject earlier bytecode.
Recompile saved programs. Register ID 5 is retired; R/S/C keep their allocator
IDs, but no live register or instruction refers to X.

## Validation

The full suite passes 865 tests. Focused coverage includes all numeric predicates,
NaN, wide branch targets, reused boolean results, boolean overflow calls,
side-effect order, exceptions/finally, assignments in loop conditions,
collections, dynamic checks, and existing promotion. Analyzer output contains
only the intentional local path-dependency warning. Generated-file verification
passes. CFG remains at `9e96620` without changes.

## Timings

Dart 3.10.7, Windows x64 AOT, sequential runs pinned to logical CPU 2 with
AboveNormal priority. Each executable gets a separate complete warmup process.
Audit sweeps 10/11 use 21 samples and different case rotations. Variant order is
reference / no-X fused / production, then reversed. Affinity sweeps use 15 samples
and the opposite order. Native checksums validate every measured sample.
No builds or tests ran concurrently with measurements. Flutter was not rerun.

The reference is `7ee5a3e`. The intermediate variant already removes X and fuses
numeric branches, but lacks the new condition lowering. Its measured audit and
affinity bytecode matches the earlier optional-not experiment.

The first audit sweep drifted substantially: for example reference tree traversal
was 160.585 ms, versus 116.934 ms in the repeat. Both raw sweeps are retained.
The following table gives the reverse-order repeat, in milliseconds; differences
of a few percent should not be interpreted as reliable improvements.

| Workload | Reference | No X + fusion | Production |
| --- | ---: | ---: | ---: |
| Integer sum | 47.172 | 42.351 | 43.268 |
| Double recurrence | 31.118 | 28.587 | 29.173 |
| Integer mixing | 39.288 | 36.884 | 37.910 |
| Particles | 42.311 | 40.227 | 41.850 |
| Checkout | 41.137 | 40.396 | 40.553 |
| Events | 7.296 | 7.762 | 7.461 |
| Word count | 36.446 | 37.227 | 34.964 |
| Recursive tree | 116.934 | 122.429 | 121.092 |

Math remains faster than reference. Broad object results are mixed: the repeat
puts events and recursive traversal slightly behind reference. These timings
do not establish a universal gain from removing X. Use the earlier paired
[experiment results](register-affinity-experiments-2026-09-16.md) alongside this
production check rather than pooling measurements from different sessions.

The targeted workload medians below retain both sweeps, separated by `/`:

| Workload | Reference | No X + fusion | Production |
| --- | ---: | ---: | ---: |
| Fields | 128.639 / 129.304 | 125.336 / 130.719 | 126.264 / 126.334 |
| Maps | 48.320 / 51.780 | 46.923 / 55.520 | 46.433 / 48.046 |
| Boolean calls | 98.642 / 104.466 | 101.519 / 108.620 | 102.666 / 100.808 |
| Comparisons | 79.768 / 84.902 | 75.087 / 76.230 | 68.706 / 68.382 |

Separate instrumented runs at 257 iterations show the comparisons workload
falling from 44,604 dispatches in reference to 44,346 with no X plus fusion,
then 37,465 with condition lowering. That is 15.5% fewer dispatches than the
intermediate version, consistent with the roughly 9–10% lower medians here.
The other three targeted workloads and all eight audit workloads execute the
same number of instructions as the intermediate version. Their timing differences
do not demonstrate savings from the new condition lowering. Boolean calls still
execute more instructions than reference, 51,696 versus 49,426, because values
that previously fit in X now need the object bank and explicit transfers.

## ARM64

Cross-compilation reproduces the chosen experiment's 27,524-byte dispatch symbol.
The loop header has 30 sampled instructions and ten stack stores. Including the
shared dispatch path, sampled integer add is 38 instructions and fused integer
`<` with a short branch is 78. The reference add was 41, and separate comparison
and branch paths totalled 121. These static counts follow default fallthroughs
and exclude helper bodies. They are not measurements on ARM hardware.

## Same-bank moves and swaps

The absence of swaps comes from the constrained allocator, not the runtime.
`allocateRegisters` chooses that allocator for typed operations. Only the
bypassed general allocator constructs `SwapOp`; the constrained path never does.

A source probe calling `callee(b, a)` emits `aSpill`, `aFromB`, `bReload`.
The double equivalent emits `fSpill`, `fFromG`, `gReload`. Same-bank copies are
therefore in use. Ordinary arithmetic often needs none because opcode variants
accept the resident operand order and SSA assignments coalesce. Most join
boundaries spill live values, so their permutations also go through memory.

The next allocator optimization is to place an instruction's operands together
and resolve resident permutation cycles with swaps. Costing should count a
two-register cycle as one swap, while preserving aliases, liveness, and saved
spill state. Carrying register states across more joins is a separate, larger
change. This checkpoint leaves both optimizations pending.

## Reproduction

[register-affinity-evidence.zip](register-affinity-evidence.zip) includes the
reference tree, variant source overlays, raw timing and opcode-count logs,
ARM64 disassembly, test logs, and restoration/build scripts. Its `production`
variant is this implementation. Native binaries and dependency caches are
excluded. Follow its README to restore package configuration, then run:

```powershell
python experiment.py build production
python experiment.py affinity production
./run.ps1 -Variant production -Sweep 12 -Rotation 6 -Samples 21 -Warmup
./run.ps1 -Variant production -Probe affinity -Sweep 12 -Samples 15 -Warmup
python experiment.py arm production
python inspect.py production
```
