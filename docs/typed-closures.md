# Closure checkpoint

This document records the design and measurements at successive checkpoints.
For current format versions and suite results, see the
[current checkpoint](current-compiler-checkpoint.md).

The subsequent [global checkpoint](typed-globals.md) adds runtime-owned global
state and retains the originating runtime across closures and bound methods.

The compiler now lowers closure creation and invocation to the typed register
machine. It follows closure targets during reachability analysis and serializes
their signatures and capture layouts. The production backend remains singular.

## Captures and evaluation

Lexical analysis identifies captured bindings before generating code. Each
captured binding gets a shared cell at its declaration. The outer function and
all closures read and write that same cell, including when closure creation is
conditional. Cell payloads retain the compiler's native representation; capturing
an integer does not create a `$int`. Explicit conversion instructions transfer
values between typed registers and cell storage in object registers.

An escaping closure owns a fixed list of its captures, independent of VM frames.
Nested closures forward free bindings; unrelated locals are not retained. Local
recursive functions capture their own predeclared cell. Loop lowering creates
distinct cells for iteration bindings. Constructor initializers, inherited member
access and `super` access participate in receiver capture.

Call lowering snapshots the callee before evaluating arguments and snapshots each
argument before evaluating the next. Named arguments are then placed in canonical
order without changing source evaluation order.

## Calls

Ordinary closures have a hidden receiver in R and boxed language arguments in
S/C. More than two arguments use S for the first and the existing C overflow list
for the rest. No permanent registers or typed overflow lists were added. The
compiler emits scalar boxing at this dynamic boundary and unboxing in the callee.

`callClosure` checks the callable and signature through a non-inlined helper.
A same-program closure with all positional and named arguments supplied enters a
callee frame in the existing switch loop. It does not allocate an argument list
or recursively call the Dart interpreter entry. The frame carries the capture
environment; capture loads do not keep an extra environment register live across
arithmetic dispatch. Calls clobber registers, so the allocator spills live values.

Calls with omitted parameters, function tearoffs, bound method tearoffs and host
callbacks use an adapter. It validates argument names/counts, fills defaults and
converts according to the compiled target signature. Scalar default wrappers are
cached per descriptor. This path currently allocates argument storage and enters
the VM recursively. It is a future optimization target, especially for frequent
optional-argument calls.

Bound methods retain virtual dispatch. Member resolution selects the runtime
override before the adapter binds that method's declaration order and defaults.
Compiled class methods carry closure signature descriptors in the existing table.
Host callback entry through `EvalCallable.call` also applies omitted defaults.
The legacy callback interface remains positional; named host invocation is
supported by `TypedClosure.invoke` and the typed host-function adapter.

Cached frames release captured environments and object spills when returning.
The one-child frame cache remains unchanged. Alternating closure targets can
allocate new frames, and closure creation allocates cells and capture storage.
This checkpoint does not claim allocation-free closure execution generally.

## Encoding and validation

Typed payload version 109 has a 64-byte header, closure descriptors and closure
call-site descriptors. The outer Program envelope stays at version 102. Validation
checks signature lengths, default types, named parameter uniqueness, capture
bounds and outgoing capacity. Defaults currently support scalar constants only.

Six instructions bring the table to 204 entries, leaving 52 byte values for
future intrinsics. This exceeds the early under-200 target, while retaining the
single-byte opcode encoding. Future Map/Set operations should follow List's
explicit representation and operand conventions without permanent registers.

## Verification and next checkpoint

Tests cover shared mutation, escaping and nested closures, shadowing, recursion,
per-iteration bindings, evaluation order, native captured values, defaults,
reordered named arguments, overflow, receiver capture, virtual method tearoffs
and host callbacks. Runtime and codec coverage includes serialized programs.
See [the current checkpoint](current-compiler-checkpoint.md) and
[the ARM64 and benchmark measurements](typed-arm64-optimization.md).

Further closure optimization should specialize defaults and tearoffs at compile
time where possible, and measure polymorphic calls before widening the frame
cache. Multi-register record returns still need result layouts and allocator
support for multiple outputs, with C providing a single overflow list.
