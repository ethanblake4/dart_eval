# Typed backend implementation

The user approved implementation on 2026-09-13. This supersedes the pause and
generic-runtime-first order in backend-checkpoint.md. Commit and push each
verified stage in both repositories. Preserve the adjacent package's unrelated
working-tree fixture edits.

## Requirements

The production dispatch loop uses a dense integer switch over bytecode and named,
non-nullable typed scalar registers. Arithmetic handlers must not decode register
arrays, recover operand types, allocate instruction objects, or call generic
arithmetic helpers. Fixed operand and destination combinations are encoded in
the opcode. The existing general-object register machine is a semantic reference
while the typed backend reaches parity.

The register bank has two integer, two double, two boolean, and three general
object registers. Strings and nullable values use the object bank alongside
existing $Instance and $Value objects. Restricted loop registers and instruction
fusion still need measurement. Spills use typed backing storage. Language types, wrapper
objects, and machine representations must remain distinct. Representation changes
are explicit at SSA definitions, phi edges, calls, and suspension boundaries.

## Stages

1. Generate a scalar runtime, opcode metadata, and encodings from one instruction
   description. Verify arithmetic, comparisons, branches, and typed spills with
   execution tests. Establish native Dart and object-register baselines, compile
   AOT, inspect native output, and record reproducible commands and limitations.
2. Make constrained allocation preserve ordered duplicate operands, respect
   register groups and clobbers, and spill live values instead of dropping them
   when destructive instructions need an occupied register. Verify with execution
   tests under two-register pressure and across control-flow edges.
3. Connect frontend SSA representations to the compact backend. Start with explicit
   primitive signatures, arithmetic, branches, loops, and direct calls. Reject
   unsupported operations explicitly. Test source-to-execution and serialization,
   including recursion, spills, and reverse operand order.
4. Add remaining representations and runtime operations with explicit call,
   exception, closure, bridge, and suspension conventions. Resolve the existing
   semantic failures against the typed backend before declaring parity.
5. Tune instruction selection, register counts, spill placement, compact branch
   encodings, and fused instructions using measured workloads. Preserve generated
   assembly and benchmark evidence when changing the hot loop.

## Validation principles

Run AOT performance tests separately from JIT. On Dart 3.10.7 the switch selection
code explicitly limits optimized jump-table selection to AOT. Small synthetic
switches do not reproduce the deployment dispatch function. Record SDK, target,
iterations, timing spread, code size, and benchmark checksums. A zero-allocation
claim must distinguish arithmetic dispatch from run entry, spilling, calls, and
return boxing. An unavailable platform is an unmeasured platform.

New package allocation tests must check executed results and live-value survival.
Do not refresh the preexisting package golden strings merely to silence failures.

## Implemented checkpoints

- `c074333`: generated scalar switch and reproducible AOT baseline. Results and
  native-code limitations are in typed-dispatch-baseline.md.
- Package `8afe791`: ordered duplicate operands, operation-specific variants and
  clobbers, constrained spilling, graph cloning, and SSA metadata rebuilding.
- Package `0436280`: carry resident registers across linear block boundaries.
- Package `104c802`: execution stress tests for clobbers, phi swaps, and joins.

The primitive compiler/call checkpoint is `5a02f83`. The current checkpoint
extends that pipeline with three object registers and tunes dispatch/calls using
ARM64 AOT output. See [the assembly and timing report](typed-arm64-optimization.md).

## Current runtime and compiler

`Compiler.compileTyped` lowers reachable direct functions from SSA to fixed
register operands. Numeric registers remain typed Dart locals; object registers
`r/s/c` hold arbitrary references. Spills use separate numeric and object banks.
The generator emits 194 instruction forms, prioritizing simple operations in
opcode order. It removes redundant reversed primitive comparisons, supplies
signed16 integer immediates, and emits short relative branches with automatic
absolute32 widening. Conditional branches decode their target only when taken.

Calls clobber all nine registers. Their previous values are unspecified, and the
allocator spills caller values that remain live. Numeric locals are not reset
on every call; object locals are cleared to avoid retaining dead references.
Arguments are separated by bank, not restricted to numeric values. An internal
callee borrows the suspended caller's outgoing buffers read-only. It owns its
own spill/outgoing buffers, so recursion cannot overwrite its arguments. One
cached child per call depth removes repeated allocation for consecutive calls to
the same function. Calls to a different function replace that cached child.
Spills/outgoing storage starts empty on reuse, and consumed object arguments and
inactive object spills are cleared. Host calls receive independent argument
snapshots because a callback may retain its list or reenter the runtime.

Source support includes the previous numeric/control-flow subset plus object,
string, nullable and dynamic parameters/results, object identity through SSA
phis and calls, object equality, positional callbacks and dynamic method calls.
Interop reuses `Runtime`'s existing invocation path, including `$InstanceImpl`,
`$Instance`, `EvalCallable`, and bridge wrappers. It never blindly unwraps an
`$InstanceImpl`. Pass an existing matching `Runtime` as `runtime:` when invoking
its evaluated/bridge objects. Raw Dart functions can be called without it.
Arbitrary host object methods still require the existing wrapping/bridge setup.

```dart
final program = Compiler().compileTyped({
  'example': {'main.dart': 'Object main(Object value) => value;'},
}, entrypoint: 'package:example/main.dart');
final object = Object();
assert(identical(TypedMachine.run(program, objectArguments: [object]), object));
```

Typed codec version 103 intentionally rejects version 102 bytecode, because
opcode numbering and frame layout changed. It serializes scalar/null/string
object constants, preserving UTF-16 code units and numeric bits. Live application
objects remain valid arguments/in-memory constants but are rejected by the codec
rather than being serialized into a lossy replacement.

`compile` still uses the reference backend. Creating typed classes, collections
and closures, named callback arguments, exception handling and async/suspension
remain unfinished. Existing evaluated method offsets refer to the supplied
reference Runtime; this checkpoint does not link newly compiled typed class
methods. The new bridge path is compatibility plumbing, not full typed parity.

## Checkpoint and next work

Validation: 79 focused tests pass; full suite 564 passes, 30 existing reference
failures, six skips. Analysis has zero errors. This checkpoint changes dart_eval
only; control_flow_graph remains at `104c802`, with the user's fixture edits
untouched. The full-suite failures match backend-checkpoint-failures.txt.

The runtime probe and PowerShell disassembly script reproduce ARM64 inspection.
The arithmetic path is 40 native instructions versus 52 at `5a02f83`, despite the
added object bank and interop paths. This is an instruction count, not an ARM64
speedup measurement. The host benchmarks are Windows x64 and show substantial
run-to-run noise; their raw ranges are in the report.

Next useful work is typed class/method linking and closure/exception conventions,
plus instruction selection that reduces conservative loop/join spills. Measure
restricted `%l` and fused comparisons before spending more opcode space. The
194-case layout stays below 200 today; expanding symmetric families indiscriminately
would consume the remaining space. Preserve the current ARM64 probe and compare
both numeric and object/call workloads after each change.
