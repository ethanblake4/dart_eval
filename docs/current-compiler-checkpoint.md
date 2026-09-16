# Current compiler checkpoint

The `xv2` branch uses one typed register backend. After cleanup, 801 tests pass
with zero failures or skips. Analysis reports no errors or code warnings; the
remaining warning is the intentional local `control_flow_graph` path dependency.
The generated runtime check passes with 243 opcodes and 13 one-byte slots free.

The legacy interpreter, prototype loop, opcode classes, continuations, frame
state, function pointers, instance implementation, and prescan are removed.
Compiler locals use lexical scopes and SSA values without legacy stack offsets.
Closures retain argument counts and defaults without unused runtime type trees.
Serialized Program metadata contains only fields consumed by the runtime.
The CLI `dump` command decodes the current bytecode directly. A serialized
loop program verified both execution and dumping; mixed-call, external-call,
and async benchmark smoke runs also passed their checksum checks.

Program envelope version: 103. Typed payload version: 115. Recompile bytecode
produced before this cleanup; obsolete declaration, initializer, and runtime-type
metadata blocks are no longer serialized.

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
dependency. Its preexisting test-fixture changes and deleted test remain untouched.
