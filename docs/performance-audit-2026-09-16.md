# Performance audit, September 16, 2026

Audit of dart_eval `446d44973abcf9aea1318ae5affc36685d1b70c4` on branch `xv2`. Measurements ran on September 15 local time, September 16 UTC. No compiler, runtime, bridge, or test implementation changed during this audit.

## Findings

The current compiler does not yet deliver the intended performance. Source-compiled math loops measured 28 to 169 times slower than native Dart, and their medians were 1.2 to 1.8 times slower than CPython. The raw dispatcher performs much better than the generated programs suggest. Compiler output contains unnecessary branches, conversion round trips, and virtual calls for operations the VM already supports directly.

The object workloads expose a larger problem than arithmetic dispatch. Particle updates and recursive object traversal measured 426 and 315 times slower than native Dart. Generated code repeatedly calls synthetic getters, boxes numeric results, and moves values through spills. Source inspection also identifies a single-child frame cache that can allocate again when a caller alternates callees.

Loading has a particularly clear algorithmic target. A 648 KiB program with 3,001 functions takes about 153 ms to decode and validate. Branch validation repeatedly searches the function list even though the branch's owner was known during decoding. This should be fixed before spending time on individual byte copies.

Flutter bridging is already substantially faster than the published engine in the matched release probes. Widget construction improved about 5 times, native callbacks 13 times, and controller cycles 4.5 times. Constructor-heavy code improved roughly 47 times, with considerable timing variation. These wins coexist with the compiler and runtime costs identified below.

These are measurements of this checkout and the workloads below. They are not a general performance guarantee, and the workload suite also found a valid Dart program that the compiler currently rejects.

## Measurement conditions

| Item | Configuration |
|---|---|
| Host | Windows 11 build 26200, AMD Ryzen AI Max Pro 390, 12 cores / 24 logical processors |
| Dart execution tests | Dart 3.10.7 stable, Windows x64 AOT |
| Python | CPython 3.12.9, Anaconda build, ordinary Python loops without NumPy |
| Flutter tests | FVM Flutter 3.35.2 / Dart 3.9.0, Windows release AOT |
| ARM inspection | Dart 3.10.7 Linux ARM64 AOT snapshot, cross-compiled and disassembled |

The Dart execution probe compiles native and interpreted paths into the same executable. Both use the same algorithms and runtime-supplied iteration counts. Guest compilation, bytecode loading, and initial runtime setup happen before execution timing. Each workload has five warmup calls and eleven measured samples. Native calls are batched to roughly 30 ms per sample, then normalized to one call. Native and guest sample order alternates. Measured results are checked against the native checksum.

Python uses the same three math algorithms and iteration counts, three warmups, and nine samples. This comparison applies to the installed CPython version, not every Python implementation or release.

Final root benchmark processes ran on logical CPU 2 with AboveNormal priority. Benchmark processes did not compete with one another. The workstation still showed frequency and scheduling variation, especially during the integer-sum workload. Tables give medians and observed ranges where useful. These are not confidence intervals. Small differences with overlapping ranges should not guide architecture decisions.

ARM figures are static instruction counts along selected paths. No ARM machine was available, so there are no ARM timing, cycle, cache-miss, or power measurements.

## Tight math loops

Times are milliseconds per complete workload. Ratios divide the dart_eval median by the comparison median; greater than one means dart_eval is slower.

| Workload | Iterations | Native Dart | dart_eval | CPython | eval / Dart | eval / Python |
|---|---:|---:|---:|---:|---:|---:|
| Integer sum, `sum += i` | 2,000,000 | 0.797 | 134.686 | 113.027 | 169x | 1.19x |
| Double recurrence, `x = x * 1.0000001 + 0.125` | 1,000,000 | 1.521 | 42.378 | 32.022 | 27.9x | 1.32x |
| Integer multiply, add, XOR, mask | 1,000,000 | 1.227 | 171.779 | 93.000 | 140x | 1.85x |

| Workload | Native range, ms | dart_eval range, ms | Python range, ms |
|---|---:|---:|---:|
| Integer sum | 0.533 to 1.213 | 86.026 to 258.808 | 102.904 to 169.087 |
| Double recurrence | 1.214 to 1.622 | 33.483 to 46.728 | 31.648 to 56.322 |
| Integer mixing | 1.212 to 1.247 | 165.839 to 180.993 | 72.628 to 96.040 |

Integer-sum and double ranges overlap Python's ranges. The evidence supports saying that these compiled loops have not established an advantage over CPython. The integer-mixing regression is clearer and has a specific cause: known integer XOR and AND still become boxed virtual calls.

### Dispatcher-only comparison

The existing `benchmark/dispatch.dart` uses hand-written bytecode. Its kernels differ from the source workloads above, so these numbers are a diagnostic comparison, not an alternative score for the compiler.

| Kernel, 5 million iterations | Native ms | Typed VM ms | Object-reference VM ms | Typed ns / bytecode |
|---|---:|---:|---:|---:|
| Integer, 4 bytecodes / iteration | 1.268 | 35.150 | 44.134 | 1.76 |
| Double, 4 bytecodes / iteration | 2.602 | 37.994 | 52.615 | 1.90 |
| Mixed, 5 bytecodes / iteration | 2.548 | 43.196 | 59.592 | 1.73 |

These runs used twelve warmups and nine measured samples. The object-reference VM is the benchmark's comparison implementation, not pub.dev dart_eval. The typed VM is 1.26 to 1.38 times faster than that reference here. Its tiny arithmetic handlers are viable, but current source lowering leaves much of that benefit unused.

## Object and general Dart workloads

| Workload | Work per invocation | Native ms | dart_eval ms | eval / Dart |
|---|---|---:|---:|---:|
| Particle updates | 64 objects, 1,000 update steps, numeric fields and methods | 0.109 | 46.332 | 426x |
| Event callbacks | 20,000 events, two closures sharing captured state | 0.098 | 14.175 | 145x |
| Word counting | 96,000 tokens, lowercase, split, map lookup/update | 3.591 | 31.575 | 8.79x |
| Recursive tree | 1,000 traversals of 255 nodes, nullable fields and method calls | 0.341 | 107.352 | 315x |

The corresponding dart_eval ranges were 46.018 to 52.135 ms, 12.559 to 28.257 ms, 31.248 to 36.200 ms, and 106.483 to 121.533 ms. Native ranges were 0.105 to 0.118 ms, 0.083 to 0.118 ms, 3.391 to 4.725 ms, and 0.327 to 0.448 ms.

Word counting spends more work inside native collection and string operations, which helps amortize interpreter overhead. The particle and tree cases spend much more time crossing guest method and field boundaries. These are small application-shaped workloads, not whole applications. They do not cover I/O throughput, sustained async traffic, large heaps, or every dynamic dispatch pattern.

A further shopping-basket workload alternates two pricing-policy classes through a `dynamic` receiver. Native Dart accepts it, but dart_eval reports `Incompatible representations for arg_1₁: integer and object; an explicit conversion is required`. Equivalent source variations also failed. There is no timing for that workload. The representation solver correctly requires an object operand for unboxing; the likely defect is an earlier conversion or ABI decision. Fixing it is a correctness prerequisite for expanding the polymorphic workload sample.

## Flutter bridging versus pub.dev

The published baseline is dart_eval **0.8.5**, the current release listed on [pub.dev](https://pub.dev/packages/dart_eval) when checked for this audit. The current side uses local dart_eval and flutter_eval at `4ee2015`. The published side uses an isolated copy of flutter_eval at `1bf342a`, before the new runtime API adaptation, with pub.dev dart_eval 0.8.5. This compares working compiler/runtime/adapter combinations; it does not isolate the runtime from every adapter change.

Both sides use FVM Flutter 3.35.2 / Dart 3.9.0 and Windows release AOT. The guest workload files and native control files match between builds. Native-only `const` constructors in an exploratory probe were removed before final sampling. Those exploratory results are excluded here. Compilation happens outside timing, and warmed measurements exclude decoding/setup.

There are two runs per engine, in current, published, published, current order. Each run has three warmups and eleven measured samples per workload, giving 22 samples per engine. Processes use the same CPU affinity and priority as the other tests. Every warmup and measured checksum is checked after stopping the timer.

| Workload | Work per invocation | Current ms | Published 0.8.5 ms | Published / current |
|---|---|---:|---:|---:|
| Pure Dart control | 100,000 iterations of integer mask and sum | 15.595 | 31.345 | 2.01x |
| Bridge constructors | 5,000 batches, 20,000 objects total | 13.462 | 626.161 | 46.51x |
| Widget trees | 1,250 Column/Padding/Container/Row trees with Text | 1.986 | 9.873 | 4.97x |
| Native callbacks | 25,000 ChangeNotifier notifications into a guest closure | 10.782 | 141.021 | 13.08x |
| Controller cycles | 5,000 create/listen/clear/remove/dispose cycles | 4.489 | 20.368 | 4.54x |

| Workload | Current observed range, ms | Published observed range, ms | Native control median, current build / published build, ms |
|---|---:|---:|---:|
| Pure Dart control | 13.604 to 54.898 | 29.902 to 42.651 | 0.032 / 0.061 |
| Bridge constructors | 3.986 to 22.078 | 588.155 to 724.041 | 0.586 / 0.306 |
| Widget trees | 1.954 to 3.178 | 9.533 to 10.240 | 0.071 / 0.056 |
| Native callbacks | 10.546 to 11.767 | 137.653 to 149.439 | 0.147 / 0.119 |
| Controller cycles | 4.347 to 5.699 | 19.888 to 23.104 | 0.285 / 0.221 |

The constructor workload creates EdgeInsets, BorderRadius, TextStyle, and BoxDecoration objects and retains them in a List until returning its length. The widget workload constructs trees and returns their count. It does not mount widgets, run layout, rasterize, or measure frame rate. Native AOT is free to optimize short-lived work, and native controls differ between the two executable environments. The guest-to-guest comparison is the primary result here. Constructor timings are particularly sensitive to allocation/GC and workstation noise; the exact 46.51x factor should not be generalized to an application. The gap itself is unambiguous in these samples.

Fresh-runtime first invocation, including decoding, setup, and the entire 20,000-object constructor workload, measured 10.644 ms for current and 640.179 ms for published. Their ranges were 5.086 to 23.100 ms and 584.135 to 735.826 ms. This is not a pure loading measurement. The current first-call median can be lower than its warmed constructor median because of allocation/GC state and variation. Lazy construction plus plugin registration alone took medians of 2 and 14 microseconds and did not decode bytecode.

The probe also exposed a current compatibility failure: assigning `TextEditingController.text` reaches `$Object.$setProperty` and throws `UnimplementedError: set $Object.text`, despite the bridge implementing a setter. The timed controller workload uses the supported `clear()` mutation on both engines. The failure was recorded, not fixed.

Bridging therefore does not need a wholesale redesign to regain the published engine's throughput. The remaining opportunities are to cut known-signature callback setup, repeated argument-layout allocation, wrapper allocation, and unnecessary compiler-generated work. The 3.9.0 Flutter results should not be compared directly with the standalone 3.10.7 timings to infer an SDK or VM speed difference.

## IR and bytecode quality

The arithmetic loop IR has conventional SSA loop phis and typed arithmetic. Lowering and block layout then expand a very small computation substantially.

For integer sum, the successful iteration executes bytecode positions `15, 18, 21, 22, 25, 28, 34, 37, 40, 41, 48, 51, 54, 57, 58, 61, 64, 67`. Its eighteen instructions include:

| Work | Bytecodes per iteration |
|---|---:|
| Spills and reloads | 9 |
| Unconditional jumps | 4 |
| Adds | 2 |
| Comparison, conditional jump, immediate load | 3 |

Positions 25 to 28 to 34 form a jump-only chain. Better layout and fallthrough handling can remove three of the four unconditional jumps in this loop. That is a 17% reduction in executed bytecode count before considering other changes, not a measured 17% speedup. The loop increment also loads `1` and adds it although increment opcodes already exist.

Nine spill/reloads are expensive, but two integer banks cannot hold the bound, counter, and sum simultaneously. The target should be better allocation, phi placement, and rematerialization, rather than assuming all spills can disappear. The double loop similarly reloads two constants every iteration, with only two double banks available.

Other concrete findings:

* List loops emit `aListLengthR; rBoxA; aFromR`. This occurs in particles, events, and word counting. A nonescaping wrapper is allocated only to recover the same integer immediately.
* Integer mixing emits typed multiply/add followed by boxes and two `callVirtual` instructions for XOR and AND. The runtime already has typed bitwise instructions.
* Particle methods call tiny synthetic field getters/setters virtually, then unbox numeric values and box results. Exact-class or proven synthetic-accessor specialization would remove several costs together. It must preserve overrides and user-defined getter side effects.
* Tree traversal repeats getter calls around null checks. Its non-null assertion also constructs a message and invokes an external helper before the assertion instruction. Avoiding eager error-message work is worth investigating. Removing repeated getter calls requires proof that the getter is synthetic or pure.

The instruction stream itself is compact. The sum program has 70 bytes of code in a 9,035-byte payload; particles have 795 code bytes in 10,988 bytes; word counting has 542 code bytes in 9,743 bytes. Most small-program payload size is metadata. Compact operands help storage, but source-level instruction count and operand decoding currently dominate the more obvious execution opportunities.

## ARM64 instruction sampling

The AOT `_dispatch` function occupies 25,656 bytes and reserves a 176-byte native stack frame. There are 243 opcodes, leaving thirteen values in the one-byte opcode space.

Counts below include the steady dispatch header and the ordinary loop tail where applicable. A helper call counts as one instruction; its body is excluded unless separately stated. Paths exclude GC, failed checks, exception handling, write barriers, and other slow paths. Thus call, allocation, List, and async rows are partial native costs.

| Operation | Approximate executed ARM64 instructions | Extra work outside count |
|---|---:|---|
| Integer add / double add / increment | 41 | None on sampled path |
| Register move | 40 | None |
| Signed integer immediate | 76 | None |
| Integer / double / object constant | 71 / 72 / 72 | Pool helper; integer helper adds 10 |
| Integer spill / reload | 78 / 76 | None |
| Object spill / reload | 85 / 76 | Heap-reference store excludes write barrier |
| Short conditional branch, taken / not taken | 77 / 53 | None |
| Short unconditional branch | 73 | None |
| Full-width conditional branch, taken | 90 | None |
| Object field load / store | 90 / 99 | Store excludes write barrier |
| Static call | 71 | Warm frame entry adds 35; cold entry allocates |
| Virtual call, guest member found | 95 | Resolution and frame entry |
| External / host call | 75 / 75 | Argument export and host callback bodies |
| Box small integer / double | 68 / 73 | Allocation stubs |
| Unbox integer | 54 | Conversion helper |
| List index / set / append / length | 72 / 74 / 68 / 69 | Indirect host List operation |
| String length / concat / code unit | 64 / 74 / 76 | Concat helper and allocation |
| Internal integer / object return | 59 / 58 | Frame leave |
| Root integer / object return | 42 / 40 | Sample uses small integer |
| Begin async / await / async return | 51 / 64 / 63 | Async state and scheduling helpers |

The common header is 31 instructions, including eleven native stack stores on every dispatch. The common tail adds five instructions and reloads three shared values. Together they account for 36 of the 41 instructions for addition. Operand decoding adds separate byte loads and checks, which makes immediate, spill, and branch operations much more expensive than their arithmetic names suggest.

A warm static call plus internal integer return costs about 209 instructions, plus two indirect `List.length` bodies, before argument setup, callee work, or explicit spill bytecodes. Even a frame with no object spills or outgoing arguments takes a 44-instruction leave path and those two length calls. Nonempty frames also clear references. The one-child frame cache is keyed by callee, so alternating callees can replace the cached frame and allocate its arrays again.

Boxing a small integer allocates both a `$int` and its `$Object` delegate. Boxing a double additionally allocates a native boxed double on the sampled path. Avoiding redundant boxing therefore removes more than one allocation. Virtual cache hits still perform nested map lookups, followed by dispatch checks and frame handling.

This snapshot comes from `benchmark/runtime_probe.dart`. Its AOT reachability differs from a Flutter application; concrete native bridge subclasses are absent and some bridge paths disappear. Exact counts must be rechecked in the target application and SDK. Changing Dart source to reduce stores or checks is an experiment, not a guaranteed AOT improvement. Actual ARM hardware measurements are still needed.

## Bytecode loading

These synthetic programs retain every generated function as an export. Straight-line functions return strings assembled from an argument and constants. Branch-heavy functions contain a counting loop. A separate `main` returns 42, keeping first invocation work negligible.

Times are medians in milliseconds. `Program.read` includes decoding and validation. First-call columns include runtime construction, setup, and execution of `main`, with input bytes already in memory. The parsed-program column reuses a validated `Program` but creates independent runtime state each time.

| Fixture | Functions | Payload KiB | Code KiB | Read + validate | First call from bytes | First call from parsed program |
|---|---:|---:|---:|---:|---:|---:|
| Straight, small | 2 | 9.1 | 0.04 | 0.307 | 0.273 | 0.045 |
| Straight, medium | 101 | 42.3 | 3.1 | 0.783 | 0.598 | 0.035 |
| Straight, large | 1,001 | 348.2 | 31.3 | 3.602 | 2.905 | 0.067 |
| Branch, medium | 101 | 29.7 | 6.8 | 0.404 | 0.441 | 0.023 |
| Branch, large | 1,001 | 220.4 | 68.4 | 20.277 | 19.098 | 0.070 |
| Branch, largest | 3,001 | 648.1 | 205.1 | 152.683 | 158.518 | 0.185 |

Each mode uses eight warmups and seven samples, with batches from three to one hundred operations. Modes run separately, so noise and GC can make a first-call median lower than a standalone read median. Do not subtract these medians to infer exact phase costs. Read/validate ranges for the two largest branch fixtures were 17.528 to 21.061 ms and 136.123 to 193.123 ms.

`Runtime(bytes)` is lazy. Timing only its constructor does not measure loading. Reading the largest branch fixture from the warm OS file cache took a median 0.214 ms, versus 153 ms for decode/validation. This is not a cold-disk measurement.

The branch fixture grows from 1,001 to 3,001 functions, but read time grows roughly 7.5 times. Source inspection explains this: `TypedProgram` uses `ordered.lastWhere` for each branch destination, giving a branch-count times function-count cost. It repeats a related search for exception destinations. The typed-payload-only measurement takes roughly the same time as whole-program reading for the largest fixture, so JSON envelope decoding cannot explain this growth.

Other loading opportunities are smaller but concrete:

* Field validation recomputes the maximum field count across every class for each field instruction.
* `TypedFunction.callLayout` reconstructs argument-location maps and lists on every access. Validation often only needs its overflow count. External entry preparation also uses this getter; ordinary internal static calls do not reconstruct it on every call.
* The envelope reader copies the embedded payload, and `TypedProgram` copies code again. Numeric pools first decode into ordinary lists, then copy into typed arrays. Some function/class metadata is frozen and cloned twice.
* Seven envelope sections pass through UTF-8, JSON, and replacement typed maps. Repeated metadata strings also allocate during decoding.

An internal decoder that owns its buffers could remove redundant copies while retaining defensive public constructors. It must carry slice offsets and lengths correctly and preserve endian/alignment handling. Reusing a parsed program already avoids validation on subsequent runtime creation; globals and bridge registrations must remain independent.

## Recommended optimization order

This order balances likely impact with implementation scope and confidence in the diagnosis. A loading fix has no effect on a warmed loop, and an arithmetic fix has limited value to a host-heavy application. Use the corresponding workloads as separate acceptance criteria. These are proposals, not implemented or measured speedups.

| Order | Target | Expected benefit and evidence | Scope |
|---|---|---|---|
| 1 | Make branch and exception-target validation use the known owning function | Removes the observed branch-count times function-count loading cost. Preserve instruction-boundary and same-function checks. | Small, localized algorithm change |
| 2 | Select existing integer bitwise and increment instructions | Removes boxed virtual XOR/AND calls in mixing and events; removes immediate-plus-add sequences for increments. No new opcode allocation required. | Small to medium compiler change |
| 3 | Eliminate proven box/unbox round trips | Removes repeated wrapper allocation in List loops and other boundaries. Keep conversions explicit and compiler-controlled; do not add runtime type guessing. | Small to medium IR/lowering change |
| 4 | Thread jump-only blocks and emit fallthroughs after layout | Three removable unconditional branches in the eighteen-bytecode sum loop; similar chains across the sample. Update branches and exception regions consistently. | Small to medium backend change |
| 5 | Precompute validation metadata and argument layouts | Hoist class field limits; avoid rebuilding call layouts for validation and exported/callback entry. Useful for both loading and call-heavy code. | Small, with immutable metadata ownership to preserve |
| 6 | Specialize callback entry and reduce frame allocation/cleanup | Native callbacks construct argument/register lists and a fresh root frame; alternating internal callees evict the caller's sole cached child. Use known signatures, then consider bounded frame reuse. Preserve reentrancy, suspended frames, and prompt reference release. | Medium interop/runtime change |
| 7 | Improve register allocation and loop phi handling | Half of the sum loop's bytecodes are spills/reloads. Carry useful values across blocks, rematerialize cheap constants, and avoid needless parallel-copy traffic. Respect the real two-bank pressure. | Medium to large backend change |
| 8 | Specialize proven field/getter and method calls | Addresses the largest OOP gaps by removing virtual lookup, tiny callee frames, and numeric conversion boundaries together. Requires exact-class or override analysis and safe treatment of bridge classes. | Larger compiler change |
| 9 | Reduce wrapper and dynamic dispatch allocation | Small-integer boxing creates two wrappers; member-cache hits still use nested maps. Investigate lazy delegate storage and compact compiler-assigned member IDs without weakening dynamic behavior. | Medium to large interop/runtime change |
| 10 | Experiment with dispatcher state preservation and operand decoding | Common code is 36 of 41 instructions for add; spills and taken branches cost much more. Inspect AOT after each small generator change, then measure real ARM hardware. | High leverage, uncertain implementation cost |
| 11 | Remove redundant decoder copies and metadata reconstruction | Reduces linear allocation and memory traffic after the dominant validator issue is fixed. Preserve ownership, mutation safety, and portability. | Medium codec change |

I would start with the first five, then rerun this entire workload set before changing the register-bank design or adding many fused opcodes. Only thirteen opcode slots remain. Existing typed operations are underused, and consuming those slots now could restrict future Map, Set, String, or List intrinsics without addressing the larger costs.

The rejected polymorphic workload and Flutter setter failure need correctness follow-up alongside this work. Performance results from supported paths must not hide those gaps. No allocation profile or CPU sampling profile was collected, so the relative weight of frame churn, wrapper allocation, and member lookup within the OOP times remains to be measured.

The callback path is distinct from internal calls. `TypedClosure.invoke` builds its argument vector; `TypedEntry.fromValues` reconstructs the call layout and a register list; `TypedMachine.runEntry` creates a fresh root frame and its spill arrays. A generated bridge adapter knows its callback signature, so it is worth investigating an exact entry path with precomputed locations. That does not justify changing the flexible exported-function API or reusing an active frame during reentrant callbacks.

Source anchors for implementation planning:

* [Branch ownership validation](D:/Projects/dart_eval/lib/src/eval/runtime/typed/typed_program.dart:536), [field-limit recomputation](D:/Projects/dart_eval/lib/src/eval/runtime/typed/typed_program.dart:441), and [call-layout getter](D:/Projects/dart_eval/lib/src/eval/runtime/typed/typed_function.dart:81).
* [Internal frame entry](D:/Projects/dart_eval/lib/src/eval/runtime/typed/typed_frame.dart:161), [frame cleanup](D:/Projects/dart_eval/lib/src/eval/runtime/typed/typed_frame.dart:203), and [prepared callback entry](D:/Projects/dart_eval/lib/src/eval/runtime/typed/typed_frame.dart:111).
* [Closure invocation](D:/Projects/dart_eval/lib/src/eval/runtime/typed/typed_closure.dart:171) and [root frame creation](D:/Projects/dart_eval/lib/src/eval/runtime/typed/typed_machine.g.dart:42). Runtime changes must go through the generator rather than editing the generated machine directly.

## Evidence and reproduction

Local evidence is retained under `.dart_tool/performance_audit_20260916/`. It includes the exact workload source, emitted IR and bytecode, payloads, AOT executables, raw timing samples, ARM disassembly, and selected native instruction paths. This directory is ignored by Git.

Key files are `audit.dart`, `cases.json`, `python_math.py`, `execution-aot-pinned.jsonl`, `python-math-pinned.jsonl`, `loading-aot-pinned.jsonl`, `dispatch-aot-pinned.txt`, and `arm64/REPORT.md`. The rejected original workload is `checkout-original.dart`. `arm64/instruction_counts.csv` and `arm64/paths_fast.json` preserve the instruction-count evidence.

Flutter probes and results are under `D:/Projects/flutter_eval/.dart_tool/performance_audit_20260916/`. `stats.json` aggregates `current-final.json`, `current-final2.json`, `published-final.json`, and `published-final2.json`. `protocol.json` records the run configuration. The `current` and `published` projects contain the exact probe sources and dependency lockfiles; `flutter_eval_legacy` contains the adapter snapshot. Use FVM from the flutter_eval directory tree to build them, then run each release executable with `--benchmark --iterations=5000 --warmups=3 --samples=11 --output=<unique-json-path>`. Flutter's engine remains alive after the probe writes its result, so terminate that probe process after the output file appears before starting another run.

An [evidence bundle](D:/Projects/dart_eval/.dart_tool/performance_audit_20260916/performance-audit-evidence.zip) preserves the probes, raw results, bytecode, disassembly, report, and legacy Flutter adapter source. SDKs, package caches, and compiled executables are excluded; reproduction still needs the named checkouts and toolchains.

From the dart_eval root, the principal commands are:

```powershell
dart compile exe .dart_tool/performance_audit_20260916/audit.dart -o .dart_tool/performance_audit_20260916/audit.exe
.dart_tool/performance_audit_20260916/audit.exe prepare
.dart_tool/performance_audit_20260916/audit.exe execute 11
python .dart_tool/performance_audit_20260916/python_math.py
.dart_tool/performance_audit_20260916/audit.exe loadprepare
.dart_tool/performance_audit_20260916/audit.exe branchprepare
.dart_tool/performance_audit_20260916/audit.exe load
./tool/inspect_typed_arm64.ps1 -Objdump 'C:/Program Files/LLVM/bin/llvm-objdump.exe' -Objcopy 'C:/Program Files/LLVM/bin/llvm-objcopy.exe' -Output .dart_tool/performance_audit_20260916/arm64
```

For comparable timing, run one benchmark process at a time with the affinity and priority above. Preserve the raw samples rather than choosing the fastest run. No projected optimization speedups in this report have been benchmarked.
