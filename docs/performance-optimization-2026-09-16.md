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

## Callback entry

Typed entry construction now assigns typed fields directly, removing the temporary nine-element object list. Zero-argument callbacks with no optional/named adapter enter directly with their environment and bound receiver. Other signatures retain their existing validation and compiler-generated adapters.

The AOT callback benchmark compiles once, resolves each callback once, reuses argument lists, and checks the result after every sample. These are native-to-guest boundary costs including the guest body, not dispatch-only timings. Eleven samples, 300,000 calls per zero-argument case and 100,000 per other case:

| Callback | Before ns/call | After ns/call |
|---|---:|---:|
| Void, updating a global | 91.04 | 60.06 |
| Captured integer result | 112.28 | 82.41 |
| One integer argument | 130.71 | 122.81 |
| Optional argument adapter | 103.58 | 99.46 |
| Bound instance method | 244.35 | 217.69 |

The callback changes and current allocator work pass all 817 dart_eval tests. Focused callback coverage includes fresh and serialized closures, captures, bound receivers, reentrancy, exceptions, and asynchronous results. Scoped analysis is clean.

Register/opcode/inlining experiments are isolated from production. They measure source-generated workloads as well as call benchmarks, and must preserve room for future collection intrinsics.

## Conditional register carry and remaining correctness

The constrained allocator now carries registers into each ordinary forward branch successor with one predecessor. Joins and backedges still use canonical spill slots. An explicit operation marker prevents synthetic exception edges from inheriting registers. RPO positions are indexed once rather than searched repeatedly.

The particles workload drops two static spill/reload instructions and four bytes; checkout drops three spill/reloads and eight bytes; events drops one spill/reload and two bytes. Other workloads are mostly unchanged. This is a conservative improvement, not a global register allocator.

An additional correctness regression found while preparing callback workloads is fixed: implicit instance-field assignment now returns the boxed representation actually stored. Prefix and compound updates previously could try to box that value again. Fresh and serialized regression coverage includes fields, captures, and globals.

The sibling control_flow_graph allocator checkpoint is `7dc5626`. Its twelve existing string-fixture failures reproduced exactly against the old library. The subsequent test refactor replaces shared mutable snapshots with independent graph/SSA/liveness/allocation assertions and executable loop cases, including zero, one, and multiple iterations. All 65 CFG tests now pass, with clean analysis of changed test files.

## Frame reuse

Inactive leaf frames now reuse their storage across different callees, growing a spill or outgoing buffer only when necessary. Object buffers are fully cleared on return. Suspended frames detach and cannot be borrowed by the former caller. Frames with cached children keep the old function-specific policy.

That last restriction is measured. Retargeting every inactive frame reduced allocation but slowed recursive trees from about 104–105 ms to 122–126 ms. Caching the previous callee did not solve this. Restricting retargeting to frames without cached children retained the object-workload gains and improved trees too. Buffer capacities remain at their high-water sizes until their frame is released; this trades some retained empty storage for fewer allocations.

The reference below already includes the first five changes, callback entry, and conditional carry. These sequential pinned AOT runs use fifteen samples per workload. The two leaf experiments bracket an additional reference run; the final column is the shipped source, after formatting and making the helper private.

| Workload | Reference runs ms | Leaf-only runs ms | Final source ms |
|---|---:|---:|---:|
| Integer mixing | 32.387 / 33.124 | 32.866 / 38.320 | 32.671 |
| Particles | 44.297 / 45.263 | 35.855 / 36.305 | 35.467 |
| Checkout | 40.038 / 41.184 | 34.914 / 35.276 | 34.402 |
| Events | 6.791 / 6.943 | 6.288 / 6.313 | 6.261 |
| Word counting | 28.507 / 28.907 | 28.897 / 29.466 | 28.757 |
| Recursive tree | 104.279 / 105.498 | 97.328 / 99.165 | 99.161 |

Particle, checkout, event, and tree improvements repeat. Arithmetic and word-count differences are mostly noise. The final sum/double medians were 76.218/32.198 ms, while warmed reference/leaf runs were about 39–40/26 ms. Native controls again moved with the first two cases, so those final raw numbers cannot establish a regression or a precise speedup. Every audit result matched native Dart.

At 300,000 iterations and 21 samples, the leaf variant's method-call loop took 61.649 ms versus 67.795 ms for the nearby reference; polymorphic calls took 31.640 versus 35.153 ms. Primitive, mixed, boxed-argument, and overflow-argument calls were broadly unchanged. Full sample ranges are preserved; earlier noisy call sweeps are not discarded from the evidence.

## Register, opcode, and inlining experiments

Each variant has an isolated source tree and dependency configuration. All eight source workloads passed their checksum checks. Secondary dispatch also passed explicit tests of extended constants, globals, exceptions, fresh/serialized execution, and invalid encodings. These prototypes retain the current codec version only inside their isolated trees; their payloads must not be mixed with production bytecode.

| Variant | ARM64 dispatch bytes | Common header instructions | Integer add path instructions | Decision |
|---|---:|---:|---:|---|
| Current boundaries | 25,664 | 31 | 41 | Keep |
| Prefer inline frame entry/return | 28,848 | 31 | 43 | Reject: larger loop, no broad workload win |
| Prefer inline pool access | 25,952 | 31 | 47 | Reject: more register pressure and slower workloads |
| 200 primary operations plus secondary prefix | 24,696 | 31 | 40 | Keep prototype only: smaller native code, no measured throughput win |
| Third integer register, hot constant loads | 34,428 | 32 | 41 | Reject this design: larger loop and slower workloads |

These are cross-compiled Dart 3.10.7 Linux ARM64 instructions, not ARM hardware timings. The add count includes one dispatch header and the handler's path back to dispatch, excluding called helper bodies. The baseline header saves eleven stack values per iteration. Its immediate load, reload, and spill paths are approximately 76, 76, and 78 instructions. Frame reuse leaves the final dispatch at 25,664 bytes.

The first third-register experiment misplaced its constant load in the secondary table. A corrected run put that operation in the primary table. It removes one reload from integer mixing and reduces its code from 61 to 58 bytes, but takes 37.141 ms versus reference runs of 32.387/33.124 ms. Particles, checkout, events, word counting, and trees also regress. This measures one additional integer register with a conservative allocator, not every possible larger-bank design. The public argument/return ABI remained unchanged.

Secondary dispatch reserves a primary byte and reads a second selector into a nested integer switch. Its path to the second dispatch adds about 23 instructions before the cold handler in the 200-primary experiment. The primary selection uses static usage in this small workload set, which biases it toward these programs. It is useful evidence for accommodating future Map/Set/List/String intrinsics, not justification for deleting operations absent from eight programs. Production keeps all 243 operations and the existing bytecode format.

For a future allocator pass, loop headers and backedges remain the largest compiler opportunity. The sum loop still spills/reloads six values per successful iteration. Whole-loop register assignment and constant rematerialization should be measured before adding another scalar bank. Exact-class field/method lowering is the next broader OOP target; these measurements do not make dynamic lookup or wrapper costs disappear.

## Final validation and evidence

The final dart_eval suite passes **822 tests**. Five frame-reuse tests cover storage growth and clearing, outgoing overflow, fresh/serialized execution, exceptions/finally, detached asynchronous calls, and recursive sibling calls. Analysis has no code issues; the existing path-dependency publishing warning remains. The generator check passes with 243 instructions. The sibling CFG suite passes **65 tests**, and its fixture-refactor checkpoint is `9e96620`. Flutter performance was not rerun.

Raw results, source snapshots, experiment scripts, emitted IR/bytecode, ARM disassembly, and validation logs are retained in `.dart_tool/performance_optimization_20260916/`. The committed `docs/performance-optimization-evidence.zip` contains the portable evidence, excluding executables, AOT images, package caches, and absolute package configurations. Its README explains reconstruction. Early noisy sweeps and rejected variants remain included.
