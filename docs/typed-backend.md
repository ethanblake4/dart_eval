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
The generator emits 189 instruction forms, prioritizing simple operations in
opcode order. It removes redundant reversed primitive comparisons, supplies
signed16 integer immediates, and emits short relative branches with automatic
absolute32 widening. Conditional branches decode their target only when taken.

Calls clobber all nine registers. The allocator assigns all call arguments
simultaneously, resolves permutations, and saves caller values that remain live.
The callee receives register parameters without argument-load instructions.

The complete signature determines argument locations, including unused parameters:

- The first two integers use A/B, doubles F/G, and booleans E/X.
- Remaining parameters, including excess native scalars, use R/S/C in source order.
- If more than three parameters need object registers, the first two use R/S and
  C holds one `List<Object?>` for the rest. Five integers fit without a list;
  six integers use A/B/R/S and a two-element list in C.

Native scalar transfers into object registers use explicit native conversions.
They do not construct language wrappers. Language boxing has separate opcodes
that construct `$int`, `$double`, `$bool`, or `$String`; unboxing expects the
specific wrapper selected by the compiler.

There is one call opcode and no runtime return-bank discriminator. Scalar returns
use A/F/E/R according to the compiler's result representation. Record construction
and multiple-register results remain future work; the current ABI does not flatten
records or return an overflow list for multi-value results.

Each frame owns typed spills and a single optional outgoing list. During an
internal call the callee borrows that list through C. Nested calls use their own
frame's list. One cached child per call depth avoids repeated allocation for
consecutive calls to the same function. Consumed outgoing references and inactive
object spills are cleared on return. Numeric spill slots need no clearing because
the compiler writes values before loading them. Host calls receive snapshots
because bridge APIs take lists and callbacks may retain them or reenter.

Source support includes the previous numeric/control-flow subset plus object,
string, nullable and dynamic parameters/results, object identity through SSA
phis and calls, object equality, positional callbacks and dynamic method calls.
Dynamic invocation uses canonical boxed `$Value?` arguments and results, with raw
null as the internal null representation. It preserves `$InstanceImpl` and custom
`$Instance` identities. There is no per-call representation guessing or
`wrapAlways` in the typed path. The public host entry adapter normalizes raw host
objects once; raw Dart functions become explicit `TypedHostFunction` adapters.
Those adapters translate the host boundary where actual types can be unknown.

Calls into reference bytecode use compiler-emitted parameter/result representation
metadata in the entry instruction, cached by function offset. Existing files
without this metadata must be recompiled before the typed runtime calls them.
Reference methods currently require a complete positional argument vector;
omitted optional arguments are rejected. Pass the matching reference `Runtime`
when invoking its evaluated/bridge objects. Arbitrary host methods still require
registered bridge wrappers.

```dart
final program = Compiler().compileTyped({
  'example': {'main.dart': 'Object main(Object value) => value;'},
}, entrypoint: 'package:example/main.dart');
final object = Object();
assert(identical(TypedMachine.run(program, objectArguments: [object]), object));
```

Typed codec version 104 intentionally rejects earlier typed bytecode, because
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

Register ABI checkpoint validation: full suite 581 passes, 30 existing reference
failures, six skips; analysis has zero errors. The failure names match
backend-checkpoint-failures.txt. Focused tests cover argument permutations,
repeated values, unused parameters, five-scalar register calls, recursive overflow,
boxed interop, and serialized reference conversion metadata.

Package `cf63c11` adds simultaneous incoming-register definitions to the constrained
allocator. Its eight focused allocator tests pass. The user's package fixture
edits remain untouched.

The ARM64 arithmetic path remains 40 native instructions. The full run function
shrinks from 19,780 to 17,592 bytes. These are code measurements, not ARM64 timings.
See [the assembly and timing report](typed-arm64-optimization.md).

Next work is typed class/method linking, closure/exception conventions, and
compiler lowering for optional/named dynamic calls. Multiple-register record
results need explicit result layouts and allocator support for multiple outputs;
use the same register-first rule with C overflow rather than typed return lists.
The reference VM still has its older representation helpers; typed calls no longer
use those helpers. Continue comparing numeric and object/call workloads when
changing the 189-case loop or extending instruction selection.
