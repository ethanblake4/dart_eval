# Bridge construction and guest overrides

Bridge constructors use the existing external-call ABI: compiler-boxed R/S/C
arguments, typed outgoing slots for overflow, and a list only for legacy host
callbacks that require one. Construction then attaches the compiler-selected
runtime type and guest subclass to the returned host object. The attachment
operation keeps the guest subclass live across the external call through normal
register allocation; it reserves no permanent register.

A guest subclass stores a BridgeSuperShim as its parent. The constructor links
that shim to the host object after construction, allowing super calls and
inherited fields to reach the host implementation without reentering a guest
override. Further guest inheritance unwraps the existing typed parent and updates
the same host object's dispatch root. Export returns that existing host object,
so native callbacks reach the most-derived guest override.

Guest calls to bridge-derived receivers use member dispatch. Ordinary typed
receivers take the existing path first; only other receivers are examined for
bridge registration. A bridge-backed guest member enters the same dispatch loop
using its typed receiver and existing argument registers. Native callbacks use an
explicit bound-member entry, without the legacy extra receiver argument.

The frontend stops super-method lookup at the declared bridge member so named
arguments retain their declared layout. BridgeInstantiate requires a runtime
type ID at every compiler site; plain bridge objects do not use a fabricated
runtime type. The payload version is 114, with 240 opcodes and no new metadata
table.

Validation covers the existing twelve bridge tests plus three fresh/serialized
cases: runtime type identity, named construction and super calls, inherited field
reads/writes, native overrides, and further inheritance with async callbacks.
The bridge/class/typed-instance/codec group passes all 50 tests. One old fixture
passed an undeclared constructor argument; its invocation now matches the
constructor signature.

ARM64 inspection uses Dart 3.10.7, cross-compiled from Windows x64 with LLVM's
ARM64 disassembler. The 240-opcode snapshot retains the 41-instruction integer
and double addition paths, eleven stack stores, three stack loads, and a
176-byte native dispatch frame. The dispatch body measured 25,292 bytes and the
recovery driver 428 bytes in the final inheritance snapshot.
These counts describe generated code, not hardware timings. Bridge and member
resolution remain cold helpers outside the arithmetic dispatch path.

Windows x64 AOT call coverage used 100,001 iterations and three samples, with
checksum `30010480045`. Median ns/iteration: primitive 115, mixed 311, method
474, polymorphic 302, boxed arguments 304, overflow arguments 379. Concurrent
work made these measurements noisy; they are a workload smoke check, not a
before/after performance claim. Reproduce with `benchmark/typed_calls.dart` on
an idle machine for comparisons.
