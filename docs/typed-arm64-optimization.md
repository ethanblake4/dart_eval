# ARM64 dispatch and object-call checkpoint

Inspected with Dart 3.10.7 on Windows x64, cross-compiling Linux ARM64. No ARM64
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

| Workload | Median ms | Min�max ms |
| --- | ---: | ---: |
| Register ABI primitive call loop | 492.983 | 381.712�720.593 |
| Register ABI mixed object/primitive call loop | 1245.398 | 968.621�1985.247 |

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
