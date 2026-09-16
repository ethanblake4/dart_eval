# Register affinity experiments

These experiments compare against dart_eval `7ee5a3e` and control_flow_graph
`9e96620`, with Dart 3.10.7. Production sources remain unchanged while the
variants are measured. Each variant has its own source snapshot, package
configuration, compiler, serialized programs, and AOT executable.

The variants are:

| Variant | Change | Opcodes |
|---|---|---:|
| Reference | Current production runtime | 243 |
| E-only comparisons | Remove twelve numeric comparison handlers targeting X; retain X storage and ABI | 231 |
| S-only field reads | Replace `rLoadPropertyR` with `rLoadPropertyS` | 243 |
| Optional S field reads | Offer both forms to the existing constrained allocator | 244 |
| Combined | E-only comparisons plus optional S field reads | 232 |
| No X register | Remove X from dispatch, allocator, entry state, and argument layout | 207 |

The no-X variant passes only the first boolean argument in E. Additional
booleans use the existing object registers and, when needed, the single
overflow list. Existing compiler-generated conversions handle that boundary.
It keeps the other register IDs unchanged. Experimental opcode tables and
argument layouts are incompatible with production bytecode, and payloads are
compiled separately for every variant.

## ARM64 output

These are static measurements from Linux ARM64 cross-compilation, not timings
on ARM hardware. All variants compile the same audit driver. Handler counts
follow the default conditional fallthrough path through one handler and back
to dispatch, including the dispatch header and excluding called helper bodies.
They are not universal best-case or worst-case counts.

| Variant | Dispatch bytes | Header instructions | Header stack stores | Integer add path | Reload path | Call path |
|---|---:|---:|---:|---:|---:|---:|
| Reference | 25,664 | 31 | 11 | 41 | 76 | 71 |
| E-only comparisons | 25,280 | 31 | 11 | 41 | 76 | 71 |
| S-only field reads | 25,668 | 31 | 11 | 41 | 76 | 71 |
| Optional S field reads | 25,904 | 31 | 11 | 41 | 76 | 71 |
| Combined | 25,520 | 31 | 11 | 41 | 76 | 71 |
| No X register | 22,524 | 30 | 10 | 40 | 74 | 69 |

Removing X entirely saves 3,140 bytes, about 12.2%, and one store in the common
dispatch header. Removing its comparison handlers alone saves 384 bytes but
does not change the sampled execution paths. R- and S-based field reads have
the same 93-instruction path in their respective variants.

## Emitted and executed bytecode

Instrumented executables count every opcode dispatched. These executables are
separate from the uninstrumented timing binaries.

All eight existing audit workloads emit the same named instructions and have
the same executed instruction counts under the reference, E-only, optional-S,
combined, and no-X designs. Numeric opcode IDs differ between variants.

The optional S field-read instruction is never selected in these workloads or
the new field workload. Normal field reads currently lower to getter calls.
Each generated getter reads one field and returns it, so retaining the receiver
provides no benefit inside that function. Forcing S adds one move to each such
getter invocation:

| Workload | Reference dispatches | S-only dispatches | Extra dispatches |
|---|---:|---:|---:|
| Particles | 5,788,632 | 6,172,888 | 384,256 |
| Checkout | 6,940,639 | 7,260,639 | 320,000 |
| Recursive tree | 13,512,150 | 14,531,150 | 1,019,000 |

Spill/reload counts remain unchanged in these cases. Receiver affinity should
be revisited alongside direct field lowering, which could keep repeated field
reads in one caller and preserve the receiver across them.

The new source-driven probe covers repeated field updates, map keys and values,
several simultaneously live booleans, boolean calls, short-circuit side effects,
and nested integer/double comparisons including NaN. At 257 iterations, the
boolean workload gives:

| Variant | Executed instructions | Spills and reloads |
|---|---:|---:|
| Reference | 49,426 | 25,823 |
| E-only comparisons | 49,811 | 26,208 |
| Optional S field reads | 49,426 | 25,823 |
| No X register | 51,954 | 27,580 |

E-only comparisons add 0.8% more dispatches in this case. Removing X entirely
adds 5.1% more dispatches and 6.8% more spill/reloads. The other three targeted
workloads have unchanged instruction counts.

## Validation

The combined and no-X variants each pass all 822 tests with the original pinned
dependencies. No-X updates four tests whose machine-level ABI expectations
change. Source behavior remains covered by the existing suite. Additional
checks pass for fresh and serialized entrypoints, four boolean arguments through
exported calls and guest closure callbacks, and false return values.

Both variants pass scoped analysis. The no-X dispatch contains no X local or
instruction referencing register 5. No Flutter benchmarks were run.

## Windows x64 AOT timings

Measurements ran sequentially on the same Ryzen AI Max Pro390 machine, pinned
to logical CPU 2 with AboveNormal priority. Three initial 15-sample audit sweeps
rotated workload order and reversed variant order. Their raw results include
the recurring slow process-start cases. A final 21-sample sweep first ran a
complete untimed three-sample audit process for each variant to warm the CPU.
The following table uses that final sweep. Every measured result matched its
native Dart control.

| Workload | Reference ms | E-only comparisons ms | No X ms |
|---|---:|---:|---:|
| Integer sum | 39.458 | 39.579 | 39.451 |
| Double recurrence | 26.043 | 26.282 | 25.842 |
| Integer mixing | 33.043 | 32.967 | 32.831 |
| Particles | 35.077 | 36.009 | 34.374 |
| Checkout | 34.874 | 35.133 | 34.169 |
| Events | 6.266 | 6.813 | 6.588 |
| Word counting | 29.302 | 30.689 | 28.595 |
| Recursive tree | 97.046 | 100.881 | 98.521 |

The new source workloads ran 100,000 iterations, with fifteen samples each for
native Dart, fresh programs, and serialized programs. The second sweep reversed
variant order and added the same untimed process warmup. These are its fresh
program medians; serialized execution and all raw samples are retained too.

| Workload | Reference ms | E-only comparisons ms | No X ms |
|---|---:|---:|---:|
| Repeated fields and updates | 107.073 | 106.741 | 110.245 |
| Map operations | 40.869 | 41.357 | 41.347 |
| Live booleans and boolean calls | 81.761 | 84.196 | 87.028 |
| Nested numeric comparisons | 66.449 | 66.950 | 66.328 |

Removing X improves some OOP audit cases by about 2%, but events regress about
5%, and the boolean workload regresses about 6% in the warmed repeat. Arithmetic
is mostly unchanged on this x64 host. Removing only the comparison duplicates
does not establish a throughput benefit, and events, word counting, and trees
are slower. The ARM64 code-size improvement should not be interpreted as an
x64 speedup or as a measured ARM64 speedup.

## Decisions from the register experiments

Keep the production register bank and opcode table for this checkpoint.

- Do not force field receivers into S. It adds dispatches to current getters.
- Do not add the optional S field-read opcode yet. The compiler did not select
  it in the measured source workloads. Revisit it with direct field lowering.
- Preserve the E-only and no-X variants as measured alternatives. No-X frees
  36 opcode slots and reduces ARM64 dispatch size by 12.2%, but it has a real
  boolean-pressure cost and mixed x64 results. ARM hardware timings would help
  decide whether that trade is worthwhile for Flutter deployments.

The next experiment fuses numeric comparisons used only by their following
branch. It tests whether eliminating a dispatch is more valuable than changing
boolean register availability alone.

The committed `register-affinity-evidence.zip` contains source snapshots,
variant overlays, test logs, raw timings, executed-opcode counts, ARM64
disassembly, and reconstruction scripts. Local binaries and complete working
trees remain under `.dart_tool/register_affinity_20260916/`.
