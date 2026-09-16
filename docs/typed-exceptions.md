# Typed exception checkpoint

This document records the design and measurements at successive checkpoints.
For current format versions and suite results, see the
[current checkpoint](current-compiler-checkpoint.md).

The typed backend now lowers synchronous try/catch/finally, throw/rethrow,
assertions and runtime type tests. It retains the register ABI: A/B integers,
F/G doubles, E/X booleans and R/S/C objects. No handler table or completion
payload becomes a permanent switch-loop register.

## Compiler preservation and completions

An exception may interrupt a block before its outgoing phi copies execute.
Bindings visible across a protected region therefore use dedicated typed spill
slots. These occupy a prefix of each frame's spill bank; allocator spills follow
that prefix. Reads and writes inside the region use explicit slot operations.
Handlers and continuations reload from those slots rather than trusting the
registers left by a throwing instruction. Captured variables retain their shared
cells; only the cell reference needs preservation across handler entry.

Protected returns store their result in a slot of the function's declared result
representation, then execute a completion jump to a normal return continuation.
Break and continue similarly record a destination and target handler depth. The
runtime visits intervening finally blocks before reaching that destination. A
new throw, return or escaping jump from finally replaces the pending completion.
A nested handled try inside finally leaves the outer pending completion intact.
Ordinary returns contain no handler checks.

The initial implementation conservatively preserves all visible locals at try
entry. A later liveness pass can restrict this to bindings needed by handlers or
post-try continuations. That optimization must account for throws during RHS
evaluation, nested handlers and closure mutations.

## Runtime recovery

`TypedMachine.runEntry` owns the recovery boundary and calls the non-inlined
`_dispatch` switch. Putting a Dart catch region around the switch caused the AOT
compiler to reserve a much larger spill area and emit additional stack-address
instructions. Recovery outside the switch avoids that cost.

Each invocation owns a root frame. Existing call return addresses also identify
active cached child frames: calls set the address, and `leave` marks it inactive
with -1. Only a thrown exception traverses that chain to find the current frame.
Unwinding pops handlers and clears exited frames. Recovery reenters the switch
with empty registers and the selected frame/handler PC; compiler-generated
reloads restore the needed values. Static function lookup is inside the existing
frame-entry helper, keeping its metadata table out of the dispatch loop.

Handler storage is allocated lazily and reused by nesting depth. Each active
handler tracks body/catch/finally phase, its caught error and trace, and an optional
pending jump or throw. Exception normalization occurs at this boundary only.
Guest values remain canonical values; native errors receive explicit bridge
wrappers for source type tests. The original exception and trace are retained
for rethrow, whose bytecode selects the lexical catch region rather than matching
the thrown object's identity. Existing host behavior remains: guest `WrappedException` is unwrapped
at the exported call boundary, while uncaught native errors become a
`RuntimeException` retaining the native cause.

## Format and capacity

Typed codec version 111 has a 76-byte header. It serializes exception regions
(owning function, catch PC, finally PC) and completion jumps (owning function,
destination PC, target handler depth). Validation checks table bounds, instruction
boundaries and same-function ownership. The outer Program envelope remains 102.
This checkpoint has 222 opcodes, leaving 34 byte values for later additions,
including Map/Set intrinsics using the existing object registers.

Tests cover fresh and serialized programs, native bridge errors, nested source
calls and closures, recursive and cached-frame unwinding, every register bank,
failed global initialization, typed catch selection, original exception/trace
identity, shadowed locals, and completion replacement through finally. See the
[the current checkpoint](current-compiler-checkpoint.md) and
[ARM64 and benchmark report](typed-arm64-optimization.md) for results.

Final full-suite validation: 725 passes, 95 failures and six skips, with zero
analyzer errors. There are 33 recovered tests and no regressions among previously
passing tests. The failures comprise 94 unfinished-feature errors and the existing
Future.delayed timing assertion, which passes in isolation. All 27 new checkpoint
tests pass, including 24 source-level cases exercised fresh and serialized and
three codec validation tests.

## Next checkpoint

Implement suspension and resumption for async functions using the existing frame
and completion conventions. Preserve typed spills, closure environments, handler
phases and pending finally completions across await. Route asynchronous errors
through the same lexical handler chain, and retain the compiler's explicit value
representations at suspension boundaries. Begin with the existing Await and
ReturnAsync IR and async/exception tests, then rerun the complete migration suite.

Map/Set lowering, remaining representation mismatches, dynamic named-argument
calls and bridge inheritance still appear in the baseline. Call-adapter costs,
frame caching for alternating callees and multiple-register record returns remain
separate performance work. The adjacent control_flow_graph fixture edits were
left untouched; no allocator changes were required for this checkpoint.
