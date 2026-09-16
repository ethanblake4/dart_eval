# Current compiler checkpoint

The `xv2` branch uses one typed register backend. Verification passes 856 tests,
with no failures or skips. Analysis has zero errors and 50 warnings/info.
The generated runtime check passes. The requested test-parity work is complete.

The compiler emits explicit boxing and unboxing. Calls retain the established
typed register ABI and one object overflow list. Async functions suspend into
detached frames; ordinary calls do not check async state. Bridge subclasses
dispatch guest overrides in the same VM loop. Late fields without initializers
have dedicated checks; ordinary field operations are unchanged. Mapped host
Lists expose canonical values through an explicit lazy adapter.

Typed payload version: 115. Opcode count: 243, leaving 13 one-byte slots.
Keep room for future collection intrinsics. `$List.view<T>(values, mapper)` is
now a static generic adapter returning `$List<$Value?>`. Entrypoint arguments
continue to use the public name-to-value map.

Checkpoint history from this continuation:

- `7248efd`: typed exception handling.
- `437c146`: Map/Set operations and stable call operands.
- `d88237b`: async suspension, records, and type operations.
- `6fb69d9`: bridge subclass dispatch and representation fixes.
- The commit containing this note restores all six skipped tests, late-field
  checks, mapped Lists, and indexed assignment effects.

Performance review includes mixed/object/overflow calls and async scheduling,
not just arithmetic. The final ARM64 snapshot retains a 41-instruction arithmetic
path and 176-byte native frame. Dispatch occupies 25,656 bytes. Cross-compilation
does not provide ARM hardware timings; noisy x64 call measurements are not
claimed as speedups. Details and reproduction commands are in
[async](typed-async.md), [bridge](typed-bridge.md), and
[restored coverage](typed-restored-tests.md).

Passing this suite does not establish complete Dart language coverage. Known
remaining limitations include lazy evaluation of late instance-field initializer
expressions, some class-literal expressions, native host Record construction,
and multi-register record returns. Exported records retain a `$Record` handle.
Future payloads retain the existing boxed guest convention.

The adjacent `D:\Projects\control_flow_graph` checkout remains the local path
dependency. Preserve its preexisting modified test fixtures and deleted
`test/control_flow_graph_test.dart`; this continuation did not change them.

Run `dart test`, `dart analyze`, and
`dart run tool/generate_typed_machine.dart --check` from dart_eval.
[The test baseline](typed-migration-failures.md) records final evidence paths.
