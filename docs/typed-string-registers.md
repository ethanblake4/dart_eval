# String register ARM64 experiment

Decision: keep String operands in R/S for the current List/String instruction checkpoint.

Frozen source: d51f120, isolated worktree D:/Projects/dart_eval/.dart_tool/string_probe.
Dart 3.10.7, Windows x64 host, Linux ARM64 AOT cross-compilation, LLVM disassembly.
No ARM64 execution or hardware timing. Production files were not changed.

The existing whole 189-op TypedMachine.run switch was extended with six identical-position cases numbered 189-194: load left String, load right String, length, codeUnitAt, concatenation, export left. Variants use r/s with exact `as String` casts, one added `String u` with s cast, or two added `String u,v`. New locals initialize to the empty string and stay live through dispatch. The probe reads bytecode and arguments from files and retains optional Runtime interop. Experimental metadata was added so normal TypedProgram validation accepts the cases. It is experiment metadata, not production allocator support for u/v.

All three variants passed native-host semantic checks for length, codeUnitAt and concat: 5, 101, hello world. Existing switch/call behavior otherwise comes from the frozen source. Local scripts and binaries remain in that ignored worktree: `.dart_tool/compile-variant.ps1`, `.dart_tool/verify.dart`, and `.dart_tool/{object,one,two}.{aot,asm,symbols}`. The original generated machine is preserved in `.dart_tool/machine.original.txt`. These local artifacts are not included in the commit.

To reproduce independently, use a separate checkout at `d51f120`, append six experimental instruction descriptors to its generated opcode table, and add cases 189–194 to its full generated switch. Keep the added cases at the same positions for all variants. Their bodies are:

| Case | Existing object registers | One typed String local | Two typed String locals |
| --- | --- | --- | --- |
| 189, load left | `r = r as String` | `u = r as String` | `u = r as String` |
| 190, load right | `s = s as String` | `s = s as String` | `v = s as String` |
| 191, length | `a = (r as String).length` | `a = u.length` | `a = u.length` |
| 192, code unit | `a = (r as String).codeUnitAt(b)` | `a = u.codeUnitAt(b)` | `a = u.codeUnitAt(b)` |
| 193, concat | `r = (r as String) + (s as String)` | `u = u + (s as String)` | `u = u + v` |
| 194, export | `r = r` | `r = u` | `r = u` |

Initialize added locals to `''` before dispatch. Build the unchanged file-loading `benchmark/runtime_probe.dart` with `dart compile aot-snapshot --target-os=linux --target-arch=arm64`, then disassemble the `TypedMachine.run` symbol using the existing inspection script's LLVM procedure. The descriptors permit validation of host semantic probes; they do not integrate U/V into the production allocator or calling convention.

| Variant | run start | run end exclusive | run text bytes | frame bytes |
|---|---|---|---|---|
| object | 0x24ff24 | 0x2543f0 | 17612 | 192 |
| one | 0x24ff0c | 0x2544f8 | 17900 | 200 |
| two | 0x24ff00 | 0x25465c | 18268 | 208 |

One local adds 288 bytes, two add 656. This is function symbol text including cold paths, not whole binary size. Both added locals occupy ordinary tagged pointer registers and stack slots. No representation unboxing is gained.

Dispatch header spans object 0x250038-0x2500b4 inclusive, one 0x250018-0x250098, two 0x250014-0x250098. Each includes spill stores, stack-limit check, checked bytecode fetch and jump-table branch. Executed instructions: 32/33/34. Shared backedge is 3 instructions in all variants: object 0x253e74-0x253e7c; one 0x253f7c-0x253f84; two 0x2540e0-0x2540e8. Thus the extra global charge is exactly 1/2 unconditional stores per dispatch in this build. It is not a percentage timing estimate.

Fast successful handler instruction counts below exclude common dispatch/backedge and exclude callee execution. codeUnitAt counts the one-byte String path with an in-range index. Cast error paths are excluded. Counts include handler return branch and restore moves/loads.

| handler | object | one | two |
|---|---|---|---|
| length | 26 | 16 | 17 |
| codeUnitAt | 39 | 29 | 30 |
| concat | 38 | 29 | 19 |

Handler ranges inclusive:
- length: object 0x253c70-0x253ce0; one 0x253e0c-0x253e48; two 0x253f94-0x253fd4.
- codeUnitAt: object 0x253ce4-0x253d94; one 0x253e4c-0x253ec8; two 0x253fd8-0x254058.
- concat: object 0x253d98-0x253e44; one 0x253ecc-0x253f48; two 0x25405c-0x2540a4.

Length full dispatch instruction counts therefore 61/52/54; codeUnitAt 74/65/67; concat 73/65/56 plus callee. Loading u/v requires its own cast and dispatch; exporting u back to r also requires dispatch. A hot scan can amortize that setup, isolated string operations may not. Typed locals do remove repeated type checks, but codeUnitAt still checks bounds and selects one-byte/two-byte storage. All concat versions call the same 128-byte _StringBase.+ body. Allocation/copy cost is outside these counts.

The earlier prototype used String u and String v parameters and proposed dedicated string banks and concat/length/conversion operations (available in Git history before this cleanup). Parameter typing alone does not reserve hardware registers. In this experiment the new typed locals remain live across the whole switch, extending register pressure and forcing more preservation around unrelated calls.

Recommendation: dedicated native String operations on existing object registers are the smaller first step. Revisit one String accumulator if real programs repeatedly scan or manipulate a retained string. Two persistent String locals are harder to justify without string-heavy measurements because both tax unrelated bytecode dispatch. These counts depend on compiler version and case order; they establish the tradeoff, not a universal break-even point or hardware speedup.
