# Performance optimization checkpoints

## First five targets and correctness

Implemented linear branch/exception destination validation, a hoisted field limit, cached immutable function layouts, and allocation-free validation of argument overflow counts. Public const function descriptions remain supported and caller-owned argument lists are still copied before validation.

The compiler now selects typed integer bitwise/shift operations and increments, eliminates proven primitive box/unbox round trips, and lays out fallthrough traces with jump-only labels redirected to their destinations. Loop phis and exception targets retain their semantics. The sum loop executes eleven bytecodes per successful iteration instead of eighteen, and its code shrank from 70 to 46 bytes.

Binary-expression lowering now preserves the evaluated left operand before evaluating the right. This fixes the shopping-basket representation failure and evaluation order when the right operand changes the left operand's source local. The basket workload now compiles and returns 66,905,000, matching native Dart.

In flutter_eval, the TextEditingController bridge setter now returns after assigning text instead of falling through to the superclass setter. A fresh/serialized regression and the fourteen-test Flutter suite pass. No Flutter performance benchmarks were rerun.

The complete dart_eval suite passed 810 tests. Subsequent layout/metadata refinements passed the relevant 77-test and 66-test subsets. Analysis has no code errors or warnings; the existing local path-dependency publishing warning remains. Generated runtime validation passes with 243 instructions.

The saved baseline executable and new AOT executables use the audit's workloads and checksum checks. Processes were pinned to logical CPU 2, AboveNormal, and run sequentially. Raw evidence is under `.dart_tool/performance_optimization_20260916/`.

| Workload | Baseline median ms | First optimized sweep ms | Final optimized sweep ms |
|---|---:|---:|---:|
| Integer sum | 88.193 | 38.491 | 76.949 |
| Double recurrence | 35.082 | 25.819 | 56.936 |
| Integer mixing | 179.051 | 32.032 | 31.608 |
| Particles | 47.291 | 44.808 | 43.934 |
| Events | 13.205 | 6.863 | 6.900 |
| Word counting | 31.583 | 28.148 | 28.680 |
| Recursive tree | 115.936 | 105.287 | 103.709 |

The first sweep predates removal of unreachable trampolines and the overflow-count refinement. The final sweep shows substantial startup-time noise in its first two workloads: native sum also rose from 0.425 ms in the first optimized sweep to 0.840 ms, and native double recurrence from 1.250 to 2.489 ms. Do not interpret the raw doubled times as a compiler regression, or claim a precise sum/double speedup from these runs. Integer mixing and events show consistent improvements of about 5.6 and 1.9 times. Object-heavy workloads improve modestly and still need call/field work.

On identical preexisting payloads, read/validate medians for the 1,001-function branch fixture fell from 14.086 to 2.396 ms, and the 3,001-function fixture from 116.334 to 10.382 ms. The 1,001-function straight-line fixture changed from 1.961 to 2.202 ms. The algorithmic loading improvement is concentrated in branch-heavy programs; the remaining linear metadata costs still matter.

Targets six and seven are being evaluated separately. A native-to-guest callback benchmark has been added before changing callback entry so that the next checkpoint has a comparable baseline. Register/opcode/inlining experiments must measure source-generated workloads as well as dispatch kernels, and preserve room for future collection intrinsics.
