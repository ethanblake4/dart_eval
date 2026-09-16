# Typed backend implementation

Current production integration: [exported function API](typed-exports.md).
Latest checkpoint: [global storage and initialization](typed-globals.md).
`Compiler.compile` and `Runtime.executeLib` now use the typed backend exclusively.
`executeLib` and `eval` bind a parameter-name map and return normalized host values.
The checkpoints below preserve the implementation history; the reference backend
has since been removed. See the typed migration failure report for current gaps.

The user approved implementation on 2026-09-13. This supersedes the pause and
generic-runtime-first order in backend-checkpoint.md. Commit and push each
verified stage in both repositories. Preserve the adjacent package's unrelated
working-tree fixture edits.

## Requirements

The production dispatch loop uses a dense integer switch over bytecode and named,
non-nullable typed scalar registers. Arithmetic handlers must not decode register
arrays, recover operand types, allocate instruction objects, or call generic
arithmetic helpers. Fixed operand and destination combinations are encoded in
the opcode. The general-object register machine has been removed; existing source
tests are the parity reference.

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

The List/String checkpoint removes ten reverse commutative forms: integer add, multiply,
and/or/xor; floating add/multiply; boolean and/or/xor. Integer and boolean operand
permutations are allocator choices, with one canonical result register. Floating
operand order remains unchanged to preserve NaN payload propagation. Subtraction,
division, modulo and shifts retain operand-order-specific forms.

Ten List/String instructions replace those ten slots, keeping 189 opcodes:
String length, concatenation, codeUnitAt, indexing; List creation, length, indexing,
indexed assignment, append, and explicit boxing. String operations consume native
Strings in R/S. Compiler-emitted unboxing selects that representation first.
Indexed List instructions use C for the collection, A for an index, and R for an element.
List elements retain the compiler-selected language representation.

List length requires proof of native list storage. The compiler tracks allocations
through boxing, assignments and joins where every source is known. It does not
replace an unknown List implementation's getter with a host List cast. Raw host
list arguments must use the existing canonical wrapper convention, for example
`$List.wrap([$int(7)])`, or the registered bridge conversion. Typed general List
getter dispatch uses the registered bridge when allocation provenance is unknown.

Dedicated String registers are deferred. The full-loop experiment found shorter
String handlers but an extra unconditional spill store on every dispatch for each
added String local. See [String register measurements](typed-string-registers.md).
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

Typed codec version 107 intentionally rejects earlier typed bytecode, because
opcode numbering and class/signature metadata changed. It serializes scalar/null/string
object constants, preserving UTF-16 code units and numeric bits. Live application
objects remain valid arguments/in-memory constants but are rejected by the codec
rather than being serialized into a lossy replacement.

`compile` uses the typed backend. Typed Map/Set construction, closure
creation, optional/named dynamic arguments, exception handling and async/suspension
remain unfinished. Existing reference-evaluated method offsets refer to the
supplied reference Runtime. Typed class members use their own function table.

## Native class checkpoint

The compiler links reachable constructors and the members of allocated classes.
Class tables contain library/name identity, field counts, and getter/setter/method
function IDs. Call sites record member kind, name and positional argument count;
unrelated classes may use the same method name with different signatures. The
codec preserves these tables and explicit result representations.

`TypedInstance` implements the existing `$Instance` bridge contract. Fields keep
canonical language values. Superclass storage uses separate owner views, as in
the reference runtime; source-level `this` resolves to the most-derived instance.
Member resolution caches the owner and function, including inherited members.
Callable fields/getters and inherited bridge methods also resolve through the
explicit invocation adapter. Dynamic operations on standard-library wrappers
still need a matching Runtime when they use the bridge path, including arithmetic
whose result has remained dynamic instead of being converted to a native scalar.

Ordinary same-program virtual calls enter a typed frame in the current switch.
The receiver occupies R, the first argument S, and the second C. With more than
two arguments, C carries the caller frame's single overflow list, starting at
the second argument. Arguments/results use the canonical object representation;
the compiler emits primitive boxing/unboxing. All registers are caller-clobbered,
so the allocator saves live values. Constructors and explicit superclass calls
use direct function IDs. Void returns have an explicit null-return instruction.

Bridge and cross-program calls need argument snapshots and explicit entry/result
adapters. Bound method tear-offs currently use this adapter path too. Operators
with scalar return signatures also use the explicit adapter when called virtually.
These paths can reenter a Dart invocation; ordinary same-program methods do not.
The one-child frame cache still reallocates when alternating target functions at
the same depth. These are specific targets for subsequent call optimization.

Seven class/call instructions bring the table to 196 entries. This leaves 60
one-byte values available. Future Map/Set intrinsics should be added to the same
generator with explicit inputs, outputs, representation, clobbers and exception
behavior. They can use C for a collection and R/S for keys/elements, following
List's convention, without adding permanent loop registers. Only substitute a
native intrinsic when the compiler proves the required storage representation;
custom collection implementations must retain virtual dispatch. Class/member
metadata does not consume an opcode per class or method. Reinspect full-loop AOT
output after additions: even handler-local table accesses can become loop-wide
live registers under Dart's optimizer.

## Checkpoint and next work

Native class checkpoint validation: 624 passes, 28 existing reference failures,
six skips, zero analyzer errors. Failure names match the updated baseline. The
previously failing Functional test 1 now passes after inherited receiver dispatch
was corrected. Class tests execute both freshly compiled and serialized programs.
Call benchmarks pass all checksums, including odd iteration counts. The generated
files pass `--check`; full ARM64 add dispatch takes 38 native instructions, with
19,700 bytes in the loop. See the assembly report for addresses and timing limits.

List/String checkpoint validation: full suite 594 passes, 29 existing reference
failures, six skips; analysis has zero errors. The regex replacement loop now
passes. Representation normalization before throw/return preserves completion
operands when a handler needs the same local in a different representation.
The remaining failure names match
backend-checkpoint-failures.txt. Focused tests cover argument permutations,
repeated values, unused parameters, five-scalar register calls, recursive overflow,
boxed interop, and serialized reference conversion metadata.

Package `cf63c11` adds simultaneous incoming-register definitions to the constrained
allocator. Its eight focused allocator tests pass. The user's package fixture
edits remain untouched.

The ARM64 arithmetic path is 39 native instructions versus 40 at `d51f120`.
The full run function is 19,256 bytes versus 17,592, reflecting the larger
String/List handlers. These are code measurements, not ARM64 timings.
See [the assembly and timing report](typed-arm64-optimization.md).

Next work is closure/exception conventions and
compiler lowering for optional/named dynamic calls. Multiple-register record
results need explicit result layouts and allocator support for multiple outputs;
use the same register-first rule with C overflow rather than typed return lists.
The reference VM still has its older representation helpers; typed calls no longer
use those helpers. Continue comparing numeric and object/call workloads when
changing the 196-case loop or extending instruction selection.

Closure capture storage, global initialization and synchronous exceptions are
implemented. See the [exception checkpoint](typed-exceptions.md) for current
preservation rules, runtime recovery, format changes and the suspension plan.
