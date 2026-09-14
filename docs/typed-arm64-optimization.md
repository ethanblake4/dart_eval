# ARM64 dispatch and object-call checkpoint

Inspected with Dart 3.10.7 on Windows x64, cross-compiling Linux ARM64. No ARM64
hardware timing was performed. The reference source checkpoint is `5a02f83`.

## Emitted loop

The current probe loads bytecode and every argument bank from files. An optional
reference Runtime keeps evaluated-object and bridge invocation reachable during
AOT compilation. The final runtime has 194 opcodes and named registers `a/b`,
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
| Entire run function, including cold paths | 16,108 bytes | 19,780 bytes |

Stack loads count the header as well as the shared tail. These are host compiler
spills/reloads, separate from bytecode spill instructions. Native instruction
counts are not cycles. The function now implements substantially more behavior,
so its larger total size is not a regression comparison of identical features.
The jump table and separately compiled helpers are outside the function size.

In the final recorded binary, `TypedMachine.run` begins at `0x250068`, size
`0x4d44`. The repeated header spans `0x250128` through `0x2501a4`; the common tail
spans `0x254688` through `0x254690`. The double-add handler at `0x250428` is:

```asm
fadd d2, d1, d0
mov  v1.16b, v2.16b
mov  x5, x14
mov  x4, x3
b    0x254688
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

Internal calls borrow the suspended caller's typed/object outgoing buffers as
read-only arguments. Callees have independent outgoing buffers, including under
recursion. A parent caches one child frame; consecutive calls to the same function
at that depth reuse its storage. This removes the old temporary sublists,
argument copies and repeated frame allocations for those calls. A different
callee replaces the cached child. Entry storage still copies user argument lists.

All registers are caller-clobbered; numeric registers need not be zeroed after
calls. Spills and outgoing storage reset on frame reuse. Inactive object spills
and consumed object argument buffers are cleared to release references. Host
calls take an independent argument snapshot before clearing outgoing storage, so
callbacks can retain their arguments or reenter safely.

Objects are existing Dart/$Value/$Instance references, not a new object model.
The supplied Runtime initializes itself and dispatches through its existing
method/bridge machinery. Tests exercise a real evaluated class instance, a custom
$Instance, $Function callbacks, primitive wrappers and reentrant calls. Newly
compiled typed class construction/method linking and closure creation remain
unfinished; existing evaluated method offsets belong to the supplied Runtime.

## Windows x64 timing observations

These are AOT execution measurements on the existing Windows host, not ARM64
results. Both call benchmarks compile their source outside the timed region and
verify checksums. Each iteration includes loop/argument/spill/return work, so
nanoseconds per iteration must not be interpreted as isolated call latency.

At five million iterations and seven samples:

| Workload | Median ms | Min–max ms |
| --- | ---: | ---: |
| `5a02f83` primitive call loop | 1150.441 | 695.908–1538.804 |
| Current primitive call loop | 664.591 | 418.364–810.315 |
| Current mixed object/primitive call loop | 1458.219 | 930.487–1607.632 |
| Current integer dispatch benchmark | 51.518 | 44.103–64.021 |
| Current double dispatch benchmark | 43.916 | 41.471–61.193 |
| Current mixed dispatch benchmark | 97.345 | 93.151–157.139 |

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

Validation includes 79 focused tests, zero analyzer errors, and the full suite
with 564 passes, six skips, and the same 30 reference-backend failures listed in
backend-checkpoint-failures.txt. Tests cover mixed recursive calls, three-object
phi cycles, buffer lifetime, bridge semantics, signed branch endpoints, branch
widening over 5,500 calls, serialization, and invalid input rejection.
