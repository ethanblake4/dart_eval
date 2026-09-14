# Typed dispatch baseline

Measured on 2026-09-13 with Dart 3.10.7, Windows x64, AMD Ryzen AI Max Pro 390 (12 cores, 24 logical processors). This is an initial scalar dispatch experiment, independent of frontend compilation. No ARM measurement is available.

The generated machine has 152 real instructions and six scalar locals: two integers, two doubles, and two booleans. Bytecode is a `Uint8List`; constants and spills use separate typed banks. Instructions select fixed operands and destinations. The loop does not allocate operand lists or decode instruction objects.

Each workload ran 5,000,000 iterations in seven timed samples after twelve warmup runs of 100,000 iterations per implementation. Every result was checked and consumed. Integer sums a descending counter; double accumulates 0.25; mixed XORs the counter and accumulates 0.25. Integer and double execute four bytecodes per iteration, mixed five.

| Workload | Implementation | Median ms | Min–max ms | Median ns/iteration |
| --- | --- | ---: | ---: | ---: |
| Integer | Native Dart | 1.418 | 1.384–1.787 | 0.28 |
| Integer | Typed switch | 42.383 | 35.929–60.625 | 8.48 |
| Integer | Object reference | 44.614 | 40.871–66.475 | 8.92 |
| Double | Native Dart | 2.145 | 2.093–2.447 | 0.43 |
| Double | Typed switch | 38.146 | 36.997–41.528 | 7.63 |
| Double | Object reference | 46.242 | 44.394–58.895 | 9.25 |
| Mixed | Native Dart | 2.177 | 2.075–2.394 | 0.44 |
| Mixed | Typed switch | 49.739 | 45.267–57.943 | 9.95 |
| Mixed | Object reference | 57.876 | 55.497–67.848 | 11.58 |

The typed medians were about 1.05–1.21 times faster than the object reference in this run, with overlapping sample ranges. An earlier run gave 1.20–1.46 times. These are noisy local measurements, not a general speedup claim. Native Dart remains roughly 18–30 times faster in the recorded run. Dispatch still dominates these small operations.

The object reference uses the same byte encoding and an `Object?` register list, with a smaller switch containing only the workload instructions. It does not allocate decoder objects. It is a comparison kernel, not the project's existing generic register runtime. The full 152-instruction typed switch prevents an artificially tiny typed dispatch benchmark, but AOT can still specialize other parts of the program.

## Reproduction

Run from the repository root in PowerShell:

```powershell
dart run tool/generate_typed_machine.dart --check
dart test test/typed_machine_test.dart
dart compile exe benchmark/typed_dispatch.dart -o .dart_tool/typed_dispatch.exe
& ./.dart_tool/typed_dispatch.exe 5000000 7
dart compile aot-snapshot benchmark/typed_dispatch.dart -o .dart_tool/typed_dispatch.aot
& 'C:/Program Files/AMD/ROCm/6.2/bin/llvm-objdump.exe' --disassemble-symbols=TypedMachine.run --no-show-raw-insn .dart_tool/typed_dispatch.aot
```

## Assembly findings and limits

The inspected AOT snapshot contains a jump-table dispatch (`jmpq *%r11`) for the dense opcode range. Floating arithmetic uses scalar `addsd`, `subsd`, `mulsd`, and `divsd` instructions. Integer arithmetic uses raw integer machine operations. Spill arrays are allocated at entry, and boxed return values have allocation paths at the external boundary. The inspected `TypedMachine.run` symbol occupied 11,944 bytes; the smaller object-reference kernel occupied 2,416 bytes.

Typed locals do not guarantee permanent hardware register residency. At the common dispatch header, Dart stores both integer locals and both double locals to stack slots before its stack-limit/safepoint check. Those stores occur per dispatch and are an explicit cost of this implementation. The machine avoids an object register file for scalar operations, but it does not eliminate compiler-generated stack stores.

All timed programs have zero spill slots and use only the integer argument bank. Whole-program AOT analysis can specialize those paths, including constant zero spill lengths. Unit tests cover typed spills and all argument banks, but the timing and assembly above do not establish their performance in a general runtime. Calls, objects, exceptions, frontend-generated code, and broader application workloads require separate measurements.

The deterministic generator check and 18 machine tests pass. Targeted analysis of the generator, generated runtime, benchmark, and tests reports no issues.
