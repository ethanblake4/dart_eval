# Current compiler checkpoint

The `xv2` branch uses one typed register backend. At this checkpoint, 868 tests pass
with zero failures or skips. Analysis reports no errors or code warnings; the
remaining warning is the intentional local `control_flow_graph` path dependency.
The generated runtime check passes with 231 opcodes and 25 one-byte slots free.

The runtime has eight registers: A/B integers, F/G doubles, E boolean, and R/S/C
objects. X is removed from dispatch, argument binding, frame state, and allocator
metadata. Excess boolean arguments use the object registers and existing single
overflow list. All six numeric comparisons in both scalar banks have fused
conditional branches, with short relative and wide absolute encodings. Fusion
requires a single-use comparison and preserves NaN behavior by swapping edges
when negating a condition.

Condition-only `&&`, `||`, and `!` lower directly to CFG edges in statements,
loops, ternaries, and collections. Expression-valued logic retains its value;
conditions containing type tests retain the existing promotion path. See
[production measurements](register-branch-checkpoint-2026-09-16.md).

The legacy interpreter, prototype loop, opcode classes, continuations, frame
state, function pointers, instance implementation, and prescan are removed.
Compiler locals use lexical scopes and SSA values without legacy stack offsets.
Closures retain argument counts and defaults without unused runtime type trees.
Serialized Program metadata contains only fields consumed by the runtime.
The CLI `dump` command decodes the current bytecode directly. A serialized
loop program verified both execution and dumping; mixed-call, external-call,
and async benchmark smoke runs also passed their checksum checks.

Program envelope version: 104. Typed payload version: 116. Recompile earlier
bytecode: removing X changes opcode numbering and boolean argument locations.

Tests are grouped under compiler, runtime, language, interop, standard library,
security, and packages; shared fixtures live under support. See
[test layout](../test/README.md). Test and benchmark filenames no longer have a
`typed_` prefix. Thirteen obsolete or duplicate suites were removed, four small
regression suites were consolidated, and the unique 48-live-value call-pressure
case was retained with fresh and serialized execution. Runtime identity,
exception unwinding, async behavior, codec rejection, and generated bridge
coverage remain in the suite.

The compiler emits explicit boxing and unboxing. Calls use typed registers and
one object overflow list. Async functions suspend into detached frames; ordinary
calls do not check async state. Guest bridge overrides dispatch in the VM loop.
Ordinary field accesses have no late-field checks. Mapped host Lists expose
canonical values through an explicit lazy adapter. Preserve room for future
collection intrinsics in the shared instruction generator.

The latest ARM64 inspection before this structural cleanup measured a
41-instruction arithmetic path and a 176-byte native frame. The generated
runtime dispatch is unchanged by cleanup. Performance evidence includes
mixed/object/overflow calls and async scheduling; cross-compilation does not
provide ARM hardware timings. See [ARM64 measurements](typed-arm64-optimization.md),
[async](typed-async.md), and [bridge dispatch](typed-bridge.md).

Known language limitations include lazy evaluation of late instance-field
initializer expressions, some class-literal expressions, native host Record
construction, and multi-register record returns. Exported records retain a
`$Record` handle. Future payloads retain the existing boxed guest convention.

Run `dart test`, `dart analyze`, and
`dart run tool/generate_typed_machine.dart --check`. Renamed benchmarks live in
`benchmark/`; ARM64 inspection uses `tool/inspect_typed_arm64.ps1`.

The adjacent `D:\Projects\control_flow_graph` checkout remains the local path
dependency at `f77d892`. Its constrained allocator places operands together,
using swaps for resident permutations and safe copies for other placements.
The CFG suite passes 74 tests. See [allocator measurements](allocator-swaps-2026-09-16.md).

The sibling flutter_eval package passes 18 tests on FVM Flutter 3.35.2 / Dart 3.9
against this checkout, including widget callbacks, state updates, navigation,
MethodChannel, asset loading, and hot-swap overrides. Its entrypoint adapters now
use named argument maps and normalized returns. Runtime bridge tables are sized
from program metadata instead of a fixed 1,000-entry limit; a large-plugin
regression covers both list and register callbacks above that limit.
