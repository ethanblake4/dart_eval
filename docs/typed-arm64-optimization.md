# ARM64 dispatch and object-call checkpoint

Inspected with Dart 3.10.7 on Windows x64, cross-compiling Linux ARM64.
The main report records the `d51f120` register ABI checkpoint; the List/String
instruction update is recorded at the end. No ARM64
hardware timing was performed. The reference source checkpoint is `5a02f83`.

## Emitted loop

The current probe loads bytecode and every argument bank from files. An optional
reference Runtime keeps evaluated-object and bridge invocation reachable during
AOT compilation. The register ABI runtime has 189 opcodes and named registers `a/b`,
`f/g`, `e/x`, and `r/s/c`.

| Ordinary arithmetic path | Previous primitive runtime | Current object-capable runtime |
| --- | ---: | ---: |
| Header through indirect dispatch | 35 | 32 |
| Integer add handler | 5 | 5 |
| Shared tail | 12 | 3 |
| Complete integer add | 52 | 40 |
| Complete double add | 53 | 40 |
| Stack stores on this path | 11 | 11 |
| Stack loads on this path | 12 | 2 |
| Entire run function, including cold paths | 16,108 bytes | 17,592 bytes |

Stack loads count the header as well as the shared tail. These are host compiler
spills/reloads, separate from bytecode spill instructions. Native instruction
counts are not cycles. The function now implements substantially more behavior,
so its larger total size is not a regression comparison of identical features.
The jump table and separately compiled helpers are outside the function size.

In the final recorded binary, `TypedMachine.run` begins at `0x24feec`, size
`0x44b8`. The repeated header spans `0x250000` through `0x25007c`; the common tail
spans `0x253e24` through `0x253e2c`. The double-add handler at `0x250300` is:

```asm
fadd d2, d1, d0
mov  v1.16b, v2.16b
mov  x3, x14
mov  x10, x9
b    0x253e24
```

Numeric arithmetic still has no dynamic operand dispatch or boxing. The switch
still performs a stack-limit check, bytecode bounds check, redundant negative
opcode check and maximum-opcode check. Together with the indirect jump and two
direct branches, that is seven branch instructions per ordinary add. Most checks
are normally not taken; this does not predict branch misses.

## Changes selected by inspection

- Non-inlined call setup alone reduced the old function from 16,108 to 11,216
  bytes before object support was added. Allocation/copying code no longer
  expands each call case inside the switch.
- Numeric opcode order matters on this SDK. Giving simple register operations
  lower opcode numbers reduced the extra register shuffling introduced by the
  object bank. Merely rearranging source cases without changing their numeric
  values produced identical output.
- Constant-pool accessors stay outside the loop. Inlining their pool bases and
  repeated bounds metadata increased live state and arithmetic-handler copying.
  Signed16 integer immediates avoid this helper boundary for common small values.
- Spill banks are accessed from the frame when needed rather than cached as
  extra loop locals. Primitive operations remain directly in the switch.
- Conditional branches only decode their displacement when taken. The compiler
  starts with signed16 relative branches and widens those that cannot reach to
  absolute32. Short branches occupy three bytes instead of five.
- Redundant reverse primitive comparison forms were removed, making room for
  object instructions while keeping the table below 200.

Several experiments were discarded. ByteData-based immediate decoding increased
the function to about 26 KB and caused severe stack traffic. Explicit `continue`
versus `break` produced the same assembly. The generated loop retains a labeled
continue for direct expression of its dispatch control flow, not as a speed claim.
The restricted third integer register and fused comparisons remain unmeasured.

## Calls and existing objects

Internal calls now pass register arguments directly. Dedicated scalar registers
fill first, then spare object registers hold native scalars or boxed references.
Only excess arguments use a single list in C. The previous four outgoing buffers
and all per-bank argument-load opcodes are gone. A single call opcode replaces
four return-bank call opcodes, and returns no longer check `returnBank`.

A parent caches one child frame. Callees have independent outgoing lists for
recursion, and borrow the parent's list without copying. Numeric spill slots
are initialized by compiler-emitted stores rather than cleared on frame reuse.
Object spills and consumed outgoing lists are cleared to release references.
Host callbacks still receive independent boxed argument snapshots because the
existing bridge API requires lists and permits retention and reentry.

Internal language values are `$Value?`, preserving evaluated-instance identity.
Explicit box/unbox instructions perform compiler-selected conversions. Native
scalars placed in spare object registers use separate raw moves and exact casts.
Conversion at the external host boundary remains necessary. Reference bytecode
adapters use compiler-emitted signature metadata rather than inspecting values.
Typed class construction/method linking and closure creation remain unfinished.

Compared with checkpoint `89eb7d6`, the arithmetic path remains 40 instructions
and the run function shrinks by 2,188 bytes, about 11%. The emitted instruction
table has 189 entries instead of 194. This does not include helper functions or
prove improved cache behavior on ARM hardware.

## Windows x64 timing observations

These are AOT execution measurements on the existing Windows host, not ARM64
results. Both call benchmarks compile their source outside the timed region and
verify checksums. Each iteration includes loop/argument/spill/return work, so
nanoseconds per iteration must not be interpreted as isolated call latency.

At five million iterations and seven samples:

| Workload | Median ms | Min–max ms |
| --- | ---: | ---: |
| `5a02f83` primitive call loop | 1150.441 | 695.908–1538.804 |
| `89eb7d6` primitive call loop | 664.591 | 418.364–810.315 |
| `89eb7d6` mixed object/primitive call loop | 1458.219 | 930.487–1607.632 |
| `89eb7d6` integer dispatch benchmark | 51.518 | 44.103–64.021 |
| `89eb7d6` double dispatch benchmark | 43.916 | 41.471–61.193 |
| `89eb7d6` mixed dispatch benchmark | 97.345 | 93.151–157.139 |

The register ABI run, also five million iterations and seven samples, produced:

| Workload | Median ms | Min-max ms |
| --- | ---: | ---: |
| Register ABI primitive call loop | 492.983 | 381.712-720.593 |
| Register ABI mixed object/primitive call loop | 1245.398 | 968.621-1985.247 |

The checksum was 157522500. These were separate runs under variable host load,
so the lower medians are not a controlled speedup comparison.

Earlier one-million-iteration runs had overlapping ranges and inconsistent
rankings. The large spread prevents a reliable call-speedup claim. Structural
allocation improvements and the ARM64 instruction reduction are established;
stable timing and hardware cache/branch measurements remain necessary. The tiny
object-reference dispatch benchmark covers only a subset of the full switch and
is not representative of the existing full interpreter.

## Reproduce

From the repository root, using LLVM tools that support AArch64:

```powershell
.\tool\inspect_typed_arm64.ps1 -Objdump 'C:/Program Files/LLVM/bin/llvm-objdump.exe' -Objcopy 'C:/Program Files/LLVM/bin/llvm-objcopy.exe'
dart compile exe benchmark/typed_calls.dart -o .dart_tool/typed_calls.exe
.dart_tool/typed_calls.exe 5000000 7
dart compile exe benchmark/typed_dispatch.dart -o .dart_tool/typed_dispatch.exe
.dart_tool/typed_dispatch.exe 5000000 7
```

The script writes the snapshot, symbols and disassembly under `.dart_tool/arm64`.
It strips symbols only from a separate inspection copy, because AOT mapping
symbols can make LLVM print executable instructions as `.word`. Addresses can
change between SDKs and entry points. The original baseline and intermediate
experiment artifacts are retained locally under `.dart_tool`.

Validation reports zero analyzer errors and the full suite with 581 passes,
six skips, and the same 30 reference-backend failure names listed in
backend-checkpoint-failures.txt. Tests include mixed recursive calls, three-object
phi cycles, overflow lifetime, explicit bridge semantics, signed branch endpoints,
branch widening over 12,000 calls, serialization, and invalid input rejection.

## List and String instructions

Ten reverse commutative forms were replaced with ten List/String operations,
leaving the table at 189 entries. The compiler can reverse integer/boolean input
placement while emitting the same opcode, and preserves floating operand order.

The new whole-loop symbol is 19,256 bytes, up from 17,592 at `d51f120`, because
String/List handlers need casts, indexing checks and method/allocation code.
The ordinary add path has 39 instructions: 32 in dispatch, five in the handler,
and two in the common tail. It still performs 11 stack stores and two stack loads.
One handler instruction now loads a constant-pool value where the earlier layout
moved a register. Fewer instructions does not imply fewer cycles.

Recorded `TypedMachine.run` range: `0x24ffcc` to `0x254b04` exclusive.
Dispatch: `0x2500e0` through `0x25015c`. Integer add: `0x2502f0` through
`0x250300`. Double add: `0x25037c` through `0x25038c`. Shared tail:
`0x254584` through `0x254588`. Addresses depend on the full probe and SDK.

A Windows x64 AOT smoke benchmark at one million iterations, three samples,
produced typed medians of 11.566 ms integer, 11.060 ms double, and 11.735 ms mixed.
Ranges were 11.383-11.603, 10.124-11.407, and 11.295-12.511 ms. Checksum:
544359285. These are independent host runs, not a controlled speedup comparison.

The separate [String-register experiment](typed-string-registers.md) measures the
cost of adding one or two String locals to a frozen full dispatch loop. Each adds
one unconditional stack store per dispatch. The production update keeps Strings
in existing object registers and supplies dedicated operations on them.

Validation after the List/String update: 594 passes, six skips, 29 existing
reference failures, zero analyzer errors. The regex replacement loop now passes.
The updated failure baseline is backend-checkpoint-failures.txt.

## Native class checkpoint

The 196-opcode loop supports linked class construction, field storage, lexical
superclass access and register-ABI virtual calls. A first ARM64 build increased
the arithmetic path to 43 instructions. Dart hoisted class and call-site table
bases and lengths into the loop, requiring six loads in the common tail.

Class construction now stays behind a non-inlined constructor. Call-site indexing
happens inside the non-inlined dispatch resolver and bridge fallback. Resolved
members hold the immutable function descriptor directly, avoiding another indexed
lookup on every invocation. The table bases and lengths no longer remain live
across every bytecode. The public export adapter is outside `runRaw`, so internal
returns retain their compiler-selected representation.

Using the same Dart 3.10.7 Linux ARM64 probe, the final arithmetic path has 38
instructions: 32 dispatch, four integer/double add, and two common tail. It still
has 11 stack stores and two stack loads. The previous List/String checkpoint had
39 instructions. The full loop is 19,700 bytes, up 444 bytes from 19,256.
These are static native-code measurements, not ARM64 cycle or cache measurements.

Recorded `TypedMachine.runRaw` range is `0x140690` to `0x145384` exclusive.
Dispatch runs from `0x1408d8` through `0x140954`; integer add from `0x140a90`
through `0x140a9c`; double add from `0x140b00` through `0x140b0c`; common tail
from `0x144e24` through `0x144e28`. The inspection script now selects `runRaw`.

Same-program ordinary virtual calls perform cached member resolution and enter
a frame in this loop. They do not construct an argument list when receiver and
arguments fit R/S/C, nor inspect values to decide boxing. Overflow borrows the
caller's existing list. Resolution, initial member-cache population, frame entry
and return still cost work. Alternating functions can replace the single cached
child frame. Bridge calls, bound tear-offs and scalar operator adapters remain
separate host invocation paths.

The expanded `typed_calls.dart` benchmark verifies checksums for class mutation,
alternating receiver classes at one call site, arbitrary boxed arguments and
overflow. Windows x64 AOT, one million iterations and five samples, after the
full test run completed:

| Workload | Median ms | Min to max ms |
| --- | ---: | ---: |
| Primitive direct call | 88.717 | 84.997 to 109.279 |
| Mixed object/primitive direct call | 194.072 | 170.170 to 288.638 |
| Class method with field mutation | 570.560 | 482.156 to 861.287 |
| Alternating receiver classes | 289.809 | 271.368 to 291.109 |
| Boxed object arguments | 325.081 | 303.176 to 383.399 |
| Four integer method arguments | 460.470 | 347.680 to 477.528 |

Checksum: `5000085080000`. An odd-count 1,001-iteration smoke run also passes.
These workloads include different method bodies and dispatch patterns, so their
timings are not comparable as isolated call latencies. Host variability remains
large, including across successive runs. Use them as reproducible workloads for
future controlled profiling, not as evidence of a speedup over the prior commit.

Final validation: 624 passes, six skips, 28 existing reference failure names,
zero analyzer errors, generated files current. The earlier Functional test 1
failure now passes. Class tests include serialization and inheritance; boundary
tests cover callable fields and bridge method overrides.

## Export API integration

Map binding and host conversion now prepare a `TypedEntry` outside the switch.
The production loop is `TypedMachine.runEntry`; `runRaw` and `run` delegate to
it after preparing arguments. No export metadata or argument-map lookup is live
inside the loop. No opcodes or registers were added, leaving 196 opcodes and
60 byte values for future intrinsics.

With Dart 3.10.7 and the full Linux ARM64 probe, integer/double add still takes
38 instructions: 32 dispatch, four handler, two common tail. Stack traffic stays
at 11 stores and two loads on this path. The loop symbol is 19,368 bytes, down
332 bytes from the class checkpoint because entry preparation moved out of the
function. This does not measure total boundary cost or ARM64 execution time.

Recorded range: `0x17ad94` to `0x17f93c` exclusive. Dispatch:
`0x17ae90` through `0x17af0c`. Integer add: `0x17b048` through `0x17b054`.
Double add: `0x17b0b8` through `0x17b0c4`. Common tail:
`0x17f3dc` through `0x17f3e0`. The inspection script selects `runEntry`.

The public API and existing suite now use the typed backend exclusively.
Validation: 416 passes, 263 failures in unfinished compiler/runtime features,
six skips, zero analyzer errors. Export binding, codec and host identity tests
pass. See [the migration baseline](typed-migration-failures.md) for failed names
and their first reported errors. No speedup is claimed from these code counts.

## External bridge checkpoint

`callExternal` resolves its descriptor inside a non-inlined helper. Generated
bridges consume R/S/C directly, while legacy registrations receive a snapshot
list. `rBridgeArgument` is an explicit nullable-argument conversion emitted by
the compiler. No new permanent registers or loop-wide metadata tables were added.
There are 198 opcodes, leaving 58 byte values available for future intrinsics.

The final Dart 3.10.7 Linux ARM64 probe retains both legacy callbacks and direct
register callbacks. Its arithmetic path is unchanged at 38 instructions: 32
dispatch, four integer/double add and two common tail, with 11 stack stores and
two stack loads. The loop occupies 19,600 bytes, up 232 from the export checkpoint.

Recorded `TypedMachine.runEntry` range: `0x13f1f8` to `0x143e88` exclusive.
Dispatch: `0x13f2f4` through `0x13f370`. Integer add: `0x13f4ac` through
`0x13f4b8`. Double add: `0x13f51c` through `0x13f528`. Common tail:
`0x143920` through `0x143924`. These are static instruction counts, not ARM64
execution timings or an isolated measurement of external-call latency.

`benchmark/typed_external_calls.dart` executes identical bytecode with either
registration path. Its loop passes opaque object references and verifies identity
inside the callback; compilation and runtime construction are outside timing.
Windows x64 AOT, one million iterations, five samples, final standalone run:

| Arguments | Registration | Median ms | Min to max ms |
| --- | --- | ---: | ---: |
| 3 | Legacy list | 223.797 | 107.724 to 268.513 |
| 3 | Registers | 102.493 | 95.243 to 107.629 |
| 6 | Legacy list | 423.709 | 239.808 to 670.144 |
| 6 | Registers | 201.612 | 197.635 to 234.446 |

Checksum: `10000120110000`. An odd-count 1,001-iteration smoke run also passes.
Host variability is too large to attribute these timing differences to this
change: an earlier run measured 101.003/99.158 ms for three arguments and
246.772/432.720 ms for six. Direct callbacks avoid argument-vector allocation by
construction, but a throughput improvement has not been established.

Full validation: 514 passes, 185 failures, six skips, zero analyzer errors and
generated files current. Of the failures, 184 are unfinished compiler/runtime
features; `Future.delayed` exceeds its 200 ms full-suite timing threshold but
passes in isolation. 77 formerly failing tests now pass in the full run, with
no regressions among previously passing tests. See the current migration report.

## Closure checkpoint

Closures add six instructions and a frame environment field. The exact-call
handler resolves a same-program closure, then enters its frame in the existing
switch. Signature lookup and capture loads use non-inlined helpers. No new
registers are live across arithmetic dispatch. There are 204 opcodes and 52
unused byte values.

The final Dart 3.10.7 Linux ARM64 probe has the same 38-instruction arithmetic
path: 32 dispatch, four integer/double add and two common tail. Stack traffic
remains 11 stores and two loads. `TypedMachine.runEntry` occupies 20,548 bytes,
948 more than the external-call checkpoint.

Recorded range: `0x152834` to `0x157878` exclusive. Dispatch: `0x152950` through
`0x1529cc`. Integer add: `0x152b08` through `0x152b14`. Double add:
`0x152b78` through `0x152b84`. Common tail: `0x1572f8` through `0x1572fc`.
These are static counts, not ARM64 execution timings.

`benchmark/typed_closures.dart` compiles source before timing and constructs
closures outside its interpreted loop. Every workload checks its result.
Windows x64 AOT, one million iterations, five samples:

| Workload | Calls per iteration | Median ms | Min to max ms |
| --- | ---: | ---: | ---: |
| Direct source function | 1 | 60.361 | 60.179 to 129.428 |
| Exact noncapturing closure | 1 | 134.062 | 133.304 to 142.444 |
| Shared mutable sibling captures | 2 | 405.396 | 308.450 to 475.158 |
| Closure with four arguments | 1 | 470.917 | 435.108 to 494.820 |
| Closure using named default | 1 | 776.739 | 753.009 to 811.938 |

Checksum: `90090000`. An odd 1,001-iteration smoke run gives `108018`.
The shared-capture case alternates two callees and therefore replaces the single
cached child frame. The default case uses the allocating signature adapter.
These workloads do different work, and repeated runs have varied substantially.
They establish reproducible profiling cases, not an isolated closure-call cost
or a reliable speedup over earlier checkpoints.

Full validation: 606 passes, 151 failures, six skips, zero analyzer errors,
generated files current. 34 formerly failing tests now pass; no previously
passing test regressed. 150 errors concern unfinished features and the remaining
failure is the existing Future.delayed timing threshold, passing in isolation.
The closure contract and next checkpoint are saved in [typed-closures.md](typed-closures.md).

## Global storage checkpoint

Eight typed global load/store instructions bring the table to 212 entries,
leaving 44 byte values. Their helpers access per-runtime values and initialization
flags. They do not add permanent register variables or keep a globals table live
across arithmetic dispatch. Initializer execution uses a separate VM invocation
on the first read; subsequent reads use the initialized value directly.

Dart 3.10.7, full Linux ARM64 probe: the integer/double add path remains 38
instructions, consisting of 32 dispatch, four handler and two common tail.
Stack traffic stays at 11 stores and two loads. `TypedMachine.runEntry` occupies
21,800 bytes, up 1,252 from the closure checkpoint.

Recorded range: `0x167344` to `0x16c86c` exclusive. Dispatch: `0x167488` through
`0x167504`. Integer add: `0x167640` through `0x16764c`. Double add:
`0x1676b0` through `0x1676bc`. Common tail: `0x16c2ac` through `0x16c2b0`.
These are static code measurements, not ARM64 timings.

`benchmark/typed_globals.dart` compares a local accumulator with an initialized
native integer global and an object-global workload. It compiles before timing,
uses independent runtimes and verifies that each lazy initializer runs once.
Windows x64 AOT, one million iterations and five samples:

| Workload | Median ms | Min to max ms |
| --- | ---: | ---: |
| Local accumulator | 44.765 | 43.757 to 46.309 |
| Integer global read/write | 50.560 | 47.159 to 63.149 |
| Object globals and identity | 360.113 | 250.042 to 370.322 |

Checksum: `37537530`. A 1,001-iteration smoke run gives `45025`. The object
workload performs more global accesses and branching than the scalar workloads.
These results are profiling baselines, not an isolated measurement of global
access cost. Cross-runtime ownership adds a reference to each evaluated instance
and a runtime identity check to direct method resolution.

See [the global checkpoint](typed-globals.md) for semantics and saved next steps,
and [the migration report](typed-migration-failures.md) for full-suite results.
