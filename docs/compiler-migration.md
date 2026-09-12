# Compiler migration to control_flow_graph

The xv2 branch replaces direct bytecode emission with a control-flow graph and
SSA pipeline. Stages 1–3 are committed. The current stage 4 checkpoint emits
executable register instructions and integrates serialization and the public
runtime. Runtime parity is incomplete: see [the resume notes](backend-checkpoint.md)
for verified results, remaining failures, and the next steps.

## What to reuse

The original `origin/xval` branch contains useful examples of SSA-producing
expressions, argument handling, integer intrinsics, and branch construction.
Its `compiler/macros/branch.dart` shows explicit condition, branch, and merge
blocks. Its `compiler/helpers/invoke.dart` and `compiler/optimizer/intrinsics.dart`
show the intended distinction between primitive operations and dynamic calls.
These changes need adaptation to current analyzer AST APIs and current language
features; importing entire old files would discard intervening fixes.

The old branch was never a finished compiler. Its loop implementation was
mostly commented out, the assembler contained substantial commented code, and
`Compiler.compile` constructed SSA but returned a program with no instructions.
The old hand-written register layout is an ABI sketch, not a working backend.

The adjacent `control_flow_graph` package now provides graph builders, phi
insertion, semi-pruned SSA construction, liveness/register-pressure analysis,
spilling, physical register allocation, and assembly callbacks. Use its current
allocator and assembler APIs rather than reviving the old xval assembler.
The dependency remains a local path in `pubspec.yaml`.

## Stages and acceptance criteria

1. **Finish the frontend contract.** AST visitors emit `Operation` objects,
   locals refer to SSA values, calls explicitly define their results, and
   parameters define incoming values. Preserve current declaration, bridge,
   argument-default, boxing, enum, and record behavior. Keep analyzer errors at
   zero; do not reintroduce bytecode-shaped compatibility APIs.
2. **Validate graph construction.** Give each function its own graph and stable
   declaration identity. Every control transfer ends a block; branches have
   explicit successors, loops have backedges, and returns do not fall through.
   Add compile-to-IR tests for nested branches, short-circuiting, loops,
   break/continue, exceptions, defaults, and closures before optimizing them.
3. **Establish SSA invariants.** Run phi insertion and SSA conversion over each
   function independently. Verify every read resolves to the intended definition
   and every `copyWith` obeys renaming. Preserve operand order and multiplicity:
   CFG exposes a set of inputs, but `f(x, x)` still has two arguments. Keep
   lexical variable names separate from SSA identity and preserve boxing state
   at joins. Add effect modeling before enabling dead-definition elimination:
   the current package can otherwise remove a call whose result is unused.
4. **Lower to instructions.** Define register groups, calling convention,
   operation variants, spill/reload/move/swap callbacks, and branch encoding.
   Start with constants, arithmetic, parameters, returns, calls, and branches.
   Resolve function, global-initializer, override, exception-handler, and jump
   locations only after final instruction layout. Add bridge and object,
   collection, closure, and async instructions in tested increments.
5. **Prove runtime parity.** Run existing semantic tests against the new backend,
   comparing results and exceptions with the established behavior. Cover saved
   bytecode round trips and bridge interop before replacing the public runtime
   path. Benchmark only after correctness; tune allocation and optimization
   based on measured workloads.

## Current migration details

Declaration compilation uses IR for parameter loads, properties, globals,
constructor calls, bridge subclass creation, and returns. Explicit constructors
register their declaration identity. Field initialization respects fields already
initialized by a constructor, and enum allocation accounts for its hidden fields
once. Enum constants resolve their selected named constructor.

Focused IR tests cover repeated operands, dynamic-call receiver ordering, bridge
arguments, mutation operations with no SSA result, and increments whose old and
new values receive different SSA versions. These tests protect the transformation
contract; they do not establish execution parity or a finished backend.

`Compiler.functionGraphs` exposes the typed graphs from the last compilation,
keyed by the function IDs used in declaration metadata. `Compiler.functionNames`
maps those IDs to labels. These IDs must be relocated to instruction offsets by
the backend. Graphs are returned before optimization; the tests explicitly run
phi insertion and SSA conversion on branches and loops.

The frontend now builds loops, branches, break destinations, and exception
regions without patching bytecode offsets. Exception operations describe handler
entry and pending completion. Their runtime behavior, especially nested finally
blocks and abrupt completion, still needs lowering and semantic tests. Closures
currently capture values; mutable captured locals need shared cells before
execution parity. Collection spreads and continue statements now use explicit loop and branch
blocks. Labeled break and continue remain unsupported.

## Validation for this pass

This section records the initial frontend pass, before the executable backend.

- Full `dart analyze --format machine`: zero errors. Warnings remain in the
  unfinished runtime/serialization code and for the local path dependency.
- Twenty focused tests pass across `compiler_cfg_test.dart`,
  `compiler_control_flow_test.dart`, `ir_test.dart`, and `flow_ir_test.dart`.
- No analyzer exclusions or error suppressions were added.
- The runtime suite is not a completion gate for this frontend pass because
  `Compiler.compile` still returns empty bytecode and serialization/lowering
  remain unfinished in the inherited branch.

Package reference: [control_flow_graph](https://pub.dev/packages/control_flow_graph).
Implementation decisions use the adjacent checkout selected by `pubspec.yaml`.

## Milestone 2: graph construction

Completed control-flow validation before transformations, unreachable-block
pruning, continue targets for each loop form, short-circuit expressions, and
list/set/map spreads. Closure compilation isolates loop and exception contexts.
A field-read path now preserves its SSA result. Fifty-two dart_eval frontend
and IR tests pass, including declarations, defaults, exceptions, and async IR.

The companion control_flow_graph changes add unreachable-block pruning, register
single-block roots, and fix dominator convergence. Both new regression tests
pass. The full package suite currently has ten golden-output failures in the
preexisting edited for-loop fixture: it adds a subtraction but expects the old
loop output. Those existing allocator/test changes remain outside this commit.

## Milestone 3: SSA invariants and effects

The compiler now retains frontend graphs and creates transformed copies in
`Compiler.ssaFunctionGraphs`. It runs phi insertion, SSA conversion, dominance
validation, conservative dead-definition removal, and a second validation.
The complete frontend/IR suite has 115 passing tests.

The companion package now defaults operations to effectful, tracks uses from
return/effect-only operations, and copies shared operands before assigning SSA
versions. It preserves terminal blocks during trimming. Pure dead chains can be
removed without deleting calls or potentially throwing operations. Ten targeted
package regression tests pass. Copy propagation and block trimming remain
outside the compiler pipeline until their further transformations are validated.

## Stage 4 checkpoint: executable register backend

Instruction lowering now runs through the package's SSA, dead-definition removal,
spilling, phi elimination, register allocation, and assembler. Function and block
addresses are relocated after layout. The runtime executes a bounded general
register file with separate call frames; programs round-trip through the version
101 codec. This is an executable checkpoint, not a claim of completed parity.

All 24 new machine/backend/codec tests pass. The full dart_eval suite has 485
passing tests, 30 failures, and 6 skips. Full analysis reports zero errors, with
warnings and lint infos remaining. The companion package has 21 passing targeted
tests and zero analyzer errors or warnings. Work stops here at the user's request;
resume from [backend-checkpoint.md](backend-checkpoint.md).
