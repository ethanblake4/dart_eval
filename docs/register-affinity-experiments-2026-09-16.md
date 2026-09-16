# Register affinity experiments

This report records the experiments before promotion. The subsequent
[production checkpoint](register-branch-checkpoint-2026-09-16.md) adopts no X,
full numeric fusion, and direct short-circuit conditions.

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
| Fused full | E-only comparisons plus all twelve numeric fused branches and short forms | 255 |
| Fused integer less-than | Reference plus integer `<` branch and short form | 245 |
| No X plus fused full | No-X register bank plus all twelve fused branches and short forms | 231 |

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

## Fused comparisons and branches

The fusion pass runs before register allocation. It replaces an adjacent pure
numeric comparison and final false-branch only when the comparison result has
one definition and one use across the entire function, including phi inputs.
It validates both CFG successors. Materialized booleans remain available to
their other users. A fused floating comparison branches on `!(left < right)`
where appropriate, preserving unordered NaN semantics rather than substituting
`left >= right`.

All three fused variants pass **839 tests**, including seventeen additional
cases for comparison semantics, serialization, NaN/infinities, nested branches,
loop backedges, reused booleans, side effects, exceptions, wide branch targets,
and six boolean parameters through calls.

| Variant | ARM64 dispatch bytes | Header instructions | Integer add path | Fused short `<` path |
|---|---:|---:|---:|---:|
| Reference | 25,664 | 31 | 41 | 121 across two dispatches |
| Fused integer less-than | 25,804 | 31 | 39 | 80 |
| Fused full | 30,676 | 31 | 39 | 85 |
| No X plus fused full | 27,524 | 30 | 38 | 78 |

The reference pair consists of a 44-instruction comparison path and a
77-instruction short-branch path under the same counting convention. The
limited variant adds only 140 native bytes, about 0.5%, and two opcodes. It
leaves eleven primary opcode slots available. The full variant leaves one;
combining the full family with no X leaves twenty-five.

The integer-sum loop drops from eleven bytecodes per iteration to ten, reducing
executed instructions from 22,000,011 to 20,000,010. Double recurrence drops from
14,000,011 to 13,000,010; integer mixing from 18,000,011 to 17,000,010. Full fusion
also eliminates another 128,000 comparisons in particles and 15,000 in checkout
compared with the limited variant. Tree traversal has few eligible numeric
branches, so its instruction count barely changes.

These warmed audit sweeps use twenty-one samples, reverse variant order, and
rotate workload order. Each cell lists the two run medians in milliseconds.

| Workload | Reference | Fused integer `<` | Fused full | No X plus fused full |
|---|---:|---:|---:|---:|
| Integer sum | 38.115 / 38.901 | 35.917 / 36.148 | 35.546 / 35.659 | 35.593 / 35.019 |
| Double recurrence | 25.235 / 25.636 | 24.130 / 24.247 | 23.898 / 24.032 | 23.822 / 23.605 |
| Integer mixing | 31.720 / 32.557 | 31.169 / 31.176 | 30.753 / 31.018 | 30.264 / 30.831 |
| Particles | 34.181 / 34.220 | 34.241 / 34.610 | 34.289 / 34.107 | 33.771 / 33.580 |
| Checkout | 33.800 / 33.845 | 33.617 / 33.767 | 33.570 / 33.425 | 33.104 / 33.435 |
| Events | 6.131 / 6.144 | 6.270 / 6.413 | 6.910 / 6.428 | 6.316 / 6.113 |
| Word counting | 28.886 / 29.075 | 28.636 / 28.755 | 28.984 / 28.820 | 29.495 / 29.134 |
| Recursive tree | 95.361 / 96.371 | 97.111 / 99.569 | 97.310 / 100.533 | 95.840 / 95.189 |

The targeted source workloads used two warmed fifteen-sample sweeps, also in
opposite variant orders. These are fresh-program medians in milliseconds.

| Workload | Reference | Fused integer `<` | Fused full | No X plus fused full |
|---|---:|---:|---:|---:|
| Fields | 103.173 / 105.445 | 104.191 / 106.337 | 112.204 / 106.951 | 104.425 / 104.485 |
| Maps | 39.925 / 40.630 | 40.806 / 40.441 | 39.908 / 40.096 | 39.228 / 39.316 |
| Booleans and calls | 81.143 / 81.279 | 80.757 / 82.114 | 81.515 / 82.586 | 84.255 / 83.287 |
| Nested comparisons | 65.454 / 65.510 | 64.292 / 64.952 | 63.892 / 65.538 | 63.041 / 62.986 |

Fusion is a stronger optimization target than register redistribution alone.
The limited variant repeatedly improves integer sum by 6–7% and double
recurrence by 4–5%. Adding the full family without removing X does not justify
its much larger dispatch and near-exhausted opcode budget on these workloads.
It also retains the cost of losing the ordinary X-targeted comparisons.

No X plus full fusion gives the strongest arithmetic results: integer sum
improves 7–10%, double recurrence 6–8%, and integer mixing about 5%. Most OOP
results are close to baseline or modestly better, but the boolean-heavy workload
remains 2.5–4% slower. The limited variant retains the existing ABI but events
and tree traversal are a few percent slower in these runs. The counts establish
the dispatch saving; the mixed broader results still matter.

Production remains unchanged. My next implementation candidate is the limited
fused branch, with the event/tree regressions investigated before promotion.
The no-X/full-fusion variant is worth an ARM hardware comparison because it
combines fewer dispatches with one fewer saved register, but static ARM64 counts
alone cannot settle its wider performance tradeoff.

A further extension handles one intervening logical-not by swapping the two
branch destinations. It adds no opcodes. The variant retaining X with only fused
integer `<` passes 846 tests; the no-X/full-family variant passes 857, including
negated floating comparisons with NaN. Both analyzers are clean. All eight audit
payloads and the complete affinity bytecode are byte-identical to their parent
variants, so there was no reason to repeat timings. Explicit
`if (!(a < b))` exercises the extension; the measured workloads do not.

This also identifies an IR opportunity. The frontend introduces a logical-not
for `||`, but short-circuit expressions often retain their left operand as part
of the expression result. That additional use correctly prevents this local
fusion. Lowering condition-only expressions directly to control flow could
avoid those boolean values and phi inputs, making more comparisons eligible.
That is a separate compiler change, rather than a reason to weaken the safety
check or add more opcode variants.

The committed `register-affinity-evidence.zip` contains source snapshots,
variant overlays, test logs, raw timings, executed-opcode counts, ARM64
disassembly, and reconstruction scripts. Local binaries and complete working
trees remain under `.dart_tool/register_affinity_20260916/`.
