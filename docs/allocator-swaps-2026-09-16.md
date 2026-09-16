# Allocator swap checkpoint

The constrained allocator now places all operands together, emitting register
swaps for resident cycles. control_flow_graph `f77d892` contains the allocator
and its tests; dart_eval adds source-to-bytecode integration coverage.

Reversed integer and double calls now use `aBSwap` and `fGSwap` instead of
spill / copy / reload. Three-object rotations use two swaps without spilling.
Moves into available destinations run first, avoiding unnecessary spills even
when the instruction has no permutation cycle. Duplicate operands and resident
aliases retain their values. Swaps require a shared register group containing
both registers; incompatible cycles retain the spill-based fallback.

Variant selection credits reciprocal pairs as one swap. Its eviction cost still
accounts for the value currently occupying a destination before loading inputs.
Operand matching also handles overlapping register types when an operation has
no fixed variants. This is compiler work; the runtime and opcode table are unchanged.
Constrained assembler integrations must now supply the existing `onSwap` callback
if their allocation can form cycles. dart_eval already supplies it.

## Verification

- control_flow_graph: 74 tests pass; analyzer clean.
- dart_eval: 868 tests pass; only the existing local path-dependency warning.
- Generator check: 231 instructions, unchanged bytecode versions 104/116.
- Coverage includes exact scalar/object swap emission, live values across calls,
  stored spills, duplicate operands, aliases, independent banks, overlapping
  groups, and fresh/serialized execution.

## Performance

Dart 3.10.7, Windows x64 AOT, logical CPU 2, AboveNormal priority. Before and
after payloads run through the **same executable**, alternating order each sample.
Two sweeps use 31 samples per workload, different workload orders, a separate
warmup process, and five warmups per runtime. Every measured result is checked
against native Dart. No builds or tests ran during these paired measurements.
Flutter and ARM64 were not rerun because this change affects allocation rather
than dispatch implementation.

The baseline is dart_eval `c6d69a9` with CFG `9e96620`; the new payloads use CFG
`f77d892`. Call probes each execute 100,000 iterations. The other eight workloads
retain the parameters from the prior performance audit. Values below are median
milliseconds for sweep 1 / sweep 2.

| Workload | Before | After |
| --- | ---: | ---: |
| Integer permutation calls | 5.764 / 5.635 | 5.041 / 5.206 |
| Double permutation calls | 15.384 / 14.602 | 14.194 / 13.388 |
| Object rotation calls | 23.871 / 23.373 | 23.385 / 22.921 |
| Integer sum | 39.544 / 37.444 | 39.589 / 37.437 |
| Double recurrence | 26.858 / 25.288 | 26.928 / 25.297 |
| Integer mixing | 34.885 / 32.485 | 35.175 / 32.404 |
| Particles | 37.112 / 34.855 | 35.673 / 33.555 |
| Checkout | 36.967 / 34.900 | 36.344 / 34.386 |
| Events | 6.927 / 6.581 | 6.257 / 5.905 |
| Word count | 30.839 / 28.410 | 30.487 / 27.614 |
| Recursive tree | 104.321 / 101.984 | 104.544 / 101.770 |

Integer permutation calls improve 7.6–12.5%, doubles 7.7–8.3%, and object calls
about 2%. Events improve about 10% and particles about 4%. The unchanged math
workloads and tree traversal remain within measurement noise. Host performance
drifts between sweeps, so compare before/after within each paired sweep.

Bytecode sizes also fall: integer calls 73→62 bytes, double calls 94→78,
object calls 186→180, particles 679→602, events 227→197, and word count 409→384.
The three arithmetic-loop bytecodes retain their original sizes and contents.
Much of the broader improvement comes from scheduling copies safely before
overwriting their sources; only the dedicated call probes emit swaps in this
workload set.

## Remaining work and reproduction

Join boundaries still use canonical spill slots, so this does not introduce
register-state merging across arbitrary CFG edges. Alias-heavy placements can
prefer several safe copies over a shorter swap sequence. Longer-cycle costing
remains approximate; placement correctness does not depend on that estimate.

[allocator-swap-evidence.zip](allocator-swap-evidence.zip) contains the driver,
source workloads, both CFG source snapshots, bytecodes, disassembly listings,
raw paired timings, validation logs, and restoration instructions. The saved
payloads can run against this checkpoint without recompilation. Native binaries
and dependency caches are excluded.
