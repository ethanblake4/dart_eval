# External bridge checkpoint

`InvokeExternal` now lowers to `callExternal` with a u16 index into an immutable
`TypedExternalCall` table. Each descriptor records the registered function ID and
argument count. The compiler preserves source argument order and repeated SSA
operands, and saves values live across the call. Every register is caller-clobbered;
the canonical result returns in R.

| Argument count | Registers |
| --- | --- |
| 0 | No argument registers are read |
| 1 | R |
| 2 | R, S |
| 3 | R, S, C |
| More than 3 | R, S, and one borrowed C list containing arguments 2 onward |

All supplied arguments are canonical language values. The compiler emits scalar
boxing before the call and the required result conversion afterward. Unused
registers are unspecified and may still contain native values. No extra permanent
registers or typed overflow lists were introduced.

## Generated bindings

`Runtime.registerBridgeFuncRegisters` registers an `EvalRegisterFunc` with the
signature `$Value? Function(Runtime, Object? r, Object? s, Object? c)`. Bindgen emits
these callbacks for top-level functions, constructors, static methods and static
accessors. A callback reads only the slots its signature declares. Known
nonnullable scalar parameters use concrete wrapper casts and typed getters.

These callbacks do not allocate argument vectors. For overflow, generated code
captures individual values from C before invoking native code. In particular,
native callback closures capture those values instead of retaining C, because
the caller can reuse its overflow list on the next invocation.

Existing `registerBridgeFunc` callbacks still receive a fresh `List<$Value?>`.
They may retain or mutate it across reentry. The runtime selects this compatibility
path only for legacy registrations. Existing hand-written standard-library
bindings continue through that path until migrated. The generated legacy callable
methods remain available for tear-offs; registered static entry calls use the
register callback. There is still only one compiler and runtime backend.

## Null and optional arguments

Raw null in a bridge slot means an optional parameter was omitted. A supplied
language null must instead arrive as `$null`. `PrepareBridgeArgument` lowers to
the explicit `rBridgeArgument` instruction for supplied nullable/dynamic values.
It converts null to the constant `$null` and leaves non-null values alone. The
compiler uses a fresh SSA result so the original local retains its VM representation.
Known nonnullable arguments need no such instruction.

Generated default expressions test whether the slot was omitted before reading
its value. This preserves explicit null, including a nullable parameter with a
non-null default. Bridge results normalize `$null` back to the VM's null. Public
`executeLib` parameter-map binding remains outside these internal call paths.

## Validation and continuation

Typed codec 108 uses a 56-byte header and serializes the external-call table.
Validation checks descriptor indices, argument counts and caller overflow
capacity. Old payloads must be recompiled. The Program envelope remains 102.

Tests cover direct and legacy calls, arities 0/1/2/3/6, repeated operands, opaque
object identity, nullable/default parameters, serialization, reentry, retained
legacy lists and generated native callbacks. The bindgen test compiles and runs
the generated Dart source. `benchmark/typed_external_calls.dart` compares identical
bytecode with legacy and direct registrations and checks results explicitly.

The loop has 198 opcodes, leaving 58 byte values for future intrinsics, including
Map/Set operations. The ARM64 arithmetic path remains 38 instructions. See
[assembly measurements](typed-arm64-optimization.md) and the
[current failure report](typed-migration-failures.md).

The next bounded compiler checkpoint is closure capture storage and creation.
Define shared mutable capture cells and typed entry signatures before lowering
`CreateClosure`; preserve identity for escaping closures. Globals, exceptions,
async, Map/Set construction and remaining representation mismatches stay on the
migration list. Generated bridge registration can also be adopted incrementally
by existing hand-written bindings without changing the VM ABI.
